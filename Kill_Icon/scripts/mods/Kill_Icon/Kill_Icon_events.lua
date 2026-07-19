local KI = get_mod("Kill_Icon")

KI.KillIconEvents = {}

-- 引入AttackSettings用于攻击结果检测
local AttackSettings = require("scripts/settings/damage/attack_settings")
local DamageSettings = require("scripts/settings/damage/damage_settings")
local damage_types = DamageSettings.damage_types

-- DoT（Damage over Time）damage_type 集合
-- 基于 scripts/settings/damage/damage_settings.lua 中 damage_types 枚举的实证分析
-- 任何在此集合中的 damage_type 都被视为持续伤害
local DOT_DAMAGE_TYPES = {
    [damage_types.bleeding]      = true,  -- 出血（狂热者血咒等）
    [damage_types.burning]       = true,  -- 燃烧（火焰喷射器、燃烧弹）
    [damage_types.toxin]         = true,  -- 中毒（毒药 stat）
    [damage_types.corruption]    = true,  -- 腐化（永久伤害）
    [damage_types.grimoire]      = true,  -- 死灵之书 tick
    [damage_types.warpfire]      = true,  -- 灵能火焰
    [damage_types.electrocution] = true,  -- 触电（链式闪电法杖等）
}

-- 伙伴 attack_type 白名单（仅 Adamant 狗）
local COMPANION_ATTACK_TYPES = {
    [AttackSettings.attack_types.companion_dog] = true,
}

-- 目标类型检测函数
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

-- 处理攻击结果的内部函数
local function handle_attack_result(damage_profile, attacked_unit, attacking_unit, hit_weakspot, damage, attack_result, attack_type)
    -- 总开关关闭时静默
    if not KI:get("enabled") then
        return
    end

    -- 伙伴攻击判定（用户决策：仅识别 Adamant 狗）
    local is_companion_attack = attack_type and COMPANION_ATTACK_TYPES[attack_type] == true

    -- 只处理有效伤害
    if not damage or damage <= 0 then
        return
    end

    -- 检查是否是本地玩家攻击
    local local_player = Managers.player and Managers.player:local_player_safe(1)
    if not local_player or not local_player.player_unit then
        return
    end

    if attacking_unit ~= local_player.player_unit then
        return
    end

    -- 只处理击杀事件
    if attack_result ~= AttackSettings.attack_results.died then
        return
    end

    -- DoT伤害类型检测
    -- 优先依据 damage_profile.damage_type 字段（权威，由 damage_profile 显式声明）
    -- 后备依据 damage_profile.name 关键字模糊匹配（兼容部分未显式设置 damage_type 的 buff 类伤害）
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

    -- 获取breed信息
    local unit_data_extension = ScriptUnit.has_extension(attacked_unit, "unit_data_system")
    local breed_or_nil = unit_data_extension and unit_data_extension:breed()

    local is_kill_headshot = hit_weakspot == true

    -- 击杀 target 过滤
    local kill_target_setting = KI:get("kill_target") or "all"
    if not is_target_valid(breed_or_nil, kill_target_setting) then
        return
    end

    -- DoT 击杀图标开关
    local dot_icon_allowed = not (is_dot_damage and not KI:get("kill_dot_icon"))

    -- 伙伴击杀图标开关
    local companion_kill_icon_allowed = not (is_companion_attack and not KI:get("companion_kill_icon_enabled"))

    -- 显示击杀图标
    if dot_icon_allowed and companion_kill_icon_allowed and KI:get("kill_icon_enabled") and KI.KillIconManager then
        KI.KillIconManager.show_icon(is_kill_headshot)
    end
end

-- 初始化Damage hook
KI.KillIconEvents.init_damage_hooks = function()
    KI:hook(CLASS.AttackReportManager, "add_attack_result", function(func, self, damage_profile, attacked_unit, attacking_unit, attack_direction, hit_world_position, hit_weakspot, damage, attack_result, attack_type, damage_efficiency, is_critical_strike, ...)
        func(self, damage_profile, attacked_unit, attacking_unit, attack_direction, hit_world_position, hit_weakspot, damage, attack_result, attack_type, damage_efficiency, is_critical_strike, ...)
        handle_attack_result(damage_profile, attacked_unit, attacking_unit, hit_weakspot, damage, attack_result, attack_type)
    end)
end

return KI.KillIconEvents
