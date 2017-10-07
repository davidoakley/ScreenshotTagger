 --Libraries--------------------------------------------------------------------
local LAM = LibStub("LibAddonMenu-2.0")
local LMP = LibStub("LibMapPins-1.0")
local LGPS = LibStub("LibGPS2")

ScreenshotTagger = {}
ScreenshotTagger.name = "ScreenshotTagger"

ZO_CreateStringId("SCREENSHOTTAGGER_NAME", "Screenshots")

local pinType = "ScreenshotTaggerMapPin"
local INFORMATION_TOOLTIP
local mapPane = {}
local mapScrollListData = 1
local mapScrollListSortKeys = {
	["mapName"] = { },
    ["characterName"] = {  tiebreaker = "mapName" },
}


--Local variables -------------------------------------------------------------
local updatePins = {}
local updating = false
--local addon = nil


local function GetDirectionIcon(heading)
  if     heading >=6.0 or heading < 0.4 then return "icon-n.dds"
  elseif heading < 1.2 then return "icon-nw.dds"
  elseif heading < 2.0 then return "icon-w.dds"
  elseif heading < 2.8 then return "icon-sw.dds"
  elseif heading < 3.6 then return "icon-s.dds"
  elseif heading < 4.4 then return "icon-se.dds"
  elseif heading < 5.2 then return "icon-e.dds"
  elseif heading < 6.0 then return "icon-ne.dds"
  else   return "icon.dds"
  end
end

local function GetPinTexturePath(pin)
	local _, event = pin:GetPinTypeAndTag()
	return "ScreenshotTagger/icons/" .. GetDirectionIcon(event.heading)
end

local function PinTooltipCreator(pin)
	d("PinTooltipCreator")
	local _, event = pin:GetPinTypeAndTag()

	local name = event.time --GetAchievementInfo(pinTag[3])
--	local description, numCompleted = GetAchievementCriterion(pinTag[3], pinTag[4])
	local info = {}

--	if pinTag[5] ~= nil then
--		table.insert(info, "[" .. GetString("SKYS_MOREINFO", pinTag[5]) .. "]")
--	end
--	if numCompleted == 1 then
--		table.insert(info, "[" .. GetString(SKYS_KNOWN) .. "]")
--	end
	d(INFORMATION_TOOLTIP.tooltip)
	

	if IsInGamepadPreferredMode() then
--		INFORMATION_TOOLTIP:LayoutIconStringLine(INFORMATION_TOOLTIP.tooltip, nil, zo_strformat("<<1>>", name), INFORMATION_TOOLTIP.tooltip:GetStyle("mapTitle"))
--		INFORMATION_TOOLTIP:LayoutIconStringLine(INFORMATION_TOOLTIP.tooltip, icon, zo_strformat("(<<1>>) <<2>>", pinTag[4], description), {fontSize = 27, fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_3})
--		if info[1] then
--			INFORMATION_TOOLTIP:LayoutIconStringLine(INFORMATION_TOOLTIP.tooltip, nil, table.concat(info, " / "), INFORMATION_TOOLTIP.tooltip:GetStyle("worldMapTooltip"))
--		end
	else
	INFORMATION_TOOLTIP:AddLine(zo_strformat("<<1>>", event.fileName), "ZoFontGameOutline", ZO_SELECTED_TEXT:UnpackRGB())
	ZO_Tooltip_AddDivider(INFORMATION_TOOLTIP)
	INFORMATION_TOOLTIP:AddLine(zo_strformat("<<1>>", event.characterName), "", ZO_HIGHLIGHT_TEXT:UnpackRGB())
	INFORMATION_TOOLTIP:AddLine(zo_strformat("<<1>>", event.localisedDate), "", ZO_HIGHLIGHT_TEXT:UnpackRGB())
	INFORMATION_TOOLTIP:AddLine(zo_strformat("<<1>>", event.locationName), "", ZO_HIGHLIGHT_TEXT:UnpackRGB())
