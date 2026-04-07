# Shogun Prototype - 开发日志（协作版）

> 维护约定：每次代码改动前先阅读本文件；每次代码改动后同步更新本文件。

---

## 快速上手（给自己和协作者）

### 项目基线
- 引擎版本：Godot 4.6
- 渲染后端：GL Compatibility
- 设计视口：1920x1080
- 当前主工程目录：`d:/mygodot/shugon`
- 当前主循环：主菜单 -> 战斗 ->（胜利暂时直接下一战，失败为占位结束）

### 推荐阅读顺序（5分钟理解项目）
1. `project.godot`（全局配置、主场景、Autoload、输入映射）
2. `scenes/main.tscn` + `scripts/ui/main_menu.gd`（入口）
3. `scenes/battle/battle_scene.tscn` + `scripts/battle/battle_scene.gd`（战斗总控）
4. `scripts/battle/turn_manager.gd`（回合阶段流转）
5. `scripts/battle/entity.gd`、`player.gd`、`enemy_base.gd`（实体与行为核心）

### 代码职责速查
| 路径 | 作用 |
|------|------|
| `scripts/core/game_manager.gd` | 全局状态与场景切换 |
| `scripts/battle/battle_scene.gd` | 战斗主控、UI、输入、敌人生成 |
| `scripts/battle/turn_manager.gd` | 回合状态机（玩家->敌人->结算） |
| `scripts/battle/grid.gd` | 1D 网格坐标、占位、碰撞、世界坐标换算 |
| `scripts/battle/entity.gd` | 实体通用逻辑（HP、受击/攻击动画、浮字） |
| `scripts/battle/player.gd` | 玩家行动与技能/能量系统 |
| `scripts/battle/enemy_base.gd` | 敌人基类与意图系统 |
| `scripts/battle/enemies/*.gd` | 敌人具体AI（史莱姆、弓手） |

---

## 当前可玩状态（2026-04-07）

### 功能
- 回合流程：玩家输入 -> 玩家行动 -> 敌人行动 -> 结算
- 玩家动作：移动、4个技能、防御、跳过
- 资源系统：能量（上限5），击杀/防御/跳过可回能
- 敌人：史莱姆（近战节奏型）、弓手（远程+后撤）
- 反馈：突进、受击闪烁、受击抖动、浮字、命中脉冲、屏幕震动
- 意图：敌人每回合前展示下一步行为

### 操作
- 左移：A / 左方向键
- 右移：D / 右方向键
- 确认攻击（默认技能1）：Space / Enter
- 跳过：S
- 技能：1 / 2 / 3 / 4（按钮也可触发）
- 鼠标：点击相邻空格移动

---

## 完整目录结构（排除 `.godot/.git/.claude` 缓存）

