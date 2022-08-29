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
local level = UnitLevel("player")

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
scrollImg2 = "Interface/ChallengeModes/answer-warfronts-horde-Raider-small"
if faction == "Alliance" then
	scrollImg2 = "Interface/ChallengeModes/answer-warfronts-alliance-Knight-small"
	scrollBtnTextures = {
		Normal = "Interface/ChallengeModes/Glue-Panel-Button-Up-Blue",
		Highlight = "Interface/ChallengeModes/Glue-Panel-Button-Highlight-Blue",
		Pushed = "Interface/ChallengeModes/Glue-Panel-Button-Down-Blue",
	}
end

-- Scrolls
challengeModes.mainWindow.scroll1Button = CreateMainWindowScroll(-214, "Hardcore Challenge", "In this mode, your demise will bring a permanent end to your adventure.\n\nIf you have what it takes and progress to the maximum level without dying, you will find unique rewards and eternal glory at the end of this challenge!", "Interface/ChallengeModes/answer-ChromieScenario-Chromie-small", scrollBtnTextures)
challengeModes.mainWindow.scroll2Button = CreateMainWindowScroll(0, "Ironman Challenge", "Similarly to the Hardcore Challenge, this mode will bring an end to your adventure if you were to perish. Additionally, you cannot use talents and are allowed to equip only |CFF9D9D9DPoor|C" .. textColor .. " and |CFFFFFFFFCommon|C" .. textColor .. " equipment.\n\nArmed only with nerves of steel and unshakable resolve, reach the maximum level to attain unique rewards and eternal glory!", scrollImg2, scrollBtnTextures)
challengeModes.mainWindow.scroll3Button = CreateMainWindowScroll(214, "Bloodthirsty Challenge", "In the same vein as the Hardcore Challenge, this mode will end your adventure for good upon your death. You can also only gain experience by defeating creatures.\n\nMake it to the maximum level in brutal and restless fashion in order to find unique rewards and eternal glory!", "Interface/ChallengeModes/answer-ChromieScenario-Chromie-small", scrollBtnTextures)

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

-- Confirm window
challengeModes.confirmWindow = CreateFrame("Frame", "ChallengeModesConfirmWindow", UIParent)
challengeModes.confirmWindow:SetSize(515 * scaleX, 438 * scaleY)
challengeModes.confirmWindow:EnableMouse(true)
challengeModes.confirmWindow:SetPoint("CENTER", 0, 0)
challengeModes.confirmWindow:Hide()

CreateTexture(515 * scaleX, 438 * scaleY, atlas.WideScroll, "BACKGROUND", "CENTER", 0, 0, nil, challengeModes.confirmWindow)

challengeModes.confirmWindow.closeButton = CreateFrame("Button", nil, challengeModes.confirmWindow, "UIPanelCloseButton")
challengeModes.confirmWindow.closeButton:SetPoint("TOPRIGHT", -4, -4)
challengeModes.confirmWindow.closeButton:EnableMouse(true)
challengeModes.confirmWindow.closeButton:SetSize(32, 32)

challengeModes.confirmWindow.title = challengeModes.confirmWindow:CreateFontString()
challengeModes.confirmWindow.title:SetPoint("TOP", 0, -36)
challengeModes.confirmWindow.title:SetFont("Fonts\\FRIZQT__.TTF", 20)

local confirmLinesY
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
	CreateTexture(nil, nil, { 0, 1, 0, 1 }, "ARTWORK", "LEFT", 40, confirmLinesY, "Interface/GLUES/LOGIN/Glues-CheckBox-Check", parent)

	local txt = parent:CreateFontString()
	txt:SetPoint("LEFT", 64, confirmLinesY + 1)
	txt:SetFont("Fonts\\FRIZQT__.TTF", 13)
	txt:SetText("|CFFCD0000" .. text .. "|r")
	txt:SetShadowOffset(1, -1)

	confirmLinesY = confirmLinesY - 20
end

local function CreateConfirmOKLine(text, parent)
	CreateTexture(nil, nil, { 0, 1, 0, 1 }, "ARTWORK", "LEFT", 37, confirmLinesY - 4, "Interface/AchievementFrame/UI-Achievement-Criteria-Check", parent)

	local txt = parent:CreateFontString()
	txt:SetPoint("LEFT", 64, confirmLinesY)
	txt:SetFont("Fonts\\FRIZQT__.TTF", 13)
	txt:SetText("|CFF097000" .. text .. "|r")
	txt:SetShadowOffset(1, -1)

	confirmLinesY = confirmLinesY - 20
end

challengeModes.confirmWindow.enlistButton = CreateFrame("Button", nil, challengeModes.confirmWindow, "UIPanelButtonTemplate")
challengeModes.confirmWindow.enlistButton:SetSize(160, 40)
challengeModes.confirmWindow.enlistButton:SetPoint("CENTER", -85, -140)
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
	challengeModes.confirmWindow:Hide()
end)

challengeModes.confirmWindow.cancelButton = CreateFrame("Button", nil, challengeModes.confirmWindow, "UIPanelButtonGrayTemplate")
challengeModes.confirmWindow.cancelButton:SetSize(160, 40)
challengeModes.confirmWindow.cancelButton:SetPoint("CENTER", 85, -140)
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
	local challengeName
	if btn == challengeModes.mainWindow.scroll1Button then
		challengeName = "Hardcore"
	elseif btn == challengeModes.mainWindow.scroll2Button then
		challengeName = "Ironman"
	else
		challengeName = "Bloodthirsty"
	end

	-- Add the detail lines
	local confirmLineFrame = confirmLineFrames[challengeName]
	confirmLinesY = 100
	if challengeName == "Ironman" then
		confirmLinesY = 110
	end
	CreateConfirmXLine("Any death is permanent and will delete your character", confirmLineFrame)
	if challengeName == "Ironman" then
		CreateConfirmXLine("Can only wear |CFF9D9D9DPoor|CFFCD0000 and |CFFFFFFFFCommon|CFFCD0000 equipment", confirmLineFrame)
		CreateConfirmXLine("Cannot use talent points", confirmLineFrame)
	elseif challengeName == "Bloodthirsty" then
		CreateConfirmXLine("Can only gain experience from defeating creatures", confirmLineFrame)
	end
	CreateConfirmXLine("Can only party up with other " .. challengeName .. " players", confirmLineFrame)
	CreateConfirmXLine("Cannot use the Auction House", confirmLineFrame)
	CreateConfirmXLine("Cannot trade with other players", confirmLineFrame)
	CreateConfirmXLine("Cannot use Guild Banks", confirmLineFrame)
	CreateConfirmXLine("Cannot be turned off", confirmLineFrame)

	confirmLinesY = confirmLinesY - 10
	CreateConfirmOKLine("Join the Hall of Fame when reaching maximum level", confirmLineFrame)
	CreateConfirmOKLine("Receive unique rewards when reaching maximum level", confirmLineFrame)
	CreateConfirmOKLine("Death is not permanent anymore at maximum level", confirmLineFrame)

	btn:SetScript("OnClick", function()
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

function Handlers.OpenBannerUI(player, game)
	challengeModes.mainWindow:Show()
end
