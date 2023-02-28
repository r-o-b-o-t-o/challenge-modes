-- Note that getting AIO is done like this since AIO is defined on client
-- side by default when running addons and on server side it may need to be
-- required depending on the load order.
local AIO = AIO or require("AIO")
local channelName = "ChallengeModes"

-- This will add this file to the server side list of addons to send to players.
-- The function is coded to get the path and file name automatically,
-- but you can also provide them yourself. AIO.AddAddon will return true if the
-- addon was added to the list of loaded addons, this means that if the
-- function returns true the file is being executed on server side and we
-- return since this is a client file. On client side the file will be executed
-- entirely.
if AIO.AddAddon() then
	return
end

-- AIO.AddHandlers adds a new table of functions as handlers for a name and returns the table.
-- This is used to add functions for a specific "channel name" that trigger on specific messages.
local Handlers = AIO.AddHandlers(channelName, {})
local challengeModes = {}

local scaleX = 1 / 1.25
local scaleY = 1 / 1.175
local hordeAtlas = {
	TopBorder = { 0.0, 0.68359375, 0.1171875, 0.146484375 },
	BottomBorder = { 0.0, 0.68359375, 0.0859375, 0.115234375 },
	LeftBorder = { 0.015625, 0.484375, 0.0, 1.0 },
	RightBorder = { 0.515625, 0.984375, 0.0, 1.0 },
	TopLeftCorner = { 0.0009765625, 0.1630859375, 0.783203125, 0.9453125 },
	TopRightCorner = { 0.1630859375, 0.0009765625, 0.783203125, 0.9453125 },
	BottomLeftCorner = { 0.0009765625, 0.1630859375, 0.9453125, 0.783203125 },
	BottomRightCorner = { 0.1630859375, 0.0009765625, 0.9453125, 0.783203125 },
	Scroll = { 0.0009765625, 0.2490234375, 0.3525390625, 0.78125 },
	ScrollHead = { 0.2509765625, 0.525390625, 0.7822265625, 0.8642578125 },
	ScrollImgFrame = { 0.755859375, 0.9560546875, 0.4609375, 0.5673828125 },
	TitleLeft = { 0.787109375, 0.984375, 0.2666015625, 0.349609375 },
	TitleRight = { 0.587890625, 0.78515625, 0.2666015625, 0.349609375 },
	TitleMiddle = { 0.0, 0.5, 0.0009765625, 0.083984375 },
	Header = { 0.3837890625, 0.83203125, 0.1484375, 0.2646484375 },
	HeaderSize = { W = 459, H = 119, Y = 50 },
	CloseCorner = { 0.833984375, 0.8662109375, 0.1484375, 0.1796875 },
	WideScroll = { 0.2509765625, 0.75390625, 0.3525390625, 0.7802734375 },
	EnlistSplash = { 0.001953125, 0.9140625, 0.28125, 0.556640625 },
}
local allianceAtlas = {
	TopBorder = { 0.0, 0.68359375, 0.0322265625, 0.0615234375 },
	BottomBorder = { 0.68359375, 0.0, 0.0615234375, 0.0322265625 },
	LeftBorder = { 0.015625, 0.484375, 0.0, 1.0 },
	RightBorder = { 0.515625, 0.984375, 0.0, 1.0 },
	TopLeftCorner = { 0.0009765625, 0.1630859375, 0.5791015625, 0.7412109375 },
	TopRightCorner = { 0.1630859375, 0.0009765625, 0.5791015625, 0.7412109375 },
	BottomLeftCorner = { 0.0009765625, 0.1630859375, 0.7412109375, 0.5791015625 },
	BottomRightCorner = { 0.1630859375, 0.0009765625, 0.7412109375, 0.5791015625 },
	Scroll = { 0.0009765625, 0.2490234375, 0.1484375, 0.5771484375 },
	ScrollHead = { 0.6337890625, 0.908203125, 0.7822265625, 0.8642578125 },
	ScrollImgFrame = { 0.0009765625, 0.201171875, 0.8828125, 0.9892578125 },
	TitleLeft = { 0.755859375, 0.953125, 0.3525390625, 0.435546875 },
	TitleRight = { 0.953125, 0.755859375, 0.3525390625, 0.435546875 },
	TitleMiddle = { 0.0, 0.5, 0.0634765625, 0.146484375 },
	Header = { 0.6337890625, 0.94140625, 0.1484375, 0.279296875 },
	HeaderSize = { W = 315, H = 134, Y = 68 },
	CloseCorner = { 0.1650390625, 0.197265625, 0.5791015625, 0.6103515625 },
	WideScroll = { 0.2509765625, 0.75390625, 0.3525390625, 0.7802734375 },
	EnlistSplash = { 0.001953125, 0.9140625, 0.001953125, 0.27734375 },
}
local _, _, _, race = GetPlayerInfoByGUID(UnitGUID("player"))
local atlas, faction, titleColor, textColor
if race == "Orc" or race == "Scourge" or race == "Tauren" or race == "Troll" or race == "BloodElf" then
	faction = "Horde"
	atlas = hordeAtlas
	titleColor = "FF3A0A00"
	textColor = "FF6F0000"
