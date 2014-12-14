-- XEP-0313: Message Archive Management for Prosody
-- Copyright (C) 2011-2012 Kim Alvefur
--
-- This file is MIT/X11 licensed.

local xmlns_mam     = "urn:xmpp:mam:tmp";
local xmlns_delay   = "urn:xmpp:delay";
local xmlns_forward = "urn:xmpp:forward:0";

local st = require "util.stanza";
local rsm = module:require "mod_mam/rsm";
local jid_bare = require "util.jid".bare;
local jid_split = require "util.jid".split;
local jid_prep = require "util.jid".prep;
local host = module.host;

local serialize, deserialize = require"util.json".encode, require"util.json".decode;
local unpack = unpack;
local tostring = tostring;
local time_now = os.time;
local t_insert = table.insert;
local m_min = math.min;
local timestamp, timestamp_parse = require "util.datetime".datetime, require "util.datetime".parse;
local default_max_items, max_max_items = 20, module:get_option_number("max_archive_query_results", 50);
--local rooms_to_archive = module:get_option_set("rooms_to_archive",{});

local sql, setsql, getsql = {};
do -- SQL stuff
local dburi;
local connection;
local connections = module:shared "/*/sql/connection-cache";
local build_url = require"socket.url".build;
local resolve_relative_path = require "core.configmanager".resolve_relative_path;
local params = module:get_option("mam_sql", module:get_option("sql"));

local function db2uri(params)
	return build_url{
		scheme = params.driver,
		user = params.username,
		password = params.password,
		host = params.host,
		port = params.port,
		path = params.database,
	};
end

local function test_connection()
	if not connection then return nil; end
	if connection:ping() then
		return true;
	else
		module:log("debug", "Database connection closed");
		connection = nil;
		connections[dburi] = nil;
	end
end
local function connect()
	if not test_connection() then
		prosody.unlock_globals();
		local dbh, err = DBI.Connect(
			params.driver, params.database,
			params.username, params.password,
			params.host, params.port
		);
		prosody.lock_globals();
		if not dbh then
			module:log("debug", "Database connection failed: %s", tostring(err));
			return nil, err;
		end
		module:log("debug", "Successfully connected to database");
		dbh:autocommit(false); -- don't commit automatically
		connection = dbh;

		connections[dburi] = dbh;
	end
	return connection;
end

do -- process options to get a db connection
	local ok;
	prosody.unlock_globals();
	ok, DBI = pcall(require, "DBI");
	if not ok then
		package.loaded["DBI"] = {};
		module:log("error", "Failed to load the LuaDBI library for accessing SQL databases: %s", DBI);
		module:log("error", "More information on installing LuaDBI can be found at http://prosody.im/doc/depends#luadbi");
	end
	prosody.lock_globals();
	if not ok or not DBI.Connect then
		return; -- Halt loading of this module
	end

	params = params or { driver = "SQLite3" };

	if params.driver == "SQLite3" then
		params.database = resolve_relative_path(prosody.paths.data or ".", params.database or "prosody.sqlite");
	end

	assert(params.driver and params.database, "Both the SQL driver and the database need to be specified");

	dburi = db2uri(params);
	connection = connections[dburi];

	assert(connect());

end

function getsql(sql, ...)
	if params.driver == "PostgreSQL" then
		sql = sql:gsub("`", "\"");
	end
	-- do prepared statement stuff
	local stmt, err = connection:prepare(sql);
	if not stmt and not test_connection() then error("connection failed"); end
	if not stmt then module:log("error", "QUERY FAILED: %s %s", err, debug.traceback()); return nil, err; end
	-- run query
	local ok, err = stmt:execute(...);
	if not ok and not test_connection() then error("connection failed"); end
	if not ok then return nil, err; end

	return stmt;
end
function setsql(sql, ...)
	local stmt, err = getsql(sql, ...);
	if not stmt then return stmt, err; end
	return stmt:affected();
end
function sql.rollback(...)
	if connection then connection:rollback(); end -- FIXME check for rollback error?
	return ...;
end
function sql.commit(...)
	if not connection:commit() then return nil, "SQL commit failed"; end
	return ...;
end

end

local archive_store = "archive2";

