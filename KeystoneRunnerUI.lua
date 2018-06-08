local UI = {}
local KSR_PREFIX = "KSRNNR"
local KSR_DATA_VER = 1
local KSR_MSGQUERYKSR = "QUERYKSR"
local KSR_MSGSEP = "\t"
local KSR_HEADERREPLYKEYS = "CMD=REPLYKEYS"
local KSR_MSGREPLYKEYS = KSR_HEADERREPLYKEYS..KSR_MSGSEP.."battleTag=%s"..KSR_MSGSEP.."dataver=%d"..KSR_MSGSEP.."keys=%s"
_KSRGlobal = { UI = UI, Prefix = KSR_PREFIX,  DataVer = KSR_DATA_VER, MsgQueryKSR = KSR_MSGQUERYKSR, MsgSep = KSR_MSGSEP, MsgHeaderReplyKeys = KSR_HEADERREPLYKEYS, MsgReplyKeys = KSR_MSGREPLYKEYS }
local MAX_QUERY_RETRY = 3
local INTERVAL_QUERY_RETRY = 2
local INTERVAL_HOTKEY = 0.35

-- sizes for adpative layout
local WIDTH_FRAME = 770
local HEIGHT_FRAME = 600
local EDGE_SIZE = 16
local WIDTH_SUBFRAME = WIDTH_FRAME - EDGE_SIZE * 2
local HEIGHT_SUBFRAME = HEIGHT_FRAME - EDGE_SIZE * 2
local COUNT_FRIENDSBTN = 15
local WIDTH_FRIENDSBTN = 300
local HEIGHT_FRIENDSBTN = 34
local OFFSET_Y_FRIENDSBTN = -58
local HEIGHT_SEARCHBOX = 24
local OFFSET_Y_SEARCHBOX = -28
local OFFSET_X_FRIENDSINFO = WIDTH_FRIENDSBTN + EDGE_SIZE * 2
local WIDTH_SMF = WIDTH_SUBFRAME - OFFSET_X_FRIENDSINFO
local WIDTH_BUTTON = 64
local HEIGHT_BUTTON = 64
local MARGIN_BUTTON = 12

local FRIENDS_TEXTURE_ONLINE = "Interface\\FriendsFrame\\StatusIcon-Online"
local FRIENDS_TEXTURE_AFK = "Interface\\FriendsFrame\\StatusIcon-Away"
local FRIENDS_TEXTURE_DND = "Interface\\FriendsFrame\\StatusIcon-DnD"
local FRIENDS_TEXTURE_OFFLINE = "Interface\\FriendsFrame\\StatusIcon-Offline"
local FRIENDS_BNET_NAME_COLOR_CODE = "|cff82c5ff"
local FRIENDS_BROADCAST_TIME_COLOR_CODE = "|cff4381a8"
local FRIENDS_WOW_NAME_COLOR_CODE = "|cfffde05c"
local FRIENDS_OTHER_NAME_COLOR_CODE = "|cff7b8489"
local FRIENDS_GRAY_COLOR = "|cff7b8489"
local COMMENT_COLOR =  "|cff9ba4a9"
local FRIENDS_BNET_BACKGROUND_COLOR = {r=0, g=0.694, b=0.941, a=0.05}
local FRIENDS_OFFLINE_BACKGROUND_COLOR = {r=0.588, g=0.588, b=0.588, a=0.05}

local BTN_INVITE_TEXTURE = "Interface\\AddOns\\KeystoneRunner\\media\\btnInvite"
local BTN_WHISPER_TEXTURE = "Interface\\AddOns\\KeystoneRunner\\media\\btnWhisper"
local BTN_REPORTKEYS_TEXTURE = "Interface\\AddOns\\KeystoneRunner\\media\\btnReportKeys"
local BTN_QUERYKEYS_TEXTURE = "Interface\\AddOns\\KeystoneRunner\\media\\btnQueryKeys"
local BTN_QUERYDGINFO_TEXTURE = "Interface\\AddOns\\KeystoneRunner\\media\\btnQueryDGInfo"
local BTNS_HIGHLIGHT_TEXTURE = "Interface\\AddOns\\KeystoneRunner\\media\\btns_HLT.tga"
local BTN_TEXTURE_SUFFIX_NML = "_NML.tga"
local BTN_TEXTURE_SUFFIX_DIS = "_DIS.tga"
local BTN_TEXTURE_SUFFIX_PSH = "_PSH.tga"

function dumptbl(t)
	for k, v in pairs(t) do
		print(k)
		if v ~= nil then
			print(v)
		else
			print("nil")
		end
	end
	print(" ")
end

-- http://lua-users.org/wiki/StringTrim trim6
local function trim(s)
	return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

