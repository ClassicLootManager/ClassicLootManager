local _, CLM = ...

-- Libs
local ScrollingTable = LibStub("ScrollingTable")
local AceGUI = LibStub("AceGUI-3.0")

local LIBS =  {
    registry = LibStub("AceConfigRegistry-3.0"),
    gui = LibStub("AceConfigDialog-3.0")
}

local LOG = CLM.LOG
local UTILS = CLM.UTILS
local MODULES = CLM.MODULES
local CONSTANTS = CLM.CONSTANTS
local ACL = MODULES.ACL

local GUI = CLM.GUI

local mergeDictsInline = UTILS.mergeDictsInline
local GetColorCodedClassDict = UTILS.GetColorCodedClassDict
local Trim = UTILS.Trim

local ProfileManager = MODULES.ProfileManager
local RosterManager = MODULES.RosterManager
local PointManager = MODULES.PointManager
local LedgerManager = MODULES.LedgerManager
local EventManager = MODULES.EventManager
local RaidManager = MODULES.RaidManager

local FILTER_IN_RAID = 100
-- local FILTER_STANDBY = 102

local StandingsGUI = {}

local function InitializeDB(self)
    local db = MODULES.Database:GUI()
    if not db.standings then
        db.standings = { }
    end
    self.db = db.standings
end

local function StoreLocation(self)
    self.db.location = { self.top:GetPoint() }
end

local function RestoreLocation(self)
    if self.db.location then
        self.top:ClearAllPoints()
        self.top:SetPoint(self.db.location[3], self.db.location[4], self.db.location[5])
    end
end

function StandingsGUI:Initialize()
    InitializeDB(self)
    EventManager:RegisterWoWEvent({"PLAYER_LOGOUT"}, (function(...) StoreLocation(self) end))
    self.tooltip = CreateFrame("GameTooltip", "CLMStandingsListGUIDialogTooltip", UIParent, "GameTooltipTemplate")
    self:Create()
    self:RegisterSlash()
    self._initialized = true
    self.selectedRoster = 0
    LedgerManager:RegisterOnUpdate(function(lag, uncommitted)
        if lag ~= 0 or uncommitted ~= 0 then return end
        self:Refresh(true)
    end)

end

local function ST_GetName(row)
    return row.cols[1].value
end

local function ST_GetClass(row)
    return row.cols[3].value
end

local function ST_GetWeeklyGains(row)
    return row.cols[5].value
end

local function ST_GetWeeklyCap(row)
    return row.cols[6].value
end

local function GenerateUntrustedOptions(self)
    local filters = UTILS.ShallowCopy(GetColorCodedClassDict())
    filters[FILTER_IN_RAID] = UTILS.ColorCodeText("In Raid", "FFD100")
    -- filters[FILTER_STANDBY] = UTILS.ColorCodeText("Standby", "FFD100")
    return {
        filter_header = {
            type = "header",
            name = "Filtering",
            order = 0
        },
        filter_display = {
            name = "Filter",
            type = "multiselect",
            set = function(i, k, v) self.filterOptions[tonumber(k)] = v; self:Refresh() end,
            get = function(i, v) return self.filterOptions[tonumber(v)] end,
            values = filters,
            width = 0.49,
            disabled = function() return self.searchMethod and true or false end,
            order = 1
        },
        filter_search = {
            name = "Search",
            desc = "Search for player names. Separate multiple with a comma ','. Minimum 3 characters. Overrides filtering.",
            type = "input",
            set = (function(i, v)
                self.searchString = v
                if v and strlen(v) >= 3 then
                    local searchList = { strsplit(",", v) }
                    self.searchMethod = (function(playerName)
                        for _, searchString in ipairs(searchList) do
                            searchString = Trim(searchString)
                            if strlen(searchString) >= 3 then
                                searchString = ".*" .. strlower(searchString) .. ".*"
                                if(string.find(strlower(playerName), searchString)) then
                                    return true
                                end
                            end
                        end
                        return false
                    end)
                else
                    self.searchMethod = nil
                end
                self:Refresh()
            end),
            get = (function(i) return self.searchString end),
            width = "full",
            order = 4,
        },
        filter_select_all = {
            name = "All",
            desc = "Select all classes.",
            type = "execute",
            func = (function()
                for i=1,9 do
                    self.filterOptions[i] = true
                end
                self:Refresh(true)
            end),
            disabled = function() return self.searchMethod and true or false end,
            width = 0.55,
            order = 2,
        },
        filter_select_none = {
            name = "None",
            desc = "Clear all classes.",
            type = "execute",
            func = (function()
                for i=1,9 do
                    self.filterOptions[i] = false
                end
                self:Refresh(true)
            end),
            disabled = function() return self.searchMethod and true or false end,
            width = 0.55,
            order = 3,
        },
    }
