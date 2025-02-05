-- ------------------------------- --
local  _, CLM = ...
-- ------ CLM common cache ------- --
-- local LOG       = CLM.LOG
-- local CONSTANTS = CLM.CONSTANTS
local UTILS     = CLM.UTILS
-- ------------------------------- --

local mergeLists = UTILS.mergeLists
local typeof = UTILS.typeof
local CreateGUIDList = UTILS.CreateGUIDList

local LogEntry  = LibStub("EventSourcing/LogEntry")

local deflate = UTILS.deflate

local RosterCreate                  = LogEntry:extend("R0")
local RosterDelete                  = LogEntry:extend("R1")
local RosterRename                  = LogEntry:extend("R2")
local RosterUpdateConfig            = LogEntry:extend("R3")
local RosterUpdateConfigSingle      = LogEntry:extend("R4")
-- local RosterUpdateDefault           = LogEntry:extend("R5")
local RosterUpdateDefaultSingle     = LogEntry:extend("R6")
local RosterUpdateOverrides         = LogEntry:extend("R7")
local RosterUpdateOverridesSingle   = LogEntry:extend("R8")
local RosterRemoveOverrides         = LogEntry:extend("RR")
local RosterUpdateProfiles          = LogEntry:extend("R9")
local RosterCopyData                = LogEntry:extend("RC")
local RosterBossKillBonus           = LogEntry:extend("RB")
local RosterFieldRename             = LogEntry:extend("RF")
local RosterAwardMultiplier         = LogEntry:extend("RM")

local RosterDynamicItemValueEquation            = LogEntry:extend("VE")
local RosterDynamicItemValueExpvar              = LogEntry:extend("VX")
local RosterDynamicItemValueCustomExpression    = LogEntry:extend("VC")
local RosterDynamicItemValueMultiplier          = LogEntry:extend("VM")
local RosterDynamicItemValueSlotMultiplier      = LogEntry:extend("VS")
local RosterDynamicItemValueTierMultiplier      = LogEntry:extend("VT")

-- ------------ --
-- RosterCreate --
-- ------------ --
function RosterCreate:new(rosterUid, name, pointType)
    local o = LogEntry.new(self);
    o.n = tostring(name) or ""
    o.r = tonumber(rosterUid) or 0
    o.p = tonumber(pointType) or 0
    return o
end

function RosterCreate:rosterUid()
    return self.r
end

function RosterCreate:name()
    return self.n
end

function RosterCreate:pointType()
    return self.p
end

local RosterCreateFields = mergeLists(LogEntry:fields(), {"r", "n", "p"})
function RosterCreate:fields()
    return RosterCreateFields
end

-- ------------ --
-- RosterDelete --
-- ------------ --
function RosterDelete:new(rosterUid)
    local o = LogEntry.new(self);
    o.r = tonumber(rosterUid) or 0
    return o
end

function RosterDelete:rosterUid()
    return self.r
end

local RosterDeleteFields = mergeLists(LogEntry:fields(), {"r"})
function RosterDelete:fields()
    return RosterDeleteFields
end

-- ------------ --
-- RosterRename --
-- ------------ --
function RosterRename:new(rosterUid, name)
    local o = LogEntry.new(self);
    o.n = tostring(name) or ""
    o.r = tonumber(rosterUid) or 0
    return o
end

function RosterRename:rosterUid()
    return self.r
end

function RosterRename:name()
    return self.n
end

local RosterRenameFields = mergeLists(LogEntry:fields(), {"r", "n"})
function RosterRename:fields()
    return RosterRenameFields
end
-- ------------------ --
-- RosterUpdateConfig --
-- ------------------ --
function RosterUpdateConfig:new(rosterUid, config)
    local o = LogEntry.new(self);
    o.r = tonumber(rosterUid) or 0
    if not typeof(config, CLM.MODELS.RosterConfiguration) then
        config = CLM.MODELS.RosterConfiguration:New()
    end
    o.c = deflate(config)
    return o
