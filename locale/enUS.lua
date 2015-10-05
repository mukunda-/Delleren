-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon
Delleren.Locale = {}
local L = Delleren.Locale

-------------------------------------------------------------------------------
setmetatable( L, { 

	__index = function( table, key ) 
		return key 
	end;
	
	__call = function( table, key, ... )
		for i = 1, select( "#", ... ) do
			key = string.gsub( key, "{" .. i .. "}", select( i, ... ) )
		end
	return key
  end;
})

-------------------------------------------------------------------------------

-------------------
---- cdbar.lua ----
-------------------

--L["Delleren CDBar"] = 


--------------------
---- config.lua ----
--------------------

--L["Master"]
--L["Sound Effects"]
--L["Ambience"]
--L["Music"] 

--L["Lock Frames"] 
--L["Locks/Unlocks frames to be moved."]
--L["Minimap Icon"]
--L["Hide/Show the minimap icon."]
--L["Calling"]
L["Whisper Option Description"] = "Whispers are used to call for spells from players without Delleren installed. If you disable whispers, you are expected to call for your spell manually (e.g. over voice-chat)."
--L["Enable Whispers"]
L["Localize Whisper Description"] = "Disable localize whispers to always have whispers sent in English rather than based on your locale. This is recommended if you don't personally speak english but often play with players that do.";
--L["Localize Whispers"]
L["Prefer Delleren Players Description"] = "Prefer Delleren enabled players over normal players. This will cause query filters to choose players with Delleren installed over other players, even if they have a lower priority in the query filter.";

--L["Indicator"]
--L["Frame Size"]
--L["Size of the indicator frame."]
--L["Font Size"]
--L["Size of the indicator font."]
--L["Font"]
--L["Indicator font."]
--L["Reset Position"]
--L["Reset the indicator's position."]

--L["Sounds"]
--L["Sound Channel:"]
--L["Channel to play sounds on."]
--L["Call:"]
--L["Sound to play when making a call."]
--L["Non-Delleren Call:"]
--L["Sound to play when making a call to a user without Delleren."]
--L["Help:"]
--L["Sound to play when being asked for help."]
--L["Fail:"]
--L["Sound to play when something goes wrong."]


--L["CD Bar"]
L["CD Bar Description"] = "The CD Bar is an actionbar-like display of CDs that you are tracking. If you are like Migs (you play on a toaster), disabling it may give a tiny performance boost."
--L["Enable"]
--L["Enable the CD Bar."]
--L["Enable Mouse"]
--L["Enable mouse interaction with the CD bar."]
--L["Button Size"]
--L["Size of button frames."]
--L["Columns"]
--L["Number of columns in layout."]
--L["Padding"]
--L["Padding in between each button."]

--L["Tracked Spells"]
L["Tracked Spells Description"] = "Spells that are tracked may be called for with instant queries, and they show up in the CD bar."
--L["Edit"]
L["Editor Help"] = "Add or remove which spells are tracked here. Enter spell IDs or spell names separated by new lines. The spells must be defined in Delleren's spell database to be tracked."

--L["Unknown spell"]
--L["Invalid spell ID:"]


----------------------
---- delleren.lua ----
----------------------

--L["Version:"]
--L["One or more players in your raid are using a newer version of Delleren that isn't compatible with yours."]
--L["Invalid spell ID: "]
--L["Unknown option: "]
--L["No spell IDs given!"]
--L["Your version: "]
--L[" (Incompatible)"]
--L["Not installed."]
--L["Unknown."]
--L["Unknown spell: "]
--L["Usage: "]

-- chat commands
--L["call"]
--L["ignore"]
--L["config"]
--L["who"]
--L["version"]
--L["id"]
--L["fuck"]
--L["Command listing:"]
--L["config - Open configuration."]
--L["call - Call for a cd. (See User's Manual.)"]
--L["who - List player versions."]
--L["ignore - Open ignore panel."]


-----------------------
---- indicator.lua ----
-----------------------

--L["Right-click to lock."]


---------------------------
---- minimapbutton.lua ----
---------------------------

--L["Open Ingore Panel"]
--L["Show Versions"]
--L["Open Configuration"]
--L["Close"]

-- tooltip:
--L["|cff00ff00Click|r to unlock frames."]
--L["|cff00ff00Shift-Click|r to open ignore panel."]
--L["|cff00ff00Right-click|r for options."]


-------------------
---- query.lua ----
-------------------

--L["I need {1}."]


-----------------------
---- querylist.lua ----
-----------------------

--L["Cancel"]
