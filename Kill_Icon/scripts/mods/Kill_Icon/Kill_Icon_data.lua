local KI = get_mod("Kill_Icon")

-- Target type options (use localized text)
local TARGET_OPTIONS = {
    {text = "All Enemies", value = "all"},
    {text = "Elite Only", value = "elite"},
    {text = "Special Only", value = "special"},
    {text = "Elite, Special and Boss", value = "elite_special_boss"},
}

-- Apply localization to target options
for i, opt in ipairs(TARGET_OPTIONS) do
    local localized = KI:localize(opt.value)
    if localized and localized ~= opt.value then
        TARGET_OPTIONS[i].text = localized
    end
end

-- Deep-copy options per dropdown to avoid DMF recursive localization
local function make_localized_options(raw_options)
    local result = {}
    for i, opt in ipairs(raw_options) do
        local text = opt.text
        local localized = KI:localize(opt.value)
        if localized and localized ~= opt.value then
            text = localized
        end
        result[i] = { text = text, value = opt.value }
    end
    return result
end

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
                    },
                    {
                        setting_id = "kill_target",
                        type = "dropdown",
                        default_value = "all",
                        options = make_localized_options(TARGET_OPTIONS),
                    },
                    {
                        setting_id = "kill_dot_icon",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "kill_icon_transparency",
                        type = "numeric",
                        default_value = 80,
                        range = {0, 100},
                        step = 5,
                    },
                    {
                        setting_id = "kill_icon_normal_color_r",
                        type = "numeric",
                        default_value = 216,
                        range = {0, 255},
                    },
                    {
                        setting_id = "kill_icon_normal_color_g",
                        type = "numeric",
                        default_value = 229,
                        range = {0, 255},
                    },
                    {
                        setting_id = "kill_icon_normal_color_b",
                        type = "numeric",
                        default_value = 207,
                        range = {0, 255},
                    },
                    {
                        setting_id = "kill_icon_headshot_color_r",
                        type = "numeric",
                        default_value = 255,
                        range = {0, 255},
                    },
                    {
                        setting_id = "kill_icon_headshot_color_g",
                        type = "numeric",
                        default_value = 156,
                        range = {0, 255},
                    },
                    {
                        setting_id = "kill_icon_headshot_color_b",
                        type = "numeric",
                        default_value = 6,
                        range = {0, 255},
                    },
                    {
                        setting_id = "custom_hud_mode",
                        tooltip = "custom_hud_mode_tooltip",
                        type = "checkbox",
                        default_value = false,
                    },
                    {
                        setting_id = "kill_icon_vertical_position",
                        type = "numeric",
                        default_value = 55,
                        range = {0, 100},
                        step = 5,
                    },
                    {
                        setting_id = "kill_icon_horizontal_position",
                        type = "numeric",
                        default_value = 50,
                        range = {0, 100},
                        step = 5,
                    },
                    {
                        setting_id = "kill_icon_size",
                        type = "numeric",
                        default_value = 8,
                        range = {5, 20},
                        step = 1,
                    },
                    {
                        setting_id = "kill_icon_duration",
                        type = "dropdown",
                        default_value = "20",
                        options = {
                            {text = "1.0s", value = "10"},
                            {text = "1.5s", value = "15"},
                            {text = "2.0s", value = "20"},
                            {text = "2.5s", value = "25"},
                            {text = "3.0s", value = "30"},
                        },
                    },
                },
            },
        }
    }
}
