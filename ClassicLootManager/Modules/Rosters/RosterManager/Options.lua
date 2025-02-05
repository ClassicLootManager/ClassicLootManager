-- ------------------------------- --
local  _, CLM = ...
-- ------ CLM common cache ------- --
-- local LOG       = CLM.LOG
local CONSTANTS = CLM.CONSTANTS
local UTILS     = CLM.UTILS
-- ------------------------------- --

local CBTYPE = {
    GETTER          = "get",
    SETTER          = "set",
    EXECUTOR        = "execute",
    HIDER           = "hide",
    CONFIRMATION    = "confirm"
}

local RosterManagerOptions = { externalOptions = {} }

local function GetRosterOption(name, option)
    local roster = CLM.MODULES.RosterManager:GetRosterByName(name)
    if roster == nil then return nil end
    return roster:GetConfiguration(option)
end

local function SetRosterOption(name, option, value)
    CLM.MODULES.RosterManager:SetRosterConfiguration(name, option, value)
end

function RosterManagerOptions:Initialize()
    self.pointType = CONSTANTS.POINT_TYPE.DKP
    self.rosterName = CLM.MODULES.RosterManager:GenerateName()
    self.variableNames = {}
    for _, v in pairs(CONSTANTS.CUSTOM_EQUATION_VARIABLES) do
        table.insert(self.variableNames, v)
    end
    self.readOnly = not CLM.MODULES.ACL:CheckLevel(CONSTANTS.ACL.LEVEL.MANAGER)
    self.handlers = {
        general_name_get = (function(name)
            return name
        end),
        general_name_set = (function(old, new)
            CLM.MODULES.RosterManager:RenameRoster(old, new)
        end),
        general_remove_execute = (function(name)
            CLM.MODULES.RosterManager:DeleteRosterByName(name)
        end),
        general_fill_profiles_execute = (function(name)
            local profiles = CLM.MODULES.ProfileManager:GetProfiles()
            local profileList = {}
            for GUID, _ in pairs(profiles) do
                table.insert(profileList, GUID)
            end
            local roster = CLM.MODULES.RosterManager:GetRosterByName(name)
            CLM.MODULES.RosterManager:AddProfilesToRoster(roster, profileList)
        end),
        general_copy_execute = (function(name)
            if self.copy_source_name == nil then return end
            CLM.MODULES.RosterManager:Copy(self.copy_source_name, name, true, true, true, false)
        end),
        general_copy_source_get = (function(name)
            return self.copy_source_name
        end),
        general_copy_source_set = (function(name, value)
            self.copy_source_name = value
        end),
        -- Bonuses
        general_boss_kill_bonus_get = (function(name)
            return GetRosterOption(name, "bossKillBonus")
        end),
        general_boss_kill_bonus_set = (function(name, value)
            SetRosterOption(name, "bossKillBonus", value)
        end),
        general_boss_kill_bonus_value_get = (function(name)
            return tostring(GetRosterOption(name, "bossKillBonusValue"))
        end),
        general_boss_kill_bonus_value_set = (function(name, value)
            SetRosterOption(name, "bossKillBonusValue", value)
        end),
        general_on_time_bonus_get = (function(name)
            return GetRosterOption(name, "onTimeBonus")
        end),
        general_on_time_bonus_set = (function(name, value)
            SetRosterOption(name, "onTimeBonus", value)
        end),
        general_on_time_bonus_value_get = (function(name)
            return tostring(GetRosterOption(name, "onTimeBonusValue"))
        end),
        general_on_time_bonus_value_set = (function(name, value)
            SetRosterOption(name, "onTimeBonusValue", value)
        end),
        general_raid_completion_bonus_get = (function(name)
            return GetRosterOption(name, "raidCompletionBonus")
        end),
        general_raid_completion_bonus_set = (function(name, value)
            SetRosterOption(name, "raidCompletionBonus", value)
        end),
        general_raid_completion_bonus_value_get = (function(name)
            return tostring(GetRosterOption(name, "raidCompletionBonusValue"))
        end),
        general_raid_completion_bonus_value_set = (function(name, value)
            SetRosterOption(name, "raidCompletionBonusValue", value)
        end),
        general_interval_bonus_get = (function(name)
            return GetRosterOption(name, "intervalBonus")
        end),
        general_interval_bonus_set = (function(name, value)
            SetRosterOption(name, "intervalBonus", value)
        end),
        general_interval_bonus_value_get = (function(name)
            return tostring(GetRosterOption(name, "intervalBonusValue"))
        end),
        general_interval_bonus_value_set = (function(name, value)
            SetRosterOption(name, "intervalBonusValue", value)
        end),
        general_interval_bonus_time_get = (function(name)
            return tostring(GetRosterOption(name, "intervalBonusTime"))
        end),
        general_interval_bonus_time_set = (function(name, value)
            SetRosterOption(name, "intervalBonusTime", value)
        end),
        general_weekly_reset_timezone_get = (function(name)
            return GetRosterOption(name, "weeklyReset")
        end),
        general_weekly_reset_timezone_set = (function(name, value)
            SetRosterOption(name, "weeklyReset", value)
        end),
        general_allow_self_bench_subscribe_get = (function(name)
            return GetRosterOption(name, "selfBenchSubscribe")
        end),
        general_allow_self_bench_subscribe_set = (function(name, value)
            SetRosterOption(name, "selfBenchSubscribe", value)
        end),
        general_auto_bench_leavers_get = (function(name)
            return GetRosterOption(name, "autoBenchLeavers")
        end),
        general_auto_bench_leavers_set = (function(name, value)
            SetRosterOption(name, "autoBenchLeavers", value)
        end),
        general_bench_multiplier_get = (function(name)
            return tostring(GetRosterOption(name, "benchMultiplier"))
        end),
        general_bench_multiplier_set = (function(name, value)
            SetRosterOption(name, "benchMultiplier", value)
        end),
        general_auto_award_include_bench_get = (function(name)
            return GetRosterOption(name, "autoAwardIncludeBench")
        end),
        general_auto_award_include_bench_set = (function(name, value)
            SetRosterOption(name, "autoAwardIncludeBench", value)
        end),
        general_auto_award_online_only_get = (function(name)
            return GetRosterOption(name, "autoAwardOnlineOnly")
        end),
        general_auto_award_online_only_set = (function(name, value)
            SetRosterOption(name, "autoAwardOnlineOnly", value)
        end),
        general_auto_award_same_zone_only_get = (function(name)
            return GetRosterOption(name, "autoAwardSameZoneOnly")
        end),
        general_auto_award_same_zone_only_set = (function(name, value)
            SetRosterOption(name, "autoAwardSameZoneOnly", value)
        end),
        general_named_buttons_toggle_set = (function(name, value)
            SetRosterOption(name, "namedButtons", value)
        end),
        general_named_buttons_toggle_get = (function(name)
            return GetRosterOption(name, "namedButtons")
        end),
        -- Caps
        general_hard_cap_get = (function(name)
            return tostring(GetRosterOption(name, "hardCap"))
        end),
        general_hard_cap_set = (function(name, value)
            SetRosterOption(name, "hardCap", value)
        end),
        general_round_decimals_get = (function(name)
            return GetRosterOption(name, "roundDecimals")
        end),
        general_round_decimals_set = (function(name, value)
            SetRosterOption(name, "roundDecimals", value)
        end),
        general_round_pr_get = (function(name)
            return GetRosterOption(name, "roundPR")
        end),
        general_round_pr_set = (function(name, value)
            SetRosterOption(name, "roundPR", value)
        end),
        general_min_gp_get = (function(name)
            return tostring(GetRosterOption(name, "minGP"))
        end),
        general_min_gp_set = (function(name, value)
            SetRosterOption(name, "minGP", value)
        end),
        general_weekly_cap_get = (function(name)
            return tostring(GetRosterOption(name, "weeklyCap"))
        end),
        general_weekly_cap_set = (function(name, value)
            SetRosterOption(name, "weeklyCap", value)
        end),
        -- Auction
        auction_auction_type_get = (function(name)
            return GetRosterOption(name, "auctionType")
        end),
        auction_auction_type_set = (function(name, value)
            SetRosterOption(name, "auctionType", value)
        end),
        auction_item_value_mode_get = (function(name)
            return GetRosterOption(name, "itemValueMode")
        end),
        auction_item_value_mode_set = (function(name, value)
            SetRosterOption(name, "itemValueMode", value)
        end),
        auction_dynamic_item_values_get = (function(name)
            return GetRosterOption(name, "dynamicValue")
        end),
        auction_dynamic_item_values_set = (function(name, value)
            SetRosterOption(name, "dynamicValue", value)
        end),
        auction_base_always_get = (function(name)
            return GetRosterOption(name, "baseAlways")
        end),
        auction_base_always_set = (function(name, value)
            SetRosterOption(name, "baseAlways", value)
        end),
        auction_allin_always_get = (function(name)
            return GetRosterOption(name, "allInAlways")
        end),
        auction_allin_always_set = (function(name, value)
            SetRosterOption(name, "allInAlways", value)
        end),
        auction_always0_get = (function(name)
            return GetRosterOption(name, "always0")
        end),
        auction_always0_set = (function(name, value)
            SetRosterOption(name, "always0", value)
        end),
        auction_equalbids_get = (function(name)
            return GetRosterOption(name, "allowEqualMax")
        end),
        auction_equalbids_set = (function(name, value)
            SetRosterOption(name, "allowEqualMax", value)
        end),
        auction_cancelpass_get = (function(name)
            return GetRosterOption(name, "allowCancelPass")
        end),
        auction_cancelpass_set = (function(name, value)
            SetRosterOption(name, "allowCancelPass", value)
        end),
        auction_use_os_get = (function(name)
            return GetRosterOption(name, "useOS")
        end),
        auction_use_os_set = (function(name, value)
            SetRosterOption(name, "useOS", value)
        end),
        auction_zero_sum_bank_get = (function(name)
            return GetRosterOption(name, "zeroSumBank")
        end),
        auction_zero_sum_bank_set = (function(name, value)
            SetRosterOption(name, "zeroSumBank", value)
        end),
        auction_zero_sum_bank_inflation_value_get = (function(name)
            return tostring(GetRosterOption(name, "zeroSumBankInflation"))
        end),
        auction_zero_sum_bank_inflation_value_set = (function(name, value)
            SetRosterOption(name, "zeroSumBankInflation", value)
        end),
        auction_allow_below_min_standings_get = (function(name)
            return GetRosterOption(name, "allowBelowMinStandings")
        end),
        auction_allow_below_min_standings_set = (function(name, value)
            SetRosterOption(name, "allowBelowMinStandings", value)
        end),
        auction_minimal_increment_get = (function(name)
            return tostring(GetRosterOption(name, "minimalIncrement"))
        end),
        auction_minimal_increment_set = (function(name, value)
            SetRosterOption(name, "minimalIncrement", value)
        end),
        auction_tax_get = (function(name)
            return tostring(GetRosterOption(name, "tax"))
        end),
        auction_tax_set = (function(name, value)
            SetRosterOption(name, "tax", value)
        end),
        auction_auction_time_get = (function(name)
            return tostring(GetRosterOption(name, "auctionTime"))
        end),
        auction_auction_time_set = (function(name, value)
            SetRosterOption(name, "auctionTime", value)
        end),
        auction_antisnipe_time_get = (function(name)
            return tostring(GetRosterOption(name, "antiSnipe"))
        end),
        auction_antisnipe_time_set = (function(name, value)
            SetRosterOption(name, "antiSnipe", value)
        end),
        auction_linear_time_multiply_get = (function(name)
            return GetRosterOption(name, "multiplyTime")
        end),
        auction_linear_time_multiply_set = (function(name, value)
            SetRosterOption(name, "multiplyTime", value)
        end),
        auction_roll_time_get = (function(name)
            return tostring(GetRosterOption(name, "rollTime"))
        end),
        auction_roll_time_set = (function(name, value)
            SetRosterOption(name, "rollTime", value)
        end),
        auction_minimum_points_get = (function(name)
            return tostring(GetRosterOption(name, "minimumPoints"))
        end),
        auction_minimum_points_set = (function(name, value)
            SetRosterOption(name, "minimumPoints", value)
        end),
        general_starting_points_get = (function(name)
            return tostring(GetRosterOption(name, "basePoints"))
        end),
        general_starting_points_set = (function(name, value)
            SetRosterOption(name, "basePoints", value)
        end),
        general_starting_spent_get = (function(name)
            return tostring(GetRosterOption(name, "baseSpent"))
        end),
        general_starting_spent_set = (function(name, value)
            SetRosterOption(name, "baseSpent", value)
        end),
    }

    self:UpdateOptions()

    CLM.MODULES.LedgerManager:RegisterOnUpdate(function(lag, uncommitted)
        if lag ~= 0 or uncommitted ~= 0 then return end
        self:UpdateOptions()
        CLM.MODULES.ConfigManager:UpdateOptions(CONSTANTS.CONFIGS.GROUP.ROSTER)
    end)
