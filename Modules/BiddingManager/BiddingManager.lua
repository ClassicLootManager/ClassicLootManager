local define = LibDependencyInjection.createContext(...)

define.module("BiddingManager", {
    "Utils", "Log",
    "Constants",  "Meta:ADDON_TABLE","Models/Roster", "L", "Comms", "AuctionManager", "Database", "ConfigManager", "Constants/BiddingCommType", "EventManager"
}, function(resolve, UTILS, LOG, CONSTANTS, CLM, _, L, Comms, AuctionManager, Database, ConfigManager, BiddingCommType, EventManager)

local BIDDING_COMM_PREFIX = "Bidding1"

local BiddingManager = {}
function BiddingManager:Initialize()
    LOG:Trace("BiddingManager:Initialize()")

    self.bids = {}
    self.lastBid = 0
    self.guiBid = false -- hiding responses for bidding through chat command (which shouldnt be used anyway)
    self.auctionInProgress = false

    Comms:Register(BIDDING_COMM_PREFIX, (function(rawMessage, distribution, sender)
        local message = CLM.MODELS.BiddingCommStructure:New(rawMessage)
        if UTILS.Contains(BiddingCommType, message:Type()) == false then return end
        -- Bidding Manager is owner of the channel
        -- pass handling to Auction Manager
        AuctionManager:HandleIncomingMessage(message, distribution, sender)
    end), CONSTANTS.ACL.LEVEL.PLEBS, true)

    self:ClearAuctionInfo()

    self.handlers = {
        [CONSTANTS.AUCTION_COMM.TYPE.START_AUCTION]     = "HandleStartAuction",
        [CONSTANTS.AUCTION_COMM.TYPE.STOP_AUCTION]      = "HandleStopAuction",
        [CONSTANTS.AUCTION_COMM.TYPE.ANTISNIPE]         = "HandleAntiSnipe",
        [CONSTANTS.AUCTION_COMM.TYPE.ACCEPT_BID]        = "HandleAcceptBid",
        [CONSTANTS.AUCTION_COMM.TYPE.DENY_BID]          = "HandleDenyBid",
        [CONSTANTS.AUCTION_COMM.TYPE.DISTRIBUTE_BID]    = "HandleDistributeBid"
    }

    self.db = Database:Personal('bidding', {
        autoOpen = true,
        autoUpdateBidValue = false
    })

    local options = {
        bidding_header = {
            type = "header",
            name = L["Bidding"],
            order = 70
        },
        bidding_auto_open = {
            name = L["Toggle Bidding auto-open"],
            desc = L["Toggle auto open and auto close on auction start and stop"],
            type = "toggle",
            set = function(i, v) self:SetAutoOpen(v) end,
            get = function(i) return self:GetAutoOpen() end,
            width = "full",
            order = 71
          },
          bidding_auto_update = {
            name = L["Enable auto-update bid values"],
            desc = L["Enable auto-update bid values when current highest bid changes (open auction only)."],
            type = "toggle",
            set = function(i, v) self:SetAutoUpdateBidValue(v) end,
            get = function(i) return self:GetAutoUpdateBidValue() end,
            width = "full",
            order = 72
          }
    }
    ConfigManager:RegisterGlobal(options)


    self._initialized = true
end

function BiddingManager:SetAutoOpen(value)
    self.db.autoOpen = value and true or false
end

function BiddingManager:GetAutoOpen()
    return self.db.autoOpen
end

function BiddingManager:SetAutoUpdateBidValue(value)
    self.db.autoUpdateBidValue = value and true or false
end

function BiddingManager:GetAutoUpdateBidValue()
    return self.db.autoUpdateBidValue
end

function BiddingManager:GetLastBidValue()
    return self.lastBid
end

function BiddingManager:Bid(value, type)
    LOG:Trace("BiddingManager:Bid()")
    if not self.auctionInProgress then
        LOG:Debug("BiddingManager:Bid(): No auction in progress")
        return
    end
    value = tonumber(value) or 0
    self.lastBid = value
    self.guiBid = true
    local message = CLM.MODELS.BiddingCommStructure:New(
        BiddingCommType.SUBMIT_BID,
        CLM.MODELS.BiddingCommSubmitBid:New(value, type)
    )
    Comms:Send(BIDDING_COMM_PREFIX, message, Distribution.WHISPER, self.auctioneer, CONSTANTS.COMMS.PRIORITY.ALERT)
end

function BiddingManager:CancelBid()
    LOG:Trace("BiddingManager:CancelBid()")
    if not self.auctionInProgress then return end
    self.lastBid = nil
    self.guiBid = true
    local message = CLM.MODELS.BiddingCommStructure:New(BiddingCommType.CANCEL_BID, {})
    Comms:Send(BIDDING_COMM_PREFIX, message, Distribution.WHISPER, self.auctioneer, CONSTANTS.COMMS.PRIORITY.ALERT)
end

function BiddingManager:NotifyPass()
    LOG:Trace("BiddingManager:NotifyPass()")
    if not self.auctionInProgress then return end
    self.lastBid = L["PASS"]
    self.guiBid = true
    local message = CLM.MODELS.BiddingCommStructure:New(BiddingCommType.NOTIFY_PASS, {})
    Comms:Send(BIDDING_COMM_PREFIX, message, Distribution.WHISPER, self.auctioneer, CONSTANTS.COMMS.PRIORITY.ALERT)
end

function BiddingManager:NotifyCantUse()
    LOG:Trace("BiddingManager:NotifyCantUse()")
    if not self.auctionInProgress then return end
    local message = CLM.MODELS.BiddingCommStructure:New(BiddingCommType.NOTIFY_CANTUSE, {})
    Comms:Send(BIDDING_COMM_PREFIX, message, Distribution.WHISPER, self.auctioneer, CONSTANTS.COMMS.PRIORITY.ALERT)
end

function BiddingManager:NotifyHide()
    LOG:Trace("BiddingManager:NotifyHide()")
    if not self.auctionInProgress then return end
    local message = CLM.MODELS.BiddingCommStructure:New(BiddingCommType.NOTIFY_HIDE, {})
    Comms:Send(BIDDING_COMM_PREFIX, message, Distribution.WHISPER, self.auctioneer, CONSTANTS.COMMS.PRIORITY.ALERT)
end

function BiddingManager:ClearAuctionInfo()
    self.auctionInfo = nil
    self.auctioneer = nil
    self.lastBid = nil
    self.guiBid = false
end

function BiddingManager:HandleIncomingMessage(message, _, sender)
    LOG:Trace("BiddingManager:HandleIncomingMessage()")
    if not AuctionManager:IsAuctioneer(sender, true) then
        LOG:Error("Received unauthorised auction command from %s", sender)
        return
    end
    local mtype = message:Type() or 0
    if self.handlers[mtype] then
        self[self.handlers[mtype]](self, message:Data(), sender)
    end
end


local PlayStartSound, PlayEndSound
PlayStartSound = function()
    if not CLM.GlobalConfigs:GetSounds() then return end
    PlaySound(12889)
end
PlayEndSound = function()
    if not CLM.GlobalConfigs:GetSounds() then return end
    PlaySound(12867)
end

function BiddingManager:HandleStartAuction(data, sender)
    LOG:Trace("BiddingManager:HandleStartAuction()")
    if self.auctionInProgress then
        LOG:Debug("Received new auction from %s while auction is in progress", sender)
        return
    end
    self.auctionInfo = data
    self.auctioneer = sender
    self.auctionInProgress = true
    PlayStartSound()
    CLM.GUI.BiddingManager:StartAuction(self:GetAutoOpen(), self.auctionInfo)
    LOG:Message(L["Auction of "] .. self.auctionInfo:ItemLink())
end

function BiddingManager:HandleStopAuction(_, sender)
    LOG:Trace("BiddingManager:HandleStopAuction()")
    if not self.auctionInProgress then
        LOG:Debug("Received auction stop from %s while no auctions are in progress", sender)
        return
    end
    self.auctionInProgress = false
    self:ClearAuctionInfo()
    PlayEndSound()
    CLM.GUI.BiddingManager:EndAuction()
    LOG:Message(L["Auction finished"])
end

function BiddingManager:HandleAntiSnipe(_, sender)
    LOG:Trace("BiddingManager:HandleAntiSnipe()")
    if not self.auctionInProgress then
        LOG:Debug("Received antisnipe from %s while no auctions are in progress", sender)
        return
    end
    CLM.GUI.BiddingManager:AntiSnipe()
end

function BiddingManager:HandleAcceptBid(_, sender)
    LOG:Trace("BiddingManager:HandleAcceptBid()")
    if not self.auctionInProgress then
        LOG:Debug("Received accept bid from %s while no auctions are in progress", sender)
        return
    end
    if self.guiBid then
        local value =  self.lastBid or L["cancel"]
        EventManager:DispatchEvent(CONSTANTS.EVENTS.USER_BID_ACCEPTED, { value = value })
        LOG:Message(L["Your bid (%s) was |cff00cc00accepted|r"], value)
        self.guiBid = false
    end
end

function BiddingManager:HandleDenyBid(data, sender)
    LOG:Trace("BiddingManager:HandleDenyBid()")
    if not self.auctionInProgress then
        LOG:Debug("Received deny bid from %s while no auctions are in progress", sender)
        return
    end
    if self.guiBid then
        local value = self.lastBid or L["cancel"]
        EventManager:DispatchEvent(CONSTANTS.EVENTS.USER_BID_DENIED, { value = value, reason = CONSTANTS.AUCTION_COMM.DENY_BID_REASONS_STRING[data:Reason()] or L["Unknown"] })
        LOG:Message(L["Your bid (%s) was denied: |cffcc0000%s|r"], value, CONSTANTS.AUCTION_COMM.DENY_BID_REASONS_STRING[data:Reason()] or L["Unknown"])
        self.guiBid = false
    end
end

function BiddingManager:HandleDistributeBid(data, sender)
    LOG:Trace("BiddingManager:HandleDistributeBid()")
    if not self.auctionInProgress then
        LOG:Debug("Received distribute bid from %s while no auctions are in progress", sender)
        return
    end
    if self:GetAutoUpdateBidValue() then
        local value = (tonumber(data:Value()) or 0) + self.auctionInfo:Increment()
        CLM.GUI.BiddingManager:UpdateCurrentBidValue(value)
    end
end





resolve(BiddingManager)
end)

define.module("Constants/BiddingCommType", {}, function(resolve)
    resolve({
        SUBMIT_BID  = 1,
        CANCEL_BID  = 2,
        NOTIFY_PASS = 3,
        NOTIFY_HIDE = 4,
        NOTIFY_CANTUSE = 5
    })
end)

define.module("Constants/BidType", {"Constants/SlotValueTier"}, function (resolve, SlotValueTier)
    resolve({
        MAIN_SPEC = 1,
        OFF_SPEC = 2,
        -- PASS = 3,
        -- CANCEL = 4,
        [SlotValueTier.BASE]    = SlotValueTier.BASE,
        [SlotValueTier.SMALL]   = SlotValueTier.SMALL,
        [SlotValueTier.MEDIUM]  = SlotValueTier.MEDIUM,
        [SlotValueTier.LARGE]   = SlotValueTier.LARGE,
        [SlotValueTier.MAX]     = SlotValueTier.MAX
    })

end)