end

local function GenerateManagerOptions(self)
    return {
        award_header = {
            type = "header",
            name = "Management",
            order = 10
        },
        award_dkp_value = {
            name = "Award DKP value",
            desc = "DKP value that will be awarded.",
            type = "input",
            set = function(i, v) self.awardValue = v end,
            get = function(i) return self.awardValue end,
            width = 0.6,
            pattern = CONSTANTS.REGEXP_FLOAT,
            order = 11
        },
        award_dkp_note = {
            name = "Note",
            desc = "Note to be added to award. Max 32 characters. It is recommended to not include date nor selected reason here. If you will input encounter ID it will be transformed into boss name.",
            type = "input",
            set = function(i, v) self.note = v end,
            get = function(i) return self.note end,
            width = 0.5,
            order = 12
        },
        award_reason = {
            name = "Reason",
            type = "select",
            values = CONSTANTS.POINT_CHANGE_REASONS.GENERAL,
            set = function(i, v) self.awardReason = v end,
            get = function(i) return self.awardReason end,
            order = 13
        },
        award_dkp = {
            name = "Award",
            desc = "Award DKP to selected players or everyone if none selected.",
            type = "execute",
            width = "full",
            func = (function(i)
                -- Award Value
                local awardValue = tonumber(self.awardValue)
                if not awardValue then LOG:Debug("StandingsGUI(Award): missing award value"); return end
                -- Reason
                local awardReason
                if self.awardReason and CONSTANTS.POINT_CHANGE_REASONS.GENERAL[self.awardReason] then
                    awardReason = self.awardReason
                else
                    LOG:Debug("StandingsGUI(Award): missing reason");
                    awardReason = CONSTANTS.POINT_CHANGE_REASON.MANUAL_ADJUSTMENT
                end
                -- Selected: roster, profiles
                local roster, profiles = self:GetSelected()
                if roster == nil then
                    LOG:Debug("StandingsGUI(Award): roster == nil")
                    return
                end
                if not profiles or #profiles == 0 then
                    LOG:Debug("StandingsGUI(Award): profiles == 0")
                    return
                end
                -- Roster award
                if #profiles == #roster:Profiles() then
                    PointManager:UpdateRosterPoints(roster, awardValue, awardReason, CONSTANTS.POINT_MANAGER_ACTION.MODIFY, false, self.note)
                elseif RaidManager:IsInActiveRaid() then
                    local raidAward = false
                    local raid = RaidManager:GetRaid()
                    if #profiles == #raid:Players() then
                        raidAward = true
                        for _, profile in ipairs(profiles) do
                            raidAward = raidAward and raid:IsPlayerInRaid(profile:GUID())
                        end
                    end
                    if raidAward then
                        PointManager:UpdateRaidPoints(raid, awardValue, awardReason, CONSTANTS.POINT_MANAGER_ACTION.MODIFY, self.note)
                    else
                        PointManager:UpdatePoints(roster, profiles, awardValue, awardReason, CONSTANTS.POINT_MANAGER_ACTION.MODIFY, self.note)
                    end
                else
                    PointManager:UpdatePoints(roster, profiles, awardValue, awardReason, CONSTANTS.POINT_MANAGER_ACTION.MODIFY, self.note)
                end
                -- Update points
                -- PointManager:UpdatePoints(roster, profiles, awardValue, awardReason, CONSTANTS.POINT_MANAGER_ACTION.MODIFY)
            end),
            confirm = true,
            order = 14
        },
        roster_players_header = {
            type = "header",
            name = "Players",
            order = 25
        },
        add_from_raid = {
            name = "Add from raid",
            desc = "Adds players from current raid to the roster. Creates profiles if not exists.",
            type = "execute",
            width = "full",
            func = (function()
                local roster, _ = self:GetSelected()
                if roster == nil then
                    LOG:Debug("StandingsGUI(Remove): roster == nil")
                    return
                end
                RosterManager:AddFromRaidToRoster(roster)
            end),
            confirm = true,
            order = 26
        },
        remove_from_roster = {
            name = "Remove from roster",
            desc = "Removes selected players from roster or everyone if none selected.",
            type = "execute",
            width = "full",
            func = (function(i)
                local roster, profiles = self:GetSelected()
                if roster == nil then
                    LOG:Debug("StandingsGUI(Remove): roster == nil")
                    return
                end
                if not profiles or #profiles == 0 then
                    LOG:Debug("StandingsGUI(Remove): profiles == 0")
                    return
                end
                RosterManager:RemoveProfilesFromRoster(roster, profiles)
            end),
            confirm = true,
            order = 27
        }
    }
