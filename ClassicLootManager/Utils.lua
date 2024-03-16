---@diagnostic disable: param-type-mismatch
local CLM = select(2, ...) ---@class CLM

local LOG = CLM.LOG
local CONSTANTS = CLM.CONSTANTS

---@class UTILS
local UTILS = {}

local CLM_ICON_DARK = "Interface\\AddOns\\ClassicLootManager\\Media\\Icons\\clm-dark-32.png"

local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")
UTILS.LibDD = LibDD
local DumpTable = LibStub("EventSourcing/Util").DumpTable

---@param string string?
---@return string
local function capitalize(string)
    string = string or ""
    return string.upper(string.sub(string, 1,1)) .. string.lower(string.sub(string, 2))
end

---@type table<integer, string>
local numberToClass = {
    [1]  = "Warrior",
    [2]  = "Paladin",
    [3]  = "Hunter",
    [4]  = "Rogue",
    [5]  = "Priest",
    [6]  = "Death Knight",
    [7]  = "Shaman",
    [8]  = "Mage",
    [9]  = "Warlock",
    [10] = "Monk",
    [11] = "Druid",
    [12] = "Demon Hunter",
    [13] = "Evoker"
}
local classOrdered
if CLM.WoW10 then
    classOrdered = { "Death Knight", "Demon Hunter", "Druid", "Evoker", "Hunter", "Mage", "Monk", "Priest", "Rogue", "Shaman", "Paladin", "Warlock", "Warrior" }
elseif CLM.WoWSeasonal then
    classOrdered = { "Druid", "Hunter", "Mage", "Priest", "Rogue", "Shaman", "Paladin", "Warlock", "Warrior" }
else
    classOrdered = { "Death Knight", "Druid", "Hunter", "Mage", "Priest", "Rogue", "Shaman", "Paladin", "Warlock", "Warrior" }
end
local classToNumber = {}
for k, v in pairs(numberToClass) do
    classToNumber[v] = k
end

---@param class string
---@return integer
function UTILS.ClassToNumber(class)
    return classToNumber[class] or 0
end

---@param number integer
---@return string
function UTILS.NumberToClass(number)
    return numberToClass[number] or ""
end

---@type table<string, canonicalClass>
local classToCanonical = {
    ["Warrior"] = "WARRIOR",
    ["Paladin"] = "PALADIN",
    ["Hunter"] = "HUNTER",
    ["Rogue"] = "ROGUE",
    ["Priest"] = "PRIEST",
    ["Death Knight"] = "DEATHKNIGHT",
    ["Shaman"] = "SHAMAN",
    ["Mage"] = "MAGE",
    ["Warlock"] = "WARLOCK",
    ["Monk"] = "MONK",
    ["Druid"] = "DRUID",
    ["Demon Hunter"] = "DEMONHUNTER",
    ["Evoker"] = "EVOKER",
}

---comment
---@param class string
---@return canonicalClass?
function UTILS.CanonicalClass(class)
    return classToCanonical[class]
end

---@type table<canonicalClass, integer>
local canonicalToNumber = {
    ["WARRIOR"] = 1,
    ["PALADIN"] = 2,
    ["HUNTER"] = 3,
    ["ROGUE"] = 4,
    ["PRIEST"] = 5,
    ["DEATHKNIGHT"] = 6,
    ["SHAMAN"] = 7,
    ["MAGE"] = 8,
    ["WARLOCK"] = 9,
    ["MONK"] = 10,
    ["DRUID"] = 11,
    ["DEMONHUNTER"] = 12,
    ["EVOKER"] = 13,
}

---@param class canonicalClass
---@return integer
function UTILS.CanonicalClassToNumber(class)
    return canonicalToNumber[class]
end

---@type table<string, ColorDefinition>
local classColors = {
    ["Druid"]           = { a = 1, r = 1,    g = 0.49, b = 0.04, hex = "FF7D0A" },
    ["Hunter"]          = { a = 1, r = 0.67, g = 0.83, b = 0.45, hex = "ABD473" },
    ["Mage"]            = { a = 1, r = 0.25, g = 0.78, b = 0.92, hex = "40C7EB" },
    ["Priest"]          = { a = 1, r = 1,    g = 1,    b = 1,    hex = "FFFFFF" },
    ["Rogue"]           = { a = 1, r = 1,    g = 0.96, b = 0.41, hex = "FFF569" },
    ["Shaman"]          = { a = 1, r = 0.01, g = 0.44, b = 0.87, hex = "0270DD" },
    ["Paladin"]         = { a = 1, r = 0.96, g = 0.55, b = 0.73, hex = "F58CBA" },
    ["Warlock"]         = { a = 1, r = 0.53, g = 0.53, b = 0.93, hex = "8787ED" },
    ["Warrior"]         = { a = 1, r = 0.78, g = 0.61, b = 0.43, hex = "C79C6E" },
    ["Death Knight"]    = { a = 1, r = 0.77, g = 0.12, b = 0.23, hex = "C41E3A" },
    ["Demon Hunter"]    = { a = 1, r = 0.64, g = 0.19, b = 0.79, hex = "A330C9" },
    ["Monk"]            = { a = 1, r = 0,    g = 1.00, b = 0.60, hex = "00FF98" },
    ["Evoker"]          = { a = 1, r = 0.20, g = 0.58, b = 0.50, hex = "33937F" },
}

