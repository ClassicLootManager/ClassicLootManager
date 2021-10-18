local _, CLM = ...

local LOG = CLM.LOG
local MODULES = CLM.MODULES
local CONSTANTS = CLM.CONSTANTS

local ACL = MODULES.ACL
local PointManager = MODULES.PointManager
local RaidManager = MODULES.RaidManager
local EventManager = MODULES.EventManager

local HYDROSS_ENCOUNTER_ID = 623
local HYDROSS_ENCOUNTER_NAME = "Hydross the Unstable"
local HYDROSS_NPC_ID = 21216

local RAID_AWARD_LEDGER_CLASS = "DR"

local function handleEncounterStart(self, addon, event, id, name, difficulty, groupSize)
    LOG:Info("[%s %s]: <%s, %s, %s, %s, %s>", addon, event, id, name, difficulty, groupSize)
    if self:IsEnabled() and self:IsBossKillBonusAwardingEnabled() and not self:EncounterInProgress() then
        self.encounterInProgress = id
    end
end

local function handleEncounterEnd(self, addon, event, id, name, difficulty, groupSize, success)
    LOG:Info("[%s %s]: <%s, %s, %s, %s, %s>", addon, event, id, name, difficulty, groupSize, success)
    if self:IsEnabled() and self:IsBossKillBonusAwardingEnabled() and self:EncounterInProgress() then
        if self.encounterInProgress == id then
            if RaidManager:IsInActiveRaid() and success == 1 then
                local roster = RaidManager:GetRaid():Roster()
                if roster:GetConfiguration("bossKillBonus") then
                    local value = roster:GetBossKillBonusValue(id)
                    if value > 0 then
                        PointManager:UpdateRaidPoints(RaidManager:GetRaid(), value, CONSTANTS.POINT_CHANGE_REASON.BOSS_KILL_BONUS, CONSTANTS.POINT_MANAGER_ACTION.MODIFY)
                    end
                end
            end
            self.encounterInProgress = 0
        end
    end
end

local function handleHydrossWorkaround(self, addon, event)
    if self:IsEnabled() and self:IsBossKillBonusAwardingEnabled() and (self.encounterInProgress == HYDROSS_ENCOUNTER_ID) then
        local _, subevent, _, _, _, _, _, guid, _   = CombatLogGetCurrentEventInfo()
        if subevent == "UNIT_DIED" then
            local _, _, _, _, _, npc_id = strsplit("-", guid)
            if tonumber(npc_id) == HYDROSS_NPC_ID then
                handleEncounterEnd(self, addon, "ENCOUNTER_END", HYDROSS_ENCOUNTER_ID, HYDROSS_ENCOUNTER_NAME, 176, 25, 1)
            end
        end
    end
end

local function handleIntervalBonus(self)
    LOG:Trace("AutoAwardManager handleIntervalBonus()")
    if not IsInRaid() then return end
    if not self:IsEnabled() then return end
    if not self:IsIntervalBonusAwardingEnabled() then return end
    if not RaidManager:IsInProgressingRaid() then return end
    -- Validate roster
    local raid = RaidManager:GetRaid()
    local roster = raid:Roster()
    if not roster then
        LOG:Warning("No roster in raid for handleIntervalBonus()")
        return
    end
    -- Validate settings
    if not roster:GetConfiguration("intervalBonus") then return end
    local interval = roster:GetConfiguration("intervalBonusTime")
    if interval <= 0 then return end
    local value = roster:GetConfiguration("intervalBonusValue")
    if value <= 0 then return end
    interval = interval * 60 -- minutes in seconds
    local now = GetServerTime()
    local pointHistory = roster:GetRaidPointHistory()
    local award = true
    -- Check if at least interval passed since raid start
    if now - raid:StartTime() < interval then return end
    -- Check History
    for _,pointHistoryEntry in ipairs(pointHistory) do
        -- If we are already so deep in history we missed the interval
        if now - pointHistoryEntry:Timestamp() >= interval then 
            break
        end
        -- Check for raid awards
        if pointHistoryEntry:Type() == CONSTANTS.POINT_HISTORY_SOURCE.RAID_AWARD then
            if pointHistoryEntry:Extra() == raid:UID() then
                award = false
                break
            end
        end
    end
    if award then
        PointManager:UpdateRaidPoints(raid, value, CONSTANTS.POINT_CHANGE_REASON.INTERVAL_BONUS, CONSTANTS.POINT_MANAGER_ACTION.MODIFY)
    end