end

local function GenerateOfficerOptions(self)
    return {
        decay_dkp_value = {
            name = "Decay DKP %",
            desc = "DKP % that will be decayed.",
            type = "input",
            set = function(i, v) self.decayValue = v end,
            get = function(i) return self.decayValue end,
            width = "half",
            pattern = CONSTANTS.REGEXP_FLOAT,
            order = 21
        },
        decay_negative = {
            name = "Negatives",
            desc = "Include players with negative standings.",
            type = "toggle",
            set = function(i, v) self.includeNegative = v end,
            get = function(i) return self.includeNegative end,
            width = "half",
            order = 22
        },
        decay_dkp = {
            name = "Decay",
            desc = "Execute decay for selected players or everyone if none selected.",
            type = "execute",
            width = "full",
            func = (function(i)
                -- Decay Value
                local decayValue = tonumber(self.decayValue)
                if not decayValue then LOG:Debug("StandingsGUI(Decay): missing decay value"); return end
                if decayValue > 100 or decayValue < 0 then LOG:Warning("Standings: Decay value should be between 0 and 100%"); return end
                -- Selected: roster, profiles
                local roster, profiles = self:GetSelected()
                if roster == nil then
                    LOG:Debug("StandingsGUI(Decay): roster == nil")
                    return
                end
                if not profiles or #profiles == 0 then
                    LOG:Debug("StandingsGUI(Decay): profiles == 0")
                    return
                end
                if #profiles == #roster:Profiles() then
                    PointManager:UpdateRosterPoints(roster, decayValue, CONSTANTS.POINT_CHANGE_REASON.DECAY, CONSTANTS.POINT_MANAGER_ACTION.DECAY, not self.includeNegative)
                else
                    local filter
                    if not self.includeNegative then
                        filter = (function(_roster, profile)
                            return (_roster:Standings(profile:GUID()) >= 0)
                        end)
                    end
                    roster, profiles = self:GetSelected(filter)
                    if not profiles or #profiles == 0 then
                        LOG:Debug("StandingsGUI(Decay): profiles == 0")
                        return
                    end
                    PointManager:UpdatePoints(roster, profiles, decayValue, CONSTANTS.POINT_CHANGE_REASON.DECAY, CONSTANTS.POINT_MANAGER_ACTION.DECAY)
                end
            end),
            confirm = true,
            order = 23
        }
    }
end

local function CreateManagementOptions(self, container)
    local ManagementOptions = AceGUI:Create("SimpleGroup")
    ManagementOptions:SetLayout("Flow")
    ManagementOptions:SetWidth(200)
    self.ManagementOptions = ManagementOptions
    self.filterOptions = {}
    self.searchString = ""
    self.searchMethod = nil
    self.decayValue = nil
    self.includeNegative = false
    self.awardValue = nil
    self.note = ""
    self.awardReason = CONSTANTS.POINT_CHANGE_REASON.MANUAL_ADJUSTMENT
    for _=1,9 do table.insert( self.filterOptions, true ) end
    self.filterOptions[100] = false
    self.filterOptions[101] = false
    self.filterOptions[102] = false
    local options = {
        type = "group",
        args = {}
    }
    mergeDictsInline(options.args, GenerateUntrustedOptions(self))
    if ACL:CheckLevel(CONSTANTS.ACL.LEVEL.ASSISTANT) then
        mergeDictsInline(options.args, GenerateManagerOptions(self))
    end
    if ACL:CheckLevel(CONSTANTS.ACL.LEVEL.MANAGER) then
        mergeDictsInline(options.args, GenerateOfficerOptions(self))
    end
    LIBS.registry:RegisterOptionsTable("clm_standings_gui_options", options)
    LIBS.gui:Open("clm_standings_gui_options", ManagementOptions)
    self.st:SetFilter((function(stobject, row)
        local isInRaid = {}

        local playerName = ST_GetName(row)
        local class = ST_GetClass(row)

        -- Check Search first, discard others
        if self.searchMethod then
            return self.searchMethod(playerName)
        end

        -- Check raid
        for i=1,MAX_RAID_MEMBERS do
            local name = GetRaidRosterInfo(i)
            if name then
                name = UTILS.RemoveServer(name)
                isInRaid[name] = true
            end
        end
        -- Check for standby filter
        -- FILTER_STANDBY = 102
        -- Check class filter

        local status
        for id, _class in pairs(GetColorCodedClassDict()) do
            if class == _class then
                status = self.filterOptions[id]
            end
        end
        if status == nil then return false end -- failsafe
        if self.filterOptions[FILTER_IN_RAID] then
            status = status and isInRaid[playerName]
        end
        return status
    end))

    return ManagementOptions
