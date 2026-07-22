local KI = get_mod("Kill_Icon")

local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

-- Icon size
local ICON_SIZE = 64
local ICON_ROOT_SIZE = 96
-- Leave animation: max slide-left offset (px), independent of slot spacing
local LEAVE_OFFSET = 110
local MAX_SLOTS = 10

-- Built-in material paths (no external HTTP PNG loading)
local MATERIAL_PATHS = {
    normal   = "content/ui/materials/hud/interactions/icons/enemy",
    headshot = "content/ui/materials/hud/interactions/icons/enemy_priority",
    circle   = "content/ui/materials/backgrounds/scanner/scanner_drill_wireframe_small",
}

-- Queue structure
KI.KillIconManager = {
    _slots = {},
}

-- Init slots
for i = 1, MAX_SLOTS do
    KI.KillIconManager._slots[i] = {
        active = false,
        is_headshot = false,
        start_time = 0,
        target_x = 0,
        current_x = 0,
        leaving = false,
        leaving_start_time = 0,
        pending_leave = false,
        leave_ready_time = 0,
        leave_assigned_delay = 0,
    }
end

-- Public API to show an icon
KI.KillIconManager.show_icon = function(is_headshot)
    local manager = KI.KillIconManager
    local now_time = Managers.time:time("main")

    -- Compute dynamic spacing from current icon size setting
    local size_scale = (KI:get("kill_icon_size") or 10) / 10
    local dynamic_spacing = ICON_ROOT_SIZE * size_scale - 20

    -- 1. Find a free slot
    local free_slot = nil
    for i = 1, MAX_SLOTS do
        if not manager._slots[i].active then
            free_slot = i
            break
        end
    end

    -- Otherwise reuse the oldest leaving slot
    if not free_slot then
        for i = 1, MAX_SLOTS do
            if manager._slots[i].leaving then
                free_slot = i
                break
            end
        end
    end

    -- Otherwise force-reuse the leftmost slot
    if not free_slot then
        local leftmost_x = math.huge
        for i = 1, MAX_SLOTS do
            local s = manager._slots[i]
            if s.active and s.target_x < leftmost_x then
                leftmost_x = s.target_x
                free_slot = i
            end
        end
        -- Mark as leaving to exclude from shift below
        if free_slot then
            manager._slots[free_slot].leaving = true
        end
    end

    -- 2. Compute icon left edge offset relative to kill_icon_root
    -- The newest slot targets offset 0 (at the parent's position).
    -- Older active slots are shifted left by dynamic_spacing in step 3 below.
    -- kill_icon_root's absolute position is managed either by Kill_Icon (custom_hud_mode OFF)
    -- or by custom_hud (custom_hud_mode ON).
    local center_x = 0

    -- 3. Shift all active (non-leaving) slots left by one position
    for i = 1, MAX_SLOTS do
        local s = manager._slots[i]
        if s.active and not s.leaving then
            s.target_x = s.target_x - dynamic_spacing
        end
    end

    -- 4. Activate new slot, sliding in from 60px right of center
    local slot = manager._slots[free_slot]
    slot.active = true
    slot.is_headshot = is_headshot
    slot.start_time = now_time
    slot.target_x = center_x
    slot.current_x = center_x + 60
    slot.leaving = false
    slot.pending_leave = false
end

-- Default base position computed from default settings (used as the initial
-- position of kill_icon_root before update() runs, and as a fallback when
-- custom_hud has not yet customized the position)
local screen_width = UIWorkspaceSettings.screen.size[1]
local screen_height = UIWorkspaceSettings.screen.size[2]
local DEFAULT_HORIZ_POS = 50
local DEFAULT_VERT_POS = 55
local default_base_x = screen_width * (DEFAULT_HORIZ_POS / 100) - ICON_ROOT_SIZE / 2
local default_base_y = (DEFAULT_VERT_POS / 100) * (screen_height - ICON_ROOT_SIZE)

-- Scenegraph definition
local scenegraph_definition = {
    screen = UIWorkspaceSettings.screen,
    -- Parent scenegraph for all kill icon slots.
    -- When custom_hud_mode is OFF, Kill_Icon positions this from settings.
    -- When custom_hud_mode is ON, custom_hud can move this as a single unit.
    kill_icon_root = {
        horizontal_alignment = "left",
        parent = "screen",
        vertical_alignment = "top",
        size = {ICON_ROOT_SIZE, ICON_ROOT_SIZE},
        position = {default_base_x, default_base_y, 0},
    },
}

-- Create scenegraph entry per slot (parented to kill_icon_root so they move as a group)
for i = 1, MAX_SLOTS do
    scenegraph_definition["icon_root_" .. i] = {
        horizontal_alignment = "left",
        parent = "kill_icon_root",
        vertical_alignment = "top",
        size = {ICON_ROOT_SIZE, ICON_ROOT_SIZE},
        position = {0, 0, 0},
    }
    scenegraph_definition["circle_root_" .. i] = {
        horizontal_alignment = "center",
        parent = "icon_root_" .. i,
        vertical_alignment = "center",
        size = {ICON_ROOT_SIZE, ICON_ROOT_SIZE},
        position = {0, 0, 1},
    }
end

-- Widget definitions
local widget_definitions = {}

-- Create widget pair per slot (uses built-in material paths via content.icon)
for i = 1, MAX_SLOTS do
    widget_definitions["kill_icon_" .. i] = UIWidget.create_definition({
        {
            style_id = "icon",
            value_id = "icon",
            pass_type = "texture",
            style = {
                color = {
                    0,
                    255,
                    255,
                    255,
                },
                offset = {0, 0, 0},
                size = {ICON_SIZE, ICON_SIZE},
            },
            visibility_function = function(content, style)
                return content.icon ~= nil
            end,
        },
    }, "icon_root_" .. i)

    widget_definitions["circle_icon_" .. i] = UIWidget.create_definition({
        {
            style_id = "circle",
            value_id = "circle",
            pass_type = "texture",
            style = {
                color = {
                    255,
                    255,
                    0,
                    0,
                },
                offset = {0, 0, 0},
                size = {ICON_SIZE, ICON_SIZE},
            },
            visibility_function = function(content, style)
                return content.circle ~= nil
            end,
        },
    }, "circle_root_" .. i)
end

-- HUD element class
local HudKillIcon = class("HudKillIcon", "HudElementBase")

HudKillIcon.init = function(self, parent, draw_layer, start_scale)
    HudKillIcon.super.init(self, parent, draw_layer, start_scale, {
        scenegraph_definition = scenegraph_definition,
        widget_definitions = widget_definitions,
    })
end

HudKillIcon.update = function(self, dt, t, ui_renderer, render_settings, input_service)
    local manager = KI.KillIconManager
    local now_time = Managers.time:time("main")

    -- Animation params
    local enter_duration = 0.3
    local leave_duration = 0.2

    -- Settings
    local size_scale = (KI:get("kill_icon_size") or 10) / 10
    local vert_pos = KI:get("kill_icon_vertical_position") or 0
    local screen_height = UIWorkspaceSettings.screen.size[2]
    local screen_width = UIWorkspaceSettings.screen.size[1]
    local horiz_pos = KI:get("kill_icon_horizontal_position") or 50
    local base_x = screen_width * (horiz_pos / 100) - ICON_ROOT_SIZE / 2
    local base_y = (vert_pos / 100) * (screen_height - ICON_ROOT_SIZE)
    local display_duration = (tonumber(KI:get("kill_icon_duration")) or 20) / 10

    local normal_r = KI:get("kill_icon_normal_color_r") or 255
    local normal_g = KI:get("kill_icon_normal_color_g") or 255
    local normal_b = KI:get("kill_icon_normal_color_b") or 255
    local headshot_r = KI:get("kill_icon_headshot_color_r") or 255
    local headshot_g = KI:get("kill_icon_headshot_color_g") or 0
    local headshot_b = KI:get("kill_icon_headshot_color_b") or 0
    local transparency_factor = (KI:get("kill_icon_transparency") or 100) / 100

    -- Update kill_icon_root base position.
    -- When custom_hud_mode is OFF, Kill_Icon manages the base position from settings.
    -- When custom_hud_mode is ON, custom_hud manages the base position, so we leave it untouched.
    if not KI:get("custom_hud_mode") then
        local kill_icon_root = self._ui_scenegraph["kill_icon_root"]
        if kill_icon_root then
            kill_icon_root.position[1] = base_x
            kill_icon_root.position[2] = base_y
            self._update_scenegraph = true
        end
    end

    -- Detect slots that newly reach the leave threshold this frame.
    -- Assign staggered delays so leftmost slot leaves first, others follow.
    local new_pending = {}
    for i = 1, MAX_SLOTS do
        local slot = manager._slots[i]
        if slot.active and not slot.leaving and not slot.pending_leave then
            local elapsed = now_time - slot.start_time
            if elapsed > display_duration then
                slot.pending_leave = true
                slot.leave_ready_time = now_time
                table.insert(new_pending, {index = i, target_x = slot.target_x})
            end
        end
    end

    if #new_pending > 0 then
        table.sort(new_pending, function(a, b)
            return a.target_x < b.target_x
        end)
        local stagger_delay = 0.03
        for rank, entry in ipairs(new_pending) do
            manager._slots[entry.index].leave_assigned_delay = (rank - 1) * stagger_delay
        end
    end

    -- Update each slot (positions are relative to kill_icon_root)
    for i = 1, MAX_SLOTS do
        local slot = manager._slots[i]
        local icon_widget = self._widgets_by_name["kill_icon_" .. i]
        local circle_widget = self._widgets_by_name["circle_icon_" .. i]
        local icon_root = self._ui_scenegraph["icon_root_" .. i]

        if not icon_root then
            -- Skip invalid slot
        elseif not slot.active then
            -- Hide inactive slot
            if icon_widget.content.icon ~= nil then
                icon_widget.content.icon = nil
            end
            if circle_widget.content.circle ~= nil then
                circle_widget.content.circle = nil
            end
        elseif slot.leaving then
            -- Leave animation
            local leave_elapsed = now_time - slot.leaving_start_time
            if leave_elapsed >= leave_duration then
                slot.active = false
                slot.leaving = false
                icon_widget.content.icon = nil
                circle_widget.content.circle = nil
            else
                -- Slide left and fade out
                local progress = leave_elapsed / leave_duration
                progress = 1 - (1 - progress) ^ 3
                local leave_offset = LEAVE_OFFSET * progress
                slot.current_x = slot.target_x - leave_offset

                local alpha = math.floor(255 * (1 - progress) * transparency_factor)
                icon_widget.style.icon.color = {alpha, slot.is_headshot and headshot_r or normal_r, slot.is_headshot and headshot_g or normal_g, slot.is_headshot and headshot_b or normal_b}
                circle_widget.content.circle = nil

                icon_root.position[1] = slot.current_x
                icon_root.position[2] = 0
                self._update_scenegraph = true
            end
        else
            -- Active slot
            local elapsed = now_time - slot.start_time
            local is_headshot = slot.is_headshot

            -- Check if staggered leave delay has elapsed
            if slot.pending_leave and now_time - slot.leave_ready_time >= slot.leave_assigned_delay then
                slot.pending_leave = false
                slot.leaving = true
                slot.leaving_start_time = now_time
            end

            -- Smooth move to target_x
            slot.current_x = slot.current_x + (slot.target_x - slot.current_x) * dt * 10

            icon_root.position[1] = slot.current_x
            icon_root.position[2] = 0
            self._update_scenegraph = true

            -- Compute alpha (enter fade only; exit fade is handled by leave branch)
            local alpha = 255
            if elapsed < enter_duration then
                local progress = elapsed / enter_duration
                progress = 1 - (1 - progress) ^ 3
                alpha = math.floor(255 * progress)
            end

            -- Enter scale animation: 1.8 -> size_scale (ease-out)
            local scale = size_scale
            if elapsed < enter_duration then
                local progress = elapsed / enter_duration
                progress = 1 - (1 - progress) ^ 3
                scale = 1.8 - (1.8 - size_scale) * progress
            end

            -- Apply texture
            icon_widget.content.icon = is_headshot and MATERIAL_PATHS.headshot or MATERIAL_PATHS.normal

            -- Apply color
            if is_headshot then
                icon_widget.style.icon.color = {math.floor(alpha * transparency_factor), headshot_r, headshot_g, headshot_b}
            else
                icon_widget.style.icon.color = {math.floor(alpha * transparency_factor), normal_r, normal_g, normal_b}
            end

            -- Apply scale and offset
            local scaled_size = {
                math.floor(ICON_SIZE * scale),
                math.floor(ICON_SIZE * scale),
            }
            icon_widget.style.icon.size = scaled_size
            icon_widget.style.icon.offset = {
                math.floor((ICON_ROOT_SIZE - scaled_size[1]) * 0.5),
                math.floor((ICON_ROOT_SIZE - scaled_size[2]) * 0.5),
                0,
            }

            -- Circle effect (headshot only)
            if is_headshot then
                circle_widget.content.circle = MATERIAL_PATHS.circle

                local base_display_size = ICON_SIZE * size_scale
                local circle_duration = 0.5
                local circle_elapsed = elapsed - enter_duration

                local circle_scale = 1
                local circle_alpha = 255

                if circle_elapsed > 0 and circle_elapsed < circle_duration then
                    local progress = circle_elapsed / circle_duration
                    circle_scale = 1 + 3 * progress
                    circle_alpha = math.floor(255 * (1 - progress))
                elseif circle_elapsed >= circle_duration then
                    circle_alpha = 0
                end

                local circle_size = {
                    math.floor(base_display_size * circle_scale),
                    math.floor(base_display_size * circle_scale),
                }
                circle_widget.style.circle.size = circle_size
                circle_widget.style.circle.offset = {
                    math.floor((ICON_ROOT_SIZE - circle_size[1]) * 0.5),
                    math.floor((ICON_ROOT_SIZE - circle_size[2]) * 0.5),
                    0,
                }
                circle_widget.style.circle.color = {math.floor(circle_alpha * transparency_factor), headshot_r, headshot_g, headshot_b}
            else
                circle_widget.content.circle = nil
            end
        end
    end

    HudKillIcon.super.update(self, dt, t, ui_renderer, render_settings, input_service)
end

HudKillIcon.draw = function(self, dt, t, ui_renderer, render_settings, input_service)
    if not KI:get("kill_icon_enabled") then
        return
    end

    -- Skip in hub
    local game_mode_name = Managers.state.game_mode and Managers.state.game_mode:game_mode_name()
    local is_in_hub = game_mode_name == "hub"
    if is_in_hub then
        return
    end

    HudKillIcon.super.draw(self, dt, t, ui_renderer, render_settings, input_service)
end

return HudKillIcon
