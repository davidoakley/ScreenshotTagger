--Libraries--------------------------------------------------------------------
local LAM = LibStub("LibAddonMenu-2.0")
local LMP = LibStub("LibMapPins-1.0")
local LGPS = LibStub("LibGPS2")

ScreenshotTagger = {}
ScreenshotTagger.name = "ScreenshotTagger"
ScreenshotTagger.pinType = "ScreenshotTaggerMapPin"


--Local variables -------------------------------------------------------------


function ScreenshotTagger.OnScreenshotSaved(eventCode, directory, filename)
  SetMapToPlayerLocation()

  --local x, y, zoneMapIndex = gps:LocalToGlobal(GetMapPlayerPosition("player"))
  local worldX, worldY = GetMapPlayerPosition("player")
  local zone = GetUnitZone('player')
  local nx, nz, mapHeading = GetMapPlayerPosition('player')
  local mapName = GetMapName()
  local isHousingZone = GetCurrentZoneHouseId() ~= 0
  local locationName = mapName
  local mapZone, mapSubzone = LMP:GetZoneAndSubzone()
  local cameraHeading = GetPlayerCameraHeading()

  if mapName ~= zone then
    locationName = mapName .. ", " .. zone
  end
  
  if isHousingZone then
    locationName = zone .. ", " .. mapName
  end
  
  d("ScreenshotTagger: Taken screenshot: " .. directory .. filename)
  d("ScreenshotTagger: @ " .. worldX .. "," .. worldY .. "heading" .. cameraHeading)
  d("ScreenshotTagger: location: " .. locationName)
  d("ScreenshotTagger: zone " .. zone .. " mapType " .. GetMapContentType() .. " mapName " .. mapName)
  
  local event = {}
  event.fileName = filename
  event.filePath = directory .. filename
  event.worldPosition = { worldX, worldY }
  event.heading = cameraHeading
  event.locationName = locationName
  event.zone = zone
  event.zoneIndex = GetUnitZoneIndex('player')
  event.mapName = mapName
  event.mapZone = { mapZone, mapSubzone }
  event.houseId = GetCurrentZoneHouseId()
  event.time = os.date("%Y-%m-%d %H:%M:%S")
  event.localisedDate = os.date("%x %X")
  event.characterName = GetUnitName("player")
  
--  local poiCount = GetNumPOIs(event.zoneIndex)

  ScreenshotTagger.savedVariables.log[#ScreenshotTagger.savedVariables.log + 1] = event
  
	ScreenshotTagger.populateScrollList(ScreenshotTagger.savedVariables.log)
end

local function WorldMapStateChanged(_, newState)
    if (newState == SCENE_SHOWING) then
        ScreenshotTagger.populateScrollList(ScreenshotTagger.savedVariables.log)
    end
end

function ScreenshotTagger:Initialise()
	d("ScreenshotTagger:Initialize")
  self.savedVariables = ZO_SavedVars:NewAccountWide("ScreenshotTagger_Data", 1, nil, {})
  
  if self.savedVariables.log == nil then
    self.savedVariables.log = {}
  end
  
  if self.savedVariables.map == nil then
    self.savedVariables.map = {
		pinType = 1,
		pinSize = 30,
		pinLevel = 40,
		filterSettings = { [ScreenshotTagger.pinType] = true }
	}
  end
  
	ScreenshotTagger.createMapPane()
	ScreenshotTagger.populateScrollList(ScreenshotTagger.savedVariables.log)
  
	-- Set wich tooltip must be used
	ScreenshotTagger.OnGamepadPreferredModeChanged()
	
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_SCREENSHOT_SAVED, ScreenshotTagger.OnScreenshotSaved)
	EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, ScreenshotTagger.OnGamepadPreferredModeChanged)
    WORLD_MAP_SCENE:RegisterCallback("StateChange", WorldMapStateChanged)
    GAMEPAD_WORLD_MAP_SCENE:RegisterCallback("StateChange", WorldMapStateChanged)
	
	self:InitialiseMapPins()
end
 
function ScreenshotTagger.OnAddOnLoaded(event, addonName)
  -- d("OnAddOnLoaded " .. addonName)
  if addonName ~= "ScreenshotTagger" then return end
  ScreenshotTagger:Initialise()
  d("ScreenshotTagger: Calling Initialize")
end

 
-- Finally, we'll register our event handler function to be called when the proper event occurs.
EVENT_MANAGER:RegisterForEvent("ScreenshotTagger", EVENT_ADD_ON_LOADED, ScreenshotTagger.OnAddOnLoaded)

SLASH_COMMANDS["/sst"] = function()
  ScreenshotTagger.OnScreenshotSaved(0, "DUMMY/", "DUMMY")
end
