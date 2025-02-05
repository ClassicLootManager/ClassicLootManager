local function testIsValidExpression(showPassedTests)
    local function toResultText(result)
        if result then
            return "PASSED"
        else
            return "FAILED"
        end
    end

    local variables = {
        ["a"] = "a",
        ["b"] = "b",
        ["ab"] = "ab",
        ["hello"] = "hello"
    }
    local tests = {
        -- start with, end with, or only operator
        ["+"] = false,
        ["+a"] = false,
        ["a+"] = false,
        ["-"] = false,
        ["-a"] = true,
        ["--a"] = false,
        ["---a"] = false,
        ["a-"] = false,
        ["/"] = false,
        ["/a"] = false,
        ["a/"] = false,
        ["*"] = false,
        ["*a"] = false,
        ["a*"] = false,
        ["^"] = false,
        ["^a"] = false,
        ["a^"] = false,

        -- Repeating operator
        ["a++b"] = false,
        ["a--b"] = true,
        ["a---b"] = false,
        ["a+--b"] = false,
        ["a--+b"] = false,
        ["a//b"] = false,
        ["a**b"] = false,
        ["a^^b"] = false,
        ["a+-b"] = true,
        ["a^-b"] = true,
        ["a*-b"] = true,
        ["a/-b"] = true,
        ["a-/b"] = false,
        ["a/*b"] = false,
        ["a*^b"] = false,
        ["a^+b"] = false,

        -- operator before closing parenthesis
        ["(a+)"] = false,
        ["(a-)"] = false,
        ["(a/)"] = false,
        ["(a*)"] = false,
        ["(a^)"] = false,

        -- empty parenthesis
        ["()"] = false,
        ["a^()"] = false,
        ["ab+()"] = false,
        ["(a)"] = true,
        ["(a+b)"] = true,

        -- non-operator before opening parenthesis
        ["a(b)"] = false,
        ["1(1)"] = false,
        ["a+(b)"] = true,
        ["1+(1)"] = true,

        -- text
        ["abc"] = false,
        ["ab+c"] = false,
        ["c"] = false,
        ["ab"] = true,
        ["a+b"] = true,
        ["a"] = true,

        -- parenthesis balancing
        [")("] = false,
        ["(a"] = false,
        ["a)"] = false,
        ["(a))"] = false,
        ["((a)"] = false,
        ["((a))"] = true,

        -- special characters
        ["d_e"] = false,
        ["§"] = false,

        -- empty expression
        [""] = false,

        -- length
        [string.rep("a+", 49) .. "12"] = true,
        [string.rep("a+", 49) .. "123"] = false,

        -- floating point
        ["1.1"] = true,
        ["1.1+1.1"] = true,
        ["1.1+(1.1)"] = true,
        ["(1.1)"] = true,
        ["(1.1+1.1)"] = true,
        ["(1.1+(1.1))"] = true,
        [".1"] = false,
        ["1."] = false,
        ["."] = false,
        ["1.1."] = false,
        ["1.1.1"] = false,
        ["1.1.1+1.1.1"] = false,
        ["1.1.1+(1.1.1)"] = false,
        ["(1.1.1)"] = false,
        ["(1.1.1+1.1.1)"] = false,
        ["(1.1.1+(1.1.1))"] = false,

        -- negative numbers
        ["-1"] = true,
        ["1--1"] = true,
        ["1*-1"] = true,
        ["1^-1"] = true,
        ["1/-1"] = true,
        ["1+-1"] = true,
        ["(-1)"] = true,

        -- random positive cases
        ["a+b"] = true,
        ["ab"] = true,
        ["b^(a)"] = true,
        ["b^(1)"] = true,
        ["10^(1)"] = true,
        ["((3)/1)"] = true,
        ["ab+(b)"] = true,
        ["(a)"] = true,
        ["-1+1*2^3+4/5-6+(3-4)^((5+6)+(2^(-3+9)))+a"] = true
    }

    local maxTestLength = 0
    for test, _ in pairs(tests) do
        if #test > maxTestLength then
            maxTestLength = #test
        end
    end
    local headerPadding = string.rep(" ", maxTestLength - #("TEST"))

    print("TEST" .. headerPadding, "OUTPUT", "TEST RESULT")
    print("----" .. headerPadding, "------", "-----------")

    local passedTestsCount = 0
    local totalTestsCount = 0
    for _ in pairs(tests) do
        totalTestsCount = totalTestsCount + 1
    end
    for test, expected in pairs(tests) do
        local result, errors = ExpressionParser:IsValidExpression(test, variables)
        local pass = result == expected
        if pass then
            passedTestsCount = passedTestsCount + 1
        end

        if not pass or showPassedTests then
            local padding = string.rep(" ", maxTestLength - #test)
            print(test .. padding, result, toResultText(pass))
            print(table.concat(errors, ", "))
        end
    end

    print("Passed tests: " .. passedTestsCount .. "/" .. totalTestsCount)
end

local function testEvaluate(showPassedTests)
    local function toResultText(result)
        if result then
            return "PASSED"
        else
            return "FAILED"
        end
    end

    local variables = {
        ["a"] = "1",
        ["b"] = "2",
        ["c"] = "3"
    }
    local tests = {
        ["1+1"] = 2,
        ["1+1*2"] = 3,
        ["-1+1*2^3+4/5-6+(3-4)^((5+6)+(2^(-3+9)))+a"] = 1.8,
        ["-(1-3)*2"] = 4
    }

    local maxTestLength = 0
    for test, _ in pairs(tests) do
        if #test > maxTestLength then
            maxTestLength = #test
        end
    end
    local headerPadding = string.rep(" ", maxTestLength - #("TEST"))

    print("TEST" .. headerPadding, "OUTPUT", "TEST RESULT")
    print("----" .. headerPadding, "------", "-----------")

    local passedTestsCount = 0
    local totalTestsCount = 0
    for _ in pairs(tests) do
        totalTestsCount = totalTestsCount + 1
    end
    for test, expected in pairs(tests) do
        local result = ExpressionParser:Evaluate(test, variables)
        local pass = tostring(result) == tostring(expected)
        if pass then
            passedTestsCount = passedTestsCount + 1
        end

        if not pass or showPassedTests then
            local padding = string.rep(" ", maxTestLength - #test)
            print(test .. padding, result, toResultText(pass))
        end
    end

    print("Passed tests: " .. passedTestsCount .. "/" .. totalTestsCount)

end

-- testIsValidExpression(false)
-- testEvaluate(false)