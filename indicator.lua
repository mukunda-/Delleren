-------------------------------------------------------------------------------
-- Delleren
-- External CD caller.
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
--
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon

-------------------------------------------------------------------------------
Delleren.Indicator = {
	ani = {
		state    = "NONE";
		time     = 0;
		finished = true;
	};
	font = "Fonts\\FRIZQT__.TTF";
	fontsize = 16;
	frame = nil;
	shown = false;
}

-------------------------------------------------------------------------------
-- Interpolates two sets of color components.
--
local function ColorLerp( r1, g1, b1, r2, g2, b2, a )
	a = math.min( a, 1 )
	a = math.max( a, 0 )
	return r1 + (r2-r1) * a, 
	       g1 + (g2-g1) * a, 
		   b1 + (b2-b1) * a
end

-------------------------------------------------------------------------------
function Delleren.Indicator:Desaturate( desaturate )
	self.frame.icon:SetDesaturated( desaturate )
end

-------------------------------------------------------------------------------
-- Returns true if the indicator is in the middle of an animation.
--
function Delleren.Indicator:Animating()
	return not self.ani.finished
end

-------------------------------------------------------------------------------
function Delleren.Indicator:SetText( caption )
	self.frame.text:SetText( caption )
	self.frame.text:Show()
end

-------------------------------------------------------------------------------
function Delleren.Indicator:HideText()
	self.frame.text:SetText("")
end

-------------------------------------------------------------------------------
function Delleren.Indicator:Init()
	local frame = CreateFrame( "Button", "DellerenIndicator", UIParent )
	self.frame = frame
	
	--
	--frame:SetResizable( true )
	--frame:SetMinResize( 16, 16 )
	frame:SetPoint( "CENTER", nil, 0, 0 )
	frame:EnableMouse( false )
	frame:Hide()
	
	frame.text = frame:CreateFontString()
	frame.text:SetFont( "Fonts\\FRIZQT__.TTF", 16, "OUTLINE" ) 
	frame.text:SetPoint( "CENTER", self.frame, 0, 0 )
	frame.text:Hide()
	
	local icon = self.frame:CreateTexture( nil, "BACKGROUND" )
	icon:SetAllPoints( frame )
	frame.icon = icon
	icon:SetTexture( "Interface\\Icons\\spell_holy_sealofsacrifice" )
	
	Delleren:AddMasque( "BUTTON", frame, {Icon = frame.icon} )
end

-------------------------------------------------------------------------------
function Delleren.Indicator:SetAnimation( source, state )

	if source == "QUERY" and Delleren.Help.active then 
		-- do not interfere with help interface
		return
	end
	 
	self.ani.state    = state
	self.ani.time     = GetTime()
	self.ani.finished = false
end

-------------------------------------------------------------------------------
function Delleren.Indicator:UpdateAnimation()
	local t = GetTime() - self.ani.time
	
	if self.ani.state == "ASKING" then
		local r,g,b = ColorLerp( 1,1,1, 1,0.7,0.2, t / 0.25 )
		self.frame.icon:SetVertexColor( r, g, b, 1 )
		self.frame:SetAlpha( 1 )
		self.frame.text:SetTextColor( 1, 1, 1, 1 )
		self:Desaturate( true )
		if t >= 1.0 then self.ani.finished = true end
		
	elseif self.ani.state == "SUCCESS" then
		
		local a = 1.0 - math.min( t / 0.5, 1 )
		self.frame.icon:SetVertexColor( 0.3, 1, 0.3, 1 )
		self.frame:SetAlpha( a )
		self.frame.text:SetTextColor  ( 0.3, 1, 0.3, 1 )
		self:Desaturate( true )
		if t >= 0.5 then self.ani.finished = true end
		
	elseif self.ani.state == "FAILURE" then
	
		local a = 1.0 - math.min( t / 0.5, 1 )
		self.frame.icon:SetVertexColor( 1, 0.1, 0.2, 1)
		self.frame:SetAlpha( a )
		self.frame.text:SetTextColor  ( 1, 0.1, 0.2, 1 )
		self:Desaturate( true )
		if t >= 0.5 then self.ani.finished = true end
		
	elseif self.ani.state == "POLLING" then
	
		local r,g,b = 0.25, 0.25, 0.6
		
		b = b + math.sin( GetTime() * 6.28 * 3 ) * 0.4
		
		r,g,b = ColorLerp( 1,1,1,r,g,b, t / 0.2 )
		self.frame.icon:SetVertexColor( r, g, b, 1 )
		self.frame:SetAlpha( 1 )
		self.frame.text:SetTextColor( 1,1,1,1 )
		self:Desaturate( true )
		if t >= 1.0 then self.ani.finished = true end
		
	elseif self.ani.state == "HELP" then
		local r,g,b = ColorLerp( 1,1,1, 0.5,0,0.5, t/0.25 )
		self.frame.icon:SetVertexColor( r, g, b, 1 )
		self.frame.text:SetTextColor( 1,1,1,1 )
		self.frame:SetAlpha( 1 )
		self:Desaturate( false )
		if t >= 1.0 then self.ani.finished = true end
	else
		self.frame.text:SetTextColor( 1,1,1,1 )
	end
