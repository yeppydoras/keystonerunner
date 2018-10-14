local ksr = LibStub("AceAddon-3.0"):NewAddon("KeystoneRunner", "AceBucket-3.0", "AceEvent-3.0")
local ver = GetAddOnMetadata("KeystoneRunner", "Version")

local L = _KSRGlobal.L
local UI = _KSRGlobal.UI
local KSR_PREFIX = _KSRGlobal.Prefix
local KSR_DATA_VER = _KSRGlobal.DataVer
local KSR_MSGQUERYKSR = _KSRGlobal.MsgQueryKSR
local KSR_MSGSEP = _KSRGlobal.MsgSep
local KSR_HEADERREPLYKEYS = _KSRGlobal.MsgHeaderReplyKeys
local KSR_MSGREPLYKEYS = _KSRGlobal.MsgReplyKeys
local KSR_STD_TITLE = _KSRGlobal.StdTitle
local KSR_MPLOOTSPEC = _KSRGlobal.MPLootSpec

local MYTHIC_KEYSTONE_ID = 158923
local SEC_A_WEEK = 7 * 24 * 3600

local MIN_REPLY_INTERVAL = 15 * 60
local MIN_HINT_INTERVAL = 60 * 60
local MAX_AUTO_REPLY_TIMES = 3
local MAX_MPLUS_LOG = 1000
local msgSep_log = "===== Weekly Mythic+ Log ====="
local msgLogEntryID = " [%s] "

local MAX_CHAR_LEVEL = 120
local kwAutoReply = "#key"
local kwKeywords = "keystone|鑰石|钥石|key|鑰匙|钥匙|m%+|大秘|大米|保底|低保"
local kwFilters = "<keystone runner>|keystone runner|."

--[[

** baseTime table **
baseTime-US, Tuesday, 31-Oct-17 15:00:00 UTC, 1509462000
baseTime-KR, Thursday, 01-Nov-17 23:00:00 UTC, 1509577200
baseTime-EU, Wednesday, 01-Nov-17 07:00:00 UTC, 1509519600
baseTime-TW, Thursday, 01-Nov-17 23:00:00 UTC, 1509577200
baseTime-CN, Thursday, 01-Nov-17 23:00:00 UTC, 1509577200

ref pages:
https://us.battle.net/forums/en/wow/topic/20745655899
https://eu.battle.net/forums/en/wow/topic/17612252415

]]

-- Utils

function ksr:printUsage(help)
	print(L["msgSelfDesp"]..format(" (ver: %s)", ver))
	if help then
		print(L["msgUsageDetail"])
	end
end

-- Events

function ksr:onBagUpdate()
	self:checkNewKeyStone()
end

function ksr:onChallengeModeCompleted()

	function nameWRealm(name, realm)
		if name == nil then
			return "[N/A]"
		end

		if (realm == nil) or (realm == "") then
			return format("%s-%s", name, GetRealmName())
		else
			return format("%s-%s", name, realm)
		end
	end

	self:checkNewKeyStone()

	local _, level, elapsedMS, _, keystoneUpgradeLevels = C_ChallengeMode.GetCompletionInfo()
	self:updateWeeklyBest(level)

	-- log m+ data
	local dateTime = date("%Y/%m/%d %H:%M")
	local mapName = GetInstanceInfo()
	local partyMember = format("%s %s %s %s %s", self.name, nameWRealm(UnitName("party1")), nameWRealm(UnitName("party2")), nameWRealm(UnitName("party3")), nameWRealm(UnitName("party4")))
	local elapsedTime = SecondsToTime(elapsedMS / 1000)

	local newLogEntry = { name = self.name, dateTime = dateTime, mapName = mapName, level = level, partyMember = partyMember, 
		elapsedTime = elapsedTime, keystoneUpgradeLevels = keystoneUpgradeLevels }
	table.insert(self.MPlusLog, newLogEntry)
end

