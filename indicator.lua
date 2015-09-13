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
	frame.text:SetPoint( "CENTER", g_frame, 0, 0 )
	frame.text:Hide()
	
	local icon = g_frame:CreateTexture( nil, "BACKGROUND" );
	icon:SetAllPoints( frame )
	frame.icon = icon
	icon:SetTexture( "Interface\\Icons\\spell_holy_painsupression" );
	
	if DellerenAddon.masque_group then
		--self.masque_group:AddButton( frame )
	end
end
