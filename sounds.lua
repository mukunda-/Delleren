-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com) 
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon

local SharedMedia = LibStub("LibSharedMedia-3.0")

SharedMedia:Register( "sound", "Delleren-Call", "Interface\\Addons\\Delleren\\sounds\\ask.ogg"  )
SharedMedia:Register( "sound", "Delleren-Help", "Interface\\Addons\\Delleren\\sounds\\help.ogg" )
SharedMedia:Register( "sound", "Delleren-Fail", "Interface\\Addons\\Delleren\\sounds\\fail.ogg" )

-------------------------------------------------------------------------------
function Delleren:PlaySound( sound )
	
	local info = Delleren.Config.db.profile.sounds[sound]
	
	if info.enabled then
	
		PlaySoundFile( info.file, info.chan )
		
	end
end
