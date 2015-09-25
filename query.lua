-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon

local QUERY_WAIT_TIME     = 0.5  -- time to wait for cd responses
local QUERY_TIMEOUT       = 2.0  -- time to give up query
local HARD_QUERY_TIMEOUT  = 4.0  -- time for the query to stop even
                                -- when there are options left!
local HELP_TIMEOUT        = 7.0  -- time to allow user to cast a spell.
local MANUAL_MENU_TIMEOUT = 15.0 -- timeout for selecting a manual request

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
	manual     = false; -- if this is a manual call
	ignore_rest= false; -- if the query should no longer accept new options
	checked    = false; -- if we ran a check
}

-------------------------------------------------------------------------------
-- Start a new query.
--
-- @param list    List of spell or item IDs to ask for.
-- @param item    true if we are requesting an item to be used.
-- @param buff    true if we expect the id to cast a buff on us. false if we
--                just want them to use the spell or item without caring for
--                the target.
-- @param manual  Manual call.
-- @param players Player preference list. Note that this takes over
--                the table given.
--			   
function Delleren.Query:Start( list, item, buff, manual, players )
	if self.active then return end -- query in progress already
	
	self.active      = true
	self.time        = GetTime()
	self.start_time  = self.time
	self.requested   = false 
	self.buff        = buff
	self.list        = {} 
	self.item        = item or nil
	self.rid         = math.random( 1, 999999 )
	self.manual      = manual
	self.ignore_rest = false
	self.players     = players
	self.checked     = false
	
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
	else
		for k,spell in ipairs(list) do
			table.insert( check_list, spell )
		end
	end
	
	-- TODO: player preference list
	
	if #instant_list > 0 then
		-- do an instant request
		
		for name in Delleren:IteratePlayers() do
			local spell = Delleren.Status:HasSpellReady( name, instant_list )
			if spell and Delleren:UnitNearby( name ) 
			   and not Delleren.Status:PingTimeout( name ) 
			   and not UnitIsDeadOrGhost( name ) 
			   and UnitIsConnected( name ) then
			   
				table.insert( self.list, 
					{ name = name;
					  id = spell;
					  timeout = Delleren.Status:PlayerInTimeout( name );
					})
			end
		end
		
		if not Delleren.Help.active then
			Delleren.Indicator:SetIconID( instant_list[1], self.item )
		end
	end
	
	if not self.manual then
		if #self.list > 0 then
			-- we can make an instant request
			
			if self:RequestCD() then
				Delleren:PlaySound( "CALL" )
			end
		else
			
			if #check_list > 0 then
			
				self:SendCheck( check_list )
				
				Delleren:PlaySound( "CALL" )
			else
			
				self:Fail()
			end
		end
	else
	
		if #self.list == 0 and #check_list == 0 then
			-- no spells available	
			self:Fail() 
		else
			Delleren:PlaySound( "CALL" )
			Delleren.QueryList:ShowList( self.list, self.item, true )
			
			if #check_list > 0 then
				self:SendCheck( check_list )
			end
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
	
	self.checked = true
end

-------------------------------------------------------------------------------
function Delleren.Query:Fail()
	if self.active then
		Delleren:PlaySound( "FAIL" )
		Delleren.Indicator:SetAnimation( "QUERY", "FAILURE" )
		self.active = false
		Delleren.QueryList:Hide()
	end
end

-------------------------------------------------------------------------------
function Delleren.Query:UpdateAutoRequest()
	local t  = GetTime() - self.time
	local t2 = GetTime() - self.start_time
	
	if #self.list == 0 and (not self.checked or self.ignore_rest) then
		self:Fail()
		return
	end
	
	if t2 >= HARD_QUERY_TIMEOUT then
		self:Fail()
		return
	end
	
	if t2 >= QUERY_WAIT_TIME then
		if not self:RequestCD() then
			if t2 >= QUERY_TIMEOUT or self.ignore_rest then
			
				self:Fail()
				return
			end
		end
	end
		 
end

