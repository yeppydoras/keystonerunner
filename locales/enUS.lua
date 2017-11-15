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
L["msgSelfDesp"] = "|cFFFF7D0A<Keystone Runner>|r Track and report keystones for all characters"
L["msgUsageBrief"] = "* Report to party with \"/ksr p\" or guild with \"/ksr g\"\r* Check out more information with \"ksr help\""
-- review mark
L["msgUsageDetail"] = "  /ksr p - Report to party\r  /ksr g - Report to guild\r  /ksr s - Report to \"say\"\r  /ksr w [name-realm] - Report to character(whisper)\r  /ksr w - Report to last player who sends you message\r  /ksr r - Report to last player who sends you message contains keywords (i.e. \"Keystone\")\r  /ksr log - View Mythic+ log\r  /ksr log <keyword1> <keyword2> ... - Search Mythic+ log with keyword(s)\r  /ksr wipelog - Clean Mythic+ log\r  /ksr clear - Clear all data"
L["msgCantSendMsg"] = "<Keystone Runner> No target defined to send keystones"
L["msgMPlusDND"] = "<Keystone Runner> %s is challenging: %s(+%s)  Boss kills: %s/%s  %s: %s Elapsed time: %s. Send me %s to view all my keystones. <Auto reply will cooldown after 5 minutes>"
L["msgHintSemiAutoReply"] = "<Keystone Runner> detected keyword <%s>. Report all your keystones with \"/ksr r\" to <%s>"
L["msgParty"] = "party"
L["msgToggleMPlusAutoReply"] = "<Keystone Runner> Mythic+ auto reply Enabled : %s"
L["msgToggleKeyAutoReply"] = "<Keystone Runner> Key auto reply Enabled : %s"
L["msgUnknownOptCmd"] = "<Keystone Runner> Unknown option command"
