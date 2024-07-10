local RainWidget = require "widgets/rainwidget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"

Assets = {
    Asset("ATLAS","images/rainwidget_bg.xml"),
    Asset("IMAGE","images/rainwidget_bg.tex"),
	Asset("ATLAS","images/rainwidget_rainicon.xml"),
    Asset("IMAGE","images/rainwidget_rainicon.tex"),
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