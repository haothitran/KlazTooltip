local addon, ns = ...
local C = {}
ns.C = C

--------------------------------------------------------------------------------
-- // CONFIG
--------------------------------------------------------------------------------

C.Font = {
  ["Family"] = STANDARD_TEXT_FONT,  -- font family
  ["Size"] = 12,                    -- font size
  ["Style"] = "OUTLINE",            -- font outline
}

C.Size = {
  ["Width"] = 200,                   -- frame width
  ["Height"] = 50,                  -- frame height
}

C.Position = {
	["Point"] = "BOTTOMRIGHT",             -- attachment point to parent
	["RelativeTo"] = UIParent,      -- parent frame
	["RelativePoint"] = "BOTTOMRIGHT",     -- parent attachment point
	["XOffset"] = -240,                  -- horizontal offset from parent point
	["YOffset"] = 134,               -- vertical offset from parent point
}
