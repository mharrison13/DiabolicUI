local ADDON, Engine = ...
local L = Engine:GetLocale()

-- This module requires a "HIGH" priority, 
-- as other modules like the questtracker and the unitframes
-- hook themselves into its frames!
local Module = Engine:NewModule("ActionBars", "HIGH")

-- Lua API
local _G = _G
local ipairs = ipairs
local select = select
local table_insert = table.insert
local tonumber = tonumber
local unpack = unpack

-- WoW API
local CreateFrame = _G.CreateFrame
local GetAccountExpansionLevel = _G.GetAccountExpansionLevel
local GetScreenWidth = _G.GetScreenWidth
local GetTimeToWellRested = _G.GetTimeToWellRested
local GetXPExhaustion = _G.GetXPExhaustion
local HasArtifactEquipped = _G.HasArtifactEquipped
local IsXPUserDisabled = _G.IsXPUserDisabled
local IsPossessBarVisible = _G.IsPossessBarVisible
local SetActionBarToggles = _G.SetActionBarToggles
local UnitHasVehicleUI = _G.UnitHasVehicleUI
local UnitHasVehiclePlayerFrameUI = _G.UnitHasVehiclePlayerFrameUI
local UnitLevel = _G.UnitLevel
local UnitXP = _G.UnitXP
local UnitXPMax = _G.UnitXPMax

-- WoW tables and objects
local GameTooltip = _G.GameTooltip
local MAX_PLAYER_LEVEL_TABLE = _G.MAX_PLAYER_LEVEL_TABLE

-- Client version constants
local ENGINE_LEGION 	= Engine:IsBuild("Legion")
local ENGINE_WOD 		= Engine:IsBuild("WoD")
local ENGINE_MOP 		= Engine:IsBuild("MoP")
local ENGINE_CATA 		= Engine:IsBuild("Cata")