end

function RosterUpdateConfig:rosterUid()
    return self.r
end

function RosterUpdateConfig:config()
    return self.c
end

local RosterUpdateConfigFields = mergeLists(LogEntry:fields(), {"r", "c"})
function RosterUpdateConfig:fields()
    return RosterUpdateConfigFields
end
-- ------------------------ --
-- RosterUpdateConfigSingle --
-- ------------------------ --
function RosterUpdateConfigSingle:new(rosterUid, config, value)
    local o = LogEntry.new(self);
    o.r = tonumber(rosterUid) or 0
    o.c = tostring(config) or ""
    o.v = value
    return o
end

function RosterUpdateConfigSingle:rosterUid()
    return self.r
end

function RosterUpdateConfigSingle:config()
    return self.c
end

function RosterUpdateConfigSingle:value()
    return self.v
end

local RosterUpdateConfigSingleFields = mergeLists(LogEntry:fields(), {"r", "c", "v"})
function RosterUpdateConfigSingle:fields()
    return RosterUpdateConfigSingleFields
end
-- ------------------- --
-- RosterUpdateDefault --
-- ------------------- --
-- function RosterUpdateDefault:new(rosterUid, defaults)
--     local o = LogEntry.new(self);
--     o.r = tonumber(rosterUid) or 0
--     o.d = defaults or {}
--     return o
-- end

-- function RosterUpdateDefault:rosterUid()
--     return self.r
-- end

-- function RosterUpdateDefault:defaults()
--     return self.d
-- end

-- local RosterUpdateDefaultFields = mergeLists(LogEntry:fields(), {"r", "d"})
-- function RosterUpdateDefault:fields()
--     return RosterUpdateDefaultFields
-- end
-- ------------------------- --
-- RosterUpdateDefaultSingle --
-- ------------------------- --
function RosterUpdateDefaultSingle:new(rosterUid, slot, tier, value)
    local o = LogEntry.new(self);
    o.r = tonumber(rosterUid) or 0
    o.d = tostring(slot) or "" -- not the most optimal but i don't expect it to be changed too often
    o.i = tier
    o.a = tonumber(value)
    return o
end

function RosterUpdateDefaultSingle:rosterUid()
    return self.r
end

function RosterUpdateDefaultSingle:slot()
    return self.d
end

function RosterUpdateDefaultSingle:tier()
    return self.i
end

function RosterUpdateDefaultSingle:value()
    return self.a
end

local RosterUpdateDefaultSingleFields = mergeLists(LogEntry:fields(), {"r", "d", "i", "a"})
function RosterUpdateDefaultSingle:fields()
    return RosterUpdateDefaultSingleFields
end
-- ------------------------ --
-- RosterUpdateOverrides --
-- ------------------------ --
function RosterUpdateOverrides:new(rosterUid, itemId, values)
    local o = LogEntry.new(self);
    o.r = tonumber(rosterUid) or 0
    o.i = tonumber(itemId) or 0
    o.b = {}
    if type(values) == "table" then
        for key,_ in pairs(CLM.CONSTANTS.SLOT_VALUE_TIERS) do
            o.b[key] = tonumber(values[key])
        end
    end
    return o
end

function RosterUpdateOverrides:rosterUid()
    return self.r
end

function RosterUpdateOverrides:itemId()
    return self.i
end

function RosterUpdateOverrides:values()
    -- return self.b
    return ((type(self.b) == "table") and self.b or {})
end

local RosterUpdateOverridesFields = mergeLists(LogEntry:fields(), {"r", "i", "b"})
function RosterUpdateOverrides:fields()
    return RosterUpdateOverridesFields
end
-- --------------------------- --
-- RosterUpdateOverridesSingle --
-- --------------------------- --
function RosterUpdateOverridesSingle:new(rosterUid, itemId, tier, value)
    local o = LogEntry.new(self);
    o.r = tonumber(rosterUid) or 0
    o.o = tonumber(itemId) or 0
    o.t = tier
    o.v = tonumber(value) or 0
    return o