function ksr:onChatMsg(event, ...)
	local argv = {...}
	local ID, name, channel = ""
	local msg = string.lower(argv[1])
	local autoReplyMPlusDND = false
	local isMe = false

	if event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_PARTY_LEADER" then
		if argv[2] == self.name then
			isMe = true
		end
		ID = "_PARTY_"
		channel = "PARTY"
		name = L["msgParty"]
	else
		if event == "CHAT_MSG_BN_WHISPER" then
			ID = argv[13]
			channel = "BN_WHISPER"
		elseif event == "CHAT_MSG_WHISPER" then
			ID = argv[2]
			channel = "WHISPER"
		end

		self.MRW_ID = ID
		self.MRW_Channel = channel
		name = argv[2]
		-- bug: cant detect UnitInParty(bn_whisper_source_player)
		autoReplyMPlusDND = self:canReplyMPlusDND(name)
	end

	-- AutoReply -> ReplyMPlusDND -> isAFK -> normal keywords & hint
	if self.Settings.autoReplyKey and msg == kwAutoReply then
		-- feat: prevent spamming the whisper channel
		if (channel == "PARTY") then
			self:announceAllKeystones(channel, ID, true, kwAutoReply)
		elseif (channel == "WHISPER" or channel == "BN_WHISPER") and self:checkAutoReply(ID) then
			self:announceAllKeystones(channel, ID, true, kwAutoReply)
			self:updateAutoReply(ID, channel)
		end
	elseif autoReplyMPlusDND and self:checkReplyInterval(ID) then
		local mapName, level, killCount, bossCount, troopsString, troopsQuantityString, elapsedTime = self:getChallengeModeInfo()
		local mplusdndmsg = format(L["msgMPlusDND"], self.name, mapName, level, killCount, bossCount, troopsString, troopsQuantityString, elapsedTime, kwAutoReply)
		self:addChatMessage(mplusdndmsg, channel, ID)
		self:updateReplyInterval(ID)
	elseif (not isMe) and self:checkFilters(msg) then
		local hasKeyword, keyword = self:checkKeywords(msg)
		if hasKeyword and (channel ~= self.MRT_Channel or ID ~= self.MRT_ID or (GetTime() - self.MRT_Time >= MIN_HINT_INTERVAL)) then
			print(format(L["msgHintSemiAutoReply"], keyword, name))
			self.MRT_Time = GetTime()
			self.MRT_Channel = channel
			self.MRT_ID = ID
		end
	end
end

function ksr:onEvent(event, ...)

	local function cutLeft(str, left)
		return string.sub(str, string.len(left) + 1, string.len(str))
	end

	if event == "BN_CHAT_MSG_ADDON" then
		local prefix, message, w, bid = ...

		if prefix ~= KSR_PREFIX then return end

		if message == KSR_MSGQUERYKSR then
			local replyMsg = string.format(KSR_MSGREPLYKEYS, self.battleTag, KSR_DATA_VER, self:textOfAllKeystones())
			BNSendGameData(bid, KSR_PREFIX, replyMsg)
		elseif isLeft(message, KSR_HEADERREPLYKEYS) then
			-- not initialized yet, discard this message
			if UI.ksr == nil then return end
			local parts = { strsplit(KSR_MSGSEP, message) }
			-- cmd, battleTag, dataver, keys
			local battleTag = cutLeft(parts[2], "battleTag=")
			local dataver = tonumber(cutLeft(parts[3], "dataver="))
			local keys = cutLeft(parts[4], "keys=")
			UI:updateFriendKeys(battleTag, dataver, keys)
		end
	elseif event == "CHALLENGE_MODE_MAPS_UPDATE" then
		self:initWeeklyBest()
		-- Keep an eye on CHALLENGE_MODE_MAPS_UPDATE
		-- self.eventFrame:UnregisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
	elseif event == "CHALLENGE_MODE_START" then
		local insID = ...
		local keyID = _KSRGlobal.ins_key_ID[tostring(insID)]
		local strKey = format(KSR_MPLOOTSPEC, self.name, keyID)
		
		local mpLootSpec = self.MPLootSpec[strKey]
		if mpLootSpec ~= nil then
			print(L["msgMPSwitchLootSpec"])
			SetLootSpecialization(mpLootSpec)
		end
	end
