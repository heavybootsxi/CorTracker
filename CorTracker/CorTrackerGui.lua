require 'common'
require 'imguidef'

CorTrackerGui = {
    GuiWindow = {},
    RenderCurrentActivity = {}

};

local GuiVariables = {
    ['var_VisualPane'] = 0
};

----------------------------------------------------------------------------------------------------
-- func: ShowHelpMarker
-- desc: Shows a tooltip.
----------------------------------------------------------------------------------------------------
local function ShowHelpMarker(desc)
    imgui.TextDisabled('(?)');
    if (imgui.IsItemHovered()) then
        imgui.SetTooltip(desc);
    end
end

----------------------------------------------------------------------------------------------------
-- func: GuiWindow
-- desc: The main GUI window
----------------------------------------------------------------------------------------------------
local GuiWindow = {
    Draw = function(self, title)
        imgui.SetNextWindowSize(400, 400, ImGuiSetCond_FirstUseEver);
        imgui.Begin(title, true)
        -- Sets the next button color of ImGui based on the selected tab button.
        local function set_button_color(index)
            if (GuiVariables.var_VisualPane == index) then
                imgui.PushStyleColor(ImGuiCol_Button, 0.25, 0.69, 1.0, 0.8);
            else
                imgui.PushStyleColor(ImGuiCol_Button, 0.25, 0.69, 1.0, 0.1);
            end
        end
        -- Render the tabbed navigation buttons..
        set_button_color(0);
        if (imgui.Button('Current Activity')) then
            GuiVariables.var_VisualPane = 0;
        end
        imgui.PopStyleColor();
        imgui.SameLine();
        set_button_color(1);
        if (imgui.Button('PlaceHolder')) then
            GuiVariables.var_VisualPane = 1;
        end
        -- Render the gui panels..
        imgui.BeginGroup();
        switch(GuiVariables.var_VisualPane):caseof{
            [0] = function()
                CorTrackerGui.RenderCurrentActivity();
            end,
            [1] = function()
                -- render_keyitems_editor()
            end,
            [2] = function()
                -- render_savedlists_editor()
            end,
            [3] = function()
                -- render_configuration_editor()
            end,
            ['default'] = function()
                CorTrackerGui.RenderCurrentActivity();
            end
        };
        imgui.EndGroup();
        imgui.End();
    end

};
CorTrackerGui.GuiWindow = GuiWindow;

----------------------------------------------------------------------------------------------------
-- func: ConvertOddsBool
-- desc: Converts a bool to a roll suggestion
----------------------------------------------------------------------------------------------------
local ConvertOddsBool = function(bool)
    if (bool == false) then
        return 'Stay!'
    else
        return 'Double-Up!'
    end
end