else
	faction = "Alliance"
	atlas = allianceAtlas
	titleColor = "FF000031"
	textColor = "FF00165E"
end

local function CheckAddonVersion(version)
	version = gsub(version, "%.", "_")

	challengeModes.textureTestFrame = CreateFrame("Frame", "ChallengeModesTextureTestFrame", UIParent)
	challengeModes.textureTestFrame:SetSize(64, 64)
	challengeModes.textureTestFrame:SetPoint("CENTER")
	challengeModes.textureTestFrame:Hide()

	challengeModes.textureTestFrame.texture = challengeModes.textureTestFrame:CreateTexture()
	local ret = challengeModes.textureTestFrame.texture:SetTexture("Interface/ChallengeModes/ChallengeModesVersion" .. version)
	challengeModes.textureTestFrame = nil

	return ret == 1
end

local function CreateTexture(width, height, coords, layer, anchor, x, y, texture, parent)
	if anchor == nil then
		anchor = "CENTER"
	end
	if x == nil then
		x = 0
	end
	if y == nil then
		y = 0
	end
	if texture == nil then
		texture = "Interface/ChallengeModes/UIFrame" .. faction
	end
	if parent == nil then
		parent = challengeModes.mainWindow
	end

	local t = parent:CreateTexture(nil, layer)
	if width ~= nil and height ~= nil then
		t:SetSize(width, height)
	end
	t:SetPoint(anchor, x, y)
	t:SetTexture(texture)
	t:SetTexCoord(unpack(coords))
	return t
end

challengeModes.mainWindow = CreateFrame("Frame", "ChallengeModesMainWindow", UIParent)
challengeModes.mainWindow:SetSize(715, 530)
challengeModes.mainWindow:EnableMouse(true)
challengeModes.mainWindow:SetPoint("CENTER", 0, 0)
challengeModes.mainWindow:Hide()

_G["ChallengeModes.mainWindow"] = challengeModes.mainWindow -- https://wowpedia.fandom.com/wiki/Make_frames_closable_with_the_Escape_key
tinsert(UISpecialFrames, challengeModes.mainWindow:GetName())

challengeModes.mainWindow:SetScript("OnShow", function()
	PlaySound("GAMEDIALOGOPEN")
end)
challengeModes.mainWindow:SetScript("OnHide", function()
	PlaySound("GAMEDIALOGCLOSE")
end)

-- Background
for x = 0, 3 do
	for y = 0, 2 do
		CreateTexture(174, 171, { 0, 1, 0, 1 }, "BACKGROUND", "TOPLEFT", x * 174 + 8, -y * 171 - 8, "Interface/ChallengeModes/UIFrame" .. faction .. "Background")
	end
end

