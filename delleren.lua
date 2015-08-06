-------------------------------------------------------------------------------
-- Delleren
-- External CD caller.
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
--
-- See LICENSE.TXT
-------------------------------------------------------------------------------
-- version 1.1 beta
-------------------------------------------------------------------------------

-- indicator colors:
-- blue       : asking for cd               initialize sound
-- green+fade : cd received
-- red+fade   : failed to get a cd          fail sound
---
-- requests:
-- orange+flash : cd request                obnoxious sound
-- green+fade   : given					    good sound
-- red+fade     : timed out! bad raider!    fail sound
 

--g_frame:SetPoint( "CENTER", 0, 0 )


local COMM_PREFIX  = "CDPLEASE"

local QUERY_WAIT_TIME = 0.25   -- time to wait for cd responses
local QUERY_TIMEOUT   = 1.8    -- time to give up query
local CD_WAIT_TIMEOUT = 7.0    -- time to allow user to give us a cd
local HARD_QUERY_TIMEOUT = 5.0 -- time for the query to stop even
                               -- when there are options left!

local CD_SPELLS = { 
	102342; -- ironbark
	114030; -- vigilance
	122844; -- painsup
	6940;   -- sac
--	116841; -- tigers lust (debug)
}

local CD_MAP = {
	[102342] = "Ironbark";
	[114030] = "Vigilance";
	[122844] = "Pain Suppression";
	[6940]   = "Hand of Sacrifice";
--	[116841] = "Tiger's Lust"; -- (debug)
}

-------------------------------------------------------------------------------		  
function DellerenAddon:OnInitialize()
	SLASH_CDPLEASE1 = "/cdplease"
	
	if not DellerenAddonSaved then
		DellerenAddonSaved = {}
	end
	
	self.saved = DellerenAddonSaved
	
	local data = DellerenAddonSaved
	data.size = data.size or 48
	
	self:frames.main:SetSize( data.size, data.size )
	
	if not self.saved.init then
		self.saved.init = true
		-- stuff...
	end
	
	if not self.saved.locked then
		DellerenAddon:Unlock() 
	end
	
	self:ScheduleRepeatingTimer( "OnStatusRefresh", 5 )
end

-------------------------------------------------------------------------------
function DellerenAddon:OnStatusRefresh()
	local status = BuildStatus()
	if status == nil then return end
	
	
end

-------------------------------------------------------------------------------
function DellerenAddon:OnCombatLogEvent( event, ... ) 
	local timestamp,evt,_,sourceGUID,_,_,_,destGUID,_,_,_,spellID = ...
	
	if evt == "SPELL_AURA_APPLIED" or evt == "SPELL_AURA_REFRESH" then
	
		if self.query.active and sourceGUID == UnitGUID( self.query.unit )
           and spellID == self.query.spell then
		   
			if destGUID == UnitGUID( "player" ) then
				
				self:SetAnimation( "QUERY", "SUCCESS" )
				self.query.active = false
				
			else
				-- cd was cast on someone else! find another one!
				self.query.requested = false
			end
		end 
		
		if self.help.active and sourceGUID == UnitGUID( "player" ) 
		   and spellID == self.help.spell then
	 
			if destGUID == UnitGUID( self.help.unit ) then
				
				self:PlaySound( "GOOD" )
				self:SetAnimation( "HELP", "SUCCESS" )
				self.help.active = false
				
			else
				
				self:PlaySound( "FAIL" )
				self:SetAnimation( "HELP", "FAILURE" )
				self.help.active = false
				
			end
		end
	end
end

-------------------------------------------------------------------------------
function Delleren:Unlock()
	if self.unlocked then return end
	
	if UnitAffectingCombat( "player" ) then
		print( "Cannot unlock in combat!" )
		return
	end
	
	if self.query.active or self.help.active then
		print( "Cannot unlock when busy!" )
		return
	end
	 
	if not self.drag_stuff then
		self.drag_stuff = {}
		
		local frame = self.frames.indicator
		
		local green = frame:CreateTexture()
		green:SetAllPoints()
		green:SetTexture( 0,0.5,0,0.4 )
		 
		frame:SetScript("OnMouseDown", function(self,button)
			if button == "LeftButton" then
				self:StartMoving()
			else
				Delleren:Lock()
			end
		end)
		
		frame:SetScript( "OnMouseUp", function(self)
			self:StopMovingOrSizing()
		end)
 
		self.drag_stuff.green = green 
	else
		self.drag_stuff.green:Show()
		
	end
	
	self.frames.indicator:EnableMouse( true )
	self.frames.indicator:Show()
	self:ShowText( "Right click to lock." )
	self:frames.indicator:SetTextColor( 1, 1, 1, 1 )
	
	self.unlocked = true
	self.saved.locked = false