----------------------------------------------------------------------------------------------------
-- func: RenderCurrentActivity
-- desc: Renders the current activity gui pane
----------------------------------------------------------------------------------------------------
local RenderCurrentActivity = function()
    imgui.PushStyleColor(ImGuiCol_Border, 0.25, 0.69, 1.0, 0.4);
    imgui.TextColored(1.0, 1.0, 0.4, 1.0, 'Active Rolls ');
    imgui.SameLine();
    ShowHelpMarker('time remaining | roll | value | bonus | description');
    imgui.BeginGroup();
    imgui.BeginChild('ActiveRolls', 0, 100 - imgui.GetItemsLineHeightWithSpacing(), true);
    local e = T {};
    for k, v in pairs(CorTracker.ActiveRolls) do
        if (CorTracker.ActiveRolls[k] ~= nil) then --this will never be nil lol
            local ts = CorTracker.GetBuffDuration(v['RollTimeStamp']);
            if (ts > 0 and v.RollNumber < 12) then
            --if (ts > 0 ) then
                local m = (ts / 60) % 60;
                local s = ((ts - (math.floor(ts / 60) * 60)));
                local string = string.format('%-22s', string.format("%01i:%02i", m, s) .. ' ' .. v['RollName']) ..
                                   string.format('%-3s', v['RollNumber']);
                if (table.hasvalue(CorTracker.Dice.PercentageRolls, v['RollName'])) then
                    string = string .. string.format('+%-7s', string.format('%.0f', v['RollValue']) .. '%');
                else
                    string = string .. string.format('+%-7s', v['RollValue']);
                end
                string = string .. v['Die']['desc'];
                table.insert(e, {
                    ['time'] = ts,
                    ['value'] = string
                });
            else
                CorTracker.ActiveRolls[k] = nil;
            end
        end
    end
    if (#e > 0) then
        table.sort(e, function(k1, k2)
            return k1['time'] < k2['time']
        end)
        for _, v in ipairs(e) do
            imgui.TextUnformatted(v['value']);
        end
    end
    imgui.EndChild();
    imgui.EndGroup();
    imgui.TextColored(1.0, 1.0, 0.4, 1.0, 'Roll Odds ');
    imgui.SameLine();
    ShowHelpMarker('(doube up timer) chance to bust %%\nplaystyle suggestions based on roll odds.\nsee CorTrackerDice.lua, \'RollOdds\' for details');
    imgui.BeginGroup();
    imgui.BeginChild('Odds', 0, 60 - imgui.GetItemsLineHeightWithSpacing(), true);
    if (CorTracker.LastRoll.RollTimeStamp ~= nil and CorTracker.LastRoll.RollNumber < 12 and CorTracker.ActiveRolls[CorTracker.LastRoll.RollId] ~= nil) then
        -- add check foir last roll in active
        local o = CorTracker.GetRollOdds();
        local doubleuptimer = os.difftime(CorTracker.ActiveRolls[CorTracker.LastRoll.RollId].RollTimeStamp + 45, CorTracker.VanaTime.get_raw_timestamp());
        if (o ~= nil and doubleuptimer > 0) then
            if (o.BustChance < 100 and CorTracker.LastRoll.RollNumber < 11) then
                local bustvar = tonumber(o.BustChance * .01 + .15);
                imgui.PushStyleColor(ImGuiCol_Text, bustvar, 1.0 - bustvar, 0.0, 1.0);
                imgui.TextUnformatted('('..doubleuptimer..') '..'Chance to Bust: ' .. o.BustChance .. '%');
                imgui.PopStyleColor();
                imgui.PushStyleColor(ImGuiCol_Text, 1.0, 1.0, 1.0, 1.0);
                imgui.TextUnformatted('Safe:' .. ConvertOddsBool(o.DoubleUp.Safe)..
                ' Moderate:' .. ConvertOddsBool(o.DoubleUp.Moderate)..
                ' Risky:' .. ConvertOddsBool(o.DoubleUp.Risky));
                imgui.PopStyleColor();
            end
    end
        end
    imgui.EndChild();
    imgui.EndGroup();
    imgui.TextColored(1.0, 1.0, 0.4, 1.0, 'Roll Targets ');
    imgui.SameLine();
    ShowHelpMarker('target count | target names in alphabetical order');
    imgui.BeginGroup();
    imgui.BeginChild('Players', 0, 45 - imgui.GetItemsLineHeightWithSpacing(), true);
    if (CorTracker.LastRoll.RollTimeStamp ~= nil and CorTracker.LastRoll.RollNumber < 12 and CorTracker.ActiveRolls[CorTracker.LastRoll.RollId]) then
        local t = CorTracker.LastRoll.Targets;
        table.sort(t);
        local doubleuptimer = os.difftime(CorTracker.ActiveRolls[CorTracker.LastRoll.RollId].RollTimeStamp + 45, CorTracker.VanaTime.get_raw_timestamp());
        if (t ~= nil and doubleuptimer > 0) then
            imgui.TextWrapped(table.count(t) .. ' ' .. table.concat(t,','));
        end
    end
    imgui.EndChild();
    imgui.EndGroup();
    imgui.BeginGroup();
    imgui.TextColored(1.0, 1.0, 0.4, 1.0, 'Roll Log ');
    imgui.SameLine();
    ShowHelpMarker('timestamp | roll | lucky/unlucky | roll number');
    imgui.BeginChild('RollLog', 0, 0, true);
    for _, v in pairs(CorTracker.AllRolls) do
        local rolllog = os.date('[%X] ',v.RollTimeStamp)
        rolllog = rolllog .. string.format('%-15s',v.RollName) .. string.format('%-7s', '[' .. v.Die.lucky .. '/' .. v.Die.unlucky .. '] ');
        rolllog = rolllog .. string.format('%-2s',v.RollNumber);
        if (v.RollNumber == 11) then
            rolllog = rolllog .. ' Jackpot!';
            imgui.PushStyleColor(ImGuiCol_Text, 0.39, 0.96, 0.13, 1.0);
        elseif (v.RollNumber == v.Die.lucky) then
            rolllog = rolllog .. ' Lucky!';
            imgui.PushStyleColor(ImGuiCol_Text, 0.0, 0.5, 0.0, 1.0);
        elseif (v.RollNumber == v.Die.unlucky) then
            rolllog = rolllog .. ' Unlucky!';
            imgui.PushStyleColor(ImGuiCol_Text, 1.0, 0.5, 0.5, 1.0);
        elseif (v.RollNumber > 11) then
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
CorTrackerGui.RenderCurrentActivity = RenderCurrentActivity;

return CorTrackerGui;
