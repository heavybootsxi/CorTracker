--[[
* 
*
* This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
* To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/ or send a letter to
* Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
*
* By using Ashita, you agree to the above license and its terms.
*
*      Attribution - You must give appropriate credit, provide a link to the license and indicate if changes were
*                    made. You must do so in any reasonable manner, but not in any way that suggests the licensor
*                    endorses you or your use.
*
*   Non-Commercial - You may not use the material (Ashita) for commercial purposes.
*
*   No-Derivatives - If you remix, transform, or build upon the material (Ashita), you may not distribute the
*                    modified material. You are, however, allowed to submit the modified works back to the original
*                    Ashita project in attempt to have it added to the original project.
*
* You may not apply legal terms or technological measures that legally restrict others
* from doing anything the license permits.
*
* No warranties are given.
*
* Thanks:
* * atom0s     https://github.com/atom0s
* * thorny     https://github.com/ThornyFFXI
* * heals      https://github.com/Shirk
* * daniel_h   https://github.com/DanielHazzard
]]
--

_addon.author  = 'HeavyBoots';
_addon.name    = 'CorTracker';
_addon.version = '2.0.0';

require 'common';
require 'imguidef'
require 'helpers.Dice';
require 'ffxi.vanatime';
require 'ffxi.enums';

CorTracker = {
    player = AshitaCore:GetDataManager():GetPlayer(),
    party = {},
    lastDiceRoll = T {},
    activeDiceRolls = T {},
    rollHistory = T {},
    rollHistoryGraph = T {},
    dice = Dice,
    gui = {
        window = {},
        renderCurrentActivity = {},
        renderGraph = {},
        variables = {
            ['var_visualPane'] = 0
        },
    },
}

local config = {
    font = {
        family = 'Arial',
        size = 16,
        color = 0xFFFFFFFF,
        position = { 0, 0 },
        bgcolor = 0x80000000,
        bgvisible = true
    },
    shortText = false,
    gui = true,
};

local state = {
    active = false,
    settings = config,
};

-------------------------------------------------------------------------------
-- local functions
-------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- func: deepcopy(orig)
-- desc: Returns a deep copy of a table.
---------------------------------------------------------------------------------------------------
local function deepcopy(orig)
    local orig_type = type(orig);
    local copy;
    if orig_type == 'table' then
        copy = {};
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value);
        end
        setmetatable(copy, deepcopy(getmetatable(orig)));
    else -- number, string, boolean, etc
        copy = orig;
    end
    return copy;
end

---------------------------------------------------------------------------------------------------
-- func: sortRollTable(tbl)
-- desc: Returns a roll table sorted by timestamp
---------------------------------------------------------------------------------------------------
local function sortRollTable(tbl)
    local a = T {};

    for _, v in pairs(tbl) do
        table.insert(a, {
            roll = v,
            timeStamp = v.timeStamp,
        });
    end

    table.sort(a, function(k1, k2)
        return k1.timeStamp < k2.timeStamp;
    end);

    return a;
end

----------------------------------------------------------------------------------------------------
-- func: getRollDuration
-- desc: Compares roll timestamp to vana timestamp
----------------------------------------------------------------------------------------------------
local getRollDuration = function(rollTimeStamp)
    local ts = ((rollTimeStamp + 300)) - ashita.ffxi.vanatime.get_raw_timestamp();
    local h = (ts / 3600) % 24;
    local m = (ts / 60) % 60;
    local s = ((ts - (math.floor(ts / 60) * 60)));
    --print(string.format('%02i:%02i:%02i',h, m, s));
    return ts;

    -- TODO: figure out correct duration
    --local d = rollTimeStamp + 300 - os.time()
    --return d
end

