-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon

local CDButton = {}
Delleren.CDButton = CDButton

local g_next_button = 1

-------------------------------------------------------------------------------
function CDButton:Create()
	local data = {
		spell      = 1;
		charges    = 1;
		maxcharges = 1;
		time       = 0;
		
	}
	
	data.frame = CreateFrame( "Button", "DellerenCDButton" .. g_next_button )
	data.frame.icon = data.frame:CreateTexture( nil, "BACKGROUND" )
	data.frame.icon:SetTexture( "Interface\\Icons\\INV_Misc_QuestionMark" )
	
	data.frame:SetSize( 
	
	Delleren:AddMasque( "CDBAR", data.frame, { Icon = data.frame.icon } )
	
	setmetatable( data, {__index = CDButton} )
	
	g_next_button = g_next_button + 1
end

-------------------------------------------------------------------------------
-- Update 
function CDButton:Update( spell, charges, maxcharges, outofrange )
	
end
