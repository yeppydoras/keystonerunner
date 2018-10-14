local KSR_PREFIX = "KSRNNR"
local KSR_DATA_VER = 1
local KSR_MSGQUERYKSR = "QUERYKSR"
local KSR_MSGSEP = "\t"
local KSR_HEADERREPLYKEYS = "CMD=REPLYKEYS"
local KSR_MSGREPLYKEYS = KSR_HEADERREPLYKEYS..KSR_MSGSEP.."battleTag=%s"..KSR_MSGSEP.."dataver=%d"..KSR_MSGSEP.."keys=%s"
local KSR_STD_TITLE = "Keystone Runner"
local KSR_MPLOOTSPEC = "%s[%d]"
local L = LibStub("AceLocale-3.0"):GetLocale("KeystoneRunner")

local v8_InsKeyID = {
	["1594"] = 247, -- ML
	["1754"] = 245, -- FH
	["1762"] = 249, -- KR
	["1763"] = 244, -- AD
	["1771"] = 246, -- TD
	["1822"] = 353, -- SIEGE
	["1841"] = 251, -- UNDR
	["1862"] = 248, -- WM
	["1864"] = 252, -- SOTS
	["1877"] = 250, -- TOS
}

local v8_keyIDs = { 248, 251, 246, 247, 353, 250, 245, 249, 244, 252 }

_KSRGlobal = { L = L, Prefix = KSR_PREFIX,  DataVer = KSR_DATA_VER, MsgQueryKSR = KSR_MSGQUERYKSR, MsgSep = KSR_MSGSEP,
	MsgHeaderReplyKeys = KSR_HEADERREPLYKEYS, MsgReplyKeys = KSR_MSGREPLYKEYS, StdTitle = KSR_STD_TITLE, MPLootSpec = KSR_MPLOOTSPEC,
	ins_key_ID = v8_InsKeyID, keyIDs = v8_keyIDs }

-- dataver == 1
-- 	cmd, battleTag, dataver, keys
-- 	Example: "CMD=REPLYKEYS\tbattleTag=[bt]\tdataver=1\tkeys=[strings seperated with \n]"
	
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
function trim(s)
	return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

function setFontSize(obj, size)
	local fontName, fontSize, fontFlags = obj:GetFont()
	obj:SetFont(fontName, size, fontFlags)
end

function isLeft(str, left)
	return string.sub(str, 1, string.len(left)) == left
end
