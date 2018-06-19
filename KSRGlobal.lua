local KSR_PREFIX = "KSRNNR"
local KSR_DATA_VER = 1
local KSR_MSGQUERYKSR = "QUERYKSR"
local KSR_MSGSEP = "\t"
local KSR_HEADERREPLYKEYS = "CMD=REPLYKEYS"
local KSR_MSGREPLYKEYS = KSR_HEADERREPLYKEYS..KSR_MSGSEP.."battleTag=%s"..KSR_MSGSEP.."dataver=%d"..KSR_MSGSEP.."keys=%s"
local KSR_STD_TITLE = "Keystone Runner"
_KSRGlobal = { Prefix = KSR_PREFIX,  DataVer = KSR_DATA_VER, MsgQueryKSR = KSR_MSGQUERYKSR, MsgSep = KSR_MSGSEP,
	MsgHeaderReplyKeys = KSR_HEADERREPLYKEYS, MsgReplyKeys = KSR_MSGREPLYKEYS, StdTitle = KSR_STD_TITLE }

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