-- Whether or not the XP bar area is used.
-- This will return true for the artifact bar as well, 
-- and for reputation when we introduce reputation tracking.
Module.IsXPVisible = ENGINE_LEGION and function(self)
	local expacMax = MAX_PLAYER_LEVEL_TABLE[LE_EXPANSION_LEVEL_CURRENT or #MAX_PLAYER_LEVEL_TABLE]
	local playerMax = MAX_PLAYER_LEVEL_TABLE[GetAccountExpansionLevel() or #MAX_PLAYER_LEVEL_TABLE]
	local playerLevel = UnitLevel("player")

	if (playerLevel == playerMax) or (playerLevel >= expacMax) then

		-- honor bar if in a BG
		local hasHonorBar
		if (playerLevel >= expacMax) then
			local isInInstance, instanceType = IsInInstance()
			if (instanceType == "pvp") or (instanceType == "arena") then
				hasHonorBar = true
			end 
		end

		if UnitHasVehicleUI("player") or UnitHasVehiclePlayerFrameUI("player") then
			return false
		elseif HasArtifactEquipped() then
			return true, true, hasHonorBar
		else
			return hasHonorBar, false, hasHonorBar
		end

	else

		if IsXPUserDisabled() then
			return false
		elseif UnitHasVehicleUI("player") or UnitHasVehiclePlayerFrameUI("player") then
			return false
		else
			return true
		end

	end

end or ENGINE_CATA and function(self)
	if ((MAX_PLAYER_LEVEL_TABLE[GetAccountExpansionLevel() or #MAX_PLAYER_LEVEL_TABLE] or MAX_PLAYER_LEVEL_TABLE[#MAX_PLAYER_LEVEL_TABLE]) == UnitLevel("player")) then
		return false
	else
		if IsXPUserDisabled() then
			return false
		elseif UnitHasVehicleUI("player") or UnitHasVehiclePlayerFrameUI("player") then
			return false
		else
			return true
		end
	end

end or function(self)
	if ((MAX_PLAYER_LEVEL_TABLE[GetAccountExpansionLevel() or #MAX_PLAYER_LEVEL_TABLE] or MAX_PLAYER_LEVEL_TABLE[#MAX_PLAYER_LEVEL_TABLE]) == UnitLevel("player")) then
		return false
	else
		if IsXPUserDisabled() then
			return false
		elseif UnitHasVehicleUI("player") then
			return false
		else
			return true
		end
	end
end

Module.ApplySettings = Module:Wrap(function(self)
	local db = self.db
	local Main = self:GetWidget("Controller: Main"):GetFrame()

	-- Tell the secure environment about the number of visible bars
	-- This will also fire off an artwork update and sizing of bars and buttons!
	Main:SetAttribute("numbars", db.num_bars)
	Main:SetAttribute("numsidebars", db.num_side_bars)
end)

Module.GetBars = function(self)
	if (not self.bars) then
		self.bars = {}
	end
	return self.bars
end

Module.GetBinds = function(self)
	if not(self.binds) then
		self.binds = {}
	end
	return self.binds
end

Module.AddBar = function(self, bar, actionName)
	local bars = self:GetBars()
	local barNum = #bars + 1
	bars[barNum] = bar
	if actionName then
		self:GetBinds()[barNum] = actionName
	end
end

Module.OnInit = function(self, event, ...)
	self.config = self:GetDB("ActionBars") -- static config
	self.db = self:GetConfig("ActionBars", "character") -- per user settings for bars

	-- Enable controllers
	-- These mostly handle visibility, size and layout,
	-- so that other secure frames can anchor themselves to the bars.
	local main = self:GetWidget("Controller: Main")
	main:Enable()

	-- Set the keyword for our main controller, 
	-- as both the other widgets and other modules rely on it. 
	-- We upvalue it for faster reference, as we know it won't change.
	local Main = main:GetFrame()
	Engine:RegisterKeyword("Main", function() return Main end)

	-- Enable everything
	self:GetWidget("Controller: Pet"):Enable()
	self:GetWidget("Controller: Menu"):Enable()
	self:GetWidget("Controller: Chat"):Enable()

	self:GetWidget("Bar: Vehicle"):Enable()
	self:GetWidget("Bar: 1"):Enable()
	self:GetWidget("Bar: 2"):Enable()
	self:GetWidget("Bar: 3"):Enable()
	self:GetWidget("Bar: 4"):Enable()
	self:GetWidget("Bar: 5"):Enable()
	self:GetWidget("Bar: Pet"):Enable()
	self:GetWidget("Bar: Stance"):Enable() 
	self:GetWidget("Bar: XP"):Enable()
	self:GetWidget("Bar: Floaters"):Enable()

	self:GetWidget("Menu: Main"):Enable()
	self:GetWidget("Menu: Chat"):Enable()

	-- Add our bars to the registry, and register their action name for keybind grabbing
	self:AddBar(self:GetWidget("Bar: 1"):GetFrame(), "ACTIONBUTTON%d")
	self:AddBar(self:GetWidget("Bar: 2"):GetFrame(), "MULTIACTIONBAR1BUTTON%d")
	self:AddBar(self:GetWidget("Bar: 3"):GetFrame(), "MULTIACTIONBAR2BUTTON%d")
	self:AddBar(self:GetWidget("Bar: 4"):GetFrame(), "MULTIACTIONBAR3BUTTON%d")
	self:AddBar(self:GetWidget("Bar: 5"):GetFrame(), "MULTIACTIONBAR4BUTTON%d")
	self:AddBar(self:GetWidget("Bar: Pet"):GetFrame(), "BONUSACTIONBUTTON%d")
	self:AddBar(self:GetWidget("Bar: Stance"):GetFrame(), "SHAPESHIFTBUTTON%d")

	if ENGINE_CATA then
		--elf:GetWidget("Bar: Extra"):Enable() -- the extraactionbutton
		--self:AddBar(self:GetWidget("Bar: Extra"):GetFrame(), "EXTRAACTIONBUTTON%d")
	end
	
	-- Grab the blizzard UI keybinds for our own bars
	self:GetWidget("Keybinds"):Enable()

	-- Fire up the artwork
	self:GetWidget("Artwork"):Enable()

	-- WotLK didn't have an option to cast on key down, though the code and addons support it. 
	-- To better mimic future functionality, we splice the option into the blizzard interface menu, 
	-- and create a fake CVar for it so other modules easier can track changes to it. 
	--
	-- ...Is this something that should be baked into the handler itself...?
	-- 
	if (not ENGINE_CATA) then
		local value, defaultValue, serverStoredAccountWide, serverStoredPerCharacter = GetCVarInfo("ActionButtonUseKeyDown")
		if value == nil and defaultValue == nil and serverStoredAccountWide == nil and serverStoredPerCharacter == nil then
			RegisterCVar("ActionButtonUseKeyDown", false)
			hooksecurefunc("SetCVar", function(name, value) 
				if name == "ActionButtonUseKeyDown" then
					self:GetHandler("ActionButton"):OnEvent("CVAR_UPDATE", "ACTION_BUTTON_USE_KEY_DOWN", value)
					self.db.cast_on_down = GetCVarBool("ActionButtonUseKeyDown") and 1 or 0 -- store the change 
				end
			end)
			
			-- set the newly created CVar to our stored setting
			SetCVar("ActionButtonUseKeyDown", self.db.cast_on_down == 1 and "1" or "0")
		end
		
		-- add the button to the same menu as it's found in from Cata and up
		local name = "InterfaceOptionsCombatPanelActionButtonUseKeyDown"
		if (not _G[name]) then

			-- We're mimicking what blizzard do to create the button in Cata and higher here
			-- We can't directly add it to their system, though, because the menu is secure and that would taint it 
			local button = CreateFrame("CheckButton", "$parentActionButtonUseKeyDown", InterfaceOptionsCombatPanel, "InterfaceOptionsCheckButtonTemplate")
			button:SetPoint("TOPLEFT", button:GetParent():GetName().."SelfCastKeyDropDown", "BOTTOMLEFT", 14, -24)
			button:SetChecked(GetCVarBool("ActionButtonUseKeyDown"))
			button:SetScript("OnClick", function() 
				if button:GetChecked() then
					SetCVar("ActionButtonUseKeyDown", "1")
				else
					SetCVar("ActionButtonUseKeyDown", "0")
				end
				self:GetHandler("ActionButton"):OnEvent("CVAR_UPDATE", "ACTION_BUTTON_USE_KEY_DOWN", GetCVar("ActionButtonUseKeyDown"))
			end)
			_G[button:GetName() .. "Text"]:SetText(L["Cast action keybinds on key down"])
		end
	end
	
end

Module.OnEnable = function(self, event, ...)
	local BlizzardUI = self:GetHandler("BlizzardUI")
	BlizzardUI:GetElement("ActionBars"):Disable()
	BlizzardUI:GetElement("Alerts"):Disable()
	BlizzardUI:GetElement("LevelUpDisplay"):Disable()
	BlizzardUI:GetElement("Tutorials"):Disable()
	
	if ENGINE_LEGION then
		--BlizzardUI:GetElement("Menu_Panel"):Remove(5, "InterfaceOptionsActionBarsPanel")

		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsActionBarsPanelBottomLeft")
		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsActionBarsPanelBottomRight")
		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsActionBarsPanelRight")
		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsActionBarsPanelRightTwo")
		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsActionBarsPanelLockActionBars")
		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsActionBarsPanelPickupActionKeyDropDown")
		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsActionBarsPanelAlwaysShowActionBars")

	elseif ENGINE_WOD then
		BlizzardUI:GetElement("Menu_Panel"):Remove(6, "InterfaceOptionsActionBarsPanel")
	elseif ENGINE_MOP then
		BlizzardUI:GetElement("Menu_Panel"):Remove(6, "InterfaceOptionsActionBarsPanel")
		--BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsActionBarsPanelBottomLeft")
		--BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsActionBarsPanelBottomRight")
		--BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsActionBarsPanelRight")
		--BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsActionBarsPanelRightTwo")
		--BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsActionBarsPanelAlwaysShowActionBars")
		
	elseif ENGINE_CATA then
		BlizzardUI:GetElement("Menu_Panel"):Remove(6, "InterfaceOptionsActionBarsPanel")
	else
		BlizzardUI:GetElement("Menu_Panel"):Remove(6, "InterfaceOptionsActionBarsPanel")
		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsDisplayPanelShowFreeBagSpace")
	end
	
	-- In theory this shouldn't have any effect, but by removing the menu panels above, 
	-- we're preventing the blizzard UI from calling it, and for some reason it is 
	-- required to be called at least once, or the game won't fire off the events 
	-- that tell the UI that the player has an active pet out. 
	-- In other words: without it both the pet bar and pet unitframe will fail after a /reload
	SetActionBarToggles(nil, nil, nil, nil, nil)

	-- apply all module settings
	-- this also fires off the enabling and positioning of the actionbars
	self:ApplySettings()

end

