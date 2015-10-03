
# DELLEREN

#### User's Manual 

Last Updated 11:36 PM 10/2/2015

-----
Delleren is an addon that simplifies the process of identifying and calling for spells from other players in your raid. For optimal results, your entire raid should have Delleren installed.

-----
## Quick Start

Create a macro and paste this into it:

    /delleren call painsups

And use that macro to call for a defensive CD. Reading the rest of the manual is highly recommended.

-----
## Configuration

Type `/delleren config` in your chat window to open the Delleren configuration panel.

Configuration sections:

  - Calling: Options for when making calls.
  - CD Bar: Options for the CD bar.
  - Indicator: Options to style the main indicator.
  - Profiles: Profile creation and loading.
  - Sounds: Options for which sounds are associated with events.
  - Tracked Spells: Spell tracking editor.

-----
## Calling

The "call" command is used to call for CDs from other players. It's usage is:

    /delleren call {spell list} [options]

`{spell list}` is a plain list of numbers that correspond to spell IDs that you would like your raid to cast. An easy way to get spell IDs is from wowhead URLs. Just do a web search for "<spellname> wowhead" and the first result will likely be it's wowhead article and the number in the URL is the spell ID. There's also a spell ID search tool included in the Delleren configuration panel under Tracked Spells.

There are also a few presets listed below that you can use to populate your spell list. (Listed further below.)

If the person you are calling has Delleren installed, then an indicator will appear on their screen telling them to give you a CD, and a yellow indicator will appear on your screen while you wait for them. If they don't have the addon installed, then Delleren will whisper them to give you the CD instead, and a flashing-red indicator will appear on your screen; it will also make a unique sound. It's recommended that you also call out to them with voice-chat if they don't have Delleren installed, because it's easy to miss whispers during combat.

Delleren contains a small database of useful spells that you can call for. These are called tracked spells. If you call for a tracked spell, then the picking of a target is instant, otherwise, Delleren will ask the raid if they have the spell available before calling them. To make a non-tracked call, the people that may provide the spell or item must have Delleren installed.

### Options:

#### -i : Item mode.

If this flag is set, then the spell list will be treated as a list of item IDs instead. In other words, you may call for an item to be used rather than a spell.

#### -m : Manual mode.

If this flag is set, the query system will not automatically choose a player to call a spell from. A window will open that lets you select which player to call.

#### -c : Simple cast mode. 

If this flag is set, the query system won't check for a buff being cast on you. Rather, the request will be satisfied if the person called simply casts the spell, not caring if they cast it on someone or if the spell isn't castable on a target. This is mainly used for spells that don't provide a buff.

#### -p : Player list. 

This option is followed by a list of player names or special keywords that determine who we should call for a spell. Players who are listed first will be prioritized over players who are listed after. It doesn't guarantee that the order will be followed exactly because of latency issues. For example, the highest priority player could experience a bit of lag and not respond in time to the request, thus being skipped for a call. 

The special keywords are `*t` which matches any tank, `*h` which matches any healer, `*d` which matches any damager, and `*` which matches anyone.

For example: `-p llanna delleren regal` will try to request a spell from those three players, giving Llanna the highest priority and then end the query if none of those three have a desired spell available. If you add a `*` to the end, then it will *try* to get a spell from those three before resorting to getting something from any other player who can satisfy the request.

If you don't provide your own filter, there are default filters that are used depending on your role. If you are a tank, then the default filter is:

    *t *h *d *

-which means, prefer calling a tank, over a healer, over the damagers. If you aren't a tank, then the default filter is: 

    *h *d *t *

-which means, prefer calling from healers, over damagers, over tanks.


It's best explained with examples:

    /delleren call 6940 33206 114030 102342

These spell IDs are Hand of Sacrifice, Pain Suppression, Vigilance, and Ironbark. This command will ask for one of these spells from anyone who can give them.

    /delleren call 6940 33206 114030 102342 -m