```text
├─ .vscode/
│  ├─ mcp.json
│  └─ settings.json
├─ addons/
│  └─ godot_mcp/
│     ├─ tools/
│     │  ├─ asset_tools.gd
│     │  ├─ asset_tools.gd.uid
│     │  ├─ file_tools.gd
│     │  ├─ file_tools.gd.uid
│     │  ├─ project_tools.gd
│     │  ├─ project_tools.gd.uid
│     │  ├─ scene_tools.gd
│     │  ├─ scene_tools.gd.uid
│     │  ├─ script_tools.gd
│     │  ├─ script_tools.gd.uid
│     │  ├─ visualizer_tools.gd
│     │  └─ visualizer_tools.gd.uid
│     ├─ mcp_client.gd
│     ├─ mcp_client.gd.uid
│     ├─ plugin.cfg
│     ├─ plugin.gd
│     ├─ plugin.gd.uid
│     ├─ tool_executor.gd
│     └─ tool_executor.gd.uid
├─ assets/
│  ├─ fonts/
│  │  ├─ fusion-pixel-12px-monospaced-zh_hans.otf
│  │  ├─ fusion-pixel-12px-monospaced-zh_hans.otf.import
│  │  ├─ zpix.ttf
│  │  └─ zpix.ttf.import
│  └─ icons_preview/
│     ├─ grid_icons_1.png
│     ├─ grid_icons_1.png.import
│     ├─ grid_icons_2.png
│     ├─ grid_icons_2.png.import
│     ├─ slash_icon_1.png
│     ├─ slash_icon_1.png.import
│     ├─ slash_icon_2.png
│     ├─ slash_icon_2.png.import
│     ├─ sprite_sheet_1.png
│     ├─ sprite_sheet_1.png.import
│     ├─ sprite_sheet_2.png
│     └─ sprite_sheet_2.png.import
├─ scenes/
│  ├─ battle/
│  │  └─ battle_scene.tscn
│  └─ main.tscn
├─ scripts/
│  ├─ battle/
│  │  ├─ enemies/
│  │  │  ├─ archer_enemy.gd
│  │  │  ├─ archer_enemy.gd.uid
│  │  │  ├─ slime_enemy.gd
│  │  │  └─ slime_enemy.gd.uid
│  │  ├─ battle_scene.gd
│  │  ├─ battle_scene.gd.uid
│  │  ├─ enemy_base.gd
│  │  ├─ enemy_base.gd.uid
│  │  ├─ entity.gd
│  │  ├─ entity.gd.uid
│  │  ├─ grid.gd
│  │  ├─ grid.gd.uid
│  │  ├─ player.gd
│  │  ├─ player.gd.uid
│  │  ├─ skill_data.gd
│  │  ├─ skill_data.gd.uid
│  │  ├─ turn_manager.gd
│  │  └─ turn_manager.gd.uid
│  ├─ core/
│  │  ├─ game_manager.gd
│  │  └─ game_manager.gd.uid
│  └─ ui/
│     ├─ main_menu.gd
│     └─ main_menu.gd.uid
├─ shogun_project/
│  ├─ .vscode/
│  │  └─ settings.json
│  ├─ assets/
│  │  ├─ fonts/
│  │  │  ├─ fusion-pixel-12px-monospaced-zh_hans.otf
│  │  │  └─ zpix.ttf
│  │  └─ icons_preview/
│  │     ├─ grid_icons_1.png
│  │     ├─ grid_icons_2.png
│  │     ├─ slash_icon_1.png
│  │     ├─ slash_icon_2.png
│  │     ├─ sprite_sheet_1.png
│  │     └─ sprite_sheet_2.png
│  ├─ scenes/
│  │  ├─ battle/
│  │  │  └─ battle_scene.tscn
│  │  └─ main.tscn
│  ├─ scripts/
│  │  ├─ battle/
│  │  │  ├─ enemies/
│  │  │  │  └─ slime_enemy.gd
│  │  │  ├─ battle_scene.gd
│  │  │  ├─ enemy_base.gd
│  │  │  ├─ entity.gd
│  │  │  ├─ grid.gd
│  │  │  ├─ player.gd
│  │  │  ├─ skill_data.gd
│  │  │  └─ turn_manager.gd
│  │  ├─ core/
│  │  │  └─ game_manager.gd
│  │  └─ ui/
│  │     └─ main_menu.gd
│  ├─ shogun_project/
│  │  ├─ scenes/
│  │  │  ├─ battle/
│  │  │  │  └─ battle_scene.tscn
│  │  │  └─ main.tscn
│  │  ├─ scripts/
│  │  │  ├─ battle/
│  │  │  │  ├─ enemies/
│  │  │  │  │  └─ slime_enemy.gd
│  │  │  │  ├─ battle_scene.gd
│  │  │  │  ├─ enemy_base.gd
│  │  │  │  ├─ entity.gd
│  │  │  │  ├─ grid.gd
│  │  │  │  ├─ player.gd
│  │  │  │  └─ turn_manager.gd
│  │  │  ├─ core/
│  │  │  │  └─ game_manager.gd
│  │  │  └─ ui/
│  │  │     └─ main_menu.gd
│  │  ├─ devlog.md
│  │  ├─ icon.svg
│  │  └─ project.godot
│  ├─ devlog.md
│  ├─ icon.svg
│  ├─ icon.svg.import
│  └─ project.godot
├─ .editorconfig
├─ .gitattributes
├─ .gitignore
├─ devlog.md
├─ godot-mcp-server-0.4.1.tgz
├─ icon.svg
├─ icon.svg.import
├─ project.godot
└─ tmp_mcp_call_is_playing.js
```

