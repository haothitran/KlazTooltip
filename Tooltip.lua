local addon, ns = ...
local C = ns.C

--------------------------------------------------------------------------------
-- // TOOLTIP
--------------------------------------------------------------------------------

local loader = CreateFrame('Frame')
loader:RegisterEvent('ADDON_LOADED')
loader:SetScript('OnEvent', function(self, addon)
  if addon ~= KlazTooltip then
    local function initDB(db, defaults)
      if type(db) ~= 'table' then db = {} end
      if type(defaults) ~= 'table' then return db end
      for k, v in pairs(defaults) do
        if type(v) == 'table' then
          db[k] = initDB(db[k], v)
        elseif type(v) ~= type(db[k]) then
          db[k] = v
        end
      end
    return db
  end

    KlazTooltipDB = initDB(KlazTooltipDB, C.Position)
    C.UserPlaced = KlazTooltipDB
    self:UnregisterEvent('ADDON_LOADED')
  end
end)

--------------------------------------------------------------------------------
-- // ANCHOR FRAME
--------------------------------------------------------------------------------

local anchor = CreateFrame('Frame', 'KlazTooltipAnchor', UIParent)
anchor:SetSize(C.Size.Width, C.Size.Height)
if not anchor.SetBackdrop then Mixin(anchor, BackdropTemplateMixin) end
anchor:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background"})
anchor:SetFrameStrata('HIGH')
anchor:SetMovable(true)
anchor:SetClampedToScreen(true)
anchor:EnableMouse(true)
anchor:SetUserPlaced(true)
anchor:RegisterForDrag('LeftButton')
anchor:RegisterEvent('PLAYER_LOGIN')
anchor:Hide()

anchor.text = anchor:CreateFontString(nil, 'OVERLAY')
anchor.text:SetAllPoints(anchor)
anchor.text:SetFont(C.Font.Family, C.Font.Size, C.Font.Style)
anchor.text:SetShadowOffset(0, 0)
anchor.text:SetText('KlazTooltipAnchor')

anchor:SetScript('OnEvent', function(self, event, arg1)
  if event == 'PLAYER_LOGIN' then
    self:ClearAllPoints()
    self:SetPoint(
    C.UserPlaced.Point,
    C.UserPlaced.RelativeTo,
    C.UserPlaced.RelativePoint,
    C.UserPlaced.XOffset,
    C.UserPlaced.YOffset)
  end
end)

anchor:SetScript('OnDragStart', function(self)
  self:StartMoving()
end)

anchor:SetScript('OnDragStop', function(self)
  self:StopMovingOrSizing()
  self:SetUserPlaced(false)

  point, relativeTo, relativePoint, xOffset, yOffset = self:GetPoint(1)
    if relativeTo then
      relativeTo = relativeTo:GetName();
    else
      relativeTo = self:GetParent():GetName();
    end

  C.UserPlaced.Point = point
  C.UserPlaced.RelativeTo = relativeTo
  C.UserPlaced.RelativePoint = relativePoint
  C.UserPlaced.XOffset = xOffset
  C.UserPlaced.YOffset = yOffset
end)

--------------------------------------------------------------------------------
-- // POSITION
--------------------------------------------------------------------------------

hooksecurefunc('GameTooltip_SetDefaultAnchor', function(self, parent)
  self:SetOwner(parent, 'ANCHOR_NONE')
  self:ClearAllPoints()
  self:SetPoint('BOTTOMRIGHT', anchor, 'BOTTOMRIGHT', 0, 0)
end)

--------------------------------------------------------------------------------
-- // STYLE
--------------------------------------------------------------------------------

local backdrop = {
  bgFile = 'Interface\\ChatFrame\\ChatFrameBackground',
  insets = {top = 1, bottom = 1, left = 1, right = 1}
}

local function UpdateStyle(self)
  self:SetBackdrop(backdrop)
  self:SetBackdropColor(0, 0, 0, .75)
end

