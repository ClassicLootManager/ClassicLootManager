-- ------------------------------- --
local  _, CLM = ...
-- ------ CLM common cache ------- --
local CONSTANTS = CLM.CONSTANTS
-- ------------------------------- --

-- Constants
CONSTANTS.MAX_EXPRESSION_LENGTH = 100

local OPERATION_TYPE = {
    OR = 1
}

local FAILURE_CONDITIONS = {
    { OPERATION_TYPE.OR, { "^[%+%/%*%^]", "^[%-][%-]" },                                        CLM.L["Expression may not start on an operator."] },
    { OPERATION_TYPE.OR, { "[%+%-%/%*%^]$" },                                                   CLM.L["Expression may not end on an operator."] },
    { OPERATION_TYPE.OR, { "[%+%-%/%*%^][%+%/%*%^]", "[%+%-%/%*%^][%+%-%/%*%^][%+%-%/%*%^]" },  CLM.L["Expression may not contain more than one operator in a row."] },
    { OPERATION_TYPE.OR, { "[%+%-%/%*%^][%)]" },                                                CLM.L["Expression may not contain an operator before a closing parenthesis."] },
    { OPERATION_TYPE.OR, { "[%(][%)]" },                                                        CLM.L["Expression may not contain empty parenthesis."] },
    { OPERATION_TYPE.OR, { "[%d%a][%(]" },                                                      CLM.L["Expression may not contain a non-operator/non-parenthesis before an opening parenthesis."] },
    { OPERATION_TYPE.OR, { "^%.", "[^%d]%." },                                                  CLM.L["A decimal point must be preceded by a digit."] },
    { OPERATION_TYPE.OR, { "%.$", "%.[^%d]" },                                                  CLM.L["A decimal point must be followed by a digit."] },
    { OPERATION_TYPE.OR, { "%d+%.%d+%." },                                                      CLM.L["A number cannot contain multiple decimal points."] }
}


-- Private Methods
local function verifyPattern(expression, operationType, patterns, errorMessage, errors)
    if operationType == OPERATION_TYPE.OR then
        for _, pattern in ipairs(patterns) do
            if expression:match(pattern) then
                errors[#errors + 1] = errorMessage
                return
            end
        end
    else
        error("Invalid operation type: " .. operationType)
    end
end

local function verifyConditions(expression, conditions, errors)
    for _, condition in ipairs(conditions) do
        verifyPattern(expression, condition[1], condition[2], condition[3], errors)
    end
end

local function verifyAllTextIsVariableNames(expression, variables, errors)
    local errorMessage = CLM.L["Expression may only contain the pre-defined variables"]

    local variableValues = {}
    for _, value in pairs(variables) do
        variableValues[value] = true
    end

    local nonOperatorParenthesisOrNumber = "[^%+%-%/%*%^%(%)%d%.]+"
    for word in expression:gmatch(nonOperatorParenthesisOrNumber) do
        if not variableValues[word] then
            errors[#errors + 1] = errorMessage
            return
        end
    end
end

local function verifyParenthesisAreBalanced(expression, errors)
    local errorMessage = CLM.L["Expression has unbalanced parentheses"]

    local nestDepth = 0
    for i = 1, #expression do
        local c = expression:sub(i, i)
        if c == '(' then
            nestDepth = nestDepth + 1
        elseif c == ')' then
            nestDepth = nestDepth - 1
        end
        if nestDepth < 0 then
            errors[#errors + 1] = errorMessage
            return
        end
    end
    if nestDepth ~= 0 then
        errors[#errors + 1] = errorMessage
    end
end

local function tokenize(input)
    local tokens = {}
    local currentToken = ""
    local index = 1;
    for char in input:gmatch(".") do
        if char:match("[%d%.]") or (char:match("-") and not currentToken:match("[%d]$")) then
            -- gathering token parts
            currentToken = currentToken .. char
        else
            -- write current token
            currentToken = currentToken:gsub("%-%-", "") -- correction for negative numbers
            tokens[index] = currentToken
            currentToken = ""
            index = index + 1

            -- write new token
            tokens[index] = char
            index = index + 1
        end
    end
    if currentToken ~= "" then
        tokens[index] = currentToken
    end
    return tokens
end

local function processOperator(tokens, process)
    for i, token in ipairs(tokens) do
        if process[token] then
            local j = i - 1
            while tokens[j] == "" do
                j = j - 1
            end
            local left = tonumber(tokens[j])
            local right = tonumber(tokens[i + 1])
            local result = process[token](left, right)
            tokens[j] = result
            tokens[i] = ""
            tokens[i + 1] = ""
        end
    end
end

local function solve(eq)

    while eq:find("%b()") do
        eq = eq:gsub("%b()", function(block)
            local inner = block:sub(2, -2)
            return tostring(solve(inner))
        end)
    end

    local tokens = tokenize(eq)
    processOperator(tokens, {
        ["^"] = function(left, right) return left ^ right end
    })
    processOperator(tokens, {
        ["*"] = function(left, right) return left * right end,
        ["/"] = function(left, right) return left / right end
    })
    processOperator(tokens, {
        ["+"] = function(left, right) return left + right end,
        ["-"] = function(left, right) return left - right end
    })

    return tonumber(tokens[1])
end

local function replaceVariablesWithValues(expression, variables)
    for variableName in ipairs(variables) do
        local value = variables[variableName]
        expression = expression:gsub(variableName, tonumber(value) or 0)
    end
    return expression
end


-- Public methods
ExpressionParser = {}
function ExpressionParser:IsValidExpression(expression, variables)
    local cleanedExpression = string.lower(expression:gsub("%s+", ""))

    if #cleanedExpression == 0 or #cleanedExpression > CONSTANTS.MAX_EXPRESSION_LENGTH then
        return false, { string.format(CLM.L["Invalid length! Expression must be between 1 to %s characters!"], CONSTANTS.MAX_EXPRESSION_LENGTH) }
    end
    local errors = {}

    verifyConditions(cleanedExpression, FAILURE_CONDITIONS, errors)
    verifyAllTextIsVariableNames(cleanedExpression, variables, errors)
    verifyParenthesisAreBalanced(cleanedExpression, errors)

    return #errors == 0, errors
end

function ExpressionParser:Evaluate(expression, variables)
    return solve(replaceVariablesWithValues(expression, variables))
end