----------------------------------------------------------------------------------------------------
-- func: getRollOdds
-- desc: Gets bust % and Double-Up suggestions.
----------------------------------------------------------------------------------------------------
local getRollOdds = function(lastDiceRoll)
    local e =
    {
        bustChance = 0,
        doubleUp =
        {
            safe = true,
            moderate = true,
            risky = true,
        },
    };

    if (lastDiceRoll.rollNumber > 5 and lastDiceRoll.rollNumber ~= 11) then
        e.bustChance = (lastDiceRoll.rollNumber - 5) * 16.67;
    elseif lastDiceRoll.rollNumber == 11 then
        e.bustChance = 100;
    end

    local rollName = Dice.corsairRollIDs[lastDiceRoll.rollId]

    for k, _ in pairs(Dice.rollOdds) do
        if (table.hasvalue(Dice.rollOdds[k].dice, rollName)) then
            if (not table.hasvalue(Dice.rollOdds[k].safe, lastDiceRoll.rollNumber)) then
                e.doubleUp.safe = false;
            end
            if (not table.hasvalue(Dice.rollOdds[k].moderate, lastDiceRoll.rollNumber)) then
                e.doubleUp.moderate = false;
            end
            if (not table.hasvalue(Dice.rollOdds[k].risky, lastDiceRoll.rollNumber)) then
                e.doubleUp.risky = false;
            end
        end
    end
    return e;
end

---------------------------------------------------------------------------------------------------
-- func: getRollValue
-- desc: Modifies bonus data if job is in party and halves roll if not main cor.
---------------------------------------------------------------------------------------------------
local getRollValue = function(lastDiceRoll)
    if (lastDiceRoll.rollNumber > 11) then
        return lastDiceRoll.die.bust;
    end

    local value = tonumber(lastDiceRoll.die.rolls[lastDiceRoll.rollNumber]);

    for i = 0, 6 do
        if (CorTracker.party:GetMemberMainJob(i) == lastDiceRoll.die.job) then
            value = value + tonumber(lastDiceRoll.die.bonus);
        end
    end

    if (CorTracker.player:GetMainJob() ~= Jobs.Corsair) then
        value = value / 2
    end
    return value;
end

---------------------------------------------------------------------------------------------------
-- func: updateActiveRolls
-- desc: Adds or updates the last roll to the active rolls.
---------------------------------------------------------------------------------------------------
local updateActiveRolls = function(lastDiceRoll)
    if CorTracker == nil then
        return;
    end
    local newActiveRoll = CorTracker.activeDiceRolls[lastDiceRoll.rollId];
    if (newActiveRoll == nil) then
        CorTracker.activeDiceRolls[lastDiceRoll.rollId] = lastDiceRoll;
    elseif (CorTracker.activeDiceRolls[lastDiceRoll.rollId].timeRemaining < 200) then
        CorTracker.activeDiceRolls[lastDiceRoll.rollId] = lastDiceRoll;
    else
        CorTracker.activeDiceRolls[lastDiceRoll.rollId].rollNumber = lastDiceRoll.rollNumber;
        CorTracker.activeDiceRolls[lastDiceRoll.rollId].rollValue = lastDiceRoll.rollValue;
        CorTracker.activeDiceRolls[lastDiceRoll.rollId].targets = lastDiceRoll.targets;
        CorTracker.activeDiceRolls[lastDiceRoll.rollId].rollOdds = lastDiceRoll.rollOdds;
    end
end

---------------------------------------------------------------------------------------------------
-- func: createRollData
-- desc: Create dice data from last roll.
---------------------------------------------------------------------------------------------------
local createRollData = function(lastDiceRoll)
    if (lastDiceRoll == nil) then
        return;
    end

    lastDiceRoll.die = Dice.corsairRollData[Dice.corsairRollIDs[lastDiceRoll.rollId]];
    lastDiceRoll.rollOdds = getRollOdds(lastDiceRoll);
    lastDiceRoll.rollValue = getRollValue(lastDiceRoll);
end