function UI:init(ksr)
	self.ksr = ksr
	self.friendsData = {}
	self.friendsBtns = {}
	self.filteredData = {}
	self.friendsHasKSR = {}
	self.friendsWaitForResp = {}
	self.prevKey = { key = "", ts = 0 }
	self.playerFaction = UnitFactionGroup("player")
	self.keystonerunnerLDB = LibStub("LibDataBroker-1.1"):NewDataObject("KeystoneRunner", {
		type = "data source",
		text = KSR_STD_TITLE,
		icon = "Interface\\AddOns\\KeystoneRunner\\Media\\minimap.tga",
		OnClick = function() ToggleFrame(KeystoneRunnerMainFrame) end,
		OnTooltipShow = function() GameTooltip:SetText(KSR_STD_TITLE) end,
	})
	self.mmbtn = LibStub("LibDBIcon-1.0")
	self.mmbtn:Register("keystonerunner", self.keystonerunnerLDB, ksr.Settings.minimap)

	-- init frames & components
	self.mainFrame = self:createMainFrame()
	self.friendsFrame = self:createSubFrame(self.mainFrame, "friendsSubFrame")
	self:createFriendsButtons(self.friendsFrame)

	self.timerQuery = C_Timer.NewTicker(1, function() self:onTimerQuery() end)
end

function UI:getNameFromData(data)
	local accName, charName

	if data.accountName then
		accName = data.accountName
	else
		accName = UNKNOWN
	end

	if data.isOnline then
		accName = FRIENDS_BNET_NAME_COLOR_CODE..accName..FONT_COLOR_CODE_CLOSE
		charName = BNet_GetValidatedCharacterName(data.characterName, data.battleTag, data.client)
	else
		accName = FRIENDS_GRAY_COLOR..accName..FONT_COLOR_CODE_CLOSE
		charName = nil
	end

	if ((data.client == BNET_CLIENT_WOW) and (self.playerFaction == data.faction)) then
		return accName.." "..FRIENDS_WOW_NAME_COLOR_CODE.."("..charName..")"..FONT_COLOR_CODE_CLOSE
	elseif charName then
		return accName.." "..FRIENDS_OTHER_NAME_COLOR_CODE.."("..charName..")"..FONT_COLOR_CODE_CLOSE
	else
		return accName
	end
end

function UI:getOfflineFromData(data)
	if data.lastOnline ~= nil and data.lastOnline ~= 0 then
		return string.format(BNET_LAST_ONLINE_TIME, SecondsToTime(time() - data.lastOnline))
	else
		return UNKNOWN
	end
end

function UI:queryFriendKSR(bnetIDGameAccount, battleTag)
	if self.friendsWaitForResp[battleTag] == nil then
		BNSendGameData(bnetIDGameAccount, KSR_PREFIX, KSR_MSGQUERYKSR)
		self.friendsWaitForResp[battleTag] = { bnetIDGameAccount = bnetIDGameAccount, ts = GetTime() }
	end
end

function UI:onTimerQuery()
	local currTime = GetTime()

	for battleTag, data in pairs(self.friendsWaitForResp) do
		local elapsed = math.floor(currTime - data.ts + 0.5)
		if elapsed > MAX_QUERY_RETRY * INTERVAL_QUERY_RETRY then
			self.friendsWaitForResp[battleTag] = nil
			self:updateFriendPanel(battleTag)
		elseif elapsed ~= 0 and elapsed % INTERVAL_QUERY_RETRY == 0 then
			BNSendGameData(data.bnetIDGameAccount, KSR_PREFIX, KSR_MSGQUERYKSR)
		end
	end
end

function UI:updateFriendKeys(battleTag, dataver, keys)
	self.friendsHasKSR[battleTag] = { ver = dataver, keys = keys, w = date("%A"), t = date("%H:%M:%S") }
	self.friendsWaitForResp[battleTag] = nil
	self:updateFriendPanel(battleTag)
end

function UI:applyFilters(textSearch, theBattleTag)

	local strfind = strfind

	local function isWordInStrings(word, strings)
		if word == nil or word == "" or #strings == 0 then return false end

		local lowerWord = string.lower(word)
		for i = 1, #strings do
			if strings[i] ~= nil and strings[i] ~= "" and strfind(strings[i], word) then
				return true
			end
		end
		return false
	end

	local function safeLower(str)
		if str ~= nil and str ~= "" then
			return string.lower(str)
		else
			return ""
		end
	end

	--------

	if theBattleTag == nil then
		wipe(self.filteredData)
	end

	if textSearch == "" then return end
	local terms = { strsplit(" ", textSearch) }
	if #terms == 0 then return end

	for i = 1, #self.friendsData do
		local data = self.friendsData[i]

		if theBattleTag == nil or theBattleTag == data.battleTag then
			local strings = { safeLower(data.battleTagWOHashTag), safeLower(data.characterName), safeLower(data.realmName), safeLower(data.class), safeLower(data.noteText) }
			local isValid = true
			for k = 1, #terms do
				if not isWordInStrings(terms[k], strings) then
					isValid = false
					break
				end
			end

			if isValid and theBattleTag == nil then
				table.insert(self.filteredData, data)
			elseif theBattleTag ~= nil then
				for k = 1, #self.filteredData do
					if self.filteredData[k].battleTag == theBattleTag and isValid then
						self.filteredData[k] = data
						return "IUF_UPDATE"
					elseif self.filteredData[k].battleTag == theBattleTag and not isValid then
						table.remove(self.filteredData, k)
						return "IUF_DELETE"
					end
				end

				if isValid then
					table.insert(self.filteredData, data)
					return "IUF_INSERT"
				end
			end
		end
	end
