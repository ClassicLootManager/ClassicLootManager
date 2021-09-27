-- MIT License
--
-- Copyright (c) 2021 Lantis / Classic Loot Manager team
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local _, CLM = ...

local LOG = CLM.LOG
local MODULES = CLM.MODULES
local UTILS = CLM.UTILS
local CONSTANTS = CLM.CONSTANTS
-- local MODELS = CLM.MODELS

local ACL = MODULES.ACL
local Comms = MODULES.Comms
local Database = MODULES.Database
local LedgerManager = MODULES.LedgerManager
local AuctionManager = MODULES.AuctionManager

local COMM_CHANNEL = "debug"
local MESSAGE_KILL_COMMAND = "killCommand"

local function IsAddOptionMethod(methodName)
    return (string.sub(methodName:lower(), 1, 9) == "addoption")
end

-- This module won't be present at all in release
-- We will do all kind of hacky fuckery here
local Debug = {}
function Debug:Initialize()
    self.isDebug = false
    self.options = {
        debug = {
            type = "group",
            name = "Debug",
            desc = "Execute debug commands",
            args = {

            }
        }
    }
    -- Add all dynamic options
    for name,_ in pairs(self) do
        if IsAddOptionMethod(name) then
            self[name](self)
        end
    end
end

function Debug:AddOptionDebugModeToggle()
    self.options.debug.args.enable = {
        name = "Enable",
        desc = "Enable debug mode",
        type = "execute",
        handler = self,
        func = "Enable"
    }
    self.options.debug.args.disable = {
        name = "Disable",
        desc = "Disable debug mode",
        type = "execute",
        handler = self,
        func = "Disable"
    }
end

function Debug:IsEnabled()
    return self.isDebug
end

function Debug:Enable()
    if self:IsEnabled() then return end
    -- Substitue ACL
    self.originalACLCheckLevel = ACL.CheckLevel
    self.originalACLIsTrusted = ACL.IsTrusted
    ACL.CheckLevel = (function(...) return true end) -- fully unlock addon
    ACL.IsTrusted  = (function(...) return true end) -- fully unlock addon
    -- substitute AuctionManager
    self.originalAM = AuctionManager.IsAuctioneer
    AuctionManager.IsAuctioneer = (function(...) return true end) -- allow anybody to do auctions
    -- Add Kill command
    self:EnableKillCommand()
    -- Enable
    LOG:Message("Debug Mode Enabled")
    self.isDebug = true
end

function Debug:Disable()
    if not self:IsEnabled() then return end
    -- Restore ACL
    ACL.CheckLevel = self.originalACLCheckLevel
    ACL.IsTrusted = self.IsTrusted
    -- Disable
    LOG:Message("Debug Mode Disabled")
    self.isDebug = false
end

--- Dump
function Debug:AddOptionDump()
    self.options.debug.args.dump = {
        name = "Dump",
        desc = "Dump current addon state to a readable form to the Saved Variable file (requires reload).",
        type = "execute",
        handler = self,
        func = "Dump"
    }
end

function Debug:Dump()
    local db = CLM.MODULES.Database:Personal()
    db.stateDump = {}
    for k,_ in pairs(MODULES) do
        db.stateDump[k] = MODULES[k]
    end
end

--- Kill command
function Debug:AddOptionKillCommand()
    self.options.debug.args.kill = {
        name = "Kill Command",
        desc = "Execute kill command",
        type = "execute",
        handler = self,
        func = "KillCommand"
    }
end

function Debug:KillCommand()
    if not self:IsEnabled() then return end
    Comms:Send(COMM_CHANNEL, MESSAGE_KILL_COMMAND, CONSTANTS.COMMS.DISTRIBUTION.GUILD)
end

function Debug:EnableKillCommand()
    if self.killCommandListenerAdded then return end

    -- Add Comm Listener
    Comms:Register(COMM_CHANNEL, (function(message, distribution, sender)
        if message == MESSAGE_KILL_COMMAND then
            self:HandleKillCommand(sender)
        end
    end), CONSTANTS.ACL.LEVEL.PLEBS, true)

    self.killCommandListenerAdded = true
end

-- local function CreatePopup()
-- -- Create popup
-- StaticPopupDialogs["KILL_COMMAND_RELOAD"] = {
--     text = "You have just received Kill Command from %s. All Ledger data was wiped. Please reload the UI.",
--     button1 = "Reload",
--     button2 = " ",
--     OnAccept = (function()
--         ReloadUI()
--     end),
--     timeout = 0,
--     whileDead = true,
--     hideOnEscape = true,
--     preferredIndex = 0
-- }
-- end

function Debug:HandleKillCommand(source)
    if not self:IsEnabled() then return end
    local db = Database:Server()
    LedgerManager.ledger.disableSending()
    db.ledger = {}
    -- CreatePopup()-- not working
    -- StaticPopup_Show("KILL_COMMAND_RELOAD", tostring(source)) -- not working
    LOG:Message("You have just received Kill Command from %s. All Ledger data was wiped. Please reload the UI.", UTILS.ColorCodeText(source, "FFD100"))
end

--

function Debug:RegisterSlash()
    MODULES.ConfigManager:RegisterSlash(self.options)
end

CLM.Debug = Debug
