local KI = get_mod("Kill_Icon")

-- 使用 io_dofile 加载事件模块
KI:io_dofile("Kill_Icon/scripts/mods/Kill_Icon/Kill_Icon_events")

-- HUD元素配置
-- package 字段指定 HUD 元素所需的材质包，由 UIManager 在 HUD 初始化时自动加载
-- - packages/ui/views/scanner_display_view/scanner_display_view:
--   包含爆头圆环特效材质 scanner_drill_wireframe_small（游戏仅在打开扫描器时才加载此包，
--   任务中不主动加载，需在此声明才能保证 HUD 元素渲染时材质已就绪）
-- - enemy / enemy_priority 材质属于 packages/ui/hud/world_markers/world_markers，
--   由游戏玩家 HUD 在任务中始终加载，无需在此声明
local hud_elements = {
    {
        filename = "Kill_Icon/scripts/mods/Kill_Icon/Kill_Icon_hud",
        class_name = "HudKillIcon",
        package = "packages/ui/views/scanner_display_view/scanner_display_view",
    },
}

-- 注册HUD路径
for _, hud_element in ipairs(hud_elements) do
    KI:add_require_path(hud_element.filename)
end

-- 把 Kill_Icon 的 HUD 元素定义塞进一个 elements 列表（共享给下面的两个 hook）
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
-- 时机：HudLoader 加载任务 HUD 材质包阶段（早于 UIHud.init）
-- 作用：把 Kill_Icon 元素加入 element_definitions，触发 _load_ui_element_packages
--       读取 package 字段并通过 Managers.package:load() 加载 scanner_display_view 包
-- 不做这一步的话，材质包永远不会被加载，爆头圆环会渲染成占位方块
KI:hook("UIManager", "load_hud_packages", function(func, self, element_definitions, complete_callback)
    for _, hud_element in ipairs(hud_elements) do
        if not table.find_by_key(element_definitions, "class_name", hud_element.class_name) then
            table.insert(element_definitions, build_element_def(hud_element))
        end
    end

    return func(self, element_definitions, complete_callback)
end)

-- Hook 2: UIHud.init
-- 时机：UIHud 实例创建阶段（晚于 load_hud_packages）
-- 作用：把 Kill_Icon 元素插入到 UIHud 的 elements 列表，触发 _setup_elements 实例化 HudKillIcon
-- 注意：这里的 package 字段不会被再次加载（load_hud_packages 已结束），只是为了保持
--       element 定义结构完整，便于将来 _unload_element_packages 等游戏流程识别
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
