local KI = get_mod("Kill_Icon")

-- Dropdown option texts are localization keys; DMF localizes them automatically
local target_options = {
    { text = "all",                value = "all" },
    { text = "elite",              value = "elite" },
    { text = "special",            value = "special" },
    { text = "elite_special_boss", value = "elite_special_boss" },
}

return {
    name = KI:localize("mod_name"),
    description = KI:localize("mod_description"),
    is_togglable = true,
    options = {
        widgets = {
            {
                setting_id = "general_settings",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "enabled",
                        type = "checkbox",
                        default_value = true,
                    },
                    -- Companion kill icon toggle
                    {
                        setting_id = "companion_kill_icon_enabled",
                        type = "checkbox",
                        default_value = true,
                    },
                },
            },
            {
                setting_id = "icon_settings",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "kill_icon_enabled",
                        type = "checkbox",
                        default_value = true,
                        -- Detailed icon settings are shown only when kill icons are enabled
                        sub_widgets = {
                            {
                                setting_id = "kill_target",
                                type = "dropdown",
                                default_value = "all",
                                options = target_options,
                            },
                            {
                                setting_id = "kill_dot_icon",
                                type = "checkbox",
                                default_value = true,
                            },
                            {
                                setting_id = "kill_icon_duration",
                                type = "numeric",
                                default_value = 2,
                                range = { 1, 5 },
                                decimals_number = 1,
                                step_size_value = 0.5,
                                unit_text = "second",
                            },
                            {
                                setting_id = "kill_icon_size",
                                type = "numeric",
                                default_value = 80,
                                range = { 50, 200 },
                                decimals_number = 0,
                                step_size_value = 5,
                                unit_text = "percent",
                            },
                            {
                                setting_id = "kill_icon_spacing",
                                type = "numeric",
                                default_value = 100,
                                range = { 50, 100 },
                                decimals_number = 0,
                                step_size_value = 5,
                                unit_text = "percent",
                            },
                            {
                                setting_id = "kill_icon_transparency",
                                type = "numeric",
                                default_value = 80,
                                range = { 0, 100 },
                                decimals_number = 0,
                                step_size_value = 5,
                                unit_text = "percent",
                            },
                            {
                                setting_id = "kill_icon_normal_color",
                                type = "color",
                                default_value = { 255, 216, 229, 207 },
                                has_alpha = false,
                            },
                            {
                                setting_id = "kill_icon_headshot_color",
                                type = "color",
                                default_value = { 255, 255, 156, 6 },
                                has_alpha = false,
                            },
                            {
                                setting_id = "manage_icon_position",
                                type = "checkbox",
                                default_value = true,
                                -- Position sliders are shown only when this mod manages the position
                                sub_widgets = {
                                    {
                                        setting_id = "kill_icon_vertical_position",
                                        type = "numeric",
                                        default_value = 55,
                                        range = { 0, 100 },
                                        decimals_number = 0,
                                        step_size_value = 5,
                                        unit_text = "percent",
                                    },
                                    {
                                        setting_id = "kill_icon_horizontal_position",
                                        type = "numeric",
                                        default_value = 50,
                                        range = { 0, 100 },
                                        decimals_number = 0,
                                        step_size_value = 5,
                                        unit_text = "percent",
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
    },
}