end

-------------------------------------------------------------------------------
function Delleren:Lock()
	if not self.unlocked then return end
	if not self.drag_stuff then return end
	
	self.unlocked = false
	self.saved.locked = true
	
	self.drag_stuff.green:Hide()
	self:HideText()
	self.frames.indicator:EnableMouse( false )
	self.frames.indicator:Hide()
end

-------------------------------------------------------------------------------
function Delleren:ShowText( caption )
	self.frames.indicator.text:SetText( caption )
	self.frames.indicator.text:Show()
end

-------------------------------------------------------------------------------
function Delleren:HideText( caption )
	self.frames.indicator.text:Hide()
end

-------------------------------------------------------------------------------
function Delleren:Scale( size )
	
	size = tonumber( size )
	if size == nil then return end
	
	self.frames.indicator.text:SetFont( 
			"Fonts\\FRIZQT__.TTF", math.floor(16 * size/48), "OUTLINE" )
	
	size = math.max( size, 16 )
	size = math.min( size, 256 )
	
	self.saved.size = size
	self.frames.indicator:SetSize( size, size )

	if self.masque_group then
		self.masque_group:ReSkin()
	end
end

-------------------------------------------------------------------------------
local function UnitIDFromName( name )
	-- TODO check what format name is in!

	for i = 1,40 do
		local n  = UnitName( "raid" .. i )
		if n ~= nil then
			if n == name then return "raid" .. i end
		end
	end
	
	for i = 1,5 do
		local n  = UnitName( "party" .. i )
		if n ~= nil then
			if n == name then return "party" .. i end
		end
	end
	
	return nil
end

-------------------------------------------------------------------------------
local function ColorLerp( r1,g1,b1,r2,g2,b2,a )
	a = math.min( a, 1 )
	a = math.max( a, 0 )
	return r1 + (r2-r1) * a, g1 + (g2-g1) * a, b1 + (b2-b1) * a
end

-------------------------------------------------------------------------------
-- Returns the squared range to a friendly unit.
--
-- Note that the casting range is slightly longer, since this is the
-- range to their center, and casting extends to their hitboxes
--
-- @param unit unitID of friendly unit.
-- @returns distance squared.
--
local function UnitDistance( unit )
	local y,x = UnitPosition( unit )
	local my,mx = UnitPosition( "player" )
	y,x = y - my, x - mx
	local d = x*x + y*y
	return d
end

-------------------------------------------------------------------------------
local function UnitShortRange( unit )
	return UnitDistance( unit ) < 35 * 35 and IsItemInRange( 34471, unit )
end

-------------------------------------------------------------------------------
local function UnitLongRange( unit )
	return IsItemInRange( 34471, unit )
end

-------------------------------------------------------------------------------
-- Returns a range weight used for sorting the cd responses.
--
local function UnitRangeValue( unit )
	local a = UnitDistance( unit )
	
	if UnitShortRange( unit ) then
		return a
	elseif UnitLongRange( unit ) then
		return a + 100000
	else
		return a + 1000000
	end
end

