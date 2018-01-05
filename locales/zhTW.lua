-- localization file for Traditional Chinese
local L = LibStub("AceLocale-3.0"):NewLocale("KeystoneRunner", "zhTW")

L["msgHeadnote_new"] = "<Keystone Runner> 報告新鑰石："
L["msgHeadnote_all"] = "<Keystone Runner> 報告所有鑰石："
L["msgListEmpty"] = " · 目前沒有任何鑰石被記錄下來哦。"
L["msgDespFullAutoReply"] = "<Keystone Runner> 發現關鍵字「%s」並因此自動發送了鑰石列表。"
L["msgWeeklyCleanup"] = "<Keystone Runner> 新的一週開始了，上週的數據已經清除。"
L["msgWeeklyBest"] = "本周最佳"
L["msgLogSum"] = "找到了 %s 條M+挑戰日誌 <<"
L["msgLogEmpty"] = " · 目前沒有任何M+挑戰被記錄下來哦。"
L["msgLogEntryBody"] = "%s %s(+%s) { %s } 耗時：%s 鑰石升級：+%s"
L["msgSelfDesp"] = "|cFFFF7D0A<Keystone Runner>|r 記錄並報告所有角色持有的鑰石"
L["msgUsageBrief"] = "* 使用 /ksr p、/ksr g 報告到小隊或公會頻道。\r* 使用 /ksr help 查看更多幫助信息。"
-- review mark
L["msgUsageDetail"] = "  /ksr p - 報告到小隊頻道\r  /ksr g - 報告到公會頻道\r  /ksr s - 報告到say頻道\r  /ksr w [角色名字-伺服器] - 密語報告給特定角色\r  /ksr w - 密語報告給上一個發來消息的玩家\r  /ksr r - 報告給上一個發來的消息中包含特定關鍵詞（例如：鑰石）的玩家\r  /ksr log - 查看大秘境日誌\r  /ksr log <keyword1> <keyword2> ... - 以關鍵詞檢索大秘境日誌\r  /ksr opt mythicautoreply - 切換大秘境自動回覆開關\r  /ksr opt keyautoreply - 切換鑰石自動報告(#key)開關\r  /ksr wipelog - 清除大秘境日誌\r  /ksr clear - 清除所有數據"
L["msgCantSendMsg"] = "<Keystone Runner> 沒有指定發送消息的目標"
L["msgMPlusDND"] = "<Keystone Runner> %s 正在挑戰：%s(+%s)，擊殺首領：%s/%s，%s：%s，已耗時：%s。向我發送 %s 查看我的所有鑰石。<5分鐘之內不會再次自動回覆>"
L["msgHintSemiAutoReply"] = "<Keystone Runner> 發現對話中提到了「%s」，使用 /ksr r 即可報告所有鑰石給「%s」。"
L["msgParty"] = "小隊"
L["msgToggleMPlusAutoReply"] = "<Keystone Runner> 允許大秘境挑戰時自動回覆：%s"
L["msgToggleKeyAutoReply"] = "<Keystone Runner> 允許自動回覆 #key 指令：%s"
L["msgUnknownOptCmd"] = "<Keystone Runner> 無效的選項指令"
L["msgNoKeystone"] = "(沒有鑰石記錄)"
-- others
L["msgDontSpam"] = "<Keystone Runner> 這就是好奇的代價！(對你施放沈默)<短時間內無法再使用自動報告鑰石功能打擾我>"