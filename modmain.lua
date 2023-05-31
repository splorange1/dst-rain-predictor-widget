local RainWidget = require "widgets/rainwidget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"

Assets = {
    Asset("ATLAS","images/status_bgs.xml"),
    Asset("IMAGE","images/status_bgs.tex"),
	Asset("ATLAS","images/rain.xml"),
    Asset("IMAGE","images/rain.tex"),
}

local WidgetPos = GetModConfigData("configWidgetPos")
local canAnnounce = GetModConfigData("canAnnounce")

AddClassPostConstruct("widgets/controls", function(self)
	self.rainwidget = self.topleft_root:AddChild(RainWidget(self.owner))
	self.rainwidget:SetPosition(-22,WidgetPos)
	self.rainwidget.inpos = GLOBAL.Vector3(-22,WidgetPos)
	self.rainwidget.outpos = GLOBAL.Vector3(50,WidgetPos)
	self.rainwidget.canAnnounce = canAnnounce
	--GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_LSHIFT, MyKeyFunction)
end)