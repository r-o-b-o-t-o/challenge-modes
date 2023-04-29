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
local neutralAtlas = {
	TopBorder = { 0.0, 0.25, 0.0009765625, 0.0302734375 },
	BottomBorder = { 0.0, 0.25, 0.1171875, 0.146484375 },
	LeftBorder = { 0.015625, 0.484375, 0.0, 1.0 },
	RightBorder = { 0.515625, 0.984375, 0.0, 1.0 },
	TopLeftCorner = { 0.0009765625, 0.1630859375, 0.720703125, 0.8828125 },
	TopRightCorner = { 0.1630859375, 0.0009765625, 0.720703125, 0.8828125 },
	BottomLeftCorner = { 0.0009765625, 0.1630859375, 0.8828125, 0.720703125 },
	BottomRightCorner = { 0.1630859375, 0.0009765625, 0.8828125, 0.720703125 },
	TitleLeft = { 0.755859375, 0.953125, 0.1484375, 0.2314453125 },
	TitleRight = { 0.755859375, 0.953125, 0.2333984375, 0.31640625 },
	TitleMiddle = { 0.0, 0.125, 0.0322265625, 0.115234375 },
	CloseCorner = { 0.0009765625, 0.033203125, 0.5791015625, 0.6103515625 },
	WideScroll = { 0.2509765625, 0.75390625, 0.1484375, 0.576171875 },
}

local classNames = {}
classNames[1] = "WARRIOR"
classNames[2] = "PALADIN"
classNames[3] = "HUNTER"
classNames[4] = "ROGUE"
classNames[5] = "PRIEST"
classNames[6] = "DEATHKNIGHT"
classNames[7] = "SHAMAN"
classNames[8] = "MAGE"
classNames[9] = "WARLOCK"
classNames[11] = "DRUID"

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

