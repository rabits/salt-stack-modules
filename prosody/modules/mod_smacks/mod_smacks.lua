local st = require "util.stanza";
local uuid_generate = require "util.uuid".generate;

local t_insert, t_remove = table.insert, table.remove;
local math_min = math.min;
local os_time = os.time;
local tonumber, tostring = tonumber, tostring;
local add_filter = require "util.filters".add_filter;
local timer = require "util.timer";
local datetime = require "util.datetime";

local xmlns_sm2 = "urn:xmpp:sm:2";
local xmlns_sm3 = "urn:xmpp:sm:3";
local xmlns_errors = "urn:ietf:params:xml:ns:xmpp-stanzas";
local xmlns_delay = "urn:xmpp:delay";

local sm2_attr = { xmlns = xmlns_sm2 };
local sm3_attr = { xmlns = xmlns_sm3 };

local resume_timeout = module:get_option_number("smacks_hibernation_time", 300);
local s2s_smacks = module:get_option_boolean("smacks_enabled_s2s", false);
local max_unacked_stanzas = module:get_option_number("smacks_max_unacked_stanzas", 0);
local core_process_stanza = prosody.core_process_stanza;
local sessionmanager = require"core.sessionmanager";

local c2s_sessions = module:shared("/*/c2s/sessions");
local session_registry = {};

local function can_do_smacks(session, advertise_only)
	if session.smacks then return false, "unexpected-request", "Stream management is already enabled"; end

	local session_type = session.type;
	if session_type == "c2s" then
		if not(advertise_only) and not(session.resource) then -- Fail unless we're only advertising sm
			return false, "unexpected-request", "Client must bind a resource before enabling stream management";
		end
		return true;
	elseif s2s_smacks and (session_type == "s2sin" or session_type == "s2sout") then
		return true;
	end
	return false, "service-unavailable", "Stream management is not available for this stream";
end

module:hook("stream-features",
		function (event)
			if can_do_smacks(event.origin, true) then
				event.features:tag("sm", sm2_attr):tag("optional"):up():up();
				event.features:tag("sm", sm3_attr):tag("optional"):up():up();
			end
		end);

module:hook("s2s-stream-features",
		function (event)
			if can_do_smacks(event.origin, true) then
				event.features:tag("sm", sm2_attr):tag("optional"):up():up();
				event.features:tag("sm", sm3_attr):tag("optional"):up():up();
			end
		end);

module:hook_stanza("http://etherx.jabber.org/streams", "features",
		function (session, stanza)
			if can_do_smacks(session) then
				if stanza:get_child("sm", xmlns_sm3) then
					session.sends2s(st.stanza("enable", sm3_attr));
				elseif stanza:get_child("sm", xmlns_sm2) then
					session.sends2s(st.stanza("enable", sm2_attr));
				end
			end
		end);

