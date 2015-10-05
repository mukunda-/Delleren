-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon
local L = Delleren.Locale

local QUERY_WAIT_TIME     = 0.5  -- time to wait for cd responses
local QUERY_TIMEOUT       = 2.0  -- time to give up query
local HARD_QUERY_TIMEOUT  = 4.0  -- time for the query to stop even
                                 -- when there are options left!
								 
local HELP_TIMEOUT        = 7.0  -- time to allow user to cast a spell.
local MANUAL_MENU_TIMEOUT = 15.0 -- timeout for selecting a manual request
local COMPAT_TIMEOUT      = 10.0 -- time to allow non-delleren user
                                 -- to cast a spell.

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
	buff       = false;   -- if we are requesting a buff
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
--                the target. nil to inherit from spell data.
-- @param manual  Manual call.
-- @param players Player preference list. Note that this takes over
--                the table given.
--			   
function Delleren.Query:Start( list, item, buff, manual, players )
	if self.active then return end -- query in progress already
	
	
	if players == nil or #players == 0 then
	
		-- default player priority setup
		local role = UnitGroupRolesAssigned( "player" )
		
		-- default player priority
		if role == "TANK" then
			-- if they're a tank, prioritize the other tank
			players = { "*t", "*h", "*d", "*" }
			
		else
			-- otherwise prioritize healers > dps > tanks
			players = { "*h", "*d", "*t", "*" }
			
		end
	end
	
	self.active      = true
	self.time        = GetTime()
	self.start_time  = self.time
	self.requested   = false 
	self.buff_flag   = buff
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
			if Delleren.SpellData:KnownSpell( spell ) then
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
	
	if #instant_list > 0 then
		-- do an instant request
		
		for name in Delleren:IteratePlayers() do
			local spell = Delleren.Status:HasSpellReady( name, instant_list )
			if spell and Delleren:UnitNearby( name ) 
			   and not UnitIsDeadOrGhost( name ) 
			   and UnitIsConnected( name )
			   and self:PlayerPassesFilter(name) then
			   
				table.insert( self.list, 
					{ name = name;
					  id = spell;
					  timeout = Delleren.Status:PlayerInTimeout( name );
					  compat  = Delleren.Status:PlayerHasDelleren( name );
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
				
			end
		else
			
			if #check_list > 0 then
			
				self:SendCheck( check_list )
				 
			else
			
				self:Fail()
			end
		end
	else
	
		if #self.list == 0 and #check_list == 0 then
			-- no spells available	
			self:Fail() 
		else
			
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
	
		local timeout = self.compat and HELP_TIMEOUT or COMPAT_TIMEOUT
		
		if t >= timeout then
			Delleren.Status:GivePlayerTimeout( self.unit )
			
			if not self.compat then
				-- if a player who doesn't have delleren failed the request
				-- then set the cd of that spell to half of it's duration
				--
				-- we don't actually know if it's available for them.
				--
				
				--Delleren.Status:OnSpellUsed( self.unit, self.spell, true )
				--
				-- changed mind on this one, just rely on the timeouts
			end
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
function Delleren.Query:PlayerPassesFilter( name )
	
	for _,player in ipairs( self.players ) do
		local role = PLAYER_ROLE_WILDCARDS[player]
		if role then
			if UnitGroupRolesAssigned( name ) == role then return true end
		elseif player == "*" then 
			return true
		elseif player == string.lower( name ) then
			return true
		end
	end
	return false
end

-------------------------------------------------------------------------------
function Delleren.Query:GetPreferredRequestIndex()
	
	-- if we don't find a "good" match, this records our last resort
	-- of a non-delleren player, or a player in timeout
	local best_choice = nil
	local best_choice_value = 0 -- 1000-timeout = in timeout+no delleren
	                            -- 2000-timeout = delleren in timeout
								-- 3000 = no delleren
								-- 0 = not found
	
	local dellbias = Delleren.Config.db.profile.calling.dellbias
					
	local function update_best_choice( index, data )
		local value
		
		if dellbias then
			if data.timeout and not data.compat then
				-- in timeout and no delleren
				value = 1000 - data.timeout
			elseif data.timeout and data.compat then
				-- in timeout with delleren
				value = 2000 - data.timeout
			elseif not data.compat then
				-- no delleren
				value = 3000
			else
				value = 4000
			end
		else
			if data.timeout then
				value = 2000 - data.timeout
			else
				value = 4000
			end
		end
		
		if value > best_choice_value then
			best_choice = index
			best_choice_value = value
			
			if value >= 4000 then
				return true
			end
		end
	end
	
	for _,player in ipairs( self.players ) do
		
		local role = PLAYER_ROLE_WILDCARDS[player]
		if role then
			
			for index,listed in ipairs( self.list ) do
				if UnitGroupRolesAssigned(listed.name) == role then
					
					if update_best_choice( index, listed ) then 
						return best_choice 
					end
				end
			end
			
		elseif player == "*" then
			for index,listed in ipairs( self.list ) do
			
				if update_best_choice( index, listed ) then 
					return best_choice 
				end
			end
		else
			for index,listed in ipairs( self.list ) do
			
				if string.lower(listed.name) == player then
				
					if update_best_choice( index, listed ) then 
						return best_choice 
					end
				end
			end
		end
	end
	
	return best_choice
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
	self.compat    = Delleren.Status:PlayerHasDelleren( request_data.name )
	
	if not self.item then
		if Delleren.SpellData:NoBuffSpell( self.spell ) then
			-- we know this spell can't give a buff, override buff flag.
			self.buff = false
		else
			-- do what the user told us to do.
			self.buff = self.buff_flag
		end
	else
		-- item buffs are unknown, do what the user told us to do.
		self.buff  = self.buff_flag
	end
	
	if self.compat then
		
		local msgdata = {
			rid  = self.rid;
			buff = self.buff;
			item = self.item;
			id   = self.spell;
		}
		
		Delleren:Comm( "GIVE", msgdata, "WHISPER", self.unit )
		Delleren:PlaySound( "CALL" )
		Delleren.Indicator:SetAnimation( "QUERY", "CALL" )
	else
		local spell_name = string.upper( GetSpellInfo( self.spell ) )
		
		if Delleren.Config.db.profile.calling.whisper then
			if Delleren.Config.db.profile.calling.localize then
				SendChatMessage( "************************", "WHISPER", nil, self.unit )
				SendChatMessage( L( "I need {1}.", spell_name ), "WHISPER", nil, self.unit )
			else
				SendChatMessage( "************************", "WHISPER", nil, self.unit )
				SendChatMessage( "I need " .. spell_name .. ".", "WHISPER", nil, self.unit )
			end
		end
		
		Delleren:PlaySound( "MANCALL" )
		Delleren.Indicator:SetAnimation( "QUERY", "MANCALL" )
	end
	
	
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
	
		if self.manual and not self:PlayerPassesFilter( name ) then
			-- player isn't in player list
			return
		end
		
		if Delleren.Ignore:IsIgnored( name ) then
			-- player is ignored
			return
		end
		
		table.insert( self.list, 
			{ 
				name = name; 
				id = data.id; 
				timeout = Delleren.Status:PlayerInTimeout( name );
				compat  = Delleren.Status:PlayerHasDelleren( name );
			})
		
		if self.manual then
			Delleren.QueryList:ShowList( self.list, self.item )
		end
	else
		-- out of range or otherwise invalid
	end
	
end