---@param className string
---@return ColorDefinition
function UTILS.GetClassColor(className)
    local color = classColors[className]
    return (color or { r = 0.627, g = 0.627, b = 0.627, hex = "9d9d9d" })
end
local GetClassColor = UTILS.GetClassColor

---@param text string
---@param color string
---@return string
function UTILS.ColorCodeText(text, color)
    return string.format("|cff%s%s|r", color, text);
end
local ColorCodeText = UTILS.ColorCodeText

---@param className string
---@return string
function UTILS.ColorCodeAndLocalizeClass(className)
    return ColorCodeText(CLM.L[className], GetClassColor(className).hex);
end

local colorCodedClassList = {}
do
    for _,class in pairs(classOrdered) do
        tinsert(colorCodedClassList, UTILS.ColorCodeAndLocalizeClass(class))
    end
end

function UTILS.GetColorCodedClassList()
    return colorCodedClassList
end

function UTILS.GetClassList()
    return classOrdered
end

---@param percentage number
---@return string
function UTILS.ColorCodeByPercentage(percentage)
    percentage = tonumber(percentage) or 0
    if percentage < 0 then percentage = 0 end
    if percentage > 100 then percentage = 100 end

    local red, green, blue = 255, 255, 0
    if percentage < 50 then
        green = UTILS.round(5.1*percentage, 0) -- (255 * 2 / 100) * percentage
    elseif percentage > 50 then
        red = UTILS.round(5.1*(100 - percentage), 0) -- (2*255)*(100 - percentage)/100,
    end
    return string.format("|cff%s%s|r", string.format("%02x%02x%02x", red, green, blue), percentage)
end

---@param percentage number
function UTILS.GetColorByPercentage(percentage)
    percentage = tonumber(percentage) or 0
    if percentage < 0 then percentage = 0 end
    if percentage > 100 then percentage = 100 end

    local red, green, blue = 1.0, 1.0, 0.0
    if percentage < 50 then
        green = UTILS.round((percentage * 2)/100, 2)
    elseif percentage > 50 then
        red = UTILS.round(2*(100 - percentage)/100, 2)
    end
    return red, green, blue, 1.0
end

---@param s string?
function UTILS.RemoveColorCode(s)
    return string.sub(s or "", 11, -3)
end

local RemoveColorCode = UTILS.RemoveColorCode

-- formats:
-- s: string  "AARRGGBB"
-- a: string array  = {a = "AA", r = "RR", g = "GG", b = "BB"}
-- i: integer array = {a = AA, r = RR, g = GG, b = BB } from 0 to 255
-- f: float array   = {a = AA, r = RR, g = GG, b = BB } from 0 to 1

---comment
---@param itemLink itemLink
---@param format "s"?
---@return ColorDefinition | string
function UTILS.GetColorFromLink(itemLink, format)
    local _, _, a, r, g, b = string.find(itemLink, "|c(%x%x)(%x%x)(%x%x)(%x%x)|.*")
    local color = {
        a = a or "",
        r = r or "",
        g = g or "",
        b = b or ""
    }
    if format == "s" then
        return string.format("%s%s%s%s", color.a, color.r, color.g, color.b)
    else
        if format ~= "s" then
            for k,v in pairs(color) do
                color[k] = tonumber("0x" .. v) or 0
            end
            if format == "f" then
                for k,v in pairs(color) do
                    color[k] = v / 255
                end
            end
        end

        return color
    end
end

---@param itemLink itemLink
---@return number
---@return string
function UTILS.GetItemIdFromLink(itemLink)
    -- local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Name = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
    itemLink = itemLink or ""
    -- local _, _, _, _, itemId = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+).*")
    local _, _, itemId, extra = string.find(itemLink, "item:(%d+)([%d:]*)|h")
    return tonumber(itemId) or 0, extra or ""
end

---@param itemLink itemLink
---@param extra string?
---@return itemLink
function UTILS.SpoofLink(itemLink, extra)
    if not extra then return itemLink end
    local _, _, pre, post = string.find(itemLink, "(.*item:%d+)[%d:]+(|h.*)")
    if not pre or not post then return itemLink end
    return pre .. extra .. post
end

---@param name string
---@param object table
---@param cli string
function UTILS.UniversalCliMethodExecutor(name, object, cli)
    local values = {strsplit(" ", cli)}
    local method, args, parameters = values[1], {}, ""
    for i=2,#values do
        args[i - 1] = values[i]
        parameters = parameters .. tostring(values[i]) ..  ", "
    end

    if type(object[method]) == "function" then
        LOG:Info("Execute [%s(%s(%s)]", name, method, parameters)
        local result = object[method](object, unpack(args))
        if type(result) == 'table' then
            UTILS.DumpTable(result)
        else
            print(result)
        end

    else
        print("Available methods:")
        for methodName,ref in pairs(object) do
            if type(ref) == "function" then
                print(methodName)
            end
        end
    end
end

