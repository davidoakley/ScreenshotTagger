--Libraries--------------------------------------------------------------------
local LMP = LibStub("LibMapPins-1.0")
local LGPS = LibStub("LibGPS2")


--Local variables -------------------------------------------------------------
local updatePins = {}
local updating = false
local INFORMATION_TOOLTIP


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

function ScreenshotTagger.GetPinTexturePath(pin)
	local _, event = pin:GetPinTypeAndTag()
	return "ScreenshotTagger/icons/" .. GetDirectionIcon(event.heading)
end

local function PinTooltipCreator(pin)
	--d("PinTooltipCreator")
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
--	ZO_Tooltip_AddDivider(INFORMATION_TOOLTIP)
	local dateLine = event.localisedDate
	if event.characterName ~= GetUnitName("player") then
		dateLine = dateLine .. " (" .. event.characterName .. ")"
	end
	INFORMATION_TOOLTIP:AddLine(zo_strformat("<<1>>", dateLine), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
--	INFORMATION_TOOLTIP:AddVerticalPadding(-10)
--	INFORMATION_TOOLTIP:AddLine(zo_strformat("<<1>>", event.locationName), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
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
	
	--d("CreatePins: iterating " .. zone .. "," .. subzone)
	for _, event in ipairs(ScreenshotTagger.savedVariables.log) do
--	d("CreatePins: * " .. event.time)
		if event.mapZone[1] == zone and event.mapZone[2] == subzone then
			LMP:CreatePin(ScreenshotTagger.pinType, event, event.mapPosition[1], event.mapPosition[2])
		end
	end
--	updatePins = {}
	
	updating = false
end

local function QueueCreatePins(pinType)
	--d("QueueCreatePins")
	updatePins[pinType] = true

	if not updating then
		updating = true
		if IsPlayerActivated() then
			if LMP.AUI.IsMinimapEnabled() then -- "Cleaner code" is in Destinations addon, but even if adding all checks this addon does the result is same. Duplicates are created with AUI
				zo_callLater(CreatePins, 150) -- Didn't find anything proper than this. If other MiniMap addons are loaded, It will fail and create duplicates
			else
				CreatePins() -- Normal way. AUI will fire its refresh after this code has run so it will create duplicates if left "as is".
			end
		else
			EVENT_MANAGER:RegisterForEvent("ScreenshotTagger_PinUpdate", EVENT_PLAYER_ACTIVATED,
				function(event)
					EVENT_MANAGER:UnregisterForEvent("ScreenshotTagger_PinUpdate", event)
					CreatePins()
				end)
		end
	end
end
 
function ScreenshotTagger.MapPinCallback()
	--d("MapCallback")
	if not LMP:IsEnabled(ScreenshotTagger.pinType) then return end
--	if not LMP:IsEnabled(ScreenshotTagger.pinType) or (GetMapType() > MAPTYPE_ZONE) then return end
	QueueCreatePins(ScreenshotTagger.pinType)
end

-- Gamepad Switch -------------------------------------------------------------
function ScreenshotTagger.OnGamepadPreferredModeChanged()
	if IsInGamepadPreferredMode() then
		INFORMATION_TOOLTIP = ZO_MapLocationTooltip_Gamepad
	else
		INFORMATION_TOOLTIP = InformationTooltip
	end
	--d(INFORMATION_TOOLTIP)
end


function ScreenshotTagger:InitialiseMapPins()
	local pinTint = ZO_SELECTED_TEXT
	local pinLayout = { level = self.savedVariables.map.pinLevel, texture = ScreenshotTagger.GetPinTexturePath, size = self.savedVariables.map.pinSize, tint = pinTint }

	local pinTooltipCreator = {}
	pinTooltipCreator.tooltip = 1 --TOOLTIP_MODE.INFORMATION
	pinTooltipCreator.creator = PinTooltipCreator --function(pin)

	LMP:AddPinType(self.pinType, ScreenshotTagger.MapPinCallback, nil, pinLayout, pinTooltipCreator)
	LMP:AddPinFilter(self.pinType, "Screenshot locations", nil, self.savedVariables.map.filterSettings)
end

