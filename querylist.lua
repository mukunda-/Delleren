-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon
local L = Delleren.Locale

local FRAMEPADDING = 3
local ENTRYHEIGHT  = 16
local FONTHEIGHT   = 12
local ENTRYSPACING = 3
local FRAMEWIDTH   = 120

-------------------------------------------------------------------------------
Delleren.QueryList = {
	frame     = nil;
	highlight = nil;
	highlight_entry = nil;
	entries   = {}; 
	x         = 0;
	y         = 0;
	called    = false;
}

-------------------------------------------------------------------------------
function Delleren.QueryList:Init()
	self.frame = CreateFrame( "Frame", "DellerenQueryList", UIParent )
	table.insert( UISpecialFrames, "DellerenQueryList" )
	
	self.frame:SetFrameStrata( "DIALOG" )
	self.frame:SetSize( FRAMEWIDTH, 10 )
	
	self.frame.bg = self.frame:CreateTexture()
	self.frame.bg:SetTexture( 0,0,0 )
	self.frame.bg:SetAllPoints()
	self.frame:EnableMouse( true )
	 
--	self.x, self.y = 1920, 1080 
--	self.frame:SetPoint( "TOPLEFT", nil, "TOPLEFT", self.x, -self.y )
--	self.frame:Show()
	
	self.frame:SetScript( "OnHide", Delleren.QueryList.OnHide )
	
	--[[self:UpdateList( {
		{ name = "Delleren",  id = 115072 };
		{ name = "Llanna",    id = 121253 };
		{ name = "Poopsauce", id = 123986 };
	})]]
end

-------------------------------------------------------------------------------
local function GetRealCursorPosition()
	local x, y = GetCursorPosition()
	x = x / (768 * GetMonitorAspectRatio())
	y = y / 768
	x = x * UIParent:GetWidth()
	y = y * UIParent:GetHeight()
	y = UIParent:GetHeight() - y
	
	return x, y
end

-------------------------------------------------------------------------------
function Delleren.QueryList:ShowList( list, items, position )

	if position then
		self.x, self.y = GetRealCursorPosition()
	end

	local count = 0
	count = count + 1
	self:ShowEntry( count, L["Cancel"], 
		{ tex = "Interface\\ICONS\\trade_engineering"; 
		  action = { type = "CANCEL" };
		})
	
	for k,v in ipairs( list ) do
		count = count + 1
		
		local action = { type = "CALL", index = k }
		
		if not items then
			
			self:ShowEntry( count, v.name, { spell = v.id, action = action } )
		else
			self:ShowEntry( count, v.name, { item = v.id, action = action } )
		end
	end
	
	local frameheight = FRAMEPADDING*2
	                     + count * (ENTRYHEIGHT+ENTRYSPACING) - ENTRYSPACING
	self.frame:SetHeight( frameheight )
	
	self.x = math.min( math.max( self.x, 0 ), GetScreenWidth() - FRAMEWIDTH )
	self.y = math.min( math.max( self.y, 0 ), GetScreenHeight() - frameheight )
	
	self.frame:SetPoint( "TOPLEFT", nil, "TOPLEFT", self.x, -self.y )
	
	count = count + 1
	for i = count, #self.entries do
		self:HideEntry( i )
	end 
	
	self.called = false
	self.frame:Show()
end

-------------------------------------------------------------------------------
function Delleren.QueryList:ShowEntry( index, text, options )

	local frame = self.entries[index]
	if frame == nil then
		self.entries[index] = self:CreateNewEntry( index )
		frame = self.entries[index]
	end
		
	frame.action = options.action
	frame.text:SetText( text )
	
	if options.tex then
	
		frame.icon:SetTexture( options.tex )
		
	elseif options.spell then
	
		local tex = select( 3, GetSpellInfo( options.spell ))
		frame.icon:SetTexture( tex )
		
	elseif options.item then
	
		local tex = select( 10, GetItemInfo( options.item ))
		frame.icon:SetTexture( tex )
		
	end
	
	frame:Show()
end

-------------------------------------------------------------------------------
function Delleren.QueryList:HideEntry( index )
	
	if self.entries[index] then
		self.entries[index]:Hide()
	end
end

-------------------------------------------------------------------------------
function Delleren.QueryList:CreateNewEntry( index )
	
	local frame = CreateFrame( "Button", nil, self.frame )
	
	frame.entry_index = index
	
	local top = FRAMEPADDING+(index-1)*(ENTRYHEIGHT+ENTRYSPACING)
	frame:SetPoint( "TOPLEFT", FRAMEPADDING, -top )
	frame:SetPoint( "BOTTOMRIGHT", self.frame, "TOPRIGHT", 
					  -FRAMEPADDING, -(top + ENTRYHEIGHT) )
	
	frame.highlight = frame:CreateTexture( nil, "BACKGROUND" )
	frame.highlight:SetPoint( "TOPLEFT", -FRAMEPADDING, FRAMEPADDING )
	frame.highlight:SetPoint( "BOTTOMRIGHT", FRAMEPADDING, -FRAMEPADDING )
	frame.highlight:SetTexture( 1, 1, 1, 0.25 )
	frame.highlight:Hide()
	
	frame.icon = frame:CreateTexture()
	frame.icon:SetSize( ENTRYHEIGHT, ENTRYHEIGHT )
	frame.icon:SetPoint( "TOPLEFT", 0, 0 )
	frame.icon:SetTexCoord( 0.1, 0.9, 0.1, 0.9 )
	
	frame.text = frame:CreateFontString()
	frame.text:SetFont( "Fonts\\ARIALN.TTF", FONTHEIGHT, "OUTLINE" ) 
	frame.text:SetPoint( "TOPLEFT", 20, 0 )
	frame.text:SetPoint( "RIGHT", 0 )
	frame.text:SetHeight( ENTRYHEIGHT )
	 
	frame:SetScript( "OnEnter", Delleren.QueryList.EntryFrameEntered )
	frame:SetScript( "OnLeave", Delleren.QueryList.EntryFrameLeft )
	frame:SetScript( "OnMouseDown", Delleren.QueryList.EntryFrameDown )
	frame:SetScript( "OnMouseUp", Delleren.QueryList.EntryFrameUp )
	frame:SetScript( "OnClick", Delleren.QueryList.EntryFrameClicked )
		
	return frame
end

-------------------------------------------------------------------------------
function Delleren.QueryList:Hide()
	self.frame:Hide()
end

-------------------------------------------------------------------------------
function Delleren.QueryList.EntryFrameEntered( frame )
	frame.highlight:Show()
end

-------------------------------------------------------------------------------
function Delleren.QueryList.EntryFrameLeft( frame )
	frame.highlight:Hide()
end

-------------------------------------------------------------------------------
function Delleren.QueryList.EntryFrameDown( frame )
	frame.highlight:SetTexture( 1, 1, 1, 0.4 )
end

-------------------------------------------------------------------------------
function Delleren.QueryList.EntryFrameUp( frame )	
	frame.highlight:SetTexture( 1, 1, 1, 0.25 )
end
 
-------------------------------------------------------------------------------
function Delleren.QueryList.EntryFrameClicked( frame )
	if frame.action then
		if frame.action.type == "CANCEL" then
			Delleren.QueryList.frame:Hide()
		elseif frame.action.type == "CALL" then
			Delleren.QueryList.called = true
			Delleren.Query:RequestManual( frame.action.index )
			Delleren.QueryList.frame:Hide()
		end
	end
end

-------------------------------------------------------------------------------
function Delleren.QueryList.OnHide( frame )
	if not Delleren.QueryList.called then
		Delleren.Query:Fail()
	end
end
