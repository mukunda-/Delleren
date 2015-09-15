-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon

local QUERY_WAIT_TIME    = 0.25 -- time to wait for cd responses
local QUERY_TIMEOUT      = 3.0  -- time to give up query
local CD_WAIT_TIMEOUT    = 7.0  -- time to allow user to give us a cd
local HARD_QUERY_TIMEOUT = 5.0  -- time for the query to stop even
                                -- when there are options left!

Delleren.Query = {
	active     = false;	-- if we are currently asking for a cd
	time       = 0;     -- time that we changed states
	start_time = 0;     -- time that we started the query
	requested  = false; -- if a cd is being requested
	spell      = nil;   -- spellid we are asking for
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
	self.request_id    = math.random( 1, 999999 )
	
	Delleren.Indicator:Show()
	Delleren.Indicator:SetAnimation( "QUERY", "POLLING" )
	
	if not self.help.active then
		self:HideIndicatorText()
	end
	
	local instant_list = {}
	local check_list   = {}
	
	if not item then
		for k,spell in ipairs(list) do
			if self.Status:IsSubbed( spell ) then
				table.insert( instant_list, spell )
			else
				table.insert( check_list, spell )
			end
		end
	end
	
	if #instant_list > 0 then
		-- do an instant request
		
		Delleren.Status:GetPlayersReady( 
		
	end
	self:Comm( "
	
	self:SendCommMessage( COMM_PREFIX, "ASK", "RAID" )
	
	Delleren:EnableFrameUpdates()
end

-------------------------------------------------------------------------------
function Delleren.Query:Update()
	local t  = GetTime() - self.time
	local t2 = GetTime() - self.start_time
	
	if not self.requested then
	
		if t2 >= HARD_QUERY_TIMEOUT then
			
			Delleren:PlaySound( "FAIL" )
			Delleren.Indicator:SetAnimation( "QUERY", "FAILURE" )
			self.active = false
			return
		end
		
		if t2 >= QUERY_WAIT_TIME then
			if not self:RequestCD() then
				if t2 >= QUERY_TIMEOUT then
				
					Delleren:PlaySound( "FAIL" )
					Delleren.Indicator:SetAnimation( "QUERY", "FAILURE" )
					self.active = false
					return
				end
			end
		end
		
	else 
		if t >= CD_WAIT_TIMEOUT then
			Delleren:PlaySound( "FAIL" )
			Delleren.Indicator:SetAnimation( "QUERY", "FAILURE" )
			self.active = false
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
