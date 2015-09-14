-------------------------------------------------------------------------------
-- Delleren
-- External CD caller.
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
--
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
DellerenAddon.Indicator = {
	ani = {
		state    = "NONE";
		time     = 0;
		finished = true;
	};
	frame = nil;
}

-------------------------------------------------------------------------------
function DellerenAddon.Indicator:SetText( caption )
	self.frames.indicator.text:SetText( caption )
	self.frames.indicator.text:Show()
end

-------------------------------------------------------------------------------
function DellerenAddon.Indicator:Init()
	local frame = CreateFrame( "Button", "DellerenIndicator" ) 
	self.frame = frame
	
	frame:SetMovable( true )
	frame:SetResizable( true )
	frame:SetMinResize( 16, 16 )
	frame:SetPoint( "CENTER", 0, 0 )
	frame:EnableMouse( false )
	frame:Hide()
	
	frame.text = frame:CreateFontString()
	frame.text:SetFont( "Fonts\\FRIZQT__.TTF", 16, "OUTLINE" ) 
	frame.text:SetPoint( "CENTER", self.frame, 0, 0 )
	frame.text:Hide()
	
	local icon = self.frame:CreateTexture( nil, "BACKGROUND" );
	icon:SetAllPoints( frame )
	frame.icon = icon
	icon:SetTexture( "Interface\\Icons\\spell_holy_painsupression" );
	
	if DellerenAddon.masque_group then
		--self.masque_group:AddButton( frame )
	end
end

-------------------------------------------------------------------------------
function DellerenAddon.Indicator:SetAnimation( source, state )

	if source == "QUERY" and DellerenAddon.help.active then 
		-- do not interfere with help interface
		return
	end
	 
	self.ani.state    = state
	self.ani.time     = GetTime()
	self.ani.finished = false
end

-------------------------------------------------------------------------------
function DellerenAddon.Indicator:UpdateAnimation()
	local t = GetTime() - self.ani.time
	
	if self.ani.state == "ASKING" then
		local r,g,b = ColorLerp( 1,1,1, 1,0.7,0.2, t / 0.25 )
		self.frame.icon:SetVertexColor( r, g, b, 1 )
		self.frame.text:SetTextColor( 1, 1, 1, 1 )
		if t >= 1.0 then self.ani.finished = true end
		
	elseif self.ani.state == "SUCCESS" then
		
		local a = 1.0 - math.min( t / 0.5, 1 )
		self.frame.icon:SetVertexColor( 0.3, 1, 0.3, a )
		self.frame.text:SetTextColor  ( 0.3, 1, 0.3, a )
		if t >= 0.5 then self.ani.finished = true end
		
	elseif self.ani.state == "FAILURE" then
	
		local a = 1.0 - math.min( t / 0.5, 1 )
		self.frame.icon:SetVertexColor( 1, 0.1, 0.2, a )
		self.frame.text:SetTextColor  ( 1, 0.1, 0.2, a )
		if t >= 0.5 then self.ani.finished = true end
		
	elseif self.ani.state == "POLLING" then
	
		local r,g,b = 0.25, 0.25, 0.6
		
		b = b + math.sin( GetTime() * 6.28 * 3 ) * 0.4
		
		r,g,b = ColorLerp( 1,1,1,r,g,b, t / 0.2 )
		self.frame.icon:SetVertexColor( r, g, b, 1 )
		self.frame.text:SetTextColor( 1,1,1,1 )
		if t >= 1.0 then self.ani.finished = true end
		
	elseif self.ani.state == "HELP" then
		local r,g,b = ColorLerp( 1,1,1, 0.5,0,0.5, t/0.25 )
		self.frame.icon:SetVertexColor( r, g, b, 1 )
		self.frame.text:SetTextColor( 1,1,1,1 )
		if t >= 1.0 then self.ani.finished = true end
	else
		self.frame.text:SetTextColor( 1,1,1,1 )
	end
end

-------------------------------------------------------------------------------
function DellerenAddon.Indicator:ShowHelpRequest( sender )
	self.help.active = true
	self.help.unit   = UnitIDFromName( sender )
	self.help.time   = GetTime()
	self.help.pulse  = GetTime() + 1
	self:PlaySound( "HELP" )
	
	self:SetIndicatorText( UnitName( self.help.unit ))
	self:SetAnimation( "HELP", "HELP" )
	self.frame:Show()
	
	-- TODO: move this?
	DellerenAddon:EnableFrameUpdates()
end

-------------------------------------------------------------------------------
function DellerenAddon.Indicator:Hide()
	
end