end

local AutoAwardManager = {}
function AutoAwardManager:Initialize()
    LOG:Trace("AutoAwardManager:Initialize()")
    if not ACL:IsTrusted() then return end
    self.enabled = false
    self:DisableBossKillBonusAwarding()
    self:DisableIntervalBonusAwarding()
    EventManager:RegisterWoWEvent({"ENCOUNTER_START"}, (function(...)
        handleEncounterStart(self, ...)
    end))
    EventManager:RegisterWoWEvent({"ENCOUNTER_END"}, (function(...)
        handleEncounterEnd(self, ...)
    end))
    -- Hydross workaround
    EventManager:RegisterWoWEvent({"COMBAT_LOG_EVENT_UNFILTERED"}, (function(...)
        handleHydrossWorkaround(self, ...)
    end))
    MODULES.ConfigManager:RegisterUniversalExecutor("aam", "AutoAwardManager", self)
end

function AutoAwardManager:Enable()
    LOG:Trace("AutoAwardManager:Enable()")
    self.enabled = true
end

function AutoAwardManager:Disable()
    LOG:Trace("AutoAwardManager:Disable()")
    self.enabled = false
end

function AutoAwardManager:IsEnabled()
    LOG:Trace("AutoAwardManager:IsEnabled()")
    return self.enabled
end

function AutoAwardManager:EncounterInProgress()
    LOG:Trace("AutoAwardManager:EncounterInProgress()")
    return (self.encounterInProgress ~= 0)
end

function AutoAwardManager:EnableBossKillBonusAwarding()
    LOG:Trace("AutoAwardManager:EnableBossKillBonusAwarding()")
    self.bossKillBonusAwardingEnabled = true
end

function AutoAwardManager:DisableBossKillBonusAwarding()
    LOG:Trace("AutoAwardManager:DisableBossKillBonusAwarding()")
    self.encounterInProgress = 0
    self.bossKillBonusAwardingEnabled = false
end

function AutoAwardManager:IsBossKillBonusAwardingEnabled()
    LOG:Trace("AutoAwardManager:IsBossKillBonusAwardingEnabled()")
    return self.bossKillBonusAwardingEnabled
end

function AutoAwardManager:EnableIntervalBonusAwarding()
    LOG:Trace("AutoAwardManager:EnableIntervalBonusAwarding()")
    self.intervalBonusAwardingEnabled = true
    handleIntervalBonus(self) -- additional handle for cases of relogs / reloads if time has already passed
    if not self.intervalTimer then
        self.intervalTimer = C_Timer.NewTicker(60, function()
            handleIntervalBonus(self)
        end)
    end
end

function AutoAwardManager:DisableIntervalBonusAwarding()
    LOG:Trace("AutoAwardManager:DisableIntervalBonusAwarding()")
    self.intervalBonusAwardingEnabled = false
end

function AutoAwardManager:IsIntervalBonusAwardingEnabled()
    LOG:Trace("AutoAwardManager:IsIntervalBonusAwardingEnabled()")
    return self.intervalBonusAwardingEnabled
end

--@debug@
function AutoAwardManager:FakeEncounterStart()
    handleEncounterStart(self, "CLM", "ENCOUNTER_START", 123456, "Fake Encounter", 0, 25)
end

function AutoAwardManager:FakeEncounterSuccess()
    handleEncounterEnd(self, "CLM", "ENCOUNTER_END", 123456, "Fake Encounter", 0, 25, 1)
end

function AutoAwardManager:FakeEncounterFail()
    handleEncounterEnd(self, "CLM", "ENCOUNTER_END", 123456, "Fake Encounter", 0, 25, 0)
end
--@end-debug@

MODULES.AutoAwardManager = AutoAwardManager