-- Borders
CreateTexture(700 * scaleX, 30 * scaleY, atlas.TopBorder, "BORDER", "TOP")
CreateTexture(700 * scaleX, 30 * scaleY, atlas.BottomBorder, "BORDER", "BOTTOM")
CreateTexture(30 * scaleX, 400 * scaleY, atlas.LeftBorder, "BORDER", "LEFT", 0, 0, "Interface/ChallengeModes/UIFrame" .. faction .. "Vertical")
CreateTexture(30 * scaleX, 400 * scaleY, atlas.RightBorder, "BORDER", "RIGHT", 0, 0, "Interface/ChallengeModes/UIFrame" .. faction .. "Vertical")

-- Corners
CreateTexture(166 * scaleX, 166 * scaleY, atlas.TopLeftCorner, "ARTWORK", "TOPLEFT")
CreateTexture(166 * scaleX, 166 * scaleY, atlas.BottomLeftCorner, "ARTWORK", "BOTTOMLEFT")
CreateTexture(166 * scaleX, 166 * scaleY, atlas.TopRightCorner, "ARTWORK", "TOPRIGHT")
CreateTexture(166 * scaleX, 166 * scaleY, atlas.BottomRightCorner, "ARTWORK", "BOTTOMRIGHT")

local function CreateMainWindowScroll(x, title, text, img, btnTextures)
	CreateTexture(254 * scaleX, 439 * scaleY, atlas.Scroll, "BORDER", "CENTER", x, -42)
	CreateTexture(281 * scaleX, 84 * scaleY, atlas.ScrollHead, "ARTWORK", "CENTER", x, 124)
	CreateTexture(256 * scaleX, 128 * scaleY, { 0, 1, 0, 1 }, "ARTWORK", "CENTER", x, 52, img)
	CreateTexture(205 * scaleX, 109 * scaleY, atlas.ScrollImgFrame, "OVERLAY", "CENTER", x, 52)

	local scrollTitle = challengeModes.mainWindow:CreateFontString()
	scrollTitle:SetPoint("CENTER", x, 125)
	scrollTitle:SetFont("Fonts\\FRIZQT__.TTF", 14)
	scrollTitle:SetText("|C" .. titleColor .. title .. "|r")

	local scrollText = challengeModes.mainWindow:CreateFontString()
	scrollText:SetSize(200 * scaleX, 300 * scaleY)
	scrollText:SetPoint("CENTER", x, -78)
	scrollText:SetFont("Fonts\\FRIZQT__.TTF", 12)
	scrollText:SetText("|C" .. textColor .. text .. "|r")

	local btn = CreateFrame("Button", nil, challengeModes.mainWindow, "UIPanelButtonTemplate")
	btn:SetSize(120, 40)
	btn:SetPoint("CENTER", x, -190)
	btn:EnableMouse(true)
	local btnText = btn:CreateFontString()
	btnText:SetFont("Fonts\\MORPHEUS.TTF", 18, "OUTLINE")
	btnText:SetShadowOffset(1, -1)
	btn:SetFontString(btnText)
	btn:SetText("Enlist")

	if btnTextures ~= nil then
		btn:SetNormalTexture(btnTextures.Normal)
		btn:SetHighlightTexture(btnTextures.Highlight)
		btn:SetPushedTexture(btnTextures.Pushed)
	end

	return btn
end

scrollBtnTextures = nil
scrollImg1 = "Interface/ChallengeModes/Hardcore" .. faction
scrollImg2 = "Interface/ChallengeModes/Ironman" .. faction
scrollImg3 = "Interface/ChallengeModes/Bloodthirsty" .. faction
if faction == "Alliance" then
	scrollBtnTextures = {
		Normal = "Interface/ChallengeModes/Glue-Panel-Button-Up-Blue",
		Highlight = "Interface/ChallengeModes/Glue-Panel-Button-Highlight-Blue",
		Pushed = "Interface/ChallengeModes/Glue-Panel-Button-Down-Blue",
	}
end

