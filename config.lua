-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local SharedMedia = LibStub("LibSharedMedia-3.0")

-------------------------------------------------------------------------------
local SOUND_CHANNELS = {
	["Master"]   = "Master";
	["SFX"]      = "Sound Effects";
	["Ambience"] = "Ambience";
	["Music"]    = "Music";
}

-------------------------------------------------------------------------------
Delleren.Config = {
	font_list = nil; 
}

-------------------------------------------------------------------------------
local function FindValueKey( table, value ) 
	for k,v in pairs( table ) do
		if v == value then return k end
	end
end

-------------------------------------------------------------------------------
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
					get  = function( info ) return Delleren.Config.db.profile.indicator.size end;
					order = 1;
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
					get  = function( info ) return Delleren.Config.db.profile.indicator.fontsize end;
					order = 2;
				};
				fontface = {
					name = "Font";
					desc = "Indicator font.";
					type = "select"; 
					set  = function( info, val )
						Delleren.Config:SetIndicatorFont( val )
					end;
					get  = function( info ) return FindValueKey( Delleren.Config.font_list, Delleren.Config.db.profile.indicator.font ) end;
					order = 3;
				};
				resetpos = {
					name = "Reset Position";
					desc = "Reset the indicator's position.";
					type = "execute";
					func = function() Delleren.Config:SetIndicatorPosition( 0, 0 ) end;
					order = 4;
				};
			};
			
		};
		
		sounds = {
			name = "Sounds";
			type = "group";
			args = {
				channel = {
					name = "Sound Channel:";
					desc = "Channel to play sounds on.";
					type = "select";
					values = SOUND_CHANNELS;
					set  = function( info, val ) Delleren.Config.db.profile.sound.channel = val end;
					get  = function( info ) return Delleren.Config.db.profile.sound.channel end;
					order = 1;
				}; 
			};
		};
	};
}

-------------------------------------------------------------------------------
local function InsertSoundOption( key, name, desc, order )


	OPTIONS_TABLE.args.sounds.args[key .. "_BREAK"] = {
		type = "header";
		name = "";
		order = order;
	}
	
	OPTIONS_TABLE.args.sounds.args[key] = {
		name = name;
		desc = desc;
		type = "select";
		values = "SOUND_LISTING"; -- replaced later
		set  = function( info, val ) Delleren.Config:SetSound( key, val ) end;
		get  = function( info ) return FindValueKey( Delleren.Config.sound_list, Delleren.Config.db.profile.sound.sounds[key].name ) end;
		order = order+1;
	}
	 
	OPTIONS_TABLE.args.sounds.args[key .. "_ENABLE"] = {
		name = "Enable";
		desc = "Enable this sound.";
		type = "toggle";
		set  = function( info, val ) Delleren.Config:SetSoundEnable( key, val ) end;
		get  = function( info ) return Delleren.Config.db.profile.sound.sounds[key].enabled end;
		order = order+2;
	}
	
end

InsertSoundOption( "CALL", "Call:", "Sound to play when making a call.", 10 )
InsertSoundOption( "HELP", "Help:", "Sound to play when being asked for help.", 20 )
InsertSoundOption( "FAIL", "Fail:", "Sound to play when something goes wrong.", 30 )

Delleren.Config.options = OPTIONS_TABLE
 
-------------------------------------------------------------------------------
local DB_DEFAULTS = {

	profile = {
	
		locked = false;
		
		indicator = {
			size     = 64;
			fontsize = 16;
			font     = "Arial Narrow";
			icon_x   = 0;
			icon_y   = 0;
		};
		
		sound = {
		
			channel = "Master";
		
			sounds = {
				
				CALL = {
					name    = "Delleren-Call";
					file    = nil; 
					enabled = true;
				};
				HELP = {
					name    = "Delleren-Help";
					file    = nil; 
					enabled = true;
				};
				FAIL = {
					name    = "Delleren-Fail";
					file    = nil; 
					enabled = true
				};
			};
		};
	};
}

-------------------------------------------------------------------------------
function Delleren.Config:CreateDB() 
	self.db = LibStub( "AceDB-3.0" ):New( 
					"DellerenAddonSaved", DB_DEFAULTS, true )
	
	self.db.RegisterCallback( self, "OnProfileChanged", "Apply" )
	self.db.RegisterCallback( self, "OnProfileCopied",  "Apply" )
	self.db.RegisterCallback( self, "OnProfileReset",   "Apply" )
end

-------------------------------------------------------------------------------
function Delleren.Config:Init()
	if self.init then return end
	self.init = true
	
	self.font_list  = SharedMedia:List( "font" )
	self.sound_list = SharedMedia:List( "sound" )
	
	self.options.args.indicator.args.fontface.values = self.font_list
	
	for k,v in pairs( self.options.args.sounds.args ) do
		if v.values == "SOUND_LISTING" then
			v.values = self.sound_list
		end
	end
	
	self.options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable( self.db )
	
	
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
function Delleren.Config:CacheSoundPaths()
	for k,v in pairs( self.db.profile.sound.sounds ) do
		v.file = SharedMedia:Fetch( "sound", v.name )
	end
end
 
-------------------------------------------------------------------------------
-- Apply the configuration settings.
--
function Delleren.Config:Apply()

	local data = self.db.profile
	    
	Delleren.Indicator:SetFrameSize( data.indicator.size )
	Delleren.Indicator:SetFontSize( data.indicator.fontsize )
	Delleren.Indicator:SetFont( SharedMedia:Fetch( "font", data.indicator.font ))
	Delleren.Indicator:SetPosition( data.indicator.x, data.indicator.y )
	
	self:CacheSoundPaths()
	
	if not data.locked then
		Delleren:UnlockFrames()
	end
end

-------------------------------------------------------------------------------
function Delleren.Config:SetIndicatorScale( size )
	
	self.db.profile.indicator.size = size
	Delleren.Indicator:SetFrameSize( size ) 
	Delleren:ReMasque()
	
end

-------------------------------------------------------------------------------
function Delleren.Config:SetIndicatorFontSize( size )
	self.db.profile.indicator.fontsize = size
	
	Delleren.Indicator:SetFontSize( size )
end

-------------------------------------------------------------------------------
function Delleren.Config:SetIndicatorFont( font )
	-- font is an index into font_list
	self.db.profile.indicator.font = self.font_list[font]
	
	Delleren.Indicator:SetFont( 
		SharedMedia:Fetch( "font", self.db.profile.indicator.font ))
	 
end

-------------------------------------------------------------------------------
function Delleren.Config:SetIndicatorPosition( x, y )
	self.db.profile.indicator.x = x
	self.db.profile.indicator.y = y
	
	Delleren.Indicator:SetPosition( x, y )
end

-------------------------------------------------------------------------------
function Delleren.Config:SetSound( key, val )
	val = self.sound_list[val]
	self.db.profile.sound.sounds[key].name = val
	self.db.profile.sound.sounds[key].file = SharedMedia:Fetch( "sound", val )
	PlaySoundFile( self.db.profile.sound.sounds[key].file, "Master" )
end

-------------------------------------------------------------------------------
function Delleren.Config:SetSoundEnable( key, val )
	self.db.profile.sound.sounds[key].enabled = val
end
