local UI = {}
_KSRGlobal.UI = UI

local L = _KSRGlobal.L
local KSR_PREFIX = _KSRGlobal.Prefix
local KSR_DATA_VER = _KSRGlobal.DataVer
local KSR_MSGQUERYKSR = _KSRGlobal.MsgQueryKSR
local KSR_MSGSEP = _KSRGlobal.MsgSep
local KSR_HEADERREPLYKEYS = _KSRGlobal.MsgHeaderReplyKeys
local KSR_MSGREPLYKEYS = _KSRGlobal.MsgReplyKeys
local KSR_STD_TITLE = _KSRGlobal.StdTitle

local MAX_QUERY_RETRY = 3
local INTERVAL_QUERY_RETRY = 2
local INTERVAL_HOTKEY = 0.35

local COUNT_FRIENDSBTN = 14

-- sizes for adpative layout
local WIDTH_FRAME = 770
local HEIGHT_FRAME = 566
local EDGE_SIZE = 16
local HEIGHT_TITLE = 28
local WIDTH_FRIENDSBTN = 300
local HEIGHT_FRIENDSBTN = 34
local MARGIN_PANEL_COLUMNS = EDGE_SIZE * 2
local WIDTH_FRIEND_TB_BUTTON = 64
local HEIGHT_FRIEND_TB_BUTTON = 64
local MARGIN_FRIEND_TB_BUTTON = 12
local MAX_BTNWITDH = 200

local WIDTH_MYKEYS_BTN = 150
local HEIGHT_MYKEYS_BTN = 23
local MARGIN_MYKEYS_BTN = 10

-- textures and colors
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
local FRIENDS_BNET_BACKGROUND_COLOR = { r=0, g=0.694, b=0.941, a=0.05 }
local FRIENDS_OFFLINE_BACKGROUND_COLOR = { r=0.588, g=0.588, b=0.588, a=0.05 }

local BTN_INVITE_TEXTURE = "Interface\\AddOns\\KeystoneRunner\\media\\btnInvite"
local BTN_WHISPER_TEXTURE = "Interface\\AddOns\\KeystoneRunner\\media\\btnWhisper"
local BTN_REPORTKEYS_TEXTURE = "Interface\\AddOns\\KeystoneRunner\\media\\btnReportKeys"
local BTN_QUERYKEYS_TEXTURE = "Interface\\AddOns\\KeystoneRunner\\media\\btnQueryKeys"
local BTN_QUERYDGINFO_TEXTURE = "Interface\\AddOns\\KeystoneRunner\\media\\btnQueryDGInfo"
local BTN_TEXTURE_SUFFIX_NML = "_NML.tga"
local BTN_TEXTURE_SUFFIX_DIS = "_DIS.tga"
local BTN_TEXTURE_SUFFIX_PSH = "_PSH.tga"
local CLASS_ICONS = "Interface\\AddOns\\KeystoneRunner\\media\\ClassIcon_%s.tga"

-- StaticPopup
	-- ref:
		-- function StaticPopup_Show(which, text_arg1, text_arg2, data, insertedFrame)
		-- OnAccept(dialog, dialog.data, dialog.data2)
StaticPopupDialogs["KSR_CONFIRM_REPORTKEYS"] = {
	text = "",
	button1 = OKAY,
	button2 = CANCEL,
	OnAccept = function(self, data)
			if data.ksr == nil or data.pid == nil or data.pid == 0 then return end
			data.ksr:announceAllKeystones("BN_WHISPER", data.pid)
		end,
	exclusive = 1,
	hideOnEscape = 1,
}

-- init

function UI:init(ksr)
	self.ksr = ksr
	self.friendsData = {}
	self.friendsBtns = {}
	self.filteredData = {}
	self.friendsHasKSR = {}
	self.friendsWaitForResp = {}
	self.classLookup = {}
	local classL = {}
	FillLocalizedClassList(classL)
	for k, v in pairs(classL) do
		self.classLookup[v] = k
	end
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
	self.friendsFrame = self:createSubFrame_Friends(self.mainFrame)
	table.insert(self.mainFrame.tabPages, self.friendsFrame)
	self.mykeysFrame = self:createSubFrame_Mykeys(self.mainFrame)
	table.insert(self.mainFrame.tabPages, self.mykeysFrame)
	
	self.timerQuery = C_Timer.NewTicker(1, function() self:onTimerQuery() end)
	StaticPopupDialogs["KSR_CONFIRM_REPORTKEYS"].text = L["msgConfirmReportKeys"]
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

	if data.isOnline and data.client == BNET_CLIENT_WOW and self.playerFaction == data.faction then
		local colorCode
		if self.ksr ~= nil and self.ksr.Settings.renderNameWClassColor and data.classE ~= nil then
			colorCode = "|c"..RAID_CLASS_COLORS[data.classE].colorStr
		else
			colorCode = FRIENDS_WOW_NAME_COLOR_CODE
		end
		return accName.." "..colorCode.."("..charName..")"..FONT_COLOR_CODE_CLOSE
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