local function UpdateUnit(self)
  local _, unit = self:GetUnit()
  if not unit then return end

  -- unit is not a player
  if not UnitIsPlayer(unit) then
    local reaction = UnitReaction(unit, 'player')
    if reaction then
      local color = FACTION_BAR_COLORS[reaction]
      if color then
        GameTooltipStatusBar:SetStatusBarColor(color.r,color.g,color.b)
        GameTooltipTextLeft1:SetTextColor(color.r,color.g,color.b)
      end
    end

  -- unit is any player
  else
    -- name colour
    local color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
    GameTooltipTextLeft1:SetTextColor(color.r,color.g,color.b)
    GameTooltipStatusBar:SetStatusBarColor(color.r,color.g,color.b)

    -- guild name
    if GetGuildInfo(unit) then
      GameTooltipTextLeft2:SetTextColor(1, 0, 1)
    end
  end

  -- status bar
  GameTooltipStatusBar:SetHeight(4)
  GameTooltipStatusBar:SetStatusBarTexture('Interface\\ChatFrame\\ChatFrameBackground')
  GameTooltipStatusBar:ClearAllPoints()
  GameTooltipStatusBar:SetPoint('LEFT', 1, 0)
  GameTooltipStatusBar:SetPoint('RIGHT', -1, 0)
  GameTooltipStatusBar:SetPoint('TOP', 0, -1)

  self:Show()
end

--------------------------------------------------------------------------------
-- // HEALTH VALUE IN STATUS BAR
--------------------------------------------------------------------------------

local formatNumber = function(val)
  if(val >= 1e6) then
    return ("%.1fm"):format(val / 1e6)
  elseif(val >= 1e3) then
    return ("%.0fk"):format(val / 1e3)
  else
    return ("%d"):format(val)
  end
end

local function healthValue(self, value)
  if(not value) then return end

  local min, max = self:GetMinMaxValues()
  if(value < min) or (value > max) then
    return
  end

  if(not self.text) then
    self.text = self:CreateFontString(nil, "OVERLAY")
    self.text:SetPoint("CENTER", self, 0, 0)
    self.text:SetFont(C.Font.Family, C.Font.Size-1, C.Font.Style)
  end

  local hp = formatNumber(self:GetValue())
  self.text:SetText(hp)
end
GameTooltipStatusBar:HookScript("OnValueChanged", healthValue)

--------------------------------------------------------------------------------
-- // SKIN
--------------------------------------------------------------------------------

for _, tooltip in next, {
  GameTooltip,
  WorldMapTooltip,
} do
  tooltip:HookScript('OnShow', UpdateStyle)
  tooltip:HookScript('OnUpdate', UpdateStyle)
  tooltip:HookScript('OnTooltipSetUnit', UpdateUnit)

  for _, shoppingTooltip in next, tooltip.shoppingTooltips do
    shoppingTooltip:HookScript('OnTooltipSetItem', UpdateStyle)
  end
end

--------------------------------------------------------------------------------
-- // SLASH COMMAND
--------------------------------------------------------------------------------

SlashCmdList.KLAZTOOLTIP = function (msg, editbox)
  if string.lower(msg) == 'reset' then
    KlazTooltipDB = C.Position
    ReloadUI()
  elseif string.lower(msg) == 'unlock' then
    if not anchor:IsShown() then
      anchor:Show()
      print('|cff1994ffKlazTooltip|r |cff00ff00Unlocked.|r')
    end
  elseif string.lower(msg) == 'lock' then
    anchor:Hide()
    print('|cff1994ffKlazTooltip|r |cffff0000Locked.|r')
  else
    print('------------------------------------------')
    print('|cff1994ffKlazTooltip commands:|r')
    print('------------------------------------------')
    print('|cff1994ff/klaztooltip unlock|r Unlocks frame to be moved.')
    print('|cff1994ff/klaztooltip lock|r Locks frame in position.')
    print('|cff1994ff/klaztooltip reset|r Resets frame to default position.')
  end
end
SLASH_KLAZTOOLTIP1 = '/klaztooltip'
SLASH_KLAZTOOLTIP2 = '/ktooltip'
SLASH_KLAZTOOLTIP3 = '/ktp'