end

function UI:adjustTopindex()
	local dataLen = #self:abstractData()
	if self.friendsFrame.topIndex  - 1 + COUNT_FRIENDSBTN > dataLen then
		self.friendsFrame.topIndex = dataLen - COUNT_FRIENDSBTN + 1
	end
	if self.friendsFrame.topIndex < 0 then
		self.friendsFrame.topIndex = 1
	end
end

function UI:updateFriendsData(theBattleTag)
	local strfind = strfind
	wipe(self.friendsData)

	local numBNetTotal, numBNetOnline = BNGetNumFriends()

	-- Enum BNet Friends
	for i = 1, numBNetTotal do
		local pid, accountName, battleTag, isBattleTag, characterName, bnetIDGameAccount, client, isOnline, lastOnline, isBnetAFK, isBnetDND, messageText, noteText, isRIDFriend, messageTime = BNGetFriendInfo(i)
		local realmName, realmID, faction, race, class, guild, zoneName, level, gameText, broadcastText, broadcastTime, bnetIDAccount, isGameAFK, isGameBusy, GUID
		if isOnline then
			_, _, _, realmName, realmID, faction, race, class, guild, zoneName, level, gameText, broadcastText, broadcastTime, _, _, bnetIDAccount, isGameAFK, isGameBusy, GUID = BNGetGameAccountInfo(bnetIDGameAccount)
		end
		local battleTagWOHashTag = ""
		if battleTag ~= "" then
			battleTagWOHashTag = string.sub(battleTag, 1, strfind(battleTag, "#") - 1)
		end
		local newFDEntry = { ID = i, pid = pid, accountName = accountName, battleTag = battleTag, battleTagWOHashTag = battleTagWOHashTag, isBattleTag = isBattleTag,
			characterName = characterName, bnetIDGameAccount = bnetIDGameAccount, client = client, isOnline = isOnline, lastOnline = lastOnline, isBnetAFK = isBnetAFK, isBnetDND = isBnetDND, noteText = noteText,
			realmName = realmName, realmID = realmID, faction = faction, race = race, class = class, zoneName = zoneName, level = level, gameText = gameText,
			bnetIDAccount = bnetIDAccount, isGameAFK = isGameAFK, isGameBusy = isGameBusy, GUID = GUID
		}
		table.insert(self.friendsData, newFDEntry)

		-- Query friend's KSR status
		if isOnline and client == BNET_CLIENT_WOW and (theBattleTag == nil or theBattleTag == battleTag) then
			self:queryFriendKSR(bnetIDGameAccount, battleTag)
		end
	end
end

function UI:abstractData()
	if #self.filteredData == 0 and self:getFriendSearchBoxText() == "" then
		return self.friendsData
	else
		return self.filteredData
	end
end

function UI:clearSelection()
	self.friendsFrame.selection.pid = 0
	self.friendsFrame.selection.battleTag = ""
	self.friendsFrame.selection.accName = ""
	self.friendsFrame.selection.gameAccountID = 0
	self.friendsFrame.selection.guid = ""
end

------ interactivation actions ------

function UI:whisperToSelection()
	local selAccName = self.friendsFrame.selection.accName
	if selAccName ~= nil and selAccName ~= "" then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		ChatFrame_SendSmartTell(selAccName)
	end
end

function UI:inviteSelection()
	local selGUID = self.friendsFrame.selection.guid
	local selGameAccountID = self.friendsFrame.selection.gameAccountID
	if selGUID == nil or selGUID == "" or selGameAccountID == nil or selGameAccountID == 0 then return end

	local inviteType = GetDisplayedInviteType(selGUID)
	if inviteType == "INVITE" or inviteType == "SUGGEST_INVITE" then
		BNInviteFriend(selGameAccountID)
	elseif inviteType == "REQUEST_INVITE" then
		BNRequestInviteFriend(selGameAccountID)
	end
end

function UI:reportKeysToSelection()
	local selPID = self.friendsFrame.selection.pid
	if selPID == nil or selPID == 0 then return end

	self.ksr:announceAllKeystones("BN_WHISPER", selPID, false)
end

function UI:refreshKeysOfSelection()
	local selGameAccountID = self.friendsFrame.selection.gameAccountID
	local selBattleTag = self.friendsFrame.selection.battleTag
	if selGameAccountID == nil or selGameAccountID == 0 or self.friendsHasKSR[selBattleTag] == nil then return end

	BNSendGameData(selGameAccountID, KSR_PREFIX, KSR_MSGQUERYKSR)
end

------ UI Actions ------

function UI:getFriendSearchBoxText()
	return trim(string.lower(self.friendsFrame.edtSearch:GetText()))
end

