# Kill Icon / 击杀图标

一个用于《战锤 40K：暗潮》（Warhammer 40,000: Darktide）的 DMF 模组，在击杀敌人时于屏幕上方显示击杀图标，并区分普通击杀与爆头击杀。

## 致谢

本模组参考了 [m4a1deathDawn/Hit_Kill_Sounds](https://github.com/m4a1deathDawn/Hit_Kill_Sounds) 的设计思路，在其基础上进行了精简：

- 仅保留**击杀图标显示**功能，移除了击杀音效等其他模块。
- **不再通过本地 HTTP 服务加载外部 PNG 图片文件**，而是直接引用游戏内置的 UI 材质路径（`content/ui/materials/hud/interactions/icons/enemy` 与 `enemy_priority`，爆头圆环特效使用 `scanner_drill_wireframe_small`）。

这样做的好处是：无需额外启动本地服务器，无需打包图片资源，避免外部 HTTP 请求带来的性能开销与安全风险，同时与游戏本体 UI 风格保持一致。

## 功能特性

- 普通击杀与爆头击杀使用不同图标，爆头时附带扩散圆环特效。
- 完整的入场 / 显示 / 离场动画，多 slot 队列支持连续击杀。
- 高度可配置（详见下方设置项）。
- 中英双语本地化。

## 安装

依赖 [Darktide Mod Framework](https://www.nexusmods.com/warhammer40kdarktide/mods/8)。

将本模组文件夹放入 DMF 的 `mods` 目录即可，启动游戏后在模组管理器中启用 `Kill Icon`。

## 设置项

### 通用设置

| 设置项 | 说明 | 默认值 |
| --- | --- | --- |
| 总开关 | 模组主开关 | 开 |
| 启用伙伴击杀图标 | 是否对 Adamant 狗的击杀显示图标 | 开 |

### 图标设置

| 设置项 | 说明 | 默认值 |
| --- | --- | --- |
| 启用击杀图标 | 击杀图标开关 | 开 |
| 击杀图标生效对象 | 全部敌人 / 仅精英 / 仅专家 / 精英、专家和 Boss | 全部敌人 |
| 持续伤害击杀显示图标 | DoT（燃烧、出血、中毒等）击杀是否显示图标 | 开 |
| 击杀图标透明度 | 0–100 | 80 |
| 普通图标颜色 - R/G/B | 普通击杀图标颜色 | 216 / 229 / 207 |
| 爆头图标颜色 - R/G/B | 爆头击杀图标颜色 | 255 / 156 / 6 |
| 图标垂直位置 | 0–100 | 55 |
| 图标水平位置 | 0–100 | 50 |
| 图标大小 | 5–20 | 8 |
| 图标显示时长 | 1.0s / 1.5s / 2.0s / 2.5s / 3.0s | 2.0s |

## 实现说明

- **事件钩子**：通过 hook `AttackReportManager.add_attack_result` 捕获击杀事件，依据 `attack_result == died` 判定击杀，`hit_weakspot` 判定爆头。
- **DoT 识别**：优先依据 `damage_profile.damage_type`，后备依据 `damage_profile.name` 关键字模糊匹配（bleed / burn / fire / toxin / corruption / grimoire / electrocution / warpfire / chain_lightning）。
- **伙伴识别**：仅识别 `attack_types.companion_dog`（Adamant 狗）。
- **HUD 注册**：通过 hook `UIManager.load_hud_packages` 与 `UIHud.init` 将自定义 HUD 元素注入游戏 HUD，并在 `load_hud_packages` 阶段声明 `package = "packages/ui/views/scanner_display_view/scanner_display_view"` 以确保爆头圆环材质在任务中被加载（游戏仅在打开扫描器时才主动加载此包）。
- **Hub 屏蔽**：在枢纽（hub）模式下不绘制图标。

## 文件结构

```
Kill_Icon/
├── Kill_Icon.mod                              # 模组入口定义
└── scripts/mods/Kill_Icon/
    ├── Kill_Icon.lua                          # 主脚本：HUD 元素注册与注入
    ├── Kill_Icon_data.lua                     # DMF 设置项定义
    ├── Kill_Icon_events.lua                   # 击杀事件钩子与目标过滤
    ├── Kill_Icon_hud.lua                      # HUD 元素类、slot 队列与渲染逻辑
    └── Kill_Icon_localization.lua             # 中英文本地化
```

## 许可

本模组仅用于学习与交流，原 Hit_Kill_Sounds 的相关权益归原作者所有。