end
--[[
-------------------------------------------------------------------------------
function Delleren.Indicator:ShowHelpRequest( sender )
	self.help.active = true
	self.help.unit   = UnitIDFromName( sender )
	self.help.time   = GetTime()
	self.help.pulse  = GetTime() + 1
	self:PlaySound( "HELP" )
	
	self:SetIndicatorText( UnitName( self.help.unit ))
	self:SetAnimation( "HELP", "HELP" )
	self.frame:Show()
	
	-- TODO: move this?
	Delleren:EnableFrameUpdates()
end]]

-------------------------------------------------------------------------------
function Delleren.Indicator:Hide()
	self.frame:Hide()
	self.shown = false
end

-------------------------------------------------------------------------------
function Delleren.Indicator:Show()
	self.frame:Show()
	self.shown = true
end

-------------------------------------------------------------------------------
function Delleren.Indicator:SetIcon( icon )
	self.frame.icon:SetTexture( icon )
end

-------------------------------------------------------------------------------
function Delleren.Indicator:SetIconID( id, item )
	
	local icon
	if not item then
		icon = select( 3, GetSpellInfo( id ))
	else
		icon = select( 10, GetItemInfo( id ))
	end
	
	self.frame.icon:SetTexture( icon )
end

-------------------------------------------------------------------------------
function Delleren.Indicator:EnableDragging( icon )

	if self.dragframe == nil then
		local green = self.frame:CreateTexture()
		green:SetAllPoints()
		green:SetTexture( 0, 0.5, 0, 0.4 )
		
	--	green.text = self.frame:CreateFontString()
	--	green.text:SetFont( "Fonts\\FRIZQT__.TTF", 8, "OUTLINE" ) 
	--	green.text:SetPoint( "CENTER", green, 0, 0 )
	--	green.text:SetText( "Delleren Indicator\nRight click to lock." )
		
		self.frame:SetScript("OnMouseDown", function(self,button)
			if button == "LeftButton" then
				self:SetMovable( true )
				self:StartMoving()
			else
				Delleren:LockFrames()
			end
		end)
		
		self.frame:SetScript( "OnMouseUp", function(self)
			self:StopMovingOrSizing()
			self:SetMovable( false )
			
			-- fixup to use center anchor
			local x, y = self:GetCenter()
			x = x - GetScreenWidth() / 2 
			y = y - GetScreenHeight() / 2 
			x = math.max( x, -GetScreenWidth()/2 )
			y = math.max( y, -GetScreenHeight()/2 )
			x = math.min( x, GetScreenWidth()/2 )
			y = math.min( y, GetScreenHeight()/2 )
			
			self:ClearAllPoints()
			self:SetPoint( "CENTER", x, y )
			
			Delleren.Config.db.profile.indicator.x = x
			Delleren.Config.db.profile.indicator.y = y
			
		end)
		
		self.dragframe = green
	end
	
	if not Delleren.Query.active and not Delleren.Help.active then
		--self:HideText()
		self:SetText( "Delleren\nRight-click to lock." )
	end
	
	self.dragframe:Show()
	--self.dragframe.text:Show()
	
	self.frame:EnableMouse( true )
	self.frame:SetAlpha( 1 )
	self.frame:Show()
end

-------------------------------------------------------------------------------
function Delleren.Indicator:DisableDragging( icon )
	
	if self.dragframe then
		self.dragframe:Hide()
--		self.dragframe.text:Hide()
	end
	
	self.frame:EnableMouse( false )
	
	if not Delleren.Query.active and not Delleren.Help.active then
		self.frame:Hide()
	end
end

-------------------------------------------------------------------------------
function Delleren.Indicator:SetFontSize( size )
	if size < 4 then size = 4 end
	if size > 32 then size = 32 end
	self.fontsize = size
	
	self.frame.text:SetFont( self.font, size, "OUTLINE" )
end

-------------------------------------------------------------------------------
function Delleren.Indicator:SetFont( font )

	self.font = font
	self.frame.text:SetFont( font, self.fontsize, "OUTLINE" )
end

-------------------------------------------------------------------------------
function Delleren.Indicator:SetFrameSize( size )
	
	size = math.max( size, 16 )
	size = math.min( size, 256 )
	
	self.frame:SetSize( size, size )
	
	Delleren:ReMasque()
end

-------------------------------------------------------------------------------
function Delleren.Indicator:SetPosition( x, y )
	x = math.max( x, -GetScreenWidth()/2 )
	y = math.max( y, -GetScreenHeight()/2 )
	x = math.min( x, GetScreenWidth()/2 )
	y = math.min( y, GetScreenHeight()/2 )
	self.frame:SetPoint( "CENTER", x, y )
end
