-- Added for MyanmarForever v0.4.0-beta on 2026-10-07; see CREDITS.txt.
-- Bindings are opt-in: never replace the player's combat or movement bindings.
local _, A = ...
BINDING_HEADER_MYANMARFOREVER = "Myanmar Forever"
BINDING_NAME_MMFOREVER_TOGGLE = "Show / hide translation"
BINDING_NAME_MMFOREVER_UP = "Scroll translation up"
BINDING_NAME_MMFOREVER_DOWN = "Scroll translation down"
BINDING_NAME_MMFOREVER_CLOSE = "Close translation"
BINDING_NAME_MMFOREVER_BIGGER = "Increase translation text size"
BINDING_NAME_MMFOREVER_SMALLER = "Decrease translation text size"

function MMForeverReaderAction(action)
  if action == "toggle" then A.ToggleReader()
  elseif action == "up" then A.ScrollReader(-126)
  elseif action == "down" then A.ScrollReader(126)
  elseif action == "close" then A.DismissReader()
  elseif action == "bigger" then A.ChangeFont(2)
  elseif action == "smaller" then A.ChangeFont(-2) end
end
