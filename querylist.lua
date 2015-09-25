-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon

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
	cancel    = nil;
	x         = 0;
	y         = 0;
}

-------------------------------------------------------------------------------
function Delleren.QueryList:Init()
	self.frame = CreateFrame( "Frame", "DellerenQueryList", UIParent )
	
	self.frame:SetSize( FRAMEWIDTH, 10 )
	
	self.frame.bg = self.frame:CreateTexture()
	self.frame.bg:SetTexture( 0,0,0 )
	self.frame.bg:SetAllPoints()
	self.frame:EnableMouse( true )
	
--	self.frame.highlight = self.frame:CreateTexture()
--	self.frame.highlight:SetTexture( 1, 1, 1, 0.25 )
--	self.frame.highlight:Hide()
	
	self.x, self.y = 1920, 1080 
	self.frame:SetPoint( "TOPLEFT", nil, "TOPLEFT", self.x, -self.y )
	self.frame:Show()
	
	self.frame:SetScript( "OnLeave", 
			function() 
				Delleren.QueryList:ClearEntryHighlight() 
			end )
	
	self:UpdateList( {
		{ name = "Delleren",  id = 115072 };
		{ name = "Llanna",    id = 121253 };
		{ name = "Poopsauce", id = 123986 };
	})
end

-------------------------------------------------------------------------------
function Delleren.QueryList:UpdateList( list, items )
	local count = 0
	for k,v in ipairs( list ) do
		count = count + 1
		
		if self.entries[count] == nil then
			self.entries[count] = self:CreateNewEntry( count )
		end
		self.entries[count].text:SetText( v.name )
		
		if not items then
			
			self:ShowEntry( count, v.name, { spell = v.id } )
		else
			self:ShowEntry( count, v.name, { item = v.id } )
		end
	end
	
	count = count + 1
	self:ShowEntry( count, "Cancel", { tex = "Interface\\ICONS\\trade_engineering" } )
	
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
end

-------------------------------------------------------------------------------
function Delleren.QueryList:ShowEntry( index, text, options )

	local frame = self.entries[index]
	if frame == nil then
		self.entries[index] = self:CreateNewEntry( index )
		frame = self.entries[index]
	end
		
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
	
	local frame = CreateFrame( "Frame", nil, self.frame )
	
	frame.entry_index = index
	
	local top = FRAMEPADDING+(index-1)*(ENTRYHEIGHT+ENTRYSPACING)
	frame:SetPoint( "TOPLEFT", FRAMEPADDING, -top )
	frame:SetPoint( "BOTTOMRIGHT", self.frame, "TOPRIGHT", 
					  -FRAMEPADDING, -(top + ENTRYHEIGHT) )
	
	
	frame.icon = frame:CreateTexture()
	frame.icon:SetSize( ENTRYHEIGHT, ENTRYHEIGHT )
	frame.icon:SetPoint( "TOPLEFT", 0, 0 )
	frame.icon:SetTexCoord( 0.1, 0.9, 0.1, 0.9 )
	
	frame.text = frame:CreateFontString()
	frame.text:SetFont( "Fonts\\ARIALN.TTF", FONTHEIGHT, "OUTLINE" ) 
	frame.text:SetPoint( "TOPLEFT", 20, 0 )
	frame.text:SetPoint( "RIGHT", 0 )
	frame.text:SetHeight( ENTRYHEIGHT )
	
	frame.highlight = frame:CreateTexture()
	frame.highlight:SetPoint( "TOPLEFT", -FRAMEPADDING, FRAMEPADDING )
	frame.highlight:SetPoint( "BOTTOMRIGHT", FRAMEPADDING, -FRAMEPADDING )
	frame.highlight:SetTexture( 1, 1, 1, 0.25 )
	
	frame:SetScript( "OnEnter", Delleren.QueryList.EntryFrameEntered )
	frame:SetScript( "OnLeave", Delleren.QueryList.EntryFrameLeft )
	frame:SetScript( "OnMouseDown", Delleren.QueryList.EntryFrameDown )
	frame:SetScript( "OnMouseUp", Delleren.QueryList.EntryFrameUp )
	frame:SetScript( "OnClicked", Delleren.QueryList.EntryFrameClicked )
		
	return frame
end

-------------------------------------------------------------------------------
function Delleren.QueryList.EntryFrameEntered( self )
	Delleren.QueryList:HighlightEntry( self.entry_index )
	self.highlight:Show()
end

-------------------------------------------------------------------------------
function Delleren.QueryList.EntryFrameLeft( self )
	Delleren.QueryList:ClearEntryHighlight( self.entry_index )
	self.highlight:Hide()
end

-------------------------------------------------------------------------------
function Delleren.QueryList.EntryFrameDown( self )
	Delleren.QueryList:HighlightEntry( self.entry_index )
	self.highlight:SetTexture( 1, 1, 1, 0.4 )
end

-------------------------------------------------------------------------------
function Delleren.QueryList.EntryFrameUp( self )	
	self.highlight:SetTexture( 1, 1, 1, 0.25 )
end

-------------------------------------------------------------------------------
function Delleren.QueryList:HighlightEntry( index )

	self.highlight_entry = index
	
	local top = (index-1) * (ENTRYHEIGHT + ENTRYSPACING)
	self.frame.highlight:SetPoint( "TOPLEFT", 0, -top )
	self.frame.highlight:SetPoint( "BOTTOMRIGHT", self.frame, "TOPRIGHT", 
								   0, -(top + ENTRYHEIGHT+FRAMEPADDING*2) )
	self.frame.highlight:Show()
end

-------------------------------------------------------------------------------
function Delleren.QueryList:ClearEntryHighlight( index )

	if self.highlight_entry == index then
		self.highlight_entry = nil
		self.frame.highlight:Hide()
	end
end

function Delleren.QueryList:OnUpdate()
	
end