function UI:highlightFriendsBtn(btnidx, state)
	local btn = self.friendsBtns[btnidx]
	if state then
		local prevHLBtn = self.friendsFrame.prevHLBtn
		if prevHLBtn ~= nil then
			prevHLBtn:UnlockHighlight()
		end
		btn:LockHighlight()
		self.friendsFrame.prevHLBtn = btn
	else
		btn:UnlockHighlight()
	end
end

function UI:setFontSize(obj, size)
	local fontName, fontSize, fontFlags = obj:GetFont()
	obj:SetFont(fontName, size, fontFlags)
end

function UI:updateFriendPanel(theBattleTag)

	local function updateStrName(obj, data)
		obj:SetText(self:getNameFromData(data))
	end
	
	local function updateStrInfo(obj, data)
		local infoText
		if data.isOnline and data.client == BNET_CLIENT_WOW then
			local zoneName = data.zoneName
			if zoneName == nil or zoneName == "" then zoneName = UNKNOWN end
			infoText = zoneName.." "..string.format(FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE, "", data.level, data.race, data.class)
		elseif data.isOnline then
			infoText = FRIENDS_GRAY_COLOR..data.gameText..FONT_COLOR_CODE_CLOSE
		else
			infoText = FRIENDS_GRAY_COLOR..self:getOfflineFromData(data)..FONT_COLOR_CODE_CLOSE
		end
		obj:SetText(infoText)
	end

	local function displayFriendStatus(data, friendKey, friendWFR)
		-- todo: localization
		if friendKey ~= nil then
			if friendKey.keys == nil then return end
			local keys = { strsplit("\n", friendKey.keys) }
			for i = 1, #keys do
				if keys[i] ~= "" then
					self.friendsFrame.smfKeys:BackFillMessage(keys[i])
				end
			end
			local currW = date("%A")
			local w = ""
			if friendKey.w ~= currW then
				w = friendKey.w.." "
			end
			self.friendsFrame.smfKeys:BackFillMessage(COMMENT_COLOR..string.format("Updated at: %s%s", w, friendKey.t)..FONT_COLOR_CODE_CLOSE)
			self.friendsFrame.smfKeys:ScrollToBottom()
		elseif data.client ~= BNET_CLIENT_WOW then
			self.friendsFrame.smfKeys:BackFillMessage(COMMENT_COLOR.."Not playing WOW"..FONT_COLOR_CODE_CLOSE)
		elseif friendWFR ~= nil then
			self.friendsFrame.smfKeys:BackFillMessage(COMMENT_COLOR.."Wait for response"..FONT_COLOR_CODE_CLOSE)
		else
			self.friendsFrame.smfKeys:BackFillMessage(COMMENT_COLOR.."Not installed"..FONT_COLOR_CODE_CLOSE)
		end
	end

	local selBattleTag = self.friendsFrame.selection.battleTag
	local abstractData = self:abstractData()
	local data
	for i = 1, #abstractData do
		if abstractData[i].battleTag == selBattleTag then
			data = abstractData[i]
			break
		end
	end
	
	-- visible
	if selBattleTag == "" or data == nil then
		self.friendsFrame.strName:Hide()
		self.friendsFrame.strInfo:Hide()
		self.friendsFrame.btnWhisper:Hide()
		self.friendsFrame.btnInvite:Hide()
		self.friendsFrame.btnReportKeys:Hide()
		self.friendsFrame.btnQueryKeys:Hide()
		self.friendsFrame.btnQueryDGInfo:Hide()
		self.friendsFrame.smfKeys:Hide()
		return
	elseif theBattleTag ~= nil and selBattleTag ~= theBattleTag then
		return
	else
		self.friendsFrame.strName:Show()
		self.friendsFrame.strInfo:Show()
		self.friendsFrame.btnWhisper:Show()
		self.friendsFrame.btnInvite:Show()
		self.friendsFrame.btnReportKeys:Show()
		self.friendsFrame.btnQueryKeys:Show()
		self.friendsFrame.btnQueryDGInfo:Show()
		self.friendsFrame.smfKeys:Show()
	end

	-- enable & content
	updateStrName(self.friendsFrame.strName, data)
	updateStrInfo(self.friendsFrame.strInfo, data)
	local friendKey = self.friendsHasKSR[selBattleTag]
	local friendWFR = self.friendsWaitForResp[selBattleTag]
	self.friendsFrame.smfKeys:Clear()
	if data.isOnline then
		self.friendsFrame.btnWhisper:Enable()
		if (data.client == BNET_CLIENT_WOW) and (self.playerFaction == data.faction) then
			self.friendsFrame.btnInvite:Enable()
		else
			self.friendsFrame.btnInvite:Disable()
		end
		self.friendsFrame.btnReportKeys:Enable()
		if (data.client == BNET_CLIENT_WOW) and (friendKey ~= nil) then
			self.friendsFrame.btnQueryKeys:Enable()
			self.friendsFrame.btnQueryDGInfo:Enable()
		else
			self.friendsFrame.btnQueryKeys:Disable()
			self.friendsFrame.btnQueryDGInfo:Disable()
		end
		displayFriendStatus(data, friendKey, friendWFR)
	else
		self.friendsFrame.btnWhisper:Disable()
		self.friendsFrame.btnInvite:Disable()
		self.friendsFrame.btnReportKeys:Disable()
		self.friendsFrame.btnQueryKeys:Disable()
		self.friendsFrame.btnQueryDGInfo:Disable()
	end