function UI:updateMyKeys()
	if self.ksr == nil then return end
	local keysText = self.ksr:textOfAllKeystones()
	if keysText == nil or keysText == "" then return end
	local keys = { strsplit("\n", keysText) }
	self.mykeysFrame.smfKeys:Clear()
	self.mykeysFrame.smfKeys:AddMessage(COMMENT_COLOR..L["strMyKeystones"]..FONT_COLOR_CODE_CLOSE)
	for i = 1, #keys do
		if keys[i] ~= "" then
			self.mykeysFrame.smfKeys:AddMessage("    "..keys[i])
		end
	end
	self.mykeysFrame.smfKeys:ScrollToBottom()
end

-- data operations

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
			local strings = { safeLower(data.battleTagWOHashTag), safeLower(data.characterName), safeLower(data.zoneName), safeLower(data.noteText) }
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
					if self.filteredData[k].battleTag == theBattleTag then
						if  isValid then
						    -- only a placeholder
							self.filteredData[k] = data
							return "IUF_UPDATE"
						else
							table.remove(self.filteredData, k)
							return "IUF_DELETE"
						end
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
	if self.friendsFrame.topIndex <= 0 then
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
		local classE = self.classLookup[class]
		if isOnline and client == BNET_CLIENT_WOW and classE == nil then
			-- assert here
			-- print("bt, charName, class, isOnline: ", battleTag, characterName, class, isOnline)
			-- print(classE.a)
		end
		local newFDEntry = { ID = i, pid = pid, accountName = accountName, battleTag = battleTag, battleTagWOHashTag = battleTagWOHashTag, isBattleTag = isBattleTag,
			characterName = characterName, bnetIDGameAccount = bnetIDGameAccount, client = client, isOnline = isOnline, lastOnline = lastOnline, isBnetAFK = isBnetAFK, isBnetDND = isBnetDND, noteText = noteText,
			realmName = realmName, realmID = realmID, faction = faction, race = race, class = class, classE = classE, zoneName = zoneName, level = level, gameText = gameText,
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
	if inviteType == "INVITE" then
		print(string.format(L["msgInviteSelFriend"], self.friendsFrame.selection.accName))
		BNInviteFriend(selGameAccountID)
	elseif inviteType == "SUGGEST_INVITE" then
		print(string.format(L["msgSuggestInviteSelFriend"], self.friendsFrame.selection.accName))
		BNInviteFriend(selGameAccountID)
	elseif inviteType == "REQUEST_INVITE" then
		print(string.format(L["msgRequestInviteSelFriend"], self.friendsFrame.selection.accName))
		BNRequestInviteFriend(selGameAccountID)
	end
end

function UI:reportKeysToSelection()
	local selPID = self.friendsFrame.selection.pid
	if self.ksr == nil or selPID == nil or selPID == 0 then return end

	self.ksr:announceAllKeystones("BN_WHISPER", selPID)
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

function UI:updateFriendPanel(theBattleTag)

	local function updateStrName(obj, data)
		obj:SetText(self:getNameFromData(data))
	end

	local function updateStrInfo(obj, data)
		local infoText
		if data.isOnline and data.client == BNET_CLIENT_WOW then
			local zoneName = data.zoneName
			if zoneName == nil or zoneName == "" then zoneName = UNKNOWN end
			local realmName = data.realmName
			if realmName == nil then realmName = "" end
			infoText = zoneName.." "..realmName.." "..string.format(FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE, "", data.level, data.race, data.class)
		elseif data.isOnline then
			infoText = FRIENDS_GRAY_COLOR..data.gameText..FONT_COLOR_CODE_CLOSE
		else
			infoText = FRIENDS_GRAY_COLOR..self:getOfflineFromData(data)..FONT_COLOR_CODE_CLOSE
		end
		obj:SetText(infoText)
	end

	local function displayFriendStatus(data, friendKey, friendWFR)
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
			self.friendsFrame.smfKeys:BackFillMessage(COMMENT_COLOR..string.format(L["msgFriendStat_Updated"], w, friendKey.t)..FONT_COLOR_CODE_CLOSE)
			self.friendsFrame.smfKeys:ScrollToBottom()
		elseif (not data.isOnline) or (data.client ~= BNET_CLIENT_WOW) then
			self.friendsFrame.smfKeys:BackFillMessage(COMMENT_COLOR..L["msgFriendStat_NotPlayingWoW"]..FONT_COLOR_CODE_CLOSE)
		elseif friendWFR ~= nil then
			self.friendsFrame.smfKeys:BackFillMessage(COMMENT_COLOR..L["msgFriendStat_WFR"]..FONT_COLOR_CODE_CLOSE)
		else
			self.friendsFrame.smfKeys:BackFillMessage(COMMENT_COLOR..L["msgFriendStat_NotInstalled"]..FONT_COLOR_CODE_CLOSE)
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
		self.friendsFrame.smfBase:Hide()
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
		-- self.friendsFrame.btnQueryDGInfo:Show()
		self.friendsFrame.smfBase:Show()
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
		if data.client == BNET_CLIENT_WOW and self.playerFaction == data.faction then
			self.friendsFrame.btnInvite:Enable()
		else
			self.friendsFrame.btnInvite:Disable()
		end
		self.friendsFrame.btnReportKeys:Enable()
		if data.client == BNET_CLIENT_WOW and friendKey ~= nil then
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

	-- try to keep current selection, if selection is in search result, otherwise select idx(1)
	if btnidx == 0 and #self.filteredData ~= 0 and not isSelectionInFiltered() then
		self.friendsFrame.topIndex = 1
		btnidx = 1
	end

	if btnidx ~= 0 then
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
	end
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
			if data.client == BNET_CLIENT_WOW and data.classE ~= nil then
				btn.iconClient:SetTexture(string.format(CLASS_ICONS, data.classE))
			else
				btn.iconClient:SetTexture(BNet_GetClientTexture(data.client))
			end
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
			if i + self.friendsFrame.topIndex - 1 > #abstractData then
				-- assert here
			else
				btn:Show()
				local data = abstractData[i + self.friendsFrame.topIndex - 1]
				updateBtnDrawings(data, btn)
				updateBtnName(data, btn)
				updateBtnInfo(data, btn)
			end
		end
	end
end

function UI:updateFriendsFrame(theBattleTag)
	self:updateFriendsData(theBattleTag)
	local textSearch = self:getFriendSearchBoxText()
	if textSearch ~= "" then
		self:applyFilters(textSearch, theBattleTag)
		self:adjustTopindex()
	end
	self:selectFriendByIndex(0, theBattleTag)
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

function UI:onMainFrameTabClick(obj)
	self.mainFrame.tabPages[self.mainFrame.selectedTab]:Hide()
	PanelTemplates_Tab_OnClick(obj, self.mainFrame)
	self.mainFrame.tabPages[self.mainFrame.selectedTab]:Show()
	self.mainFrame.title:SetText(string.format("%s - %s", KSR_STD_TITLE, obj:GetText()))
end

-- create frames & components

function UI:createFriendsButtons(parent)
	for i = 1, COUNT_FRIENDSBTN do
		local friendBtn = CreateFrame("BUTTON", nil, parent)
		friendBtn:SetSize(WIDTH_FRIENDSBTN, HEIGHT_FRIENDSBTN)
		friendBtn:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, (COUNT_FRIENDSBTN - i) * HEIGHT_FRIENDSBTN)
		friendBtn.t = friendBtn:CreateTexture(nil, "BACKGROUND")
		friendBtn.t:SetSize(WIDTH_FRIENDSBTN, HEIGHT_FRIENDSBTN - 1)
		friendBtn.t:SetPoint("CENTER", friendBtn, "CENTER")
		friendBtn.t:SetColorTexture(0.2, 0.2, 0.2)
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
		friendBtn.strName:SetSize(245, 12)
		friendBtn.strName:SetPoint("TOPLEFT", friendBtn, "TOPLEFT", 20, -4)
		friendBtn.strName:SetJustifyH("LEFT")
		friendBtn.strName:SetText("NAME")
		friendBtn.strInfo = friendBtn:CreateFontString(nil, "ARTWORK", "FriendsFont_Small")
		friendBtn.strInfo:SetSize(245, 10)
		friendBtn.strInfo:SetPoint("TOPLEFT", friendBtn.strName, "BOTTOMLEFT", 0, -3)
		friendBtn.strInfo:SetJustifyH("LEFT")
		friendBtn.strInfo:SetText("INFO")
		friendBtn.index = i
		friendBtn:SetScript("OnMouseUp", function(obj, button)
				self:selectFriendByIndex(obj.index)
				-- todo: popup menu { invite, favTag, ... }
				-- if button == "RightButton" then
					-- self:inviteSelection()
				-- end
			end)
		friendBtn:SetScript("OnDoubleClick", function(obj) self:whisperToSelection() end)
		friendBtn:SetScript("OnMouseWheel", function(obj, delta) self:onScrollFriendsList(delta) end)
		table.insert(self.friendsBtns, friendBtn)
	end