local locales = {}
locales["enUS"] = {
	Main_Title = "You may choose to face greater challenges during your adventures",
	Main_Desc1 = "In this mode, your demise will bring a permanent end to your adventure.\n\nIf you have what it takes and progress to the maximum level without dying, you will find unique rewards and eternal glory at the end of this challenge!",
	Main_Desc2 = "In this mode, you cannot use talents and are allowed to equip only |CFF9D9D9DPoor|C" .. textColor .. " and |CFFFFFFFFCommon|C" .. textColor .. " equipment.\n\nArmed only with nerves of steel and unshakable resolve, reach the maximum level to attain unique rewards and eternal glory!",
	Main_Desc3 = "In this mode, you can only gain experience by defeating creatures.\n\nMake it to the maximum level in brutal and restless fashion in order to find unique rewards and eternal glory!",
	Main_ChallengeName = "{1} Challenge",
	Main_Enlist = "Enlist",
	Main_Hardcore = "Hardcore",
	Main_Ironman = "Ironman",
	Main_Bloodthirsty = "Bloodthirsty",
	Confirm_Permadeath = "Any death is permanent and will delete your character",
	Confirm_Equipment = "Can only wear |CFF9D9D9DPoor|CFFCD0000 and |CFFFFFFFFCommon|CFFCD0000 equipment",
	Confirm_Talents = "Cannot use talent points",
	Confirm_XP = "Can only gain experience from defeating creatures",
	Confirm_Party = "Can only party up with players with the same challenges",
	Confirm_Trade = "Can only trade with players with the same challenges",
	Confirm_Mail = "Can only receive items or money by mail from players\nwith the same challenges",
	Confirm_AH = "Cannot use Auction Houses",
	Confirm_GB = "Cannot use Guild Banks",
	Confirm_Disable = "Cannot be turned off",
	Confirm_HallOfFame = "Join the Hall of Fame",
	Confirm_Rewards = "Receive unique rewards when reaching maximum level",
	Confirm_PermaDeathMaxLvl = "Death is not permanent anymore at maximum level",
	Confirm_Combo = "You can enlist for multiple challenges at the same time",
	Confirm_Cancel = "Cancel",
	HoF_Title = "In remembrance of the bravest adventurers",
	HoF_Completed = "Completed",
	HoF_Dead = "Failed",
	HoF_Active = "Active",
	HoF_MyChars = "My Characters",
	HoF_Solo = "Solo",
	HoF_Classes = "{1} classes displayed",
	HoF_Name = "Name",
	HoF_Level = "Level",
	HoF_Rank = "Ranking",
	SelectAll = "Select All",
	SelectNone = "Select None",
	Death_Title = "YOU DIED",
	Completed_Title = "CONGRATULATIONS!",
	Completed_Text = "{1} faced many challenges,\nbut overcame them through\nsheer will and determination\n\nPlayed for {2}\n\n{3} rank: #{4}",
	Death_Logout = "Logout",
	Death_Text = "{1}'s journey ends here\n\nDied at level {2}\nPlayed for {3}\n\n{4} rank: #{5}",
	Splash_Text = "Enlisted for {1} Challenge!",
	Err_ChallengeActive = "You are already enlisted for this challenge.",
	Err_Exp = "Only available to level 1 characters with no experience points.\nCreate a fresh character to start the challenge.",
	Err_Items = "You possess items that were not included in your starting equipment.\nGet rid of them or create a fresh character to start the challenge.",
	Err_Money = "You have money in your inventory.\nGet rid of it or create a fresh character to start the challenge.",
	Err_Mail = "You have pending mails.\nCreate a fresh character to start the challenge.",
	Err_Deaths = "This character has died before...\nCreate a fresh character to start the challenge.",
	Err_Range = "You are too far away."
}
locales["enGB"] = locales["enUS"]
locales["frFR"] = {
	Main_Title = "Vous pouvez choisir de relever des défis au cours de vos aventures",
	Main_Desc1 = "Dans ce mode, votre décès mettra un terme définitif à votre aventure.\n\nSi vous avez assez de courage et progressez jusqu'au niveau maximum sans mourir, vous trouverez des récompenses uniques et une gloire éternelle à la fin de ce défi !",
	Main_Desc2 = "Dans ce mode, vous ne pouvez pas utiliser les points de talent et vous ne pouvez équiper que des objets de qualité |CFF9D9D9DMédiocre|C" .. textColor .. " ou |CFFFFFFFFNormale|C" .. textColor .. ".\n\nArmé uniquement de nerfs d'acier et d'une détermination inébranlable, atteignez le niveau maximum pour obtenir des récompenses uniques et une gloire éternelle !",
	Main_Desc3 = "Dans ce mode, vous gagnez de l'expérience seulement en tuant des créatures.\n\nAtteignez le niveau maximum de manière brutale afin d'acquérir des récompenses uniques et une gloire éternelle !",
	Main_ChallengeName = "Défi {1}",
	Main_Enlist = "S'inscrire",
	Main_Hardcore = "Hardcore",
	Main_Ironman = "Homme de Fer",
	Main_Bloodthirsty = "Sanguinaire",
	Confirm_Permadeath = "La mort est permanente et entraîne une suppression du personnage",
	Confirm_Equipment = "Vous pourrez seulement porter de l'équipement de qualité |CFF9D9D9DMédiocre|CFFCD0000 ou |CFFFFFFFFNormale|CFFCD0000",
	Confirm_Talents = "Vous ne pourrez pas utiliser de points de talents",
	Confirm_XP = "Vous pourrez seulement gagner de l'expérience en tuant des créatures",
	Confirm_Party = "Vous pourrez seulement être en groupe avec les joueurs qui ont le même défi",
	Confirm_Trade = "Vous pourrez seulement échanger avec les joueurs qui ont le même défi",
	Confirm_Mail = "Seuls les joueurs qui ont le même défi que vous pourront\nvous envoyer des objets ou de l'argent par courrier",
	Confirm_AH = "Vous ne pourrez pas utiliser l'hôtel des ventes",
	Confirm_GB = "Vous ne pourrez pas utiliser les banques de guildes",
	Confirm_Disable = "Ne peut pas être désactivé",
	Confirm_HallOfFame = "Rejoignez le Panthéon",
	Confirm_Rewards = "Recevez des récompenses uniques en atteignant le niveau maximum",
	Confirm_PermaDeathMaxLvl = "La mort n'est plus permanente au niveau maximum",
	Confirm_Combo = "Vous pouvez vous inscrire pour plusieurs défis simultanément",
	Confirm_Cancel = "Annuler",
	HoF_Title = "En mémoire des plus braves aventuriers",
	HoF_Completed = "Terminé",
	HoF_Dead = "Échoué",
	HoF_Active = "Actif",
	HoF_MyChars = "Mes Personnages",
	HoF_Solo = "Solo",
	HoF_Classes = "{1} classes affichées",
	HoF_Name = "Nom",
	HoF_Level = "Niv.",
	HoF_Rank = "Rang",
	SelectAll = "Sélectionner Tout",
	SelectNone = "Sélectionner Aucun",
	Death_Title = "VOUS ÊTES MORT",
	Completed_Title = "FÉLICITATIONS!",
	Completed_Text = "{1} a fait face à de\nnombreux défis, mais les a surmontés\ngrâce à sa volonté et sa détermination\n\n{2} de jeu\n\nRang {3} : #{4}",
	Death_Logout = "Déconnexion",
	Death_Text = "L'aventure de {1} s'arrête ici\n\nMort au niveau {2}\n{3} de jeu\n\nRang {4} : #{5}",
	Splash_Text = "Inscrit pour le défi {1} !",
	Err_ChallengeActive = "Vous êtes déjà inscrit à ce défi.",
	Err_Exp = "Disponible seulement pour les personnages niveau 1 sans points d'expérience.\nCréez un nouveau personnage pour commencer le défi.",
	Err_Items = "Vous avez de l'équipement qui n'était pas inclus dans votre inventaire de départ.\nDébarrassez-vous en ou créez un nouveau personnage pour commencer le défi.",
	Err_Money = "Vous avez de l'argent dans votre inventaire.\nDébarrassez-vous en ou créez un nouveau personnage pour commencer le défi.",
	Err_Mail = "Vous avez des courriers en attente.\nCréez un nouveau personnage pour commencer le défi.",
	Err_Deaths = "Ce personnage a déjà décédé...\nCréez un nouveau personnage pour commencer le défi.",
	Err_Range = "Vous êtes trop loin."
}
locales["deDE"] = {
	Main_Title = "Ihr könnt zusätzliche Herausforderungen für Eure Abenteuer wählen",
	Main_Desc1 = "In diesem Modus wird Euer Ableben das endgültige Ende Eures Abenteuers bedeuten.\n\nFalls Ihr es schafft und das maximale Level erreicht ohne zu sterben, werdet Ihr einzigartige Belohnungen und ewigen Ruhm bei Abschluss der Herausforderung erhalten!",
	Main_Desc2 = "In diesem Modus könnt Ihr nur |CFF9D9D9DSchlechte|C" .. textColor .. " und |CFFFFFFFFVerbreitete|C" .. textColor .. " Gegenstände benutzen.\n\nBewaffnet nur mit Nerven aus Stahl und unerschütterlicher Entschlossenheit erhaltet Ihr einzigartige Belohnungen und ewigen Ruhm für das Erreichen des Maximallevels!",
	Main_Desc3 = "In diesem Modus könnt Ihr nur Erfahrung sammeln, indem Ihr Gegner besiegt.\n\nErreicht auf brutale und rastlose Weise die maximale Stufe, um einzigartige Belohnungen und ewigen Ruhm zu finden!",
	Main_ChallengeName = "{1} Modus",
	Main_Enlist = "Anmeldung",
	Main_Hardcore = "Hardcore",
	Main_Ironman = "Ironman",
	Main_Bloodthirsty = "Blutdurstig",
	Confirm_Permadeath = "Der Tod ist dauerhaft und löscht Euren Charakter",
	Confirm_Equipment = "Man kann nur |CFF9D9D9DSchlechte|CFFCD0000 und |CFFFFFFFFVerbreitete|CFFCD0000 Ausrüstung benutzen",
	Confirm_Talents = "Man kann keine Talentpunkte nutzen",
	Confirm_XP = "Man kann ausschließlich durch das Töten von Gegnern Erfahrung erhalten.",
	Confirm_Party = "Man kann nur mit Spielern in eine Gruppe, die genau die gleichen Herausforderungen haben",
	Confirm_Trade = "Man kann nur mit Spielern handeln, die genau die gleichen Herausforderungen haben",
	Confirm_Mail = "Man kann nur Gegenstände oder Gold von Spielern per Mail erhalten,\ndie genau die gleichen Herausforderungen haben",
	Confirm_AH = "Man kann das Auktionshaus nicht nutzen",
	Confirm_GB = "Man kann die Gildenbank nicht nutzen",
	Confirm_Disable = "Kann nicht deaktiviert werden",
	Confirm_HallOfFame = "Werdet Teil der Ruhmeshalle",
	Confirm_Rewards = "Erhalte einzigartige Belohnungen, wenn Ihr das Maximallevel erreicht",
	Confirm_PermaDeathMaxLvl = "Der Tod ist nicht mehr dauerhaft, wenn Ihr das Maximallevel erreicht",
	Confirm_Combo = "Ihr könnt euch für mehrere Herausforderungen gleichzeitig anmelden",
	Confirm_Cancel = "Abbrechen",
	HoF_Title = "In Erinnerung an die tapfersten Abenteurer",
	HoF_Completed = "Beendet",
	HoF_Dead = "Fehlgeschlagen",
	HoF_Active = "Aktiv",
	HoF_MyChars = "Meine Charaktere",
	HoF_Solo = "Solo",
	HoF_Classes = "{1} Klassen",
	HoF_Name = "Name",
	HoF_Level = "Level",
	HoF_Rank = "Rang",
	SelectAll = "Alles auswählen",
	SelectNone = "Keine auswählen",
	Death_Title = "IHR SEIT TOT",
	Completed_Title = "GLÜCKWUNSCH!",
	Completed_Text = "{1} hat vielen Herausforderungen\ngetrotzt, und sie durch\nbloßen Willen und\nEntschlossenheit bestanden.\n\nSpielzeit: {2}\n\n{3} Rang: #{4}",
	Death_Logout = "Ausloggen",
	Death_Text = "{1}'s Reise endet hier\n\nGestorben auf Level {2}\nSpielzeit: {3}\n\n{4} Rang: #{5}",
	Splash_Text = "Angemeldet für die {1} Herausforderung!",
	Err_ChallengeActive = "Ihr seid bereits für diese Herausforderung angemeldet.",
	Err_Exp = "Nur möglich für Level 1 Charaktere ohne Erfahrungspunkte.\nErstellt einen neuen Charakter, um die Herausforderung zu starten.",
	Err_Items = "Ihr verfügt über einen Gegenstand, der nicht zu eurem Startinventar gehört.\nWerdet ihn los oder erstellt einen neuen Charakter, um die Herausforderung zu starten.",
	Err_Money = "Ihr habt Geld in eurem Inventar.\nWerdet es los oder erstellt einen neuen Charakter, um die Herausforderung zu starten.",
	Err_Mail = "Es wurde euch Post zugestellt.\nErstellt einen neuen Charakter, um die Herausforderung zu starten.",
	Err_Deaths = "Dieser Charakter ist bereits gestorben...\nErstellt einen neuen Charakter, um die Herausforderung zu starten.",
	Err_Range = "Ihr seid zu weit entfernt."
}
locales["esES"] = {
	Main_Title = "Puedes elegir enfrentarte a mayores desafíos en tus aventuras",
	Main_Desc1 = "En este modo, morir traerá un final permanente a tu aventura.\n\nSi tienes lo que se necesita y llegas al nivel máximo sin morir, encontraras recompensas uúnicas y gloria eterna!",
	Main_Desc2 = "En este modo, no puedes usar talentos y sólo puedes equipar ítems de calidad |CFF9D9D9DPobre|C" .. textColor .. " y |CFFFFFFFFComún|C" .. textColor .. ".\n\nArmado Sólo con nervios de acero y resolución inquebrantable, alcanza el nivel máximo para recibir recompensas únicas y gloria eterna!",
	Main_Desc3 = "En este modo, sólo puedes ganar experiencia derrotando enemigos.\n\nAlcanza el nivel máximo en estilo brutal e imparable para encontrar recompensas únicas y gloria eterna!",
	Main_ChallengeName = "Desafío {1}",
	Main_Enlist = "Anotarse",
	Main_Hardcore = "Hardcore",
	Main_Ironman = "Ironman",
	Main_Bloodthirsty = "Sanguinario",
	Confirm_Permadeath = "Toda muerte es permanente y eliminará a tu personaje",
	Confirm_Equipment = "Sólo puedes usar equipo |CFF9D9D9DPobre|CFFCD0000 y |CFFFFFFFFComún|CFFCD0000",
	Confirm_Talents = "No puedes usar talentos",
	Confirm_XP = "Sólo puedes ganar experiencia derrotando enemigos",
	Confirm_Party = "Sólo puedes hacer grupo con otros en los mismos desafíos",
	Confirm_Trade = "Sólo puedes comerciar con otros en los mismos desafíos",
	Confirm_Mail = "No puedes recibir oro o ítems a través del correo",
	Confirm_AH = "No puedes usar la Casa de Subastas",
	Confirm_GB = "No puedes usar el Banco de la Hermandad",
	Confirm_Disable = "No se puede desactivar",
	Confirm_HallOfFame = "Únete al Salón de la Fama",
	Confirm_Rewards = "Recibe recompensas uúnicas al nivel máximo",
	Confirm_PermaDeathMaxLvl = "Morir ya no es permanente al nivel máximo",
	Confirm_Combo = "Puedes anotarte en múltiples desafíos al mismo tiempo",
	Confirm_Cancel = "Cancelar",
	HoF_Title = "En memoria a los mas valientes aventureros",
	HoF_Completed = "Completado",
	HoF_Dead = "Fallado",
	HoF_Active = "Activo",
	HoF_MyChars = "Mis Personajes",
	HoF_Solo = "Solo",
	HoF_Classes = "{1} clases mostradas",
	HoF_Name = "Nombre",
	HoF_Level = "Nivel",
	HoF_Rank = "Ranking",
	SelectAll = "Seleccionar Todo",
	SelectNone = "Seleccionar Ninguno",
	Death_Title = "HAS MUERTO",
	Completed_Title = "¡FELICITACIONES!",
	Completed_Text = "{1} enfrentó muchos desafios,\npero los superó con\ndeterminación y voluntad pura\n\nHa jugado {2}\n\n{3} rango: #{4}",
	Death_Logout = "Salir",
	Death_Text = "La aventura de {1} ha terminado aquí\n\nMurió al nivel {2}\nHa jugado {3}\n\n{4} rango: #{5}",
	Splash_Text = "Anotado para el Desafío {1}!",
	Err_ChallengeActive = "Ya te has anotado para ese desafío.",
	Err_Exp = "Sólo disponible para personajes nivel 1 sin puntos de experiencia.\nCrea un personaje fresco para iniciar el desafío.",
	Err_Items = "Posees ítems no incluidos en tu equipamiento inicial.\nDeshaste de ellos o crea un personaje fresco para iniciar el desafío.",
	Err_Money = "Tienes oro en tu inventario.\nDeshaste de el o crea un personaje fresco para iniciar el desafío.",
	Err_Mail = "Tienes correo pendiente.\nCrea un personaje fresco para iniciar el desafío.",
	Err_Deaths = "Este personaje ya ha muerto antes...\nCrea un personaje fresco para iniciar el desafío.",
	Err_Range = "Estás muy lejos."
}
locales["esMX"] = locales["esES"]
local locale = GetLocale()
if locales[locale] == nil then
	locale = "enUS"
