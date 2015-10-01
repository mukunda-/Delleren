-------------------------------------------------------------------------------
-- DELLEREN
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon

--spell definition format:
--
-- [spellid] = { 
--    cd      = cooldown in seconds, default = GetSpellBaseCooldown
--    talent  = Talent required to activate spell, formatted as row * 10 + column 
--    charges = max number of spell charges, default (nil) is 1
--    mods    = list of functions that modify the data according to talent data
--    buff    = spellid of buff we expect to be cast on us, default = same as spellid, 0 = non-buff ability
-- }

Delleren.SpellData = {}

-------------------------------------------------------------------------------
local function TalentSelected( build, index )
	local row = math.floor( index / 10 )
	index = index - row * 10
	return tonumber(string.sub( build.talents, row, row )) == index
	
--	local _,_,_,sel,avail = GetTalentInfo( row, index, nil, true, name )
--	return sel and avail
end

-------------------------------------------------------------------------------
local function GlyphSelected()
	return false
end

-------------------------------------------------------------------------------
local function ClemencyMod( data, build )
	if TalentSelected( build, 43 ) then
		data.charges = 2
	else
		data.charges = 1
	end
end
 
-------------------------------------------------------------------------------
local function DevoAuraMod( data, name )
	-- TODO find devo aura glyph and set cd
end

-------------------------------------------------------------------------------
local SpellData = {

-------------------------------------------------------------------------------
	["DEATHKNIGHT"] = {
		all = {
			[51052]  = { talent = 22; buff=0 };        -- Anti-magic zone
		};
	};
	
-------------------------------------------------------------------------------
	["DRUID"] = {
	
		all = {
			[106898] = { buff=0; };                    -- Stampeding Roar
		};
	
		-- resto
		[105] = {
			[740]    = { buff=0; };                    -- Tranquility
			[102342] = {};                             -- Ironbark
		};
	};
	
-------------------------------------------------------------------------------
	["HUNTER"] = {
	};
	
-------------------------------------------------------------------------------
	["MAGE"] = {
		all = {
			[113724] = { talent = 31; buff=0; };       -- Ring of Frost
		};
	};
	
-------------------------------------------------------------------------------
	["MONK"] = {
		all = {
			[116841] = { talent = 12; };               -- Tiger's Lust
			[116844] = { talent = 41; };               -- Ring of Peace
			[119392] = { talent = 42; buff=0; };       -- Charging Ox Wave
			[119381] = { talent = 43; buff=0; };       -- Leg Sweep
		};
		
		-- mistweaver
		[270] = {
			[115310] = { buff=0 };                     -- Revival
			[116849] = { cd = 100 };                   -- Life Cocoon
		};
	};
	
-------------------------------------------------------------------------------
	["PALADIN"] = {
		all = {
			[6940]   = { mods = { ClemencyMod } };     -- Hand of Sacrifice
			[1044]   = { mods = { ClemencyMod } };     -- Hand of Freedom
			[1022]   = { mods = { ClemencyMod } };     -- Hand of Protection
			[633]    = { buff=0; };                    -- Lay on Hands
			[114039] = { talent = 41; };               -- Hand of Purity
		};
		
		-- protection
		[66] = { 
			[1038] = { mods = { ClemencyMod } };       -- Hand of Salvation
		};
		
		-- holy
		[65] = {
			[31821] = { buff=0; mods = { DevoAuraMod }; }; -- Devotion Aura
		};
	};
	
-------------------------------------------------------------------------------
	["PRIEST"] = {
		
		-- disc
		[256] = {
			[62618] = { buff=0; };                     -- Power Word: Barrier
			[33206] = {};                              -- Pain Suppression
		};
		
		-- holy
		[257] = {
			[64843] = { buff=0; };                     -- Divine Hymn
			[47788] = {};                              -- Guardian Spirit
		};
	};
	
-------------------------------------------------------------------------------
	["ROGUE"] = {
		all = {
			[76577] = { buff=0; };                     -- Smoke Bomb
			[1725]  = { buff=0; };                     -- Distract
		};
	};
	
-------------------------------------------------------------------------------
	["SHAMAN"] = {
	
		-- resto
		[264] = {
			[98008] = { buff=0; };                     -- Spirit Link Totem
		};
	};
	
-------------------------------------------------------------------------------
	["WARLOCK"] = {
		
	};
	
-------------------------------------------------------------------------------
	["WARRIOR"] = {
		all = {
			[114028] = { talent = 51; buff=0; };       -- Mass Spell Reflection
			[114030] = { talent = 53; };               -- Vigilance
			[46968]  = { talent = 42; buff=0; };       -- Shockwave 
		};
		
		-- arms
		[71] = {
			[97462] = { buff=0; };                     -- Rallying Cry
		};
		
		-- fury
		[72] = {
			[97462] = { buff=0; };                     -- Rallying Cry
		};
	};
	
-------------------------------------------------------------------------------
	["DEMONHUNTER"] = {
		-- :)
	};
}

-------------------------------------------------------------------------------
local GlyphFilter = {
	-- glyphs that we should care about
	-- currently none.
}

-------------------------------------------------------------------------------
local SpellMap = {
}

do
	for _,c in pairs( SpellData ) do
		for _,spec in pairs( c ) do
			for spellid,spelldata in pairs( spec ) do
				SpellMap[spellid] = spelldata
			end
		end
	end
end

-------------------------------------------------------------------------------
function Delleren.SpellData:GlyphFilter( id )
	return GlyphFilter[id]
end

-------------------------------------------------------------------------------
function Delleren.SpellData:KnownSpell( id )
	return SpellMap[id]
end

-------------------------------------------------------------------------------
function Delleren.SpellData:NoBuffSpell( id )
	local a = SpellMap[id]
	if not a then return nil end
	return a.buff == 0
end

-------------------------------------------------------------------------------
function Delleren.SpellData:BuffSpell( id )
	local a = SpellMap[id]
	if not a then return nil end
	return a.buff ~= 0
end

-------------------------------------------------------------------------------
local function ApplySpellMods( data, build )
	if data.mods then
		for _,mod in ipairs( data.mods ) do
			mod( data, build )
		end
	end
end

-------------------------------------------------------------------------------
-- Returns a list of spells for a class with a spec, talents and glyphs.
--
-- @param cls     Unit class filename.
-- @param spec    Specialization ID.
-- @param talents Talent build, a string of digits.
-- @param glyphs  A list of glyphs they know.
--
-- @returns A map of spells that they know.
--          [spellid] = { cd = cd duration, maxcharges = max # of charges }
--
function Delleren.SpellData:GetSpells( cls, spec, talents, glyphs )
	if not SpellData[cls] then return {} end -- Unknown class!
	
	local build = {
		spec    = spec;
		talents = talents;
		glyphs  = glyphs;
	}
	
	local state = 1
	
	local spells = {}
	
	for k,v in pairs( SpellData[cls].all or {} ) do
		
		ApplySpellMods( v, build )
		
		local spell = {
			cd = v.cd or ((GetSpellBaseCooldown( k ) or 0)/1000);
			maxcharges = v.charges or 1;
		}
		
		spells[k] = spell
	end
	
	for k,v in pairs( SpellData[cls][spec] or {} ) do
		
		ApplySpellMods( v, build )
		
		local spell = {
			cd = v.cd or ((GetSpellBaseCooldown( k ) or 0)/1000);
			maxcharges = v.charges or 1;
		}
		
		spells[k] = spell
	end
	
	return spells
end