end

function UI:createFriendTBBtn(idx, strTexture, tooltip, parent)
	local btn = CreateFrame("BUTTON", nil, parent)
	local offsetY = -EDGE_SIZE * 6
	btn:SetSize(WIDTH_FRIEND_TB_BUTTON, HEIGHT_FRIEND_TB_BUTTON)
	btn:SetPoint("TOPLEFT", parent.strInfo, "BOTTOMLEFT", (idx - 1) * (WIDTH_FRIEND_TB_BUTTON + MARGIN_FRIEND_TB_BUTTON), -MARGIN_PANEL_COLUMNS)
	btn:SetNormalTexture(strTexture..BTN_TEXTURE_SUFFIX_NML)
	btn:SetHighlightTexture(strTexture..BTN_TEXTURE_SUFFIX_NML)
	btn:SetPushedTexture(strTexture..BTN_TEXTURE_SUFFIX_PSH)
	btn:SetDisabledTexture(strTexture..BTN_TEXTURE_SUFFIX_DIS)
	btn.tooltip = tooltip
	btn:SetScript("OnEnter", function(obj)
			if obj.tooltip == nil or obj.tooltip == "" then return end
			-- note: anchor must be set before addline
			local parts = { strsplit("\n", obj.tooltip) }
			GameTooltip:SetOwner(obj, "ANCHOR_BOTTOMRIGHT", -56, -8)
			GameTooltip:SetText(parts[1])
			if #parts > 1 then
				for i = 2, #parts do
					GameTooltip:AddLine(parts[i], 0.8, 0.8, 0.8)
				end
			end
			GameTooltip:Show()
		end)
	btn:SetScript("OnLeave", function(obj)
			GameTooltip:Hide()
		end)
	return btn
