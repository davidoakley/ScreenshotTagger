--Libraries--------------------------------------------------------------------
local LAM = LibStub("LibAddonMenu-2.0")
local LMP = LibStub("LibMapPins-1.0")
local LGPS = LibStub("LibGPS2")

ScreenshotTagger = {}
ScreenshotTagger.name = "ScreenshotTagger"
ScreenshotTagger.pinType = "ScreenshotTaggerMapPin"
ScreenshotTagger.savedState = {}
ScreenshotTagger.savedState.questIndicator = true

--Local variables -------------------------------------------------------------

function ScreenshotTagger.TakeScreenshot()
	--d("Taking screenshot")
	ScreenshotTagger.savedState.questIndicator = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_QUEST_BESTOWER_INDICATORS)
	SetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_QUEST_BESTOWER_INDICATORS, tostring(false))

	ToggleShowIngameGui()
	
	zo_callLater(function ()
		TakeScreenshot()

		zo_callLater(function ()
			ToggleShowIngameGui()
			SetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_QUEST_BESTOWER_INDICATORS, tostring(ScreenshotTagger.savedState.questIndicator))
		end, 500)

	end, 50)
	
--	ToggleShowIngameGui()
end

function ScreenshotTagger.OnScreenshotSaved(eventCode, directory, filename)
	SetMapToPlayerLocation()

	--local x, y, zoneMapIndex = gps:LocalToGlobal(GetMapPlayerPosition("player"))
--  local worldX, worldY = GetMapPlayerPosition("player")
	local zone = GetUnitZone('player')
	local mapX, mapY, mapHeading = GetMapPlayerPosition('player')
	local worldX, worldY = LGPS:LocalToGlobal(mapX, mapY)
	local mapName = GetMapName()
	local isHousingZone = GetCurrentZoneHouseId() ~= 0
	local locationName = mapName
	local mapZone, mapSubzone = LMP:GetZoneAndSubzone()
	local cameraHeading = GetPlayerCameraHeading()
	local currentMapFloor, currentMapFloorCount = GetMapFloorInfo()

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
	event.mapPosition = { mapX, mapY }
	event.mapIndex = GetCurrentMapZoneIndex()
	event.mapZone = { mapZone, mapSubzone }
	event.floor = currentMapFloor
	event.floorCount = currentMapFloorCount
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
	--d("ScreenshotTagger:Initialize")
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

	ScreenshotTagger.savedState.questIndicator = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_QUEST_BESTOWER_INDICATORS)

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
	if addonName ~= "ScreenshotTagger" then
		return
	end
	ScreenshotTagger:Initialise()
	--d("ScreenshotTagger: Calling Initialize")
end

-- ZO_CreateStringId("SI_BINDING_NAME_SST_TAKESCREENSHOT", "Take Enhanced Screenshot")
 
-- Finally, we'll register our event handler function to be called when the proper event occurs.
EVENT_MANAGER:RegisterForEvent("ScreenshotTagger", EVENT_ADD_ON_LOADED, ScreenshotTagger.OnAddOnLoaded)

SLASH_COMMANDS["/sst"] = function()
	ScreenshotTagger.OnScreenshotSaved(0, "DUMMY/", "DUMMY")
end