local function wrap_session(session, resume, xmlns_sm)
	local sm_attr = { xmlns = xmlns_sm };
	-- Overwrite process_stanza() and send()
	local queue;
	if not resume then
		queue = {};
		session.outgoing_stanza_queue = queue;
		session.last_acknowledged_stanza = 0;
	else
		queue = session.outgoing_stanza_queue;
	end

	local _send = session.sends2s or session.send;
	local function new_send(stanza)
		local attr = stanza.attr;
		if attr and not attr.xmlns then -- Stanza in default stream namespace
			local cached_stanza = st.clone(stanza);

			if cached_stanza and cached_stanza:get_child("delay", xmlns_delay) == nil then
				cached_stanza = cached_stanza:tag("delay", { xmlns = xmlns_delay, from = session.host, stamp = datetime.datetime()});
			end

			queue[#queue+1] = cached_stanza;
		end
		if session.hibernating then
			-- The session is hibernating, no point in sending the stanza
			-- over a dead connection.  It will be delivered upon resumption.
			return true;
		end
		local ok, err = _send(stanza);
		if ok and #queue > max_unacked_stanzas and not session.awaiting_ack and attr and not attr.xmlns then
			session.awaiting_ack = true;
			return _send(st.stanza("r", sm_attr));
		end
		return ok, err;
	end

	if session.sends2s then
		session.sends2s = new_send;
	else
		session.send = new_send;
	end

	local session_close = session.close;
	function session.close(...)
		if session.resumption_token then
			session_registry[session.resumption_token] = nil;
			session.resumption_token = nil;
		end
		return session_close(...);
	end

	if not resume then
		session.handled_stanza_count = 0;
		add_filter(session, "stanzas/in", function (stanza)
			if not stanza.attr.xmlns then
				session.handled_stanza_count = session.handled_stanza_count + 1;
				session.log("debug", "Handled %d incoming stanzas", session.handled_stanza_count);
			end
			return stanza;
		end);
	end

	return session;
end

function handle_enable(session, stanza, xmlns_sm)
	local ok, err, err_text = can_do_smacks(session);
	if not ok then
		session.log("warn", "Failed to enable smacks: %s", err_text); -- TODO: XEP doesn't say we can send error text, should it?
		session.send(st.stanza("failed", { xmlns = xmlns_sm }):tag(err, { xmlns = xmlns_errors}));
		return true;
	end

	module:log("debug", "Enabling stream management");
	session.smacks = true;

	wrap_session(session, false, xmlns_sm);

	local resume_token;
	local resume = stanza.attr.resume;
	if resume == "true" or resume == "1" then
		resume_token = uuid_generate();
		session_registry[resume_token] = session;
		session.resumption_token = resume_token;
	end
	(session.sends2s or session.send)(st.stanza("enabled", { xmlns = xmlns_sm, id = resume_token, resume = resume }));
	return true;
end
module:hook_stanza(xmlns_sm2, "enable", function (session, stanza) return handle_enable(session, stanza, xmlns_sm2); end, 100);
module:hook_stanza(xmlns_sm3, "enable", function (session, stanza) return handle_enable(session, stanza, xmlns_sm3); end, 100);

function handle_enabled(session, stanza, xmlns_sm)
	module:log("debug", "Enabling stream management");
	session.smacks = true;

	wrap_session(session, false, xmlns_sm);

	-- FIXME Resume?

	return true;
end
module:hook_stanza(xmlns_sm2, "enabled", function (session, stanza) return handle_enabled(session, stanza, xmlns_sm2); end, 100);
module:hook_stanza(xmlns_sm3, "enabled", function (session, stanza) return handle_enabled(session, stanza, xmlns_sm3); end, 100);

function handle_r(origin, stanza, xmlns_sm)
	if not origin.smacks then
		module:log("debug", "Received ack request from non-smack-enabled session");
		return;
	end
	module:log("debug", "Received ack request, acking for %d", origin.handled_stanza_count);
	-- Reply with <a>
	(origin.sends2s or origin.send)(st.stanza("a", { xmlns = xmlns_sm, h = tostring(origin.handled_stanza_count) }));
	return true;
end
module:hook_stanza(xmlns_sm2, "r", function (origin, stanza) return handle_r(origin, stanza, xmlns_sm2); end);
module:hook_stanza(xmlns_sm3, "r", function (origin, stanza) return handle_r(origin, stanza, xmlns_sm3); end);

function handle_a(origin, stanza)
	if not origin.smacks then return; end
	origin.awaiting_ack = nil;
	-- Remove handled stanzas from outgoing_stanza_queue
	--log("debug", "ACK: h=%s, last=%s", stanza.attr.h or "", origin.last_acknowledged_stanza or "");
	local handled_stanza_count = tonumber(stanza.attr.h)-origin.last_acknowledged_stanza;
	local queue = origin.outgoing_stanza_queue;
	if handled_stanza_count > #queue then
		module:log("warn", "The client says it handled %d new stanzas, but we only sent %d :)",
			handled_stanza_count, #queue);
		module:log("debug", "Client h: %d, our h: %d", tonumber(stanza.attr.h), origin.last_acknowledged_stanza);
		for i=1,#queue do
			module:log("debug", "Q item %d: %s", i, tostring(queue[i]));
		end
	end
	for i=1,math_min(handled_stanza_count,#queue) do
		t_remove(origin.outgoing_stanza_queue, 1);
	end
	origin.last_acknowledged_stanza = origin.last_acknowledged_stanza + handled_stanza_count;
	return true;
end
module:hook_stanza(xmlns_sm2, "a", handle_a);
module:hook_stanza(xmlns_sm3, "a", handle_a);

--TODO: Optimise... incoming stanzas should be handled by a per-session
-- function that has a counter as an upvalue (no table indexing for increments,
-- and won't slow non-198 sessions). We can also then remove the .handled flag
-- on stanzas

function handle_unacked_stanzas(session)
	local queue = session.outgoing_stanza_queue;
	local error_attr = { type = "cancel" };
	if #queue > 0 then
		session.outgoing_stanza_queue = {};
		for i=1,#queue do
			local reply = st.reply(queue[i]);
			if reply.attr.to ~= session.full_jid then
				reply.attr.type = "error";
				reply:tag("error", error_attr)
					:tag("recipient-unavailable", {xmlns = "urn:ietf:params:xml:ns:xmpp-stanzas"});
				core_process_stanza(session, reply);
			end
		end
	end
end

module:hook("pre-resource-unbind", function (event)
	local session, err = event.session, event.error;
	if session.smacks then
		if not session.resumption_token then
			local queue = session.outgoing_stanza_queue;
			if #queue > 0 then
				module:log("warn", "Destroying session with %d unacked stanzas", #queue);
				handle_unacked_stanzas(session);
			end
		else
			session.log("debug", "mod_smacks hibernating session for up to %d seconds", resume_timeout);
			local hibernate_time = os_time(); -- Track the time we went into hibernation
			session.hibernating = hibernate_time;
			local resumption_token = session.resumption_token;
			timer.add_task(resume_timeout, function ()
				session.log("debug", "mod_smacks hibernation timeout reached...");
				-- We need to check the current resumption token for this resource
				-- matches the smacks session this timer is for in case it changed
				-- (for example, the client may have bound a new resource and
				-- started a new smacks session, or not be using smacks)
				local curr_session = full_sessions[session.full_jid];
				if false and session.destroyed then
					session.log("debug", "The session has already been destroyed");
				elseif curr_session and curr_session.resumption_token == resumption_token
				-- Check the hibernate time still matches what we think it is,
				-- otherwise the session resumed and re-hibernated.
				and session.hibernating == hibernate_time then
					session.log("debug", "Destroying session for hibernating too long");
					session_registry[session.resumption_token] = nil;
					session.resumption_token = nil;
					sessionmanager.destroy_session(session);
				else
					session.log("debug", "Session resumed before hibernation timeout, all is well")
				end
			end);
			return true; -- Postpone destruction for now
		end

	end
end);

function handle_resume(session, stanza, xmlns_sm)
	if session.full_jid then
		session.log("warn", "Tried to resume after resource binding");
		session.send(st.stanza("failed", { xmlns = xmlns_sm })
			:tag("unexpected-request", { xmlns = xmlns_errors })
		);
		return true;
	end

	local id = stanza.attr.previd;
	local original_session = session_registry[id];
	if not original_session then
		session.log("debug", "Tried to resume non-existent session with id %s", id);
		session.send(st.stanza("failed", { xmlns = xmlns_sm })
			:tag("item-not-found", { xmlns = xmlns_errors })
		);
	elseif session.username == original_session.username
	and session.host == original_session.host then
		session.log("debug", "mod_smacks resuming existing session...");
		-- TODO: All this should move to sessionmanager (e.g. session:replace(new_session))
		if original_session.conn then
			session.log("debug", "mod_smacks closing an old connection for this session");
			local conn = original_session.conn;
			c2s_sessions[conn] = nil;
			conn:close();
		end
		original_session.ip = session.ip;
		original_session.conn = session.conn;
		original_session.send = session.send;
		original_session.stream = session.stream;
		original_session.secure = session.secure;
		original_session.hibernating = nil;
		local filter = original_session.filter;
		local stream = session.stream;
		local log = session.log;
		function original_session.data(data)
			data = filter("bytes/in", data);
			if data then
				local ok, err = stream:feed(data);
				if ok then return; end
				log("debug", "Received invalid XML (%s) %d bytes: %s", tostring(err), #data, data:sub(1, 300):gsub("[\r\n]+", " "):gsub("[%z\1-\31]", "_"));
				original_session:close("xml-not-well-formed");
			end
		end
		wrap_session(original_session, true, xmlns_sm);
		-- Inform xmppstream of the new session (passed to its callbacks)
		stream:set_session(original_session);
		-- Similar for connlisteners
		c2s_sessions[session.conn] = original_session;

		session.send(st.stanza("resumed", { xmlns = xmlns_sm,
			h = original_session.handled_stanza_count, previd = id }));

		-- Fake an <a> with the h of the <resume/> from the client
		original_session:dispatch_stanza(st.stanza("a", { xmlns = xmlns_sm,
			h = stanza.attr.h }));

		-- Ok, we need to re-send any stanzas that the client didn't see
		-- ...they are what is now left in the outgoing stanza queue
		local queue = original_session.outgoing_stanza_queue;
		for i=1,#queue do
			session.send(queue[i]);
		end
	else
		module:log("warn", "Client %s@%s[%s] tried to resume stream for %s@%s[%s]",
			session.username or "?", session.host or "?", session.type,
			original_session.username or "?", original_session.host or "?", original_session.type);
		session.send(st.stanza("failed", { xmlns = xmlns_sm })
			:tag("not-authorized", { xmlns = xmlns_errors }));
	end
	return true;
end
module:hook_stanza(xmlns_sm2, "resume", function (session, stanza) return handle_resume(session, stanza, xmlns_sm2); end);
module:hook_stanza(xmlns_sm3, "resume", function (session, stanza) return handle_resume(session, stanza, xmlns_sm3); end);