-------------------------------------------------------------------------------
-- Returns true if we have a cd ready to give to someone, and it isn't
-- already being asked for.
--
-- @param ignore_reserve Don't return false if we have our CD reserved,
--                       (check the cooldown only)
-- @param list           List of spell IDs or item IDs to check. May be a 
--                       single id number too.
-- @param item           true if we are checking for items instead of spells.
--
-- @returns nil if no spells or items are ready, or returns the id of one
--          that is ready.
--
local function HasCDReady( ignore_reserve, list, item )
	if not ignore_reserve and (self.help.active or self.unlocked) then
		-- someone is already asking us!
		return nil
	end
	
	if UnitIsDeadOrGhost( "player" ) then 
		-- we are dead
		return nil
	end
	
	if type(list) == "number" then
		list = {list}
	end
	
	-- todo: spell reserves
	
	for k,v in ipairs( list ) do
		if not item then
			if IsSpellKnown( v ) then
				local charges = GetSpellCharges( v ) 
				if charges ~= nil and charges >= 1 then return true end
				
				local start, duration, enable = GetSpellCooldown( v )
				if start == 0 then return true end
				
				-- if there is 1 second left on the cd, then it's ready enough
				-- also uh, account for gcd time which may interfere
				if duration - (GetTime() - start) < 1.6 then return true end
			end
		else
			if GetItemCount( v ) > 0 then
				local start, duration, enable = GetItemCooldown( v )
				if start == 0 then return true end
				
				if duration - (GetTime() - start) < 1.6 then return true end
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Returns true if a name, which may or may not have a realm appended
-- matches a unit's name.
--
local function NameMatch( name, unit ) 
	local n
	if not string.find( name, "-" ) then
		local _,r = UnitName( "player" )
		name = name .. '-' .. r
	end
	
	local n,r = UnitName( unit )
	if n == nil then return false end
	n = n .. '-' .. r
	return n == name
end

-------------------------------------------------------------------------------
function Delleren:OnInitialize()
	self:RegisterComm( "DELLEREN" )
end

-------------------------------------------------------------------------------
function Delleren:OnCommReceived( prefix, packed_message, dist, sender )
	if prefix ~= self.COMM_PREFIX then return end -- discard unwanted messages
	
	local result, msg, data = self:Deserialize( packed_message )
	
	if result == false then return end -- bad message
	
	if msg == "CHECK" then
		-- player is checking if we have a cd ready
		
		local id = HasCDReady( false, data.id, data.item )
		
		if id then
			self:RespondReady( sender, id )
		end
		
	elseif msg == "READY" then
		
		if not self.query.active or data.rid ~= self.query.rid then 
			return
		end
		
		if data.target and not NameMatch( data.target, "player" ) then 
		   return 
		end
		
		local unit = UnitIDFromName( sender )
		if unit ~= nil and UnitLongRange( unit ) then
		
			table.insert( self.query.list, unit )
			
		else
			-- out of range or cant find unit id
		end
		
	elseif msg == "GIVE" then
		-- player is asking for a CD
		
		if data.target and 
		   not NameMatch( data.target, "player" ) then return end
		
		if not HasCDReady( false, data.id, data.item ) then
		
			self:DeclineCD( sender, data.rid )
		else
			self:ShowHelpRequest( sender, data.id, data.item, data.buff )
		end

	elseif msg == "NO" then
		-- player denied our cd request
		
		if data.target and 
		   not NameMatch( data.target, "player" ) then return end
		
		if data.rid == self.query.request_id then
			-- try again.
			self.query.requested = false
		end
		
	elseif msg == "STATUS" then
		RecordStatus( sender, data )
	elseif msg == "POLL" then
		SendStatus()
	end  
end

-------------------------------------------------------------------------------
function DellerenAddon:SendStatus()
	if self.status.active then return end
	
	self.statusmsg.active = true
	
	self:ScheduleTimer( "SendStatusDelayed", 5 )
end

-------------------------------------------------------------------------------
function DellerenAddon:SendStatusDelayed()
	
end

-------------------------------------------------------------------------------
function DellerenAddon:RespondReady( sender )
	self:SendCommMessage( COMM_PREFIX, "READY", "WHISPER", sender ) 
end
 