end

local function CreateStandingsDisplay(self)
    -- Profile Scrolling Table
    local columns = {
        {   name = "Name", width = 100 },
        {   name = "DKP", width = 100, sort = ScrollingTable.SORT_DSC, color = {r = 0.0, g = 0.93, b = 0.0, a = 1.0} },
        {   name = "Class", width = 100 },
        {   name = "Spec", width = 100 }
    }
    local StandingsGroup = AceGUI:Create("SimpleGroup")
    StandingsGroup:SetLayout("Flow")
    StandingsGroup:SetHeight(560)
    StandingsGroup:SetWidth(450)
    -- Roster selector
    local RosterSelectorDropDown = AceGUI:Create("Dropdown")
    RosterSelectorDropDown:SetLabel("Select roster")
    RosterSelectorDropDown:SetCallback("OnValueChanged", function() self:Refresh() end)
    self.RosterSelectorDropDown = RosterSelectorDropDown
    StandingsGroup:AddChild(RosterSelectorDropDown)
    -- Standings
    self.st = ScrollingTable:CreateST(columns, 25, 18, nil, StandingsGroup.frame, true)
    self.st:EnableSelection(true)
    self.st.frame:SetPoint("TOPLEFT", RosterSelectorDropDown.frame, "TOPLEFT", 0, -60)
    self.st.frame:SetBackdropColor(0.1, 0.1, 0.1, 0.1)

    -- OnEnter handler -> on hover
    local OnEnterHandler = (function (rowFrame, cellFrame, data, cols, row, realrow, column, table, ...)
        local status = self.st.DefaultEvents["OnEnter"](rowFrame, cellFrame, data, cols, row, realrow, column, table, ...)
        local rowData = self.st:GetRow(realrow)
        if not rowData or not rowData.cols then return status end
        local tooltip = self.tooltip
        if not tooltip then return end
        tooltip:SetOwner(rowFrame, "ANCHOR_TOPRIGHT")
        local weeklyGain = ST_GetWeeklyGains(rowData)
        local weeklyCap = ST_GetWeeklyCap(rowData)
        tooltip:AddLine("Weekly gains:")
        local gains = weeklyGain
        if weeklyCap > 0 then
            gains = gains .. " / " .. weeklyCap
        end
        tooltip:AddLine(gains)
        tooltip:Show()
        return status
    end)
    -- OnLeave handler -> on hover out
    local OnLeaveHandler = (function (rowFrame, cellFrame, data, cols, row, realrow, column, table, ...)
        local status = self.st.DefaultEvents["OnLeave"](rowFrame, cellFrame, data, cols, row, realrow, column, table, ...)
        self.tooltip:Hide()
        return status
    end)
    -- end
    self.st:RegisterEvents({
        OnEnter = OnEnterHandler,
        OnLeave = OnLeaveHandler
    })

    return StandingsGroup
end

function StandingsGUI:Create()
    LOG:Trace("StandingsGUI:Create()")
    -- Main Frame
    local f = AceGUI:Create("Frame")
    f:SetTitle("Rosters")
    f:SetStatusText("")
    f:SetLayout("Table")
    f:SetUserData("table", { columns = {0, 0}, alignV =  "top" })
    f:EnableResize(false)
    f:SetWidth(700)
    f:SetHeight(685)
    self.top = f
    UTILS.MakeFrameCloseOnEsc(f.frame, "CLM_Rosters_GUI")
    f:AddChild(CreateStandingsDisplay(self))
    f:AddChild(CreateManagementOptions(self))
    RestoreLocation(self)
    -- Hide by default
    f:Hide()