end

function UI:selectFriendByIndex(btnidx, theBattleTag)

	function isSelectionInFiltered()
		local selBattleTag = self.friendsFrame.selection.battleTag
		if #self.filteredData == 0 or selBattleTag == "" then
			return false
		end
		for i = 1, #self.filteredData do
			if self.filteredData[i].battleTag == selBattleTag then return true end
		end
		return false
	end

	if btnidx == 0 and not isSelectionInFiltered() then
		btnidx =1
	elseif btnidx == 0 then
		self:updateFriendPanel(theBattleTag)
		return
	end

	local idx = self.friendsFrame.topIndex + btnidx - 1
	local abstractData = self:abstractData()
	if idx > #abstractData then
		-- assert here
		self:clearSelection()
		return
	end

	local data = abstractData[idx]
	self.friendsFrame.selection.pid = data.pid
	self.friendsFrame.selection.battleTag = data.battleTag
	self.friendsFrame.selection.accName = data.accountName
	self.friendsFrame.selection.gameAccountID = data.bnetIDGameAccount
	self.friendsFrame.selection.guid = data.GUID

	self:highlightFriendsBtn(btnidx, true)
	self:updateFriendPanel(theBattleTag)
end

function UI:updateFriendsBtns()

	local function updateBtnDrawings(data, btn)
		-- icons & background
		if data.isOnline then
			if data.isBnetAFK or data.isGameAFK then
				btn.iconStatus:SetTexture(FRIENDS_TEXTURE_AFK)
			elseif data.isBnetDND or data.isGameBusy then
				btn.iconStatus:SetTexture(FRIENDS_TEXTURE_DND)
			else
				btn.iconStatus:SetTexture(FRIENDS_TEXTURE_ONLINE)
			end
			btn.iconClient:SetTexture(BNet_GetClientTexture(data.client))
			btn.iconClient:Show()
			btn.t:SetColorTexture(FRIENDS_BNET_BACKGROUND_COLOR.r, FRIENDS_BNET_BACKGROUND_COLOR.g, FRIENDS_BNET_BACKGROUND_COLOR.b, FRIENDS_BNET_BACKGROUND_COLOR.a)
		else
			btn.iconStatus:SetTexture(FRIENDS_TEXTURE_OFFLINE)
			btn.iconClient:Hide()
			btn.t:SetColorTexture(FRIENDS_OFFLINE_BACKGROUND_COLOR.r, FRIENDS_OFFLINE_BACKGROUND_COLOR.g, FRIENDS_OFFLINE_BACKGROUND_COLOR.b, FRIENDS_OFFLINE_BACKGROUND_COLOR.a)
		end

		if data.battleTag == self.friendsFrame.selection.battleTag then
			self:highlightFriendsBtn(btn.index, true)
		else
			self:highlightFriendsBtn(btn.index, false)
		end
	end

	local function updateBtnName(data, btn)
		btn.strName:SetText(self:getNameFromData(data))
	end

	local function updateBtnInfo(data, btn)
		local btnInfoText

		if data.isOnline then
			if data.client == BNET_CLIENT_WOW then
				if data.zoneName and data.zoneName ~= "" then
					btnInfoText = data.zoneName
				else
					btnInfoText = UNKNOWN
				end
			else
				btnInfoText = data.gameText
			end
		else
			btnInfoText = self:getOfflineFromData(data)
		end
		btnInfoText = FRIENDS_GRAY_COLOR..btnInfoText..FONT_COLOR_CODE_CLOSE
		btn.strInfo:SetText(btnInfoText)
	end

	-- end of inner functions

	local abstractData = self:abstractData()

	for i = 1, COUNT_FRIENDSBTN do
		local btn = self.friendsBtns[i]
		if i > #abstractData then
			btn:Hide()
		else
			btn:Show()
			local data = abstractData[i + self.friendsFrame.topIndex - 1]
			updateBtnDrawings(data, btn)
			updateBtnName(data, btn)
			updateBtnInfo(data, btn)
		end
	end
end

function UI:updateFriendsFrame(theBattleTag)
	self:updateFriendsData(theBattleTag)
	local textSearch = self:getFriendSearchBoxText()
	if textSearch ~= "" then
		self:applyFilters(textSearch, theBattleTag)
		self:adjustTopindex()
		self:selectFriendByIndex(0, theBattleTag)
	end
	self:updateFriendsBtns()
end

-- components evnet handlers

function UI:onFriendSearch(textSearch)
	self:applyFilters(textSearch)
	self:adjustTopindex()
	self:selectFriendByIndex(0)
	self:updateFriendsBtns()
end

