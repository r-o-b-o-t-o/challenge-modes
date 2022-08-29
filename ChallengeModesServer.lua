-- Constants
local GAMEOBJECT_EVENT_ON_USE = 14 -- (event, go, player) - Can return true to stop normal action

-- Ids
local allianceGobjEntry = 2000000
local hordeGobjEntry = 2000001

-- Note that getting AIO is done like this since AIO is defined on client
-- side by default when running addons and on server side it may need to be
-- required depending on the load order. On server only files the require
-- would be enough, but lets just keep it like this for the sake of consistency
local AIO = AIO or require("AIO")
local channelName = "ChallengeModes"

-- AIO.AddHandlers adds a new table of functions as handlers for a name and returns the table.
-- This is used to add functions for a specific "channel name" that trigger on specific messages.
local Handlers = AIO.AddHandlers(channelName, {})

function Handlers.EnableMode(player, mode)

end

local function OnAllianceBannerUse(event, gobj, player)
	if player:IsAlliance() then
		AIO.Handle(player, channelName, "OpenBannerUI")
	end
end

local function OnHordeBannerUse(event, gobj, player)
	if player:IsHorde() then
		AIO.Handle(player, channelName, "OpenBannerUI")
	end
end

RegisterGameObjectEvent(allianceGobjEntry, GAMEOBJECT_EVENT_ON_USE, OnAllianceBannerUse)
RegisterGameObjectEvent(hordeGobjEntry, GAMEOBJECT_EVENT_ON_USE, OnHordeBannerUse)