---------------------------------------------------------------------------------------------------
-- func: manageActiveDiceRolls
-- desc: Manages dice in teh active roll table
---------------------------------------------------------------------------------------------------
local manageActiveDiceRolls = function()
    if CorTracker == nil then
        return;
    end
    for k, roll in pairs(CorTracker.activeDiceRolls) do
        local timeRemaining = getRollDuration(roll.timeStamp);
        if (timeRemaining < 225 or roll.rollNumber >= 12) then
            if not (table.hasvalue(CorTracker.rollHistoryGraph, CorTracker.activeDiceRolls[k])) then
                table.insert(CorTracker.rollHistoryGraph, CorTracker.activeDiceRolls[k])
            end
        end
        if (timeRemaining <= 0 or roll.rollNumber >= 12) then
            CorTracker.activeDiceRolls[k] = nil;
        else
            CorTracker.activeDiceRolls[k].timeRemaining = timeRemaining;
        end
    end
end

---------------------------------------------------------------------------------------------------
-- func: manageDisplayText
-- desc: Manages the various text displays
---------------------------------------------------------------------------------------------------
local manageDisplayText = function()
    if CorTracker == nil then
        return;
    end
    for _, roll in pairs(CorTracker.activeDiceRolls) do
        local m = (roll.timeRemaining / 60) % 60;
        local s = ((roll.timeRemaining - (math.floor(roll.timeRemaining / 60) * 60)));

        -------------------------------------------------------------------------------
        -- shortText
        -------------------------------------------------------------------------------
        roll.shortText       = string.format("%01i:%02i", m, s) ..
            ' ' .. Dice.corsairRollIDs[roll.rollId] .. ' ' .. roll.rollNumber;

        -------------------------------------------------------------------------------
        -- activeRollsText
        -------------------------------------------------------------------------------
        roll.activeRollsText = string.format('%-22s',
                string.format("%01i:%02i", m, s) .. ' ' .. Dice.corsairRollIDs[roll.rollId])
            .. string.format('%-3s', roll.rollNumber);

        if (table.hasvalue(Dice.percentageRolls, Dice.corsairRollIDs[roll.rollId])) then
            roll.activeRollsText = roll.activeRollsText ..
                string.format('+%-7s', string.format('%.0f', roll.rollValue) .. '%');
        else
            roll.activeRollsText = roll.activeRollsText .. string.format('+%-7s', roll.rollValue);
        end

        roll.activeRollsText = roll.activeRollsText .. roll.die.desc;
    end
end

-------------------------------------------------------------------------------
-- gui functions
-------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- func: showHelpMarker
-- desc: Shows a tooltip.
----------------------------------------------------------------------------------------------------
local showHelpMarker = function(desc)
    imgui.TextDisabled('(?)');
    if (imgui.IsItemHovered()) then
        imgui.SetTooltip(desc);
    end
end

----------------------------------------------------------------------------------------------------
-- func: convertOddsBool
-- desc: Converts a bool to a roll suggestion
----------------------------------------------------------------------------------------------------
local convertOddsBool = function(bool)
    if (bool == false) then
        return 'Stay!'
    else
        return 'Double-Up!'
    end
end

----------------------------------------------------------------------------------------------------
-- func: GuiWindow
-- desc: The main GUI window
----------------------------------------------------------------------------------------------------
CorTracker.gui.window = {
    Draw = function(self, title)
        imgui.SetNextWindowSize(400, 400, ImGuiSetCond_FirstUseEver);
        imgui.Begin(title, true)

        local function set_button_color(index)
            if (CorTracker.gui.variables.var_visualPane == index) then
                imgui.PushStyleColor(ImGuiCol_Button, 0.25, 0.69, 1.0, 0.8);
            else
                imgui.PushStyleColor(ImGuiCol_Button, 0.25, 0.69, 1.0, 0.1);
            end
        end

        set_button_color(0);
        if (imgui.Button('Current Activity')) then
            CorTracker.gui.variables.var_visualPane = 0;
        end

        imgui.PopStyleColor();
        imgui.SameLine();

        set_button_color(1);
        if (imgui.Button('Trends')) then
            CorTracker.gui.variables.var_visualPane = 1;
        end

        imgui.PopStyleColor();

        imgui.BeginGroup();
        switch(CorTracker.gui.variables.var_visualPane):caseof {
            [0] = function()
                CorTracker.gui.renderCurrentActivity();
            end,
            [1] = function()
                CorTracker.gui.renderGraph();
            end,
            [2] = function()
                --
            end,
            [3] = function()
                --
            end,
            ['default'] = function()
                CorTracker.gui.renderCurrentActivity();
            end
        };
        imgui.EndGroup();
        imgui.End();
    end
}

