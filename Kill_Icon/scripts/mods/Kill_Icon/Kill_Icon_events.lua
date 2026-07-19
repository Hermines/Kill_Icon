local KI = get_mod("Kill_Icon")

KI.KillIconEvents = {}

-- Attack result detection
local AttackSettings = require("scripts/settings/damage/attack_settings")
local DamageSettings = require("scripts/settings/damage/damage_settings")
local damage_types = DamageSettings.damage_types

-- DoT damage_type set (from damage_settings.lua damage_types enum)
local DOT_DAMAGE_TYPES = {
    [damage_types.bleeding]      = true,
    [damage_types.burning]       = true,
    [damage_types.toxin]         = true,
    [damage_types.corruption]    = true,
    [damage_types.grimoire]      = true,
    [damage_types.warpfire]      = true,
    [damage_types.electrocution] = true,
}

-- Companion attack_type whitelist (Adamant dog only)
local COMPANION_ATTACK_TYPES = {
    [AttackSettings.attack_types.companion_dog] = true,
}

-- Target type filter
-- target_setting: "all" | "elite" | "special" | "elite_special_boss"
local function is_target_valid(breed_or_nil, target_setting)
    if not target_setting or target_setting == "all" then
        return true
    end

    if not breed_or_nil then
        return false
    end

    local tags = breed_or_nil.tags
    if not tags then
        return false
    end

    if target_setting == "elite" then
        return tags.elite == true
    elseif target_setting == "special" then
        return tags.special == true
    elseif target_setting == "elite_special_boss" then
        return tags.elite == true or tags.special == true or tags.monster == true or tags.captain == true
    end

    return true
end

-- Attack result handler
local function handle_attack_result(damage_profile, attacked_unit, attacking_unit, hit_weakspot, damage, attack_result, attack_type)
    -- Master switch
    if not KI:get("enabled") then
        return
    end

    -- Companion attack (Adamant dog only)
    local is_companion_attack = attack_type and COMPANION_ATTACK_TYPES[attack_type] == true

    -- Only valid damage
    if not damage or damage <= 0 then
        return
    end

    -- Must be local player's attack
    local local_player = Managers.player and Managers.player:local_player_safe(1)
    if not local_player or not local_player.player_unit then
        return
    end

    if attacking_unit ~= local_player.player_unit then
        return
    end

    -- Only kill events
    if attack_result ~= AttackSettings.attack_results.died then
        return
    end

    -- DoT detection: prefer damage_profile.damage_type, fall back to name keyword match
    local is_dot_damage = false
    if damage_profile then
        local dt = damage_profile.damage_type
        if dt and DOT_DAMAGE_TYPES[dt] then
            is_dot_damage = true
        elseif damage_profile.name then
            local profile_name = damage_profile.name:lower()
            if profile_name:find("bleed") or profile_name:find("burn") or profile_name:find("fire") or
               profile_name:find("toxin") or profile_name:find("corruption") or profile_name:find("grimoire") or
               profile_name:find("electrocution") or profile_name:find("warpfire") or
               profile_name:find("chain_lighting") or profile_name:find("chain_lightning") then
                is_dot_damage = true
            end
        end
    end

    -- Get breed info
    local unit_data_extension = ScriptUnit.has_extension(attacked_unit, "unit_data_system")
    local breed_or_nil = unit_data_extension and unit_data_extension:breed()

    local is_kill_headshot = hit_weakspot == true

    -- Target filter
    local kill_target_setting = KI:get("kill_target") or "all"
    if not is_target_valid(breed_or_nil, kill_target_setting) then
        return
    end

    -- DoT kill icon toggle
    local dot_icon_allowed = not (is_dot_damage and not KI:get("kill_dot_icon"))

    -- Companion kill icon toggle
    local companion_kill_icon_allowed = not (is_companion_attack and not KI:get("companion_kill_icon_enabled"))

    -- Show kill icon
    if dot_icon_allowed and companion_kill_icon_allowed and KI:get("kill_icon_enabled") and KI.KillIconManager then
        KI.KillIconManager.show_icon(is_kill_headshot)
    end
end

-- Init damage hooks
KI.KillIconEvents.init_damage_hooks = function()
    KI:hook(CLASS.AttackReportManager, "add_attack_result", function(func, self, damage_profile, attacked_unit, attacking_unit, attack_direction, hit_world_position, hit_weakspot, damage, attack_result, attack_type, damage_efficiency, is_critical_strike, ...)
        func(self, damage_profile, attacked_unit, attacking_unit, attack_direction, hit_world_position, hit_weakspot, damage, attack_result, attack_type, damage_efficiency, is_critical_strike, ...)
        handle_attack_result(damage_profile, attacked_unit, attacking_unit, hit_weakspot, damage, attack_result, attack_type)
    end)
end

return KI.KillIconEvents
