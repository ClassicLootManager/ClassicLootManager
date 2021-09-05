local _, CLM = ...

-- Libs
local ScrollingTable = LibStub("ScrollingTable")
local AceGUI = LibStub("AceGUI-3.0")

-- local LIBS =  {
--     registry = LibStub("AceConfigRegistry-3.0"),
--     gui = LibStub("AceConfigDialog-3.0")
-- }
local LOG = CLM.LOG
local UTILS = CLM.UTILS
local MODULES = CLM.MODULES
local CONSTANTS = CLM.CONSTANTS

local POINT_CHANGE_REASON_DECAY = CONSTANTS.POINT_CHANGE_REASON.DECAY
local POINT_CHANGE_REASONS_ALL = CONSTANTS.POINT_CHANGE_REASONS.ALL

local GUI = CLM.GUI

-- local mergeDictsInline = UTILS.mergeDictsInline
-- local GetColorCodedClassDict = UTILS.GetColorCodedClassDict

local getGuidFromInteger = UTILS.getGuidFromInteger
local GetClassColor = UTILS.GetClassColor
local ColorCodeText = UTILS.ColorCodeText
-- local GetItemIdFromLink = UTILS.GetItemIdFromLink

local ProfileManager = MODULES.ProfileManager
local RosterManager = MODULES.RosterManager
-- local PointManager = MODULES.PointManager
local LedgerManager = MODULES.LedgerManager
local EventManager = MODULES.EventManager

local function ST_GetPointHistory(row)
    return row.cols[5].value
end

local RightClickMenu

local PointHistoryGUI = {}

local function InitializeDB(self)
    local db = MODULES.Database:GUI()
    if not db.point then
        db.point = { }
    end
    self.db = db.point
end

local function StoreLocation(self)
    self.db.location = { self.top:GetPoint() }
end

local function RestoreLocation(self)
    if self.db.location then
        self.top:SetPoint(self.db.location[3], self.db.location[4], self.db.location[5])
    end
end

function PointHistoryGUI:Initialize()
    InitializeDB(self)
    EventManager:RegisterEvent({"PLAYER_LOGOUT"}, (function(...) StoreLocation(self) end))
    self:Create()
    self:RegisterSlash()
    LedgerManager:RegisterOnUpdate(function(lag, uncommitted)
        if lag ~= 0 or uncommitted ~= 0 then return end
        self:Refresh(true)
    end)
    self.tooltip = CreateFrame("GameTooltip", "CLMPointHistoryGUIDialogTooltip", UIParent, "GameTooltipTemplate")

    RightClickMenu = CLM.UTILS.GenerateDropDownMenu({
        {
            title = "Remove selected",
            func = (function()
                local row = self.st:GetRow(self.st:GetSelection())
                if row then
                    local history = ST_GetPointHistory(row)
                    LedgerManager:Remove(history:Entry(), true)
                end
            end),
            trustedOnly = true,
            color = "cc0000"
        }
    }, CLM.MODULES.ACL:IsTrusted())

    self._initialized = true
end

local columns = {
    {name = "Reason",  width = 150},
    {name = "Date", width = 150, sort = ScrollingTable.SORT_DSC},
    {name = "Value",  width = 70},
    {name = "Awarded By",  width = 70},
}