end

local function L(key, ...)
	local str = locales[locale][key] or locales["enUS"][key] or ""

	local args = {...}
	for i = 1, #args do
		str = str:gsub("{" .. i .. "}", args[i])
	end

	return str
end

local function TestTexture(textureName)
	challengeModes.textureTestFrame = CreateFrame("Frame", "ChallengeModesTextureTestFrame", UIParent)
	challengeModes.textureTestFrame:SetSize(64, 64)
	challengeModes.textureTestFrame:SetPoint("CENTER")
	challengeModes.textureTestFrame:Hide()

	challengeModes.textureTestFrame.texture = challengeModes.textureTestFrame:CreateTexture()
	local ret = challengeModes.textureTestFrame.texture:SetTexture(textureName)
	challengeModes.textureTestFrame = nil

	return ret == 1
end

local function IsPatchInstalled()
	return TestTexture("Interface/ChallengeModes/ChallengeModes")
end

local function CheckAddonVersion(version)
	version = gsub(version, "%.", "_")
	return TestTexture("Interface/ChallengeModes/ChallengeModesVersion" .. version)
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

local function FormatChallengesArray(challenges, maxLen)
	local str = ""
	local linebreak = false
	for i = 1, #challenges do
		if maxLen ~= nil and not linebreak and string.len(str) >= maxLen then
			str = str .. "\n"
			linebreak = true
		end

		str = str .. L("Main_" .. challenges[i])
		if i ~= #challenges then
			str = str .. " + "
		end
	end
	return str
end

local function SetTooltip(frame, text, frameOwner)
	frame:SetScript("OnEnter", function()
		if frameOwner ~= nil then
			GameTooltip:SetOwner(frameOwner, "ANCHOR_TOP")
		else
			GameTooltip:SetOwner(frame, "ANCHOR_TOP")
		end
		GameTooltip:SetText(text)
		GameTooltip:Show()
	end)

	frame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
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
	scrollTitle:SetFont("Fonts/FRIZQT__.TTF", 14)
	scrollTitle:SetText("|C" .. titleColor .. title .. "|r")

	local scrollText = challengeModes.mainWindow:CreateFontString()
	scrollText:SetSize(200 * scaleX, 300 * scaleY)
	scrollText:SetPoint("CENTER", x, -78)
	scrollText:SetFont("Fonts/FRIZQT__.TTF", 12)
	scrollText:SetText("|C" .. textColor .. text .. "|r")

	local btn = CreateFrame("Button", nil, challengeModes.mainWindow, "UIPanelButtonTemplate")
	btn:SetSize(120, 40)
	btn:SetPoint("CENTER", x, -190)
	btn:EnableMouse(true)
	local btnText = btn:CreateFontString()
	btnText:SetFont("Fonts/MORPHEUS.TTF", 18, "OUTLINE")
	btnText:SetShadowOffset(1, -1)
	btn:SetFontString(btnText)
	btn:SetText(L("Main_Enlist"))

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
challengeModes.mainWindow.scroll1Button = CreateMainWindowScroll(-214, L("Main_ChallengeName", L("Main_Hardcore")), L("Main_Desc1"), scrollImg1, scrollBtnTextures)
challengeModes.mainWindow.scroll2Button = CreateMainWindowScroll(0, L("Main_ChallengeName", L("Main_Ironman")), L("Main_Desc2"), scrollImg2, scrollBtnTextures)
challengeModes.mainWindow.scroll3Button = CreateMainWindowScroll(214, L("Main_ChallengeName", L("Main_Bloodthirsty")), L("Main_Desc3"), scrollImg3, scrollBtnTextures)

-- Title
CreateTexture(512 * scaleX, 85 * scaleY, atlas.TitleMiddle, "BORDER", "TOP", 0, -34)
CreateTexture(202 * scaleX, 85 * scaleY, atlas.TitleLeft, "ARTWORK", "TOPLEFT", 45, -34)
CreateTexture(202 * scaleX, 85 * scaleY, atlas.TitleRight, "ARTWORK", "TOPRIGHT", -45, -34)

challengeModes.mainWindow.titleText = challengeModes.mainWindow:CreateFontString()
challengeModes.mainWindow.titleText:SetPoint("TOP", 0, -60)
challengeModes.mainWindow.titleText:SetFont("Fonts/FRIZQT__.TTF", 16, "OUTLINE")
challengeModes.mainWindow.titleText:SetText(L("Main_Title"))

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
challengeModes.confirmWindow.width = 560
if locale == "deDE" then
	challengeModes.confirmWindow.width = 780
elseif locale == "frFR" then
	challengeModes.confirmWindow.width = 690
end
challengeModes.confirmWindow:SetSize(challengeModes.confirmWindow.width * scaleX, 438 * scaleY)
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

CreateTexture(challengeModes.confirmWindow.width * scaleX, 438 * scaleY, atlas.WideScroll, "BACKGROUND", "CENTER", 0, 0, nil, challengeModes.confirmWindow)

