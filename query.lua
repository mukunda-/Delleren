-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon

local QUERY_WAIT_TIME    = 0.25 -- time to wait for cd responses
local QUERY_TIMEOUT      = 2.0  -- time to give up query
local HARD_QUERY_TIMEOUT = 4.0  -- time for the query to stop even
                                -- when there are options left!
local HELP_TIMEOUT       = 7.0  -- time to allow user to cast a spell.

-- TODO: request priority targets

-------------------------------------------------------------------------------
Delleren.Query = {
	active     = false;	-- if we are currently asking for a cd
	time       = 0;     -- time that we changed states
	start_time = 0;     -- time that we started the query
	requested  = false; -- if a cd is being requested
	spell      = nil;   -- spellid we are asking for
	item       = nil;   -- true if this is an item request, nil if not
	list       = {};    -- list of userids that have cds available
	unit       = nil;   -- name of person we want a cd from 
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
	
	self.active      = true
	self.time        = GetTime()
	self.start_time  = self.time
	self.requested   = false 
	self.buff        = buff
	self.list        = {} 
	self.item        = item or nil
	self.rid         = math.random( 1, 999999 )
	
	
	Delleren.Indicator:Show()
	Delleren.Indicator:SetAnimation( "QUERY", "POLLING" )
	
	if not Delleren.Help.active then
		Delleren.Indicator:HideText()
	end
	
	local instant_list = {} -- spells that we can call for instantly
	local check_list   = {} -- spells that we have to check for
	
	if not item then
		for k,spell in ipairs(list) do
			if Delleren.Status:IsSubbed( spell ) then
				table.insert( instant_list, spell )
			else
				table.insert( check_list, spell )
			end
		end
	end
	
	-- TODO: player preference list
	
	if #instant_list > 0 then
		-- do an instant request
		
		for name in Delleren:IteratePlayers() do
			local spell = Delleren.Status:HasSpellReady( name, instant_list )
			if spell then
				table.insert( self.list, { name = name, id = spell } )
			end
		end
	end
	
	if #self.list > 0 then
		-- we can make an instant request
		
		self:RequestCD()
		Delleren:PlaySound( "CALL" )
	else
		
		if #check_list > 0 then
		
			self:SendCheck( check_list )
			Delleren:PlaySound( "CALL" )
		else
		
			self:Fail()
		end
	end
	
	Delleren:EnableFrameUpdates()
end

-------------------------------------------------------------------------------
function Delleren.Query:SendCheck( list )
	local data = {
		rid  = self.rid;
		ids  = list;
		item = self.item;
	}
	
	if not Delleren.Help.active then
		Delleren.Indicator:SetIconID( list[1], self.item )
	end
	
	Delleren:Comm( "CHECK", data, "RAID" )
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
	
	if UnitIsDeadOrGhost( "player" ) then
		self:Fail()
		return
	end	
	
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
		
		if UnitIsDeadOrGhost( self.unit ) then
			self:Fail()
			return
		end
	end 
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
	
	local request_data = self.list[ #self.list ]
	table.remove( self.list )
	
	self.unit      = request_data.name
	self.requested = true
	self.time      = GetTime()
	self.spell     = request_data.id
	
	local msgdata = {
		rid  = self.rid;
		buff = self.buff;
		item = self.item;
		id   = self.spell;
	}
	
	Delleren:Comm( "GIVE", msgdata, "WHISPER", self.unit )
	
	Delleren.Indicator:SetAnimation( "QUERY", "ASKING" ) 
	
	if not Delleren.Help.active then
		
		local unit_name = Delleren:UnitNameColored( self.unit )
		local request_text
		local request_icon
		
		if not self.item then
			local name, _, icon = GetSpellInfo( self.spell )
			request_text = name
			request_icon = icon
		else
			local name,_,_,_,_,_,_,_,_,texture = GetItemInfo( self.spell )
			request_text = name
			request_icon = texture
		end
		
		request_text = request_text or "???"
		request_icon = request_icon or ""
		
		Delleren.Indicator:SetText( unit_name .. "\n" .. request_text  )
		Delleren.Indicator:SetIcon( request_icon )
	
	end
	
	return true 
end

-------------------------------------------------------------------------------
-- Process data received from a READY message.
--
function Delleren.Query:HandleReadyMessage( name, data )
	 
	if not self.active or data.rid ~= self.rid then 
		return -- invalid or lost message
	end
	
	if Delleren:UnitLongRange( name ) then
		
		table.insert( self.list, 
			{ 
				name = name; 
				id = data.id; 
			})
		
	else
		-- out of range or otherwise invalid
	end
	
end