function UI:onScrollFriendsList(delta)
	local abstractData = self:abstractData()

	if #abstractData <= COUNT_FRIENDSBTN then return end

	if delta < 0 then
		if self.friendsFrame.topIndex + COUNT_FRIENDSBTN <= #abstractData then
			self.friendsFrame.topIndex = self.friendsFrame.topIndex + 1
			self:updateFriendsBtns()
		end
	else
		if self.friendsFrame.topIndex > 1 then
			self.friendsFrame.topIndex = self.friendsFrame.topIndex - 1
			self:updateFriendsBtns()
		end
	end
end

function UI:onKeyDown(obj, key)
	
	local function ignoreLR(key)
		return string.sub(key, 2, string.len(key))
	end

	if string.len(key) < 4 then return end
	local currTime = GetTime()
	
	if self.prevKey.key == key and currTime - self.prevKey.ts <= INTERVAL_HOTKEY then
		local ikey = ignoreLR(key)
		if ikey == "CTRL" then
			self.friendsFrame.edtSearch:SetFocus()
		elseif ikey == "ALT" then
			self:whisperToSelection()
		elseif key == "INSERT" then
			self:inviteSelection()
		elseif key == "DELETE" then
			self.friendsFrame.edtSearch:SetText("")
			self:onFriendSearch(self:getFriendSearchBoxText())
		else
			self.prevKey.key = key
			self.prevKey.ts = currTime
		end
	else
		self.prevKey.key = key
		self.prevKey.ts = currTime
	end
end

function UI:createFriendsButtons(parent)
	for i = 1, COUNT_FRIENDSBTN do
		local friendBtn = CreateFrame("BUTTON", nil, parent)
		friendBtn:SetSize(WIDTH_FRIENDSBTN, HEIGHT_FRIENDSBTN)
		friendBtn:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", 0, -i * HEIGHT_FRIENDSBTN + OFFSET_Y_FRIENDSBTN)
		friendBtn.t = friendBtn:CreateTexture(nil, "BACKGROUND")
		friendBtn.t:SetSize(WIDTH_FRIENDSBTN, HEIGHT_FRIENDSBTN - 1)
		friendBtn.t:SetPoint("CENTER", friendBtn, "CENTER")
		friendBtn.t:SetColorTexture(0.2, 0.2, 0.6)
		friendBtn.hl = friendBtn:CreateTexture(nil, "HIGHLIGHT")
		friendBtn.hl:SetSize(WIDTH_FRIENDSBTN, HEIGHT_FRIENDSBTN - 2)
		friendBtn.hl:SetPoint("CENTER", friendBtn, "CENTER")
		friendBtn.hl:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
		friendBtn.hl:SetVertexColor(0.243, 0.570, 1)
		friendBtn:SetHighlightTexture(friendBtn.hl)
		friendBtn.iconStatus = friendBtn:CreateTexture(nil, "ARTWORK")
		friendBtn.iconStatus:SetSize(16, 16)
		friendBtn.iconStatus:SetPoint("TOPLEFT", friendBtn, "TOPLEFT", 4, -3)
		friendBtn.iconStatus:SetTexture(FRIENDS_TEXTURE_ONLINE)
		friendBtn.iconClient = friendBtn:CreateTexture(nil, "ARTWORK")
		friendBtn.iconClient:SetSize(28, 28)
		friendBtn.iconClient:SetPoint("TOPRIGHT", friendBtn, "TOPRIGHT", -1, -3)
		friendBtn.iconClient:SetTexture("Interface\\FriendsFrame\\Battlenet-WoWicon")
		friendBtn.strName = friendBtn:CreateFontString(nil, "ARTWORK", "FriendsFont_Normal")
		friendBtn.strName:SetSize(226, 12)
		friendBtn.strName:SetPoint("TOPLEFT", friendBtn, "TOPLEFT", 20, -4)
		friendBtn.strName:SetJustifyH("LEFT")
		friendBtn.strName:SetText("NAME")
		friendBtn.strInfo = friendBtn:CreateFontString(nil, "ARTWORK", "FriendsFont_Small")
		friendBtn.strInfo:SetSize(260, 10)
		friendBtn.strInfo:SetPoint("TOPLEFT", friendBtn.strName, "BOTTOMLEFT", 0, -3)
		friendBtn.strInfo:SetJustifyH("LEFT")
		friendBtn.strInfo:SetText("INFO")
		friendBtn.index = i
		friendBtn:SetScript("OnMouseUp", function(obj, button)
				self:selectFriendByIndex(obj.index)
				if button == "RightButton" then
					self:inviteSelection()
				end
			end)
		friendBtn:SetScript("OnDoubleClick", function(obj) self:whisperToSelection() end)
		friendBtn:SetScript("OnMouseWheel", function(obj, delta) self:onScrollFriendsList(delta) end)
		table.insert(self.friendsBtns, friendBtn)
	end
end