Same as before, but it will open a menu to let you choose who to call from.

    /delleren call 76577 -c

Ask for a smoke bomb (spell ID 76577) to be used. Since Smoke Bomb doesn't target players directly, the -c flag is used to tell the system that you don't expect a buff to be cast on yourself.

    /delleren call 33206 -p regal

Ask for Pain Suppresion from a player named Regal, and fail the request if it's on CD.

    /delleren call 6940 33206 114030 102342 -p regal daxsik *

Ask for damage reduction CDs, but prefer getting one from your trusty healers named Regal and Daxsik before resorting to getting one from any other players.

    /delleren call 49040 -i

Call for a Jeeves (item ID 49040) to be summoned. `-i` makes it an item request.

    /delleren call jeeves -i -m

List who has a Jeeves available to be used. The spell preset `jeeves` was used here. See below for other presets.

    /delleren call painsups -p *h

Call for a defensive CD from any healer.


Spell presets may be used along with spell IDs, the current ones are:

 - `painsups` - Hand of Sacrifice, Pain Suppression, Vigilance, and Ironbark
 - `antimagiczone` - Anti-Magic Zone
 - `ironbark` - Ironbark
 - `sac` - Hand of Sacrifice
 - `bop` - Hand of Protection
 - `psup` - Pain Suppression
 - `smokebomb` - Smoke Bomb
 - `vig` - Vigilance
 - `jeeves` - Jeeves (item)

-----
## Indicator States

The Delleren Indicator shows the status of a call or request. 

 - Flashing Blue: Asking the raid for data.
 - Flashing Red: Calling a player without Delleren. The callee and spell name will be shown. Telling them via voice-chat is recommended.
 - Yellow: Calling a player with Delleren. The callee and spell name will be shown. Voice-chat should be unecessary in this case.
 - Flashing Purple: Being called for a spell. The spell name and who is calling will be shown.
 - Green Fade: Successful operation.
 - Red Fade: Failed operation.

-----
## Query Notes

When calling a player with Delleren, they have 7 seconds to respond to the request. If they don't have Delleren, they have 10 seconds to respond. If they don't respond in time, your indicator will show a failed-state, and the player in question will be placed in "timeout".

When a player is in timeout, they will not be called for another CD unless they are the only option remaining, in which case they will be tried again for their CD.

Delleren handles call-collisions. If a target has Delleren installed and receives two calls at once, then they will deny one of them, and the denied caller will automatically continue calling from someone else. If they don't have Delleren installed, the call will simply fail for the person that doesn't receive the CD, and they will have to make another call if they still need a CD.

-----
## CD Bar

Delleren provides a simple cooldown tracking interface that allows you to easily see if certain desired spells are available in your raid via the CD Bar. The CD Bar can be toggled on or off in the configuration panel. Disabling the CD Bar will increase performance slightly. 

The buttons on the CD Bar may be clicked to call for the corresponding spells. Left-click makes an auto-query. Right-click makes a manual-query, so a menu will be shown, listing who has the spell ready.

Which spells are tracked is controlled in the configuration panel under Tracked Spells. There is an edit box in which you can list spell IDs to track. There is also a tool underneath the edit box to help you find Spell IDs from spell names. Currently, the spells you want to track must be defined already in Delleren's spell database. Defining more spells is not supported yet.

The buttons change visual states according to the situation. Grayed-out/disabled means that all of the people who can provide the spell are dead. The buttons turn red when all of the players who can give the spell are out of range. A cooldown overlay is only shown when all players have the spell on CD, otherwise, a normal button will be shown, with a "stacks" number showing how many charges of the spell are ready to be used, if more than one.

-----
## Player Ignore

You can disable using spells from certain players in your party or raid using the ignore feature. Type `/delleren ignore` to bring up the ignore menu and click on the player names to toggle their ignored state.

If you want to ignore incoming calls from a player (e.g. if they are abusing the addon and spamming calls for no reason), you can ignore them the same way you ignore their chat.