end

-- Functions

function ksr:canReplyMPlusDND(name)
	if self.Settings.autoReplyMPlusDND and C_ChallengeMode.IsChallengeModeActive() then
		return true
	else
		return false
	end
end

function ksr:getChallengeModeInfo()

	local function getElapsedTime(...)
		for i = 1, select("#", ...) do
			local timerID = select(i, ...)
			local _, elapsedTime, type = GetWorldElapsedTime(timerID)
			if type == LE_WORLD_ELAPSED_TIMER_TYPE_CHALLENGE_MODE then
				return SecondsToTime(elapsedTime)
			end
		end
		return 0
	end

	local mapName = C_ChallengeMode.GetMapUIInfo(C_ChallengeMode.GetActiveChallengeMapID())
	local level = C_ChallengeMode.GetActiveKeystoneInfo()
	local bossCount = 0
	local killCount = 0
	local elapsedTime = getElapsedTime(GetWorldElapsedTimers())
	local troopsString = ""
	local troopsQuantityString = ""
	local _, _, stepCount = C_Scenario.GetStepInfo()
	for i	= 1, stepCount do
		local criteriaString, _, completed, quantity, totalQuantity, _, _, quantityString, _, _, _, _, isWeightedProgress = C_Scenario.GetCriteriaInfo(i)
		if not isWeightedProgress then
			bossCount = bossCount + 1
			if completed then
				killCount = killCount + 1
			end
		else
			troopsString = criteriaString
			troopsQuantityString = math.floor(tonumber(strsub(quantityString, 1, -2)) / totalQuantity * 100).."%"
		end
	end

	return mapName, level, killCount, bossCount, troopsString, troopsQuantityString, elapsedTime
end

function ksr:checkNewKeyStone()
	local keystone, changed = self:updateKeystone()
	if changed then
		self:announceKeystone(keystone)
	end
end

function ksr:checkReplyInterval(ID)
	if (self.timeReply[ID] == nil) or (GetTime() - self.timeReply[ID] >= MIN_REPLY_INTERVAL) then
		return true
	else
		return false
	end
end

function ksr:checkAutoReply(ID)
	if self.autoReply[ID] == nil then
		return true
	elseif GetTime() - self.autoReply[ID]["time"] >= MIN_REPLY_INTERVAL then
		self.autoReply[ID]["time"] = nil
		self.autoReply[ID]["times"] = nil
		return true
	elseif self.autoReply[ID]["times"] < MAX_AUTO_REPLY_TIMES then
		return true
	else
		return false
	end
end

function ksr:checkFilters(msg)
	for _, v in pairs(self.Filters) do
		if isLeft(msg, v) then
			return false
		end
	end
	return true
end

function ksr:checkKeywords(msg)
	for _, v in pairs(self.Keywords) do
		if strfind(msg, v) then
			return true, gsub(v, "%%", "")
		end
	end

	return false, nil
end

function ksr:updateReplyInterval(ID)
	self.timeReply[ID] = GetTime()
end

function ksr:updateAutoReply(ID, channel)
	if (self.autoReply[ID] == nil) or (self.autoReply[ID]["time"] == nil) then
		self.autoReply[ID] = {}
		self.autoReply[ID]["time"] = GetTime()
		self.autoReply[ID]["times"] = 1
	else
		self.autoReply[ID]["times"] = self.autoReply[ID]["times"] + 1
	end

	if self.autoReply[ID]["times"] >= MAX_AUTO_REPLY_TIMES then
		self:lockAutoReply(ID, channel)
	end
end

