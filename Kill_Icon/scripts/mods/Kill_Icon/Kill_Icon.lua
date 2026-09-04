local KI = get_mod("Kill_Icon")

-- Load events module
KI:io_dofile("Kill_Icon/scripts/mods/Kill_Icon/Kill_Icon_events")

-- Sanitize settings left over from an older settings format.
-- Old versions stored "kill_icon_duration" as a string ("10".."30") and "kill_icon_size"
-- as 5-20. Invalid values are reset to the new defaults instead of being migrated.
local stored_duration = KI:get("kill_icon_duration")
if type(stored_duration) ~= "number" then
    KI:set("kill_icon_duration", 2)
end

local stored_size = KI:get("kill_icon_size")
if type(stored_size) ~= "number" or stored_size < 50 or stored_size > 200 then
    KI:set("kill_icon_size", 80)
end

-- Validate icon spacing (percent); reset out-of-range values to the default.
-- Values below 50% are discarded because icons would overlap
local stored_spacing = KI:get("kill_icon_spacing")
if type(stored_spacing) ~= "number" or stored_spacing < 50 or stored_spacing > 100 then
    KI:set("kill_icon_spacing", 100)
end

-- Cached settings: the HUD reads them every frame, and DMF clones table values
-- (colors) on every 'get' call, so read them once here and sync on change
KI.settings = {
    enabled                       = KI:get("enabled"),
    companion_kill_icon_enabled   = KI:get("companion_kill_icon_enabled"),
    kill_icon_enabled             = KI:get("kill_icon_enabled"),
    kill_target                   = KI:get("kill_target"),
    kill_dot_icon                 = KI:get("kill_dot_icon"),
    kill_icon_duration            = KI:get("kill_icon_duration"),
    kill_icon_size                = KI:get("kill_icon_size"),
    kill_icon_spacing             = KI:get("kill_icon_spacing"),
    kill_icon_transparency        = KI:get("kill_icon_transparency"),
    kill_icon_normal_color        = KI:get("kill_icon_normal_color"),
    kill_icon_headshot_color      = KI:get("kill_icon_headshot_color"),
    manage_icon_position          = KI:get("manage_icon_position"),
    kill_icon_vertical_position   = KI:get("kill_icon_vertical_position"),
    kill_icon_horizontal_position = KI:get("kill_icon_horizontal_position"),
}

KI.on_setting_changed = function(setting_id)
    if KI.settings[setting_id] ~= nil then
        KI.settings[setting_id] = KI:get(setting_id)
    end
end

-- HUD element config
-- package declares the texture package required by the HUD element (auto-loaded by UIManager)
-- scanner_display_view contains the headshot circle texture scanner_drill_wireframe_small
-- (game only loads it when scanner is open, so we must declare it here)
local hud_elements = {
    {
        filename = "Kill_Icon/scripts/mods/Kill_Icon/Kill_Icon_hud",
        class_name = "HudKillIcon",
        package = "packages/ui/views/scanner_display_view/scanner_display_view",
    },
}

-- Register HUD paths
for _, hud_element in ipairs(hud_elements) do
    KI:add_require_path(hud_element.filename)
end

-- Build element definition (shared by the two hooks below)
local function build_element_def(hud_element)
    return {
        class_name = hud_element.class_name,
        filename = hud_element.filename,
        use_hud_scale = true,
        visibility_groups = hud_element.visibility_groups or {"alive"},
        package = hud_element.package,
    }
end

-- Hook 1: UIManager.load_hud_packages
-- Inserts Kill_Icon into element_definitions so its package gets loaded
-- Without this, the headshot circle texture would never load and render as a placeholder
KI:hook("UIManager", "load_hud_packages", function(func, self, element_definitions, complete_callback)
    for _, hud_element in ipairs(hud_elements) do
        if not table.find_by_key(element_definitions, "class_name", hud_element.class_name) then
            table.insert(element_definitions, build_element_def(hud_element))
        end
    end

    return func(self, element_definitions, complete_callback)
end)

-- Hook 2: UIHud.init
-- Inserts Kill_Icon into UIHud's elements list so HudKillIcon gets instantiated
KI:hook("UIHud", "init", function(func, self, elements, visibility_groups, params)
    for _, hud_element in ipairs(hud_elements) do
        if not table.find_by_key(elements, "class_name", hud_element.class_name) then
            table.insert(elements, build_element_def(hud_element))
        end
    end

    return func(self, elements, visibility_groups, params)
end)

KI.on_all_mods_loaded = function()
    if KI.KillIconEvents then
        KI.KillIconEvents:init_damage_hooks()
    end
end
