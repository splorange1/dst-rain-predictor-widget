local Widget = require "widgets/widget"
local TextButton = require "widgets/textbutton"
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"

Assets = {
    Asset("ATLAS","images/status_bgs.xml"),
    Asset("IMAGE","images/status_bgs.tex"),
	Asset("ATLAS","images/rain.xml"),
    Asset("IMAGE","images/rain.tex"),
}

local function GetWorld()
	return TheWorld:HasTag("island") and "Island" or 
	TheWorld:HasTag("volcano") and "Volcano" or
	TheWorld.net.components.weather ~= nil and "Surface" or
	TheWorld.net.components.caveweather ~= nil and "Caves"
end

local function PredictRainStart()
	local MOISTURE_RATES
	local moisture
	local moistureceil
	local world = GetWorld()

	if world == "Island" or world == "Volcano" then
		MOISTURE_RATES = {
		    MIN = {
		        autumn = 0,
		        winter = 3,
		        spring = 3,
		        summer = 0,
		    },
		    MAX = {
		        autumn = 0.1,
		        winter = 3.75,
		        spring = 3.75,
		        summer = -0.2,
		    }
		}

		moisture = TheWorld.state.islandmoisture
		moistureceil = TheWorld.state.islandmoistureceil
	else
		MOISTURE_RATES = {
			MIN = {
				autumn = .25,
				winter = .25,
				spring = 3,
				summer = .1,
			},
			MAX = {
				autumn = 1.0,
				winter = 1.0,
				spring = 3.75,
				summer = .5,
			}
		}

		moisture = TheWorld.state.moisture
		moistureceil = TheWorld.state.moistureceil
	end

	local remainingsecondsinday = TUNING.TOTAL_DAY_TIME - (TheWorld.state.time * TUNING.TOTAL_DAY_TIME)
	local totalseconds = 0
	local rain = false

	local season = TheWorld.state.season
	local seasonprogress = TheWorld.state.seasonprogress
	local elapseddaysinseason = TheWorld.state.elapseddaysinseason
	local remainingdaysinseason = TheWorld.state.remainingdaysinseason
	local totaldaysinseason = remainingdaysinseason / (1 - seasonprogress)
	local _totaldaysinseason = elapseddaysinseason + remainingdaysinseason

	while elapseddaysinseason < _totaldaysinseason do
		local moisturerate

		if world == "Surface" and season == "winter" and elapseddaysinseason == 2 then
			moisturerate = 50
		else
			local p = 1 - math.sin(PI * seasonprogress)
			moisturerate = MOISTURE_RATES.MIN[season] + p * (MOISTURE_RATES.MAX[season] - MOISTURE_RATES.MIN[season])
		end

		local _moisture = moisture + (moisturerate * remainingsecondsinday)
	
		if _moisture >= moistureceil then
			totalseconds = totalseconds + ((moistureceil - moisture) / moisturerate)
			rain = true
			break
		else
			moisture = _moisture
			totalseconds = totalseconds + remainingsecondsinday
			remainingsecondsinday = TUNING.TOTAL_DAY_TIME
			elapseddaysinseason = elapseddaysinseason + 1
			remainingdaysinseason = remainingdaysinseason - 1
			seasonprogress = 1 - (remainingdaysinseason / totaldaysinseason)
		end
	end

	local days = TheWorld.state.cycles + 1 + TheWorld.state.time + (totalseconds / TUNING.TOTAL_DAY_TIME)
	local mins = math.floor(totalseconds / 60)
	local secs = math.floor(totalseconds % 60)

	if secs < 10 then
	secs = string.format("%02d",secs)
	end

	days = string.format("%.1f",days)

	return world, totalseconds, rain, days, mins, secs
end

