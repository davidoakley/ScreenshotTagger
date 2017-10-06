ScreenshotTagger = {}
ScreenshotTagger.name = "ScreenshotTagger"
 
 --Libraries--------------------------------------------------------------------
local libAM = LibStub("LibAddonMenu-2.0")
local libMP = LibStub("LibMapPins-1.0")
local libGPS = LibStub("LibGPS2")

local PINS = "ScreenshotTagger"


local addon = nil
 
function ScreenshotTagger:Initialize()
  addon = self
  self.savedVariables = ZO_SavedVars:NewAccountWide("ScreenshotTagger_Data", 1, nil, {})
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_SCREENSHOT_SAVED, self.OnScreenshotSaved)
  
  local ddsPath = "ScreenshotTagger/icons/icon.dds"
  local pinTextureLevel = 40
  local pinTextureSize = 30
  local pinTint = ZO_SELECTED_TEXT
  local pinLayout = { level = pinTextureLevel, texture = ddsPath, size = pinTextureSize, tint = pinTint }

  --libMP:AddPinType(PINS, MapCallback_unknown, nil, pinLayout_unknown, pinTooltipCreator)
  --libMP:AddPinFilter(PINS, "Show unknown skyshards", nil, db.filters)

  if self.savedVariables.log == nil then
    self.savedVariables.log = {}
  end
end
 
-- Then we create an event handler function which will be called when the "addon loaded" event
-- occurs. We'll use this to initialize our addon after all of its resources are fully loaded.
function ScreenshotTagger.OnAddOnLoaded(event, addonName)
  -- d("OnAddOnLoaded " .. addonName)
  if addonName ~= "ScreenshotTagger" then return end
  ScreenshotTagger:Initialize()
  d("Calling Initialize")
end

function ScreenshotTagger.OnScreenshotSaved(eventCode, directory, filename)
  SetMapToPlayerLocation()

  --local x, y, zoneMapIndex = gps:LocalToGlobal(GetMapPlayerPosition("player"))
  local worldX, worldY = GetMapPlayerPosition("player")
  local zone = GetUnitZone('player')
  local nx, nz, heading = GetMapPlayerPosition('player')
  local mapName = GetMapName()
  local isHousingZone = GetCurrentZoneHouseId() ~= 0
  local locationName = mapName

  if mapName ~= zone then
    locationName = mapName .. ", " .. zone
  end
  
  if isHousingZone then
    locationName = zone .. ", " .. mapName
  end
  
  d("ScreenshotTagger: Taken screenshot: " .. directory .. filename)
  d("ScreenshotTagger: @ " .. worldX .. "," .. worldY .. "heading" .. heading)
  d("ScreenshotTagger: location: " .. locationName)
  d("ScreenshotTagger: zone " .. zone .. " mapType " .. GetMapContentType() .. " mapName " .. mapName)
  
  local event = {}
  event.filePath = directory .. filename
  event.worldPosition = { worldX, worldY }
  event.heading = heading
  event.locationName = locationName
  event.zone = zone
  event.zoneIndex = GetUnitZoneIndex('player')
  event.mapName = mapName
  event.houseId = GetCurrentZoneHouseId()
  event.time = os.date("%Y-%m-%d %H:%M:%S")
  
--  local poiCount = GetNumPOIs(event.zoneIndex)

  
  addon.savedVariables.log[#addon.savedVariables.log + 1] = event
end
 
-- Finally, we'll register our event handler function to be called when the proper event occurs.
-- d("ScreenshotTagger runs")
EVENT_MANAGER:RegisterForEvent("ScreenshotTagger", EVENT_ADD_ON_LOADED, ScreenshotTagger.OnAddOnLoaded)

SLASH_COMMANDS["/sst"] = function()
  ScreenshotTagger.OnScreenshotSaved(0, "DUMMY/", "DUMMY")
end