-- Scrolls
challengeModes.mainWindow.scroll1Button = CreateMainWindowScroll(-214, "Hardcore Challenge", "In this mode, your demise will bring a permanent end to your adventure.\n\nIf you have what it takes and progress to the maximum level without dying, you will find unique rewards and eternal glory at the end of this challenge!", scrollImg1, scrollBtnTextures)
challengeModes.mainWindow.scroll2Button = CreateMainWindowScroll(0, "Ironman Challenge", "In this mode, you cannot use talents and are allowed to equip only |CFF9D9D9DPoor|C" .. textColor .. " and |CFFFFFFFFCommon|C" .. textColor .. " equipment.\n\nArmed only with nerves of steel and unshakable resolve, reach the maximum level to attain unique rewards and eternal glory!", scrollImg2, scrollBtnTextures)
challengeModes.mainWindow.scroll3Button = CreateMainWindowScroll(214, "Bloodthirsty Challenge", "In this mode, you can only gain experience by defeating creatures.\n\nMake it to the maximum level in brutal and restless fashion in order to find unique rewards and eternal glory!", scrollImg3, scrollBtnTextures)

-- Title
CreateTexture(512 * scaleX, 85 * scaleY, atlas.TitleMiddle, "BORDER", "TOP", 0, -34)
CreateTexture(202 * scaleX, 85 * scaleY, atlas.TitleLeft, "ARTWORK", "TOPLEFT", 45, -34)
CreateTexture(202 * scaleX, 85 * scaleY, atlas.TitleRight, "ARTWORK", "TOPRIGHT", -45, -34)

challengeModes.mainWindow.titleText = challengeModes.mainWindow:CreateFontString()
challengeModes.mainWindow.titleText:SetPoint("TOP", 0, -62)
challengeModes.mainWindow.titleText:SetFont("Fonts\\FRIZQT__.TTF", 14)
challengeModes.mainWindow.titleText:SetText("You may choose to face greater challenges during your adventures")

-- Header & close button
CreateTexture(atlas.HeaderSize.W * scaleX, atlas.HeaderSize.H * scaleY, atlas.Header, "OVERLAY", "TOP", 0, atlas.HeaderSize.Y)
CreateTexture(33, 32, atlas.CloseCorner, "OVERLAY", "TOPRIGHT")
challengeModes.mainWindow.closeButton = CreateFrame("Button", nil, challengeModes.mainWindow, "UIPanelCloseButton")
challengeModes.mainWindow.closeButton:SetPoint("TOPRIGHT", 0, 0)
challengeModes.mainWindow.closeButton:EnableMouse(true)
challengeModes.mainWindow.closeButton:SetSize(32, 32)
challengeModes.mainWindow.closeButton:SetScript("OnClick", function()
	challengeModes.mainWindow:Hide()
	AIO.Handle(channelName, "closeBannerUI")
end)

-- Confirm window
challengeModes.confirmWindow = CreateFrame("Frame", "ChallengeModesConfirmWindow", UIParent)
challengeModes.confirmWindow:SetSize(515 * scaleX, 438 * scaleY)
challengeModes.confirmWindow:EnableMouse(true)
challengeModes.confirmWindow:SetPoint("CENTER", 0, 0)
challengeModes.confirmWindow:Hide()

_G["ChallengeModes.confirmWindow"] = challengeModes.confirmWindow -- https://wowpedia.fandom.com/wiki/Make_frames_closable_with_the_Escape_key
tinsert(UISpecialFrames, challengeModes.confirmWindow:GetName())

challengeModes.confirmWindow:SetScript("OnShow", function()
	PlaySound("QUESTLOGOPEN")
end)
challengeModes.confirmWindow:SetScript("OnHide", function()
	PlaySound("QUESTLOGCLOSE")
	AIO.Handle(channelName, "closeBannerUI")
end)

CreateTexture(515 * scaleX, 438 * scaleY, atlas.WideScroll, "BACKGROUND", "CENTER", 0, 0, nil, challengeModes.confirmWindow)

challengeModes.confirmWindow.closeButton = CreateFrame("Button", nil, challengeModes.confirmWindow, "UIPanelCloseButton")
challengeModes.confirmWindow.closeButton:SetPoint("TOPRIGHT", -4, -4)
challengeModes.confirmWindow.closeButton:EnableMouse(true)
challengeModes.confirmWindow.closeButton:SetSize(32, 32)