end

function RosterUpdateOverridesSingle:rosterUid()
    return self.r
end

function RosterUpdateOverridesSingle:itemId()
    return self.o
end

function RosterUpdateOverridesSingle:tier()
    return self.t
end

function RosterUpdateOverridesSingle:value()
    return self.v
end

local RosterUpdateOverridesSingleFields = mergeLists(LogEntry:fields(), {"r", "o", "t", "v"})
function RosterUpdateOverridesSingle:fields()
    return RosterUpdateOverridesSingleFields
end
-- ------------------------ --
-- RosterRemoveOverrides --
-- ------------------------ --
function RosterRemoveOverrides:new(rosterUid, itemId)
    local o = LogEntry.new(self);
    o.r = tonumber(rosterUid) or 0
    o.i = tonumber(itemId) or 0
    return o
end

function RosterRemoveOverrides:rosterUid()
    return self.r
end

function RosterRemoveOverrides:itemId()
    return self.i
end

local RosterRemoveOverridesFields = mergeLists(LogEntry:fields(), {"r", "i"})
function RosterRemoveOverrides:fields()
    return RosterRemoveOverridesFields
end
-- -------------------- --
-- RosterUpdateProfiles --
-- -------------------- --
function RosterUpdateProfiles:new(rosterUid, profiles, remove)
    local o = LogEntry.new(self);
    o.r = tonumber(rosterUid) or 0
    o.p = CreateGUIDList(profiles)
    o.e = remove and true or false
    return o
end

function RosterUpdateProfiles:rosterUid()
    return self.r
end

function RosterUpdateProfiles:profiles()
    return self.p
end

function RosterUpdateProfiles:remove()
    return self.e
end

local RosterUpdateProfilesFields = mergeLists(LogEntry:fields(), {"r", "p", "e"})
function RosterUpdateProfiles:fields()
    return RosterUpdateProfilesFields
end

-- -------------------- --
-- RosterCopyData --
-- -------------------- --
function RosterCopyData:new(sourceRosterUid, targetRosterUid, config, defaults, overrides, profiles)
    local o = LogEntry.new(self);
    o.r = tonumber(sourceRosterUid) or 0
    o.a = tonumber(targetRosterUid) or 0
    o.c = config    and true or false
    o.d = defaults  and true or false
    o.o = overrides and true or false
    o.p = profiles  and true or false
    return o
end

function RosterCopyData:sourceRosterUid()
    return self.r
end

function RosterCopyData:targetRosterUid()
    return self.a
end

function RosterCopyData:config()
    return self.c
end

function RosterCopyData:defaults()
    return self.d
end

function RosterCopyData:overrides()
    return self.o
end

function RosterCopyData:profiles()
    return self.p
end

local RosterCopyDataFields = mergeLists(LogEntry:fields(), {"r", "a", "c", "d", "o", "p"})
function RosterCopyData:fields()
    return RosterCopyDataFields
end

-- -------------------- --
-- RosterBossKillBonus --
-- -------------------- --
function RosterBossKillBonus:new(rosterUid, encounterId, difficultyId, isHardMode, value)
    local o = LogEntry.new(self);
    o.r = tonumber(rosterUid) or 0
    o.e = tonumber(encounterId) or 0
    o.v = tonumber(value) or 0
    o.d = tonumber(difficultyId) or -1
    o.h = isHardMode and true or false
    return o
end

function RosterBossKillBonus:rosterUid()
    return self.r
end

function RosterBossKillBonus:encounterId()
    return self.e
end

function RosterBossKillBonus:difficultyId()
    return (self.d or -1)
end

function RosterBossKillBonus:isHardMode()
    return self.h
end

function RosterBossKillBonus:value()
    return self.v
end

local RosterBossKillBonusFields = mergeLists(LogEntry:fields(), {"r", "e", "v", "d", "h"})
function RosterBossKillBonus:fields()
    return RosterBossKillBonusFields
