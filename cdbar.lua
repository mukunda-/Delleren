-------------------------------------------------------------------------------
-- Delleren
-- External CD caller.
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
--
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon
local L        = Delleren.Locale

Delleren.CDBar = {
	frame    = nil;
	buttons  = {};
	unlocked = false;
}

-------------------------------------------------------------------------------
Delleren:AddSetup( function ()
	local self = Delleren.CDBar
	
	self.frame = CreateFrame( "Frame", "DellerenCDBar", UIParent )
	self.frame:SetPoint( "CENTER", 0, 0 )
	self.frame:SetSize( 64,64 )
end)

-------------------------------------------------------------------------------
function Delleren.CDBar:UpdateButtons( data )
	if not Delleren.Config.db.profile.cdbar.enabled then return end
	
	local relayout = false
	for k,v in ipairs( data ) do
		if not self.buttons[k] then
			self.buttons[k] = Delleren.CDButton:Create( self.frame )
			
			if self.unlocked 
			   or not Delleren.Config.db.profile.cdbar.enable_mouse then
			   
				self.buttons[k]:EnableMouse( false )
			end
			relayout = true
		end
		
		self.buttons[k]:Update( v.spell, v.stacks, v.disabled, 
		                   v.time, v.duration, v.outrange )
	end
	
	for i = #data+1, #self.buttons do
		self.buttons[i]:Hide()
	end
	
	if relayout then
		self:UpdateLayout()
	end
end

-------------------------------------------------------------------------------
function Delleren.CDBar:UpdateLayout()
	local size, columns, padding = Delleren.Config.db.profile.cdbar.size, 
								   Delleren.Config.db.profile.cdbar.columns, 
								   Delleren.Config.db.profile.cdbar.padding
	
	for i = 1, #self.buttons do
		local x = ((i-1) % columns) * (size+padding)
		local y = math.floor((i-1) / columns) * (size+padding)
		
		self.buttons[i]:SetPosition( self.frame, x, -y )
		
		self.buttons[i]:SetSize( size, size )
	end
	
	local maxcols = math.min( #Delleren.Config.tracked_spell_data, columns )
	maxcols = math.max( maxcols, 1 )
	
	local maxrows = math.floor((#Delleren.Config.tracked_spell_data-1)/columns)+1
	
	local framewidth  = math.max( maxcols * (size+padding) - padding, 64 )
	local frameheight = math.max( maxrows * (size+padding) - padding, 32 )
	
	self.frame:SetSize( framewidth, frameheight )
	
	Delleren.Config.db.profile.cdbar.x = math.max( Delleren.Config.db.profile.cdbar.x, -GetScreenWidth()/2 )
	Delleren.Config.db.profile.cdbar.y = math.max( Delleren.Config.db.profile.cdbar.y, -GetScreenHeight()/2+8 )
	Delleren.Config.db.profile.cdbar.x = math.min( Delleren.Config.db.profile.cdbar.x,  GetScreenWidth()/2-8 )
	Delleren.Config.db.profile.cdbar.y = math.min( Delleren.Config.db.profile.cdbar.y,  GetScreenHeight()/2 )
			
	self.frame:SetPoint( "TOPLEFT", nil, "CENTER", 
							Delleren.Config.db.profile.cdbar.x,
							Delleren.Config.db.profile.cdbar.y )
							
	if Delleren.Config.db.profile.cdbar.enable_mouse then
		
		self:EnableMouse()
	else
		self:DisableMouse()
	end
	
	if Delleren.Config.db.profile.cdbar.enabled then
		self.frame:Show()
	else
		self.frame:Hide()
	end
	
	Delleren:ReMasque()
end

-------------------------------------------------------------------------------
function Delleren.CDBar:Refresh()
	local data = Delleren.Status:BuildCDBarData()
	
	self:UpdateButtons( data )
end

-------------------------------------------------------------------------------
function Delleren.CDBar:EnableMouse()
	if Delleren.Config.db.profile.cdbar.enable_mouse and not self.unlocked then
		for k,v in pairs( self.buttons ) do
			v:EnableMouse()
		end
	end
end

-------------------------------------------------------------------------------
function Delleren.CDBar:DisableMouse()
	for k,v in pairs( self.buttons ) do
		v:DisableMouse()
	end
end

-------------------------------------------------------------------------------
function Delleren.CDBar:Unlock()
	
	if self.unlocked then return end
	self.unlocked = true
	
	self:DisableMouse()
	
	if not self.dragframe then
		self.dragframe = CreateFrame( "Frame", "DellerenCDBarTitleFrame", self.frame )
		self.dragframe:SetAllPoints()
		
		local green = self.dragframe:CreateTexture()
		green:SetAllPoints()
		green:SetTexture( 0, 0.5, 0, 0.4 )
		green:Show()
		self.dragframe:SetFrameStrata("HIGH")
		
		self.dragframe.text = self.dragframe:CreateFontString()
		self.dragframe.text:SetFont( "Fonts\\FRIZQT__.TTF", 10, "OUTLINE" ) 
		self.dragframe.text:SetText( L["Delleren CDBar"] )
		self.dragframe.text:SetPoint( "CENTER", self.dragframe )
		
		self.frame:SetScript("OnMouseDown", function(self,button)
			if button == "LeftButton" then
				self:SetMovable( true )
				self:StartMoving()
			end
		end)
		
		self.frame:SetScript( "OnMouseUp", function(self)
			self:StopMovingOrSizing()
			self:SetMovable( false )
			
			-- fixup to use center anchor
			local x,y = self:GetLeft(), self:GetTop()
			x = x - GetScreenWidth() / 2 
			y = y - GetScreenHeight() / 2
			x = math.max( x, -GetScreenWidth()/2 )
			y = math.max( y, -GetScreenHeight()/2+8 )
			x = math.min( x, GetScreenWidth()/2-8 )
			y = math.min( y, GetScreenHeight()/2 )
			self:ClearAllPoints()
			self:SetPoint( "TOPLEFT", nil, "CENTER", x, y )
			
			Delleren.Config.db.profile.cdbar.x = x
			Delleren.Config.db.profile.cdbar.y = y
			
		end)
	end
	
	self.dragframe:Show()
	self.frame:EnableMouse( true )
	
	-- for some reason clicking the buttons unparents the icons
	DellerenAddon:ReMasque()
end

-------------------------------------------------------------------------------
function Delleren.CDBar:Lock()
	if not self.unlocked then return end
	self.unlocked = false
	
	self:EnableMouse()
	
	self.dragframe:Hide()
	self.frame:EnableMouse( false )
end
