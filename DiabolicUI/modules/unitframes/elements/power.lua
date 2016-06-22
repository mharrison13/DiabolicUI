local _, Engine = ...
local Handler = Engine:GetHandler("UnitFrame")

-- WoW API
local UnitIsConnected = UnitIsConnected
local UnitIsDead = UnitIsDead
local UnitIsFriend = UnitIsFriend
local UnitIsGhost = UnitIsGhost
local UnitIsTapDenied = UnitIsTapDenied -- new in Legion
local UnitIsTapped = UnitIsTapped -- removed in Legion
local UnitIsTappedByAllThreatList = UnitIsTappedByAllThreatList -- removed in Legion
local UnitIsTappedByPlayer = UnitIsTappedByPlayer -- removed in Legion
local UnitPlayerControlled = UnitPlayerControlled
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType

local colors = {
	disconnected = { .5, .5, .5 },
	dead = { .5, .5, .5 },
	tapped = { 161/255, 141/255, 120/255 },
	ENERGY = {
		{ 250/255, 250/255, 210/255, 1, "bar" },
		{ 255/255, 215/255, 0/255, .9, "moon" },
		{ 218/255, 165/255, 32/255, .7, "smoke" },
		{ 139/255, 69/255, 19/255, 1, "shade" }
	},
	FOCUS = {
		{ 250/255, 125/255, 62/255, 1, "bar" },
		{ 255/255, 127/255, 63/255, .9, "moon" },
		{ 218/255, 109/255, 54/255, .7, "smoke" },
		{ 139/255, 69/255, 34/255, 1, "shade" }
	},
	MANA = {
		{ 18/255, 68/255, 255/255, 1, "bar" },
		{ 18/255, 68/255, 255/255, .9, "moon" },
		{ 18/255, 68/255, 255/255, .7, "smoke" },
		{ 0/255, 0/255, 0/255, 1, "shade" }
	},
	RAGE = {
		{ 139/255, 10/255, 10/255, 1, "bar" },
		{ 139/255, 10/255, 10/255, .9, "moon" },
		{ 78/255, 10/255, 10/255, .7, "smoke" },
		{ 0/255, 0/255, 0/255, 1, "shade" }
	},
	RUNIC_POWER = {
		{ 0/255, 209/255, 255/255, 1, "bar" },
		{ 0/255, 209/255, 255/255, .9, "moon" },
		{ 0/255, 209/255, 255/255, .7, "smoke" },
		{ 0/255, 0/255, 0/255, 1, "shade" }
	},
	HAPPINESS = {
		{ 0/255, 255/255, 255/255, 1, "bar" },
		{ 0/255, 255/255, 255/255, .9, "moon" },
		{ 0/255, 255/255, 255/255, .7, "smoke" },
		{ 0/255, 0/255, 0/255, 1, "shade" }
	},
	AMMOSLOT = {
		{ 204/255, 153/255, 0/255, 1, "bar" },
		{ 204/255, 153/255, 0/255, .9, "moon" },
		{ 204/255, 153/255, 0/255, .7, "smoke" },
		{ 0/255, 0/255, 0/255, 1, "shade" }
	},
	FUEL = {
		{ 0/255, 140/255, 127/255, 1, "bar" },
		{ 0/255, 140/255, 127/255, .9, "moon" },
		{ 0/255, 140/255, 127/255, .7, "smoke" },
		{ 0/255, 0/255, 0/255, 1, "shade" }
	}		
}	

local Update
if Engine:IsBuild("Legion") then
	Update = function(self, event, ...)
		local Power = self.Power

		local unit = self.unit
		local powerID, powerType = UnitPowerType(unit)
		local power = UnitPower(unit, powerID)
		local powermax = UnitPowerMax(unit, powerID)
		
		local dead = UnitIsDead(unit) or UnitIsGhost(unit)
		if dead then
			power = 0
			powermax = 0
		end

		local object_type = Power:GetObjectType()
		local color = powerType and colors[powerType] or colors.MANA
		
		if object_type == "Orb" then
			if Power.powerType ~= powerType then
				Power:Clear() -- forces the orb to empty, for a more lively animation on power/form changes
				Power.powerType = powerType
			end

			Power:SetMinMaxValues(0, powermax)
			Power:SetValue(power)
			
			for i = 1,4 do
				Power:SetStatusBarColor(unpack(color[i]))
			end

		elseif object_type == "StatusBar" then
			if Power.powerType ~= powerType then
				Power.powerType = powerType
			end

			Power:SetMinMaxValues(0, powermax)
			Power:SetValue(power)
			
			local r, g, b
			if not UnitIsConnected(unit) then
				r, g, b = unpack(colors.disconnected)
			elseif UnitIsDead(unit) or UnitIsGhost(unit) then
				r, g, b = unpack(colors.dead)
			elseif UnitIsTapDenied(unit) then
				r, g, b = unpack(colors.tapped)
			else
				r, g, b = unpack(color[2])
			end
			Power:SetStatusBarColor(r, g, b)
		end
		
		if Power.PostUpdate then
			return Power:PostUpdate()
		end
	end