-------------------------------------------------------------------------------
-- Pop the top of the cd list and make a request.
--
-- @param sort Sort the list before popping it.
--
function CDPlease:RequestCD( sort )

	if g_query_requested then return false end -- request already in progress
	
	if #g_query_list == 0 then
		return false
	end

	if sort then
		table.sort( g_query_list, 
			function( a, b )
				-- can't get much less efficient than this!
				return UnitRangeValue(a) < UnitRangeValue(b)
			end
		) 
	end
	
	local unit = g_query_list[ #g_query_list ]
	table.remove( g_query_list )
	
	g_query_unit = unit
	g_query_requested = true
	g_query_time = GetTime()
	
	self:SendCommMessage( COMM_PREFIX, "CD", "WHISPER", UnitName( unit ))
	
	self:SetAnimation( "QUERY", "ASKING" )
	self:PlaySound( "ASK" )
	
	if not g_help_active then
		self:ShowText( UnitName( g_query_unit ))
	end
	 
	return true
	
end

-------------------------------------------------------------------------------
-- Decline giving a CD, sending a "NO" response
--
-- @param caller Name of caller
--
function CDPlease:DeclineCD( caller )
	self:SendCommMessage( COMM_PREFIX, "NO", "WHISPER", caller )
end

-------------------------------------------------------------------------------
-- Request a CD from the raid.
--
function CDPlease:CallCD()
	if g_query_active then 
		-- query is in progress already
		return
	end
	
	CDPlease:Lock()
	
	g_query_active        = true
	g_query_time          = GetTime()
	g_query_start_time    = g_query_time
	g_query_requested     = false 
	g_query_list          = {} 
	
	g_frame:Show()
	self:SetAnimation( "QUERY", "POLLING" )
	
	if not g_help_active then
		self:HideText()
	end
	
	self:SendCommMessage( COMM_PREFIX, "ASK", "RAID" )
	
	DoEmote( "helpme" )
	
	self:EnableFrameUpdates()
end

-------------------------------------------------------------------------------
function CDPlease:OnQueryUpdate()
	local t = GetTime() - g_query_time
	local t2 = GetTime() - g_query_start_time
	 
		
	if not g_query_requested then
	
		if t2 >= HARD_QUERY_TIMEOUT then
			
			self:PlaySound( "FAIL" )
			self:SetAnimation( "QUERY", "FAILURE" )
			g_query_active = false
			return
		end
	
		if t2 >= QUERY_WAIT_TIME then
			if not self:RequestCD() then
				if t2 >= QUERY_TIMEOUT then
				
					self:PlaySound( "FAIL" )
					self:SetAnimation( "QUERY", "FAILURE" )
					g_query_active = false
					return
				end
			end
		end
		
	else 
		if t >= CD_WAIT_TIMEOUT then
			self:PlaySound( "FAIL" )
			self:SetAnimation( "QUERY", "FAILURE" )
			g_query_active = false
		end
	end 
end

-------------------------------------------------------------------------------
function CDPlease:OnHelpUpdate()
	
	local t = GetTime() - g_help_time
	
	if GetTime() >= g_help_pulse then
		g_help_pulse = g_help_pulse + 1
		self:SetAnimation( "HELP", "HELP" )
		
		self:PlaySound( "HELP" )
	end
	--
--	if not HasCDReady( true ) then
--		g_help_active = false
--		self:SetAnimation( "HELP", "FAILURE" )
--		g_help_active = false
--		return
--	end
	
	if t >= CD_WAIT_TIMEOUT then
		self:PlaySound( "FAIL" )
		self:SetAnimation( "HELP", "FAILURE" )
		g_help_active = false
		return
	end
	
end

-------------------------------------------------------------------------------
-- Frame update handler.
--
function CDPlease:OnFrame()
	if g_query_active then
		self:OnQueryUpdate()
	end
	
	if g_help_active then
		self:OnHelpUpdate()
	end
	
	self:UpdateAnimation()
	
	if not g_query_active and not g_help_active and g_ani_finished then
		self:DisableFrameUpdates()
		g_frame:Hide()
	end
end

-------------------------------------------------------------------------------
-- Enable the OnFrame callback.
--
function CDPlease:EnableFrameUpdates()
	
	g_frame:SetScript( "OnUpdate", function() CDPlease:OnFrame() end )
	CDPlease:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED", "OnCombatLogEvent" )
end

-------------------------------------------------------------------------------
-- Disable the OnFrame callback.
--
function CDPlease:DisableFrameUpdates()
	g_frame:SetScript( "OnUpdate", nil )
	CDPlease:UnregisterEvent( "COMBAT_LOG_EVENT_UNFILTERED", "OnCombatLogEvent" )
end

-------------------------------------------------------------------------------
function CDPlease:NoCDAvailable()
	
end

-------------------------------------------------------------------------------
local SOUND_LIST = {
	["FAIL"] = "Interface\\Addons\\cdplease\\sounds\\fail.ogg";
	["ASK"]  = "Interface\\Addons\\cdplease\\sounds\\ask.ogg";
	["HELP"] = "Interface\\Addons\\cdplease\\sounds\\help.ogg";
	["GOOD"] = "Interface\\Addons\\cdplease\\sounds\\good.ogg";
}

function CDPlease:PlaySound( sound )
	local s = SOUND_LIST[sound]
	if s == nil then return end
	PlaySoundFile( s, "Master" )
end

-------------------------------------------------------------------------------
function CDPlease:ShowHelpRequest( sender )
	g_help_active = true
	g_help_unit   = UnitIDFromName( sender )
	g_help_time   = GetTime()
	g_help_pulse  = GetTime() + 1
	self:PlaySound( "HELP" )
	
	self:ShowText( UnitName( g_help_unit ))
	self:SetAnimation( "HELP", "HELP" )
	g_frame:Show()
	 
	
	self:EnableFrameUpdates()
end

-------------------------------------------------------------------------------
function CDPlease:SetAnimation( source, state )

	if source == "QUERY" and g_help_active then 
		-- do not interfere with help interface
		return
	end
	
	g_ani_state = state
	g_ani_time  = GetTime()
	g_ani_finished = false
end


-------------------------------------------------------------------------------
function CDPlease:UpdateAnimation()
	local t = GetTime() - g_ani_time
	
	if g_ani_state == "ASKING" then
		local r,g,b = ColorLerp( 1,1,1, 1,0.7,0.2, t / 0.25 )
		g_frame.icon:SetVertexColor( r, g, b, 1 )
		g_frame.text:SetTextColor( 1, 1, 1, 1 )
		if t >= 1.0 then g_ani_finished = true end
		
	elseif g_ani_state == "SUCCESS" then
		
		local a = 1.0 - math.min( t / 0.5, 1 )
		g_frame.icon:SetVertexColor( 0.3, 1, 0.3, a )
		g_frame.text:SetTextColor  ( 0.3, 1, 0.3, a )
		if t >= 0.5 then g_ani_finished = true end
		
	elseif g_ani_state == "FAILURE" then
	
		local a = 1.0 - math.min( t / 0.5, 1 )
		g_frame.icon:SetVertexColor( 1, 0.1, 0.2, a )
		g_frame.text:SetTextColor  ( 1, 0.1, 0.2, a )
		if t >= 0.5 then g_ani_finished = true end
		
	elseif g_ani_state == "POLLING" then
	
		local r,g,b = 0.25, 0.25, 0.6
		
		b = b + math.sin( GetTime() * 6.28 * 3 ) * 0.4
		
		r,g,b = ColorLerp( 1,1,1,r,g,b, t / 0.2 )
		g_frame.icon:SetVertexColor( r, g, b, 1 )
		g_frame.text:SetTextColor( 1,1,1,1 )
		if t >= 1.0 then g_ani_finished = true end
		
	elseif g_ani_state == "HELP" then
		local r,g,b = ColorLerp( 1,1,1, 0.5,0,0.5, t/0.25 )
		g_frame.icon:SetVertexColor( r, g, b, 1 )
		g_frame.text:SetTextColor( 1,1,1,1 )
		if t >= 1.0 then g_ani_finished = true end
	else
		g_frame.text:SetTextColor( 1,1,1,1 )
	end
end

-------------------------------------------------------------------------------
-- Slash command for macro binding.
--
function SlashCmdList.CDPLEASE( msg )
	local args = {}
	
	for i in string.gmatch( msg, "%S+" ) do
		table.insert( args, i )
	end
	
	if args[1] == "unlock" then
		CDPlease:Unlock()
	elseif args[1] == "call" then
		CDPlease:CallCD()
	elseif args[1] == "size" then
		CDPlease:Scale( args[2] )
		
	elseif args[1] == "fuck" then
		
		print( "My what a filthy mind you have!" )
		 
	else
		print( "/cdplease unlock - Unlock the frame." )
		print( "/cdplease size <pixels> - Scale the frame." )
		print( "/cdplease call - Call for a cd." )
	end
	 
	--CDPlease:CallCD()
end
