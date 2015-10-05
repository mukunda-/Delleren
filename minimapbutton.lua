-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon
local L = Delleren.Locale

Delleren.MinimapButton = {}

local LDB    = LibStub:GetLibrary( "LibDataBroker-1.1" )
local DBIcon = LibStub:GetLibrary( "LibDBIcon-1.0"     )

-------------------------------------------------------------------------------
function Delleren.MinimapButton:Init()
	
	self.data = LDB:NewDataObject( "Delleren", {
		type = "data source";
		text = "Delleren";
		icon = "Interface\\Icons\\Spell_Nature_LightningShield";
		OnClick = function(...) Delleren.MinimapButton:OnClick(...) end;
		OnEnter = function(...) Delleren.MinimapButton:OnEnter(...) end;
		OnLeave = function(...) Delleren.MinimapButton:OnLeave(...) end;
	});
end

-------------------------------------------------------------------------------
function Delleren.MinimapButton:OnLoad() 
	DBIcon:Register( "Delleren", self.data, Delleren.Config.db.profile.mmicon )
end

-------------------------------------------------------------------------------
function Delleren.MinimapButton:Show( show )
	if show then
		DBIcon:Show( "Delleren" )
	else
		DBIcon:Hide( "Delleren" )
	end
end

-------------------------------------------------------------------------------
function Delleren.MinimapButton:OnClick( frame, button )
	if button == "LeftButton" then
		if not IsShiftKeyDown() then
			Delleren:ToggleFrameLock()
		else
			Delleren.Ignore:OpenPanel()
		end
	elseif button == "RightButton" then
		self:ShowMenu()
	end
end
 
-------------------------------------------------------------------------------
local function InitializeMenu( self, level )
	local info
	
	local function AddMenuButton( text, func )
		info = UIDropDownMenu_CreateInfo()
		info.text = text
		info.func = func
		info.notCheckable = true
		UIDropDownMenu_AddButton( info, level )
	end
	
	local function AddSeparator()
		info = UIDropDownMenu_CreateInfo()
		info.notClickable = true
		info.disabled = true
		UIDropDownMenu_AddButton( info, level )
	end

	info = UIDropDownMenu_CreateInfo()
	info.text    = "Delleren"
	info.isTitle = true
	info.notCheckable = true
	UIDropDownMenu_AddButton( info, level )

	AddMenuButton( L["Open Ingore Panel"], function() Delleren.Ignore:OpenPanel() end )
	
	AddSeparator()
	
	AddMenuButton( L["Show Versions"], function() Delleren:WhoCommand() end )
	AddMenuButton( L["Open Configuration"], function() Delleren.Config:Open() end )
	
	AddSeparator()
	
	AddMenuButton( L["Close"], function() end )
end

-------------------------------------------------------------------------------
function Delleren.MinimapButton:ShowMenu()
	if not self.menu then
		self.menu = CreateFrame( "Button", "DellerenMenu", UIParent, "UIDropDownMenuTemplate" )
		self.menu.displayMode = "MENU"
	end
	 
	UIDropDownMenu_Initialize( DellerenMenu, InitializeMenu )
	UIDropDownMenu_SetWidth( DellerenMenu, 100 )
	UIDropDownMenu_SetButtonWidth( DellerenMenu, 124 ) 
	UIDropDownMenu_JustifyText( DellerenMenu, "LEFT" )
	
	local x,y = GetCursorPosition()
	local scale = UIParent:GetEffectiveScale()
	ToggleDropDownMenu( 1, nil, self.menu, "UIParent", x / scale, y / scale )
end

-------------------------------------------------------------------------------
function Delleren.MinimapButton:OnEnter( frame ) 
	-- Section the screen into 6 sextants and define the tooltip 
	-- anchor position based on which sextant the cursor is in.
	-- Code taken from WeakAuras.
	--
    local max_x = 768 * GetMonitorAspectRatio()
    local max_y = 768
    local x, y = GetCursorPosition()
	
    local horizontal = (x < (max_x/3) and "LEFT") or ((x >= (max_x/3) and x < ((max_x/3)*2)) and "") or "RIGHT"
    local tooltip_vertical = (y < (max_y/2) and "BOTTOM") or "TOP"
    local anchor_vertical = (y < (max_y/2) and "TOP") or "BOTTOM"
    GameTooltip:SetOwner( frame, "ANCHOR_NONE" )
    GameTooltip:SetPoint( tooltip_vertical..horizontal, frame, anchor_vertical..horizontal )
	
	GameTooltip:ClearLines()
	GameTooltip:AddDoubleLine("Delleren", Delleren.version, 0, 0.7, 1, 1, 1, 1)
	GameTooltip:AddLine( " " )
	GameTooltip:AddLine( L["|cff00ff00Click|r to unlock frames."], 1, 1, 1 )
	GameTooltip:AddLine( L["|cff00ff00Shift-Click|r to open ignore panel."], 1, 1, 1 )
	GameTooltip:AddLine( L["|cff00ff00Right-click|r for options."], 1, 1, 1 )
	GameTooltip:Show();
end

-------------------------------------------------------------------------------
function Delleren.MinimapButton:OnLeave( frame ) 
	GameTooltip:Hide()
end