challengeModes.confirmWindow.title = challengeModes.confirmWindow:CreateFontString()
challengeModes.confirmWindow.title:SetPoint("TOP", 0, -30)
challengeModes.confirmWindow.title:SetFont("Fonts\\FRIZQT__.TTF", 20)

local confirmLinesY
local confirmLinesGap
local function CreateConfirmLineFrame()
	local f = CreateFrame("Frame", nil, challengeModes.confirmWindow)
	f:SetSize(challengeModes.confirmWindow:GetSize())
	f:SetPoint("CENTER", challengeModes.confirmWindow)
	f:Hide()
	return f
end
local confirmLineFrames = {
	Hardcore = CreateConfirmLineFrame(),
	Ironman = CreateConfirmLineFrame(),
	Bloodthirsty = CreateConfirmLineFrame(),
}
local function CreateConfirmXLine(text, parent)
	CreateTexture(nil, nil, { 0, 1, 0, 1 }, "ARTWORK", "LEFT", 30, confirmLinesY, "Interface/GLUES/LOGIN/Glues-CheckBox-Check", parent)

	local txt = parent:CreateFontString()
	txt:SetPoint("LEFT", 54, confirmLinesY + 1)
	txt:SetFont("Fonts\\FRIZQT__.TTF", 13)
	txt:SetText("|CFFCD0000" .. text .. "|r")
	txt:SetShadowOffset(1, -1)

	confirmLinesY = confirmLinesY - confirmLinesGap
end

local function CreateConfirmOKLine(text, parent)
	CreateTexture(nil, nil, { 0, 1, 0, 1 }, "ARTWORK", "LEFT", 27, confirmLinesY - 4, "Interface/AchievementFrame/UI-Achievement-Criteria-Check", parent)

	local txt = parent:CreateFontString()
	txt:SetPoint("LEFT", 54, confirmLinesY)
	txt:SetFont("Fonts\\FRIZQT__.TTF", 13)
	txt:SetText("|CFF097000" .. text .. "|r")
	txt:SetShadowOffset(1, -1)

	confirmLinesY = confirmLinesY - confirmLinesGap
end

challengeModes.confirmWindow.enlistButton = CreateFrame("Button", nil, challengeModes.confirmWindow, "UIPanelButtonTemplate")
challengeModes.confirmWindow.enlistButton:SetSize(160, 40)
challengeModes.confirmWindow.enlistButton:SetPoint("CENTER", -85, -146)
challengeModes.confirmWindow.enlistButton:EnableMouse(true)
challengeModes.confirmWindow.enlistButtonText = challengeModes.confirmWindow.enlistButton:CreateFontString()
challengeModes.confirmWindow.enlistButtonText:SetFont("Fonts\\MORPHEUS.TTF", 18, "OUTLINE")
challengeModes.confirmWindow.enlistButtonText:SetShadowOffset(1, -1)
challengeModes.confirmWindow.enlistButton:SetFontString(challengeModes.confirmWindow.enlistButtonText)
challengeModes.confirmWindow.enlistButton:SetText("Enlist")
if scrollBtnTextures ~= nil then
	challengeModes.confirmWindow.enlistButton:SetNormalTexture(scrollBtnTextures.Normal)
	challengeModes.confirmWindow.enlistButton:SetHighlightTexture(scrollBtnTextures.Highlight)
	challengeModes.confirmWindow.enlistButton:SetPushedTexture(scrollBtnTextures.Pushed)
end
challengeModes.confirmWindow.enlistButton:SetScript("OnClick", function()
	AIO.Handle(channelName, "enlist", challengeModes.selectedChallenge)
end)