----------------------------------------------------------------------------------------------------
-- func: renderCurrentActivity
-- desc: Renders the current activity gui pane
----------------------------------------------------------------------------------------------------
CorTracker.gui.renderCurrentActivity = function()
    imgui.PushStyleColor(ImGuiCol_Border, 0.25, 0.69, 1.0, 0.4);
    imgui.TextColored(1.0, 1.0, 0.4, 1.0, 'Active Rolls ');

    imgui.SameLine();
    showHelpMarker('time remaining | roll | value | bonus | description');

    imgui.BeginGroup();
    imgui.BeginChild('ActiveRolls', 0, 100 - imgui.GetItemsLineHeightWithSpacing(), true);

    if (table.count(CorTracker.activeDiceRolls) ~= 0) then
        local e = sortRollTable(CorTracker.activeDiceRolls);

        for k, _ in ipairs(e) do
            imgui.TextUnformatted(e[k].roll.activeRollsText);
        end
    end

    imgui.EndChild();
    imgui.EndGroup();

    imgui.TextColored(1.0, 1.0, 0.4, 1.0, 'Roll Odds ');
    imgui.SameLine();
    showHelpMarker(
        '(doube up timer) chance to bust %%\nplaystyle suggestions based on roll odds.\nsee CorTrackerDice.lua, \'RollOdds\' for details');

    imgui.BeginGroup();
    imgui.BeginChild('Odds', 0, 60 - imgui.GetItemsLineHeightWithSpacing(), true);

    if (CorTracker.activeDiceRolls[CorTracker.lastDiceRoll.rollId] ~= nil) then
        local dblUpTimer = os.difftime(
            CorTracker.activeDiceRolls[CorTracker.lastDiceRoll.rollId].timeStamp + 45,
            ashita.ffxi.vanatime.get_raw_timestamp());

        local bustChance = CorTracker.lastDiceRoll.rollOdds.bustChance;

        if (dblUpTimer > 0 and bustChance < 100 and CorTracker.lastDiceRoll.rollNumber < 11) then
            local bustvar = tonumber(bustChance * .01 + .15);

            imgui.PushStyleColor(ImGuiCol_Text, bustvar, 1.0 - bustvar, 0.0, 1.0);
            imgui.TextUnformatted('(' .. dblUpTimer .. ') ' .. 'Chance to Bust: ' .. bustChance .. '%');

            imgui.PopStyleColor();
            imgui.PushStyleColor(ImGuiCol_Text, 1.0, 1.0, 1.0, 1.0);

            imgui.TextUnformatted('Safe:' .. convertOddsBool(CorTracker.lastDiceRoll.rollOdds.doubleUp.safe) ..
            ' Moderate:' .. convertOddsBool(CorTracker.lastDiceRoll.rollOdds.doubleUp.moderate) ..
            ' Risky:' .. convertOddsBool(CorTracker.lastDiceRoll.rollOdds.doubleUp.risky));

            imgui.PopStyleColor();
        end
    end
    imgui.EndChild();
    imgui.EndGroup();

    imgui.TextColored(1.0, 1.0, 0.4, 1.0, 'Roll Targets ');
    imgui.SameLine();
    showHelpMarker('target count | target names in alphabetical order');

    imgui.BeginGroup();
    imgui.BeginChild('Players', 0, 45 - imgui.GetItemsLineHeightWithSpacing(), true);

    if (CorTracker.activeDiceRolls[CorTracker.lastDiceRoll.rollId] ~= nil) then
        table.sort(CorTracker.lastDiceRoll.targets)

        imgui.TextWrapped(table.count(CorTracker.lastDiceRoll.targets) ..
        ' ' .. table.concat(CorTracker.lastDiceRoll.targets, ','));
    end

    imgui.EndChild();
    imgui.EndGroup();

    imgui.BeginGroup();
    imgui.TextColored(1.0, 1.0, 0.4, 1.0, 'Roll Log ');

    imgui.SameLine();
    showHelpMarker('timestamp | roll | lucky/unlucky | roll number');

    imgui.BeginChild('RollLog', 0, 0, true);

    for _, roll in pairs(CorTracker.rollHistory) do
        local rolllog = os.date('[%X] ', roll.timeStamp);
        rolllog = rolllog ..
            string.format('%-15s', Dice.corsairRollIDs[roll.rollId]) ..
            string.format('%-7s', '[' .. roll.die.lucky .. '/' .. roll.die.unlucky .. '] ');
        rolllog = rolllog .. string.format('%-2s', roll.rollNumber);

        if (roll.rollNumber == 11) then
            rolllog = rolllog .. ' Jackpot!';
            imgui.PushStyleColor(ImGuiCol_Text, 0.39, 0.96, 0.13, 1.0);
        elseif (roll.rollNumber == roll.die.lucky) then
            rolllog = rolllog .. ' Lucky!';
            imgui.PushStyleColor(ImGuiCol_Text, 0.0, 0.5, 0.0, 1.0);
        elseif (roll.rollNumber == roll.die.unlucky) then
            rolllog = rolllog .. ' Unlucky!';
            imgui.PushStyleColor(ImGuiCol_Text, 1.0, 0.5, 0.5, 1.0);
        elseif (roll.rollNumber > 11) then
            rolllog = rolllog .. ' Bust!';
            imgui.PushStyleColor(ImGuiCol_Text, 1.0, 0.0, 0.0, 1.0);
        else
            imgui.PushStyleColor(ImGuiCol_Text, 1.0, 1.0, 1.0, 1.0);
        end

        imgui.TextUnformatted(rolllog);
        imgui.PopStyleColor();
    end

    imgui.EndChild();
    imgui.EndGroup();
