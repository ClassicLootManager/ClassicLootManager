-- ------------------------------- --
local  _, CLM = ...
-- ------ CLM common cache ------- --
local LOG       = CLM.LOG
local CONSTANTS = CLM.CONSTANTS
local UTILS     = CLM.UTILS
-- ------------------------------- --

local RosterManager = {}
function RosterManager:GenerateName()
    local prefix = CONSTANTS.ROSTER_NAME_GENERATOR.PREFIX[math.random(1, #CONSTANTS.ROSTER_NAME_GENERATOR.PREFIX)]
    local suffix = CONSTANTS.ROSTER_NAME_GENERATOR.SUFFIX[math.random(1, #CONSTANTS.ROSTER_NAME_GENERATOR.SUFFIX)]
    return UTILS.capitalize(prefix).. " " .. UTILS.capitalize(suffix)
end

local function initializePoints(entry, roster, GUID)
    local basePoints = roster:GetConfiguration("basePoints")
    if basePoints > 0 then
        roster:SetStandings(GUID, basePoints)
        CLM.MODULES.PointManager:AddFakePointHistory(roster, { GUID }, basePoints, CONSTANTS.POINT_CHANGE_REASON.ROSTER_JOIN, entry:time(), entry:creatorFull(), nil, CONSTANTS.POINT_CHANGE_TYPE.POINTS)
    end
    if roster:GetPointType() == CONSTANTS.POINT_TYPE.EPGP then
        local baseSpent = roster:GetConfiguration("baseSpent")
        if baseSpent > 0 then
            roster:UpdateSpent(GUID, baseSpent)
            CLM.MODULES.PointManager:AddFakePointHistory(roster, { GUID }, baseSpent, CONSTANTS.POINT_CHANGE_REASON.ROSTER_JOIN, entry:time(), entry:creatorFull(), nil, CONSTANTS.POINT_CHANGE_TYPE.SPENT)
        end
    end
end

-- Controller Roster Manger
function RosterManager:Initialize()
    LOG:Trace("RosterManager:Initialize()")

    -- Initialize Cache
    self.cache = {
        rostersUidMap = {},
        rosters = {}
    }

    -- Register mutators
    CLM.MODULES.LedgerManager:RegisterEntryType(
        CLM.MODELS.LEDGER.ROSTER.Create,
        (function(entry)
            LOG:TraceAndCount("mutator(RosterCreate)")
            local uid = entry:rosterUid()
            local name = entry:name()
            local pointType = entry:pointType()
            if self.cache.rosters[name] or self.cache.rostersUidMap[uid] then
                LOG:Debug("Roster [%s:%s] already exists. Verify data integrity with other officers.", name, uid)
                return
            end
            if not (pointType and CONSTANTS.POINT_TYPES[pointType] ~= nil) then return end
            local roster = CLM.MODELS.Roster:New(uid, pointType, self.db.raidsForFullAttendance, self.db.attendanceWeeksWindow)
            if self.db.displayTooltipConfig[uid] == nil then
                self.db.displayTooltipConfig[uid] = true
            end
            self.cache.rosters[name] = roster
            self.cache.rostersUidMap[uid] = name
        end))

    CLM.MODULES.LedgerManager:RegisterEntryType(
        CLM.MODELS.LEDGER.ROSTER.Delete,
        (function(entry)
            LOG:TraceAndCount("mutator(RosterDelete)")
            local uid = entry:rosterUid()

            local roster = self:GetRosterByUid(uid)
            if not roster then
                LOG:Debug("Removing non-existent roster [%s]", uid)
                return
            end

            local name = self.cache.rostersUidMap[uid]
            self.cache.rostersUidMap[uid] = nil
            self.cache.rosters[name] = nil
        end))

    CLM.MODULES.LedgerManager:RegisterEntryType(
        CLM.MODELS.LEDGER.ROSTER.Rename,
        (function(entry)
            LOG:TraceAndCount("mutator(RosterRename)")
            local uid = entry:rosterUid()
            local name = entry:name()

            local o = self:GetRosterByUid(uid)
            if not o then
                LOG:Debug("Renaming non-existent roster [%s]", uid)
                return
            end
            local n = self:GetRosterByName(name)
            if n then
                LOG:Debug("Roster named [%s] already exists", name)
                return
            end

            local oldname = self.cache.rostersUidMap[uid]
            -- Attach roster to new name
            self.cache.rosters[name] = o
            self.cache.rostersUidMap[uid] = name

            -- Remove old assignments
            self.cache.rosters[oldname] = nil
        end))

    CLM.MODULES.LedgerManager:RegisterEntryType(
        CLM.MODELS.LEDGER.ROSTER.CopyData,
        (function(entry)
            LOG:TraceAndCount("mutator(RosterCopyData)")
            local sourceUid = entry:sourceRosterUid()
            local targetUid = entry:targetRosterUid()

            local s = self:GetRosterByUid(sourceUid)
            if not s then
                LOG:Debug("Copying from non-existent roster [%s]", sourceUid)
                return
            end
            local t = self:GetRosterByUid(targetUid)
            if not t then
                LOG:Debug("Copying to non-existent roster [%s]", targetUid)
                return
            end

            if entry:config() then
                t:CopyConfiguration(s)
            end

            if entry:defaults() then
                t:CopyDefaultSlotValues(s)
            end

            if entry:overrides() then
                t:CopyItemValues(s)
            end

            if entry:profiles() then
                t:CopyProfiles(s)
            end
        end))

    CLM.MODULES.LedgerManager:RegisterEntryType(
        CLM.MODELS.LEDGER.ROSTER.UpdateConfigSingle,
        (function(entry)
            LOG:TraceAndCount("mutator(RosterUpdateConfigSingle)")
            local rosterUid = entry:rosterUid()

            local roster = self:GetRosterByUid(rosterUid)
            if not roster then
                LOG:Debug("Updating non-existent roster [%s]", rosterUid)
                return
            end

            roster:SetConfiguration(entry:config(), entry:value())
        end))

    CLM.MODULES.LedgerManager:RegisterEntryType(
        CLM.MODELS.LEDGER.ROSTER.UpdateDefaultSingle,
        (function(entry)
            LOG:TraceAndCount("mutator(RosterUpdateDefaultSingle)")
            local rosterUid = entry:rosterUid()

            local roster = self:GetRosterByUid(rosterUid)
            if not roster then
                LOG:Debug("Updating non-existent roster [%s]", rosterUid)
                return
            end

            roster:SetDefaultSlotTierValue(entry:slot(), entry:tier(), entry:value())
        end))

    CLM.MODULES.LedgerManager:RegisterEntryType(
        CLM.MODELS.LEDGER.ROSTER.UpdateOverrides,
        (function(entry)
            LOG:TraceAndCount("mutator(RosterUpdateOverrides)")
            local rosterUid = entry:rosterUid()

            local roster = self:GetRosterByUid(rosterUid)
            if not roster then
                LOG:Debug("Updating non-existent roster [%s]", rosterUid)
                return
            end

            roster:SetItemValues(entry:itemId(), entry:values())
        end))

    CLM.MODULES.LedgerManager:RegisterEntryType(
        CLM.MODELS.LEDGER.ROSTER.UpdateOverridesSingle,
        (function(entry)
            LOG:TraceAndCount("mutator(RosterUpdateOverridesSingle)")
            local rosterUid = entry:rosterUid()

            local roster = self:GetRosterByUid(rosterUid)
            if not roster then
                LOG:Debug("Updating non-existent roster [%s]", rosterUid)
                return
            end

            roster:SetItemTierValue(entry:itemId(), entry:tier(), entry:value())
        end))
    CLM.MODULES.LedgerManager:RegisterEntryType(
        CLM.MODELS.LEDGER.ROSTER.RemoveOverrides,
        (function(entry)
            LOG:TraceAndCount("mutator(RemoveOverrides)")
            local rosterUid = entry:rosterUid()

            local roster = self:GetRosterByUid(rosterUid)
            if not roster then
                LOG:Debug("Updating non-existent roster [%s]", rosterUid)
                return
            end

            roster:ClearItemValues(entry:itemId())
        end))

    CLM.MODULES.LedgerManager:RegisterEntryType(
        CLM.MODELS.LEDGER.ROSTER.UpdateProfiles,
        (function(entry)
            LOG:TraceAndCount("mutator(RosterUpdateProfiles)")
            local rosterUid = entry:rosterUid()

            local roster = self:GetRosterByUid(rosterUid)
            if not roster then
                LOG:Debug("Updating non-existent roster [%s]", rosterUid)
                return
            end

            local profiles = entry:profiles()
            if not profiles or type(profiles) ~= "table" or #profiles == 0 then
                LOG:Debug("Empty profiles table in mutator(RosterUpdateProfiles)")
                return
            end

            if entry:remove() then
                for _, iGUID in ipairs(profiles) do
                    local GUID = UTILS.getGuidFromInteger(iGUID)
                    local profile = CLM.MODULES.ProfileManager:GetProfileByGUID(GUID)
                    if profile then
                        roster:RemoveProfileByGUID(GUID)
                        -- If it is a main with linked alts - remove all alts
                        if profile:HasAlts() then
                            for altGUID, _ in pairs(profile:Alts()) do
                                roster:RemoveProfileByGUID(altGUID)
                            end
                        end
                    end
                end
            else
                for _, iGUID in ipairs(profiles) do
                    local initialize = false
                    local GUID = UTILS.getGuidFromInteger(iGUID)
                    if not roster:IsProfileInRoster(GUID) then
                        initialize = true
                        roster:AddProfileByGUID(GUID)
                    end
                    local profile = CLM.MODULES.ProfileManager:GetProfileByGUID(GUID)
                    if profile then
                        -- If it is an alt of a linked main - set its standings and gains from main
                        if profile:Main() ~= "" then
                            -- add main in case it isnt there
                            if not roster:IsProfileInRoster(profile:Main()) then
                                roster:AddProfileByGUID(profile:Main())
                                initializePoints(entry, roster, profile:Main())
                            end
                            roster:MirrorStandings(profile:Main(), { GUID })
                            roster:MirrorWeeklyGains(profile:Main(), { GUID })
                            CLM.MODULES.PointManager:AddFakePointHistory(roster, { GUID }, roster:Standings(profile:Main()), CONSTANTS.POINT_CHANGE_REASON.LINKING_OVERRIDE, entry:time(), entry:creatorFull())
                        else
                            if initialize then
                                initializePoints(entry, roster, GUID)
                            end
                        end
                    end
                end
            end
        end))

    CLM.MODULES.LedgerManager:RegisterEntryType(
        CLM.MODELS.LEDGER.ROSTER.BossKillBonus,
        (function(entry)
            LOG:TraceAndCount("mutator(RosterBossKillBonus)")
            local rosterUid = entry:rosterUid()

            local roster = self:GetRosterByUid(rosterUid)
            if not roster then
                LOG:Debug("Updating non-existent roster [%s]", rosterUid)
                return
            end
            roster:SetBossKillBonusValue(entry:encounterId(), entry:difficultyId(), entry:isHardMode(), entry:value())
        end))

    CLM.MODULES.LedgerManager:RegisterEntryType(
        CLM.MODELS.LEDGER.ROSTER.FieldRename,
        (function(entry)
            LOG:TraceAndCount("mutator(RosterRenameField)")
            local rosterUid = entry:rosterUid()

            local roster = self:GetRosterByUid(rosterUid)
            if not roster then
                LOG:Debug("Updating non-existent roster [%s]", rosterUid)
                return
            end
            roster:SetFieldName(entry:tier(), entry:name())
        end))

    CLM.MODULES.LedgerManager:RegisterEntryType(
        CLM.MODELS.LEDGER.ROSTER.DynamicItemValueEquation,
        (function(entry)
            LOG:TraceAndCount("mutator(DynamicItemValueEquation)")
            local rosterUid = entry:rosterUid()

            local roster = self:GetRosterByUid(rosterUid)
            if not roster then
                LOG:Debug("Updating non-existent roster [%s]", rosterUid)
                return
            end

            roster:GetCalculator():SetEquation(entry:equation())
        end))

    CLM.MODULES.LedgerManager:RegisterEntryType(
        CLM.MODELS.LEDGER.ROSTER.AwardMultiplier,
        (function(entry)
            LOG:TraceAndCount("mutator(RosterAwardMultiplier)")
            local rosterUid = entry:rosterUid()

            local roster = self:GetRosterByUid(rosterUid)
            if not roster then
                LOG:Debug("Updating non-existent roster [%s]", rosterUid)
                return
            end

            roster:SetSlotClassMultiplierValue(UTILS.NumberToClass(entry:ingameClass()), entry:slot(), entry:value())
        end))

    CLM.MODULES.LedgerManager:RegisterEntryType(
        CLM.MODELS.LEDGER.ROSTER.DynamicItemValueExpvar,
        (function(entry)
            LOG:TraceAndCount("mutator(DynamicItemValueExpvar)")
            local rosterUid = entry:rosterUid()

            local roster = self:GetRosterByUid(rosterUid)
            if not roster then
                LOG:Debug("Updating non-existent roster [%s]", rosterUid)
                return
            end

            roster:GetCalculator():SetExpvar(entry:expvar())
        end))

    CLM.MODULES.LedgerManager:RegisterEntryType(
            CLM.MODELS.LEDGER.ROSTER.DynamicItemValueCustomExpression,
            (function(entry)
                LOG:TraceAndCount("mutator(DynamicItemValueCustomExpression)")
                local rosterUid = entry:rosterUid()

                local roster = self:GetRosterByUid(rosterUid)
                if not roster then
                    LOG:Debug("Updating non-existent roster [%s]", rosterUid)
                    return
                end
                local customExpression = entry:customExpression()
                if not ExpressionParser:IsValidExpression(customExpression, CONSTANTS.CUSTOM_EQUATION_VARIABLES) then
                    LOG:Error("Attempting to set invalid custom expression! [%s]", customExpression)
                    return
                else
                    roster:GetCalculator():SetCustomExpression(customExpression)
                end
            end))

    CLM.MODULES.LedgerManager:RegisterEntryType(
        CLM.MODELS.LEDGER.ROSTER.DynamicItemValueMultiplier,
        (function(entry)
            LOG:TraceAndCount("mutator(DynamicItemValueMultiplier)")
            local rosterUid = entry:rosterUid()

            local roster = self:GetRosterByUid(rosterUid)
            if not roster then
                LOG:Debug("Updating non-existent roster [%s]", rosterUid)
                return
            end

            roster:GetCalculator():SetMultiplier(entry:multiplier())
        end))

    CLM.MODULES.LedgerManager:RegisterEntryType(
        CLM.MODELS.LEDGER.ROSTER.DynamicItemValueSlotMultiplier,
        (function(entry)
            LOG:TraceAndCount("mutator(DynamicItemValueSlotMultiplier)")
            local rosterUid = entry:rosterUid()

            local roster = self:GetRosterByUid(rosterUid)
            if not roster then
                LOG:Debug("Updating non-existent roster [%s]", rosterUid)
                return
            end

            roster:GetCalculator():SetSlotMultiplier(entry:slot(), entry:multiplier())
        end))

    CLM.MODULES.LedgerManager:RegisterEntryType(
        CLM.MODELS.LEDGER.ROSTER.DynamicItemValueTierMultiplier,
        (function(entry)
            LOG:TraceAndCount("mutator(DynamicItemValueTierMultiplier)")
            local rosterUid = entry:rosterUid()

            local roster = self:GetRosterByUid(rosterUid)
            if not roster then
                LOG:Debug("Updating non-existent roster [%s]", rosterUid)
                return
            end

            roster:GetCalculator():SetTierMultiplier(entry:tier(), entry:multiplier())
        end))

    CLM.MODULES.LedgerManager:RegisterOnRestart(function()
        self:WipeAll()
    end)

    self.db = CLM.MODULES.Database:Personal('rosterManager', {
        raidsForFullAttendance = 2,
        attendanceWeeksWindow = 10,
        displayTooltipConfig = {}
    })

    local options = {
        attendance_header = {
            type = "header",
            name = CLM.L["Attendance"],
            order = 20
        },
        attendance_max = {
            name = CLM.L["Raids needed in reset"],
            desc = CLM.L["Provide number of raids needed for 100% attendance in a weekly reset. Between 1 - 50 raids. Defaults to 2. Requires /reload."],
            type = "range",
            min = 1,
            max = 50,
            softMin = 1,
            softMax = 10,
            step = 1,
            set = function(i, v)
                v = tonumber(v) or 1
                if v < 1 then v = 1 end
                if v > 50 then v = 50 end
                self.db.raidsForFullAttendance = v
            end,
            get = function(i) return self.db.raidsForFullAttendance end,
            order = 21
          },
          attendance_window = {
            name = CLM.L["Average weeks"],
            desc = CLM.L["Provide number of weeks that will be accounted for attendance. Between 1 - 1000 weeks. Defaults to 10. Requires /reload."],
            type = "range",
            min = 1,
            max = 1000,
            softMin = 1,
            softMax = 54,
            step = 1,
            set = function(i, v)
                v = tonumber(v) or 1
                if v < 1 then v = 1 end
                if v > 1000 then v = 1000 end
                self.db.attendanceWeeksWindow = v
            end,
            get = function(i) return self.db.attendanceWeeksWindow end,
            order = 22
          },
          export_rosters = {
            name = CLM.L["Select Rosters to display"],
            type = "multiselect",
            set = function(i, k, v)
                self.db.displayTooltipConfig[tonumber(k) or 0] = v
            end,
            get = function(i, k) return self.db.displayTooltipConfig[k] end,
            values = function()
                local roster_list = {}
                for uid, name in pairs(CLM.MODULES.RosterManager:GetRostersUidMap()) do
                    roster_list[uid] = name
                end
                return roster_list
            end,
            order = 902
        }
    }
    CLM.MODULES.ConfigManager:Register(CLM.CONSTANTS.CONFIGS.GROUP.GLOBAL, options)
end

function RosterManager:GetDisplayTooltip(rosterUid)
    return self.db.displayTooltipConfig[tonumber(rosterUid) or 0]
end

function RosterManager:GetRosters()
    return self.cache.rosters
end

function RosterManager:GetRostersUidMap()
    return self.cache.rostersUidMap
end

function RosterManager:GetRosterByName(name)
    return self.cache.rosters[name]
end

function RosterManager:GetRosterByUid(uid)
    return self.cache.rosters[self.cache.rostersUidMap[uid]]
end


function RosterManager:GetRosterNameByUid(uid)
    return self.cache.rostersUidMap[uid]
end

function RosterManager:NewRoster(pointType, name)
    LOG:Trace("RosterManager:NewRoster()")

    name = name or self:GenerateName()
    while self.cache.rosters[name] ~= nil do
        name = self:GenerateName()
    end

    local uid = GetServerTime()
    while self.cache.rostersUidMap[uid] ~= nil do
        uid = uid +  1
    end

    if not (pointType and CONSTANTS.POINT_TYPES[pointType] ~= nil) then
        LOG:Error("RosterManager:NewRoster(): Invalid point type")
        return
    end
    CLM.MODULES.LedgerManager:Submit(CLM.MODELS.LEDGER.ROSTER.Create:new(uid, name, pointType), true)
end

function RosterManager:DeleteRosterByName(name)
    LOG:Trace("RosterManager:DeleteRosterByName()")
    local roster = self:GetRosterByName(name)
    if not roster then
        LOG:Error("RosterManager:RenameRoster(): Unknown roster name %s", name)
        return
    end
    CLM.MODULES.LedgerManager:Submit(CLM.MODELS.LEDGER.ROSTER.Delete:new(roster:UID()), true)
end

function RosterManager:RenameRoster(old, new)
    LOG:Trace("RosterManager:RenameRoster()")
    local o = self:GetRosterByName(old)
    if not o then
        LOG:Error("RosterManager:RenameRoster(): Unknown roster name %s", old)
        return
    end
    local n = self:GetRosterByName(new)
    if n then
        LOG:Error("RosterManager:RenameRoster(): Roster with name %s already exists", new)
        return
    end

    CLM.MODULES.LedgerManager:Submit(CLM.MODELS.LEDGER.ROSTER.Rename:new(o:UID(), new), true)
end

function RosterManager:Copy(source, target, config, defaults, overrides, profiles)
    LOG:Trace("RosterManager:Copy()")
    local s = self:GetRosterByName(source)
    if not s then
        LOG:Error("RosterManager:Copy(): Unknown roster name %s", source)
        return
    end
    local t = self:GetRosterByName(target)
    if not t then
        LOG:Error("RosterManager:Copy(): Unknown roster name %s", target)
        return
    end

    CLM.MODULES.LedgerManager:Submit(CLM.MODELS.LEDGER.ROSTER.CopyData:new(s:UID(), t:UID(), config, defaults, overrides, profiles), true)
end

function RosterManager:SetRosterConfiguration(name, option, value)
    LOG:Trace("RosterManager:SetRosterConfiguration()")
    local roster = self:GetRosterByName(name)
    if not roster then
        LOG:Error("RosterManager:SetRosterConfiguration(): Unknown roster name %s", name)
        return
    end
    if not option then
        LOG:Error("RosterManager:SetRosterConfiguration(): Missing option")
        return
    end
    if value == nil then
        LOG:Error("RosterManager:SetRosterConfiguration(): Missing value")
        return
    end
    local current = roster:GetConfiguration(option)
    if current == nil then
        LOG:Error("RosterManager:SetRosterConfiguration(): Invalid option [%s]", option)
        return
    end
    if type(current) == "number" then
        value = tonumber(value)
    elseif type(current) == "string" then
        value = tostring(value)
    elseif type(current) == "boolean" then
        value = value and true or false
    end
    if value == nil then
        LOG:Fatal("RosterManager:SetRosterConfiguration(): Invalid value type")
        return
    end
    if current == value then
        LOG:Debug("RosterManager:SetRosterConfiguration(): No change to option [%s]. Skipping.", option)
        return
    end

    CLM.MODULES.LedgerManager:Submit(CLM.MODELS.LEDGER.ROSTER.UpdateConfigSingle:new(roster:UID(), option, value), true)
end

function RosterManager:SetRosterDefaultSlotTierValue(nameOrRoster, slot, tier, value)
    LOG:Trace("RosterManager:SetRosterDefaultSlotTierValue()")
    local roster
    if UTILS.typeof(nameOrRoster, CLM.MODELS.Roster) then
        roster = nameOrRoster
    else
        roster = self:GetRosterByName(nameOrRoster)
    end
    if not roster then
        LOG:Error("RosterManager:SetRosterDefaultSlotTierValue(): Invalid roster object or name")
        return nil
    end
    if not value then
        LOG:Error("RosterManager:SetRosterDefaultSlotTierValue(): Missing value")
        return
    end
    if not slot or not CONSTANTS.INVENTORY_TYPES_SET[slot] then
        LOG:Error("RosterManager:SetRosterDefaultSlotTierValue(): Missing slot")
        return
    end
    if not tier or not CONSTANTS.SLOT_VALUE_TIERS[tier] then
        LOG:Error("RosterManager:SetRosterDefaultSlotTierValue(): Missing tier")
        return
    end
    if roster:GetDefaultSlotTierValue(slot, tier) == tonumber(value) then
        LOG:Debug("RosterManager:SetRosterDefaultSlotTierValue(): No change to value. Skipping.")
        return
    end

    CLM.MODULES.LedgerManager:Submit(CLM.MODELS.LEDGER.ROSTER.UpdateDefaultSingle:new(roster:UID(), slot, tier, value), true)
end

function RosterManager:SetSlotClassMultiplierValue(nameOrRoster, class, slot, value)
    LOG:Trace("RosterManager:SetSlotClassMultiplierValue()")
    local roster
    if UTILS.typeof(nameOrRoster, CLM.MODELS.Roster) then
        roster = nameOrRoster
    else
        roster = self:GetRosterByName(nameOrRoster)
    end
    if not roster then
        LOG:Error("RosterManager:SetSlotClassMultiplierValue(): Invalid roster object or name")
        return nil
    end
    value = tonumber(value)
    if not value then
        LOG:Error("RosterManager:SetSlotClassMultiplierValue(): Missing value")
        return
    end
    if not slot or not CONSTANTS.INVENTORY_TYPES_SET[slot] then
        LOG:Error("RosterManager:SetSlotClassMultiplierValue(): Missing slot")
        return
    end
    if roster:GetSlotClassMultiplierValue(class, slot) == value then
        LOG:Debug("RosterManager:SetSlotClassMultiplierValue(): No change to value. Skipping.")
        return
    end

    CLM.MODULES.LedgerManager:Submit(CLM.MODELS.LEDGER.ROSTER.AwardMultiplier:new(roster:UID(), class, slot, value), true)
end

function RosterManager:SetRosterDynamicItemValueEquation(nameOrRoster, equation)
    LOG:Trace("RosterManager:SetRosterDynamicItemValueEquation()")
    local roster
    if UTILS.typeof(nameOrRoster, CLM.MODELS.Roster) then
        roster = nameOrRoster
    else
        roster = self:GetRosterByName(nameOrRoster)
    end
    if not equation or not CONSTANTS.ITEM_VALUE_EQUATIONS[equation] then
        LOG:Error("RosterManager:SetRosterDynamicItemValueEquation(): Missing equation")
        return
    end
    if roster:GetCalculator():GetEquation() == equation then
        LOG:Debug("RosterManager:SetRosterDynamicItemValueEquation(): No change to value. Skipping.")
        return
    end

    CLM.MODULES.LedgerManager:Submit(CLM.MODELS.LEDGER.ROSTER.DynamicItemValueEquation:new(roster:UID(), equation), true)
end

function RosterManager:SetRosterDynamicItemValueExpvar(nameOrRoster, expvar)
    LOG:Trace("RosterManager:SetRosterDynamicItemValueExpvar()")
    expvar = tonumber(expvar)
    local roster
    if UTILS.typeof(nameOrRoster, CLM.MODELS.Roster) then
        roster = nameOrRoster
    else
        roster = self:GetRosterByName(nameOrRoster)
    end
    if not roster then
        LOG:Error("RosterManager:SetRosterDynamicItemValueExpvar(): Invalid roster object or name")
        return nil
    end
    if not expvar then
        LOG:Error("RosterManager:SetRosterDynamicItemValueExpvar(): Missing expvar")
        return
    end
    if roster:GetCalculator():GetExpvar() == expvar then
        LOG:Debug("RosterManager:SetRosterDynamicItemValueExpvar(): No change to value. Skipping.")
        return
    end

    CLM.MODULES.LedgerManager:Submit(CLM.MODELS.LEDGER.ROSTER.DynamicItemValueExpvar:new(roster:UID(), expvar), true)
end

function RosterManager:SetRosterDynamicItemValueCustomExpression(nameOrRoster, custom_expression)
    LOG:Trace("RosterManager:SetRosterDynamicItemValueCustomExpression()")
    local roster
    if UTILS.typeof(nameOrRoster, CLM.MODELS.Roster) then
        roster = nameOrRoster
    else
        roster = self:GetRosterByName(nameOrRoster)
    end
    if not roster then
        LOG:Error("RosterManager:SetRosterDynamicItemValueCustomExpression(): Invalid roster object or name")
        return nil
    end
    if not custom_expression then
        LOG:Error("RosterManager:SetRosterDynamicItemValueCustomExpression(): Missing custom_expression")
        return
    end
    if roster:GetCalculator():GetCustomExpression() == custom_expression then
        LOG:Debug("RosterManager:SetRosterDynamicItemValueCustomExpression(): No change to value. Skipping.")
        return
    end
    if not ExpressionParser:IsValidExpression(custom_expression, CONSTANTS.CUSTOM_EQUATION_VARIABLES) then
        LOG:Error("RosterManager:SetRosterDynamicItemValueCustomExpression(): Invalid custom_expression [%s]", custom_expression)
        return
    end

    CLM.MODULES.LedgerManager:Submit(CLM.MODELS.LEDGER.ROSTER.DynamicItemValueCustomExpression:new(roster:UID(), custom_expression), true)
end

function RosterManager:SetRosterDynamicItemValueMultiplier(nameOrRoster, multiplier)
    LOG:Trace("RosterManager:SetRosterDynamicItemValueMultiplier()")
    multiplier = tonumber(multiplier)
    local roster
    if UTILS.typeof(nameOrRoster, CLM.MODELS.Roster) then
        roster = nameOrRoster
    else
        roster = self:GetRosterByName(nameOrRoster)
    end
    if not roster then
        LOG:Error("RosterManager:SetRosterDefaultSlotTierValue(): Invalid roster object or name")
        return nil
    end
    if not multiplier then
        LOG:Error("RosterManager:SetRosterDefaultSlotTierValue(): Missing multiplier")
        return
    end
    if roster:GetCalculator():GetMultiplier() == multiplier then
        LOG:Debug("RosterManager:SetRosterDefaultSlotTierValue(): No change to value. Skipping.")
        return
    end

    CLM.MODULES.LedgerManager:Submit(CLM.MODELS.LEDGER.ROSTER.DynamicItemValueMultiplier:new(roster:UID(), multiplier), true)
end

function RosterManager:SetRosterDynamicItemValueSlotMultiplier(nameOrRoster, slot, multiplier)
    LOG:Trace("RosterManager:SetRosterDynamicItemValueSlotMultiplier()")
    multiplier = tonumber(multiplier)
    local roster
    if UTILS.typeof(nameOrRoster, CLM.MODELS.Roster) then
        roster = nameOrRoster
    else
        roster = self:GetRosterByName(nameOrRoster)
    end
    if not roster then
        LOG:Error("RosterManager:SetRosterDynamicItemValueSlotMultiplier(): Invalid roster object or name")
        return nil
    end
    if not multiplier then
        LOG:Error("RosterManager:SetRosterDynamicItemValueSlotMultiplier(): Missing value")
        return
    end
    if not slot or not CONSTANTS.INVENTORY_TYPES_SET[slot] then
        LOG:Error("RosterManager:SetRosterDynamicItemValueSlotMultiplier(): Missing slot")
        return
    end
    if roster:GetCalculator():GetSlotMultiplier(slot) == multiplier then
        LOG:Debug("RosterManager:SetRosterDynamicItemValueSlotMultiplier(): No change to value. Skipping.")
        return
    end

    CLM.MODULES.LedgerManager:Submit(CLM.MODELS.LEDGER.ROSTER.DynamicItemValueSlotMultiplier:new(roster:UID(), slot, multiplier), true)
end

function RosterManager:SetRosterDynamicItemValueTierMultiplier(nameOrRoster, tier, multiplier)
    LOG:Trace("RosterManager:SetRosterDynamicItemValueTierMultiplier()")
    multiplier = tonumber(multiplier)
    local roster
    if UTILS.typeof(nameOrRoster, CLM.MODELS.Roster) then
        roster = nameOrRoster
    else
        roster = self:GetRosterByName(nameOrRoster)
    end
    if not roster then
        LOG:Error("RosterManager:SetRosterDynamicItemValueTierMultiplier(): Invalid roster object or name")
        return nil
    end
    if not multiplier then
        LOG:Error("RosterManager:SetRosterDynamicItemValueTierMultiplier(): Missing value")
        return
    end
    if not tier or not CONSTANTS.SLOT_VALUE_TIERS[tier] then
        LOG:Error("RosterManager:SetRosterDynamicItemValueTierMultiplier(): Missing tier")
        return
    end
    if roster:GetCalculator():GetTierMultiplier(tier) == multiplier then
        LOG:Debug("RosterManager:SetRosterDynamicItemValueTierMultiplier(): No change to value. Skipping.")
        return
    end

    CLM.MODULES.LedgerManager:Submit(CLM.MODELS.LEDGER.ROSTER.DynamicItemValueTierMultiplier:new(roster:UID(), tier, multiplier), true)
end

function RosterManager:SetFieldName(nameOrRoster, field, name)
    LOG:Trace("RosterManager:SetFieldName()")
    local roster
    if UTILS.typeof(nameOrRoster, CLM.MODELS.Roster) then
        roster = nameOrRoster
    else
        roster = self:GetRosterByName(nameOrRoster)
    end
    if not roster then
        LOG:Error("RosterManager:SetFieldName(): Invalid roster object or name")
        return nil
    end
    if not name then
        LOG:Error("RosterManager:SetFieldName(): Missing name")
        return
    end
    if not field or not CONSTANTS.SLOT_VALUE_TIERS[field] then
        LOG:Error("RosterManager:SetFieldName(): Missing tier")
        return
    end
    name = tostring(name)
    if string.len(name) > 16 then
        LOG:Warning("RosterManager:SetFieldName(): Truncating name %s for field %s to 16 chars.", name, field)
        name = strsub(name, 1, 16)
    end

    if name == roster:GetFieldName(field) then
        LOG:Debug("RosterManager:SetFieldName(): No change to name. Skipping.")
        return
    end

    CLM.MODULES.LedgerManager:Submit(CLM.MODELS.LEDGER.ROSTER.FieldRename:new(roster:UID(), field, name), true)
end

function RosterManager:CompareAndSanitizeSlotTierValues(current, new)
    local sanitizedValues = {}
    local allSame = true
    for key,_ in pairs(CONSTANTS.SLOT_VALUE_TIERS) do
        local value = tonumber(new[key])
        if not value then
            LOG:Error("RosterManager:CompareAndSanitizeSlotTierValues(): Missing valid value for tier %s", CONSTANTS.SLOT_VALUE_TIERS_GUI[key])
            return
        end
        if current[key] ~= value then
            allSame = false
        end
        sanitizedValues[key] = value
    end
    if allSame then
        LOG:Debug("RosterManager:CompareAndSanitizeSlotTierValues(): No change to value. Skipping.")
        return
    end
    return sanitizedValues
end

function RosterManager:SetRosterItemValues(nameOrRoster, itemId, values)
    LOG:Trace("RosterManager:SetRosterItemTierValue()")
    local roster
    if UTILS.typeof(nameOrRoster, CLM.MODELS.Roster) then
        roster = nameOrRoster
    else
        roster = self:GetRosterByName(nameOrRoster)
    end
    if not roster then
        LOG:Error("RosterManager:SetRosterItemValue(): Invalid roster object or name")
        return nil
    end
    if not itemId then
        LOG:Error("RosterManager:SetRosterItemValue(): Missing itemId")
        return
    end
    local sanitizedValues = self:CompareAndSanitizeSlotTierValues(roster:GetItemValues(itemId), values)
    if sanitizedValues then
        CLM.MODULES.LedgerManager:Submit(CLM.MODELS.LEDGER.ROSTER.UpdateOverrides:new(roster:UID(), itemId, sanitizedValues), true)
    end
end

function RosterManager:RemoveRosterItemOverride(nameOrRoster, itemId)
    LOG:Trace("RosterManager:RemoveRosterItemOverride()")
    local roster
    if UTILS.typeof(nameOrRoster, CLM.MODELS.Roster) then
        roster = nameOrRoster
    else
        roster = self:GetRosterByName(nameOrRoster)
    end
    if not itemId then
        LOG:Error("RosterManager:RemoveRosterItemOverride(): Missing itemId")
        return
    end

    if not roster.itemValues[itemId] then
        LOG:Debug("RosterManager:RemoveRosterItemOverride(): No change to value. Skipping.")
        return
    end

    CLM.MODULES.LedgerManager:Submit(CLM.MODELS.LEDGER.ROSTER.RemoveOverrides:new(roster:UID(), itemId), true)
end

function RosterManager:SetRosterItemTierValue(nameOrRoster, itemId, tier, value)
    LOG:Trace("RosterManager:SetRosterItemTierValue()")
    local roster
    if UTILS.typeof(nameOrRoster, CLM.MODELS.Roster) then
        roster = nameOrRoster
    else
        roster = self:GetRosterByName(nameOrRoster)
    end
    if not roster then
        LOG:Error("RosterManager:SetRosterItemValue(): Invalid roster object or name")
        return nil
    end
    if not itemId then
        LOG:Error("RosterManager:SetRosterItemValue(): Missing itemId")
        return
    end
    value = tonumber(value)
    if not value then
        LOG:Error("RosterManager:SetRosterItemTierValue(): Missing value")
        return
    end
    if not tier or not CONSTANTS.SLOT_VALUE_TIERS[tier] then
        LOG:Error("RosterManager:SetRosterItemTierValue(): Missing tier")
        return
    end
    CLM.MODULES.LedgerManager:Submit(CLM.MODELS.LEDGER.ROSTER.UpdateOverridesSingle:new(roster:UID(), itemId, tier, value), true)
end

function RosterManager:SetRosterBossKillBonusValue(nameOrRoster, encounterId, difficultyId, isHardMode, value)
    LOG:Trace("RosterManager:SetRosterBossKillBonusValue()")
    local roster
    if UTILS.typeof(nameOrRoster, CLM.MODELS.Roster) then
        roster = nameOrRoster
    else
        roster = self:GetRosterByName(nameOrRoster)
    end
    if not roster then
        LOG:Error("RosterManager:SetRosterBossKillBonusValue(): Invalid roster object or name")
        return nil
    end
    if not tonumber(encounterId) then
        LOG:Error("RosterManager:SetRosterBossKillBonusValue(): Missing encounterId")
        return
    end
    if not tonumber(difficultyId) then
        LOG:Error("RosterManager:SetRosterBossKillBonusValue(): Missing difficultyId")
        return
    end
    if not tonumber(value) then
        LOG:Error("RosterManager:SetRosterBossKillBonusValue(): Missing value")
        return
    end
    local currentBonus = roster:GetBossKillBonusValue(encounterId, difficultyId, isHardMode)
    if currentBonus == value then
        LOG:Debug("RosterManager:SetRosterBossKillBonusValue(): No change to value. Skipping.")
        return
    end
    CLM.MODULES.LedgerManager:Submit(CLM.MODELS.LEDGER.ROSTER.BossKillBonus:new(roster:UID(), encounterId, difficultyId, isHardMode, value), true)
end

function RosterManager:AddProfilesToRoster(roster, profiles)
    LOG:Trace("RosterManager:AddProfilesToRoster()")
    if not UTILS.typeof(roster, CLM.MODELS.Roster) then
        LOG:Error("RosterManager:AddProfilesToRoster(): Invalid roster object")
        return
    end
    if profiles == nil or type(profiles) ~= "table" or #profiles == 0 then
        LOG:Warning("Empty profiles table in AddProfilesToRoster()")
        return
    end

    local entry = CLM.MODELS.LEDGER.ROSTER.UpdateProfiles:new(roster:UID(), profiles, false)
    local t = entry:profiles()
    if not t or (#t == 0) then
        LOG:Error("RosterManager:AddProfilesToRoster(): Empty profiles list")
        return
    end

    CLM.MODULES.LedgerManager:Submit(entry, true)
end

function RosterManager:RemoveProfilesFromRoster(roster, profiles)
    LOG:Trace("RosterManager:RemoveProfilesFromRoster()")
    if not UTILS.typeof(roster, CLM.MODELS.Roster) then
        LOG:Error("RosterManager:RemoveProfilesFromRoster(): Invalid roster object")
        return
    end
    if profiles == nil or type(profiles) ~= "table" or #profiles == 0 then
        LOG:Error("Empty profiles table in RemoveProfilesFromRoster()")
        return
    end

    local entry = CLM.MODELS.LEDGER.ROSTER.UpdateProfiles:new(roster:UID(), profiles, true)

    local t = entry:profiles()
    if not t or (#t == 0) then
        LOG:Error("RosterManager:RemoveProfilesFromRoster(): Empty profiles list")
        return
    end

    CLM.MODULES.LedgerManager:Submit(entry, true)
end

function RosterManager:AddFromRaidToRoster(roster)
    LOG:Trace("RosterManager:AddFromRaidToRoster()")
    if not UTILS.typeof(roster, CLM.MODELS.Roster) then
        LOG:Error("RosterManager:AddFromRaidToRoster(): Invalid roster object")
        return
    end
    if not IsInRaid() then return end
    -- Lazy fill profiles
    CLM.MODULES.ProfileManager:FillFromRaid()
    local missingProfiles = {}
    for i=1,MAX_RAID_MEMBERS do
        local name  = GetRaidRosterInfo(i)
        if name then
            name = UTILS.Disambiguate(name)
            local profile = CLM.MODULES.ProfileManager:GetProfileByName(name)
            if profile then
                local GUID = profile:GUID()
                if not roster:IsProfileInRoster(GUID) then
                    tinsert(missingProfiles, GUID)
                end
            else
                LOG:Debug("Missing [%s] profile after filling from raid. Weird.", name)
            end
        end
    end
    if #missingProfiles > 0 then
        LOG:Message(CLM.L["Adding missing %s players to current roster"], #missingProfiles)
        self:AddProfilesToRoster(roster, missingProfiles)
    end
end

function RosterManager:AddLootToRoster(roster, loot, profile)
    LOG:Trace("RosterManager:AddLootToRoster()")
    if not UTILS.typeof(roster, CLM.MODELS.Roster) then
        LOG:Error("RosterManager:AddLootToRoster(): Invalid roster object")
        return
    end
    if not UTILS.typeof(profile, CLM.MODELS.Profile) then
        LOG:Error("RosterManager:AddLootToRoster(): Invalid profile object")
        return
    end
    if not UTILS.typeof(loot, CLM.MODELS.Loot) then
        LOG:Error("RosterManager:AddLootToRoster(): Invalid loot object")
        return
    end
    LOG:Debug("RosterManager:AddLootToRoster(): Roster [%s] Loot Id [%s] Profile [%s]", roster:UID(), loot:Id(), profile:GUID())
    roster:AddLoot(loot, profile)
end

function RosterManager:AddDisenchantedToRoster(roster, loot)
    LOG:Trace("RosterManager:AddDisenchantedToRoster()")
    if not UTILS.typeof(roster, CLM.MODELS.Roster) then
        LOG:Error("RosterManager:AddDisenchantedToRoster(): Invalid roster object")
        return
    end
    if not UTILS.typeof(loot, CLM.MODELS.Loot) then
        LOG:Error("RosterManager:AddDisenchantedToRoster(): Invalid loot object")
        return
    end
    LOG:Debug("RosterManager:AddDisenchantedToRoster(): Roster [%s] Loot Id [%s]", roster:UID(), loot:Id())
    roster:AddDisenchanted(loot)
end

function RosterManager:WipeStandings()
    LOG:Trace("RosterManager:WipeStandings()")
    for _, roster in pairs(self.cache.rosters) do
        roster:WipeStandings()
    end
end

function RosterManager:WipeAll()
    LOG:Trace("RosterManager:WipeAll()")
    self.cache = {
        rostersUidMap = {},
        rosters = {}
    }
end

CLM.MODULES.RosterManager = RosterManager

CONSTANTS.ROSTER_NAME_GENERATOR = {
    PREFIX = {
        "adorable",
        "adventurous",
        "aggressive",
        "agreeable",
        "alert",
        "alive",
        "amused",
        "angry",
        "annoyed",
        "annoying",
        "anxious",
        "arrogant",
        "ashamed",
        "attractive",
        "average",
        "awful",
        "bad",
        "beautiful",
        "better",
        "bewildered",
        "black",
        "bloody",
        "blue",
        "blue-eyed",
        "blushing",
        "bored",
        "brainy",
        "brave",
        "breakable",
        "bright",
        "busy",
        "calm",
        "careful",
        "cautious",
        "charming",
        "cheerful",
        "clean",
        "clear",
        "clever",
        "cloudy",
        "clumsy",
        "colorful",
        "combative",
        "comfortable",
        "concerned",
        "condemned",
        "confused",
        "cooperative",
        "courageous",
        "crazy",
        "creepy",
        "crowded",
        "cruel",
        "curious",
        "cute",
        "dangerous",
        "dark",
        "dead",
        "defeated",
        "defiant",
        "delightful",
        "depressed",
        "determined",
        "different",
        "difficult",
        "disgusted",
        "distinct",
        "disturbed",
        "dizzy",
        "doubtful",
        "drab",
        "dull",
        "eager",
        "easy",
        "elated",
        "elegant",
        "embarrassed",
        "enchanting",
        "encouraging",
        "energetic",
        "enthusiastic",
        "envious",
        "evil",
        "excited",
        "expensive",
        "exuberant",
        "fair",
        "faithful",
        "famous",
        "fancy",
        "fantastic",
        "fierce",
        "filthy",
        "fine",
        "foolish",
        "fragile",
        "frail",
        "frantic",
        "friendly",
        "frightened",
        "funny",
        "gentle",
        "gifted",
        "glamorous",
        "gleaming",
        "glorious",
        "good",
        "gorgeous",
        "graceful",
        "grieving",
        "grotesque",
        "grumpy",
        "handsome",
        "happy",
        "healthy",
        "helpful",
        "helpless",
        "hilarious",
        "homeless",
        "homely",
        "horrible",
        "hungry",
        "hurt",
        "ill",
        "important",
        "impossible",
        "inexpensive",
        "innocent",
        "inquisitive",
        "itchy",
        "jealous",
        "jittery",
        "jolly",
        "joyous",
        "kind",
        "lazy",
        "light",
        "lively",
        "lonely",
        "long",
        "lovely",
        "lucky",
        "magnificent",
        "misty",
        "modern",
        "motionless",
        "muddy",
        "mushy",
        "mysterious",
        "nasty",
        "naughty",
        "nervous",
        "nice",
        "nutty",
        "obedient",
        "obnoxious",
        "odd",
        "old-fashioned",
        "open",
        "outrageous",
        "outstanding",
        "panicky",
        "perfect",
        "plain",
        "pleasant",
        "poised",
        "poor",
        "powerful",
        "precious",
        "prickly",
        "proud",
        "putrid",
        "puzzled",
        "quaint",
        "real",
        "relieved",
        "repulsive",
        "rich",
        "scary",
        "selfish",
        "shiny",
        "shy",
        "silly",
        "sleepy",
        "smiling",
        "smoggy",
        "sore",
        "sparkling",
        "splendid",
        "spotless",
        "stormy",
        "strange",
        "stupid",
        "successful",
        "super",
        "talented",
        "tame",
        "tasty",
        "tender",
        "tense",
        "terrible",
        "thankful",
        "thoughtful",
        "thoughtless",
        "tired",
        "tough",
        "troubled",
        "ugliest",
        "ugly",
        "uninterested",
        "unsightly",
        "unusual",
        "upset",
        "uptight",
        "vast",
        "victorious",
        "vivacious",
        "wandering",
        "wear",
        "wicked",
        "wide-eyed",
        "wild",
        "witty",
        "worried",
        "worrisome",
        "wrong",
        "zany",
        "zealous",
        },
    SUFFIX = {
        "ants",
        "bats",
        "bears",
        "bees",
        "birds",
        "buffalloes",
        "cats",
        "chickens",
        "cattle",
        "dogs",
        "dolphins",
        "ducks",
        "elephants",
        "fishes",
        "foxes",
        "frogs",
        "geese",
        "goats",
        "horses",
        "kangaroos",
        "lions",
        "monkeys",
        "owls",
        "oxen",
        "penguins",
        "people",
        "pigs",
        "rabbits",
        "sheep",
        "tigers",
        "whales",
        "wolves",
        "zebras"
    }
}