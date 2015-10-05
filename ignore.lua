-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon
local L = Delleren.Locale

local BUTTON_WIDTH  = 120
local BUTTON_HEIGHT = 16
local ROWS = 8
local PADDING = 4
local FONTHEIGHT = 12

-------------------------------------------------------------------------------
Delleren.Ignore = {
	frame = nil; -- the ignore player panel
	buttons = {};
	
	ignored = {};
}

local ButtonFunctions = {}
local ButtonEvents = {}

-------------------------------------------------------------------------------
function Delleren.Ignore:InitPanel()
	if not self.frame then
		local frame = CreateFrame( "Frame", "DellerenIgnorePanel", UIParent )
		table.insert( UISpecialFrames, "DellerenIgnorePanel" )
		
		frame.bg = frame:CreateTexture()
		frame.bg:SetTexture( 0,0,0, 0.75 )
		frame.bg:SetAllPoints()
		frame:SetSize( 100, 50 )
		frame:SetPoint( "CENTER" )
		frame:Hide()
		
		self.frame = frame
		
		local closebutton = CreateFrame( "Button", "DellerenIgnoreClose", 
		                                 self.frame, "UIPanelButtonTemplate" )

		closebutton:SetWidth( 64 )
		closebutton:SetHeight( BUTTON_HEIGHT )
		closebutton:Show()
		closebutton:SetText( L["Close"] )
		closebutton:SetPoint( "BOTTOM", 0, PADDING )
		closebutton:SetScript( "OnClick", function() Delleren.Ignore.frame:Hide() end )
	end
	
	
end

-------------------------------------------------------------------------------
function Delleren.Ignore:Load()
	self.ignored = {}
	for k,v in pairs( Delleren.Config.db.char.ignored ) do
		self.ignored[k] = true
		Delleren.Status:CopyIgnore( k )
	end
end

-------------------------------------------------------------------------------
function Delleren.Ignore:Save()
	Delleren.Config.db.char.ignored = self.ignored
end

-------------------------------------------------------------------------------
function Delleren.Ignore:Reset()
	self.ignored = {}
	self:Save()
end

-------------------------------------------------------------------------------
function Delleren.Ignore:GetButton( index )
	local button = self.buttons[index]
	if not button then
		button = CreateFrame( "Button", nil, self.frame  )
		
		button.entry_index = index
		button.player = ""
	
		local left, top = math.floor((index-1) / ROWS) * (BUTTON_WIDTH+PADDING), 
		             ((index-1) % ROWS) * (BUTTON_HEIGHT+PADDING)
					 
		button.highlight = button:CreateTexture( nil, "BACKGROUND" )
		button.highlight:SetPoint( "TOPLEFT", -PADDING, PADDING )
		button.highlight:SetPoint( "BOTTOMRIGHT", PADDING, -PADDING )
		button.highlight:SetTexture( 1, 1, 1, 0.25 )
		button.highlight:SetBlendMode( "ADD" )
		button.highlight:Hide()
		
		
		button.red = button:CreateTexture( nil, "BACKGROUND" )
		button.red:SetPoint( "TOPLEFT", -PADDING, PADDING )
		button.red:SetPoint( "BOTTOMRIGHT", PADDING, -PADDING )
		button.red:SetTexture( 1, 0, 0, 0.5 )
		button.red:Hide()
		
		button.text = button:CreateFontString()
		button.text:SetFont( "Fonts\\ARIALN.TTF", FONTHEIGHT, "OUTLINE" ) 
		button.text:SetAllPoints()
	 
		button:SetWidth( BUTTON_WIDTH )
		button:SetHeight( BUTTON_HEIGHT )
		button:SetPoint( "TOPLEFT", PADDING + left, -PADDING - top )
		
		button:SetScript( "OnEnter",     ButtonEvents.ButtonEntered )
		button:SetScript( "OnLeave",     ButtonEvents.ButtonLeft    )
		button:SetScript( "OnMouseDown", ButtonEvents.ButtonDown    )
		button:SetScript( "OnMouseUp",   ButtonEvents.ButtonUp      )
		button:SetScript( "OnClick",     ButtonEvents.ButtonClicked )
		
		for k,v in pairs( ButtonFunctions ) do button[k] = v end
		
		self.buttons[index] = button
	end
	
	return button
end

-------------------------------------------------------------------------------
function ButtonFunctions:RefreshColor() 
	local _, cls = UnitClass( self.player )
	local color = { r = 1, g = 1, b = 1 }
	if cls then
		color = RAID_CLASS_COLORS[cls]
	end
	
	local ignored = Delleren.Ignore.ignored[ self.player ]
	self.text:SetTextColor( color.r, color.g, color.b, ignored and 0.25 or 1 )
	
	if ignored then
		self.red:Show()
	else
		self.red:Hide()
	end
end


-------------------------------------------------------------------------------
function ButtonFunctions:SetPlayer( player )
	self.player = player
	self.text:SetText( player )
	self:RefreshColor()
end

--[[
-------------------------------------------------------------------------------
local function ButtonFunctions:SetChecked( checked )
	self.checked = checked
	self.class = class
	self:RefreshColor()
end]]

-------------------------------------------------------------------------------
function ButtonEvents:ButtonEntered()
	self.highlight:Show()
end

-------------------------------------------------------------------------------
function ButtonEvents:ButtonLeft() 
	self.highlight:Hide()
end

-------------------------------------------------------------------------------
function ButtonEvents:ButtonDown()
	self.highlight:SetTexture( 1, 1, 1, 0.4 )
end

-------------------------------------------------------------------------------
function ButtonEvents:ButtonUp()	
	self.highlight:SetTexture( 1, 1, 1, 0.25 )
end
 
-------------------------------------------------------------------------------
function ButtonEvents:ButtonClicked()
	if not Delleren.Ignore.ignored[ self.player ] then
		Delleren.Ignore.ignored[ self.player ] = true
	else
		Delleren.Ignore.ignored[ self.player ] = nil
	end
	self:RefreshColor()
	Delleren.Ignore:Save()
	
	Delleren.Status:CopyIgnore( self.player )
end

-------------------------------------------------------------------------------
function Delleren.Ignore:OpenPanel()
	
	self:InitPanel()
	
	local count = 0
	for player in Delleren:IteratePlayers() do
		count = count + 1
		local button = self:GetButton( count )
		button:SetPlayer( player )
		button:Show()
	end
	
	if count == 0 then return end -- no players in party
	
	-- hide remaining buttons
	for i = count+1, #self.buttons do
		self.buttons[i]:Hide()
	end
	
	-- size frame
	local width = math.floor( (count-1) / ROWS ) + 1
	local height = math.min( count, ROWS )
	self.frame:SetWidth( (BUTTON_WIDTH+PADDING) * width + PADDING )
	self.frame:SetHeight( (BUTTON_HEIGHT+PADDING) * height + PADDING + 24 )
	
	self.frame:Show()
end

-------------------------------------------------------------------------------
function Delleren.Ignore:IsIgnored( name )
	return self.ignored[name]
end