end

function UI:createSMFBaseFrame(parent)
	local baseFrame = CreateFrame("FRAME", nil, parent)
	baseFrame:SetBackdrop({
		bgFile = nil, edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
		tile = true, tileSize = 16, edgeSize = 1,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }})
	baseFrame:SetBackdropBorderColor(1, 1, 1, 0.12)
	baseFrame.bg = baseFrame:CreateTexture(nil, "BACKGROUND")
	baseFrame.bg:SetPoint("TOPLEFT", baseFrame, "TOPLEFT", 1, -1)
	baseFrame.bg:SetPoint("BOTTOMRIGHT", baseFrame, "BOTTOMRIGHT", -1, 1)
	baseFrame.bg:SetColorTexture(0, 0, 0, 0.5)
	
	return baseFrame
end

function UI:createSMFFrame(base)
	local smf = CreateFrame("SCROLLINGMESSAGEFRAME", nil, base)
	smf:SetPoint("TOPLEFT", base, "TOPLEFT", EDGE_SIZE, -EDGE_SIZE)
	smf:SetPoint("BOTTOMRIGHT", base, "BOTTOMRIGHT", -EDGE_SIZE, EDGE_SIZE)
	
	return smf
end

function UI:createSubFrame_Friends(parent)
	local sf = CreateFrame("FRAME", nil, parent)
	sf.topIndex = 1
	sf.selection = { pid = 0, battleTag = "", accName = "", gameAccountID = 0, guid = "" }
	sf.prevHLBtn = nil

	sf:SetPoint("TOPLEFT", parent, "TOPLEFT", EDGE_SIZE, -EDGE_SIZE - HEIGHT_TITLE)
	sf:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -EDGE_SIZE, EDGE_SIZE)

	sf.edtSearch = CreateFrame("EDITBOX", nil, sf)
	sf.edtSearch:SetSize(WIDTH_FRIENDSBTN, 24)
	sf.edtSearch:SetPoint("TOPLEFT", sf, "TOPLEFT", 0, 0)
	sf.edtSearch:SetFontObject(ChatFontNormal)
	sf.edtSearch:SetMaxBytes(128)
	sf.edtSearch:SetAutoFocus(false)
	sf.edtSearch:SetBackdrop({
		bgFile = nil, edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
		tile = true, tileSize = 16, edgeSize = 1,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }})
	sf.edtSearch:SetBackdropBorderColor(1, 1, 1, 0.12)
	local l, r, t, b = sf.edtSearch:GetTextInsets()
	sf.edtSearch:SetTextInsets(22, r, t, b)
	sf.edtSearch.iconSearch = sf.edtSearch:CreateTexture(nil, "ARTWORK")
	sf.edtSearch.iconSearch:SetSize(14, 14)
	sf.edtSearch.iconSearch:SetPoint("TOPLEFT", sf.edtSearch, "TOPLEFT", 6, -6)
	sf.edtSearch.iconSearch:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
	sf.edtSearch.hint = sf.edtSearch:CreateFontString(nil, "ARTWORK")
	sf.edtSearch.hint:SetFontObject(ChatFontNormal)
	sf.edtSearch.hint:SetSize(WIDTH_FRIENDSBTN - 48, 24)
	sf.edtSearch.hint:SetPoint("TOPLEFT", sf.edtSearch, "TOPLEFT", 22, 0)
	sf.edtSearch.hint:SetJustifyH("LEFT")
	sf.edtSearch.hint:SetJustifyV("MIDDLE")
	sf.edtSearch.hint:SetText(COMMENT_COLOR..L["msgSearchBoxHint"]..FONT_COLOR_CODE_CLOSE)
	sf.edtSearch:SetScript("OnEnterPressed", function(obj) obj:ClearFocus() end)
	sf.edtSearch:SetScript("OnEscapePressed", function(obj) obj:ClearFocus() end)
	sf.edtSearch:SetScript("OnChar", function(obj) self:onFriendSearch(self:getFriendSearchBoxText()) end)
	sf.edtSearch:SetScript("OnKeyDown", function(obj, key) self:onKeyDown(obj, key) end)
	sf.edtSearch:SetScript("OnKeyUp", function(obj, key) if key == "DELETE" or key == "BACKSPACE" then self:onFriendSearch(self:getFriendSearchBoxText()) end end)
	sf.edtSearch:SetScript("OnEditFocusGained", function(obj) obj.hint:Hide() end)

	sf.strName = sf:CreateFontString(nil, "ARTWORK")
	sf.strName:SetHeight(24)
	sf.strName:SetPoint("TOPLEFT", sf.edtSearch, "TOPRIGHT", MARGIN_PANEL_COLUMNS, 0)
	sf.strName:SetPoint("TOPRIGHT", sf, "TOPRIGHT", 0, 0)
	sf.strName:SetFontObject(ChatFontNormal)
	setFontSize(sf.strName, 16)
	sf.strName:SetJustifyH("LEFT")
	sf.strName:SetJustifyV("MIDDLE")
	sf.strName:SetText("NAME")
	sf.strInfo = sf:CreateFontString(nil, "ARTWORK")
	sf.strInfo:SetHeight(21)
	sf.strInfo:SetPoint("TOPLEFT", sf.strName, "BOTTOMLEFT", 0, 0)
	sf.strInfo:SetPoint("TOPRIGHT", sf.strName, "BOTTOMRIGHT", 0, 0)
	sf.strInfo:SetFontObject(ChatFontNormal)
	setFontSize(sf.strInfo, 14)
	sf.strInfo:SetJustifyH("LEFT")
	sf.strInfo:SetJustifyV("MIDDLE")
	sf.strInfo:SetText("INFO")

	-- toolbar buttons
	sf.btnWhisper = self:createFriendTBBtn(1, BTN_WHISPER_TEXTURE, L["tooltipWhisper"], sf)
	sf.btnWhisper:SetScript("OnClick", function(obj) self:whisperToSelection() end)
	sf.btnInvite = self:createFriendTBBtn(2, BTN_INVITE_TEXTURE, L["tooltipInvite"], sf)
	sf.btnInvite:SetScript("OnClick", function(obj) self:inviteSelection() end)
	sf.btnReportKeys = self:createFriendTBBtn(3, BTN_REPORTKEYS_TEXTURE, L["tooltipReportKeys"], sf)
	sf.btnReportKeys:SetScript("OnClick", function(obj) StaticPopup_Show("KSR_CONFIRM_REPORTKEYS", self.friendsFrame.selection.accName, nil, 
		{ ksr = self.ksr, pid = self.friendsFrame.selection.pid }) end)
	sf.btnQueryKeys = self:createFriendTBBtn(4, BTN_QUERYKEYS_TEXTURE, L["tooltipQueryKeys"], sf)
	sf.btnQueryKeys:SetScript("OnClick", function(obj) self:refreshKeysOfSelection() end)
	sf.btnQueryDGInfo = self:createFriendTBBtn(5, BTN_QUERYDGINFO_TEXTURE, L["tooltipQueryDGInfo"], sf)

	-- smf
	sf.smfBase = self:createSMFBaseFrame(sf)
	sf.smfBase:SetPoint("TOPLEFT", sf.btnWhisper, "BOTTOMLEFT", 0, -MARGIN_PANEL_COLUMNS)
	sf.smfBase:SetPoint("BOTTOMRIGHT", sf, "BOTTOMRIGHT", 0, 0)
	sf.smfKeys = self:createSMFFrame(sf.smfBase)
	sf.smfKeys:SetFontObject(ChatFontNormal)
	setFontSize(sf.smfKeys, 16)
	sf.smfKeys:SetInsertMode(1)
	sf.smfKeys:SetJustifyH("LEFT")
	sf.smfKeys:SetFading(false)
	sf.smfKeys:SetSpacing(6)
	sf.smfKeys:SetIndentedWordWrap(true)
	sf.smfKeys:SetScript("OnMouseWheel", function(obj, delta)
			if delta < 0 then
				obj:ScrollUp()
			else
				obj:ScrollDown()
			end
		end)

	self:createFriendsButtons(sf)

	return sf
