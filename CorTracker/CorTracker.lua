_addon.author  = 'HeavyBoots';
_addon.name    = 'CorTracker';
_addon.version = '1.0.1';

require 'common';
require 'ffxi.vanatime'


CorTracker =
{
    Player =  AshitaCore:GetDataManager():GetPlayer(),
    Party = AshitaCore:GetDataManager():GetParty(),
    Dice = require('CorTrackerDice'),
    VanaTime = ashita.ffxi.vanatime,
    ActiveRolls = T{},
    LastRoll = T{},
    AllRolls = T{},
    Config = T{},
    GetBuffDuration = {},
    GetRollOdds = {},
    GetRollValue = {},
    CreateRoll = {},
    Gui = require('CorTrackerGui'),
    Deepcopy = {},
};

----------------------------------------------------------------------------------------------------
-- func: GetBuffDuration
-- desc: Converts the buff timestamp to m:s.
----------------------------------------------------------------------------------------------------
local GetBuffDuration = function(raw_duration)
    return (os.difftime(raw_duration +300, CorTracker.VanaTime.get_raw_timestamp()))
end
CorTracker.GetBuffDuration = GetBuffDuration;

----------------------------------------------------------------------------------------------------
-- func: GetRollOdds
-- desc: Gets bust % and Double-Up suggestions.
----------------------------------------------------------------------------------------------------
local GetRollOdds = function()
    if (CorTracker.LastRoll.RollNumber == nil) then
        return;
    end
    -- create local variables
    local rollNumber = tonumber(CorTracker.LastRoll['RollNumber']);
    local e =
    {
        BustChance = 0,
        DoubleUp =
        {
            Safe = true,
            Moderate = true,
            Risky = true,
        },
    };
    if (rollNumber > 5 and rollNumber ~= 11) then
        e.BustChance = (rollNumber-5) * 16.67;
    elseif rollNumber == 11 then
        e.BustChance = 100;
    end
    -- loop dice data to get odds.
    for k, _ in pairs(CorTracker.Dice.RollOdds) do
        if (table.hasvalue(CorTracker.Dice.RollOdds[k]['dice'], CorTracker.LastRoll['RollName'])) then
            if (not table.hasvalue(CorTracker.Dice.RollOdds[k]['safe'], rollNumber)) then
                e.DoubleUp.Safe = false;
            end
            if (not table.hasvalue(CorTracker.Dice.RollOdds[k]['moderate'], rollNumber)) then
                e.DoubleUp.Moderate = false;
            end
            if (not table.hasvalue(CorTracker.Dice.RollOdds[k]['risky'], rollNumber)) then
                e.DoubleUp.Risky = false;
            end
        end
    end
    return e;
end
CorTracker.GetRollOdds = GetRollOdds;

---------------------------------------------------------------------------------------------------
-- func: GetRollValue
-- desc: Modifies bonus data if job is in party and halves roll if not main cor.
---------------------------------------------------------------------------------------------------
local GetRollValue = function()
    if (CorTracker.LastRoll['Die']['rolls'][CorTracker.LastRoll['RollNumber']] ~= nil) then
        local rollValue = CorTracker.LastRoll['Die']['rolls'][CorTracker.LastRoll['RollNumber']];
        print(rollValue)
        if (CorTracker.LastRoll['RollNumber'] > 11) then
            return CorTracker.LastRoll.Die.bust;
        else
            local value = tonumber(CorTracker.LastRoll['Die']['rolls'][CorTracker.LastRoll['RollNumber']]);
            for i = 0, 6 do
                if (CorTracker.Party:GetMemberMainJob(i) == CorTracker.LastRoll['Die'].Job) then
                    value = value + tonumber(CorTracker.LastRoll['Die'].bonus);
                    break
                end
            end
            if (CorTracker.Player:GetMainJob() ~= Jobs.Corsair) then
                value = value / 2
            end
            return value;
        end
    end
end
CorTracker.GetRollValue = GetRollValue;

