name = "Rain Predictor Widget"
description = "Grants you a widget that predicts the beginning and endings of rain"
author = "splorange"
version = "1.4"
api_version = 10

dst_compatible = true
forge_compatible = true
gorge_compatible = true

dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false

all_clients_require_mod = false
server_only_mod = false
client_only_mod = true

icon_atlas = "atlas-0.xml"
icon = "atlas-0.tex"

configuration_options =
{
    {
        name = "configWidgetPos",
        label = "Widget Position",
        options = 
        {
            {description = "Recommended", data = -30},
            {description = "Lower", data = -105},
        },
        default = -30,
    },
    {
        name = "canAnnounce",
        label = "Announce forecast on click",
        options = 
        {
            {description = "Yes", data = true},
            {description = "No", data = false},
        },
        default = true,
    },

}
