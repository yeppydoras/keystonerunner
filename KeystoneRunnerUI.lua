local UI = {}
_KSRGlobal = { UI = UI }

local BACKDROP = {
bgFile = "Interface/Tooltips/UI-Tooltip-Background",
edgeFile = nil, tile = true, tileSize = 16, edgeSize = 16,
insets = {left = 0, right = 0, top = 0, bottom = 0}
}

function UI:init(ksr)
	self.mainFrame = nil
	self.ksr = ksr
	self.keystonerunnerLDB = LibStub("LibDataBroker-1.1"):NewDataObject("KeystoneRunner", {
		type = "data source",
		text = "Keystone Runner",
		icon = "Interface\\AddOns\\KeystoneRunner\\Media\\minimap.tga",
		OnClick = function() self:onMinimapBtnClick() end,
		OnTooltipShow = function() GameTooltip:SetText("Keystone Runner") end,
	})
	self.mmbtn = LibStub("LibDBIcon-1.0")
	self.mmbtn:Register("keystonerunner", self.keystonerunnerLDB, ksr.Settings.minimap)
end

function UI:onMinimapBtnClick()
	if self.mainFrame == nil then
		self.mainFrame = self:createMainFrame()
	end
	self.mainFrame:SetShown(not self.mainFrame:IsShown())
	print("OK")
end

function UI:createMainFrame()
	local mf = CreateFrame('FRAME', 'KeystoneRunnerFrame', UIParent)
	mf:SetFrameStrata('DIALOG')
	mf:SetWidth(450)
	mf:SetHeight(600)
	mf:SetPoint('CENTER', UIParent, 'CENTER')
	mf:EnableMouse(true)
	mf:SetBackdrop(BACKDROP)
	mf:SetBackdropColor(0, 0, 0, 1)
	mf:SetMovable(true)
	mf:RegisterForDrag('LeftButton')
	mf:EnableKeyboard(true)
	mf:SetPropagateKeyboardInput(true)
	mf:SetClampedToScreen(true)
	mf:Hide()
	return mf
end