end

-- ------------------------- --
-- RosterFieldRename --
-- ------------------------- --
function RosterFieldRename:new(rosterUid, tier, name)
    local o = LogEntry.new(self);
    o.r = tonumber(rosterUid) or 0
    o.i = tier
    o.a = name
    return o
end

function RosterFieldRename:rosterUid()
    return self.r
end

function RosterFieldRename:tier()
    return self.i
end

function RosterFieldRename:name()
    return self.a
end

local RosterFieldRenameFields = mergeLists(LogEntry:fields(), {"r", "i", "a"})
function RosterFieldRename:fields()
    return RosterFieldRenameFields
end
-- ------------------------- --
-- RosterAwardMultiplier --
-- ------------------------- --
function RosterAwardMultiplier:new(rosterUid, class, slot, value)
    local o = LogEntry.new(self);
    o.r = tonumber(rosterUid) or 0
    o.c = tonumber(class) or UTILS.ClassToNumber(class)
    o.s = tostring(slot) or "" -- not the most optimal but i don't expect it to be changed too often
    o.v = tonumber(value)
    return o
end

function RosterAwardMultiplier:rosterUid()
    return self.r
end

function RosterAwardMultiplier:ingameClass()
    return self.c
end

function RosterAwardMultiplier:slot()
    return self.s
end

function RosterAwardMultiplier:value()
    return self.v
end

local RosterAwardMultiplierFields = mergeLists(LogEntry:fields(), {"r", "c", "s", "v"})
function RosterAwardMultiplier:fields()
    return RosterAwardMultiplierFields
end
-- ------------------------------ --
-- RosterDynamicItemValueEquation --
-- ------------------------------ --
function RosterDynamicItemValueEquation:new(rosterUid, equation)
    local o = LogEntry.new(self);
    o.r = tonumber(rosterUid) or 0
    o.e = tonumber(equation) or 0
    return o
end

function RosterDynamicItemValueEquation:rosterUid()
    return self.r
end

function RosterDynamicItemValueEquation:equation()
    return self.e
end

local RosterDynamicItemValueEquationFields = mergeLists(LogEntry:fields(), {"r", "e"})
function RosterDynamicItemValueEquation:fields()
    return RosterDynamicItemValueEquationFields
end

-- ---------------------------- --
-- RosterDynamicItemValueExpvar --
-- ---------------------------- --
function RosterDynamicItemValueExpvar:new(rosterUid, expvar)
    local o = LogEntry.new(self);
    o.r = tonumber(rosterUid) or 0
    o.m = tonumber(expvar) or 0
    return o
end

function RosterDynamicItemValueExpvar:rosterUid()
    return self.r
end

function RosterDynamicItemValueExpvar:expvar()
    return self.m
end

local RosterDynamicItemValueExpvarFields = mergeLists(LogEntry:fields(), {"r", "m"})
function RosterDynamicItemValueExpvar:fields()
    return RosterDynamicItemValueExpvarFields
end

-- ---------------------------- --
-- RosterDynamicItemValueCustomExpression --
-- ---------------------------- --
function RosterDynamicItemValueCustomExpression:new(rosterUid, custom_expression)
    local o = LogEntry.new(self);
    o.r = tonumber(rosterUid) or 0
    local lengthRestricted = string.sub(tostring(custom_expression or "0"), 1, ExpressionParser.MAX_EXPRESSION_LENGTH)
    o.m = string.lower(lengthRestricted:gsub("%s+", ""))
    return o
end

function RosterDynamicItemValueCustomExpression:rosterUid()
    return self.r
end

function RosterDynamicItemValueCustomExpression:customExpression()
    return self.m
end

local RosterDynamicItemValueCustomExpressionFields = mergeLists(LogEntry:fields(), {"r", "m"})
function RosterDynamicItemValueCustomExpression:fields()
    return RosterDynamicItemValueCustomExpressionFields
