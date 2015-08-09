-------------------------------------------------------------------------------
-- Delleren
-- External CD caller.
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
--
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

DellerenAddon = LibStub("AceAddon-3.0"):NewAddon( "Delleren", 
	             		  "AceComm-3.0", "AceEvent-3.0", "AceSerializer-3.0",
						  "AceTimer-3.0" ) 


-------------------------------------------------------------------------------
DellerenAddon.help = {
	active = false; -- if we are currently being asked for a cd
	unit   = nil;   -- unitid that is asking for the cd
	spell  = nil;   -- spellid they are asking for
	pulse  = 0;     -- time for the next pulse animation
	rid    = 0;     -- request id
}

-------------------------------------------------------------------------------
DellerenAddon.statusmsg = {
	active = false; -- if we are about to send a status message
}

-------------------------------------------------------------------------------
DellerenAddon.status = {
	
}

-------------------------------------------------------------------------------
DellerenAddon.drag_stuff = {}
DellerenAddon.unlocked   = false
			  
-------------------------------------------------------------------------------
function DellerenAddon:InitMasque()
	local masque = LibStub( "Masque", true )
	
	if masque then
		self.masque_group = masque:Group( "Delleren", "Button" )
	end
	
end

-------------------------------------------------------------------------------
function DellerenAddon:InitVars()
	
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
	
	self.frames.indicator = frame
	
	local frame = CreateFrame( "Frame", "DellerenCDFrame" )
	frame:SetMovable( true )
	frame:EnableMouse( false )
	frame:Show()
end

-------------------------------------------------------------------------------
function DellerenAddon:Setup()
	self:InitMasque()
	
	self:InitFrames() 
	
	self.Indicator:Init()
	
	if self.masque_group then
		self.masque_group:ReSkin()
	end
end