function ksr:lockAutoReply(ID, channel)
	self:addChatMessage(L["msgDontSpam"], channel, ID)
        self.autoReply[ID]["time"] = GetTime() + 15 * 60
end

function ksr:updateWeeklyBest(level)
	if (self.WeeklyBest[self.name] == nil) or (self.WeeklyBest[self.name] < level) then
		self.WeeklyBest[self.name] = level
	end
end

function ksr:textOfKeystone(keystone, plainText)

	function cutRight(str, sep)
		local pos = strfind(str, sep)
		if pos then
			return string.sub(str, 1, pos - 1)
		else
			return str
		end
	end

	local strNameClass
	local classColor = RAID_CLASS_COLORS[keystone.classE]
	local name = cutRight(keystone.name, "-")
	-- bug fix: "卍" & "卐" cant send in party channel [reason : no idea]
	if plainText then
		name = gsub(gsub(name, "卍", "←"), "卐", "→")
	end
	if keystone.classE ~= nil and classColor ~= nil and not plainText then
		strNameClass = format("|c%s%s|r", classColor.colorStr, name)
	else
		strNameClass = format("%s(%s)", name, L[string.format("ABBR_%s", keystone.classE)])
	end

	if keystone.keystoneLevel ~= 0 and keystone.dungeonID ~= 0 then
		return string.format("[%s%d]", L[string.format("DIDv8_%d", keystone.dungeonID)], keystone.keystoneLevel).." "..strNameClass
	else
		return L["msgNoKeystone"].." "..strNameClass
	end
end

function ksr:textOfWeeklyBest(keystone)
	local weeklyBest = self.WeeklyBest[keystone.name]
	if (weeklyBest == nil) or (weeklyBest == 0) then
		return format(L["msgWeeklyBest"], "N/A")
	else
		return format(L["msgWeeklyBest"], "+"..tostring(weeklyBest))
	end
end

function ksr:addChatMessage(msg, channel, ID)
	if (channel == "PARTY" and IsInGroup()) or (channel == "GUILD" and GetGuildInfo("player")) or (channel == "SAY") then
		SendChatMessage(msg, channel)
		return true
	elseif (channel == "WHISPER") and (ID ~= nil) then
		SendChatMessage(msg, channel, nil, ID)
		return true
	elseif (channel == "BN_WHISPER") and (ID ~= nil) then
		BNSendWhisper(ID, msg)
		return true
	else
		print(msg)
		return false
	end
end

function ksr:announceKeystone(keystone)
	-- announce keystone to party members
	if keystone then
		local msgKS = L["msgHeadnote_new"]..self:textOfKeystone(keystone, true)
		return self:addChatMessage(msgKS, "PARTY", nil)
	else
		return false
	end
end

function ksr:textOfAllKeystones()
	local sorted = {}
	local msg = ""

	if next(self.Keystones) ~= nil then
		for _, ks in pairs(self.Keystones) do
			table.insert(sorted, ks)
		end

		-- order by keystoneLevel desc
		table.sort(sorted, function(a, b) return a.keystoneLevel > b.keystoneLevel end)

		for i = 1, #sorted do
			msg = msg..self:textOfKeystone(sorted[i], false).." "..self:textOfWeeklyBest(sorted[i]).."\n"
		end
	else
		msg = L["msgListEmpty"]
	end

	return msg
end

