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
	
	data.frame = CreateFrame( "Button", "DellerenCDButton" .. g_next_button, UIParent, "UIPanelSquareButton" )
	data.frame.icon:SetTexture("Interface\\Icons\\Temp")
	--data.frame.icon = data.frame:CreateTexture( nil, "BACKGROUND" )
	--data.frame.icon:SetTexture( "Interface\\Icons\\INV_Misc_QuestionMark" ) 
	data.frame:SetSize( 64, 64 )
	data.frame:SetPoint( "CENTER", 0, 0 )
	data.frame:EnableMouse( true )
	data.frame:SetScript("OnClick", function() print('hi') end)
	data.frame:Disable()
	Delleren:AddMasque( "CDBAR", data.frame )
	
	for k,v in pairs( data.frame ) do
		print( k )
	end
	
	setmetatable( data, {__index = CDButton} )
	
	g_next_button = g_next_button + 1
	
	return data
end

-------------------------------------------------------------------------------
-- Update 
function CDButton:Update( spell, charges, maxcharges, outofrange )
	
end
