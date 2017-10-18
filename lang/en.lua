local strings = {
    -- Controls
    SI_BINDING_NAME_SST_TAKESCREENSHOT	= "Take Enhanced Screenshot",
    
    -- Map Filters
    SST_FILTER_SCREENSHOT_LOCATIONS = "Screenshot locations",

    -- Map Pane
    SST_PANE_TITLE = "Screenshots",
    SST_PANE_FILE_TITLE = "File",
    SST_PANE_FILE_TOOLTIP = "Sort on screenshot file name",
    SST_PANE_LOCATION_TITLE = "Location",
    SST_PANE_LOCATION_TOOLTIP = "Sort on location",

}

for stringId, stringValue in pairs(strings) do
   ZO_CreateStringId(stringId, stringValue)
   SafeAddVersion(stringId, 1)
end