end

function StandingsGUI:Refresh(visible)
    LOG:Trace("StandingsGUI:Refresh()")
    if not self._initialized then return end
    if visible and not self.top:IsVisible() then return end
    self.st:ClearSelection()
    self:RefreshRosters()

    local roster = self:GetCurrentRoster()
    if not roster then return end
    local weeklyCap = roster:GetConfiguration("weeklyCap")
    local rowId = 1
    local data = {}
    for GUID,value in pairs(roster:Standings()) do
        local profile = ProfileManager:GetProfileByGUID(GUID)
        if profile then
            local row = {cols = {}}
            row.cols[1] = {value = profile:Name()}
            row.cols[2] = {value = value}
            row.cols[3] = {value = UTILS.ColorCodeClass(profile:Class())}
            row.cols[4] = {value = profile:SpecString()}
            -- not displayed
            row.cols[5] = {value = roster:GetCurrentGainsForPlayer(GUID)}
            row.cols[6] = {value = weeklyCap}
            data[rowId] = row
            rowId = rowId + 1
        end
    end
    self.st:SetData(data)
    LIBS.gui:Open("clm_standings_gui_options", self.ManagementOptions)
    self.top:SetStatusText(tostring(#data or 0) .. " players in roster")
end

function StandingsGUI:GetCurrentRoster()
    self.db.selectedRosterUid = self.RosterSelectorDropDown:GetValue()
    return RosterManager:GetRosterByUid(self.db.selectedRosterUid)
end

function StandingsGUI:GetSelected(filter)
    if type(filter) ~= "function" then
        filter = (function(roster, profile) return profile end)
    end
    -- Roster
    local roster = self:GetCurrentRoster()
    if not roster then
        return nil, nil
    end
    -- Profiles
    local selected = self.st:GetSelection()
    local profiles = {}
    if #selected == 0 then -- nothing selected: assume all visible are selected
        selected = self.st:DoFilter()
    end
    for _,s in pairs(selected) do
        local profile = ProfileManager:GetProfileByName(ST_GetName(self.st:GetRow(s)))
        if profile then
            table.insert(profiles, profile)
        else
            LOG:Debug("No profile for %s", ST_GetName(self.st:GetRow(s)))
        end
    end
    local profiles_filtered = {}
    for _, profile in ipairs(profiles) do
        if filter(roster, profile) then
            table.insert(profiles_filtered, profile)
        end
    end
    return roster, profiles_filtered
end

function StandingsGUI:RefreshRosters()
    LOG:Trace("StandingsGUI:RefreshRosters()")
    local rosters = RosterManager:GetRosters()
    local rosterUidMap = {}
    local rosterList = {}
    local positionOfSavedRoster = 1
    local n = 1
    for name, roster in pairs(rosters) do
        rosterUidMap[roster:UID()] = name
        rosterList[n] = roster:UID()
        if roster:UID() == self.db.selectedRosterUid then
            positionOfSavedRoster = n
        end
        n = n + 1
    end
    self.RosterSelectorDropDown:SetList(rosterUidMap, rosterList)
    if not self.RosterSelectorDropDown:GetValue() then
        if #rosterList > 0 then
            self.RosterSelectorDropDown:SetValue(rosterList[positionOfSavedRoster])
        end
    end
end

function StandingsGUI:Toggle()
    LOG:Trace("StandingsGUI:Toggle()")
    if not self._initialized then return end
    if self.top:IsVisible() then
        self.top:Hide()
    else
        self.filterOptions[FILTER_IN_RAID] = IsInRaid() and true or false
        self:Refresh()
        self.top:Show()
    end
end

function StandingsGUI:RegisterSlash()
    local options = {
        standings = {
            type = "execute",
            name = "Standings",
            desc = "Toggle standings window display",
            handler = self,
            func = "Toggle",
        }
    }
    MODULES.ConfigManager:RegisterSlash(options)
end

function StandingsGUI:Reset()
    LOG:Trace("StandingsGUI:Reset()")
    self.top:ClearAllPoints()
    self.top:SetPoint("CENTER", 0, 0)
end

GUI.Standings = StandingsGUI