function UI:createFriendTBBtn(offsetX, strTexture, tooltip, parent)
	local btn = CreateFrame("BUTTON", nil, parent)
	local offsetY = -EDGE_SIZE * 6
	btn:SetSize(WIDTH_BUTTON, HEIGHT_BUTTON)
	btn:SetPoint("TOPLEFT", parent, "TOPLEFT", OFFSET_X_FRIENDSINFO + offsetX, offsetY)
	btn:SetNormalTexture(strTexture..BTN_TEXTURE_SUFFIX_NML)
	btn:SetHighlightTexture(strTexture..BTN_TEXTURE_SUFFIX_NML)
	btn:SetPushedTexture(strTexture..BTN_TEXTURE_SUFFIX_PSH)
	btn:SetDisabledTexture(strTexture..BTN_TEXTURE_SUFFIX_DIS)
	btn.tooltip = tooltip
	return btn
end

function UI:createSubFrame(parent, name)
	local sf = CreateFrame("FRAME", name, parent)
	sf:SetSize(WIDTH_SUBFRAME, HEIGHT_SUBFRAME)
	sf:SetPoint("TOPLEFT", parent, "TOPLEFT", EDGE_SIZE, -EDGE_SIZE)
	sf.topIndex = 1
	sf.selection = { pid = 0, battleTag = "", accName = "", gameAccountID = 0, guid = "" }
	sf.prevHLBtn = nil
	sf.t = sf:CreateTexture(nil, "BACKGROUND")
	sf.t:SetSize(WIDTH_SUBFRAME, HEIGHT_SUBFRAME)
	sf.t:SetPoint("CENTER", sf, "CENTER")
	sf.t:SetColorTexture(0.5, 0.5, 0.5, 0)

	sf.edtSearch = CreateFrame("EditBox", nil, sf)
	sf.edtSearch:SetSize(WIDTH_FRIENDSBTN, HEIGHT_SEARCHBOX)
	sf.edtSearch:SetPoint("TOPLEFT", sf, "TOPLEFT", 0, OFFSET_Y_SEARCHBOX)
	sf.edtSearch:SetFontObject(ChatFontNormal)
	sf.edtSearch:SetMaxBytes(128)
	sf.edtSearch:SetAutoFocus(false)
	sf.edtSearch:SetBackdrop({
		bgFile = nil, edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
		tile = true, tileSize = 16, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}})
	sf.edtSearch:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.3)
	local l, r, t, b = sf.edtSearch:GetTextInsets()
	sf.edtSearch:SetTextInsets(22, r, t, b)
	sf.edtSearch.iconSearch = sf.edtSearch:CreateTexture(nil, "ARTWORK")
	sf.edtSearch.iconSearch:SetSize(14, 14)
	sf.edtSearch.iconSearch:SetPoint("TOPLEFT", sf.edtSearch, "TOPLEFT", 6, -6)
	sf.edtSearch.iconSearch:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
	sf.edtSearch:SetScript("OnEnterPressed", function(obj) obj:ClearFocus() end)
	sf.edtSearch:SetScript("OnEscapePressed", function(obj) obj:ClearFocus() end)
	sf.edtSearch:SetScript("OnChar", function(obj) self:onFriendSearch(self:getFriendSearchBoxText()) end)
	sf.edtSearch:SetScript("OnKeyDown", function(obj, key) self:onKeyDown(obj, key) end)
	sf.edtSearch:SetScript("OnKeyUp", function(obj, key) if key == "DELETE" or key == "BACKSPACE" then self:onFriendSearch(self:getFriendSearchBoxText()) end end)
	-- todo: relative layout
	-- sf.iconCurr = sf:CreateTexture(nil, "ARTWORK")
	-- sf.iconCurr:SetSize(32, 32)
	-- sf.iconCurr:SetPoint("TOPLEFT", sf, "TOPLEFT", OFFSET_X_FRIENDSINFO, -EDGE_SIZE)
	-- sf.iconCurr:SetTexture("Interface\\FriendsFrame\\Battlenet-WoWicon")
	sf.strName = sf:CreateFontString(nil, "ARTWORK")
	sf.strName:SetFontObject(ChatFontNormal)
	self:setFontSize(sf.strName, 16)
	sf.strName:SetSize(WIDTH_SMF, 16)
	sf.strName:SetPoint("TOPLEFT", sf, "TOPLEFT", OFFSET_X_FRIENDSINFO, OFFSET_Y_SEARCHBOX - 4)
	sf.strName:SetJustifyH("LEFT")
	sf.strName:SetText("NAME")
	sf.strInfo = sf:CreateFontString(nil, "ARTWORK")
	sf.strInfo:SetFontObject(ChatFontNormal)
	self:setFontSize(sf.strInfo, 14)
	sf.strInfo:SetSize(WIDTH_SMF, 14)
	sf.strInfo:SetPoint("TOPLEFT", sf.strName, "BOTTOMLEFT", 0, -12)
	sf.strInfo:SetJustifyH("LEFT")
	sf.strInfo:SetText("INFO")

	-- todo: localization
	sf.btnWhisper = self:createFriendTBBtn((WIDTH_BUTTON + MARGIN_BUTTON) * 0, BTN_WHISPER_TEXTURE, "WHISPER", sf)
	sf.btnWhisper:SetScript("OnClick", function(obj) self:whisperToSelection() end)
	sf.btnInvite = self:createFriendTBBtn((WIDTH_BUTTON + MARGIN_BUTTON) * 1, BTN_INVITE_TEXTURE, "INVITE", sf)
	sf.btnInvite:SetScript("OnClick", function(obj) self:inviteSelection() end)
	sf.btnReportKeys = self:createFriendTBBtn((WIDTH_BUTTON + MARGIN_BUTTON) * 2, BTN_REPORTKEYS_TEXTURE, "REPORTKEYS", sf)
	sf.btnReportKeys:SetScript("OnClick", function(obj) self:reportKeysToSelection() end)
	sf.btnQueryKeys = self:createFriendTBBtn((WIDTH_BUTTON + MARGIN_BUTTON) * 3, BTN_QUERYKEYS_TEXTURE, "QUERYKEYS", sf)
	sf.btnQueryKeys:SetScript("OnClick", function(obj) self:refreshKeysOfSelection() end)
	sf.btnQueryDGInfo = self:createFriendTBBtn((WIDTH_BUTTON + MARGIN_BUTTON) * 4, BTN_QUERYDGINFO_TEXTURE, "QUERYDGINFO", sf)

	sf.smfKeys = CreateFrame("ScrollingMessageFrame", nil, sf)
	sf.smfKeys:SetSize(WIDTH_SMF, 375)
	sf.smfKeys:SetPoint("TOPLEFT", sf.btnWhisper, "BOTTOMLEFT", 0, -EDGE_SIZE * 2)
	sf.smfKeys:SetFontObject(ChatFontNormal)
	self:setFontSize(sf.smfKeys, 16)
	sf.smfKeys:SetInsertMode(1)
	sf.smfKeys:SetJustifyH("LEFT")
	sf.smfKeys:SetFading(false)
	sf.smfKeys:SetSpacing(2)
	sf.smfKeys:SetIndentedWordWrap(true)
	sf.smfKeys:SetScript("OnMouseWheel", function(obj, delta)
			if delta < 0 then
				self.friendsFrame.smfKeys:ScrollUp()
			else
				self.friendsFrame.smfKeys:ScrollDown()
			end
		end)

	return sf