end
--CorTracker.gui.renderCurrentActivity = renderCurrentActivity;

----------------------------------------------------------------------------------------------------
-- func: renderGraph
-- desc: Renders the roll graph
----------------------------------------------------------------------------------------------------
CorTracker.gui.renderGraph = function()
    imgui.PushStyleColor(ImGuiCol_PlotHistogram, 0.77, 0.83, 0.80, 0.3);

    local test = T {};

    for k, v in pairs(CorTracker.rollHistoryGraph) do
        local roll = deepcopy(v);
        if (roll.rollNumber > 11) then
            roll.rollNumber = 0;
        end
        if (test[Dice.corsairRollIDs[roll.rollId]] == nil) then
            test[Dice.corsairRollIDs[roll.rollId]] = T {};
        end
        table.insert(test[Dice.corsairRollIDs[roll.rollId]], roll.rollNumber);
    end

    for k, v in pairs(test) do
        local sum = 0
        for _, n in pairs(v) do
            sum = sum + n
        end
        local avg = tostring(sum / #v)
        imgui.PlotHistogram(k, v, #v, 0, avg, 0, 11, 200, 50);
    end
end
-------------------------------------------------------------------------------
-- ashita events
-------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- func: load
-- desc: Event called when the addon is being loaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
    state.settings = ashita.settings.load_merged(_addon.path .. 'settings/settings.json', state.settings);

    local f = AshitaCore:GetFontManager():Create('__CorTracker_addon');
    f:SetColor(state.settings.font.color);
    f:SetFontFamily(state.settings.font.family);
    f:SetFontHeight(state.settings.font.size);
    f:SetBold(false);
    f:SetPositionX(state.settings.font.position[1]);
    f:SetPositionY(state.settings.font.position[2]);
    f:SetVisibility(true);
    f:GetBackground():SetColor(state.settings.font.bgcolor);
    f:GetBackground():SetVisibility(state.settings.font.bgvisible);
    state.font = f;
end);

----------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Event called when the addon is being unloaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()
    AshitaCore:GetFontManager():Delete(state.font:GetAlias());
end);