function ksr:announceAllKeystones(channel, ID, autoReply, keyword)
	local retVal
	local plainText = true
	local sorted = {}

	if channel == "" or ID == "" then
		print(L["msgCantSendMsg"])
		return
	elseif channel == "PARTY" and not IsInGroup(LE_PARTY_CATEGORY_HOME) then
		print(L["msgNotInGroup"])
		return
	elseif channel == "GUILD" and GetGuildInfo("player") == nil then
		print(L["msgNotInGuild"])
		return
	end

	if channel == "DEFCHAT" then
		plainText = false
	end

	retVal = self:addChatMessage(L["msgHeadnote_all"], channel, ID)
	if next(self.Keystones) ~= nil then
		for _, ks in pairs(self.Keystones) do
			table.insert(sorted, ks)
		end

		-- order by keystoneLevel desc
		table.sort(sorted, function(a, b) return a.keystoneLevel > b.keystoneLevel end)

		for i = 1, #sorted do
			local msg = "."..self:textOfKeystone(sorted[i], plainText).." "..self:textOfWeeklyBest(sorted[i])
			retVal = self:addChatMessage(msg, channel, ID) and retVal
		end
	else
		retVal = self:addChatMessage(L["msgListEmpty"], channel, ID) and retVal
	end

	if autoReply then
		retVal = self:addChatMessage(format(L["msgDespFullAutoReply"], keyword), channel, ID) and retVal
	end

	if not retVal then
		self:printUsage(true)
	end
end

function ksr:weeklyCleanUp()
	-- Only initialize once during one session
	if self.baseTime == 0 then
		local region = GetCurrentRegion()
		if region < 1 or region > 5 then
			-- unknown region
			return false
		end
		self.baseTime = ({ 1509462000, 1509577200, 1509519600, 1509577200, 1509577200 })[region]
	end

	local currTime = GetServerTime()
	if self.Settings.nextResetTime < currTime then
		self.Settings.nextResetTime = SEC_A_WEEK - math.fmod(currTime - self.baseTime, SEC_A_WEEK) + currTime
		if next(self.Keystones) ~= nil then
			self:weeklyResetData()
			return true
		else
			return false
		end
	else
		return false
	end
end

function ksr:updateKeystone()
	-- do not execute update during ChallengeMode, otherwise will get an invalid msg "active keystone (level)-1"
	if C_ChallengeMode.IsChallengeModeActive() then
		return nil, nil
	end

	if self:weeklyCleanUp() then
		print(L["msgWeeklyCleanup"])
		return nil, nil
	end
	
	if UnitLevel("player") < MAX_CHAR_LEVEL then
		self.Keystones[self.name] = nil
	end

	for bag = 0, NUM_BAG_SLOTS do
		local numSlots = GetContainerNumSlots(bag)
		for slot = 1, numSlots do
			if GetContainerItemID(bag, slot) == MYTHIC_KEYSTONE_ID then
				local orgLink = GetContainerItemLink(bag, slot)
				
				local dungeonID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
				local keystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel()

				local newKeystone = { name = self.name, class = self.classL, classE = self.classE, link = orgLink, dungeonID = dungeonID, keystoneLevel = keystoneLevel }
				local oldKeystone = self.Keystones[self.name]
				local changed = ((oldKeystone == nil) or (oldKeystone.keystoneLevel ~= newKeystone.keystoneLevel) or (oldKeystone.dungeonID ~= newKeystone.dungeonID))
				self.Keystones[self.name] = newKeystone

				-- Send Addon message is better, instead of calling UI function
				if changed and UI ~= nil then
					UI:updateMyKeys()
				end
				
				return self.Keystones[self.name], changed
			end
		end
	end
	-- no keystone
	return nil, nil
end

function ksr:resetData()
	wipe(self.Keystones)
	wipe(self.WeeklyBest)
	wipe(self.MPlusLog)
end

function ksr:shrinkLog()
	if #self.MPlusLog > MAX_MPLUS_LOG then
		local count = #self.MPlusLog - MAX_MPLUS_LOG
		for i = 1, count do
            table.remove(self.MPlusLog, 1)
		end
	end
end

function ksr:weeklyResetData()
	for _, ks in pairs(self.Keystones) do
		ks.link = ""
		ks.dungeonID = 0
		ks.keystoneLevel = 0
	end
	wipe(self.WeeklyBest)
	self:shrinkLog()
end