end

function UI:createMainFrame()
	local mf = CreateFrame("FRAME", "KeystoneRunnerMainFrame", UIParent)
	mf:Hide()
	mf:SetFrameStrata("DIALOG")
	mf:SetSize(WIDTH_FRAME, HEIGHT_FRAME)
	mf:SetPoint("CENTER", UIParent, "CENTER")
	mf:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = {left = 4, right = 4, top = 4, bottom = 4}})
	mf:SetBackdropColor(0, 0, 0, 1)
	mf:SetMovable(true)
	mf:RegisterForDrag("LeftButton")
	mf:EnableMouse(true)
	mf:EnableKeyboard(true)
	mf:SetPropagateKeyboardInput(true)
	mf:SetClampedToScreen(true)
	-- init components which parent is mainFrame
	mf.title = mf:CreateFontString(nil, "ARTWORK")
	mf.title:SetFontObject(GameFontNormalLarge)
	mf.title:SetSize(WIDTH_SUBFRAME, 14)
	mf.title:SetPoint("TOPLEFT", mf, "TOPLEFT", EDGE_SIZE, -EDGE_SIZE)
	mf.title:SetJustifyH("LEFT")
	mf.title:SetText(KSR_STD_TITLE)
	mf.btnClose = CreateFrame("BUTTON", nil, mf, "UIPanelCloseButtonNoScripts")
	mf.btnClose:SetPoint("TOPRIGHT", mf, "TOPRIGHT", -10, -10)
	mf.btnClose:SetScript("OnClick", function(obj) self.mainFrame:Hide() end)
	-- Events
	mf:RegisterEvent("BN_FRIEND_LIST_SIZE_CHANGED")
	mf:SetScript("OnShow", function(obj)
			self:updateFriendsFrame()
			obj:RegisterEvent("BN_FRIEND_INFO_CHANGED")
			obj:SetPropagateKeyboardInput(true)
			PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
		end)
	mf:SetScript("OnHide", function(obj)
			PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
			obj:SetPropagateKeyboardInput(false)
			obj:UnregisterEvent("BN_FRIEND_INFO_CHANGED")
		end)
	mf:SetScript("OnEvent", function(obj, event, ...)
			if event == "BN_FRIEND_LIST_SIZE_CHANGED" then
				self.friendsFrame.edtSearch:SetText("")
				self:selectFriendByIndex(1)
				self:updateFriendsFrame()
			elseif event == "BN_FRIEND_INFO_CHANGED" then
				local index = ...
				if index == nil or index == 0 then return end
				local _, _, theBattleTag = BNGetFriendInfo(index)
				self:updateFriendsFrame(theBattleTag)
			end
		end)
	mf:SetScript("OnKeyDown", function(obj, key)
			if key == "ESCAPE" then
				obj:Hide()
			else
				self:onKeyDown(obj, key)
			end 
		end)
	mf:SetScript("OnDragStart", function(obj) obj:StartMoving() end)
	mf:SetScript("OnDragStop", function(obj) obj:StopMovingOrSizing() end)
	return mf
end
