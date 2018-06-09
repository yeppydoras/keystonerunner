-- localization file for English
local L = LibStub("AceLocale-3.0"):NewLocale("KeystoneRunner", "enUS", true)

L["msgHeadnote_new"] = "<Keystone Runner> Report new keystone:"
L["msgHeadnote_all"] = "<Keystone Runner> Report all keystones:"
L["msgListEmpty"] = " · No keystone logged"
L["msgDespFullAutoReply"] = "<Keystone Runner> detected keyword <%s> and report keystones automatically"
L["msgWeeklyCleanup"] = "<Keystone Runner> Weekly reset. Removing data of previous week."
L["msgWeeklyBest"] = "Weekly best"
L["msgLogSum"] = "Found: %s Mythic+ log(s) <<"
L["msgLogEmpty"] = " · No Mythic+ logged"
L["msgLogEntryBody"] = "%s %s(+%s) { %s } Time: %s Keystone upgrade: +%s"
-- review mark
L["msgSelfDesp"] = "|cFFFF7D0A<Keystone Runner>|r Assemble your mythic+ team in a better way: by searching battle.net friends and share keystones information."
L["msgSearchBoxHint"] = "pressing CONTROL twice quickly"
L["msgUsageDetail"] = "Usage:\n/ksr - Toggle Keystone Runner window\n/ksr p - Report to party\n/ksr g - Report to guild\n/ksr s - Report to say\n/ksr w [name-realm] - Report to character(whisper)\n/ksr w - [Support battle.net whisper] Report to last player who send you message\n/ksr r - [Support battle.net whisper] Report to last player who send you message contains keywords (i.e. Keystone)\n/ksr log - View Mythic+ log\n/ksr log <keyword1> <keyword2> ... - Search Mythic+ log with keyword(s)\n/ksr opt mythicautoreply - Toggle feature: Mythic+ auto whisper respond\n/ksr opt keyautoreply - Toggle feature: Auto report keystones(#key)\n/ksr wipelog - Clean Mythic+ log\n/ksr clear - Clear all data"
L["msgCantSendMsg"] = "<Keystone Runner> No target defined to send keystones"
L["msgMPlusDND"] = "<Keystone Runner> %s is challenging: %s(+%s)  Boss kills: %s/%s  %s: %s Elapsed time: %s. Send me %s to view all my keystones. <Auto reply will cooldown after 5 minutes>"
L["msgHintSemiAutoReply"] = "<Keystone Runner> detected keyword <%s>. Report all your keystones with \"/ksr r\" to <%s>"
L["msgParty"] = "party"
L["msgToggleMPlusAutoReply"] = "<Keystone Runner> Mythic+ auto reply Enabled : %s"
L["msgToggleKeyAutoReply"] = "<Keystone Runner> Key auto reply Enabled : %s"
L["msgUnknownOptCmd"] = "<Keystone Runner> Unknown option command"
L["msgNoKeystone"] = "(No keystone stored)"
L["msgFriendStat_Updated"] = "Updated at: %s%s"
L["msgFriendStat_NotPlayingWoW"] = "Friend not playing WoW"
L["msgFriendStat_WFR"] = "...Wait for response"
L["msgFriendStat_NotInstalled"] = "Keystone Runner not installed"
L["tooltipWhisper"] = "Whisper\nPress Alt key twice quickly"
L["tooltipInvite"] = "Invite\nPress Insert key twice quickly"
L["tooltipReportKeys"] = "Report Keystones"
L["tooltipQueryKeys"] = "Refresh Keystones"
L["tooltipQueryDGInfo"] = "Query friend's current Mythic+ progress"
L["strToggleFriendsFrame"] = "Toggle friend window"
-- others
L["msgDontSpam"] = "<Keystone Runner> Enough already.(Irritated) <Auto report keystones(#key) is not available to me for a short time>"