-------------------------------------------------------------------------------
-- Delleren
-- External CD caller.
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
--
-- See LICENSE.TXT
-------------------------------------------------------------------------------

DellerenAddon = LibStub("AceAddon-3.0"):NewAddon( "Delleren", 
	             		  "AceComm-3.0", "AceEvent-3.0", "AceSerializer-3.0",
						  "AceTimer-3.0" ) 
	
-------------------------------------------------------------------------------
DellerenAddon.query = {
	active     = false;	-- if we are currently asking for a cd
	time       = 0;     -- time that we changed states
	start_time = 0;     -- time that we started the query
	requested  = false; -- if a cd is being requested
	spell      = nil;   -- spellid we are asking for
	list       = {};    -- list of userids that have cds available
	unit       = nil;   -- unitid of person we want a cd from 
	rid        = 0;     -- request id
	buff       = false; -- if we are requesting a buff
}

-------------------------------------------------------------------------------
DellerenAddon.help = {
	active = false; -- if we are currently being asked for a cd
	unit   = nil;   -- unitid that is asking for the cd
	spell  = nil;   -- spellid they are asking for
	pulse  = 0;     -- time for the next pulse animation
	rid    = 0;     -- request id
}
			  
-------------------------------------------------------------------------------
function DellerenAddon:InitMasque()
	local masque = LibStub( "Masque", true )
	
	if masque then
		self.masque_group = masque:Group( "Delleren", "Button" )
	end
	
end

-------------------------------------------------------------------------------
function DellerenAddon:InitVars()

	self.frames = {}
	
	
	self.statusmsg = {
		active = false; -- if we are about to send a status message
	}
	
	self.drag_stuff = {}
	self.unlocked   = false
	
	self.SUPPORTED_CDS = {
		102342; -- ironbark
		114030; -- vigilance
		122844; -- painsup
		6940;   -- sac
		1022;   -- hand of protection
		1044;   -- hand of freedom
		47788;  -- guardian spirit
		116849; -- life cocoon
		116841; -- tiger's lust 
		114039; -- hand of purity 
	}
	
end

-------------------------------------------------------------------------------
function DellerenAddon:InitFrames()
	local frame = CreateFrame( "Button", "DellerenIndicator" ) 
	
	self:frames.indicator = frame
	
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

	if self.masque_group then
		--self.masque_group:AddButton( frame )
		self.masque_group:ReSkin()
	end
	
	local frame = CreateFrame( "Frame", "DellerenCDFrame" )
	frame:SetMovable( true )
	frame:EnableMouse( false )
	frame:Show()
end

-------------------------------------------------------------------------------
function DellerenAddon:Setup()
	self:InitVars()
	self:InitMasque()
	self:InitFrames() 
end
