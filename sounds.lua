-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com) 
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon

local SharedMedia = LibStub("LibSharedMedia-3.0")

SharedMedia:Register( "sound", "Delleren-Call",    "Interface\\Addons\\Delleren\\sounds\\ask.ogg"     )
SharedMedia:Register( "sound", "Delleren-ManCall", "Interface\\Addons\\Delleren\\sounds\\mancall.ogg" )
SharedMedia:Register( "sound", "Delleren-Help",    "Interface\\Addons\\Delleren\\sounds\\help.ogg"    )
SharedMedia:Register( "sound", "Delleren-Fail",    "Interface\\Addons\\Delleren\\sounds\\fail.ogg"    )
SharedMedia:Register( "sound", "Delleren-Good",    "Interface\\Addons\\Delleren\\sounds\\good.ogg"    )

-------------------------------------------------------------------------------
function Delleren:PlaySound( sound )
	local cfg = Delleren.Config.db.profile.sound
	
	local info = cfg.sounds[sound]
	
	if info.enabled then
	
		PlaySoundFile( info.file, cfg.channel )
		
	end
end
