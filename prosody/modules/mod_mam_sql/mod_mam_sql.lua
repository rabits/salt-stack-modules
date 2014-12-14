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

local dm_load = require "util.datamanager".load;
local dm_store = require "util.datamanager".store;
local rm_load_roster = require "core.rostermanager".load_roster;

local serialize, deserialize = require"util.json".encode, require"util.json".decode;
local unpack = unpack;
local tostring = tostring;
local time_now = os.time;
local t_insert = table.insert;
local m_min = math.min;
local timestamp, timestamp_parse = require "util.datetime".datetime, require "util.datetime".parse;
local default_max_items, max_max_items = 20, module:get_option_number("max_archive_query_results", 50);
local global_default_policy = module:get_option("default_archive_policy", false);
-- TODO Should be possible to enforce it too

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

local connect

local function test_connection()
	if not connection then return nil; end
	if connection:ping() then
		return true;
	else
		module:log("debug", "Database connection closed");
		module:log("debug", "Attempting to reconnect");
		connection = nil;
		return connect();
	end
end
function connect()
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
	if not connection then
		return nil, 'connection failed';
	end
	if not test_connection() then
		return nil, 'connection failed';
	end
	-- do prepared statement stuff
	local stmt, err = connection:prepare(sql);
	if not stmt and not test_connection() then
		return nil, "connection failed";
	end
	if not stmt then module:log("error", "QUERY FAILED: %s %s", err, debug.traceback()); return nil, err; end
	-- run query
	local ok, err = stmt:execute(...);
	if not ok and not test_connection() then
		return nil, "connection failed";
	end
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

-- For translating preference names from string to boolean and back
local default_attrs = {
	always = true, [true] = "always",
	never = false, [false] = "never",
	roster = "roster",
}

do
	local prefs_format = {
		[false] = "roster",
		-- default ::= true | false | "roster"
		-- true = always, false = never, nil = global default
		["romeo@montague.net"] = true, -- always
		["montague@montague.net"] = false, -- newer
	};
end

local archive_store = "archive2";
local prefs_store = archive_store .. "_prefs";
local function get_prefs(user)
	return dm_load(user, host, prefs_store) or
		{ [false] = global_default_policy };
end
local function set_prefs(user, prefs)
	return dm_store(user, host, prefs_store, prefs);
end


-- Handle prefs.
module:hook("iq/self/"..xmlns_mam..":prefs", function(event)
	local origin, stanza = event.origin, event.stanza;
	local user = origin.username;
	if stanza.attr.type == "get" then
		local prefs = get_prefs(user);
		local default = prefs[false];
		default = default ~= nil and default_attrs[default] or global_default_policy;
		local reply = st.reply(stanza):tag("prefs", { xmlns = xmlns_mam, default = default })
		local always = st.stanza("always");
		local never = st.stanza("never");
		for k,v in pairs(prefs) do
			if k then
				(v and always or never):tag("jid"):text(k):up();
			end
		end
		reply:add_child(always):add_child(never);
		origin.send(reply);
		return true
	else -- type == "set"
		local prefs = {};
		local new_prefs = stanza:get_child("prefs", xmlns_mam);
		local new_default = new_prefs.attr.default;
		if new_default then
			prefs[false] = default_attrs[new_default];
		end

		local always = new_prefs:get_child("always");
		if always then
			for rule in always:childtags("jid") do
				local jid = rule:get_text();
				prefs[jid] = true;
			end
		end

		local never = new_prefs:get_child("never");
		if never then
			for rule in never:childtags("jid") do
				local jid = rule:get_text();
				prefs[jid] = false;
			end
		end

		local ok, err = set_prefs(user, prefs);
		if not ok then
			origin.send(st.error_reply(stanza, "cancel", "internal-server-error", "Error storing preferences: "..tostring(err)));
		else
			origin.send(st.reply(stanza));
		end
		return true
	end
end);