-------------------------------------------------------------------------------
function Delleren.Query:UpdateManualRequest()
	local t  = GetTime() - self.time
	local t2 = GetTime() - self.start_time
	 
	if self.ignore_rest then
		-- the manual request failed.
		self:Fail()
		return
	end
	
	if not self.checked and self.list == 0 then
		self:Fail()
		return
	end
	
	if t2 >= MANUAL_MENU_TIMEOUT then
		-- took too long with menu open
		self:Fail()
	end
	
	if #self.list == 0 and t2 >= QUERY_TIMEOUT then
		-- nobody responded.
		self:Fail()
	end
	 
end

-------------------------------------------------------------------------------
function Delleren.Query:Update()
	
	if UnitIsDeadOrGhost( "player" ) then
		self:Fail()
		return
	end	
	
	local t  = GetTime() - self.time
	local t2 = GetTime() - self.start_time
	
	if not self.requested then
		if not self.manual then
			self:UpdateAutoRequest()
		else
			self:UpdateManualRequest()
		end
	else
		if t >= HELP_TIMEOUT then
			Delleren.Status:GivePlayerTimeout( self.unit )
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
local PLAYER_ROLE_WILDCARDS = {
	["*t"] = "TANK";
	["*h"] = "HEALER";
	["*d"] = "DAMAGER";
}

-------------------------------------------------------------------------------
function Delleren.Query:GetPreferredRequestIndex()
	
	-- normally this isn't needed, but if we only have a player or two
	-- in timeout left, then we will resort to requesting from them.
	local last_resort = nil
	
	for _,player in ipairs( self.players ) do
		
		if PLAYER_ROLE_WILDCARDS[player] then
			local role = PLAYER_ROLE_WILDCARDS[player]
			
			for index,listed in ipairs( self.list ) do
				if UnitGroupRolesAssigned(listed.name) == role then
					
					if not listed.timeout then
						return index
					end
					
					if not last_resort then last_resort = index end
				end
			end
			
		elseif player == "*" then
			for index,listed in ipairs( self.list ) do
			
				if not listed.timeout then return index end
				if not last_resort then last_resort = index end
			end
		else 
			for index,listed in ipairs( self.list ) do
			
				if string.lower(listed.name) == player then
					
					if not listed.timeout then return index end
					if not last_resort then last_resort = index end
				end
			end
		end
	end
	
	return last_resort
end

-------------------------------------------------------------------------------
function Delleren.Query:PopRequest()
	local index = self:GetPreferredRequestIndex()
	if index == nil then 
	
		-- no good entries found, likely ending the query
		self.list = {}
		return nil 
	end
	
	local data = self.list[index]
	table.remove( self.list, index )
	
	return data
end

-------------------------------------------------------------------------------
-- Pop the top of the query list and make a request. 
--
-- @returns true if a request was made, false if it's already in progress
--               or there are no more valid targets.
--
function Delleren.Query:RequestCD()

	if self.requested or #self.list == 0 then 
		return false  -- request already in progress or list is empty
	end
	 
	local request_data = self:PopRequest()
	if not request_data then return false end
	
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
-- Truncate the list to a single index and make a request.
--
function Delleren.Query:RequestManual( index )
	self.list = { self.list[index] }
	self.ignore_rest = true
	self:RequestCD()
end

-------------------------------------------------------------------------------
-- Process data received from a READY message.
--
function Delleren.Query:HandleReadyMessage( name, data )
	 
	if not self.active or data.rid ~= self.rid then 
		return -- invalid or lost message
	end
	
	if self.ignore_rest then
		-- ignore future options
		-- (used for manual requests)
		return 
	end
	
	if Delleren:UnitNearby( name ) then
		
		table.insert( self.list, 
			{ 
				name = name; 
				id = data.id; 
				timeout = Delleren.Status:PlayerInTimeout( name );
			})
		
		if self.manual then
			Delleren.QueryList:ShowList( self.list, self.item )
		end
	else
		-- out of range or otherwise invalid
	end
	
end