else
	Update = function(self, event, ...)
		local Power = self.Power

		local unit = self.unit
		local powerID, powerType = UnitPowerType(unit)
		local power = UnitPower(unit, powerID)
		local powermax = UnitPowerMax(unit, powerID)
		
		local dead = UnitIsDead(unit) or UnitIsGhost(unit)
		if dead then
			power = 0
			powermax = 0
		end

		local object_type = Power:GetObjectType()
		local color = powerType and colors[powerType] or colors.MANA
		
		if object_type == "Orb" then
			if Power.powerType ~= powerType then
				Power:Clear() -- forces the orb to empty, for a more lively animation on power/form changes
				Power.powerType = powerType
			end

			Power:SetMinMaxValues(0, powermax)
			Power:SetValue(power)
			
			for i = 1,4 do
				Power:SetStatusBarColor(unpack(color[i]))
			end

		elseif object_type == "StatusBar" then
			if Power.powerType ~= powerType then
				Power.powerType = powerType
			end

			Power:SetMinMaxValues(0, powermax)
			Power:SetValue(power)
			
			local r, g, b
			if not UnitIsConnected(unit) then
				r, g, b = unpack(colors.disconnected)
			elseif UnitIsDead(unit) or UnitIsGhost(unit) then
				r, g, b = unpack(colors.dead)
			elseif UnitIsTapped(unit) and 
			not(UnitPlayerControlled(unit) or UnitIsTappedByPlayer(unit) or UnitIsTappedByAllThreatList(unit) or UnitIsFriend("player", unit)) then
				r, g, b = unpack(colors.tapped)
			else
				r, g, b = unpack(color[2])
			end
			Power:SetStatusBarColor(r, g, b)
		end
		
		if Power.PostUpdate then
			return Power:PostUpdate()
		end
	end
end

local Enable = function(self)
	local Power = self.Power
	if Power.frequent then
	
	else
		if Engine:IsBuild("Cata") then
			self:RegisterEvent("UNIT_POWER", Update)
			self:RegisterEvent("UNIT_MAXPOWER", Update)
		else
			self:RegisterEvent("UNIT_MANA", Update)
			self:RegisterEvent("UNIT_RAGE", Update)
			self:RegisterEvent("UNIT_FOCUS", Update)
			self:RegisterEvent("UNIT_ENERGY", Update)
			self:RegisterEvent("UNIT_RUNIC_POWER", Update)
			self:RegisterEvent("UNIT_MAXMANA", Update)
			self:RegisterEvent("UNIT_MAXRAGE", Update)
			self:RegisterEvent("UNIT_MAXFOCUS", Update)
			self:RegisterEvent("UNIT_MAXENERGY", Update)
			self:RegisterEvent("UNIT_DISPLAYPOWER", Update)
			self:RegisterEvent("UNIT_MAXRUNIC_POWER", Update)
		end
		self:RegisterEvent("PLAYER_ENTERING_WORLD", Update)
	end
end

local Disable = function(self)
	local Power = self.Power
	if Power.frequent then
	
	else
		if Engine:IsBuild("Cata") then
			self:UnregisterEvent("UNIT_POWER", Update)
			self:UnregisterEvent("UNIT_MAXPOWER", Update)
		else
			self:UnregisterEvent("UNIT_MANA", Update)
			self:UnregisterEvent("UNIT_RAGE", Update)
			self:UnregisterEvent("UNIT_FOCUS", Update)
			self:UnregisterEvent("UNIT_ENERGY", Update)
			self:UnregisterEvent("UNIT_RUNIC_POWER", Update)
			self:UnregisterEvent("UNIT_MAXMANA", Update)
			self:UnregisterEvent("UNIT_MAXRAGE", Update)
			self:UnregisterEvent("UNIT_MAXFOCUS", Update)
			self:UnregisterEvent("UNIT_MAXENERGY", Update)
			self:UnregisterEvent("UNIT_DISPLAYPOWER", Update)
			self:UnregisterEvent("UNIT_MAXRUNIC_POWER", Update)
		end
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", Update)
	end
end

Handler:RegisterElement("Power", Enable, Disable, Update)