challengeModes.confirmWindow.cancelButton = CreateFrame("Button", nil, challengeModes.confirmWindow, "UIPanelButtonGrayTemplate")
challengeModes.confirmWindow.cancelButton:SetSize(160, 40)
challengeModes.confirmWindow.cancelButton:SetPoint("CENTER", 85, -146)
challengeModes.confirmWindow.cancelButton:EnableMouse(true)
challengeModes.confirmWindow.cancelButtonText = challengeModes.confirmWindow.cancelButton:CreateFontString()
challengeModes.confirmWindow.cancelButtonText:SetFont("Fonts\\MORPHEUS.TTF", 18, "OUTLINE")
challengeModes.confirmWindow.cancelButtonText:SetShadowOffset(1, -1)
challengeModes.confirmWindow.cancelButton:SetFontString(challengeModes.confirmWindow.cancelButtonText)
challengeModes.confirmWindow.cancelButton:SetText("Cancel")
challengeModes.confirmWindow.cancelButton:SetScript("OnClick", function()
	challengeModes.confirmWindow:Hide()
end)


local scrollButtons = { challengeModes.mainWindow.scroll1Button, challengeModes.mainWindow.scroll2Button, challengeModes.mainWindow.scroll3Button }
for _, btn in pairs(scrollButtons) do
	local challengeId
	local challengeName
	if btn == challengeModes.mainWindow.scroll1Button then
		challengeId = 1
		challengeName = "Hardcore"
	elseif btn == challengeModes.mainWindow.scroll2Button then
		challengeId = 2
		challengeName = "Ironman"
	else
		challengeId = 4
		challengeName = "Bloodthirsty"
	end

	-- Add the detail lines
	local confirmLineFrame = confirmLineFrames[challengeName]
	confirmLinesY = 110
	confirmLinesGap = 20
	if challengeName == "Hardcore" then
		CreateConfirmXLine("Any death is permanent and will delete your character", confirmLineFrame)
	end
	if challengeName == "Ironman" then
		CreateConfirmXLine("Can only wear |CFF9D9D9DPoor|CFFCD0000 and |CFFFFFFFFCommon|CFFCD0000 equipment", confirmLineFrame)
		CreateConfirmXLine("Cannot use talent points", confirmLineFrame)
	elseif challengeName == "Bloodthirsty" then
		CreateConfirmXLine("Can only gain experience from defeating creatures", confirmLineFrame)
	end
	CreateConfirmXLine("Can only party up with players with the same challenges", confirmLineFrame)
	CreateConfirmXLine("Can only trade with players with the same challenges", confirmLineFrame)
	CreateConfirmXLine("Cannot send or receive items or money by mail", confirmLineFrame)
	CreateConfirmXLine("Cannot use Auction Houses", confirmLineFrame)
	CreateConfirmXLine("Cannot use Guild Banks", confirmLineFrame)
	CreateConfirmXLine("Cannot be turned off", confirmLineFrame)

	confirmLinesY = confirmLinesY - 10
	CreateConfirmOKLine("Join the Hall of Fame when reaching maximum level", confirmLineFrame)
	CreateConfirmOKLine("Receive unique rewards when reaching maximum level", confirmLineFrame)
	if challengeName == "Hardcore" then
		CreateConfirmOKLine("Death is not permanent anymore at maximum level", confirmLineFrame)
	end
	CreateConfirmOKLine("You can enlist for multiple challenges at the same time", confirmLineFrame)

	btn:SetScript("OnClick", function()
		challengeModes.selectedChallenge = challengeId

		-- Set the title
		challengeModes.confirmWindow.title:SetText("|C" .. titleColor .. challengeName .. " Challenge" .. "|r")

		-- Show the correct lines
		for _, f in pairs(confirmLineFrames) do
			f:Hide()
		end
		confirmLineFrame:Show()

		-- Switch to the confirmation window
		challengeModes.mainWindow:Hide()
		challengeModes.confirmWindow:Show()
	end)
end


-- Death window
challengeModes.deathWindow = CreateFrame("Frame", "ChallengeModesDeathWindow", UIParent)
challengeModes.deathWindow:SetSize(490 * scaleX, 446 * scaleY)
challengeModes.deathWindow:EnableMouse(true)
challengeModes.deathWindow:SetPoint("CENTER", 0, 0)
challengeModes.deathWindow:Hide()