---

## 版本记录

## 版本 0.6.2 - VS Code 文件树清理（2026-04-07）

### 本次修改
- 在工作区设置中隐藏 Godot 自动生成文件，减少文件树噪音：
  - `**/*.uid`
  - `**/*.import`
- 说明：仅影响 VS Code 显示，不影响 Godot 资源导入与运行。

### 影响文件
- `.vscode/settings.json`
- `devlog.md`

## 版本 0.6.1 - 文档增强 + 动画回位修复（2026-04-07）

### 本次修改
- 文档增强：
  - 将日志从“纯精简版”升级为“协作版”结构（快速上手、职责速查、完整目录树、版本记录）
  - 明确记录当前引擎版本为 **Godot 4.6**
- 动画回位修复（核心）：
  - 修复攻击/受击后偶发停在位移终点的问题
  - 在实体基类新增位移动画抢占与收尾归位机制（统一管理 `_motion_tween`）
  - 受击抖动从并行 tween 改为顺序 tween，避免多位置 tweener 同时写入 `position`
  - 动画结束统一强制回到 `_visual_anchor`

### 影响文件
- `scripts/battle/entity.gd`
- `devlog.md`

---

## 版本 0.6.0 - 文档压缩 + 1080p布局适配（2026-04-07）

### 本次修改
- 文档压缩：保留关键里程碑，删减重复描述
- 分辨率改为 1920x1080，纹理过滤切到线性
- 战斗布局高清化（网格、UI、体积、特效比例）
- 主菜单高清化（标题和按钮尺寸）

### 影响文件
- `project.godot`
- `scripts/battle/grid.gd`
- `scripts/battle/battle_scene.gd`
- `scripts/battle/entity.gd`
- `scripts/battle/enemy_base.gd`
- `scripts/ui/main_menu.gd`
- `devlog.md`

---

## 版本 0.5.2 - 技能结算修复（2026-04-06）

### 关键修复
- 技能支持空放（无命中也可释放）
- 释放即扣能量（施放成功即消耗）
- 范围先做合法过滤再结算
- 伤害与能量下限保护（>=0）
- 未命中显示“落空”反馈

### 影响文件
- `scripts/battle/player.gd`
- `scripts/battle/skill_data.gd`

---

## 历史里程碑（摘要）

| 版本 | 核心内容 |
|------|----------|
| 0.5.1 | 修复弓手攻击/受击视觉飘移（锚点同步与位置入口统一） |
| 0.5.0 | 新增弓手敌人；战场敌人组合扩展；清理挡UI节点 |
| 0.4.0 | 引入能量与技能框架（4技能 + 防御/跳过 + 技能栏） |
| 0.3.0 | 完成主要战斗视觉反馈（受击、浮字、震屏、范围预览） |
| 0.2.0 | 敌人意图系统 + 鼠标交互 + Attack/Skip按钮 |
| 0.1.0 | 项目骨架搭建（主菜单、战斗场景、回合/网格/实体基础） |

---

## 当前已知问题
- 仍缺少音效与BGM
- 胜利/失败后的界面仍是占位流程
- 存在多层历史副本目录，开发时必须确认当前操作路径是主工程根目录

---

## 下一阶段优先级
1. 增加敌人类型（战士、冲锋怪等）并补齐行为差异
2. 接入正式素材并替换色块占位资源
3. 搭建“战斗后奖励/升级”界面并连通楼层推进
4. 补齐音效与关键技能特效
