# Shogun Prototype - 开发日志

---

## 版本 0.2.0 - 敌人意图 + 鼠标交互 (2026-03-31)

### 本次修改的文件

| 文件 | 改动内容 |
|------|---------|
| `scripts/battle/battle_scene.gd` | **大幅重写** — 新增鼠标点击移动/攻击、格子悬停高亮、Attack/Skip按钮、敌人意图刷新、战斗结束状态管理 |
| `scripts/battle/enemy_base.gd` | 新增意图显示系统：`update_intent()` 计算意图，头顶显示文字标签（ATK!/>>>/<<</.../!!!） |
| `scripts/battle/player.gd` | 新增 `try_move_to(pos)` 点击目标格子移动、`try_attack_at(pos)` 点击目标格子攻击 |
| `scripts/battle/grid.gd` | 新增 `world_to_grid()` 将鼠标坐标转换为格子索引 |

### 新增功能

#### 敌人意图预告
- 每个回合开始时，所有敌人头顶显示它们下一步的行为
- `ATK!` (红色) = 将要攻击
- `>>>` 或 `<<<` (黄色) = 将要移动
- `...` (灰色) = 待机
- 意图基于敌人当前与玩家的距离实时计算

#### 鼠标点击操作
- **点击相邻空格子** → 玩家移动到该格子（绿色高亮提示）
- **点击相邻敌人格子** → 玩家攻击该敌人（红色高亮提示）
- 非相邻格子点击无效（暗色高亮提示）
- 悬停时自动变色反馈可操作性

#### UI按钮
- **Attack 按钮** — 点击执行面朝方向攻击（等同 Space 键）
- **Skip 按钮** — 点击跳过回合（等同 S 键）
- 按钮在非玩家回合自动变灰禁用

### 当前完整操作方式
| 操作 | 键盘 | 鼠标 |
|------|------|------|
| 左移 | A / 左方向键 | 点击左边相邻空格子 |
| 右移 | D / 右方向键 | 点击右边相邻空格子 |
| 攻击 | Space / Enter | 点击相邻敌人 或 Attack按钮 |
| 跳过 | S | Skip按钮 |

### 接下来计划实现的功能（按优先级）
1. **战斗动画/视觉反馈** - 攻击闪烁、受伤抖动、移动平滑过渡
2. **技能系统框架** - 可配置的攻击/技能，替代当前的固定攻击
3. **更多敌人类型** - 不同 AI 行为模式（远程、冲锋、防御等）
4. **占位符像素素材** - 替换色块为简单像素画
5. **关卡/楼层系统** - 多场战斗的 Roguelike 流程
6. **奖励/升级界面** - 战斗间选择新技能

### 已知问题
- 格子悬停颜色在玩家移动后不会立即刷新（需要鼠标移动触发）
- 没有动画过渡，敌人行动是瞬间完成的
- Attack按钮只攻击面朝方向，如果面朝方向没有敌人则无效
- 没有音效和视觉特效

---

## 版本 0.1.0 - 项目骨架 (2026-03-31)

### 本次完成的工作

#### 项目配置
- `project.godot` - Godot 4.5 项目配置文件
  - 原生分辨率 384x216，窗口 1920x1080（5倍放大）
  - 像素风渲染设置（最近邻采样，无纹理过滤）
  - GL Compatibility 渲染器
  - 输入映射：A/D 移动，Space 攻击，S 跳过回合，方向键也可移动
  - GameManager 注册为全局 Autoload

#### 核心脚本
| 文件 | 作用 |
|------|------|
| `scripts/core/game_manager.gd` | 全局游戏管理器（Autoload），管理游戏状态、存档数据、场景切换 |
| `scripts/battle/turn_manager.gd` | 回合管理器，控制 玩家输入→玩家行动→敌人行动→结算 的流程 |
| `scripts/battle/grid.gd` | 1D 格子数据结构，管理实体位置、移动、碰撞检测 |
| `scripts/battle/entity.gd` | 实体基类，包含 HP、受伤、死亡等通用逻辑 |
| `scripts/battle/player.gd` | 玩家类，继承 entity，处理移动和基础攻击 |
| `scripts/battle/enemy_base.gd` | 敌人基类，继承 entity，包含 AI 决策框架（靠近/攻击） |
| `scripts/battle/enemies/slime_enemy.gd` | 史莱姆敌人（测试用），2HP，每2回合行动 |
| `scripts/battle/battle_scene.gd` | 战斗场景控制器，协调所有战斗逻辑和 UI |
| `scripts/ui/main_menu.gd` | 主菜单脚本，处理开始按钮 |

#### 目录结构
```
shogun_project/
├── project.godot
├── icon.svg
├── scenes/
│   ├── main.tscn              # 主菜单
│   └── battle/
│       └── battle_scene.tscn  # 战斗场景
├── scripts/
│   ├── core/
│   │   └── game_manager.gd    # 全局管理器
│   ├── battle/
│   │   ├── turn_manager.gd    # 回合管理
│   │   ├── grid.gd            # 1D网格
│   │   ├── entity.gd          # 实体基类
│   │   ├── player.gd          # 玩家
│   │   ├── enemy_base.gd      # 敌人基类
│   │   ├── battle_scene.gd    # 战斗场景逻辑
│   │   └── enemies/
│   │       └── slime_enemy.gd # 史莱姆敌人
│   └── ui/
│       └── main_menu.gd       # 主菜单逻辑
├── resources/entities/         # (预留) 实体数据资源
├── assets/sprites/placeholder/ # (预留) 占位符素材
├── assets/ui/                  # (预留) UI素材
├── assets/audio/               # (预留) 音频素材
└── devlog.md                   # 本文件
```
