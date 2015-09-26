-------------------------------------------------------------------------------
-- Delleren
-- External CD caller.
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
--
-- See LICENSE-DELLEREN.TXT
-------------------------------------------------------------------------------

local Delleren = DellerenAddon

local TOPICS = {

-------------------------------------------------------------------------------	
	top = 
	
[-[
[Delleren User's Manual]

Last Updated: 9/26/15

To read the manual, type /delleren help <topic> where <topic> is one of the following words:

  call - Explanation of the call command.
  presets - List of spell presets for the call command.
  cdbar - Information about the CD bar.
  tracking - Information about spell tracking.
  indicator - Information about the Delleren Indicator.

]-];

-------------------------------------------------------------------------------
	delleren =

[-[
Delleren is that one tank that ate up all of the external CDs because he was so squishy unlike brewmasters.
]-];

-------------------------------------------------------------------------------
	call =
[-[
The call command is used to request an external CD from a party member. It's usage is:

/delleren call {spell list} [options]

The spell list is a list of numbers that represent spell IDs that you would like someone in your party to cast. The call command

}

function Delleren.Manual:Read( page )
	
end