---------------------------------------------------------------------------------------------------
-- func: command
-- desc: Event called when a command is entered.
---------------------------------------------------------------------------------------------------
ashita.register_event('command', function(command, ntype)
    local args = command:args();

    if (args[1] ~= '/cortracker') then
        return false;
    end

    if (args[2] == 'test') then
        print('rolls ' .. #CorTracker.activeDiceRolls)
        return true;
    end
    return false;
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_text
-- desc: Event called when the addon is asked to handle an incoming chat line.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_text', function(mode, message, modifiedmode, modifiedmessage, blocked)
    if message ~= nil then
        --if (CorTracker.Settings.ModChatLog) then
        local messageLowercase = message:lower();
        if messageLowercase:find('receives the effect of .* roll.') or
            messageLowercase:find('loses the effect of .* roll.') or
            messageLowercase:find('.* roll effect wears off.') or
            messageLowercase:find('double%-up') then
            return true;
        end
        --end
        return false;
    end
    return false;
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Event called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, packet)
    -- zone clean up (0x00A)
    if (id == 0x00A) then
        state.Active = false;
    elseif (id == 0x028) then --TODO: comment this packet and sub items.
        local category = ashita.bits.unpack_be(packet, 82, 4);
        if category == 6 then
            local actor = struct.unpack('I', packet, 6);
            local rollNumber = ashita.bits.unpack_be(packet, 213, 17);
            if rollNumber and actor == CorTracker.party:GetMemberServerId(0) then
                local rollId = ashita.bits.unpack_be(packet, 86, 10);
                if (table.haskey(Dice.corsairRollIDs, rollId)) then
                    local targetCount = struct.unpack('b', packet, 0x09 + 1);
                    local offset = 150;
                    local targets = {};
                    CorTracker.party = AshitaCore:GetDataManager():GetParty();
                    for x = 1, targetCount do
                        local charID = ashita.bits.unpack_be(packet, offset, 32);
                        offset = offset + 123;
                        for i = 1, 6 do
                            if CorTracker.party:GetMemberName(i) ~= nil and CorTracker.party:GetMemberServerId(i) == charID then
                                table.insert(targets, 1, CorTracker.party:GetMemberName(i));
                            end
                        end
                    end

                    CorTracker.lastDiceRoll = {
                        timeStamp = ashita.ffxi.vanatime.get_raw_timestamp(),
                        rollId = rollId,
                        rollNumber = rollNumber,
                        targets = targets,
                    }
                    createRollData(CorTracker.lastDiceRoll);
                    updateActiveRolls(CorTracker.lastDiceRoll)
                    table.insert(CorTracker.rollHistory, 1, deepcopy(CorTracker.lastDiceRoll))
                end
            end
        end
    end
    return false;
end);

----------------------------------------------------------------------------------------------------
-- func: render
-- desc: Event called when the addon is being rendered.
----------------------------------------------------------------------------------------------------
ashita.register_event('render', function()
    CorTracker.party = AshitaCore:GetDataManager():GetParty();
    if (state.font:GetPositionX() ~= state.settings.font.position[1]) or (state.font:GetPositionY() ~= state.settings.font.position[2]) then
        state.settings.font.position[1] = state.font:GetPositionX();
        state.settings.font.position[2] = state.font:GetPositionY();
        ashita.settings.save(_addon.path .. 'settings/settings.json', state.settings);
    end

    manageActiveDiceRolls();
    manageDisplayText();

    if (table.count(CorTracker.activeDiceRolls) ~= 0 and config.shortText == true) then
        local displayText = T {};
        local e = sortRollTable(CorTracker.activeDiceRolls);

        for k, _ in ipairs(e) do
            table.insert(displayText, e[k].roll.shortText);
        end

        state.font:SetText(displayText:concat('\n'));
        state.font:SetVisibility(true);
    else
        state.active = false;
        state.font:SetVisibility(false);
    end

    if (config.gui == true) then
        CorTracker.gui.window:Draw(_addon.name);
    end
end);