local function PredictRainStop()
	local PRECIP_RATE_SCALE = 10
	local MIN_PRECIP_RATE = .1
	local rain = nil
	local world = GetWorld()

	local dbgstr = (world == "Island" or world == "Volcano") and TheWorld.net.components.weather:GetIADebugString() or
			world == "Surface" and TheWorld.net.components.weather:GetDebugString() or
			world == "Caves" and TheWorld.net.components.caveweather:GetDebugString()

	local _, _, moisture, moisturefloor, moistureceil, moisturerate, preciprate, peakprecipitationrate = string.find(dbgstr, ".*moisture:(%d+.%d+)%((%d+.%d+)/(%d+.%d+)%) %+ (%d+.%d+), preciprate:%((%d+.%d+) of (%d+.%d+)%).*")

	moisture = tonumber(moisture)
	moistureceil = tonumber(moistureceil)
	moisturefloor = tonumber(moisturefloor)
	preciprate = tonumber(preciprate)
	peakprecipitationrate = tonumber(peakprecipitationrate)

	local totalseconds = 0

	while moisture > moisturefloor do
		if preciprate > 0 then
			local p = math.max(0, math.min(1, (moisture - moisturefloor) / (moistureceil - moisturefloor)))
			local rate = MIN_PRECIP_RATE + (1 - MIN_PRECIP_RATE) * math.sin(p * PI)

			preciprate = math.min(rate, peakprecipitationrate)
			moisture = math.max(moisture - preciprate * FRAMES * PRECIP_RATE_SCALE, 0)

			totalseconds = totalseconds + FRAMES
		else
			break
		end
	end

	if TheWorld.state.hurricane then
		local _, _, hurricane_timer, hurricane_duration = string.find(dbgstr, ".*hurricane:(%d+.%d+)/(%d+.%d+).*")
		totalseconds = hurricane_duration - hurricane_timer
	end

	local days = TheWorld.state.cycles + 1 + TheWorld.state.time + (totalseconds / TUNING.TOTAL_DAY_TIME)
	local mins = math.floor(totalseconds / 60)
	local secs = math.floor(totalseconds % 60)
	
	if secs < 10 then
		secs = string.format("%02d",secs)
	end

	days = string.format("%.1f",days)

	return world, totalseconds, rain, days, mins, secs
end

local RainWidget = Class(Widget, function(self, owner)
    Widget._ctor(self, "RainWidget")
	self.owner = owner

	self:SetScale(0.7,0.7,0.7)

	self.inpos = Vector3(-22,-30) --105 is the good one :)
	self.outpos = Vector3(50,-30)

	self.bg = self:AddChild(Image("images/status_bgs.xml", "status_bgs.tex"))

	self.button = self.bg:AddChild(ImageButton("images/rain.xml", "rain.tex"))
	self.button:SetPosition(70,0)
	self.button:SetScale(0.6,0.6,0.6)

	self.textbtn = self.bg:AddChild(TextButton())
	self.textbtn:SetText(" ", 0)
    self.textbtn:SetFont(NUMBERFONT)
    self.textbtn:SetTextSize(30)
	self.textbtn:SetTextColour({0.5, 1, 0.5, 1})
	self.textbtn:SetPosition(-3,0)

	self.timeacc = 0
	self.open = false
	
	self.cd = nil

	self.canAnnounce = true
	
	self:StartUpdating()

	self.textbtn:SetOnClick(function() if self.canAnnounce then self:OnClickText() end end)
	self.button:SetOnClick(function() self:OnClickButton() end)
end)

function RainWidget:OnClickText()
	if not self.cd then
		self.cd = true
		local whisper = TheInput:IsControlPressed(CONTROL_FORCE_ATTACK) or TheInput:IsControlPressed(CONTROL_MENU_MISC_3)
		self.inst:DoSimTaskInTime(2, function() self.cd = nil end)
		if TheWorld.state.pop ~= 1 then
			local world, totalseconds, rain, d, m, s = PredictRainStart()
			if rain then
				TheNet:Say(STRINGS.LMB.. " The "..world.." will rain on day "..d.." ("..m.."m "..s.."s).",whisper)
			else
				if world == "Caves" then
					TheNet:Say(STRINGS.LMB.. " It will no longer rain in the Caves this "..TheWorld.state.season,whisper)
					else
					TheNet:Say(STRINGS.LMB.. " It will no longer rain on the Surface this "..TheWorld.state.season,whisper) --grammar moment
				end
			end
		else
			local world, totalseconds, rain, d, m, s = PredictRainStop()
			TheNet:Say(STRINGS.LMB.. " The "..world.." will stop raining on day "..d.." ("..m.."m "..s.."s).",whisper)
		end
	end
end

function RainWidget:OnClickButton()
	if self.open then
		self:MoveTo(self.outpos,self.inpos,0.2)
		self.open = false
	else
		self:MoveTo(self.inpos,self.outpos,0.2)
		self.open = true
	end
end

function RainWidget:OnUpdate(dt)
	self.timeacc = self.timeacc + dt
	if self.timeacc > 1 and self.open then
		self.timeacc = 0
		if TheWorld.state.pop ~= 1 then
			local world, totalseconds, rain, d, m, s = PredictRainStart()

			if rain then
				self.textbtn:SetText(m..":"..s)
				self.textbtn:SetTextSize(30)
			else
				self.textbtn:SetText("No Rain Soon")
				self.textbtn:SetTextSize(18)
			end
		else
			local world, totalseconds, rain, d, m, s = PredictRainStop()
			self.textbtn:SetText(m..":"..s)
			self.textbtn:SetTextSize(30)
		end
	end

end 

return RainWidget
