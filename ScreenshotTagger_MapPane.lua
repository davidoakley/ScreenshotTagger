 --Libraries--------------------------------------------------------------------
local LAM = LibStub("LibAddonMenu-2.0")
local LMP = LibStub("LibMapPins-1.0")
local LGPS = LibStub("LibGPS2")

--Local-Variables---------------------------------------------------------------
local mapPane = {}
local mapScrollListData = 1
local mapScrollListSortKeys = {
	["mapName"] = { },
    ["characterName"] = {  tiebreaker = "mapName" },
}

ZO_CreateStringId("SCREENSHOTTAGGER_NAME", "Screenshots")

function ScreenshotTagger.createMapPane()
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
        normal = "ScreenshotTagger/icons/icon-normaltab.dds",
        pressed = "ScreenshotTagger/icons/icon-selectedtab.dds",
        highlight = "ScreenshotTagger/icons/icon-hovertab.dds",
    }

    --
    -- Create a fragment from the window and add it to the modeBar of the WorldMap RightPane
    --
    local mapPaneFragment = ZO_FadeSceneFragment:New(mapPane)
    WORLD_MAP_INFO.modeBar:Add(SCREENSHOTTAGGER_NAME, {mapPaneFragment}, buttonData)
end

function ScreenshotTagger.populateScrollList(log)
--[[
    local player
    local scrollData = ZO_ScrollList_GetDataList(mapPane.ScrollList)

    ZO_ClearNumericallyIndexedTable(scrollData)

--    for _, event in pairs(log) do
--		table.insert(scrollData, ZO_ScrollList_CreateDataEntry(GOTO_SCROLLLIST_DATA, event))
--    end

    ZO_ScrollList_Commit(mapPane.ScrollList)
    mapPane.sortHeaders:SelectHeaderByKey("mapName")
    mapPane.sortHeaders:SelectHeaderByKey("mapName")
	]]
end
