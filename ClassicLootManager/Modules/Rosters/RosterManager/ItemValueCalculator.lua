-- ------------------------------- --
local  _, CLM = ...
-- ------ CLM common cache ------- --
local LOG       = CLM.LOG
local CONSTANTS = CLM.CONSTANTS
local UTILS     = CLM.UTILS
-- ------------------------------- --

local DEFAULT_MULTIPLIER = {
    epgpweb = 0.483,
    wowpedia = 0.04,
    custom = 1.0
}

local DEFAULT_CUSTOM_EXPRESSION = "(ilvl / 10) * slot_multiplier"

local DEFAULT_EXPVAR = 2.0

CONSTANTS.ITEM_VALUE_EQUATION = {
    EPGPWEB = 1,
    WOWPEDIA = 2,
    CUSTOM = 3
}

CONSTANTS.CUSTOM_EQUATION_VARIABLES = {
    ILVL = "ilvl",
    EXPVAR = "expvar",
    QUALITY = "quality",
    MULTIPLIER = "multiplier",
    SLOT_MULTIPLIER = "slot_multiplier"
}

local equationIDtoParam = {
    [CONSTANTS.ITEM_VALUE_EQUATION.EPGPWEB] = "epgpweb",
    [CONSTANTS.ITEM_VALUE_EQUATION.WOWPEDIA] = "wowpedia",
    [CONSTANTS.ITEM_VALUE_EQUATION.CUSTOM] = "custom",
}

local qualityModifier = {
    [2] = (function(ilvl) return (math.abs(ilvl - 4) / 2) end),
    [3] = (function(ilvl) return (math.abs(ilvl - 1.84) / 1.6) end),
    [4] = (function(ilvl) return (math.abs(ilvl - 1.3) / 1.3) end),
}

local defaultQualityModifier = (function(ilvl) return ilvl end)

local function getItemValue(quality, ilvl)
    local modifier = qualityModifier[quality] or defaultQualityModifier
    return modifier(ilvl)
end

local calculators = {
    [CONSTANTS.ITEM_VALUE_EQUATION.EPGPWEB] = (function(ilvl, quality, multiplier, expvar, slot_multiplier)
        return multiplier * math.pow(expvar, (ilvl/26) + (quality - 4)) * slot_multiplier
    end),
    [CONSTANTS.ITEM_VALUE_EQUATION.WOWPEDIA] = (function(ilvl, quality, multiplier, expvar, slot_multiplier)
        return math.pow(getItemValue(quality, ilvl), expvar) * multiplier * slot_multiplier
    end),
    [CONSTANTS.ITEM_VALUE_EQUATION.CUSTOM] = (function(ilvl, quality, multiplier, expvar, slot_multiplier, custom_expression)
        return ExpressionParser:Evaluate(custom_expression, {
            [CONSTANTS.CUSTOM_EQUATION_VARIABLES.SLOT_MULTIPLIER] = slot_multiplier,
            [CONSTANTS.CUSTOM_EQUATION_VARIABLES.MULTIPLIER] = multiplier,
            [CONSTANTS.CUSTOM_EQUATION_VARIABLES.QUALITY] = quality,
            [CONSTANTS.CUSTOM_EQUATION_VARIABLES.EXPVAR] = expvar,
            [CONSTANTS.CUSTOM_EQUATION_VARIABLES.ILVL] = ilvl
        })
    end)
}

local function getParamFromEquationID(id)
    return equationIDtoParam[id] or 0
end

local function GetDefaultMultiplier(equation)
    return DEFAULT_MULTIPLIER[getParamFromEquationID(equation)] or 1.0
end

local function SetDefaultMultiplier(self)
    self.multiplier = GetDefaultMultiplier(self.equation)
end

local function GetDefaultCustomExpression()
    return DEFAULT_CUSTOM_EXPRESSION
end

local function SetDefaultCustomExpression(self)
    self.custom_expression = GetDefaultCustomExpression()
end

local function GetDefaultSlotMultiplier(equation, slot)
    local param = getParamFromEquationID(equation)
    local slotValues = CONSTANTS.ITEM_SLOT_MULTIPLIERS[slot] or {}
    return slotValues[param] or 1.0
end

local function SetDefaultSlotMultipliers(self)
    local param = getParamFromEquationID(self.equation)
    for name, values in pairs(CONSTANTS.ITEM_SLOT_MULTIPLIERS) do
        self.slotMultipliers[name] = values[param]
    end
end

local function SetDefaultTierMultipliers(self)
    for _, tier in ipairs(CONSTANTS.SLOT_VALUE_TIERS_ORDERED) do
        self.tierMultipliers[tier] = 1.0
    end
