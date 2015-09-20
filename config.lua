-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local SharedMedia = LibStub("LibSharedMedia-3.0");

Delleren.Config = {}

local OptionsTable = {
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
				
				framesize = {
					name = "Frame Size";
					desc = "Size of the indicator frame.";
					type = "range";
					min  = 16;
					max  = 256;
					step = 1;
					set  = function( info, val )
						Delleren.Config:SetIndicatorScale( val )
					end;
					get  = function( info ) return Delleren.config.size end;
				};
				fontsize = {
					name = "Font Size";
					desc = "Size of the indicator font.";
					type = "range";
					min  = 4;
					max  = 32;
					step = 1;
					set  = function( info, val )
						Delleren.Config:SetIndicatorFontSize( val )
					end;
					get  = function( info ) return Delleren.config.fontsize end;
				};
				fontface = {
					name = "Font";
					desc = "Indicator font.";
					type = "select";
					values = { "aaa", "bbb", "ccc" }
				}
			};
			
		};
	};
}

-------------------------------------------------------------------------------
local ConfigDefaults = {
	size     = { "number", 48, 16, 256 };
	fontsize = { "number", 16, 4,  32  };
	font     = { "string", "Fonts\\FRIZQT__.TTF" };
	
};

-------------------------------------------------------------------------------
function Delleren.Config:Init()
	if self.init then return end
	self.init = true
	
	AceConfig:RegisterOptionsTable( "Delleren", OptionsTable )
end

-------------------------------------------------------------------------------
-- Open the configuration panel.
--
function Delleren.Config:Open()
	self:Init()	
	AceConfigDialog:Open( "Delleren" )
end

-------------------------------------------------------------------------------
local function Clamp( a, min, max )
	return math.min( math.max( a, min ), max )
end

-------------------------------------------------------------------------------
local function InitNumber( name, default, min, max )
	
	Delleren.config[name] = Clamp( 
		tonumber( Delleren.config[name] ) or default, min, max )
end

-------------------------------------------------------------------------------
local function InitString( name, default, min, max )
	
	Delleren.config[name] = tostring( Delleren.config[name] ) or value
		tonumber( Delleren.config[name] ) or value, min, max )
end

function Delleren.Config:InitDefaults

-------------------------------------------------------------------------------
-- Apply the configuration settings.
--
function Delleren.Config:Apply()
	
	local data = Delleren.config
	
	-- sanitize/initialize data
	InitNumber( "size", 48, 16, 256 )
	InitNumber( "fontsize", 16, 4, 32 )
	
	Delleren.Indicator:SetFrameSize( data.size )
	Delleren.Indicator:SetFontSize( data.fontsize )
	
	if not data.locked then
		Delleren:UnlockFrames()
	end
end

-------------------------------------------------------------------------------
function Delleren.Config:SetIndicatorScale( size )
	
	Delleren.config.size = size
	Delleren.Indicator:SetFrameSize( size ) 
	Delleren:ReMasque()
	
end

-------------------------------------------------------------------------------
function Delleren.Config:SetIndicatorFontSize( size )
	Delleren.config.fontsize = size
	Delleren.Indicator:SetFontSize( size )
end