---@param itemId integer
---@return string
function UTILS.GenerateItemLink(itemId)
    return string.format("item:%d:0:0:0:0:0:0:0:0:0:0:0:0", itemId)
end

---@param t table
---@return table
function UTILS.Set(t)
    local s = {}
    for _,v in pairs(t) do s[v] = true end
    return s
end

-- http://lua-users.org/wiki/CopyTable
function UTILS.ShallowCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- http://lua-users.org/wiki/CopyTable
function UTILS.DeepCopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[UTILS.DeepCopy(orig_key, copies)] = UTILS.DeepCopy(orig_value, copies)
            end
            setmetatable(copy, UTILS.DeepCopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function UTILS.typeof(object, objectType)
    if not object or not objectType then
        return false
    end
    if type(object) ~= "table" then
        return false
    end
    local mo = getmetatable(object)
    if not mo then
        return false
    end
    return (mo == objectType)
end
local typeof = UTILS.typeof

function UTILS.empty(object)
    if object == "" or object == nil then
        return true
    end
    return false
end
---@param name string?
---@return string
function UTILS.RemoveServer(name)
    name, _ = strsplit("-", name or "")
    return name
end
---@param name string?
---@return string
function UTILS.GetServer(name)
    local _, server = strsplit("-", name or "")
    return (server or "")
end

local playerGUID = UnitGUID("player") --[[@as playerGuid]]
local getIntegerGuid, myRealmId

local normalizedRealmName
---@return string
function UTILS.GetNormalizedRealmName()
    normalizedRealmName = normalizedRealmName or GetNormalizedRealmName()
    return normalizedRealmName or ""
end

local _GetNormalizedRealmName = UTILS.GetNormalizedRealmName

if CLM.WoW10 or CLM.WoWSeasonal or CLM.WoWCata then -- support cross-server for anything that is not WotLK
    ---@param GUID playerGuid
    ---@return shortGuid
    function UTILS.getIntegerGuid(GUID)
        local _, realm, int = strsplit("-", GUID)
        return {tonumber(realm, 10), tonumber(int, 16)}
    end
    getIntegerGuid = UTILS.getIntegerGuid
    myRealmId = unpack(getIntegerGuid(playerGUID), 1)
    ---@param iGUID shortGuid
    ---@return playerGuid
    function UTILS.getGuidFromInteger(iGUID)
        return string.format("Player-%d-%08X", iGUID[1], iGUID[2]) ---@diagnostic disable-line: return-type-mismatch
    end
    ---@param iGUID shortGuid
    ---@return boolean
    function UTILS.ValidateIntegerGUID(iGUID)
        if type(iGUID) ~= "table" then return false end
        for i=1,2 do if type(iGUID[i]) ~= "number" then return false end end
        return true
    end
    ---@param name string
    ---@return string
    function UTILS.Disambiguate(name)
        if string.find(name, "-") == nil then
            name = name .. "-" .. _GetNormalizedRealmName()
        end
        return name
    end
    ---@param e possibleGuidSource
    ---@return shortGuid?
    function UTILS.GetGUIDFromEntry(e)
        if typeof(e, CLM.MODELS.Profile) then
            return getIntegerGuid(e:GUID())
        elseif type(e) == "string" then
            return getIntegerGuid(e)
        elseif type(e) == "number" then
            return {myRealmId, e} --[[@as shortGuid]]
        else
            return nil
        end
    end
    ---@param playerA string
    ---@param playerB string
    ---@return boolean
    function UTILS.ArePlayersCrossRealm(playerA, playerB)
        return UTILS.GetServer(playerA) ~= UTILS.GetServer(playerB)
    end
else -- not cross-server
    ---@param GUID playerGuid
    ---@return shortGuid
    function UTILS.getIntegerGuid(GUID)
        local _, _, int = strsplit("-", GUID)
        return tonumber(int, 16) --[[@as shortGuid]]
    end
    getIntegerGuid = UTILS.getIntegerGuid
    _, myRealmId = strsplit("-", playerGUID)
    do
        local guidConversionFormat = "Player-"..tostring(myRealmId).."-%08X"
        ---@param iGUID shortGuid 
        ---@return playerGuid
        function UTILS.getGuidFromInteger(iGUID)
            return string.format(guidConversionFormat, iGUID) ---@diagnostic disable-line: return-type-mismatch
        end
    end
    ---@param iGUID shortGuid
    ---@return boolean
    function UTILS.ValidateIntegerGUID(iGUID)
        if type(iGUID) ~= "number" then return false end
        return true
    end
    ---@param name string
    ---@return string
    function UTILS.Disambiguate(name)
        return UTILS.RemoveServer(name)
    end
    ---@param e possibleGuidSource
    ---@return shortGuid?
    function UTILS.GetGUIDFromEntry(e)
        if typeof(e, CLM.MODELS.Profile) then
            return getIntegerGuid(e:GUID())
        elseif type(e) == "string" then
            return getIntegerGuid(e)
        elseif type(e) == "number" then
            return e --[[@as shortGuid]]
        else
            return nil
        end
    end
    function UTILS.ArePlayersCrossRealm(playerA, playerB)
        return false
    end
end
local GetGUIDFromEntry = UTILS.GetGUIDFromEntry

local Disambiguate = UTILS.Disambiguate
---@param unit string
---@return string
function UTILS.GetUnitName(unit)
    local name = GetUnitName(unit, true)
    return Disambiguate(name or "")
end

do
    local playerFullName
    ---@return string
    function UTILS.whoami()
        if not playerFullName then
            playerFullName = UTILS.GetUnitName("player")
        end
        return playerFullName
    end
end

function UTILS.whoamiGUID()
    return playerGUID
end

---@param playerList possibleGuidSource[]
---@return playerGuid[]
function UTILS.CreateGUIDList(playerList)
    local playerGUIDList = {}
    local GUID
    -- We expect list of either: GUID in string/integer form or profile
    -- List is expected always
    for _, p in ipairs(playerList) do
        GUID = GetGUIDFromEntry(p)
        if GUID ~= nil then
            playerGUIDList[#playerGUIDList+1] = GUID
        end
    end
    return playerGUIDList
end

---@param t table
function UTILS.DumpTable(t)
    return DumpTable(t)
end

---@param object LogEntry
---@param data table
function UTILS.inflate(object, data)
    for i, key in ipairs(object:fields(data.v)) do
        object[key] = data[i]
    end
end

---@param object LogEntry
---@param version integer?
---@return table
function UTILS.deflate(object, version)
    local result = {}
    for _, key in ipairs(object:fields(version)) do
        tinsert(result, object[key])
    end
    result.v = version
    return result
end

---@param object table
---@return table
function UTILS.keys(object)
    local keyList = {}
    local n = 0

    for k,_ in pairs(object) do
      n = n + 1
      keyList[n] = k
    end
    return keyList
end

---@param handler table
---@param method any
---@return function
function UTILS.method2function(handler, method)
    return (function(...) handler[method](handler, ...) end)
end

---comment
---@param t1 table
---@param t2 table
---@param t table?
---@return table
function UTILS.mergeLists(t1, t2, t)
    t = t or {}
    local n = 0
    for _,v in ipairs(t1) do n = n+1; t[n] = v end
    for _,v in ipairs(t2) do n = n+1; t[n] = v end
    return t
end

---@param t1 table
---@param t2 table
---@param t table?
---@return table
function UTILS.mergeDicts(t1, t2, t)
    t = t or {}
    for k,v in pairs(t1) do t[k] = v end
    for k,v in pairs(t2) do t[k] = v end
    return t
end

---@param t table
---@param s table
function UTILS.mergeDictsInline(t, s)
    for k,v in pairs(s) do t[k] = v end
end

---@param string string
---@return string
function UTILS.capitalize(string)
    return capitalize(string)
end

---@param list table?
---@return string
function UTILS.stringifyList(list)
    if not list then return "" end
    local string = ""
    for _,v in ipairs(list) do
        string = string .. tostring(v) .. ", "
    end
    return string:sub(1, -3)
end

---@param list table?
---@return string
function UTILS.stringifyDict(dict)
    if not dict then return "" end
    local string = ""
    for k,v in pairs(dict) do
        string = string .. tostring(k) .. ": " .. tostring(v) .. ", "
    end
    return string:sub(1, -3)
end

---@param frame Frame
---@param name string
function UTILS.MakeFrameCloseOnEsc(frame, name)
    _G[name] = frame
    tinsert(UISpecialFrames, name)
end

function UTILS.GetCutoffTimestamp()
    -- 25 Aug 2019 00:00:00 small bit before Wow Classic release Time
    return 1566684000
end

local function defaultDataProvider(param)
    return param
end

---comment
---@param data table
---@param tooltip GameTooltip
---@param inLine integer?
---@param max integer?
---@param dataProvider function?
---@param autoWrap boolean?
function UTILS.putListInTooltip(data, tooltip, inLine, max, dataProvider, autoWrap)
    dataProvider = dataProvider or defaultDataProvider
    inLine = inLine or 5
    max = max or 25
    local entriesInLine = 0
    local line = ""
    local separator = ", "
    local numEntries = #data
    local entriesLeft
    local notIncludedEntries = 0
    if numEntries > max then
        notIncludedEntries = numEntries - max
        numEntries = max
    end
    entriesLeft = numEntries

    while (entriesLeft > 0) do
        local currentEntry = data[numEntries - entriesLeft + 1]
        entriesLeft = entriesLeft - 1
        if entriesLeft == 0 then
            separator = ""
        end
        line = line .. dataProvider(currentEntry).. separator
        entriesInLine = entriesInLine + 1
        if entriesInLine >= inLine or entriesLeft == 0 then
            tooltip:AddLine(line, nil, nil, nil, autoWrap and true or false)
            line = ""
            entriesInLine = 0
        end
    end

    if notIncludedEntries > 0 then
        tooltip:AddLine(notIncludedEntries .. CLM.L[" more"], nil, nil, nil, autoWrap and true or false)
    end
end

---@param profile Profile
---@return string
local function profileListTooltipDataProvider(profile)
    return ColorCodeText(profile:Name(), GetClassColor(profile:Class()).hex)
end

local putListInTooltip = UTILS.putListInTooltip
---@param profiles Profile
---@param tooltip GameTooltip
function UTILS.buildPlayerListForTooltip(profiles, tooltip)
    putListInTooltip(profiles, tooltip, 5, 25, profileListTooltipDataProvider, false)
end

local greenYes = ColorCodeText(CLM.L["Yes"], "00cc00")
function UTILS.GreenYes()
    return greenYes
end

local redNo = ColorCodeText(CLM.L["No"], "cc0000")
function UTILS.RedNo()
    return redNo
end

local menuCounter = 0
---@param structure any
---@param isAssistant boolean
---@param isManager boolean
---@param frame Frame|UIDropdownMenuTemplate|nil
---@return Frame
function UTILS.GenerateDropDownMenu(structure, isAssistant, isManager, frame)
    frame = frame or CreateFrame("Frame", "CLM_Generic_Menu_DropDown" .. tostring(menuCounter), UIParent, "UIDropDownMenuTemplate")
    menuCounter = menuCounter + 1
    local isTrusted = isAssistant or isManager
    LibDD:UIDropDownMenu_Initialize(frame, (function(_, level)
        for _,k in ipairs(structure) do
            local include = not k.trustedOnly
            if k.trustedOnly then
                if k.managerOnly then
                    include = isManager
                else
                    include = isTrusted
                end
            end
            if include then
                local placeholder = LibDD:UIDropDownMenu_CreateInfo()
                placeholder.notCheckable = true
                placeholder.text = k.title
                placeholder.isTitle = k.isTitle and true or false
                if k.func then
                    placeholder.func = k.func
                end
                if k.icon then
                    placeholder.icon = k.icon
                end
                if k.color then
                    placeholder.colorCode = "|cFF" .. k.color
                end
                if k.separator then
                    placeholder.isTitle = true
                    placeholder.disabled = true
                    placeholder.icon = "Interface\\Common\\UI-TooltipDivider-Transparent"
                    placeholder.iconOnly = true
                    placeholder.iconInfo = {
                        tCoordLeft = 0,
                        tCoordRight = 1,
                        tCoordTop = 0,
                        tCoordBottom = 1,
                        tSizeX = 0,
                        tSizeY = 8,
                        tFitDropDownSizeX = true
                    }
                end
                LibDD:UIDropDownMenu_AddButton(placeholder, level)
            end
        end
    end), "MENU")

    return frame
end

---@param unixtimestamp integer
---@param offset integer?
---@return integer
function UTILS.WeekNumber(unixtimestamp, offset)
    offset = offset or 0
    local week = 1 + math.floor((unixtimestamp - offset) / 604800)
    if week < 1 then week = 1 end
    return week
end

---@param week integer
---@param offset integer?
---@return integer
function UTILS.WeekStart(week, offset)
    return ((week * 604800) + (offset or 0))
end

function UTILS.GetWeekOffsetEU()
    return 543600
end

function UTILS.GetWeekOffsetUS()
    return 486000
end

---@param number number
---@param decimals number
---@return number
function UTILS.round(number, decimals)
    local factor = 10 ^ (decimals or 0)
    return math.floor(number * factor + 0.5) / factor
end

if CLM.WoW10 then
    ---@return playerRole
    function UTILS.GetMyRole()
        local currentSpec = GetSpecialization()
        local role = "NONE"
        if currentSpec then
            _, _, _, _, role = GetSpecializationInfo(currentSpec)
        end
        return role
    end
elseif CLM.WoWSeasonal then
    ---@return playerRole
    function UTILS.GetMyRole()
        return "NONE" -- Not supported as it requires Role decoding based on spec
    end
else
    ---@return playerRole
    function UTILS.GetMyRole()
        return GetTalentGroupRole(GetActiveTalentGroup())
    end
end

---@param text FontString
---@return boolean
function UTILS.IsTooltipTextRed(text)
    if text and text:GetText() then
        local r,g,b = text:GetTextColor()
        return math.floor(r*256) >= 255 and math.floor(g*256) == 32 and math.floor(b*256) == 32
    end
    return false
end

---@param text string?
---@return string
function UTILS.Trim(text)
    text = text or ""
    return (string.gsub(text, "^[%s,]*(.-)[%s,]*$", "%1"))
end

---@param modifierFn function
---@return function
function UTILS.LibStCompareSortWrapper(modifierFn)
    return (function(s, rowa, rowb, sortbycol)
        -- Get data
        local a1, b1 = s:GetCell(rowa, sortbycol), s:GetCell(rowb, sortbycol)
        local a1_value, b1_value = a1.value, b1.value
        -- Modify Data
        a1.value, b1.value = modifierFn(a1.value, b1.value)
        -- sort
        local result = s:CompareSort(rowa, rowb, sortbycol)
        -- restore
        a1.value, b1.value  = a1_value, b1_value
        -- return
        return result
    end)
end

function UTILS.LibStModifierFn(a1, b1)
    return RemoveColorCode(a1), RemoveColorCode(b1)
end

function UTILS.LibStModifierFnNumber(a1, b1)
    return (tonumber(RemoveColorCode(a1)) or 0), (tonumber(RemoveColorCode(b1)) or 0)
end

-- Convert version string to number for comparision (e.g., "v2.5.4" to "20504")
---@param s string
---@return integer
function UTILS.VersionStringToNumber(s)
    local version = CLM.CORE.ParseVersionString(s)
    return version.major*10000 + version.minor*100 + version.patch
end

function UTILS.LibStModifierFnVersion(a1, b1)
    return UTILS.VersionStringToNumber(a1), UTILS.VersionStringToNumber(b1)
end

---@param st ScrollingTable
---@param dropdownMenu DropdownMenu
---@param rowFrame Frame
---@param cellFrame Frame
---@param data any
---@param cols any
---@param row integer
---@param realrow integer
---@param column integer
---@param table any
---@param button mouseButton
---@param ... unknown
function UTILS.LibStClickHandler(st, dropdownMenu, rowFrame, cellFrame, data, cols, row, realrow, column, table, button, ...)
    local leftClick = (button == "LeftButton")
    local rightClick = (button == "RightButton")
    local isCtrlKeyDown = IsControlKeyDown()
    local isShiftKeyDown = IsShiftKeyDown()
    local isAdditiveSelect = leftClick and isCtrlKeyDown
    local isContinuousSelect = leftClick and isShiftKeyDown
    local isSingleSelect = leftClick and not isCtrlKeyDown and not isShiftKeyDown

    local isSelected = st.selected:IsSelected(realrow)

    if not isSelected then
        if isAdditiveSelect or rightClick then
            st.DefaultEvents["OnClick"](rowFrame, cellFrame, data, cols, row, realrow, column, table, "LeftButton", ...)
        elseif isContinuousSelect then
            local first, last, selected
            for _row, _realrow in ipairs(st.filtered) do
                if not first then
                    if st.selected:IsSelected(_realrow) then first = _row end
                end
                if st.selected:IsSelected(_realrow) then last = _row end
                if _realrow == realrow then selected = _row end
            end

            st:ClearSelection()
            if (selected and first) and selected <= first then -- clicked above first
                for _row=selected,last do
                    st.DefaultEvents["OnClick"](rowFrame, cellFrame, data, cols, _row, st.filtered[_row], column, table, "LeftButton", ...)
                end
            elseif (selected and last) and selected >= last then -- clicked below last
                for _row=first,selected do
                    st.DefaultEvents["OnClick"](rowFrame, cellFrame, data, cols, _row, st.filtered[_row], column, table, "LeftButton", ...)
                end
            else -- clicked in between
                if first and last then
                    for _row=first,last do
                        st.DefaultEvents["OnClick"](rowFrame, cellFrame, data, cols, _row, st.filtered[_row], column, table, "LeftButton", ...)
                    end
                end
            end
        end
    else
        if isAdditiveSelect then
            st.selected._storage[realrow] = nil
        end
    end
    if isSingleSelect then
        st:ClearSelection()
        st.DefaultEvents["OnClick"](rowFrame, cellFrame, data, cols, row, realrow, column, table, "LeftButton", ...)
    end
    if dropdownMenu and rightClick then
        UTILS.LibDD:CloseDropDownMenus()
        UTILS.LibDD:ToggleDropDownMenu(1, nil, dropdownMenu, cellFrame, -20, 0)
    end
end

---@param st ScrollingTable
---@param dropdownMenu DropdownMenu
---@param rowFrame Frame
---@param cellFrame Frame
---@param data any
---@param cols any
---@param row integer
---@param realrow integer
---@param column integer
---@param table any
---@param button mouseButton
---@param ... unknown
function UTILS.LibStSingleSelectClickHandler(st, dropdownMenu, rowFrame, cellFrame, data, cols, row, realrow, column, table, button, ...)
    local rightClick = (button == "RightButton")

    st:ClearSelection()
    st.DefaultEvents["OnClick"](rowFrame, cellFrame, data, cols, row, realrow, column, table, "LeftButton", ...)

    if dropdownMenu and rightClick then
        UTILS.LibDD:CloseDropDownMenus()
        UTILS.LibDD:ToggleDropDownMenu(1, nil, dropdownMenu, cellFrame, -20, 0)
    end
end

function UTILS.LibStItemCellUpdate(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
    local itemInfo = data[realrow].cols[column].value
    local iconColor = data[realrow].cols[column].iconColor or {}
    local note = data[realrow].cols[column].note
    local overlay = data[realrow].cols[column].overlay or {}
    local desaturate = data[realrow].cols[column].desaturate and true or false
    local _, _, _, _, icon = GetItemInfoInstant(itemInfo or 0)

    -- Reparent and rework text FontString
    if frame.text:GetParent() ~= frame then
        frame.text:SetParent(frame)
        local font = frame.text:GetFont()
        frame.text:SetFont(font, 18, "OUTLINE")
        frame.text:SetTextColor(1.0, 1.0, 1.0, 1.0)
        frame.text:SetShadowColor(0.0, 0.0, 0.0, 1.0)
        -- frame.text:SetShadowOffset(3,-3)
        frame.text:SetJustifyH("LEFT")
        frame.text:SetJustifyV("BOTTOM")
    end

    if icon then
        frame:SetNormalTexture(icon)
        frame:SetHighlightTexture(136580, "ADD")
        frame:GetHighlightTexture():SetTexCoord(0, 1, 0.23, 0.77)
        frame:GetNormalTexture():SetVertexColor(iconColor.r or 1, iconColor.g or 1, iconColor.b or 1, iconColor.a or 1)
        frame:GetNormalTexture():SetDesaturated(desaturate)
        frame:Show()

        if overlay.text then
            frame.text:SetText(tostring(overlay.text))
            local textColor = overlay.color or {}
            frame.text:SetTextColor(textColor.r or 1.0, textColor.g or 1.0, textColor.b or 1.0, textColor.a or 1.0)
            local shadowColor = overlay.shadow or {}
            frame.text:SetShadowColor(shadowColor.r or 0.0, shadowColor.g or 0.0, shadowColor.b or 0.0, shadowColor.a or 1.0)
        end

        frame:SetScript("OnEnter", function()
            GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
            local itemInfoType = type(itemInfo)
            if itemInfoType == 'number' then
                GameTooltip:SetHyperlink("item:" .. itemInfo)
            elseif itemInfoType == 'string' then
                GameTooltip:SetHyperlink(itemInfo)
            else
                return
            end
            if note then
                GameTooltip:AddLine("\n")
                GameTooltip:AddLine(note)
                GameTooltip:AddTexture(CLM_ICON_DARK)
            end
            GameTooltip:Show()
        end)
        frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    else
        frame:Hide()
    end
end

local CanonicalClass = UTILS.CanonicalClass
---@param rowFrame Frame
---@param frame Button
---@param data any
---@param cols any
---@param row integer
---@param realrow integer
---@param column integer
---@param fShow any
---@param table any
---@param ... unknown
function UTILS.LibStClassCellUpdate(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
    local class = data[realrow].cols[column].value
    local desaturate = data[realrow].cols[column].desaturate and true or false
    if class and class ~= "" then
        frame:SetNormalTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES") -- this is the image containing all class icons
        local coords = CLASS_ICON_TCOORDS[CanonicalClass(class)]
        frame:GetNormalTexture():SetTexCoord(unpack(coords))
        frame:GetNormalTexture():SetDesaturated(desaturate)
        frame:Show()
    else
        frame:Hide()
    end
end

---@param highlightColor ColorDefinition
---@param multiselect boolean
---@return function
function UTILS.getHighlightMethod(highlightColor, multiselect)
    return (function(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, table, ...)
        table.DoCellUpdate(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, table, ...)
        local color
        local selected
        if multiselect then
            selected = table.selected:IsSelected(realrow)
        else
            selected = (table.selected == realrow)
        end
        if selected then
            color = table:GetDefaultHighlight()
        else
            color = highlightColor
        end
        table:SetHighLightColor(rowFrame, color)
    end)
end

---@param t table
---@param fnKeep function?
---@return table
function UTILS.OnePassRemove(t, fnKeep)
    local j, n = 1, #t;
    fnKeep = fnKeep or (function(tab, idx)
        return tab[idx] ~= nil
    end)
    for i=1,n do
        if (fnKeep(t, i, j)) then
            -- Move i's kept value to j's position, if it's not already there.
            if (i ~= j) then
                t[j] = t[i];
                t[i] = nil;
            end
            j = j + 1; -- Increment position of where we'll place the next kept value.
        else
            t[i] = nil;
        end
    end

    return t;
end

-- https://stackoverflow.com/a/32660766
---@param o1 any
---@param o2 any
---@param check_mt boolean
---@return boolean
function UTILS.TableCompare(o1, o2, check_mt)
    if o1 == o2 then return true end
    local o1Type = type(o1)
    local o2Type = type(o2)
    if o1Type ~= o2Type then return false end
    if o1Type ~= 'table' then return false end

    if check_mt then
        local mt1 = getmetatable(o1)
        if mt1 and mt1.__eq then
            --compare using built in method
            return o1 == o2
        end
    end

    local keySet = {}

    for key1, value1 in pairs(o1) do
        local value2 = o2[key1]
        if value2 == nil or UTILS.TableCompare(value1, value2, check_mt) == false then
            return false
        end
        keySet[key1] = true
    end

    for key2, _ in pairs(o2) do
        if not keySet[key2] then return false end
    end
    return true
end

---@param dict table
---@return boolean
function UTILS.DictNotEmpty(dict)
    return not rawequal(next(dict), nil)
end

---@param frame Frame
---@param up boolean
---@param scale number
---@return number
function UTILS.ResizeFrame(frame, up, scale)
    if up then
        scale = scale + 0.1
        if scale > 2 then scale = 2 end
    else
        scale = scale - 0.1
        if scale < 0.5 then scale = 0.5 end
    end
    frame:SetScale(scale)
    return scale
end

local invtypeWorkaround = {
    [2] = {
        [3] = "INVTYPE_RANGED", -- Weapon Guns
        [18] = "INVTYPE_RANGED",-- Weapon Crossbow
    }
}

---@param class integer
---@param subclass integer
---@return equipLoc?
function UTILS.WorkaroundEquipLoc(class, subclass)
    local classTable = invtypeWorkaround[class] or {}
    return classTable[subclass] --[[@as equipLoc]]
end


function UTILS.assertTypeof(object, objectType)
    if not typeof(object, objectType) then
        error("Unexpected object type", 2)
    end
end

function UTILS.assertType(object, objectType)
    if type(object) ~= objectType then
        error("Unexpected object type", 2)
    end
end

---@param value number
---@param low number
---@param high number
---@return number
function UTILS.Saturate(value, low, high)
    if value <= low then return low end
    if value >= high then return high end
    return value
end

local defaultCharset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890 -_=[];:<>,.?"
---@param length number
---@param customCharset string?
---@return string
function UTILS.randomString(length, customCharset)
    local charset = customCharset or defaultCharset
    local charsetLength = #charset
    local result = ""
    while #result < length do
        local char = math.random(1, charsetLength)
        result = result .. strsub(charset, char, char)
    end
    return result
end

---@param key SLOT_VALUE_TIER
---@param auction AuctionInfo
---@param prefix string?
---@param suffix string?
---@return string
function UTILS.GetAuctionConditionalFieldName(key, auction, prefix, suffix)
    local name
    prefix = prefix or "["
    suffix = suffix or "]"
    if auction and auction:GetNamedButtonsMode() then
        name = auction:GetFieldName(key)
        if name == "" then name = nil end
    end
    if not name then
        name = prefix .. CONSTANTS.SLOT_VALUE_TIERS_GUI[key] .. suffix
    end
    return name
end

---@param key SLOT_VALUE_TIER
---@param roster Roster
---@param prefix string?
---@param suffix string?
---@return string
function UTILS.GetRosterConditionalFieldName(key, roster, prefix, suffix)
    local name
    prefix = prefix or "["
    suffix = suffix or "]"
    if roster and roster:GetConfiguration("namedButtons") then
        name = roster:GetFieldName(key)
        if name == "" then name = nil end
    end
    if not name then
        name = prefix .. CONSTANTS.SLOT_VALUE_TIERS_GUI[key] .. suffix
    end
    return name
end

-- TODO this doesnt look good in history, we dont want DKP displayed there really

---@param pointType POINT_TYPE
---@param changeType POINT_CHANGE_TYPE
---@param displayDKP any
---@return string
function UTILS.DecodePointTypeChangeName(pointType, changeType, displayDKP)
    local points = displayDKP and CLM.L["DKP"] or "" -- not test_cameraDynamicPitch
    if pointType == CONSTANTS.POINT_TYPE.EPGP then
        if changeType == CONSTANTS.POINT_CHANGE_TYPE.SPENT then
            points = CLM.L["GP"]
        elseif changeType == CONSTANTS.POINT_CHANGE_TYPE.POINTS then
            points = CLM.L["EP"]
        else
            points = CLM.L["EP/GP"]
        end
    end
    return points
end

---@param message string
---@param channel? ChatType
---@param _? any
---@param target? string
function UTILS.SendChatMessage(message, channel, _, target)
    SendChatMessage("[CLM] " .. tostring(message), channel, nil, target)
end

CONSTANTS.ITEM_QUALITY = {
    [0] = ColorCodeText(CLM.L["Poor"], "9d9d9d"),
    [1] = ColorCodeText(CLM.L["Common"], "ffffff"),
    [2] = ColorCodeText(CLM.L["Uncommon"], "1eff00"),
    [3] = ColorCodeText(CLM.L["Rare"], "0070dd"),
    [4] = ColorCodeText(CLM.L["Epic"], "a335ee"),
    [5] = ColorCodeText(CLM.L["Legendary"], "ff8000"),
}

CONSTANTS.LOOT_ROLL_TYPE_ANY = -2
CONSTANTS.LOOT_ROLL_TYPE_IGNORE = -1
CONSTANTS.LOOT_ROLL_TYPE_TRANSMOG = 4
CONSTANTS.ROLL_TYPE = {
    [CONSTANTS.LOOT_ROLL_TYPE_ANY]      = ColorCodeText(CLM.L["Any"], "ff8000"),
    [CONSTANTS.LOOT_ROLL_TYPE_IGNORE]   = ColorCodeText(CLM.L["Do Nothing"], "9d9d9d"),
    [LOOT_ROLL_TYPE_PASS]               = PASS,
    [LOOT_ROLL_TYPE_NEED]               = ColorCodeText(NEED, "1eff00"),
    [LOOT_ROLL_TYPE_GREED]              = ColorCodeText(GREED , "ffd100"),
}
if CLM.WoW10 then
    CONSTANTS.ROLL_TYPE[LOOT_ROLL_TYPE_DISENCHANT]         = ColorCodeText(ROLL_DISENCHANT, "0070dd")
    CONSTANTS.ROLL_TYPE[CONSTANTS.LOOT_ROLL_TYPE_TRANSMOG] = ColorCodeText(TRANSMOGRIFICATION, "a335ee")
end

CONSTANTS.REGEXP_FLOAT = "^-?%d+%.?%d*$"
CONSTANTS.REGEXP_FLOAT_POSITIVE = "^%d+%.?%d*$"

CLM.UTILS = UTILS