CreateTexture(490 * scaleX, 446 * scaleY, { 0.0, 0.95703125, 0.0, 0.87109375 }, "BACKGROUND", "CENTER", 0, 0, "Interface/ChallengeModes/DeathWindowBackground", challengeModes.deathWindow)
CreateTexture(490 * scaleX, 446 * scaleY, { 0.0, 0.95703125, 0.0, 0.87109375 }, "BORDER", "CENTER", 0, 0, "Interface/ChallengeModes/DeathWindowBorder", challengeModes.deathWindow)
CreateTexture(187 * scaleX, 187 * scaleY, { 0.0, 1.0, 0.0, 1.0 }, "ARTWORK", "TOP", 0, -60, "Interface/ChallengeModes/Graveyard" .. random(1, 17), challengeModes.deathWindow)
CreateTexture(207 * scaleX, 207 * scaleY, { 0.0, 0.80859375, 0.0, 0.80859375 }, "OVERLAY", "TOP", 0, -60 + 9 * scaleY, "Interface/ChallengeModes/SquareBorder", challengeModes.deathWindow)

challengeModes.deathWindow.title = challengeModes.deathWindow:CreateFontString()
challengeModes.deathWindow.title:SetPoint("TOP", 0, -20)
challengeModes.deathWindow.title:SetFont("Fonts\\MORPHEUS.TTF", 22)
challengeModes.deathWindow.title:SetText("YOU DIED")

challengeModes.deathWindow.text = challengeModes.deathWindow:CreateFontString()
challengeModes.deathWindow.text:SetPoint("BOTTOM", 0, 80)
challengeModes.deathWindow.text:SetFont("Fonts\\FRIZQT__.TTF", 16)

challengeModes.deathWindow.button = CreateFrame("Button", nil, challengeModes.deathWindow, "UIPanelButtonTemplate")
challengeModes.deathWindow.button:SetSize(120, 40)
challengeModes.deathWindow.button:SetPoint("BOTTOM", 0, 24)
challengeModes.deathWindow.button:EnableMouse(true)
challengeModes.deathWindow.buttonText = challengeModes.deathWindow.button:CreateFontString()
challengeModes.deathWindow.buttonText:SetFont("Fonts\\MORPHEUS.TTF", 18, "OUTLINE")
challengeModes.deathWindow.buttonText:SetShadowOffset(1, -1)
challengeModes.deathWindow.button:SetFontString(challengeModes.deathWindow.buttonText)
challengeModes.deathWindow.button:SetText("Logout")
challengeModes.deathWindow.button:SetScript("OnClick", function()
	RepopMe()
end)

function Handlers.CheckAddonVersion(player, addonVersion)
	if not CheckAddonVersion(addonVersion) then
		AIO.Handle(channelName, "notifyInstallAddon", true)
	end
end

function Handlers.OpenBannerUI(player, addonVersion, eligible)
	if not CheckAddonVersion(addonVersion) then
		AIO.Handle(channelName, "notifyInstallAddon", true)
		return
	end
	AIO.Handle(channelName, "openBannerUI")

	for i, btn in pairs(scrollButtons) do
		if eligible[i] ~= true then
			local errTxt = ""
			if eligible[i] == "CHALLENGEACTIVE" then
				errTxt = "You are already enlisted for this challenge."
			elseif eligible[i] == "EXP" then
				errTxt = "Only available to level 1 characters with no experience points.\nCreate a fresh character to start the challenge."
			elseif eligible[i] == "ITEMS" then
				errTxt = "You possess items that were not included in your starting equipment.\nGet rid of them or create a fresh character to start the challenge."
			elseif eligible[i] == "MONEY" then
				errTxt = "You have money in your inventory.\nGet rid of it or create a fresh character to start the challenge."
			elseif eligible[i] == "MAIL" then
				errTxt = "You have pending mails.\nCreate a fresh character to start the challenge."
			elseif eligible[i] == "DEATHS" then
				errTxt = "This character has died before...\nCreate a fresh character to start the challenge."
			elseif eligible[i] == "RANGE" then
				errTxt = "You are too far away."
			end

			btn:Disable()
			btn:SetMotionScriptsWhileDisabled(true)

			btn:SetScript("OnEnter", function()
				GameTooltip:SetOwner(btn, "ANCHOR_TOP")
				GameTooltip:SetText(errTxt)
				GameTooltip:Show()
			end)

			btn:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)
		else
			btn:Enable()
			btn:SetScript("OnEnter", nil)
			btn:SetScript("OnLeave", nil)
		end
	end

	challengeModes.mainWindow:Show()
