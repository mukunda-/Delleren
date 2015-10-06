-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com) 
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon
local L = Delleren.Locale

Delleren.API = {}

local API = Delleren.API

-------------------------------------------------------------------------------
-- Access the API.
--
function Delleren:GetAPI()
	return self.API
end
 
-------------------------------------------------------------------------------
-- Start a call.
--
-- @param list    List of spell or item IDs to ask for.
-- @param item    true if the list as item IDs and not spell IDs.
-- @param buff    true to expect the spell to cast a buff on us. false if we
--                just want them to use the spell or item without caring for
--                the target. Ignored for spells that are known to not be able
--                to apply a buff.
-- @param manual  Manual call. Causes the call menu to open.
-- @param players Player preference list. This takes ownership of the table.
--                Pass nil to use the default preference list.
--	
-- @returns "BUSY"   if there is a call in progress already.
--          "FAILED" if the call failed instantly, meaning that you used
--                   known spells, and nobody could provide them or they
--                   were all on CD.
--          "OK"     if the call was started.
--
function API:Call( list, item, buff, manual, players )

	if Delleren.Query.active then return "BUSY" end
	
	Delleren.Query:Start( list, item, buff, manual, players ) 
	
	if not Delleren.Query.active then return "FAILED" end
	
	return true
end