end

function UI:createSubFrame_Mykeys(parent)
	local sf = CreateFrame("FRAME", nil, parent)
	sf:Hide()
	sf:SetPoint("TOPLEFT", parent, "TOPLEFT", EDGE_SIZE, -EDGE_SIZE - HEIGHT_TITLE)
	sf:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -EDGE_SIZE, EDGE_SIZE)

	sf.btnSendToParty = CreateFrame("BUTTON", nil, sf, "UIPanelButtonTemplate")
	sf.btnSendToParty:SetSize(WIDTH_MYKEYS_BTN, HEIGHT_MYKEYS_BTN)
	sf.btnSendToParty:SetPoint("BOTTOMLEFT", sf, "BOTTOMLEFT", 0, MARGIN_PANEL_COLUMNS)
	sf.btnSendToParty:SetText(L["btnLabelSendToParty"])
	sf.btnSendToParty:SetScript("OnClick", function(obj) self.ksr:announceAllKeystones("PARTY") end)
	sf.btnSendToGuild = CreateFrame("BUTTON", nil, sf, "UIPanelButtonTemplate")
	sf.btnSendToGuild:SetSize(WIDTH_MYKEYS_BTN, HEIGHT_MYKEYS_BTN)
	sf.btnSendToGuild:SetPoint("LEFT", sf.btnSendToParty, "RIGHT", MARGIN_MYKEYS_BTN, 0)
	sf.btnSendToGuild:SetText(L["btnLabelSendToGuild"])
	sf.btnSendToGuild:SetScript("OnClick", function(obj) self.ksr:announceAllKeystones("GUILD") end)
	sf.btnSendToSay = CreateFrame("BUTTON", nil, sf, "UIPanelButtonTemplate")
	sf.btnSendToSay:SetSize(WIDTH_MYKEYS_BTN, HEIGHT_MYKEYS_BTN)
	sf.btnSendToSay:SetPoint("LEFT", sf.btnSendToGuild, "RIGHT", MARGIN_MYKEYS_BTN, 0)
	sf.btnSendToSay:SetText(L["btnLabelSendToSay"])
	sf.btnSendToSay:SetScript("OnClick", function(obj) self.ksr:announceAllKeystones("SAY") end)

	-- smf
	sf.smfBase = self:createSMFBaseFrame(sf)
	sf.smfBase:SetPoint("TOPLEFT", sf, "TOPLEFT", 2, 0)
	sf.smfBase:SetPoint("TOPRIGHT", sf, "TOPRIGHT", -2, 0)
	sf.smfBase:SetPoint("BOTTOMLEFT", sf.btnSendToParty, "TOPLEFT", 2, EDGE_SIZE)
	sf.smfKeys = self:createSMFFrame(sf.smfBase)
	sf.smfKeys:SetFontObject(ChatFontNormal)
	setFontSize(sf.smfKeys, 16)
	-- sf.smfKeys:SetInsertMode(1)
	sf.smfKeys:SetJustifyH("LEFT")
	sf.smfKeys:SetFading(false)
	sf.smfKeys:SetSpacing(6)
	sf.smfKeys:SetIndentedWordWrap(true)
	sf.smfKeys:SetScript("OnMouseWheel", function(obj, delta)
			if delta > 0 then
				obj:ScrollUp()
			else
				obj:ScrollDown()
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
		insets = { left = 4, right = 4, top = 4, bottom = 4 }})
	mf:SetBackdropColor(0, 0, 0, 1)
	mf:SetMovable(true)
	mf:RegisterForDrag("LeftButton")
	mf:EnableMouse(true)
	mf:EnableKeyboard(true)
	mf:SetPropagateKeyboardInput(true)
	mf:SetClampedToScreen(true)
	-- init components which parent is mainFrame
	mf.title = mf:CreateFontString(nil, "ARTWORK")
	mf.title:SetHeight(HEIGHT_TITLE)
	mf.title:SetPoint("TOPLEFT", mf, "TOPLEFT",  EDGE_SIZE, -EDGE_SIZE + 2)
	mf.title:SetPoint("TOPRIGHT", mf, "TOPRIGHT", -EDGE_SIZE, -EDGE_SIZE + 2)
	mf.title:SetFontObject(GameFontNormalLarge)
	mf.title:SetJustifyH("LEFT")
	mf.title:SetJustifyV("TOP")
	mf.title:SetText(string.format("%s - %s", KSR_STD_TITLE, L["btnLabelBattlenetFriends"]))
	mf.btnClose = CreateFrame("BUTTON", nil, mf, "UIPanelCloseButtonNoScripts")
	mf.btnClose:SetPoint("TOPRIGHT", mf, "TOPRIGHT", -10, -10)
	mf.btnClose:SetScript("OnClick", function(obj) self.mainFrame:Hide() end)
	-- tabs
	mf.tabPages = {}
	mf.maxTabWidth = MAX_BTNWITDH
	mf.tabBNFriends = CreateFrame("BUTTON", "KeystoneRunnerMainFrameTab1", mf, "CharacterFrameTabButtonTemplate", 1)
	mf.tabBNFriends:SetPoint("BOTTOMLEFT", 7, -30)
	mf.tabBNFriends:SetText(L["btnLabelBattlenetFriends"])
	mf.tabBNFriends:SetScript("OnClick", function(obj) self:onMainFrameTabClick(obj) end)
	mf.tabMyKeystones = CreateFrame("BUTTON", "KeystoneRunnerMainFrameTab2", mf, "CharacterFrameTabButtonTemplate", 2)
	mf.tabMyKeystones:SetPoint("LEFT", mf.tabBNFriends, "RIGHT", -15, 0)
	mf.tabMyKeystones:SetText(L["btnLabelMyKeystones"])
	mf.tabMyKeystones:SetScript("OnClick", function(obj) self:onMainFrameTabClick(obj) end)
	PanelTemplates_SetNumTabs(mf, 2)
	mf.selectedTab = 1
	PanelTemplates_UpdateTabs(mf)
	-- Events
	mf:RegisterEvent("BN_FRIEND_LIST_SIZE_CHANGED")
	mf:SetScript("OnShow", function(obj)
			self:updateFriendsFrame()
			self:updateMyKeys()
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
