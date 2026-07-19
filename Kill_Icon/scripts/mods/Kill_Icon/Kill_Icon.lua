local KI = get_mod("Kill_Icon")

-- Load events module
KI:io_dofile("Kill_Icon/scripts/mods/Kill_Icon/Kill_Icon_events")

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