-- Handle archive queries
module:hook("iq/bare/"..xmlns_mam..":query", function(event)
	local origin, stanza = event.origin, event.stanza;
	local room = jid_split(stanza.attr.to);
	local query = stanza.tags[1];

	local room_obj = hosts[module.host].modules.muc.rooms[jid_bare(stanza.attr.to)];
	if not room_obj then
		return -- FIXME not found
	end
	local from = jid_bare(stanza.attr.from);

	if room_obj._affiliations[from] == "outcast"
		or room_obj._data.members_only and not room_obj._affiliations[from] then
		return -- FIXME unauth
	end

	if stanza.attr.type == "get" then
		local qid = query.attr.queryid;

		-- Search query parameters
		local qwith = query:get_child_text("with");
		local qstart = query:get_child_text("start");
		local qend = query:get_child_text("end");
		local qset = rsm.get(query);
		module:log("debug", "Archive query, id %s with %s from %s until %s)",
			tostring(qid), qwith or "anyone", qstart or "the dawn of time", qend or "now");

		if qstart or qend then -- Validate timestamps
			local vstart, vend = (qstart and timestamp_parse(qstart)), (qend and timestamp_parse(qend))
			if (qstart and not vstart) or (qend and not vend) then
				origin.send(st.error_reply(stanza, "modify", "bad-request", "Invalid timestamp"))
				return true
			end
			qstart, qend = vstart, vend;
		end

		local qres;
		if qwith then -- Validate the 'with' jid
			local pwith = qwith and jid_prep(qwith);
			if pwith and not qwith then -- it failed prepping
				origin.send(st.error_reply(stanza, "modify", "bad-request", "Invalid JID"))
				return true
			end
			local _, _, resource = jid_split(qwith);
			qwith = jid_bare(pwith);
			qres = resource;
		end

		-- RSM stuff
		local qmax = m_min(qset and qset.max or default_max_items, max_max_items);
		local first, last;
		local n = 0;

		local sql_query = ([[
		SELECT `id`, `when`, `stanza`
		FROM `prosodyarchive`
		WHERE `host` = ? AND `user` = ? AND `store` = ?
		AND `when` BETWEEN ? AND ?
		%s
		AND `id` > ?
		LIMIT ?;
		]]):format(qres and [[AND `resource` = ?]] or "")

		local p = {
			host, room, archive_store,
			qstart or 0, qend or time_now(),
			qset and tonumber(qset.after) or 0,
			qmax
		};
		if qres then
			t_insert(p, 6, qres);
		end
		module:log("debug", "getsql(sql_query, "..table.concat(p, ", "));
		local data, err = getsql(sql_query, unpack(p));
		if not data then
			origin.send(st.error_reply(stanza, "cancel", "internal-server-error", "Error loading archive: "..tostring(err)));
			return true
		end

		for item in data:rows() do
			local id, when, orig_stanza = unpack(item);
			--module:log("debug", "id is %s", id);

			local fwd_st = st.message{ to = stanza.attr.from, from = stanza.attr.to }
				:tag("result", { xmlns = xmlns_mam, queryid = qid, id = id }):up()
				:tag("forwarded", { xmlns = xmlns_forward })
					:tag("delay", { xmlns = xmlns_delay, stamp = timestamp(when) }):up();
			orig_stanza = st.deserialize(deserialize(orig_stanza));
			orig_stanza.attr.xmlns = "jabber:client";
			fwd_st:add_child(orig_stanza);
			origin.send(fwd_st);
			last = id;
			n = n + 1;
			if not first then
				first = id;
			end
		end
		-- That's all folks!
		module:log("debug", "Archive query %s completed", tostring(qid));

		local reply = st.reply(stanza);
		if last then
			-- This is a bit redundant, isn't it?
			reply:query(xmlns_mam):add_child(rsm.generate{first = first, last = last, count = n});
		end
		origin.send(reply);
		return true
	end
end);

-- Handle messages
local function message_handler(event)
	local origin, stanza = event.origin, event.stanza;
	local orig_type = stanza.attr.type or "normal";
	local orig_to = stanza.attr.to;
	local orig_from = stanza.attr.from;

	-- Still needed?
	if not orig_from then
		orig_from = origin.full_jid;
	end

	-- Only store groupchat messages
	if not (orig_type == "groupchat" and (stanza:get_child("body") or stanza:get_child("subject"))) then
		return;
	end

	local room = jid_split(orig_to);
	local room_obj = hosts[host].modules.muc.rooms[orig_to]
	if not room_obj then return end

	local when = time_now();
	local stanza = st.clone(stanza); -- Private copy
	--stanza.attr.to = nil;
	local nick = room_obj._jid_nick[orig_from];
	if not nick then return end
	stanza.attr.from = nick;
	local _, _, nick = jid_split(nick);
	-- And stash it
		local ok, err = setsql([[
		INSERT INTO `prosodyarchive`
		(`host`, `user`, `store`, `when`, `resource`, `stanza`)
		VALUES (?, ?, ?, ?, ?, ?);
		]], host, room, archive_store, when, nick, serialize(st.preserialize(stanza)))
		if ok then
			sql.commit();
		else
			module:log("error", "SQL error: %s", err);
			sql.rollback();
		end
	--[[ This was dropped from the spec
	if ok then
		stanza:tag("archived", { xmlns = xmlns_mam, by = host, id = id }):up();
	end
	--]]
end

module:hook("message/bare", message_handler, 2);

module:add_feature(xmlns_mam);