function ksr:viewMPlusLog(filters)
	print(msgSep_log)

	if next(self.MPlusLog) == nil then
		print(L["msgLogEmpty"])
	end

	local logCount = 0
	for i = 1, #self.MPlusLog do
		local validEntry = true
		local item = self.MPlusLog[i]
		local msgBody = format(L["msgLogEntryBody"], item.dateTime, item.mapName, item.level, item.partyMember, item.elapsedTime, item.keystoneUpgradeLevels)

		logCount = logCount + 1

		if #filters >= 2 then
			for k = 2, #filters do
				if not strfind(msgBody, filters[k]) then
					validEntry = false
					logCount = logCount - 1
					break
				end
			end
		end

		if validEntry then
			print(format(msgLogEntryID, logCount)..msgBody)
		end
	end

	print(format(L["msgLogSum"], logCount))
end

function ksr:wipelog()
	wipe(self.MPlusLog)
end

function ksr:procOptions(params)
	if params[2] == "mythicautoreply" then
		self.Settings.autoReplyMPlusDND = not self.Settings.autoReplyMPlusDND
		print(format(L["msgToggleMPlusAutoReply"], tostring(self.Settings.autoReplyMPlusDND)))
	elseif params[2] == "keyautoreply" then
		self.Settings.autoReplyKey = not self.Settings.autoReplyKey
		print(format(L["msgToggleKeyAutoReply"], tostring(self.Settings.autoReplyKey)))
	else
		print(L["msgUnknownOptCmd"])
	end
end

function ksr:slashCmd(cmd)
	local cmdp = { strsplit(" ", cmd) }
	-- cant send BN whisper by command
	if cmd == "p" or cmd == "party" then
		self:announceAllKeystones("PARTY")
	elseif cmd == "g" or cmd == "guild" then
		self:announceAllKeystones("GUILD")
	elseif cmd == "s" or cmd == "say" then
		self:announceAllKeystones("SAY")
	elseif cmd == "w" or cmd == "whisper" then
		self:announceAllKeystones(self.MRW_Channel, self.MRW_ID)
	elseif (cmdp[1] == "w" or cmdp[1] == "whisper") and #cmdp == 2 then
		self:announceAllKeystones("WHISPER", cmdp[2])
	elseif cmd == "r" or cmd == "reply" then
		self:announceAllKeystones(self.MRT_Channel, self.MRT_ID)
	elseif (cmdp[1] == "opt" or cmdp[1] == "option") and #cmdp >= 2 then
		self:procOptions(cmdp)
	-- advanced commands
	elseif cmd == "cmi" then
		print(self:getChallengeModeInfo())
	elseif cmd == "wrd" then
		self:weeklyResetData()
	elseif cmd == "clear" then
		self:resetData()
	elseif cmdp[1] == "log" then
		self:viewMPlusLog(cmdp)
	elseif cmd == "shrinklog" then
		self:shrinkLog()
	elseif cmd == "wipelog" then
		self:wipelog()
	elseif cmd == "help" then
		self:printUsage(true)
	elseif cmd == "" then
		ToggleFrame(KeystoneRunnerMainFrame)
	else
		self:announceAllKeystones("DEFCHAT")
	end
end

-- init

function ksr:initKeywords()
	self.Keywords = { strsplit("|", kwKeywords) }
	self.Filters = { strsplit("|", kwFilters) }
end

function ksr:initWeeklyBest()
	local maxLevel = 0
	for _, mapID in pairs(C_ChallengeMode.GetMapTable()) do
		local _, weeklyBestLevel = C_MythicPlus.GetWeeklyBestForMap(mapID)
		if weeklyBestLevel and weeklyBestLevel > maxLevel then
			maxLevel = weeklyBestLevel
		end
	end
	
	if maxLevel ~= 0 then
		self:updateWeeklyBest(maxLevel)
	else
		-- Remove self weeklyBestLevel from list
		self.WeeklyBest[self.name] = nil
	end
end

