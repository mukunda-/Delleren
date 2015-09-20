-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local SharedMedia = LibStub("LibSharedMedia-3.0");



Delleren.Config = {
	font_list = {};
	selected_font = 1;
}

local OPTIONS_TABLE = {
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
					get  = function( info ) 
						return Delleren.config.size 
					end;
				};
				fontsize = {
					name = "Font Size";
					desc = "Size of the indicator font.";
					type = "range";
					min  = 4;
					max  = 24;
					step = 1;
					set  = function( info, val )
						Delleren.Config:SetIndicatorFontSize( val )
					end;
					get  = function( info ) 
						return Delleren.config.fontsize 
					end;
				};
				fontface = {
					name = "Font";
					desc = "Indicator font.";
					type = "select";
					values = Delleren.Config.font_list;
					set  = function( info, val )
						Delleren.Config:SetIndicatorFont( val )
					end;
					get  = function( info ) 
						return Delleren.Config.selected_font 
					end;
				};
				resetpos = {
					name = "Reset Position";
					desc = "Reset the indicator's position.";
					type = "execute";
					func = function()
						Delleren.Config:SetIndicatorPosition( 0, 0 )
					end
				};
			};
			
		};
	};
}

Delleren.Config.options = OPTIONS_TABLE

-------------------------------------------------------------------------------
local ConfigDefaults = {
	size     = { "number", 48, 16, 256 };
	fontsize = { "number", 16, 4,  24  };
	font     = { "string", "Arial Narrow" };
	indicator_x = { "number", 0, -9999, 9999 };
	indicator_y = { "number", 0, -9999, 9999 };
};

-------------------------------------------------------------------------------
local DB_DEFAULTS = {
	profile = {
		size     = 48;
		fontsize = 16;
		font     = "Arial Narrow";
		icon_x   = 0;
		icon_y   = 0;
	};
}

-------------------------------------------------------------------------------
function Delleren.Config:CreateDB() 
	self.db = LibStub( "AceDB-3.0" ):New( 
					"DellerenAddonSaved", DB_DEFUALTS, true )
end

-------------------------------------------------------------------------------
function Delleren.Config:Init()
	if self.init then return end
	self.init = true
	
	for k,v in ipairs( SharedMedia:List( "font" ) ) do
		table.insert( self.font_list, v )
		if v == Delleren.config.font then
			self.selected_font = #self.font_list
		end
	end
	
	AceConfig:RegisterOptionsTable( "Delleren", self.options )
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
local function InitNumber( name, def, min, max )
	
	Delleren.config[name] = Clamp( 
		tonumber( Delleren.config[name] ) or def, min, max )
end

-------------------------------------------------------------------------------
local function InitString( name, def )
	
	Delleren.config[name] = tostring( Delleren.config[name] ) or def 
end

-------------------------------------------------------------------------------
function Delleren.Config:InitDefaults()

	-- sanitize/initialize config values
	
	local data = Delleren.config
	for k,v in pairs( ConfigDefaults ) do
		if v[1] == "number" then
			InitNumber( k, v[2], v[3], v[4] )
		elseif v[1] == "string" then
			InitString( k, v[2] )
		end
	end
end

-------------------------------------------------------------------------------
-- Apply the configuration settings.
--
function Delleren.Config:Apply()
	
	self:InitDefaults()
	
	local data = Delleren.config 
	
	Delleren.Indicator:SetFrameSize( data.size )
	Delleren.Indicator:SetFontSize( data.fontsize )
	Delleren.Indicator:SetFont( SharedMedia:Fetch( "font", data.font ))
	Delleren.Indicator:SetPosition( data.indicator_x, data.indicator_y )
	
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

-------------------------------------------------------------------------------
function Delleren.Config:SetIndicatorFont( font )
	-- font is an index into font_list
	
	Delleren.config.font = self.font_list[font]
	
	Delleren.Indicator:SetFont( 
		SharedMedia:Fetch( "font", Delleren.config.font ))
	
	self.selected_font = font
end

-------------------------------------------------------------------------------
function Delleren.Config:SetIndicatorPosition( x, y )
	Delleren.config.indicator_x = x
	Delleren.config.indicator_y = y
	
	Delleren.Indicator:SetPosition( x, y )
end