---------------------------------------------------------------------------------------------------
-- func: CreateRollData
-- desc: Create dice data from last roll.
---------------------------------------------------------------------------------------------------
local CreateRoll = function()
    CorTracker.LastRoll.RollOdds = CorTracker.GetRollOdds();
    CorTracker.LastRoll.RollValue = CorTracker.GetRollValue();
    local rolltoadd = CorTracker.ActiveRolls[CorTracker.LastRoll.RollId];
    if (rolltoadd == nil or GetBuffDuration(rolltoadd.RollTimeStamp) < 200) then
        CorTracker.ActiveRolls[CorTracker.LastRoll.RollId] = CorTracker.LastRoll;
    else
        CorTracker.ActiveRolls[CorTracker.LastRoll.RollId].RollNumber = CorTracker.LastRoll.RollNumber;
        CorTracker.ActiveRolls[CorTracker.LastRoll.RollId].RollValue = CorTracker.LastRoll.RollValue;
        CorTracker.ActiveRolls[CorTracker.LastRoll.RollId].Targets = CorTracker.LastRoll.Targets;
        CorTracker.ActiveRolls[CorTracker.LastRoll.RollId].RollOdds = CorTracker.LastRoll.RollOdds;
    end
    return 'debug: uses CorTracker.LastRoll';
end
CorTracker.CreateRoll = CreateRoll;

---------------------------------------------------------------------------------------------------
-- func: deepcopy(orig)
-- desc: Creates a deep copy of a table.
---------------------------------------------------------------------------------------------------
local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
CorTracker.Deepcopy = deepcopy;

-------------------------------------------------------------------------------
-- ashita events
-------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- func: load
-- desc: Event called when the addon is being loaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('load', function()

end);

----------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Event called when the addon is being unloaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()

end);

----------------------------------------------------------------------------------------------------
-- func: render
-- desc: Event called when the addon is being rendered.
----------------------------------------------------------------------------------------------------
ashita.register_event('render', function()
    CorTrackerGui.GuiWindow:Draw(_addon.name)
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_text
-- desc: Event called when the addon is asked to handle an incoming chat line.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_text', function(mode, message, modifiedmode, modifiedmessage, blocked)
    if message ~= nil then
        local messageLowercase = message:lower();
        if messageLowercase:find('receives the effect of .* roll.') or
            messageLowercase:find('loses the effect of .* roll.') or
            messageLowercase:find('.* roll effect wears off.') or
            messageLowercase:find('double%-up') then
            return true;
        end
        return false;
    end
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Event called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, packet)
    -- zone clean up
    if (id == 0x0A) then
        CorTracker.ActiveRolls = {};
        CorTracker.LastRoll = {};
    elseif (id == 0x28) then
        local category = ashita.bits.unpack_be(packet, 82, 4);
        if category == 6 then
            local actor = struct.unpack('I', packet, 6);
            local rollNumber = ashita.bits.unpack_be(packet, 213, 17);
            if rollNumber and actor == CorTracker.Party:GetMemberServerId(0) then
                local roll_id = ashita.bits.unpack_be(packet, 86, 10);
                if (table.haskey(CorTracker.Dice.CorsairRoll_IDs,roll_id)) then
                    local target_count = struct.unpack('b', packet, 0x09 + 1);
                local offset = 150;
                local targets = {};
                CorTracker.Party = AshitaCore:GetDataManager():GetParty();
                for x = 1, target_count do
                    local charID = ashita.bits.unpack_be(packet, offset, 32);
                    offset = offset + 123;
                    for i = 0, 6 do
                        if CorTracker.Party:GetMemberName(i) ~= nil and CorTracker.Party:GetMemberServerId(i) == charID then
                            table.insert(targets,1,CorTracker.Party:GetMemberName(i))
                        end
                    end
                end
                local rollName = CorTracker.Dice.CorsairRoll_IDs[roll_id];
                CorTracker.LastRoll =
                {
                    RollTimeStamp = CorTracker.VanaTime.get_raw_timestamp(),
                    RollId = roll_id,
                    RollNumber = rollNumber,
                    Targets = targets,
                    RollName = rollName,
                    Die = CorTracker.Dice.CorsairRoll_Data[rollName],
                }
                local t =  deepcopy(CorTracker.LastRoll)
                table.insert(CorTracker.AllRolls, 1, t);
                CorTracker.CreateRoll();
                end
            end
        end
    end
return false
end);

---------------------------------------------------------------------------------------------------
-- func: command
-- desc: Event called when a command was entered.
---------------------------------------------------------------------------------------------------
ashita.register_event('command', function(command, ntype)
    -- Get the command arguments..
    local args = command:args();
    for _, v in pairs(args) do
        v = v:lower();
    end

    if (args[1] ~= '/cortracker') then
        return false;
    end
end);