function ksr:registerEvent(keystone)
	local interval = 3

	if keystone ~= nil then
		-- set bag scanning interval to 1 min in case of unexpected events
		interval = 60
	end
	self:RegisterBucketEvent("BAG_UPDATE", interval, "onBagUpdate")
	self:RegisterBucketEvent("CHALLENGE_MODE_COMPLETED", 3, "onChallengeModeCompleted")

	self.chatFrame = CreateFrame("FRAME")
	self.chatFrame:RegisterEvent("CHAT_MSG_WHISPER")
	self.chatFrame:RegisterEvent("CHAT_MSG_BN_WHISPER")
	self.chatFrame:RegisterEvent("CHAT_MSG_PARTY")
	self.chatFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
	self.chatFrame:SetScript("OnEvent", function(obj, event, ...) self:onChatMsg(event, ...) end)
end

function ksr:OnInitialize()
	self.MRT_Time = 0
	self.MRT_Channel = ""
	self.MRT_ID = ""
	self.MRW_Channel = ""
	self.MRW_ID = ""

	self.chatFrame = nil
	self.eventFrame = nil
	self.Keywords = {}
	self.Filters = {}
	self.timeReply = {}
	self.autoReply = {}
	self.lootSpec = {}
	local sname = UnitName("player")
	self.name = string.format("%s-%s", sname, GetRealmName())
	self.classL, self.classE = UnitClass("player")
	local _, battleTag = BNGetInfo()
	self.battleTag = battleTag
	
	self:initKeywords()

	self.baseTime = 0

	-- init db
	self.Keystones = {}
	self.WeeklyBest = {}
	self.MPLootSpec = {}
	self.MPlusLog = {}
	local dbDefaults = {
		keystones = {},
		weeklybest = {},
		mplootspec = {},
		mpluslog = {},
		settings = {
			nextResetTime = 1509462000,
			autoReplyMPlusDND = true,
			autoReplyKey = true,
			renderNameWClassColor = false,
			minimap = {
				hide = false,
			},
		},
	}
	self.db = LibStub("AceDB-3.0"):New("KeystoneRunnerDB", { faction = dbDefaults }, true).faction
	self.Keystones = self.db.keystones
	self.WeeklyBest = self.db.weeklybest
	self.MPLootSpec = self.db.mplootspec
	self.MPlusLog = self.db.mpluslog
	self.Settings = self.db.settings

	UI:init(self)
	
	-- prepare for replying addon messages
	C_ChatInfo.RegisterAddonMessagePrefix(KSR_PREFIX)
	self.eventFrame = CreateFrame("FRAME")
	self.eventFrame:RegisterEvent("BN_CHAT_MSG_ADDON")
	self.eventFrame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
	self.eventFrame:RegisterEvent("CHALLENGE_MODE_START")
	self.eventFrame:SetScript("OnEvent", function(obj, event, ...) self:onEvent(event, ...) end)

	-- init keystone, events, player data and UI
	-- wait for player login
	self:RegisterBucketEvent("PLAYER_LOGIN", 1, function()
		self:printUsage(false)
		local keystone, _ = self:updateKeystone()
		self:registerEvent(keystone)
		C_MythicPlus.RequestMapInfo()
		local numLootSpec = GetNumSpecializations()
		table.insert(self.lootSpec, { name = L["dropDownDefLootSpec"], id = 0 })
		for i = 1, numLootSpec do
			local id, name = GetSpecializationInfo(i)
			table.insert(self.lootSpec, { name = name, id = id })
		end
	end)

	-- misc
	SLASH_KEYSTONERUNNER1, SLASH_KEYSTONERUNNER2 = "/keystonerunner", "/ksr"
	SlashCmdList["KEYSTONERUNNER"] = function(cmd) self:slashCmd(string.lower(cmd)) end

	-- Keybindings
	BINDING_HEADER_KSRHEADER = KSR_STD_TITLE
	BINDING_NAME_KSRTOGGLE = L["strToggleFriendsFrame"]
end