end

function Handlers.CloseBannerUI()
	challengeModes.mainWindow:Hide()
	challengeModes.confirmWindow:Hide()
end

function Handlers.Enlisted(player, challenge)
	if challengeModes.enlistSplashFrame ~= nil then
		challengeModes.enlistSplashFrame:Hide()
	end

	challengeModes.enlistSplashFrame = CreateFrame("Frame", "ChallengeModesEnlistSplash", UIParent)
	challengeModes.enlistSplashFrame:SetSize(467 * scaleX, 141 * scaleY)
	challengeModes.enlistSplashFrame:EnableMouse(false)
	challengeModes.enlistSplashFrame:SetPoint("BOTTOM", 0, 150)
	challengeModes.enlistSplashFrame:SetAlpha(0)

	local text = challengeModes.enlistSplashFrame:CreateFontString()
	text:SetSize(350 * scaleX, 140 * scaleY)
	text:SetPoint("CENTER", 0, 0)
	text:SetFont("Fonts\\FRIZQT__.TTF", 16)
	text:SetText("Enlisted for " .. challenge .. " Challenge!")
	text:SetShadowOffset(1, -1)

	CreateTexture(467 * scaleX, 141 * scaleY, atlas.EnlistSplash, "ARTWORK", "CENTER", 0, 0, "Interface/ChallengeModes/ScenarioHordeAlliance", challengeModes.enlistSplashFrame)

	local animGroup = challengeModes.enlistSplashFrame:CreateAnimationGroup()
	local alphaAnim = animGroup:CreateAnimation("Alpha")
	alphaAnim:SetDuration(0.1)
	alphaAnim:SetChange(1)
	alphaAnim:SetSmoothing("IN")
	animGroup:SetScript("OnUpdate", function()
		if animGroup:GetLoopState() == "NONE" then
			challengeModes.enlistSplashFrame:SetAlpha(1)
		end
	end)
	animGroup:Play()
	PlaySound("GLUECREATECHARACTERBUTTON")

	local timer = 5
	challengeModes.enlistSplashFrame:SetScript("OnUpdate", function(self, dt)
		if timer > 0 then
			timer = timer - dt

			if timer <= 0 then
				animGroup = challengeModes.enlistSplashFrame:CreateAnimationGroup()
				alphaAnim = animGroup:CreateAnimation("Alpha")
				alphaAnim:SetDuration(2)
				alphaAnim:SetChange(-1)
				animGroup:SetScript("OnUpdate", function()
					if animGroup:GetLoopState() == "NONE" then
						challengeModes.enlistSplashFrame:SetScript("OnUpdate", nil)
						challengeModes.enlistSplashFrame:Hide()
						challengeModes.enlistSplashFrame = nil
					end
				end)
				animGroup:Play()
			end
		end
	end)
end

function Handlers.OpenDeathUI(player, challenge, playedTime, rank)
	PlaySoundFile("Sound\\Interface\\PVPWARNING.wav")
	local timer = 1.65
	challengeModes.deathWindow:SetAlpha(0)
	challengeModes.deathWindow:Show()
	challengeModes.deathWindow.text:SetText(UnitName("player") .. "'s journey ends here\nDied at level " .. UnitLevel("player") .. "\nPlayed for " .. playedTime .. "\n" .. challenge .. " rank: #" .. rank)
	challengeModes.deathWindow:SetScript("OnUpdate", function(self, dt)
		if timer > 0 then
			timer = timer - dt

			if timer <= 0 then
				challengeModes.deathWindow:SetScript("OnUpdate", nil)
				challengeModes.deathWindow:SetAlpha(1)
			end
		end
	end)
end