end

local CONFIRMATION_GROUPS = UTILS.Set({"general", "auction"})
function RosterManagerOptions:_Handle(cbtype, info, ...)
    -- Assumes This is the handler of each of the subgroups but not the main group
    local roster_name = info[1]
    local group = info[2]
    local node_name
    if #info >= 2 then
        node_name = group
        for i=3,#info do
            node_name = node_name .. "_" .. info[i]
        end
    else
        node_name = info[#info]
    end
    node_name = node_name .. "_".. cbtype

    -- print(node_name)
    -- Execute handler
    if type(self.handlers[node_name]) == "function" then
        return self.handlers[node_name](roster_name, ...)
    end

    if cbtype == CBTYPE.HIDER then
        return false
    end

    if cbtype == CBTYPE.CONFIRMATION then
        if CLM.MODULES.RaidManager:IsInActiveRaid() then
            local raid = CLM.MODULES.RaidManager:GetRaid()
            if raid:Roster() == CLM.MODULES.RosterManager:GetRosterByName(roster_name) and CONFIRMATION_GROUPS[group] then
                return CLM.L["You are changing roster settings during active raid. You can continue without any issues however the settings will not get applied until you start a new one."]
            end
        end

        return false
    end

    return nil
end

function RosterManagerOptions:Getter(info, ...)
   return self:_Handle(CBTYPE.GETTER, info, ...)
end

function RosterManagerOptions:Setter(info, ...)
    if self.readOnly then return end
    self:_Handle(CBTYPE.SETTER, info, ...)
end

function RosterManagerOptions:Handler(info, ...)
    self:_Handle(CBTYPE.EXECUTOR, info, ...)
end

function RosterManagerOptions:Hider(info, ...)
    self:_Handle(CBTYPE.HIDER, info, ...)
end

function RosterManagerOptions:Confirmation(info, ...)
    return self:_Handle(CBTYPE.CONFIRMATION, info, ...)
end

local valuesWithDesc = {
    {
        type = CONSTANTS.SLOT_VALUE_TIER.BASE,
        desc = CLM.L["Base value for Static-Priced auction.\nMinimum value for Ascending and Tiered auction.\n\nSet to same value as other tier or negative to ignore."]
    },
    {
        type = CONSTANTS.SLOT_VALUE_TIER.SMALL,
        desc = CLM.L["Small value for Tiered auction.\n\nSet to same value as other tier or negative to ignore."]
    },
    {
        type = CONSTANTS.SLOT_VALUE_TIER.MEDIUM,
        desc = CLM.L["Medium value for Tiered auction.\n\nSet to same value as other tier or negative to ignore."]
    },
    {
        type = CONSTANTS.SLOT_VALUE_TIER.LARGE,
        desc = CLM.L["Large value for Tiered auction.\n\nSet to same value as other tier or negative to ignore."]
    },
    {
        type = CONSTANTS.SLOT_VALUE_TIER.MAX,
        desc = CLM.L["Maximum value for Ascending and Tiered auction.\n\nSet to same value as other tier or negative to ignore."]
    }
}

local function generateDynamicItemValuesHandlers(roster)
    local equationGet = (function()
        return roster:GetCalculator():GetEquation()
    end)
    local equationSet = (function(value)
        CLM.MODULES.RosterManager:SetRosterDynamicItemValueEquation(roster, value)
    end)
    local expvarGet = (function()
        return roster:GetCalculator():GetExpvar()
    end)
    local expvarSet = (function(value)
        CLM.MODULES.RosterManager:SetRosterDynamicItemValueExpvar(roster, value)
    end)
    local multiplierGet = (function()
        return roster:GetCalculator():GetMultiplier()
    end)
    local multiplierSet = (function(value)
        CLM.MODULES.RosterManager:SetRosterDynamicItemValueMultiplier(roster, value)
    end)
    local slotGet = (function(slot)
        return roster:GetCalculator():GetSlotMultiplier(slot)
    end)
    local slotSet = (function(slot, value)
        CLM.MODULES.RosterManager:SetRosterDynamicItemValueSlotMultiplier(roster, slot, value)
    end)
    local tierGet = (function(tier)
        return roster:GetCalculator():GetTierMultiplier(tier)
    end)
    local tierSet = (function(tier, value)
        CLM.MODULES.RosterManager:SetRosterDynamicItemValueTierMultiplier(roster, tier, value)
    end)
    local customExpressionGet = (function()
        return roster:GetCalculator():GetCustomExpression()
    end)
    local customExpressionSet = (function(value)
        CLM.MODULES.RosterManager:SetRosterDynamicItemValueCustomExpression(roster, value)
    end)
    return equationGet, equationSet, expvarGet, expvarSet, multiplierGet, multiplierSet, slotGet, slotSet, tierGet, tierSet, customExpressionGet, customExpressionSet
end

local function default_slot_values(self, roster)
    local args = {}
    local order = 0
    local prefix
    for _, slot in ipairs(CONSTANTS.INVENTORY_TYPES_SORTED) do
        prefix = slot.type:lower()
        args[prefix .. "_header"] = {
            type = "header",
            order = order,
            name = slot.name
        }
        order = order + 1
        args[prefix .. "_icon"] = {
            name = "",
            type = "description",
            image = slot.icon,
            order = order,
            width = 0.5
        }
        order = order + 1
        for _, ivalues in ipairs(valuesWithDesc) do
            args[prefix .. "_" .. ivalues.type] = {
                type = "input",
                order = order,
                desc = ivalues.desc,
                width = 0.5,
                get = (function(i)
                    return tostring(roster:GetDefaultSlotTierValue(slot.type, ivalues.type))
                end),
                set = (function(i, v)
                    if self.readOnly then return end
                    CLM.MODULES.RosterManager:SetRosterDefaultSlotTierValue(roster, slot.type, ivalues.type, tonumber(v))
                end),
                -- name = (CONSTANTS.SLOT_VALUE_TIERS_GUI[ivalues.type] or ""),
                name = UTILS.GetRosterConditionalFieldName(ivalues.type, roster),
                pattern = CONSTANTS.REGEXP_FLOAT,
            }
            order = order + 1
        end
    end
    return args
end

local function dynamic_item_values(self, roster, equationGet, equationSet, expvarGet, expvarSet, multiplierGet, multiplierSet, slotGet, slotSet, tierGet, tierSet, customExpressionGet, customExpressionSet)
    local args = {}
    local order = 0
    local prefix
    args["equation_header"] = {
        type = "header",
        order = order,
        name = CLM.L["Equation"]
    }
    order = order + 1
    local wowpedia = "WoWpedia: |c43eeee00[Multiplier] * [item value]^[Exponent] * [slot multiplier]|r\n\n"
    local epgpweb = "EPGPWeb: |c43eeee00[Multiplier] * [Base]^(ilvl/26 + (rarity - 4)) * [slot multiplier]|r\n\n"
    local custom = "Custom: |c43eeee00" .. CLM.L["Your custom defined expression"] .. "|r\n\n"
    local equationNote = "|c43ee4444Changing this will reset slot multipliers to default values.|r"
    args["equation_select"] = {
        type = "select",
        style = "dropdown",
        desc = epgpweb .. wowpedia .. custom .. equationNote,
        order = order,
        values = CONSTANTS.ITEM_VALUE_EQUATIONS_GUI,
        sorting = CONSTANTS.ITEM_VALUE_EQUATIONS_ORDERED,
        set = (function(i, v)
            if self.readOnly then return end
            equationSet(tonumber(v))
        end),
        get = (function(i) return equationGet() end),
        name = CLM.L["Select equation"]
    }
    order = order + 1
    args["equation_multiplier"] = {
        type = "input",
        desc = CLM.L["Multiplier used by the equations"],
        order = order,
        width = 0.5,
        get = (function(i) return tostring(multiplierGet()) end),
        set = (function(i, v)
            if self.readOnly then return end
            multiplierSet(tonumber(v))
        end),
        name = CLM.L["Multiplier"],
        pattern = CONSTANTS.REGEXP_FLOAT,
    }
    order = order + 1
    args["equation_expvar"] = {
        type = "input",
        desc = CLM.L["Exponential scaling value used by the equations (Base for EPGPWeb, or Exponent for WoWpedia)"],
        order = order,
        width = 0.5,
        get = (function(i) return tostring(expvarGet()) end),
        set = (function(i, v)
            if self.readOnly then return end
            expvarSet(tonumber(v))
        end),
        name = CLM.L["Exponent / Base"],
        pattern = CONSTANTS.REGEXP_FLOAT,
    }
    order = order + 1
    local customExpressionDesc = CLM.L["A custom expression to calculate item values."] .. "\n\n"
            .. CLM.L["Available variables"] .. ":\n\n"
            .. "|c43eeee00" .. table.concat(self.variableNames, "\n\n") .. "|r\n\n"
            .. "|c43ee4444" ..CLM.L["Only used when equation is set to Custom."] .. "|r"
    args["equation_customExpression"] = {
        type = "input",
        desc = customExpressionDesc,
        order = order,
        width = "full",
        get = (function() return tostring(customExpressionGet()) end),
        set = (function(_, v)
            if self.readOnly then return end
            customExpressionSet(tostring(v))
        end),
        name = CLM.L["Custom Expression"],
        validate = (function(_, expression)
            local success, errors = ExpressionParser:IsValidExpression(expression, CONSTANTS.CUSTOM_EQUATION_VARIABLES)
            if not success then
                print("|cff00cc00CLM |c43ee4444" .. CLM.L["Custom expression has the following issue(s)"] .. ":|r")
                for _, error in ipairs(errors) do
                    print("|c43ee4444||||====>|r " .. error)
                end
                return false
            end
            return true
        end),
        hidden = function()
            return equationGet() ~= CONSTANTS.ITEM_VALUE_EQUATION.CUSTOM
        end
    }
    order = order + 1
    args["slot_multipliers_header"] = {
        type = "header",
        order = order,
        name = CLM.L["Slot multipliers"]
    }
    order = order + 1
    for _, slot in ipairs(CONSTANTS.INVENTORY_TYPES_SORTED) do
        prefix = slot.type
        if CONSTANTS.ITEM_SLOT_MULTIPLIERS[prefix] then
            args[prefix .. "_"] = {
                type = "input",
                order = order,
                width = 0.5,
                get = (function(i) return tostring(slotGet(slot.type)) end),
                set = (function(i, v)
                    if self.readOnly then return end
                    slotSet(slot.type, tonumber(v))
                end),
                name = slot.name,
                pattern = CONSTANTS.REGEXP_FLOAT,
            }
            order = order + 1
        end
    end
    args["tier_multipliers_header"] = {
        type = "header",
        order = order,
        name = CLM.L["Tier multipliers"]
    }
    order = order + 1
    for _, ivalues in ipairs(valuesWithDesc) do
        -- local tierName = (CONSTANTS.SLOT_VALUE_TIERS_GUI[ivalues.type] or "")
        local tierName = UTILS.GetRosterConditionalFieldName(ivalues.type, roster)
        args[prefix .. "_" .. ivalues.type] = {
            type = "input",
            order = order,
            desc = string.format(CLM.L["Multiplier for tier %s (if used by the auction type)."], tierName),
            width = 0.6,
            get = (function(i) return tostring(tierGet(ivalues.type)) end),
            set = (function(i, v)
                if self.readOnly then return end
                tierSet(ivalues.type, tonumber(v))
            end),
            name = tierName,
            pattern = CONSTANTS.REGEXP_FLOAT,
        }
        order = order + 1
    end
    return args
end

local function item_value_overrides(self, roster)
    local items = roster:GetAllItemValues()
    local args = {}
    local order = 1
    for id,_ in pairs(items) do
        local _, _, _, _, icon = UTILS.GetItemInfoInstant(id)
        local shortItemLink = "item:" .. tostring(id)
        if icon then
            local sid = tostring(id)
            local prefix = "i" .. sid
            args[prefix .. "icon"] = {
                    name = "",
                    image = icon,
                    order = order,
                    width = 0.35,
                    type = "execute",
                    func = (function() end),
                    tooltipHyperlink = shortItemLink,
                }
            order = order + 1
            for _, ivalues in ipairs(valuesWithDesc) do
                args[prefix .. "_" .. ivalues.type] = {
                    type = "input",
                    order = order,
                    -- desc = ivalues.desc,
                    width = 0.5,
                    set = (function(i, v)
                        if self.readOnly then return end
                        CLM.MODULES.RosterManager:SetRosterItemTierValue(roster, id, ivalues.type, tonumber(v))
                    end),
                    get = (function(i)
                        local values = roster:GetItemValues(id)
                        return tostring(values[ivalues.type])
                    end),
                    -- name = (CONSTANTS.SLOT_VALUE_TIERS_GUI[ivalues.type] or ""),
                    name = UTILS.GetRosterConditionalFieldName(ivalues.type, roster),
                    pattern = CONSTANTS.REGEXP_FLOAT,
                }
                order = order + 1
            end
            args[prefix .. "remove"] = {
                name = "x",
                desc = CLM.L["Remove override"],
                -- image = icon,
                order = order,
                width = 0.30,
                type = "execute",
                func = (function() CLM.MODULES.RosterManager:RemoveRosterItemOverride(roster, id) end)
            }
            order = order + 6
        end
    end
    return args
end

local function generateBossKillAwardValueInputField(self, roster, info, instanceName, name, difficultyId, order, isHardMode, fields)
    local nameModified = CLM.DifficultyIDsMap[difficultyId] .. (isHardMode and (" " .. CLM.UTILS.ColorCodeText(CLM.L["Hard Mode"], "ee4444")) or "")
    local width
    fields = tonumber(fields)
    if fields == nil or fields <= 1 then
        width = "full"
    else
        width = 3/fields
    end
    return {
        name = nameModified,
        desc = instanceName .. " - " .. info.name,
        type = "input",
        width = width,
        order = order,
        set = (function(i, v)
            if self.readOnly then return end
            CLM.MODULES.RosterManager:SetRosterBossKillBonusValue(name, info.id, difficultyId, isHardMode, v)
        end),
        get = (function(i)
            return tostring(roster:GetBossKillBonusValue(info.id, difficultyId, isHardMode))
        end)
    }
end

local expansionInfoMap = {
    [LE_EXPANSION_CLASSIC]                  = { name = CLM.L["Classic"],                offset =  10000 },
    [LE_EXPANSION_BURNING_CRUSADE]          = { name = CLM.L["The Burning Crusade"],    offset =  20000 },
    [LE_EXPANSION_WRATH_OF_THE_LICH_KING]   = { name = CLM.L["Wrath of the Lich King"], offset =  30000 },
    [LE_EXPANSION_CATACLYSM]                = { name = CLM.L["Cataclysm"],              offset =  40000 },
    [LE_EXPANSION_DRAGONFLIGHT]             = { name = CLM.L["Dragonflight"],           offset = 100000 },
    [LE_EXPANSION_WAR_WITHIN]               = { name = CLM.L["The War Within"],         offset = 110000 },
    ["SOD"]                                 = { name = CLM.L["Season of Discovery"],    offset = 990000 },
}

local function boss_kill_award_values(self, roster, name)
    local args = {}
    -- Common
    local order
    for expansion, encounters in pairs(CLM.EncounterIDs) do
        local expansion_key = "e" .. tostring(expansion)
        order = expansionInfoMap[expansion].offset
        if not args[expansion_key] then
            args[expansion_key] = {
                type = "group",
                name = expansionInfoMap[expansion].name,
                args = {},
                order = order,
                childGroups = "select",
            }
        end
        -- For each instance
        for _, instanceData in ipairs(encounters) do
            order = order + 1
            args[expansion_key].args[instanceData.name] = {
                type = "group",
                name = instanceData.name,
                args = {},
                order = order,
            }
            -- For each boss
            local numDifficultyLevels = #instanceData.difficulty
            for _, info in ipairs(instanceData.data) do
                order = order + 1
                -- Header
                local instanceName = instanceData.name
                if info.name == nil then
                    print(instanceName, info.id, info.name)
                end
                args[expansion_key].args[instanceData.name].args["encounter_header_" .. info.name] = {
                    name = info.name or "???",
                    type = "header",
                    order = order,
                    width = "full"
                }
                -- For each difficulty
                for _,difficultyId in ipairs(instanceData.difficulty) do
                    local hardmode = CLM.EncounterHasHardMode[info.id] and true or false
                    order = order + 1
                    args[expansion_key].args[instanceData.name].args["encounter" .. info.id .. difficultyId] =
                        generateBossKillAwardValueInputField(
                            self, roster, info,
                            instanceName, name, difficultyId,
                            order, false, numDifficultyLevels + (hardmode and numDifficultyLevels or 0)
                        )
                    if hardmode then
                        order = order + 1
                        args[expansion_key].args[instanceData.name].args["encounter" .. info.id .. difficultyId .. "hm"] =
                        generateBossKillAwardValueInputField(
                            self, roster, info,
                            instanceName, name, difficultyId,
                            order, true, numDifficultyLevels + (hardmode and numDifficultyLevels or 0)
                        )
                    end
                end
            end
        end
    end
    return args
end

local function award_multipliers(self, roster)
    local args = {}

    for i, class in ipairs(UTILS.GetClassList()) do
        args[class] = {
            type = "group",
            name = UTILS.ColorCodeAndLocalizeClass(class),
            order = i,
            args = {}
        }
        local order = 0
        local prefix
        for _, slot in ipairs(CONSTANTS.INVENTORY_TYPES_SORTED) do
            prefix = slot.type:lower()
            order = order + 1
            args[class].args[prefix .. "_value"] = {
                type = "input",
                order = order,
                width = 0.5,
                get = (function()
                    return tostring(roster:GetSlotClassMultiplierValue(class, slot.type))
                end),
                set = (function(_, v)
                    if self.readOnly then return end
                    CLM.MODULES.RosterManager:SetSlotClassMultiplierValue(roster, class, slot.type, tonumber(v))
                end),
                name = slot.name,
                pattern = CONSTANTS.REGEXP_FLOAT,
            }
            order = order + 1
        end
    end
    return args
end

function RosterManagerOptions:GenerateRosterOptions(name)
    local roster = CLM.MODULES.RosterManager:GetRosterByName(name)
    local isManager = CLM.MODULES.ACL:CheckLevel(CONSTANTS.ACL.LEVEL.MANAGER)

    local isEPGP = (roster:GetPointType() == CONSTANTS.POINT_TYPE.EPGP)
    local disableManage = (function() return not isManager end)

    local equationGet, equationSet, expvarGet, expvarSet, multiplierGet, multiplierSet, slotGet, slotSet, tierGet, tierSet, customExpressionGet, customExpressionSet = generateDynamicItemValuesHandlers(roster)

    local options = {
        type = "group",
        name = name,
        handler = self,
        set = "Setter",
        get = "Getter",
        confirm = "Confirmation",
        -- hidden = "Hider",
        func = "Handler",
        childGroups = "select",
        order = roster:UID(),
        args = {
            general = {
                name = CLM.L["General settings"],
                type = "group",
                order = 1,
                args = {
                    name = {
                        name = CLM.L["Name"],
                        desc = CLM.L["Change roster name."],
                        type = "input",
                        width = 1,
                        order = 0
                    },
                    point_type = { -- informative
                        name = CLM.L["Point type"],
                        type = "select",
                        -- style = "radio",
                        get = (function(i)
                            if not roster then return nil end
                            return roster:GetPointType()
                        end),
                        order = 1,
                        disabled = true,
                        width = 1,
                        values = CONSTANTS.POINT_TYPES_GUI
                    },
                    round_decimals = {
                        name = CLM.L["Rounding"],
                        desc = CLM.L["Round to selected number of decimals"],
                        type = "select",
                        -- style = "radio",
                        width = 1,
                        disabled = disableManage,
                        order = 2,
                        values = CONSTANTS.ALLOWED_ROUNDINGS_GUI
                    },
                    copy_header = {
                        name = CLM.L["Copy settings"],
                        type = "header",
                        order = 97,
                        width = "full"
                    },
                    copy = {
                        name = CLM.L["Copy settings"],
                        desc = CLM.L["Copy settings from selected roster."],
                        type = "execute",
                        confirm = true,
                        disabled = disableManage,
                        order = 98
                    },
                    copy_source = {
                        name = CLM.L["Copy source"],
                        desc = CLM.L["Copy settings from selected roster."],
                        type = "select",
                        values = (function()
                            local v = {}
                            local r = CLM.MODULES.RosterManager:GetRosters()
                            for n, _r in pairs(r) do
                                if _r:GetPointType() == roster:GetPointType() then
                                    v[n] = n
                                end
                            end
                            return v
                        end),
                        disabled = disableManage,
                        order = 99
                    },
                    remove_header = {
                        name = CLM.L["Remove roster"],
                        type = "header",
                        order = 100,
                        width = "full"
                    },
                    remove = {
                        name = CLM.L["Remove"],
                        desc = CLM.L["Removes current roster."],
                        type = "execute",
                        confirm = true,
                        disabled = disableManage,
                        order = 101
                    },
                    --
                    bonuses_header = {
                        name = CLM.L["Bonuses"],
                        type = "header",
                        order = 4,
                        width = "full"
                    },
                    boss_kill_bonus = {
                        name = CLM.L["Boss Kill Bonus"],
                        type = "toggle",
                        order = 5,
                        disabled = disableManage,
                        width = 1
                    },
                    boss_kill_bonus_value = {
                        name = CLM.L["Default Boss Kill Bonus Value"],
                        type = "input",
                        order = 8,
                        pattern = CONSTANTS.REGEXP_FLOAT_POSITIVE,
                        disabled = disableManage,
                        width = 1
                    },
                    on_time_bonus = {
                        name = CLM.L["On Time Bonus"],
                        type = "toggle",
                        order = 6,
                        disabled = disableManage,
                        width = 1
                    },
                    on_time_bonus_value = {
                        name = CLM.L["On Time Bonus Value"],
                        type = "input",
                        order = 9,
                        pattern = CONSTANTS.REGEXP_FLOAT_POSITIVE,
                        disabled = disableManage,
                        width = 1
                    },
                    raid_completion_bonus = {
                        name = CLM.L["Raid Completion Bonus"],
                        type = "toggle",
                        order = 7,
                        disabled = disableManage,
                        width = 1
                    },
                    raid_completion_bonus_value = {
                        name = CLM.L["Raid Completion Value"],
                        type = "input",
                        order = 10,
                        pattern = CONSTANTS.REGEXP_FLOAT_POSITIVE,
                        disabled = disableManage,
                        width = 1
                    },
                    interval_bonus = {
                        name = CLM.L["Interval Bonus"],
                        type = "toggle",
                        order = 11,
                        disabled = disableManage,
                        width = 1
                    },
                    interval_bonus_time = {
                        name = CLM.L["Interval Time"],
                        desc = CLM.L["Interval in [minutes] to award bonus points"],
                        type = "input",
                        order = 12,
                        pattern = CONSTANTS.REGEXP_FLOAT_POSITIVE,
                        disabled = disableManage,
                        -- width = 0.6
                    },
                    interval_bonus_value = {
                        name = CLM.L["Interval Value"],
                        type = "input",
                        order = 13,
                        pattern = CONSTANTS.REGEXP_FLOAT_POSITIVE,
                        disabled = disableManage,
                        -- width = 0.6
                    },
                    auto_award_include_bench =  {
                        name = CLM.L["Include bench"],
                        desc = CLM.L["Include benched players in all auto-awards"],
                        type = "toggle",
                        order = 14,
                        disabled = disableManage,
                        -- width = 2
                    },
                    auto_award_online_only =  {
                        name = CLM.L["Online only"],
                        desc = CLM.L["Award points only to online players"],
                        type = "toggle",
                        order = 15,
                        -- disabled = disableManage,
                        disabled = true,
                        width = 1
                    },
                    auto_award_same_zone_only =  {
                        name = CLM.L["Same zone only"],
                        desc = CLM.L["Award points only to players in same zone"],
                        type = "toggle",
                        order = 16,
                        -- disabled = disableManage,
                        disabled = true,
                        width = 1
                    },
                    point_caps_header = {
                        name = CLM.L["Point caps"],
                        type = "header",
                        order = 17,
                        width = "full"
                    },
                    weekly_reset_timezone = {
                        name = CLM.L["Weekly reset timezone"],
                        desc = CLM.L["Select weekly reset timezone. EU: Wed 07:00 GMT or US: Tue 15:00 GMT"],
                        type = "select",
                        -- style = "radio",
                        disabled = disableManage,
                        order = 18,
                        values = CONSTANTS.WEEKLY_RESETS_GUI
                    },
                    weekly_cap = {
                        name = CLM.L["Weekly cap"],
                        desc = CLM.L["Maximum point cap player can receive per raid week. Set to 0 to disable."],
                        type = "input",
                        disabled = disableManage,
                        order = 19,
                        pattern = CONSTANTS.REGEXP_FLOAT_POSITIVE,
                        -- width = 0.6
                    },
                    hard_cap = {
                        name = CLM.L["Hard cap"],
                        desc = CLM.L["Maximum point cap that player can have. Set to 0 to disable."],
                        type = "input",
                        disabled = disableManage,
                        order = 20,
                        pattern = CONSTANTS.REGEXP_FLOAT_POSITIVE,
                        -- width = 0.6
                    },
                    starting_points_header = {
                        name = CLM.L["Starting points"],
                        type = "header",
                        order = 21,
                        width = "full"
                    },
                    starting_points = {
                        name = function() return string.format(CLM.L["Starting %s"], isEPGP and CLM.L["EP"] or CLM.L["DKP"]) end,
                        desc = function() return string.format(CLM.L["%s to be awarded to player when joining roster."], isEPGP and CLM.L["EP"] or CLM.L["DKP"]) end,
                        type = "input",
                        disabled = disableManage,
                        order = 22,
                        pattern = CONSTANTS.REGEXP_FLOAT_POSITIVE,
                    },
                    starting_spent = {
                        name = function() return string.format(CLM.L["Starting %s"], CLM.L["GP"]) end,
                        desc = function() return string.format(CLM.L["%s to be awarded to player when joining roster."], CLM.L["GP"]) end,
                        type = "input",
                        disabled = disableManage,
                        order = 23,
                        hidden = not isEPGP,
                        pattern = CONSTANTS.REGEXP_FLOAT_POSITIVE,
                    },
                    bench_header = {
                        name = CLM.L["Bench"],
                        type = "header",
                        order = 24,
                        width = "full"
                    },
                    allow_self_bench_subscribe =  {
                        name = CLM.L["Allow subscription"],
                        desc = CLM.L["Allow players to subscribe to the bench through Raids menu"],
                        type = "toggle",
                        order = 25,
                        disabled = disableManage,
                        width = 1
                    },
                    auto_bench_leavers =  {
                        name = CLM.L["Auto bench leavers"],
                        desc = CLM.L["Put players leaving raid on bench instead of removing them. To remove them completely they will need to be removed manually from the bench."],
                        type = "toggle",
                        order = 26,
                        disabled = disableManage,
                        width = 1
                    },
                    bench_multiplier =  {
                        name = CLM.L["Bench multiplier"],
                        desc = CLM.L["Point award multiplier for players on bench."],
                        type = "input",
                        order = 27,
                        disabled = disableManage,
                        pattern = CONSTANTS.REGEXP_FLOAT_POSITIVE,
                        width = 1
                    },
                    named_buttons_header = {
                        name = CLM.L["Button Names"],
                        type = "header",
                        order = 28,
                        width = "full"
                    },
                    epgp_header = {
                        name = CLM.L["EPGP"],
                        type = "header",
                        order = 36,
                        width = "full",
                        hidden = not isEPGP,
                    },
                    min_gp = {
                        name = CLM.L["Minimum GP"],
                        desc = CLM.L["Minimum GP used in calculations when player has less GP than this value."],
                        type = "input",
                        disabled = disableManage,
                        pattern = CONSTANTS.REGEXP_FLOAT_POSITIVE,
                        order = 37,
                        hidden = not isEPGP,
                    },
                    round_pr = {
                        name = CLM.L["PR Rounding"],
                        desc = CLM.L["Round PR to selected number of decimals"],
                        type = "select",
                        width = 1,
                        disabled = disableManage,
                        order = 38,
                        hidden = not isEPGP,
                        values = CONSTANTS.ALLOWED_ROUNDINGS_GUI
                    },
                },
            },
            auction = {
                name = CLM.L["Auction settings"],
                type = "group",
                order = 2,
                args = {
                    item_value_mode = {
                        name = CLM.L["Item value mode"],
                        desc = CLM.L["|cff00ee44Single-Priced:|r Static value mode. Only bidding Base value is supported.\n\n|cff00ee44Ascending:|r Ranged value mode. Allows bidding any value in |cff44ee00<base, max>|r.\n\n|cff00ee44Tiered:|r Ranged value mode. Allows bidding only specific values. Up to 5 tiers are configurable in |cff44ee00<base, small, medium, large, max>|r."],
                        type = "select",
                        disabled = disableManage,
                        order = 5,
                        values = CONSTANTS.ITEM_VALUE_MODES_GUI
                    },
                    dynamic_item_values = {
                        name = CLM.L["Dynamic Item values"],
                        type = "toggle",
                        order = 6,
                        disabled = disableManage,
                        width = 1
                    },
                    bidding_header = {
                        name = CLM.L["Bidding"],
                        type = "header",
                        order = 10,
                        width = "full"
                    },
                    minimum_points = {
                        name = CLM.L["Minimum standing"],
                        desc = CLM.L["Minimum standing required to be allowed to bid."],
                        type = "input",
                        disabled = disableManage,
                        pattern = CONSTANTS.REGEXP_FLOAT,
                        width = 1,
                        order = 11
                    },
                    use_os = {
                        name = CLM.L["OS"],
                        desc = CLM.L["Enable OS bids"],
                        type = "toggle",
                        disabled = disableManage,
                        width = 1,
                        order = 12
                    },
                    cancelpass = {
                        name = CLM.L["Always allow cancel/pass"],
                        desc = CLM.L["Enable to always allow cancelling or passing bids. Affects Open-Ascending Auction."],
                        type = "toggle",
                        disabled = disableManage,
                        width = 2,
                        order = 12.1
                    },
                    time_header = {
                        name = CLM.L["Time"],
                        type = "header",
                        order = 13,
                        width = "full"
                    },
                    auction_time = {
                        name = CLM.L["Auction length"],
                        desc = CLM.L["Auction length in seconds."],
                        type = "input",
                        disabled = disableManage,
                        pattern = CONSTANTS.REGEXP_FLOAT_POSITIVE,
                        width = 1,
                        order = 14
                    },
                    antisnipe_time = {
                        name = CLM.L["Anti-snipe time"],
                        desc = CLM.L["Time in seconds by which auction will be extended if bid is received during last 10 seconds."],
                        type = "input",
                        disabled = disableManage,
                        pattern = CONSTANTS.REGEXP_FLOAT_POSITIVE,
                        width = 1,
                        order = 15
                    },
                    linear_time_multiply = {
                        name = CLM.L["Multiply time"],
                        desc = CLM.L["Multiply auction time by the number of items to increase auction time lineary."],
                        type = "toggle",
                        disabled = disableManage,
                        width = 1,
                        order = 16
                    },
                    roll_time = {
                        name = CLM.L["Roll"] .. " " .. CLM.L["Time"],
                        desc = CLM.L["Roll"] .. " " .. CLM.L["Time"],
                        type = "input",
                        disabled = disableManage,
                        pattern = CONSTANTS.REGEXP_FLOAT_POSITIVE,
                        width = 1,
                        order = 20
                    },
                },
            },
            default_slot_values = {
                name = CLM.L["Default slot values"],
                type = "group",
                order = 3,
                args = default_slot_values(self, roster)
            },
            award_multipliers = {
                name = CLM.L["Award"] .. " " .. CLM.L["Multiplier"],
                type = "group",
                order = 4,
                childGroups = "tab",
                args = award_multipliers(self, roster)
            },
            item_value_overrides = {
                name = CLM.L["Item value overrides"],
                type = "group",
                order = 5,
                args = item_value_overrides(self, roster)
            },
            dynamic_item_values = {
                name = CLM.L["Dynamic Item values"],
                type = "group",
                order = 6,
                args = dynamic_item_values(self, roster, equationGet, equationSet, expvarGet, expvarSet, multiplierGet, multiplierSet, slotGet, slotSet, tierGet, tierSet, customExpressionGet, customExpressionSet)
            },
            boss_kill_award_values = {
                name = CLM.L["Boss kill award values"],
                type = "group",
                order = 7,
                -- childGroups = "tab",
                childGroups = "select",
                args = boss_kill_award_values(self, roster, name)
            }
        }
    }
    options.args.auction.args.auction_type = {
        name = CLM.L["Auction type"],
        desc = CLM.L["|cff00ee44Open:|r English Auction with highest bidder announcement. Highest bidder wins. Two players can not bid same value. Additionally always allows bidding base to accomodate for Swedish Auction flavor.\n\n|cff00ee44Anonymous Open:|r Same as Open but highest bidder name is not disclosed.\n\n|cff00ee44Sealed:|r Bids are not announced. Highest bidder wins.\n\n|cff00ee44Vickrey:|r Same as sealed but winner pays with second-highest bid."],
        type = "select",
        disabled = disableManage,
        order = 4,
        values = CONSTANTS.AUCTION_TYPES_GUI
    }
    -- Button names
    options.args.general.args.named_buttons_toggle = {
        name = CLM.L["Use named buttons"],
        desc = CLM.L["Will display names of the buttons instead of values in bidding UI"],
        type = "toggle",
        order = 29,
        disabled = disableManage,
        width = 1
    }
    local order = 30
    for _, tier in ipairs(CONSTANTS.SLOT_VALUE_TIERS_ORDERED) do
        options.args.general.args["named_button_tier_" .. tostring(tier)] = {
            -- name = CONSTANTS.SLOT_VALUE_TIERS_GUI[tier],
            name = UTILS.GetRosterConditionalFieldName(tier, roster),
            type = "input",
            set = (function(i, v) CLM.MODULES.RosterManager:SetFieldName(roster, tier, v) end),
            get = (function(i) return roster:GetFieldName(tier) end),
            order = order,
            disabled = disableManage,
            width = 1
        }
        order = order + 1
    end
    -- Point Specific auction settings
    if roster:GetPointType() == CONSTANTS.POINT_TYPE.DKP then
        options.args.auction.args.base_always = {
            name = CLM.L["Always allow Base bids"],
            desc = CLM.L["Enable to allow base bids even if higher bids are present if player didn't bid yet. Affects Open-Ascending Auction."],
            type = "toggle",
            disabled = disableManage,
            width = 1,
            order = 12.1
        }
        options.args.auction.args.allin_always = {
            name = CLM.L["Always allow All-In bids"],
            desc = CLM.L["Enable to always allow All-In bids. Affects Open-Ascending Auction."],
            type = "toggle",
            disabled = disableManage,
            width = 1,
            order = 12.2
        }
        options.args.auction.args.equalbids = {
            name = CLM.L["Allow equal bids"],
            desc = CLM.L["Enable to allow equal bids. Affects Open-Ascending Auction."],
            type = "toggle",
            disabled = disableManage,
            width = 1,
            order = 12.3
        }
        options.args.auction.args.always0 = {
            name = CLM.L["Always allow 0 bids"],
            desc = CLM.L["Enable to always allow 0 bids. Affects ascending item value mode."],
            type = "toggle",
            disabled = disableManage,
            width = 1,
            order = 12.4
        }
        options.args.auction.args.item_value_mode = {
            name = CLM.L["Item value mode"],
            desc = CLM.L["|cff00ee44Single-Priced:|r Static value mode. Only bidding Base value is supported.\n\n|cff00ee44Ascending:|r Ranged value mode. Allows bidding any value in |cff44ee00<base, max>|r.\n\n|cff00ee44Tiered:|r Ranged value mode. Allows bidding only specific values. Up to 5 tiers are configurable in |cff44ee00<base, small, medium, large, max>|r."],
            type = "select",
            disabled = disableManage,
            order = 5,
            values = CONSTANTS.ITEM_VALUE_MODES_GUI
        }
        options.args.auction.args.zero_sum_header = {
            name = CLM.L["Zero-Sum"],
            type = "header",
            order = 7,
            width = "full"
        }
        options.args.auction.args.zero_sum_bank = {
            name = CLM.L["Zero-Sum Bank"],
            desc = CLM.L["Enable paid value splitting amongst raiders."],
            type = "toggle",
            disabled = disableManage,
            width = 1,
            order = 8
        }
        options.args.auction.args.zero_sum_bank_inflation_value = {
            name = CLM.L["Zero-Sum Inflation Value"],
            desc = CLM.L["Additional points to be given to players atop of the split value."],
            type = "input",
            disabled = disableManage,
            pattern = CONSTANTS.REGEXP_FLOAT_POSITIVE,
            width = 1,
            order = 9
        }
        options.args.auction.args.allow_below_min_standings = {
            name = CLM.L["Allow biding more than current standings"],
            desc = CLM.L["Allow biding more than current standings and ending up with less than minimum standings."],
            type = "toggle",
            disabled = disableManage,
            width = 2,
            order = 11
        }
        options.args.auction.args.other_header = {
            name = CLM.L["Other"],
            type = "header",
            order = 16,
            width = "full"
        }
        options.args.auction.args.minimal_increment = {
            name = CLM.L["Minimal increment"],
            desc = CLM.L["Minimal value increment for open auction mode."],
            type = "input",
            disabled = disableManage,
            pattern = CONSTANTS.REGEXP_FLOAT_POSITIVE,
            width = 1,
            order = 17
        }
        options.args.auction.args.tax = {
            name = CLM.L["Tax"],
            desc = CLM.L["Additional cost (tax) to add to the award value."],
            type = "input",
            disabled = disableManage,
            pattern = CONSTANTS.REGEXP_FLOAT_POSITIVE,
            width = 1,
            order = 18
        }
    end
    return options
end

function RosterManagerOptions:UpdateOptions()
    local options = {
        new = { -- Global options -> Create New Roster
            name = CLM.L["Create"],
            desc = CLM.L["Creates new roster with default configuration"],
            type = "execute",
            func = function() CLM.MODULES.RosterManager:NewRoster(self.pointType, self.rosterName); self.rosterName = CLM.MODULES.RosterManager:GenerateName() end,
            disabled = (function() return not CLM.MODULES.ACL:CheckLevel(CONSTANTS.ACL.LEVEL.MANAGER) end),
            order = 1
        },
        roster_name = {
            name = CLM.L["Roster name"],
            desc = CLM.L["Roster Name"],
            type = "input",
            set = (function(i, v) self.rosterName = v end),
            get = (function(i) return self.rosterName end),
            disabled = (function() return not CLM.MODULES.ACL:CheckLevel(CONSTANTS.ACL.LEVEL.MANAGER) end),
            order = 2,
        },
        point_type = {
            name = CLM.L["Point type"],
            desc = CLM.L["Select DKP or EPGP point system."],
            type = "select",
            set = (function(i, v) self.pointType = v end),
            get = (function(i) return self.pointType end),
            order = 3,
            -- disabled = true,--(function() return not CLM.MODULES.ACL:CheckLevel(CONSTANTS.ACL.LEVEL.MANAGER) end),
            values = CONSTANTS.POINT_TYPES_GUI
        },
    }
    for _, name in pairs(CLM.MODULES.RosterManager:GetRostersUidMap()) do
        options[name] = self:GenerateRosterOptions(name)
    end
    CLM.MODULES.ConfigManager:Register(CONSTANTS.CONFIGS.GROUP.ROSTER, options, true)
end

CLM.OPTIONS.RosterManager = RosterManagerOptions