challengeModes.confirmWindow.closeButton = CreateFrame("Button", nil, challengeModes.confirmWindow, "UIPanelCloseButton")
challengeModes.confirmWindow.closeButton:SetPoint("TOPRIGHT", -4, -4)
challengeModes.confirmWindow.closeButton:EnableMouse(true)
challengeModes.confirmWindow.closeButton:SetSize(32, 32)

challengeModes.confirmWindow.title = challengeModes.confirmWindow:CreateFontString()
challengeModes.confirmWindow.title:SetPoint("TOP", 0, -30)
challengeModes.confirmWindow.title:SetFont("Fonts/FRIZQT__.TTF", 20)

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
local function CreateConfirmXLine(text, parent, linebreak)
	local y = confirmLinesY
	if linebreak == true then
		y = y - 6
	end

	CreateTexture(nil, nil, { 0, 1, 0, 1 }, "ARTWORK", "LEFT", 30, y, "Interface/GLUES/LOGIN/Glues-CheckBox-Check", parent)

	local txt = parent:CreateFontString()
	txt:SetPoint("LEFT", 54, y + 1)
	txt:SetFont("Fonts/FRIZQT__.TTF", 13)
	txt:SetText("|CFFCD0000" .. text .. "|r")
	txt:SetJustifyH("LEFT")
	txt:SetShadowOffset(1, -1)

	local gap = confirmLinesGap
	if linebreak == true then
		gap = gap + 14
	end

	confirmLinesY = confirmLinesY - gap
end

local function CreateConfirmOKLine(text, parent)
	CreateTexture(nil, nil, { 0, 1, 0, 1 }, "ARTWORK", "LEFT", 27, confirmLinesY - 4, "Interface/AchievementFrame/UI-Achievement-Criteria-Check", parent)

	local txt = parent:CreateFontString()
	txt:SetPoint("LEFT", 54, confirmLinesY)
	txt:SetFont("Fonts/FRIZQT__.TTF", 13)
	txt:SetText("|CFF097000" .. text .. "|r")
	txt:SetShadowOffset(1, -1)

	confirmLinesY = confirmLinesY - confirmLinesGap
end

challengeModes.confirmWindow.enlistButton = CreateFrame("Button", nil, challengeModes.confirmWindow, "UIPanelButtonTemplate")
challengeModes.confirmWindow.enlistButton:SetSize(160, 40)
challengeModes.confirmWindow.enlistButton:SetPoint("CENTER", -85, -146)
challengeModes.confirmWindow.enlistButton:EnableMouse(true)
challengeModes.confirmWindow.enlistButtonText = challengeModes.confirmWindow.enlistButton:CreateFontString()
challengeModes.confirmWindow.enlistButtonText:SetFont("Fonts/MORPHEUS.TTF", 18, "OUTLINE")
challengeModes.confirmWindow.enlistButtonText:SetShadowOffset(1, -1)
challengeModes.confirmWindow.enlistButton:SetFontString(challengeModes.confirmWindow.enlistButtonText)
challengeModes.confirmWindow.enlistButton:SetText(L("Main_Enlist"))
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
challengeModes.confirmWindow.cancelButtonText:SetFont("Fonts/MORPHEUS.TTF", 18, "OUTLINE")
challengeModes.confirmWindow.cancelButtonText:SetShadowOffset(1, -1)
challengeModes.confirmWindow.cancelButton:SetFontString(challengeModes.confirmWindow.cancelButtonText)
challengeModes.confirmWindow.cancelButton:SetText(L("Confirm_Cancel"))
challengeModes.confirmWindow.cancelButton:SetScript("OnClick", function()
	challengeModes.confirmWindow:Hide()
end)


