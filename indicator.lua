
-------------------------------------------------------------------------------
DellerenAddon.Indicator = {
	ani = {
		state    = "NONE";
		time     = 0;
		finished = true;
	}
	frame = nil
}

-------------------------------------------------------------------------------
function Delleren.Indicator:SetText( caption )
	self.frames.indicator.text:SetText( caption )
	self.frames.indicator.text:Show()
end

-------------------------------------------------------------------------------
function Delleren.Indicator:Init()
	self.frame = CreateFrame( "Button", "DellerenIndicator" ) 
	
end