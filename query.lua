-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon

local QUERY_WAIT_TIME    = 0.25 -- time to wait for cd responses
local QUERY_TIMEOUT      = 3.0  -- time to give up query
local HARD_QUERY_TIMEOUT = 5.0  -- time for the query to stop even
                                -- when there are options left!
local HELP_TIMEOUT    = 7.0  -- time to allow user to cast a spell.

-------------------------------------------------------------------------------
Delleren.Query = {
	active     = false;	-- if we are currently asking for a cd
	time       = 0;     -- time that we changed states
	start_time = 0;     -- time that we started the query
	requested  = false; -- if a cd is being requested
	spell      = nil;   -- spellid we are asking for
	item       = nil;   -- true if this is an item request, nil if not
	list       = {};    -- list of userids that have cds available
	unit       = nil;   -- unitid of person we want a cd from 
	rid        = 0;     -- request id
	buff       = false; -- if we are requesting a buff
}

-------------------------------------------------------------------------------
-- Start a new query.
--
-- @param list List of spell or item IDs to ask for.
-- @param item true if we are requesting an item to be used.
-- @param buff true if we expect the id to cast a buff on us. false if we
--             just want them to use the spell or item without caring for
--             the target.
--
function Delleren.Query:Start( list, item, buff )
	if self.active then return end -- query in progress already
	
	self.active        = true
	self.time          = GetTime()
	self.start_time    = self.time
	self.requested     = false 
	self.list          = {} 
	self.item          = item or nil
	self.request_id    = math.random( 1, 999999 )
	
	Delleren.Indicator:Show()
	Delleren.Indicator:SetAnimation( "QUERY", "POLLING" )
	
	if not self.help.active then
		self:HideIndicatorText()
	end
	
	local instant_list = {} -- spells that we can call for instantly
	local check_list   = {} -- spells that we have to check for
	
	if not item then
		for k,spell in ipairs(list) do
			if self.Status:IsSubbed( spell ) then
				table.insert( instant_list, spell )
			else
				table.insert( check_list, spell )
			end
		end
	end
	
	-- TODO: player preference list
	
	if #instant_list > 0 then
		-- do an instant request
		
		for unit in Delleren:IteratePlayers() do
			local spell = Delleren.Status:HasSpellReady( instant_list )
			if spell then
				table.insert( self.list, { unit = unit, id = spell }
			end
		end
	end
	
	if #self.list > 0 then
		-- we can make an instant request
		self:RequestCD()
	else
		
		if #check_list > 0 then
			Delleren:Comm( "
		end
	end
	
	--self:SendCommMessage( COMM_PREFIX, "ASK", "RAID" )
	
	Delleren:EnableFrameUpdates()
end

-------------------------------------------------------------------------------
function Delleren.Query:Fail()
	Delleren:PlaySound( "FAIL" )
	Delleren.Indicator:SetAnimation( "QUERY", "FAILURE" )
	self.active = false
end

-------------------------------------------------------------------------------
function Delleren.Query:Update()
	local t  = GetTime() - self.time
	local t2 = GetTime() - self.start_time
	
	if not self.requested then
	
		if t2 >= HARD_QUERY_TIMEOUT then
			self:Fail()
			return
			 
		end
		
		if t2 >= QUERY_WAIT_TIME then
			if not self:RequestCD() then
				if t2 >= QUERY_TIMEOUT then
				
					self:Fail()
					return
				end
			end
		end
		
	else 
		if t >= HELP_TIMEOUT then
			self:Fail()
			return
		end
	end 
end

-------------------------------------------------------------------------------
function Delleren.Query:OnAuraApplied( spellID, source, dest )
	
end

-------------------------------------------------------------------------------
-- Pop the top of the query list and make a request. 
--
-- @returns true if a request was made, false if it's already in progress
--               or there are no more valid targets.
--
function Delleren.Query:RequestCD( sort )

	if self.requested or #self.list == 0 then 
		return false  -- request already in progress or list is empty
	end
	
	table.sort( self.list, 
		function( a, b )
			-- can't get much less efficient than this!
			return RequestSort(a) < RequestSort(b)
		end
	)
	
	local request_data = self.list[ #self.query.list ]
	table.remove( self.list )
	
	self.unit      = request_data.unit
	self.requested = true
	self.time      = GetTime()
	
	local msgdata = {
		rid  = self.query.rid;
		buff = self.query.buff;
		item = self.query.item;
		id   = request_data.id;
	}
	
	Delleren:Comm( "GIVE", msgdata, "WHISPER", unit )
	
	Delleren.Indicator:SetAnimation( "QUERY", "ASKING" )
	Delleren:PlaySound( "ASK" )
	
	if not self.help.active then
		self:SetIndicatorText( UnitName( g_query_unit ))
	end
	
	return true 
end

-------------------------------------------------------------------------------
-- Process data received from a READY message.
--
function Delleren.Query:HandleReadyMessage( sender, data )
	
	if not self.active or data.rid ~= self.Query.rid then 
		return -- invalid or lost message
	end
	
	local unit = Delleren:UnitIDFromName( sender )
	
	if unit ~= nil and Delleren:UnitLongRange( unit ) then
	
		table.insert( self.list, 
			{ 
				unit = unit; 
				id = data.id; 
			})
		
	else
		-- out of range or cant find unit id
	end
	
end
