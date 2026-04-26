---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from the current workspace or before implementing approved specs
---

# 使用 Git Worktree

## 概览

Git worktree 会在共享同一个仓库的前提下创建隔离工作区，让任务分支能在独立目录中完成实现、验证和清理。

**核心原则：** 仓库根目录下的 `.worktrees/` + 每个任务 worktree 对应一个任务分支 + 已批准变更集成回 `controller` 开发分支 + 集成后立即清理 = 可靠隔离。

**开始时要明确说明：** “我正在使用 `using-git-worktrees` skill 来建立隔离工作区。”

## 单一事实来源

这个 skill 是所有 skills 关于任务 worktree 规则的单一事实来源。

它负责：
- 检测 `controller` 开发分支
- 为调用方指定的会改代码任务创建一个任务分支和一个任务 worktree
- 在任务被集成或显式重置前，为该任务稳定保留同一个任务 worktree
- 已批准变更集成回 `controller` 开发分支的 worktree/分支机制
- 集成后立即清理任务 worktree

其他 skill 应引用这个 skill，而不是重复描述 worktree 机制。

## 固定目录规则（强制）

- 始终在仓库根目录的 `.worktrees/` 下创建任务 worktree。
- 不要使用 `worktrees/`、`~/.config/superpowers/worktrees/` 或任何其他位置。
- 如果 `.worktrees/` 不存在，先在仓库根目录创建，再创建任务 worktree。
- 记录工作流开始时检出的那个分支。这个 `controller` 开发分支是本轮中所有任务分支的统一集成目标。
- 每个由调用工作流分配的、会改代码的任务，必须且只能有一个任务分支，以及一个对应的 `.worktrees/<task-branch>` 目录。
- 在任务被集成或显式重置前，始终为该任务保留同一个任务分支和任务 worktree，包括实现、review 修复、checkbox 更新和 re-review 阶段。
- 任务 worktree 只能由该任务的当前负责人写入。
- 共享协调文件必须保留在 `controller` 开发分支工作区中。
- 如果无法建立隔离任务 worktree，就停下并先解决这个阻塞；不要降级到非隔离执行。

## 安全校验

**在创建任何任务 worktree 前，必须先确认 `.worktrees/` 被忽略：**

```bash
git check-ignore -q .worktrees
```

**如果没有被忽略：**

1. 把 `.worktrees/` 加入 `.gitignore`
2. 提交这个改动
3. 然后再继续创建任务 worktree

**为什么这很关键：** 这样能避免误把任务 worktree 的内容提交进仓库。

## 创建步骤

### 1. 检测仓库根目录和 `controller` 开发分支

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
CONTROLLER_BRANCH=$(git branch --show-current)
```

**如果 `CONTROLLER_BRANCH` 为空：** 停下来，先问你的 human partner 这个 detached HEAD 该怎么处理，再创建任务分支。

### 2. 确保仓库根目录下存在 `.worktrees/`

```bash
mkdir -p "$REPO_ROOT/.worktrees"
git check-ignore -q .worktrees
```

### 3. 创建任务 Worktree 和任务分支

```bash
TASK_BRANCH="$BRANCH_NAME"
TASK_PATH="$REPO_ROOT/.worktrees/$TASK_BRANCH"