for _, btn in pairs({ challengeModes.mainWindow.scroll1Button, challengeModes.mainWindow.scroll2Button, challengeModes.mainWindow.scroll3Button }) do
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
	confirmLinesY = 120
	confirmLinesGap = 20
	if challengeName == "Hardcore" then
		CreateConfirmXLine(L("Confirm_Permadeath"), confirmLineFrame)
	end
	if challengeName == "Ironman" then
		CreateConfirmXLine(L("Confirm_Equipment"), confirmLineFrame)
		CreateConfirmXLine(L("Confirm_Talents"), confirmLineFrame)
	elseif challengeName == "Bloodthirsty" then
		CreateConfirmXLine(L("Confirm_XP"), confirmLineFrame)
	end
	CreateConfirmXLine(L("Confirm_Party"), confirmLineFrame)
	CreateConfirmXLine(L("Confirm_Trade"), confirmLineFrame)
	CreateConfirmXLine(L("Confirm_Mail"), confirmLineFrame, true)
	CreateConfirmXLine(L("Confirm_AH"), confirmLineFrame)
	CreateConfirmXLine(L("Confirm_GB"), confirmLineFrame)
	CreateConfirmXLine(L("Confirm_Disable"), confirmLineFrame)

	confirmLinesY = confirmLinesY - 10
	CreateConfirmOKLine(L("Confirm_HallOfFame"), confirmLineFrame)
	CreateConfirmOKLine(L("Confirm_Rewards"), confirmLineFrame)
	if challengeName == "Hardcore" then
		CreateConfirmOKLine(L("Confirm_PermaDeathMaxLvl"), confirmLineFrame)
	end
	CreateConfirmOKLine(L("Confirm_Combo"), confirmLineFrame)

	btn:SetScript("OnClick", function()
		challengeModes.selectedChallenge = challengeId

		-- Set the title
		challengeModes.confirmWindow.title:SetText("|C" .. titleColor .. L("Main_ChallengeName", L("Main_" .. challengeName)) .. "|r")

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
challengeModes.deathWindow:SetSize(512 * scaleX, 512 * scaleY)
challengeModes.deathWindow:EnableMouse(true)
challengeModes.deathWindow:SetPoint("CENTER", 0, 0)
challengeModes.deathWindow:Hide()

CreateTexture(512 * scaleX, 512 * scaleY, { 0.0, 1.0, 0.0, 1.0 }, "BACKGROUND", "CENTER", 0, 0, "Interface/ChallengeModes/DeathWindowBackground", challengeModes.deathWindow)
CreateTexture(512 * scaleX, 512 * scaleY, { 0.0, 1.0, 0.0, 1.0 }, "BORDER", "CENTER", 0, 0, "Interface/ChallengeModes/DeathWindowBorder", challengeModes.deathWindow)
CreateTexture(187 * scaleX, 187 * scaleY, { 0.0, 1.0, 0.0, 1.0 }, "ARTWORK", "TOP", 0, -80, "Interface/ChallengeModes/Graveyard" .. random(1, 17), challengeModes.deathWindow)
CreateTexture(207 * scaleX, 207 * scaleY, { 0.0, 0.80859375, 0.0, 0.80859375 }, "OVERLAY", "TOP", 0, -80 + 9 * scaleY, "Interface/ChallengeModes/SquareBorder", challengeModes.deathWindow)

challengeModes.deathWindow.title = challengeModes.deathWindow:CreateFontString()
challengeModes.deathWindow.title:SetPoint("TOP", 0, -32)
challengeModes.deathWindow.title:SetFont("Fonts/MORPHEUS.TTF", 22)
challengeModes.deathWindow.title:SetText(L("Death_Title"))

challengeModes.deathWindow.text = challengeModes.deathWindow:CreateFontString()
challengeModes.deathWindow.text:SetPoint("CENTER", 0, -88)
challengeModes.deathWindow.text:SetFont("Fonts/FRIZQT__.TTF", 16)

challengeModes.deathWindow.button = CreateFrame("Button", nil, challengeModes.deathWindow, "UIPanelButtonTemplate")
challengeModes.deathWindow.button:SetSize(140, 40)
challengeModes.deathWindow.button:SetPoint("BOTTOM", 0, 24)
challengeModes.deathWindow.button:EnableMouse(true)
challengeModes.deathWindow.buttonText = challengeModes.deathWindow.button:CreateFontString()
challengeModes.deathWindow.buttonText:SetFont("Fonts/MORPHEUS.TTF", 18, "OUTLINE")
challengeModes.deathWindow.buttonText:SetShadowOffset(1, -1)
challengeModes.deathWindow.button:SetFontString(challengeModes.deathWindow.buttonText)
challengeModes.deathWindow.button:SetText(L("Death_Logout"))
challengeModes.deathWindow.button:SetScript("OnClick", function()
	RepopMe()
	challengeModes.deathWindow:Hide()
end)


-- Hall of Fame window
challengeModes.hofWindow = CreateFrame("Frame", "ChallengeModesHallOfFameWindow", UIParent)
challengeModes.hofWindow:SetSize(715, 530)
challengeModes.hofWindow:EnableMouse(true)
challengeModes.hofWindow:SetPoint("CENTER", 0, 0)
challengeModes.hofWindow:Hide()

challengeModes.hofWindow.nbRows = 250
challengeModes.hofWindow.rowHeight = 24
challengeModes.hofWindow.dbOffset = 0
challengeModes.hofWindow.dbLimit = challengeModes.hofWindow.nbRows
challengeModes.hofWindow.playerRows = {}

_G["ChallengeModes.mainWindow"] = challengeModes.hofWindow -- https://wowpedia.fandom.com/wiki/Make_frames_closable_with_the_Escape_key
tinsert(UISpecialFrames, challengeModes.hofWindow:GetName())

challengeModes.hofWindow:SetScript("OnShow", function()
	PlaySound("GAMEDIALOGOPEN")
end)
challengeModes.hofWindow:SetScript("OnHide", function()
	PlaySound("GAMEDIALOGCLOSE")
end)

-- Background
for x = 0, 3 do
	for y = 0, 2 do
		CreateTexture(174, 171, { 0, 1, 0, 1 }, "BACKGROUND", "TOPLEFT", x * 174 + 8, -y * 171 - 8, "Interface/ChallengeModes/UIFrameNeutralBackground", challengeModes.hofWindow)
	end
end

-- Borders
CreateTexture(700 * scaleX, 30 * scaleY, neutralAtlas.TopBorder, "BORDER", "TOP", 0, 0, "Interface/ChallengeModes/UIFrameNeutral", challengeModes.hofWindow)
CreateTexture(700 * scaleX, 30 * scaleY, neutralAtlas.BottomBorder, "BORDER", "BOTTOM", 0, 0, "Interface/ChallengeModes/UIFrameNeutral", challengeModes.hofWindow)
CreateTexture(30 * scaleX, 400 * scaleY, neutralAtlas.LeftBorder, "BORDER", "LEFT", 0, 0, "Interface/ChallengeModes/UIFrameNeutralVertical", challengeModes.hofWindow)
CreateTexture(30 * scaleX, 400 * scaleY, neutralAtlas.RightBorder, "BORDER", "RIGHT", 0, 0, "Interface/ChallengeModes/UIFrameNeutralVertical", challengeModes.hofWindow)

-- Corners
CreateTexture(166 * scaleX, 166 * scaleY, neutralAtlas.TopLeftCorner, "ARTWORK", "TOPLEFT", 0, 0, "Interface/ChallengeModes/UIFrameNeutral", challengeModes.hofWindow)
CreateTexture(166 * scaleX, 166 * scaleY, neutralAtlas.BottomLeftCorner, "ARTWORK", "BOTTOMLEFT", 0, 0, "Interface/ChallengeModes/UIFrameNeutral", challengeModes.hofWindow)
CreateTexture(166 * scaleX, 166 * scaleY, neutralAtlas.TopRightCorner, "ARTWORK", "TOPRIGHT", 0, 0, "Interface/ChallengeModes/UIFrameNeutral", challengeModes.hofWindow)
CreateTexture(166 * scaleX, 166 * scaleY, neutralAtlas.BottomRightCorner, "ARTWORK", "BOTTOMRIGHT", 0, 0, "Interface/ChallengeModes/UIFrameNeutral", challengeModes.hofWindow)

-- Title
CreateTexture(512 * scaleX, 85 * scaleY, neutralAtlas.TitleMiddle, "BORDER", "TOP", 0, -34, "Interface/ChallengeModes/UIFrameNeutral", challengeModes.hofWindow)
CreateTexture(202 * scaleX, 85 * scaleY, neutralAtlas.TitleLeft, "ARTWORK", "TOPLEFT", 45, -34, "Interface/ChallengeModes/UIFrameNeutral", challengeModes.hofWindow)
CreateTexture(202 * scaleX, 85 * scaleY, neutralAtlas.TitleRight, "ARTWORK", "TOPRIGHT", -45, -34, "Interface/ChallengeModes/UIFrameNeutral", challengeModes.hofWindow)

challengeModes.hofWindow.titleText = challengeModes.hofWindow:CreateFontString()
challengeModes.hofWindow.titleText:SetPoint("TOP", 0, -60)
challengeModes.hofWindow.titleText:SetFont("Fonts/FRIZQT__.TTF", 16, "OUTLINE")
challengeModes.hofWindow.titleText:SetText(L("HoF_Title"))

-- Scroll
CreateTexture(515 * scaleX, 438 * scaleY, neutralAtlas.WideScroll, "ARTWORK", "CENTER", 0, -38, "Interface/ChallengeModes/UIFrameNeutral", challengeModes.hofWindow)

-- Checkboxes
local function CreateCheckbox(name, parent, anchor, x, y, text, checked, icon)
	local cb = CreateFrame("CheckButton", name, parent, "ChatConfigCheckButtonTemplate")
	local txt = getglobal(cb:GetName() .. "Text")
	txt:SetText(text)
	cb:SetPoint(anchor, x, y)
	cb:SetHitRectInsets(0, -txt:GetStringWidth(), 0, 0)
	cb:SetChecked(checked == true)

	if icon ~= nil then
		local img = cb:CreateTexture()
		img:SetSize(20, 20)
		img:SetPoint("LEFT", cb, "RIGHT", txt:GetStringWidth() - 4, 2)
		img:SetTexture(icon)
	end

	cb:SetScript("OnClick", function()
		challengeModes.hofWindow.dbOffset = 0
		RequestHoFData()
	end)

	return cb
end
challengeModes.hofWindow.cbHardcore = CreateCheckbox("ChallengeModesHoFCbHardcore", challengeModes.hofWindow, "TOP", -145, -140, "Hardcore", true)
challengeModes.hofWindow.cbIronman = CreateCheckbox("ChallengeModesHoFCbIronman", challengeModes.hofWindow, "TOP", -32, -140, "Ironman")
challengeModes.hofWindow.cbBloodthirsty = CreateCheckbox("ChallengeModesHoFCbBloodthirsty", challengeModes.hofWindow, "TOP", 75, -140, "Bloodthirsty")

challengeModes.hofWindow.cbCompleted = CreateCheckbox("ChallengeModesHoFCbCompleted", challengeModes.hofWindow, "TOP", -145, -160, L("HoF_Completed"), true, "Interface/ChallengeModes/HoFCompleted")
challengeModes.hofWindow.cbFailed = CreateCheckbox("ChallengeModesHoFCbFailed", challengeModes.hofWindow, "TOP", -11, -160, L("HoF_Dead"), true, "Interface/ChallengeModes/HoFDead")
challengeModes.hofWindow.cbActive = CreateCheckbox("ChallengeModesHoFCbActive", challengeModes.hofWindow, "TOP", 94, -160, L("HoF_Active"), true, "Interface/ChallengeModes/HoFActive")

challengeModes.hofWindow.cbMyChars = CreateCheckbox("ChallengeModesHoFCbMyChars", challengeModes.hofWindow, "TOP", -145, -184, L("HoF_MyChars"))
challengeModes.hofWindow.cbSolo = CreateCheckbox("ChallengeModesHoFCbSolo", challengeModes.hofWindow, "TOP", -20, -184, L("HoF_Solo"))

challengeModes.hofWindow.classes = {}
for _, classId in pairs({ 1, 2, 3, 4, 5, 7, 8, 9, 11 }) do
	challengeModes.hofWindow.classes[classId] = true
end
local classIconCoords = {}
classIconCoords["WARRIOR"] = { 0.0, 0.25, 0.0, 0.25 }
classIconCoords["PALADIN"] = { 0.0, 0.25, 0.5, 0.75 }
classIconCoords["HUNTER"] = { 0.0, 0.25, 0.25, 0.5 }
classIconCoords["ROGUE"] = { 0.5, 0.75, 0.0, 0.25 }
classIconCoords["PRIEST"] = { 0.5, 0.75, 0.25, 0.5 }
classIconCoords["SHAMAN"] = { 0.25, 0.5, 0.25, 0.5 }
classIconCoords["MAGE"] = { 0.25, 0.5, 0.0, 0.25 }
classIconCoords["WARLOCK"] = { 0.75, 1.0, 0.25, 0.5 }
classIconCoords["DRUID"] = { 0.75, 1.0, 0.0, 0.25 }
local function ClassDropDown_Menu(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	info.func = frame.SetValue
	info.keepShownOnClick = false

	info.arg1 = -1
	info.text = L("SelectAll")
	info.notCheckable = true
	UIDropDownMenu_AddButton(info)
	info.arg1 = -2
	info.text = L("SelectNone")
	info.notCheckable = true
	UIDropDownMenu_AddButton(info)

	info.keepShownOnClick = true
	info.notCheckable = false
	info.icon = "Interface/GLUES/CHARACTERCREATE/UI-CHARACTERCREATE-CLASSES"
	for key, checked in pairs(challengeModes.hofWindow.classes) do
		local className = classNames[key]
		info.arg1 = key
		info.checked = checked
		info.text = LOCALIZED_CLASS_NAMES_MALE[className]
		info.colorCode = string.format("|cff%2x%2x%2x", 255 * RAID_CLASS_COLORS[className]["r"], 255 * RAID_CLASS_COLORS[className]["g"], 255 * RAID_CLASS_COLORS[className]["b"])
		info.tCoordLeft, info.tCoordRight, info.tCoordTop, info.tCoordBottom = unpack(classIconCoords[className])
		local iconMargin = 0.02
		info.tCoordLeft, info.tCoordRight, info.tCoordTop, info.tCoordBottom = info.tCoordLeft + iconMargin, info.tCoordRight - iconMargin, info.tCoordTop + iconMargin, info.tCoordBottom - iconMargin
		UIDropDownMenu_AddButton(info)
	end
end
challengeModes.hofWindow.dropdownClass = CreateFrame("Frame", "ChallengeModesHoFClasses", challengeModes.hofWindow, "UIDropDownMenuTemplate")
challengeModes.hofWindow.dropdownClass:SetPoint("TOP", 94, -182)
function challengeModes.hofWindow.dropdownClass:SetValue(val)
	if val == -1 then
		for key, _ in pairs(challengeModes.hofWindow.classes) do
			challengeModes.hofWindow.classes[key] = true
		end
		ToggleDropDownMenu(nil, nil, challengeModes.hofWindow.dropdownClass)
	elseif val == -2 then
		for key, _ in pairs(challengeModes.hofWindow.classes) do
			challengeModes.hofWindow.classes[key] = false
		end
		ToggleDropDownMenu(nil, nil, challengeModes.hofWindow.dropdownClass)
	else
		challengeModes.hofWindow.classes[val] = not challengeModes.hofWindow.classes[val]
	end

	RequestHoFData()
	challengeModes.hofWindow.dropdownClass:UpdateText()
end
function challengeModes.hofWindow.dropdownClass:UpdateText()
	local count = 0
	for key, checked in pairs(challengeModes.hofWindow.classes) do
		if checked then
			count = count + 1
		end
	end
	UIDropDownMenu_SetText(challengeModes.hofWindow.dropdownClass, L("HoF_Classes", count))
end
UIDropDownMenu_SetWidth(challengeModes.hofWindow.dropdownClass, 120)
UIDropDownMenu_Initialize(challengeModes.hofWindow.dropdownClass, ClassDropDown_Menu)
challengeModes.hofWindow.dropdownClass:UpdateText()

-- Scrollframe
challengeModes.hofWindow.scrollParent = CreateFrame("Frame", nil, challengeModes.hofWindow)
challengeModes.hofWindow.scrollParent:SetSize(370 * scaleX, 300 * scaleY)
challengeModes.hofWindow.scrollParent:SetPoint("TOP", 0, -214)
challengeModes.hofWindow.scrollParent:SetBackdrop({
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	tile = true,
	tileSize = 8,
	edgeSize = 8,
	insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
challengeModes.hofWindow.scrollParent:SetBackdropColor(0.0, 0.0, 0.0, 1.0)
challengeModes.hofWindow.scrollParent:SetBackdropBorderColor(0.5, 0.5, 0.5)

local columnsX = 25 * scaleX - 10 + 4
challengeModes.hofWindow.scrollColumn1 = challengeModes.hofWindow.scrollParent:CreateFontString()
challengeModes.hofWindow.scrollColumn1:SetPoint("TOPLEFT", columnsX, -4)
challengeModes.hofWindow.scrollColumn1:SetWidth(100)
challengeModes.hofWindow.scrollColumn1:SetJustifyH("CENTER")
challengeModes.hofWindow.scrollColumn1:SetFont("Fonts/FRIZQT__.TTF", 13)
challengeModes.hofWindow.scrollColumn1:SetText(L("HoF_Name"))
columnsX = columnsX + challengeModes.hofWindow.scrollColumn1:GetWidth()

challengeModes.hofWindow.scrollColumn2 = challengeModes.hofWindow.scrollParent:CreateFontString()
challengeModes.hofWindow.scrollColumn2:SetPoint("TOPLEFT", columnsX, -4)
challengeModes.hofWindow.scrollColumn2:SetWidth(40)
challengeModes.hofWindow.scrollColumn2:SetJustifyH("CENTER")
challengeModes.hofWindow.scrollColumn2:SetFont("Fonts/FRIZQT__.TTF", 13)
challengeModes.hofWindow.scrollColumn2:SetText(L("HoF_Level"))
columnsX = columnsX + challengeModes.hofWindow.scrollColumn2:GetWidth()

challengeModes.hofWindow.scrollColumn3 = challengeModes.hofWindow.scrollParent:CreateFontString()
challengeModes.hofWindow.scrollColumn3:SetPoint("TOPLEFT", columnsX, -4)
challengeModes.hofWindow.scrollColumn3:SetWidth(70)
challengeModes.hofWindow.scrollColumn3:SetJustifyH("CENTER")
challengeModes.hofWindow.scrollColumn3:SetFont("Fonts/FRIZQT__.TTF", 13)
challengeModes.hofWindow.scrollColumn3:SetText(L("HoF_Rank"))
columnsX = columnsX + challengeModes.hofWindow.scrollColumn2:GetWidth()

challengeModes.hofWindow.scroll = CreateFrame("ScrollFrame", "ChallengeModesHoFScrollFrame", challengeModes.hofWindow.scrollParent, "UIPanelScrollFrameTemplate")
local scrollName = challengeModes.hofWindow.scroll:GetName()
challengeModes.hofWindow.scrollbar = _G[scrollName .. "ScrollBar"]
challengeModes.hofWindow.scrollupbutton = _G[scrollName .. "ScrollBarScrollUpButton"]
challengeModes.hofWindow.scrolldownbutton = _G[scrollName .. "ScrollBarScrollDownButton"]
challengeModes.hofWindow.scroll:SetSize(challengeModes.hofWindow.scrollParent:GetWidth() - 50 * scaleX, challengeModes.hofWindow.scrollParent:GetHeight() - 36 * scaleY)
challengeModes.hofWindow.scroll:SetPoint("TOPLEFT", 10, -24)

challengeModes.hofWindow.container = CreateFrame("Frame", "ChallengeModesHoFPlayers", challengeModes.hofWindow.scroll)
challengeModes.hofWindow.container:SetWidth(challengeModes.hofWindow.scroll:GetWidth())
challengeModes.hofWindow.container:SetHeight(0)
challengeModes.hofWindow.container:SetPoint("TOP")
challengeModes.hofWindow.scroll:SetScrollChild(challengeModes.hofWindow.container)

-- Loading spinner
local function CreateLoadingSpinner()
	local spinner = CreateFrame("Frame", "ChallengeModesLoadingSpinner", challengeModes.hofWindow.scrollParent)
	spinner:Hide()
	spinner:SetPoint("CENTER")
	spinner:SetSize(64, 64)
	spinner:SetAlpha(0.6)

	local background = spinner:CreateTexture()
	background:SetPoint("CENTER")
	background:SetAllPoints()
	background:SetTexture("Interface/ChallengeModes/StreamFrame")
	
	local inner = CreateFrame("Frame", "ChallengeModesLoadingSpinnerInner", spinner)
	inner:SetPoint("CENTER")
	inner:SetSize(62, 62)

	local circle = inner:CreateTexture()
	circle:SetAllPoints()
	circle:SetTexture("Interface/ChallengeModes/StreamCircle")
	circle:SetGradient("VERTICAL", 0.7764705882352941, 0.8431372549019608, 0.8431372549019608, 0.1568627450980392, 0.1294117647058824, 1)

	local spark = inner:CreateTexture()
	spark:SetAllPoints()
	spark:SetTexture("Interface/ChallengeModes/StreamSpark")

	local animGroup = inner:CreateAnimationGroup()
	animGroup:SetLooping("REPEAT")
	local anim = animGroup:CreateAnimation("Rotation")
	anim:SetDuration(2)
	anim:SetDegrees(-360)
	animGroup:Play()

	challengeModes.hofWindow.loadingSpinner = spinner
end
CreateLoadingSpinner()

-- Page buttons
challengeModes.hofWindow.btnPrev = CreateFrame("Button", nil, challengeModes.hofWindow.scrollParent)
challengeModes.hofWindow.btnPrev:SetNormalTexture("Interface/Buttons/UI-SpellbookIcon-PrevPage-Up")
challengeModes.hofWindow.btnPrev:SetPushedTexture("Interface/Buttons/UI-SpellbookIcon-PrevPage-Down")
challengeModes.hofWindow.btnPrev:SetDisabledTexture("Interface/Buttons/UI-SpellbookIcon-PrevPage-Disabled")
challengeModes.hofWindow.btnPrev:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight")
challengeModes.hofWindow.btnPrev:SetSize(32, 32)
challengeModes.hofWindow.btnPrev:SetPoint("LEFT", -50 * scaleX, 0)
challengeModes.hofWindow.btnPrev:Disable()

challengeModes.hofWindow.btnNext = CreateFrame("Button", nil, challengeModes.hofWindow.scrollParent)
challengeModes.hofWindow.btnNext:SetNormalTexture("Interface/Buttons/UI-SpellbookIcon-NextPage-Up")
challengeModes.hofWindow.btnNext:SetPushedTexture("Interface/Buttons/UI-SpellbookIcon-NextPage-Down")
challengeModes.hofWindow.btnNext:SetDisabledTexture("Interface/Buttons/UI-SpellbookIcon-NextPage-Disabled")
challengeModes.hofWindow.btnNext:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight")
challengeModes.hofWindow.btnNext:SetSize(32, 32)
challengeModes.hofWindow.btnNext:SetPoint("RIGHT", 50 * scaleX, 0)
challengeModes.hofWindow.btnNext:Disable()

local scrollY = 0
local function CreateHoFRow()
	local row = CreateFrame("Button", nil, challengeModes.hofWindow.container)
	row:SetPoint("TOP", 0, -scrollY)
	row:SetSize(challengeModes.hofWindow.container:GetWidth(), challengeModes.hofWindow.rowHeight)
	row:SetHighlightTexture("Interface/FriendsFrame/UI-FriendsFrame-HighlightBar", "ADD")

	row.highlight = row:CreateTexture()
	row.highlight:SetSize(row:GetSize())
	row.highlight:SetPoint("CENTER", 0, 0)
	row.highlight:SetTexture("Interface/ChallengeModes/FrameHighlightBlue")
	row.highlight:SetAlpha(1.0)
	row.highlight:SetBlendMode("ADD")
	row.highlight:SetDrawLayer("OVERLAY")
	row.highlight:Hide()

	local x = 4

	row.txtName = row:CreateFontString()
	row.txtName:SetPoint("TOPLEFT", x, 0)
	row.txtName:SetFont("Fonts/FRIZQT__.TTF", 12)
	row.txtName:SetWidth(challengeModes.hofWindow.scrollColumn1:GetWidth())
	row.txtName:SetHeight(challengeModes.hofWindow.rowHeight)
	row.txtName:SetJustifyH("CENTER")
	x = x + row.txtName:GetWidth()

	row.txtLevel = row:CreateFontString()
	row.txtLevel:SetPoint("TOPLEFT", x, 0)
	row.txtLevel:SetFont("Fonts/FRIZQT__.TTF", 12)
	row.txtLevel:SetWidth(challengeModes.hofWindow.scrollColumn2:GetWidth())
	row.txtLevel:SetHeight(challengeModes.hofWindow.rowHeight)
	row.txtLevel:SetJustifyH("CENTER")
	row.txtLevel:SetTextColor(1, 1, 1, 1)
	x = x + row.txtLevel:GetWidth()

	row.txtRank = row:CreateFontString()
	row.txtRank:SetPoint("TOPLEFT", x, 0)
	row.txtRank:SetFont("Fonts/FRIZQT__.TTF", 12)
	row.txtRank:SetWidth(challengeModes.hofWindow.scrollColumn3:GetWidth())
	row.txtRank:SetHeight(challengeModes.hofWindow.rowHeight)
	row.txtRank:SetJustifyH("CENTER")
	row.txtRank:SetTextColor(1, 1, 1, 1)
	x = x + row.txtRank:GetWidth()

	row.imgState = row:CreateTexture()
	row.imgState:SetSize(challengeModes.hofWindow.rowHeight, challengeModes.hofWindow.rowHeight)
	row.imgState:SetPoint("TOPLEFT", x, 0)
	x = x + row.imgState:GetWidth()

	scrollY = scrollY + challengeModes.hofWindow.rowHeight
	row:Hide()
	return row
end
for i = 0, challengeModes.hofWindow.nbRows do
	challengeModes.hofWindow.playerRows[i] = CreateHoFRow()
end

local function ClearHoF()
	challengeModes.hofWindow.container:SetHeight(0)
	challengeModes.hofWindow.btnPrev:Disable()
	challengeModes.hofWindow.btnNext:Disable()

	for i = 0, challengeModes.hofWindow.nbRows do
		challengeModes.hofWindow.playerRows[i]:Hide()
	end
end

-- Close button
CreateTexture(33, 32, neutralAtlas.CloseCorner, "OVERLAY", "TOPRIGHT", 0, 0, "Interface/ChallengeModes/UIFrameNeutral", challengeModes.hofWindow)
challengeModes.hofWindow.closeButton = CreateFrame("Button", nil, challengeModes.hofWindow, "UIPanelCloseButton")
challengeModes.hofWindow.closeButton:SetPoint("TOPRIGHT", 0, 0)
challengeModes.hofWindow.closeButton:EnableMouse(true)
challengeModes.hofWindow.closeButton:SetSize(32, 32)
challengeModes.hofWindow.closeButton:SetScript("OnClick", function()
	challengeModes.hofWindow:Hide()
end)


-- Completed window
challengeModes.completedWindow = CreateFrame("Frame", "ChallengeModesCompletedWindow", UIParent)
challengeModes.completedWindow:SetSize(400 * scaleX, 550 * scaleY)
challengeModes.completedWindow:EnableMouse(true)
challengeModes.completedWindow:SetPoint("CENTER", 0, 0)
challengeModes.completedWindow:Hide()

CreateTexture(400 * scaleX, 550 * scaleY, { 0.0, 0.78125, 0.0, 0.537109375 }, "BACKGROUND", "CENTER", 0, 0, "Interface/ChallengeModes/CompletedWindow", challengeModes.completedWindow)
CreateTexture(187 * scaleX, 187 * scaleY, { 0.0, 1.0, 0.0, 1.0 }, "ARTWORK", "TOP", 0, -90, "Interface/ChallengeModes/Completed_" .. select(2, UnitClass("player")) .. "_" .. tostring(UnitSex("player") - 2), challengeModes.completedWindow)
CreateTexture(207 * scaleX, 207 * scaleY, { 0.0, 0.80859375, 0.0, 0.80859375 }, "OVERLAY", "TOP", 0, -90 + 9 * scaleY, "Interface/ChallengeModes/SquareBorder", challengeModes.completedWindow)

challengeModes.completedWindow.title = challengeModes.completedWindow:CreateFontString()
challengeModes.completedWindow.title:SetPoint("TOP", 0, -32)
challengeModes.completedWindow.title:SetFont("Fonts/MORPHEUS.TTF", 22)
challengeModes.completedWindow.title:SetText(L("Completed_Title"))

challengeModes.completedWindow.text = challengeModes.completedWindow:CreateFontString()
challengeModes.completedWindow.text:SetPoint("CENTER", challengeModes.completedWindow, "BOTTOM", 0, 120)
challengeModes.completedWindow.text:SetFont("Fonts/FRIZQT__.TTF", 16)

challengeModes.completedWindow.closeButton = CreateFrame("Button", nil, challengeModes.completedWindow, "UIPanelCloseButton")
challengeModes.completedWindow.closeButton:SetPoint("TOPRIGHT", 0, 0)
challengeModes.completedWindow.closeButton:SetPoint("TOPRIGHT", -3, -4)
challengeModes.completedWindow.closeButton:EnableMouse(true)
challengeModes.completedWindow.closeButton:SetSize(28, 28)
challengeModes.completedWindow.closeButton:SetScript("OnClick", function()
	challengeModes.completedWindow:Hide()
end)

function RequestHoFData()
	local challenge = 0
	if challengeModes.hofWindow.cbHardcore:GetChecked() then challenge = challenge + 1 end
	if challengeModes.hofWindow.cbIronman:GetChecked() then challenge = challenge + 2 end
	if challengeModes.hofWindow.cbBloodthirsty:GetChecked() then challenge = challenge + 4 end
	local completed = challengeModes.hofWindow.cbCompleted:GetChecked()
	local failed = challengeModes.hofWindow.cbFailed:GetChecked()
	local active = challengeModes.hofWindow.cbActive:GetChecked()
	local myChars = challengeModes.hofWindow.cbMyChars:GetChecked()
	local solo = challengeModes.hofWindow.cbSolo:GetChecked()
	local classes = {}
	for key, checked in pairs(challengeModes.hofWindow.classes) do
		if checked then
			tinsert(classes, key)
		end
	end
	ClearHoF()
	challengeModes.hofWindow.loadingSpinner:Show()
	AIO.Handle(channelName, "hallOfFameData", challenge, completed, failed, active, myChars, solo, classes, challengeModes.hofWindow.dbOffset)
end

challengeModes.hofWindow.btnPrev:SetScript("OnClick", function()
	challengeModes.hofWindow.dbOffset = math.max(challengeModes.hofWindow.dbOffset - challengeModes.hofWindow.dbLimit, 0)
	RequestHoFData()
end)
challengeModes.hofWindow.btnNext:SetScript("OnClick", function()
	challengeModes.hofWindow.dbOffset = challengeModes.hofWindow.dbOffset + challengeModes.hofWindow.dbLimit
	RequestHoFData()
end)

function Handlers.CheckAddonVersion(player, addonVersion)
	if not IsPatchInstalled() then
		AIO.Handle(channelName, "notifyInstallAddon", false)
	elseif not CheckAddonVersion(addonVersion) then
		AIO.Handle(channelName, "notifyInstallAddon", true)
	end
end

function Handlers.OpenBannerUI(player, addonVersion, eligible)
	if not IsPatchInstalled() then
		AIO.Handle(channelName, "notifyInstallAddon", false)
		AIO.Handle(channelName, "closeBannerUI")
		return
	end
	if not CheckAddonVersion(addonVersion) then
		AIO.Handle(channelName, "notifyInstallAddon", true)
		AIO.Handle(channelName, "closeBannerUI")
		return
	end
	AIO.Handle(channelName, "openBannerUI")

	for i, btn in pairs(scrollButtons) do
		if eligible[i] ~= true then
			local errTxt = L("Err_" .. eligible[i])
			btn:Disable()
			btn:SetMotionScriptsWhileDisabled(true)

			SetTooltip(btn, errTxt)
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
	text:SetSize(380 * scaleX, 140 * scaleY)
	text:SetPoint("CENTER", 0, 0)
	text:SetFont("Fonts/FRIZQT__.TTF", 16)
	text:SetText(L("Splash_Text", L("Main_" .. challenge)))
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

function Handlers.OpenDeathUI(player, challenges, playedTime, rank)
	PlaySoundFile("Sound/Interface/PVPWARNING.wav")
	local timer = 1.65
	local challengesStr = FormatChallengesArray(challenges, 26)
	challengeModes.deathWindow:SetAlpha(0)
	challengeModes.deathWindow:Show()
	challengeModes.deathWindow.text:SetText(L("Death_Text", UnitName("player"), UnitLevel("player"), playedTime, challengesStr, rank))
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

function Handlers.OpenHallOfFameUI(player, addonVersion, maxResults)
	if not IsPatchInstalled(addonVersion) then
		AIO.Handle(channelName, "notifyInstallAddon", false)
		AIO.Handle(channelName, "closeHallOfFameUI")
		return
	end
	if not CheckAddonVersion(addonVersion) then
		AIO.Handle(channelName, "notifyInstallAddon", true)
		AIO.Handle(channelName, "closeHallOfFameUI")
		return
	end
	AIO.Handle(channelName, "openHallOfFameUI")

	challengeModes.hofWindow.dbLimit = math.min(maxResults, challengeModes.hofWindow.nbRows)
	challengeModes.hofWindow.dbOffset = 0
	challengeModes.hofWindow:Show()
	RequestHoFData()
end

function Handlers.HallOfFameData(player, rows, totalRows)
	if not challengeModes.hofWindow:IsShown() then
		return
	end

	challengeModes.hofWindow.loadingSpinner:Hide()

	local i = 0
	for _, char in pairs(rows) do
		if i >= challengeModes.hofWindow.nbRows then
			break
		end
		local row = challengeModes.hofWindow.playerRows[i]
		local className = classNames[char.c]
		row.txtName:SetText(char.n)
		row.txtName:SetTextColor(RAID_CLASS_COLORS[className]["r"], RAID_CLASS_COLORS[className]["g"], RAID_CLASS_COLORS[className]["b"])
		row.txtLevel:SetText(char.l)
		row.txtRank:SetText("#" .. char.r)
		if char.a == 1 then
			row.highlight:Show()
			row.txtName:SetFont("Fonts/FRIZQT__.TTF", 12, "OUTLINE")
		else
			row.highlight:Hide()
			row.txtName:SetFont("Fonts/FRIZQT__.TTF", 12)
		end
		if char.s == 0 then
			row.imgState:SetTexture("Interface/ChallengeModes/HoFActive")
		elseif char.s == 1 then
			row.imgState:SetTexture("Interface/ChallengeModes/HoFDead")
		elseif char.s == 2 then
			if char.r <= 3 then
				row.imgState:SetTexture("Interface/ChallengeModes/HoFRank" .. char.r)
			else
				row.imgState:SetTexture("Interface/ChallengeModes/HoFCompleted")
			end
		end
		row:Show()
		i = i + 1
	end
	challengeModes.hofWindow.container:SetHeight(math.min(#rows, challengeModes.hofWindow.nbRows) * challengeModes.hofWindow.rowHeight)

	if challengeModes.hofWindow.dbOffset + challengeModes.hofWindow.nbRows >= totalRows then
		challengeModes.hofWindow.btnNext:Disable()
	else
		challengeModes.hofWindow.btnNext:Enable()
	end
	if challengeModes.hofWindow.dbOffset >= challengeModes.hofWindow.nbRows then
		challengeModes.hofWindow.btnPrev:Enable()
	else
		challengeModes.hofWindow.btnPrev:Disable()
	end
end

function Handlers.CloseHallOfFameUI()
	challengeModes.hofWindow:Hide()
end

function Handlers.OpenCompletedUI(player, challenges, playedTime, rank)
	PlaySoundFile("Interface/ChallengeModes/1068315.ogg")
	local challengesStr = FormatChallengesArray(challenges, 18)
	challengeModes.completedWindow.text:SetText(L("Completed_Text", UnitName("player"), playedTime, challengesStr, rank))
	challengeModes.completedWindow:Show()
end
