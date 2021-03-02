--   prosody plugin path ~/.jitsi-meet-cfg/prosody/prosody-plugins-custom/mod_autolobby.lua
--   in docker-jitsi-meet project  ".env"  file
--    ENABLE_LOBBY=1
--    XMPP_MODULES=autolobby
--



local main_muc_component_config = module:get_option_string('main_muc');
if main_muc_component_config == nil then
    module:log('error', 'lobby not enabled missing main_muc config');
    return ;
end

local lobby_muc_component_config = module:get_option_string('lobby_muc');
if lobby_muc_component_config == nil then
    module:log('error', 'lobby not enabled missing lobby_muc config');
    return ;
end

local jid_split = require 'util.jid'.split;


module:log("warn","LOADED Lobby auto");

local lobby_muc_service;
local main_muc_service;



function attach_lobby_room(room)
    local node = jid_split(room.jid);
    local lobby_room_jid = node .. '@' .. lobby_muc_component_config;
    if not lobby_muc_service.get_room_from_jid(lobby_room_jid) then
        local new_room = lobby_muc_service.create_room(lobby_room_jid);
        -- set persistent the lobby room to avoid it to be destroyed
        -- there are cases like when selecting new moderator after the current one leaves
        -- which can leave the room with no occupants and it will be destroyed and we want to
        -- avoid lobby destroy while it is enabled
        new_room:set_persistent(true);
        module:log("warn","Lobby room jid = %s created __muc_mini__",lobby_room_jid);
        new_room.main_room = room;
        room._data.lobbyroom = new_room.jid;
        room:save(true);
        return true
    end
    return false
end


-- process a host module directly if loaded or hooks to wait for its load
function process_host_module(name, callback)
    local function process_host(host)
        if host == name then
            callback(module:context(host), host);
        end
    end

    if prosody.hosts[name] == nil then
        module:log('debug', 'No host/component found, will wait for it: %s', name)

        -- when a host or component is added
        prosody.events.add_handler('host-activated', process_host);
    else
        process_host(name);
    end
end

-- operates on already loaded lobby muc module
function process_lobby_muc_loaded(lobby_muc, host_module)
    module:log('debug', 'Lobby muc loaded 2');
    lobby_muc_service = lobby_muc;
end

-- process or waits to process the lobby muc component
process_host_module(lobby_muc_component_config, function(host_module, host)
    -- lobby muc component created
    module:log('info', 'Lobby component loaded - 2 %s', host);

    local muc_module = prosody.hosts[host].modules.muc;
    if muc_module then
        process_lobby_muc_loaded(muc_module, host_module);
    else
        module:log('debug', 'Will wait for muc to be available');
        prosody.hosts[host].events.add_handler('module-loaded', function(event)
            if (event.module == 'muc') then
                process_lobby_muc_loaded(prosody.hosts[host].modules.muc, host_module);
            end
        end);
    end
end);

-- process or waits to process the main muc component
process_host_module(main_muc_component_config, function(host_module, host)
    main_muc_service = prosody.hosts[host].modules.muc;


    host_module:hook("muc-occupant-joined", function(event)
        local room, stanza = event.room, event.stanza;

        module:log('warn', '-- ---- --- muc-occupant-joined: hook')

        local participant_count = 0;
        local actor;
        for _, occupant in room:each_occupant() do
            -- don't count jicofo's admin account (focus)

            module:log('warn', 'muc-occupant-joined: %s', occupant.nick)

            actor = occupant;
            if string.sub(occupant.nick,-string.len("/focus")) ~= "/focus" then
                participant_count = participant_count + 1;
                -- non focus
            end
        end

        -- if jicofo and 1 participant
        if participant_count == 1 then
            room._data.members_only = true; -- magic
            local lobby_created = attach_lobby_room(room);
            module:log('warn', 'muc-occupant-joined:lobbycreated: %s', lobby_created);
            room:save();
        end;

    end, 100);

end);