local function CreatePointDisplay(self)
    -- Profile Scrolling Table
    local StandingsGroup = AceGUI:Create("SimpleGroup")
    StandingsGroup:SetLayout("Flow")
    StandingsGroup:SetHeight(500)
    StandingsGroup:SetWidth(600)
    -- Roster selector
    local RosterSelectorDropDown = AceGUI:Create("Dropdown")
    RosterSelectorDropDown:SetLabel("Select roster")
    RosterSelectorDropDown:SetCallback("OnValueChanged", function()
        self.requestRefreshProfiles = true
        self:Refresh()
    end)
    self.RosterSelectorDropDown = RosterSelectorDropDown
    StandingsGroup:AddChild(RosterSelectorDropDown)
    -- Profile selector
    local ProfileSearchBox = AceGUI:Create("EditBox")
    ProfileSearchBox:SetLabel("Search player")
    ProfileSearchBox:SetCallback("OnValueChanged", function()-- OnEnterPressed -- this is the accept event
        self:Refresh()
    end)
    self.ProfileSearchBox = ProfileSearchBox
    StandingsGroup:AddChild(ProfileSearchBox)
    -- Standings
    self.st = ScrollingTable:CreateST(columns, 25, 18, nil, StandingsGroup.frame)
    self.st:EnableSelection(true)
    self.st.frame:SetPoint("TOPLEFT", RosterSelectorDropDown.frame, "TOPLEFT", 0, -60)
    self.st.frame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    -- OnEnter handler -> on hover
    local OnEnterHandler = (function (rowFrame, cellFrame, data, cols, row, realrow, column, table, ...)
        local status = self.st.DefaultEvents["OnEnter"](rowFrame, cellFrame, data, cols, row, realrow, column, table, ...)
        local rowData = self.st:GetRow(realrow)
        if not rowData or not rowData.cols then return status end
        local tooltip = self.tooltip
        if not tooltip then return end
        tooltip:SetOwner(rowFrame, "ANCHOR_TOPRIGHT")
        local history = ST_GetPointHistory(rowData)
        local profiles = history:Profiles()
        local numProfiles = #profiles
        tooltip:AddDoubleLine("Affected players:", tostring(numProfiles))
        if not profiles or numProfiles == 0 then
            tooltip:AddLine("None")
        else
            local profilesInLine = 0
            local line = ""
            local separator = ", "
            local profilesLeft = numProfiles
            while (profilesLeft > 0) do
                local currentProfile = profiles[numProfiles - profilesLeft + 1]
                profilesLeft = profilesLeft - 1
                if profilesLeft == 0 then
                    separator = ""
                end
                line = line .. ColorCodeText(currentProfile:Name(), GetClassColor(currentProfile:Class()).hex) .. separator
                profilesInLine = profilesInLine + 1
                if profilesInLine >= 5 or profilesLeft == 0 then
                    tooltip:AddLine(line)
                    line = ""
                    profilesInLine = 0
                end
            end
        end
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
    -- OnClick handler
    local OnClickHandler = function(rowFrame, cellFrame, data, cols, row, realrow, column, table, button, ...)
        local rightButton = (button == "RightButton")
        local status = self.st.DefaultEvents["OnClick"](rowFrame, cellFrame, data, cols, row, realrow, column, table, rightButton and "LeftButton" or button, ...)
        if rightButton then
            ToggleDropDownMenu(1, nil, RightClickMenu, cellFrame, -20, 0)
        end
        return status
    end
    -- end
    self.st:RegisterEvents({
        OnEnter = OnEnterHandler,
        OnLeave = OnLeaveHandler,
        OnClick = OnClickHandler
    })
    return StandingsGroup
end

function PointHistoryGUI:Create()
    LOG:Trace("PointHistoryGUI:Create()")
    -- Main Frame
    local f = AceGUI:Create("Frame")
    f:SetTitle("Point History")
    f:SetStatusText("")
    f:SetLayout("Table")
    f:SetUserData("table", { columns = {0, 0}, alignV =  "top" })
    f:EnableResize(false)
    f:SetWidth(600)
    f:SetHeight(600)
    self.top = f
    UTILS.MakeFrameCloseOnEsc(f.frame, "CLM_PointHistory_GUI")
    self.requestRefreshProfiles = true
    f:AddChild(CreatePointDisplay(self))
    RestoreLocation(self)
    -- Hide by default
    f:Hide()
end
-- TODO: update the whole profile handling
function PointHistoryGUI:Refresh(visible)
    LOG:Trace("PointHistoryGUI:Refresh()")
    if not self._initialized then return end
    if visible and not self.top.frame:IsVisible() then return end
    self.st:ClearSelection()
    self:RefreshRosters()
    if self.requestRefreshProfiles then
        self:RefreshProfiles()
        self.requestRefreshProfiles = false
    end

    local roster = self:GetCurrentRoster()
    if roster == nil then return end
    local profile = self:SearchForProfiles()
    local isProfileHistory = (profile and roster:IsProfileInRoster(profile:GUID()))

    local pointList
    -- player loot
    if isProfileHistory then
        pointList = roster:GetProfilePointHistoryByGUID(profile:GUID())
    else -- raid loot
        pointList = roster:GetRaidPointHistory()
    end

    local rowId = 1
    local data = {}
    for _,history in ipairs(pointList) do
        local reason = history:Reason() or 0
        local value = tostring(history:Value())
        if reason == POINT_CHANGE_REASON_DECAY then
            value = value .. "%"
        end
        local awardedBy
        local creator = ProfileManager:GetProfileByGUID(getGuidFromInteger(history:Creator()))
        if creator then
            awardedBy = ColorCodeText(creator:Name(), GetClassColor(creator:Class()).hex)
        else
            awardedBy = "Unknown"
        end
        local row = {cols = {}}
        row.cols[1] = {value = POINT_CHANGE_REASONS_ALL[reason] or ""}
        row.cols[2] = {value = date("%Y/%m/%d %a %H:%M:%S", history:Timestamp())}
        row.cols[3] = {value = value}
        row.cols[4] = {value = awardedBy}
        row.cols[5] = {value = history}
        data[rowId] =  row
        rowId = rowId + 1
    end

    self.st:SetData(data)
end

function PointHistoryGUI:GetCurrentRoster()
    return RosterManager:GetRosterByUid(self.RosterSelectorDropDown:GetValue())
end

local function GetSearchList(input)
    return { strsplit(",", input or "") }
end

function PointHistoryGUI:SearchForProfiles()
    local searchList = GetSearchList(self.ProfileSearchBox:GetValue())
    return ProfileManager:SearchMultipleProfilesByName(searchList)
end

function PointHistoryGUI:RefreshRosters()
    LOG:Trace("PointHistoryGUI:RefreshRosters()")
    local rosters = RosterManager:GetRosters()
    local rosterUidMap = {}
    local rosterList = {}
    for name, roster in pairs(rosters) do
        rosterUidMap[roster:UID()] = name
        table.insert(rosterList, roster:UID())
    end
    self.RosterSelectorDropDown:SetList(rosterUidMap, rosterList)
    if not self.RosterSelectorDropDown:GetValue() then
        if #rosterList > 0 then
            self.RosterSelectorDropDown:SetValue(rosterList[1])
        end
    end
end

function PointHistoryGUI:RefreshProfiles()
    LOG:Trace("PointHistoryGUI:RefreshProfiles()")
    local roster = self:GetCurrentRoster()
    if not roster then return end
    local profiles = roster:Profiles()
    local profileNameMap = { ["-- History --"] = "-- History --"}
    local profileList = {"-- History --"}
    for _, GUID in ipairs(profiles) do
        local profile = ProfileManager:GetProfileByGUID(GUID)
        if profile then
            profileNameMap[profile:Name()] = profile:Name()
            table.insert(profileList, profile:Name())
        end
    end
    table.sort(profileList)
    -- self.ProfileSearchBox:SetList(profileNameMap, profileList)
    -- if not self.ProfileSearchBox:GetValue() then
    --     if #profileList > 0 then
    --         self.ProfileSearchBox:SetValue(profileList[1])
    --     end
    -- end
end


function PointHistoryGUI:Toggle()
    LOG:Trace("PointHistoryGUI:Toggle()")
    if not self._initialized then return end
    if self.top.frame:IsVisible() then
        self.top.frame:Hide()
    else
        self:Refresh()
        self.top.frame:Show()
    end
end

function PointHistoryGUI:RegisterSlash()
    local options = {
        history = {
            type = "execute",
            name = "Point History",
            desc = "Toggle point history window display",
            handler = self,
            func = "Toggle",
        }
    }
    MODULES.ConfigManager:RegisterSlash(options)
end

GUI.PointHistory = PointHistoryGUI