end

local function SetCalculator(self)
    self.calculator = calculators[self.equation]
end


local ItemValueCalculator = {}
function ItemValueCalculator:New()
    local o = {}

    setmetatable(o, self)
    self.__index = self

    o.equation = CONSTANTS.ITEM_VALUE_EQUATION.EPGPWEB

    o.multiplier = 1.0
    o.expvar = 2.0
    SetDefaultMultiplier(o)
    SetDefaultCustomExpression(o)
    o.slotMultipliers = {}
    SetDefaultSlotMultipliers(o)
    o.tierMultipliers = {}
    SetDefaultTierMultipliers(o)
    SetCalculator(o)

    return o
end

function ItemValueCalculator:GetEquation()
    return self.equation
end

function ItemValueCalculator:SetEquation(equation)
    if not CONSTANTS.ITEM_VALUE_EQUATIONS[equation] then
        LOG:Fatal("Unknown equation type")
        return
    end
    if self.equation == equation then return end
    self.equation = equation
    SetDefaultMultiplier(self)
    SetDefaultSlotMultipliers(self)
    SetCalculator(self)
end

function ItemValueCalculator:GetMultiplier()
    return self.multiplier
end

function ItemValueCalculator:SetMultiplier(multiplier)
    self.multiplier = tonumber(multiplier) or GetDefaultMultiplier(self.equation)
end

function ItemValueCalculator:GetCustomExpression()
    return self.custom_expression
end

function ItemValueCalculator:SetCustomExpression(custom_expression)
    local expression = custom_expression or GetDefaultCustomExpression()
    self.custom_expression = string.lower(expression:gsub("%s+", ""))
end

function ItemValueCalculator:GetExpvar()
    return self.expvar
end

function ItemValueCalculator:SetExpvar(expvar)
    self.expvar = tonumber(expvar) or DEFAULT_EXPVAR
end

function ItemValueCalculator:GetSlotMultiplier(slot)
    return self.slotMultipliers[slot] or 1.0
end

function ItemValueCalculator:SetSlotMultiplier(slot, multiplier)
    if not CONSTANTS.ITEM_SLOT_MULTIPLIERS[slot] then return end
    self.slotMultipliers[slot] = tonumber(multiplier) or GetDefaultSlotMultiplier(self.equation, slot)
end

function ItemValueCalculator:GetTierMultiplier(tier)
    return self.tierMultipliers[tier] or 1.0
end

function ItemValueCalculator:SetTierMultiplier(tier, multiplier)
    if not CONSTANTS.SLOT_VALUE_TIERS[tier] then return end
    self.tierMultipliers[tier] = tonumber(multiplier) or 1.0
end

function ItemValueCalculator:Calculate(ilvl, quality, slot_multiplier, rounding)
    local values = {}
    local baseValue = self.calculator(ilvl, quality, self.multiplier, self.expvar, slot_multiplier, self.custom_expression)

    for tier, tierMultiplier in pairs(self.tierMultipliers) do
        values[tier] = UTILS.round(baseValue * tierMultiplier, rounding)
    end

    return values
end

local function CalculateProxy(self, itemInfoInput, itemId, rounding)
    local _, _, itemQuality, itemLevel, _, _, _, _, itemEquipLoc, _, _, classID, subclassID = UTILS.GetItemInfo(itemInfoInput)
    if not itemQuality or not itemLevel or not itemEquipLoc then
        LOG:Warning(CLM.L["Unable to get item info from server. Please try auctioning again"])
        return nil
    end

    local equipLoc = UTILS.WorkaroundEquipLoc(classID, subclassID, itemEquipLoc)
    return self:Calculate(CLM.IndirectMap.ilvl[itemId] or itemLevel, itemQuality, self:GetSlotMultiplier(CLM.IndirectMap.slot[itemId] or equipLoc), rounding)
end

function ItemValueCalculator:CalculateFromId(itemId, rounding)
    return CalculateProxy(self, itemId, itemId, rounding)
end

function ItemValueCalculator:CalculateFromLink(itemLink, rounding)
    return CalculateProxy(self, itemLink, UTILS.GetItemIdFromLink(itemLink), rounding)
end

CONSTANTS.ITEM_VALUE_EQUATIONS = UTILS.Set({
    CONSTANTS.ITEM_VALUE_EQUATION.EPGPWEB,
    CONSTANTS.ITEM_VALUE_EQUATION.WOWPEDIA,
    CONSTANTS.ITEM_VALUE_EQUATION.CUSTOM
})