--		INFORMATION_TOOLTIP:AddLine(zo_strformat("<<1>>", name), "ZoFontGameOutline", ZO_SELECTED_TEXT:UnpackRGB())
--		ZO_Tooltip_AddDivider(INFORMATION_TOOLTIP)
--		INFORMATION_TOOLTIP:AddLine(zo_strformat("(<<1>>) <<2>>", pinTag[4], description), "", ZO_HIGHLIGHT_TEXT:UnpackRGB())
--		if info[1] then
--			INFORMATION_TOOLTIP:AddLine(table.concat(info, " / "), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
--		end
	end
end

local function ShouldDisplayPins()
--	d("ShouldDisplayPins")
	return true
end

local function CreatePins()
--	d("QueueCreatePins")

	local shouldDisplay = ShouldDisplayPins()
	
	local zone, subzone = LMP:GetZoneAndSubzone()
	
	d("CreatePins: iterating " .. zone .. "," .. subzone)
	for _, event in ipairs(ScreenshotTagger.savedVariables.log) do
--	d("CreatePins: * " .. event.time)
		if event.mapZone[1] == zone and event.mapZone[2] == subzone then
			LMP:CreatePin(pinType, event, event.worldPosition[1], event.worldPosition[2])
		end
	end
--	updatePins = {}
	
	updating = false
end

local function QueueCreatePins(pinType)
	d("QueueCreatePins")
	updatePins[pinType] = true

	if not updating then
		updating = true
		if IsPlayerActivated() then
			if LMP.AUI.IsMinimapEnabled() then -- "Cleaner code" is in Destinations addon, but even if adding all checks this addon does the result is same. Duplicates are created with AUI
--	d("QueueCreatePins: zo_callLater")
				zo_callLater(CreatePins, 150) -- Didn't find anything proper than this. If other MiniMap addons are loaded, It will fail and create duplicates
			else
--	d("QueueCreatePins: CreatePins")
				CreatePins() -- Normal way. AUI will fire its refresh after this code has run so it will create duplicates if left "as is".
			end
		else
--	d("QueueCreatePins: registering for EVENT_PLAYER_ACTIVATED")
			EVENT_MANAGER:RegisterForEvent("ScreenshotTagger_PinUpdate", EVENT_PLAYER_ACTIVATED,
				function(event)
					EVENT_MANAGER:UnregisterForEvent("ScreenshotTagger_PinUpdate", event)
					CreatePins()
				end)
		end
	end
end
 
local function MapCallback()
	d("MapCallback")
	if not LMP:IsEnabled(pinType) then return end
--	if not LMP:IsEnabled(pinType) or (GetMapType() > MAPTYPE_ZONE) then return end
	QueueCreatePins(pinType)
end

local function createMapPane()
    local x,y = ZO_WorldMapLocations:GetDimensions()
    local _, point, relativeTo, relativePoint, offsetX, offsetY = ZO_WorldMapLocations:GetAnchor()

    mapPane = WINDOW_MANAGER:CreateTopLevelWindow(nil)
    mapPane:SetMouseEnabled(true)
    mapPane:SetMovable( false )
    mapPane:SetClampedToScreen(true)
    mapPane:SetDimensions( x, y )
    mapPane:SetAnchor( point, relativeTo, relativePoint, offsetX, offsetY )
    mapPane:SetHidden( true )

    -- Create Sort Headers
    mapPane.Headers = WINDOW_MANAGER:CreateControl("$(parent)Headers",mapPane,nil)
    mapPane.Headers:SetAnchor( TOPLEFT, mapPane, TOPLEFT, 0, 0 )
    mapPane.Headers:SetHeight(32)

    mapPane.Headers.Name = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)Name",mapPane.Headers,"ZO_SortHeader")
    mapPane.Headers.Name:SetDimensions(150,32)
    mapPane.Headers.Name:SetAnchor( TOPLEFT, mapPane.Headers, TOPLEFT, 8, 0 )
	
    ZO_SortHeader_Initialize(mapPane.Headers.Name, "Date", "time", ZO_SORT_ORDER_UP, TEXT_ALIGN_LEFT, "ZoFontGameLargeBold")
    ZO_SortHeader_SetTooltip(mapPane.Headers.Name, "Sort on screenshot date")

    mapPane.Headers.Location = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)Location",mapPane.Headers,"ZO_SortHeader")
    mapPane.Headers.Location:SetDimensions(150,32)
    mapPane.Headers.Location:SetAnchor( LEFT, mapPane.Headers.Name, RIGHT, 18, 0 )
    ZO_SortHeader_Initialize(mapPane.Headers.Location, "Location", "locationName", ZO_SORT_ORDER_UP, TEXT_ALIGN_LEFT, "ZoFontGameLargeBold")
    ZO_SortHeader_SetTooltip(mapPane.Headers.Location, "Sort on location")

    mapPane.sortHeaders = ZO_SortHeaderGroup:New(mapPane:GetNamedChild("Headers"), SHOW_ARROWS)
    mapPane.sortHeaders:RegisterCallback(
        ZO_SortHeaderGroup.HEADER_CLICKED,
        function(key, order)
            table.sort(
                ZO_ScrollList_GetDataList(mapPane.ScrollList),
                function(entry1, entry2)
                    if isInGroup(entry1.data.playerName) then
                        if not isInGroup(entry2.data.playerName) then
                            return true -- 1 (group member) comes before 2 (non-member)
                        end
                    else
                        if isInGroup(entry2.data.playerName) then
                            return false -- 1 (non-member) comes after 2 (group member)
                        end
                    end
                    -- both members or both non-members, break the tie using the usual column sorting rules
                    return ZO_TableOrderingFunction(entry1.data, entry2.data, key, mapScrollListSortKeys, order)
                end)
            ZO_ScrollList_Commit(mapPane.ScrollList)
        end)
    mapPane.sortHeaders:AddHeadersFromContainer()

    -- Create a scrollList
    mapPane.ScrollList = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)ScreenshotTaggerScrollList", mapPane, "ZO_ScrollList")
    mapPane.ScrollList:SetDimensions(x, y-32)
    mapPane.ScrollList:SetAnchor(TOPLEFT, mapPane.Headers, BOTTOMLEFT, 0, 0)

    -- Add a datatype to the scrollList
    ZO_ScrollList_AddDataType(mapPane.ScrollList, mapScrollListData, "ScreenshotTaggerRow", 23,
        function(control, data)

            local nameLabel = control:GetNamedChild("Name")
            local locationLabel = control:GetNamedChild("Location")

            local friendColor = ZO_ColorDef:New(0.3, 1, 0, 1)
            local groupColor = ZO_ColorDef:New(0.46, .73, .76, 1)

            local displayedlevel = 0

            nameLabel:SetText(zo_strformat("<<T:1>>", data.playerName))

            if data.playerLevel < 50 then
                displayedlevel = data.playerLevel
            else
                displayedlevel = "CP" .. data.playerVr
            end

            nameLabel.tooltipText = zo_strformat("<<T:1>>\n<<X:2>> <<X:3>>\n<<X:4>>",
                data.playeratName, displayedlevel, GetClassName(1, data.playerClass), data.playerGuilds)

            locationLabel:SetText(zo_strformat("<<C:1>>", data.zoneName))

            if isInGroup(data.playerName) then
                ZO_SelectableLabel_SetNormalColor(nameLabel, groupColor)
                ZO_SelectableLabel_SetNormalColor(locationLabel, groupColor)

            elseif IsFriend(data.playerName) then
                ZO_SelectableLabel_SetNormalColor(nameLabel, friendColor)
                ZO_SelectableLabel_SetNormalColor(locationLabel, friendColor)

            else
                ZO_SelectableLabel_SetNormalColor(nameLabel, ZO_NORMAL_TEXT)
                ZO_SelectableLabel_SetNormalColor(locationLabel, ZO_NORMAL_TEXT)
            end
        end
    )

    local buttonData = {
        normal = "ScreenshotTagger/icons/icon.dds",
        pressed = "ScreenshotTagger/icons/icon.dds",
        highlight = "ScreenshotTagger/icons/icon.dds",
    }

    --
    -- Create a fragment from the window and add it to the modeBar of the WorldMap RightPane
    --
    local mapPaneFragment = ZO_FadeSceneFragment:New(mapPane)
    WORLD_MAP_INFO.modeBar:Add(SCREENSHOTTAGGER_NAME, {mapPaneFragment}, buttonData)