# 从 controller 开发分支创建新分支，并建立 worktree
git worktree add "$TASK_PATH" -b "$TASK_BRANCH" "$CONTROLLER_BRANCH"
cd "$TASK_PATH"
```

### 4. 运行项目初始化

自动识别并执行合适的初始化步骤：

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
# 如果 controller 工作区使用本地 .venv，就在 task worktree 中也创建一个
if [ -d "$REPO_ROOT/.venv" ] && [ ! -d .venv ]; then python3 -m venv .venv; fi
# 如果 task worktree 中存在 .venv，后续 Python 初始化步骤都在这个 venv 中执行
if [ -d .venv ]; then . .venv/bin/activate; fi
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

### 5. 验证干净基线

运行测试，确保任务 worktree 的起点是干净的：

```bash
# 示例：使用项目对应的测试命令
npm test
cargo test
pytest
go test ./...
```

**如果测试失败：** 报告失败，并询问要继续还是先调查。

**如果测试通过：** 报告已就绪。

### 6. 报告位置

```
任务 worktree 已就绪：<repo-root>/.worktrees/<task-branch>
任务分支 <task-branch> 已从 <controller-branch> 创建
测试通过（<N> tests, 0 failures）
可以开始实现 <feature-name>
```

## 任务完成后的清理

当最终 review 通过，且 `controller` 已将任务分支集成回 `controller` 开发分支后：

```bash
git -C "$REPO_ROOT" worktree remove "$TASK_PATH"
git -C "$REPO_ROOT" branch -d "$TASK_BRANCH"
```

`Controller` 应在集成完成后立刻清理。不要把已完成的任务 worktree 留在本地。

如果恢复一个已有的 session，且任务 worktree 已经存在：
- 如果任务还没完成，且状态与追踪进度一致，就复用它。
- 如果任务已经集成完成，就立刻删掉它。

## 范围边界

这个 skill 负责：任务 worktree 创建、按任务隔离分支、已批准变更回到 `controller` 开发分支的 worktree/分支机制，以及集成后的清理。

它**不负责**决定任务完成 commit 的内容或归属；这些由调用它的工作流定义。

它**不负责**决定 review 何时发生、reviewer 是否复用，或任务 review/fix/re-review 循环如何运行。

它**不负责**在所有任务 worktree 都清理完之后，`controller` 开发分支接下来该怎么处理。

当任务 worktree 全部清理完后，把控制权还给调用它的工作流，让对方决定 `controller` 开发分支接下来怎么处理。

## 快速参考

| 情况 | 动作 |
|------|------|
| `.worktrees/` 不存在 | 在仓库根目录创建它 |
| `.worktrees/` 已存在 | 先验证它被忽略，再使用 |
| `.worktrees/` 没被忽略 | 把 `.worktrees/` 加进 `.gitignore` 并提交 |
| 找不到 `controller` 开发分支 | 停下并询问 |
| 任务完成并已集成 | 删除任务 worktree，然后删除任务分支 |
| 恢复时发现已完成任务残留 worktree | 立即删除 |
| 没有任何任务 worktree 了 | 把 `controller` 分支决策交回调用方 |
| 基线测试失败 | 报告失败并询问 |
| 没有 `package.json` / `Cargo.toml` | 跳过依赖安装 |

## 常见错误

### 跳过忽略校验

- **问题：** 任务 worktree 内容会被 git 跟踪，污染 `git status`
- **修正：** 在创建任何任务 worktree 前，始终执行 `git check-ignore -q .worktrees`

### 用错目录

- **问题：** 造成不一致，破坏清理预期
- **修正：** 始终使用仓库根目录的 `.worktrees/`

### 忘记 `controller` 开发分支

- **问题：** 任务分支会逐渐分叉，失去统一集成目标
- **修正：** 一开始记录好起始分支，并从它创建所有任务分支

### 共享同一个任务 worktree

- **问题：** agent 会互相干扰、覆盖改动，让集成归属变得模糊
- **修正：** 每个由调用工作流分配的、会改代码的任务都应拥有自己的任务 worktree

### 把 review 修复移到另一个 worktree

- **问题：** 会打破任务归属，混淆状态，让 re-review 失去明确对象
- **修正：** 在任务被集成或显式重置前，始终在同一个已分配的任务 worktree 中修复 review 问题

### 已完成任务的 worktree 不清理

- **问题：** 空闲 worktree 会不断堆积，混淆状态并浪费资源
- **修正：** 一旦任务集成完成，立刻删除任务 worktree 并删除任务分支

### 在测试失败的情况下继续推进

- **问题：** 无法区分新引入的 bug 和历史遗留问题
- **修正：** 先报告失败，并取得明确许可后再继续

### 用这个 skill 来决定最终分支命运

- **问题：** 把任务 worktree 机制、任务完成 commit 归属和 `controller` 分支工作流决策混在一起
- **修正：** 本 skill 只约束 worktree/分支机制；任务完成 commit 和后续分支处置交还调用工作流

### 硬编码初始化命令

- **问题：** 换了项目工具链就会失效
- **修正：** 根据项目文件自动识别（如 `package.json`）

## 工作流示例

```
You: 我正在使用 `using-git-worktrees` skill 来建立隔离工作区。

[记录 controller 开发分支：feature/auth]
[如果需要，在仓库根目录创建 .worktrees/]
[验证忽略状态 - git check-ignore 确认 .worktrees/ 已被忽略]
[创建 worktree: git worktree add /repo/.worktrees/task-auth -b task-auth feature/auth]
[运行 npm install]
[运行 npm test - 47 passing]

任务 worktree 已就绪：/Users/jesse/myproject/.worktrees/task-auth
任务分支 task-auth 已从 feature/auth 创建
测试通过（47 tests, 0 failures）
可以开始实现 auth feature
```

## Red Flags

**绝不要：**
- 在仓库根目录 `.worktrees/` 之外创建任务 worktree
- 没验证 `.worktrees/` 已被忽略，就创建任务 worktree
- 跳过基线测试验证
- 在测试失败时不经询问就继续
- 忘记哪个分支是 `controller` 开发分支
- 让无关负责人写入同一个任务 worktree
- 任务集成后还把已完成的任务 worktree 留着不删
- 用这个 skill 来决定 `controller` 开发分支的最终命运

**始终要：**
- 使用仓库根目录的 `.worktrees/`
- 验证 `.worktrees/` 已被忽略
- 从 `controller` 开发分支创建每个任务分支
- 给每个由调用工作流分配的、会改代码的任务分配一个任务 worktree
- 按调用工作流要求，把每个完成任务的已批准变更集成回 `controller` 开发分支
- 在集成后立即删除任务 worktree
- 在任务 worktree 删除后删除任务分支
- 自动识别并运行项目初始化
- 验证一条干净的测试基线

## 集成关系

**被以下工作流调用：**
- **subagent-driven-development** - 在执行会改代码的任务前必须使用；该 skill 负责这些隔离任务 worktree 上的 review/fix/re-review 编排
- 任何需要隔离任务 worktree 的工作流