CONSTANTS.ITEM_VALUE_EQUATIONS_ORDERED = {
    CONSTANTS.ITEM_VALUE_EQUATION.EPGPWEB,
    CONSTANTS.ITEM_VALUE_EQUATION.WOWPEDIA,
    CONSTANTS.ITEM_VALUE_EQUATION.CUSTOM
}

CONSTANTS.ITEM_VALUE_EQUATIONS_GUI = {
    [CONSTANTS.ITEM_VALUE_EQUATION.EPGPWEB] = CLM.L["EPGP WEB"],
    [CONSTANTS.ITEM_VALUE_EQUATION.WOWPEDIA] = CLM.L["Wowpedia"],
    [CONSTANTS.ITEM_VALUE_EQUATION.CUSTOM] = CLM.L["Custom"]
}

CONSTANTS.ITEM_SLOT_MULTIPLIERS = {
    ["INVTYPE_HEAD"] = {            epgpweb = 1.0,  wowpedia = 1.0,     custom = 1.0},
    ["INVTYPE_NECK"] = {            epgpweb = 0.5,  wowpedia = 0.55,    custom = 1.0},
    ["INVTYPE_SHOULDER"] = {        epgpweb = 0.75, wowpedia = 0.777,   custom = 1.0},
    ["INVTYPE_BODY"] = {            epgpweb = 0.0,  wowpedia = 0.0,     custom = 1.0},
    ["INVTYPE_CLOAK"] = {           epgpweb = 0.5,  wowpedia = 0.55,    custom = 1.0},
    ["INVTYPE_CHEST"] = {           epgpweb = 1.0,  wowpedia = 1.0,     custom = 1.0},
    ["INVTYPE_ROBE"] = {            epgpweb = 1.0,  wowpedia = 1.0,     custom = 1.0},
    ["INVTYPE_TABARD"] = {          epgpweb = 0.0,  wowpedia = 0.0,     custom = 1.0},
    ["INVTYPE_WRIST"] = {           epgpweb = 0.75, wowpedia = 0.55,    custom = 1.0},
    ["INVTYPE_HAND"] = {            epgpweb = 0.75, wowpedia = 0.777,   custom = 1.0},
    ["INVTYPE_WAIST"] = {           epgpweb = 1.0,  wowpedia = 0.777,   custom = 1.0},
    ["INVTYPE_LEGS"] = {            epgpweb = 1.0,  wowpedia = 1.0,     custom = 1.0},
    ["INVTYPE_FEET"] = {            epgpweb = 0.75, wowpedia = 0.777,   custom = 1.0},
    ["INVTYPE_FINGER"] = {          epgpweb = 0.5,  wowpedia = 0.55,    custom = 1.0},
    ["INVTYPE_TRINKET"] = {         epgpweb = 0.75, wowpedia = 0.7,     custom = 1.0},
    ["INVTYPE_WEAPON"] = {          epgpweb = 1.0,  wowpedia = 1.0,     custom = 1.0},
    ["INVTYPE_WEAPONMAINHAND"] = {  epgpweb = 1.5,  wowpedia = 0.42,    custom = 1.0},
    ["INVTYPE_WEAPONOFFHAND"] = {   epgpweb = 1.5,  wowpedia = 0.42,    custom = 1.0},
    ["INVTYPE_HOLDABLE"] = {        epgpweb = 0.5,  wowpedia = 0.55,    custom = 1.0},
    ["INVTYPE_2HWEAPON"] = {        epgpweb = 2.0,  wowpedia = 1.0,     custom = 1.0},
    ["INVTYPE_SHIELD"] = {          epgpweb = 0.5,  wowpedia = 0.55,    custom = 1.0},
    ["INVTYPE_RANGED"] = {          epgpweb = 0.5,  wowpedia = 0.42,    custom = 1.0},
    ["INVTYPE_RANGEDRIGHT"] = {     epgpweb = 0.5,  wowpedia = 0.42,    custom = 1.0},
    ["INVTYPE_NON_EQUIP"] = {       epgpweb = 0.0,  wowpedia = 0.0,     custom = 1.0},
    ["INVTYPE_BAG"] = {             epgpweb = 0.0,  wowpedia = 0.0,     custom = 1.0},
    ["INVTYPE_AMMO"] = {            epgpweb = 0.0,  wowpedia = 0.0,     custom = 1.0},
    ["INVTYPE_THROWN"] = {          epgpweb = 0.5,  wowpedia = 0.42,    custom = 1.0},
    ["INVTYPE_QUIVER"] = {          epgpweb = 0.5,  wowpedia = 0.42,    custom = 1.0},
    ["INVTYPE_RELIC"] = {           epgpweb = 0.5,  wowpedia = 0.42,    custom = 1.0},
}

CLM.MODELS.ItemValueCalculator = ItemValueCalculator