end

 
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
end

-- Gamepad Switch -------------------------------------------------------------
local function OnGamepadPreferredModeChanged()
	if IsInGamepadPreferredMode() then
		INFORMATION_TOOLTIP = ZO_MapLocationTooltip_Gamepad
	else
		INFORMATION_TOOLTIP = InformationTooltip
	end
	d(INFORMATION_TOOLTIP)
end

function ScreenshotTagger:Initialize()
	d("ScreenshotTagger:Initialize")
  self.savedVariables = ZO_SavedVars:NewAccountWide("ScreenshotTagger_Data", 1, nil, {})
  
  if self.savedVariables.log == nil then
    self.savedVariables.log = {}
  end
  
  if self.savedVariables.map == nil then
    self.savedVariables.map = {
		pinType = 1,
		pinSize = 20,
		pinLevel = 40,
		filterSettings = { [pinType] = true }
	}
  end
  
	createMapPane()
  
	-- Set wich tooltip must be used
	OnGamepadPreferredModeChanged()

  --local ddsPath = "ScreenshotTagger/icons/icon.dds"
  local ddsPath = "ScreenshotTagger/icons/icon.dds"
  local pinTint = ZO_SELECTED_TEXT
  local pinLayout = { level = self.savedVariables.map.pinLevel, texture = GetPinTexturePath, size = self.savedVariables.map.pinSize, tint = pinTint }

  local pinTooltipCreator = {}
  pinTooltipCreator.tooltip = 1 --TOOLTIP_MODE.INFORMATION
  pinTooltipCreator.creator = PinTooltipCreator --function(pin)

	LMP:AddPinType(pinType, MapCallback, nil, pinLayout, pinTooltipCreator)
	LMP:AddPinFilter(pinType, "Screenshot locations", nil, self.savedVariables.map.filterSettings)
	
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_SCREENSHOT_SAVED, ScreenshotTagger.OnScreenshotSaved)
	EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, OnGamepadPreferredModeChanged)
end
 
function ScreenshotTagger.OnAddOnLoaded(event, addonName)
  -- d("OnAddOnLoaded " .. addonName)
  if addonName ~= "ScreenshotTagger" then return end
  ScreenshotTagger:Initialize()
  d("ScreenshotTagger: Calling Initialize")
end

 
-- Finally, we'll register our event handler function to be called when the proper event occurs.
-- d("ScreenshotTagger runs")
EVENT_MANAGER:RegisterForEvent("ScreenshotTagger", EVENT_ADD_ON_LOADED, ScreenshotTagger.OnAddOnLoaded)

SLASH_COMMANDS["/sst"] = function()
  ScreenshotTagger.OnScreenshotSaved(0, "DUMMY/", "DUMMY")
end