end

-- -------------------------------- --
-- RosterDynamicItemValueMultiplier --
-- -------------------------------- --
function RosterDynamicItemValueMultiplier:new(rosterUid, multiplier)
    local o = LogEntry.new(self);
    o.r = tonumber(rosterUid) or 0
    o.m = tonumber(multiplier) or 0
    return o
end

function RosterDynamicItemValueMultiplier:rosterUid()
    return self.r
end

function RosterDynamicItemValueMultiplier:multiplier()
    return self.m
end

local RosterDynamicItemValueMultiplierFields = mergeLists(LogEntry:fields(), {"r", "m"})
function RosterDynamicItemValueMultiplier:fields()
    return RosterDynamicItemValueMultiplierFields
end

-- ------------------------------------ --
-- RosterDynamicItemValueSlotMultiplier --
-- ------------------------------------ --
function RosterDynamicItemValueSlotMultiplier:new(rosterUid, slot, multiplier)
    local o = LogEntry.new(self);
    o.r = tonumber(rosterUid) or 0
    o.s = slot
    o.m = tonumber(multiplier) or 0
    return o
end

function RosterDynamicItemValueSlotMultiplier:rosterUid()
    return self.r
end

function RosterDynamicItemValueSlotMultiplier:slot()
    return self.s
end

function RosterDynamicItemValueSlotMultiplier:multiplier()
    return self.m
end

local RosterDynamicItemValueSlotMultiplierFields = mergeLists(LogEntry:fields(), {"r", "s", "m"})
function RosterDynamicItemValueSlotMultiplier:fields()
    return RosterDynamicItemValueSlotMultiplierFields
end

-- ------------------------------------ --
-- RosterDynamicItemValueTierMultiplier --
-- ------------------------------------ --
function RosterDynamicItemValueTierMultiplier:new(rosterUid, tier, multiplier)
    local o = LogEntry.new(self);
    o.r = tonumber(rosterUid) or 0
    o.i = tier
    o.m = tonumber(multiplier) or 0
    return o
end

function RosterDynamicItemValueTierMultiplier:rosterUid()
    return self.r
end

function RosterDynamicItemValueTierMultiplier:tier()
    return self.i
end

function RosterDynamicItemValueTierMultiplier:multiplier()
    return self.m
end

local RosterDynamicItemValueTierMultiplierFields = mergeLists(LogEntry:fields(), {"r", "i", "m"})
function RosterDynamicItemValueTierMultiplier:fields()
    return RosterDynamicItemValueTierMultiplierFields
end

CLM.MODELS.LEDGER.ROSTER = {
    Create                              = RosterCreate,
    Delete                              = RosterDelete,
    Rename                              = RosterRename,
    UpdateConfig                        = RosterUpdateConfig,
    UpdateConfigSingle                  = RosterUpdateConfigSingle,
    UpdateDefaultSingle                 = RosterUpdateDefaultSingle,
    UpdateOverrides                     = RosterUpdateOverrides,
    UpdateOverridesSingle               = RosterUpdateOverridesSingle,
    RemoveOverrides                     = RosterRemoveOverrides,
    UpdateProfiles                      = RosterUpdateProfiles,
    CopyData                            = RosterCopyData,
    BossKillBonus                       = RosterBossKillBonus,
    FieldRename                         = RosterFieldRename,
    AwardMultiplier                     = RosterAwardMultiplier,
    DynamicItemValueEquation            = RosterDynamicItemValueEquation,
    DynamicItemValueExpvar              = RosterDynamicItemValueExpvar,
    DynamicItemValueCustomExpression    = RosterDynamicItemValueCustomExpression,
    DynamicItemValueMultiplier          = RosterDynamicItemValueMultiplier,
    DynamicItemValueSlotMultiplier      = RosterDynamicItemValueSlotMultiplier,
    DynamicItemValueTierMultiplier      = RosterDynamicItemValueTierMultiplier
}