-- Handle archive queries
module:hook("iq/self/"..xmlns_mam..":query", function(event)
	local origin, stanza = event.origin, event.stanza;
	local query = stanza.tags[1];
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
		local last;

		local sql_query = ([[
		SELECT `id`, `when`, `stanza`
		FROM `prosodyarchive`
		WHERE `host` = ? AND `user` = ? AND `store` = ?
		AND `when` BETWEEN ? AND ?
		%s %s
		AND `id` > ?
		LIMIT ?;
		]]):format(qwith and [[AND `with` = ?]] or "", qres and [[AND `resource` = ?]] or "")

		local p = {
			host, origin.username, archive_store,
			qstart or 0, qend or time_now(),
			qset and tonumber(qset.after) or 0,
			qmax
		};
		if qwith then
			if qres then
				t_insert(p, 6, qres);
			end
			t_insert(p, 6, qwith);
		end
		local data, err = getsql(sql_query, unpack(p));
		if not data then
			origin.send(st.error_reply(stanza, "cancel", "internal-server-error", "Error loading archive: "..tostring(err)));
			return true
		end

		for item in data:rows() do
			local id, when, orig_stanza = unpack(item);
			--module:log("debug", "id is %s", id);

			local fwd_st = st.message{ to = origin.full_jid }
				:tag("result", { xmlns = xmlns_mam, queryid = qid, id = id }):up()
				:tag("forwarded", { xmlns = xmlns_forward })
					:tag("delay", { xmlns = xmlns_delay, stamp = timestamp(when) }):up();
			orig_stanza = st.deserialize(deserialize(orig_stanza));
			orig_stanza.attr.xmlns = "jabber:client";
			fwd_st:add_child(orig_stanza);
			origin.send(fwd_st);
			last = id;
		end
		-- That's all folks!
		module:log("debug", "Archive query %s completed", tostring(qid));

		local reply = st.reply(stanza);
		if last then
			-- This is a bit redundant, isn't it?
			reply:query(xmlns_mam):add_child(rsm.generate{last = last});
		end
		origin.send(reply);
		return true
	end
end);

local function has_in_roster(user, who)
	local roster = rm_load_roster(user, host);
	module:log("debug", "%s has %s in roster? %s", user, who, roster[who] and "yes" or "no");
	return roster[who];
end

local function shall_store(user, who)
	-- TODO Cache this?
	local prefs = get_prefs(user);
	local rule = prefs[who];
	module:log("debug", "%s's rule for %s is %s", user, who, tostring(rule))
	if rule ~= nil then
		return rule;
	else -- Below could be done by a metatable
		local default = prefs[false];
		module:log("debug", "%s's default rule is %s", user, tostring(default))
		if default == nil then
			default = global_default_policy;
			module:log("debug", "Using global default rule, %s", tostring(default))
		end
		if default == "roster" then
			return has_in_roster(user, who);
		end
		return default;
	end
end

-- Handle messages
local function message_handler(event, c2s)
	local origin, stanza = event.origin, event.stanza;
	local orig_type = stanza.attr.type or "normal";
	local orig_to = stanza.attr.to;
	local orig_from = stanza.attr.from;

	if not orig_from and c2s then
		orig_from = origin.full_jid;
	end
	orig_to = orig_to or orig_from; -- Weird corner cases

	-- Don't store messages of these types
	if orig_type == "error"
	or orig_type == "headline"
	or orig_type == "groupchat"
	or not stanza:get_child("body") then
		return;
		-- TODO Maybe headlines should be configurable?
	end

	local store_user, store_host = jid_split(c2s and orig_from or orig_to);
	local target_jid = c2s and orig_to or orig_from;
	local target_bare = jid_bare(target_jid);
	local _, _, target_resource = jid_split(target_jid);

	if shall_store(store_user, target_bare) then
		module:log("debug", "Archiving stanza: %s", stanza:top_tag());

		--local id = uuid();
		local when = time_now();
		-- And stash it
		local ok, err = setsql([[
		INSERT INTO `prosodyarchive`
		(`host`, `user`, `store`, `when`, `with`, `resource`, `stanza`)
		VALUES (?, ?, ?, ?, ?, ?, ?);
		]], store_host, store_user, archive_store, when, target_bare, target_resource, serialize(st.preserialize(stanza)))
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
	else
		module:log("debug", "Not archiving stanza: %s", stanza:top_tag());
	end
end

local function c2s_message_handler(event)
	return message_handler(event, true);
end

-- Stanzas sent by local clients
module:hook("pre-message/bare", c2s_message_handler, 2);
module:hook("pre-message/full", c2s_message_handler, 2);
-- Stanszas to local clients
module:hook("message/bare", message_handler, 2);
module:hook("message/full", message_handler, 2);

module:add_feature(xmlns_mam);

-- In the telnet console, run:
-- >hosts["this host"].modules.mam_sql.environment.create_sql()
function create_sql()
	local stm = getsql[[
	CREATE TABLE `prosodyarchive` (
		`host` TEXT,
		`user` TEXT,
		`store` TEXT,
		`id` INTEGER PRIMARY KEY AUTOINCREMENT,
		`when` INTEGER,
		`with` TEXT,
		`resource` TEXT,
		`stanza` TEXT
	);
	CREATE INDEX `hus` ON `prosodyarchive` (`host`, `user`, `store`);
	CREATE INDEX `with` ON `prosodyarchive` (`with`);
	CREATE INDEX `thetime` ON `prosodyarchive` (`when`);
	]];
	stm:execute();
	sql.commit();
end
