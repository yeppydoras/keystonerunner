local dataStub = {}
_KSRGlobal.dataStub = dataStub

-- client: BNET_CLIENT_WOW, BNET_CLIENT_SC2, BNET_CLIENT_D3, BNET_CLIENT_WTCG, BNET_CLIENT_APP, BNET_CLIENT_HEROES, BNET_CLIENT_OVERWATCH,
-- 	BNET_CLIENT_CLNT, BNET_CLIENT_SC, BNET_CLIENT_DESTINY2
-- faction: Alliance, Horde
-- race: Human, Dwarf, Night Elf, Gnome, Draenei, Worgen, Pandaren / Orc, Undead, Tauren, Troll, Blood Elf, Goblin
-- class/E: Hunter/HUNTER, Warlock/WARLOCK, Priest/PRIEST, Paladin/PALADIN, Mage/MAGE, Rogue/ROGUE, Druid/DRUID, Shaman/SHAMAN, Warrior/WARRIOR
-- 	Death Knight/DEATHKNIGHT, Monk/MONK, Demon Hunter/DEMONHUNTER
-- zoneName =
-- 	* Dungeons:
-- 	Neltharion's Lair, Karazhan, Black Rook Hold, Cathedral of Eternal Night, Court of Stars, Darkheart Thicket, Eye of Azshara, Halls of Valor, Seat of the Triumvirate,
-- 	The Arcway, Vault of the Wardens,
-- 	* Raid:
-- 	Antorus, the Burning Throne,
-- 	* Citys:
-- 	Dalaran,
-- 	* Maps:
-- 	Azsuna, Val'sharah, Highmountain, Stormheim, Suramar
-- Name: Crising, Emong, Noru, Kulap, Sonca, Roke, Nalgae, Pakhar, Isang, Sanvu, Guchol, Kiko, Talim, Lan, Paolo, Saola, Quedan, Haikui, Salome
-- Realm: Illidan/1, Frostmourne/2, Jubei'Thos/3, Zul'jin/4, Sargeras/5, Thrall/6, Turalyon/7, Crushridge/8, Kil'jaeden/9, Emerald Dream/10, Proudmoore/11
-- RAID_CLASS_COLORS = {
-- 	["HUNTER"] = { r = 0.67, g = 0.83, b = 0.45, colorStr = "ffabd473" },
-- 	["WARLOCK"] = { r = 0.53, g = 0.53, b = 0.93, colorStr = "ff8788ee" },
-- 	["PRIEST"] = { r = 1.0, g = 1.0, b = 1.0, colorStr = "ffffffff" },
-- 	["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73, colorStr = "fff58cba" },
-- 	["MAGE"] = { r = 0.25, g = 0.78, b = 0.92, colorStr = "ff3fc7eb" },
-- 	["ROGUE"] = { r = 1.0, g = 0.96, b = 0.41, colorStr = "fffff569" },
-- 	["DRUID"] = { r = 1.0, g = 0.49, b = 0.04, colorStr = "ffff7d0a" },
-- 	["SHAMAN"] = { r = 0.0, g = 0.44, b = 0.87, colorStr = "ff0070de" },
-- 	["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43, colorStr = "ffc79c6e" },
-- 	["DEATHKNIGHT"] = { r = 0.77, g = 0.12 , b = 0.23, colorStr = "ffc41f3b" },
-- 	["MONK"] = { r = 0.0, g = 1.00 , b = 0.59, colorStr = "ff00ff96" },
-- 	["DEMONHUNTER"] = { r = 0.64, g = 0.19, b = 0.79, colorStr = "ffa330c9" },
-- }

function dataStub:fillFriendsData(friendsData, friendsHasKSR)
	-- fill friendsData
	table.insert(friendsData, { ID = 1, pid = 1, accountName = "Auring", battleTag = "Auring#1", battleTagWOHashTag = "Auring", isBattleTag = true,
		characterName = "Mawar", bnetIDGameAccount = 101, client = BNET_CLIENT_WOW, isOnline = true, lastOnline = 0, isBnetAFK = false, isBnetDND = false, noteText = "",
		realmName = "Illidan", realmID = 1, faction = "Alliance", race = "Night Elf", class = "Druid", classE = "DRUID", zoneName = "Court of Stars", level = 110, gameText = "",
		bnetIDAccount = 1, isGameAFK = false, isGameBusy = false, GUID = "Player-1" })

	table.insert(friendsData, { ID = 2, pid = 2, accountName = "Damrey", battleTag = "Damrey#2", battleTagWOHashTag = "Damrey", isBattleTag = true,
		characterName = "Kiolvar", bnetIDGameAccount = 102, client = BNET_CLIENT_WOW, isOnline = true, lastOnline = 0, isBnetAFK = true, isBnetDND = false, noteText = "",
		realmName = "Frostmourne", realmID = 2, faction = "Alliance", race = "Human", class = "Paladin", classE = "PALADIN", zoneName = "Dalaran", level = 110, gameText = "",
		bnetIDAccount = 2, isGameAFK = false, isGameBusy = false, GUID = "Player-2" })

	table.insert(friendsData, { ID = 3, pid = 3, accountName = "Dante", battleTag = "Dante#3", battleTagWOHashTag = "Dante", isBattleTag = true,
		characterName = "Treelumpin", bnetIDGameAccount = 103, client = BNET_CLIENT_WOW, isOnline = true, lastOnline = 0, isBnetAFK = false, isBnetDND = false, noteText = "",
		realmName = "Frostmourne", realmID = 2, faction = "Alliance", race = "Night Elf", class = "Demon Hunter", classE = "DEMONHUNTER", zoneName = "Stormheim", level = 102, gameText = "",
		bnetIDAccount = 3, isGameAFK = false, isGameBusy = false, GUID = "Player-3" })

	table.insert(friendsData, { ID = 4, pid = 4, accountName = "Gorio", battleTag = "Gorio#4", battleTagWOHashTag = "Gorio", isBattleTag = true,
		characterName = "Skilldotom", bnetIDGameAccount = 104, client = BNET_CLIENT_WOW, isOnline = true, lastOnline = 0, isBnetAFK = false, isBnetDND = false, noteText = "",
		realmName = "Jubei'Thos", realmID = 3, faction = "Horde", race = "Tauren", class = "Druid", classE = "DRUID", zoneName = "Val'sharah", level = 110, gameText = "",
		bnetIDAccount = 4, isGameAFK = false, isGameBusy = false, GUID = "Player-4" })

	table.insert(friendsData, { ID = 5, pid = 5, accountName = "Hato", battleTag = "Hato#5", battleTagWOHashTag = "Hato", isBattleTag = true,
		characterName = "Alodrith", bnetIDGameAccount = 105, client = BNET_CLIENT_WOW, isOnline = true, lastOnline = 0, isBnetAFK = false, isBnetDND = false, noteText = "",
		realmName = "Illidan", realmID = 1, faction = "Alliance", race = "Human", class = "Priest", classE = "PRIEST", zoneName = "The Arcway", level = 110, gameText = "",
		bnetIDAccount = 5, isGameAFK = false, isGameBusy = false, GUID = "Player-5" })

	table.insert(friendsData, { ID = 6, pid = 6, accountName = "Maring", battleTag = "Maring#6", battleTagWOHashTag = "Maring", isBattleTag = true,
		characterName = "Dunrhan", bnetIDGameAccount = 106, client = BNET_CLIENT_WOW, isOnline = true, lastOnline = 0, isBnetAFK = false, isBnetDND = false, noteText = "",
		realmName = "Zul'jin", realmID = 4, faction = "Alliance", race = "Pandaren", class = "Monk", classE = "MONK", zoneName = "Antorus, the Burning Throne", level = 110, gameText = "",
		bnetIDAccount = 6, isGameAFK = false, isGameBusy = false, GUID = "Player-6" })

	table.insert(friendsData, { ID = 7, pid = 7, accountName = "Nando", battleTag = "Nando#7", battleTagWOHashTag = "Nando", isBattleTag = true,
		characterName = "Lapudinho", bnetIDGameAccount = 107, client = BNET_CLIENT_WOW, isOnline = true, lastOnline = 0, isBnetAFK = false, isBnetDND = false, noteText = "",
		realmName = "Sargeras", realmID = 5, faction = "Alliance", race = "Gnome", class = "Death Knight", classE = "DEATHKNIGHT", zoneName = "Court of Stars", level = 110, gameText = "",
		bnetIDAccount = 7, isGameAFK = false, isGameBusy = false, GUID = "Player-7" })

	table.insert(friendsData, { ID = 8, pid = 8, accountName = "Odette", battleTag = "Odette#8", battleTagWOHashTag = "Odette", isBattleTag = true,
		characterName = "Kullerastlas", bnetIDGameAccount = 108, client = BNET_CLIENT_WOW, isOnline = true, lastOnline = 0, isBnetAFK = false, isBnetDND = false, noteText = "",
		realmName = "Thrall", realmID = 6, faction = "Alliance", race = "Worgen", class = "Hunter", classE = "HUNTER", zoneName = "Dalaran", level = 110, gameText = "",
		bnetIDAccount = 8, isGameAFK = false, isGameBusy = false, GUID = "Player-8" })

	table.insert(friendsData, { ID = 9, pid = 9, accountName = "Ramil", battleTag = "Ramil#9", battleTagWOHashTag = "Ramil", isBattleTag = true,
		characterName = "Coldchember", bnetIDGameAccount = 109, client = BNET_CLIENT_WOW, isOnline = true, lastOnline = 0, isBnetAFK = false, isBnetDND = false, noteText = "",
		realmName = "Turalyon", realmID =7 , faction = "Alliance", race = "Gnome", class = "Mage", classE = "MAGE", zoneName = "Court of Stars", level = 110, gameText = "",
		bnetIDAccount = 9, isGameAFK = false, isGameBusy = false, GUID = "Player-9" })

	table.insert(friendsData, { ID = 10, pid = 10, accountName = "Tino", battleTag = "Tino#10", battleTagWOHashTag = "Tino", isBattleTag = true,
		characterName = "Lunlemon", bnetIDGameAccount = 110, client = BNET_CLIENT_WOW, isOnline = true, lastOnline = 0, isBnetAFK = false, isBnetDND = true, noteText = "",
		realmName = "Crushridge", realmID = 8, faction = "Alliance", race = "Dwarf", class = "Rogue", classE = "ROGUE", zoneName = "Antorus, the Burning Throne", level = 110, gameText = "",
		bnetIDAccount = 10, isGameAFK = false, isGameBusy = false, GUID = "Player-10" })

	table.insert(friendsData, { ID = 11, pid = 11, accountName = "Urduja", battleTag = "Urduja#11", battleTagWOHashTag = "Urduja", isBattleTag = true,
		characterName = "Diamondbep", bnetIDGameAccount = 111, client = BNET_CLIENT_WOW, isOnline = true, lastOnline = 0, isBnetAFK = false, isBnetDND = false, noteText = "",
		realmName = "Illidan", realmID = 1, faction = "Alliance", race = "Draenei", class = "Warrior", classE = "WARRIOR", zoneName = "Seat of the Triumvirate", level = 110, gameText = "",
		bnetIDAccount = 11, isGameAFK = false, isGameBusy = false, GUID = "Player-11" })

	-- non WOW
	table.insert(friendsData, { ID = 12, pid = 12, accountName = "Fabian", battleTag = "Fabian#12", battleTagWOHashTag = "Fabian", isBattleTag = true,
		characterName = "Merbok", bnetIDGameAccount = 112, client = BNET_CLIENT_APP, isOnline = true, lastOnline = 0, isBnetAFK = false, isBnetDND = false, noteText = "",
		realmName = nil, realmID = nil, faction = nil, race = nil, class = nil, classE = nil, zoneName = nil, level = nil, gameText = "Mobile",
		bnetIDAccount = 12, isGameAFK = false, isGameBusy = false, GUID = "Player-12" })

	table.insert(friendsData, { ID = 13, pid = 13, accountName = "Merbok", battleTag = "Merbok#13", battleTagWOHashTag = "Merbok", isBattleTag = true,
		characterName = "", bnetIDGameAccount = 113, client = BNET_CLIENT_HEROES, isOnline = true, lastOnline = 0, isBnetAFK = false, isBnetDND = false, noteText = "",
		realmName = nil, realmID = nil, faction = nil, race = nil, class = nil, classE = nil, zoneName = nil, level = nil, gameText = "Playing Versus A.I.",
		bnetIDAccount = 13, isGameAFK = false, isGameBusy = false, GUID = "Player-13" })

	table.insert(friendsData, { ID = 14, pid = 14, accountName = "Jolina", battleTag = "Jolina#14", battleTagWOHashTag = "Jolina", isBattleTag = true,
		characterName = "", bnetIDGameAccount = 0, client = "", isOnline = false, lastOnline = time() - 3907, isBnetAFK = false, isBnetDND = false, noteText = "",
		realmName = nil, realmID = nil, faction = nil, race = nil, class = nil, classE = nil, zoneName = nil, level = nil, gameText = "",
		bnetIDAccount = 14, isGameAFK = false, isGameBusy = false, GUID = "Player-14" })

	table.insert(friendsData, { ID = 15, pid = 15, accountName = "Talas", battleTag = "Talas#15", battleTagWOHashTag = "Talas", isBattleTag = true,
		characterName = "", bnetIDGameAccount = 0, client = "", isOnline = false, lastOnline = time() - 86237, isBnetAFK = false, isBnetDND = false, noteText = "",
		realmName = nil, realmID = nil, faction = nil, race = nil, class = nil, classE = nil, zoneName = nil, level = nil, gameText = "",
		bnetIDAccount = 15, isGameAFK = false, isGameBusy = false, GUID = "Player-15" })

	-- fill friendsHasKSR
	friendsHasKSR["Damrey#2"] = { ver = 1, keys = "[HOV22] |cfff58cbaKiolvar|r <Done +21>\n[BRH20] |cff3fc7ebTembinim|r <Done +20>\n[DHT17] |cffffffffNesat|r <Done N/A>\n[ARC17] |cff8788eeBanyan|r <Done +15>\n"
		.."[MOS16] |cffff7d0aVintar|r <Done +16>\n[COS15] |cff00ff96Lannie|r <Done N/A>\n", w = date("%A"), t = date("%H:%M:%S") }
end

function dataStub:textOfAllKeystones()
	return "[EOA21] |cfff58cbaBising|r <Done +22>\n[VOTW19] |cff3fc7ebKaitak|r <Done +18>\n[COEN18] |cffffffffKhanun|r <Done N/A>\n[ARC17] |cff0070deKirogi|r <Done +17>\n"
		.."[UPPR16] |cffff7d0aDoksuri|r <Done +16>\n"
end