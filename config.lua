-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local options_table = {
	type = "group";
	
	args = {
		lockframes = {
			name = "Lock Frames";
			desc = "Locks/Unlocks frames to be moved.";
			type = "toggle";
			set = function(info,val) 
				Delleren:ToggleFrameLock()
			end;
			get = function(info) return not Delleren.unlocked end;
		};
		indicator = {
			name = "Indicator";
			type = "group";
			args = {
				
				
				
			};
		};
	};
}

Delleren.Config = {}

-------------------------------------------------------------------------------
function Delleren.Config:Init()
	if self.init then return end
	self.init = true
	
	AceConfig:RegisterOptionsTable( "Delleren", options_table )
end

-------------------------------------------------------------------------------
-- Open the configuration panel.
--
function Delleren.Config:Open()
	self:Init()	
	AceConfigDialog:Open( "Delleren" )
end
