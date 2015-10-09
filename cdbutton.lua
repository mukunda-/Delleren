-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon

local CDButton = {}
Delleren.CDButton = CDButton

local g_next_button = 1

local STACKFONT = "Fonts\\ARIALN.TTF"

-------------------------------------------------------------------------------
function CDButton:Create( parent )
	local data = {
		spell      = 1;
		stacks     = 1;
		outrange   = false;
		time       = 0;
		duration   = 0;
		hidden     = false;
	}
	
	data.frame = CreateFrame( "Button", "DellerenCDButton" .. g_next_button,
							  parent, "UIPanelSquareButton" )
	data.frame.cooldown = CreateFrame( "Cooldown", 
							"DellerenCDButton" .. g_next_button .. "Cooldown", 
							data.frame, "CooldownFrameTemplate" )
			
	data.frame.cooldown:SetAllPoints()
	data.frame.cooldown:SetDrawEdge( false )
	data.frame.icon:SetAllPoints()
	data.frame.icon:SetTexCoord( 0.1, 0.9, 0.1, 0.9 )
	
	-- not sure what im doing here, hopefully everyone uses masque.
	data.frame:SetNormalTexture( "" )
	data.frame:SetPushedTexture( "Interface\\BUTTONS\\CheckButtonHilight", "add" )
	data.frame:SetHighlightTexture( "Interface\\BUTTONS\\ButtonHilight-Square", "add" )
	 
	local stacks = data.frame:CreateFontString( nil, "OVERLAY" )
	data.frame.stacks = stacks
	stacks:SetFont( STACKFONT, 10, "OUTLINE" ) 
	stacks:SetPoint( "BOTTOMRIGHT", data.frame.icon, "BOTTOMRIGHT", 0, 0 ) 
	stacks:Hide()
	
	data.frame.icon:SetTexture( "Interface\\Icons\\INV_Misc_QuestionMark" )
	data.frame:SetSize( 32, 32 )
	data.frame:SetPoint( "CENTER", 0, 0 )
	data.frame:EnableMouse( true )
	
	data.frame:RegisterForClicks( "LeftButtonUp", "RightButtonUp" )
	
	data.frame:SetScript("OnClick", function( self, button, down ) 
									    data:Clicked( button ) 
									end )
	data.frame:SetScript( "OnEnter", function() data:OnEnter() end )
	data.frame:SetScript( "OnLeave", function() data:OnLeave() end )

	Delleren:AddMasque( "CDBAR", data.frame )
	
	setmetatable( data, {__index = CDButton} )
	
	g_next_button = g_next_button + 1
	
	return data
end

-------------------------------------------------------------------------------
function CDButton:OnEnter()
	GameTooltip:SetOwner( self.frame, "ANCHOR_NONE" )
    GameTooltip:SetPoint( "TOPLEFT", self.frame, "BOTTOMLEFT" )
	GameTooltip:ClearLines()
	
	local name = GetSpellInfo( self.spell )
	GameTooltip:AddLine( name, 0, 0.7, 1, 1, 1, 1 )
	GameTooltip:AddLine( " " )
	
	local list = Delleren.Status:GetSpellStatus( self.spell )
	for _,p in ipairs( list ) do
		
		local left_color, right_color
		local left_text, right_text = p.name, ""
		local _,cls = UnitClass( p.name )
		left_color = RAID_CLASS_COLORS[cls].colorStr
		
		if not p.delleren then
			left_text = left_text .. "*"
		end
		
		if p.dead then
			left_color = "ff404040"
			right_color  = "ff404040"
			if not UnitIsConnected( p.name ) then
				right_text = "OFFLINE"
			else
				right_text = "DEAD"
			end
		elseif p.charges == 0 then
			right_color = "ffc030c0"
			right_text = (tostring(math.ceil( p.cd )) or "???") .. "s"
		elseif not p.inrange then
			right_color = "ffff0000"
			right_text = "OUTRANGED"
		else
			right_color = "ff00ff00"
			
			if p.charges == 1 then
				right_text = "READY"
			else
				right_text = "READY (" .. p.charges .. ")"
			end
		end
		
		GameTooltip:AddDoubleLine( "|c" .. left_color .. left_text, 
		                           "|c" .. right_color .. right_text )
	end
	
	GameTooltip:Show()
end

-------------------------------------------------------------------------------
function CDButton:OnLeave()
	GameTooltip:Hide()
end

-------------------------------------------------------------------------------
function CDButton:Show()
	if self.hidden then
		self.hidden = false
		self.frame:Show()
	end
end

-------------------------------------------------------------------------------
function CDButton:Hide()
	if not self.hidden then
		self.hidden = true
		self.frame:Hide()
	end
end

-------------------------------------------------------------------------------
function CDButton:EnableMouse()
	self.frame:EnableMouse( true )
end

-------------------------------------------------------------------------------
function CDButton:DisableMouse()
	self.frame:EnableMouse( false )
end

-------------------------------------------------------------------------------
function CDButton:SetSize( size )
	self.frame:SetSize( size, size )
	
	local fontsize = math.floor( size * 20 / 64 )
	fontsize = math.max( fontsize, 10 )
	self.frame.stacks:SetFont( STACKFONT, fontsize, "OUTLINE" )
end

-------------------------------------------------------------------------------
function CDButton:SetPosition( frame, x, y )
	self.frame:SetPoint( "TOPLEFT", frame, x, y )
end

-------------------------------------------------------------------------------
function CDButton:Clicked( button ) 

	if self.stacks == 0 then
		return
	end
	
	local buff = Delleren.SpellData:BuffSpell( self.spell )
	if button == "LeftButton" then
		Delleren.Query:Start( {self.spell}, false, buff, false, nil )
	else
		Delleren.Query:Start( {self.spell}, false, buff, true, nil )
	end
end

-------------------------------------------------------------------------------
function CDButton:Update( spell, stacks, disabled, time, duration, outrange )

	if self.spell ~= spell then
		self.spell = spell
		local _,_,icon = GetSpellInfo( spell )
		self.frame.icon:SetTexture( icon )
	end
	
	if self.disabled ~= disabled then
	
		if disabled then
			self.frame:Disable()
		else
			self.frame:Enable()
		end
	end
	
	if self.stacks ~= stacks or self.time ~= time 
	   or self.duration ~= duration then
	   
		self.stacks = stacks
		self.time = time
		self.duration = duration
		
		if self.time == 0 then
			self.frame.cooldown:SetCooldown( 0, 0, 1, 1 )
			if stacks > 1 then
				self.frame.stacks:SetText( tostring( stacks ))
				self.frame.stacks:Show()
			else
				self.frame.stacks:Hide()
			end
		else
			self.frame.stacks:Hide()
			self.frame.cooldown:SetCooldown( time, duration, 0, 1 )
		end
	end
	
	if self.outrange ~= outrange then
		self.outrange = outrange
		if outrange then
			self.frame.icon:SetVertexColor( 1,0,0 )
		else
			self.frame.icon:SetVertexColor( 1,1,1 )
		end
	end
	
	if self.hidden then
		self:Show()
	end
end
