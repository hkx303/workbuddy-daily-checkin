# WorkBuddy Daily Check-in

一个仅面向 macOS 的本地自动化：每天定时打开 WorkBuddy，依次点击左下角账号头像、“Buddy 加油站”和“立即领取”，并在完成后验证按钮已变为“今日已领”。

> 这不是 WorkBuddy 官方工具；请自行遵守其服务条款、积分规则和当地法律。

## 它会做什么

默认每天 `00:30`，用户级 `launchd` 会运行一次脚本：

1. 若 WorkBuddy 尚未运行，尝试启动 `/Applications/WorkBuddy.app`。
2. 等待 WorkBuddy 主窗口出现，并读取窗口位置与大小。
3. 用 `cliclick` 按相对坐标执行：账号头像 → Buddy 加油站 → 立即领取。
4. 等待界面刷新，读取领取按钮中心的 RGB 颜色。
5. 校验按钮是否已从深色的“立即领取”切换为浅灰完成态“今日已领”。

只有第 5 步验证通过，任务才会以成功状态结束。

## 特性与边界

- 不保存账号、密码、Cookie 或 token，直接复用已登录的 WorkBuddy 客户端。
- 使用 macOS 原生 `launchd`，不需要常驻的第三方守护进程。
- 使用 `cliclick` 的底层点击和取色能力，规避 Electron 无障碍控件树偶发卡死，也不依赖 LaunchAgent 难以获取的屏幕录制权限。
- 点击位置会随 WorkBuddy 窗口移动而调整；它针对当前常规桌面布局和默认窗口尺寸校准。
- 如果 WorkBuddy 改版、缩放界面或改变卡片位置，需要修改 `scripts/run-checkin.sh` 中的偏移量并重新验证。

## 前提

1. macOS，且已安装、登录 WorkBuddy。
2. Homebrew 和 `cliclick`：

   ```sh
   brew install cliclick
   ```

3. 在「系统设置 → 隐私与安全性 → 辅助功能」中，添加并启用：

   - `/usr/bin/osascript`：读取 WorkBuddy 窗口位置；
   - `/opt/homebrew/opt/cliclick/bin/cliclick`：发送鼠标点击。

4. 任务触发时 Mac 必须开机且已经登录。`launchd` 不会在关机期间补跑错过的签到。

默认应用路径为 `/Applications/WorkBuddy.app`。手动运行时可临时指定其他位置：

```sh
WORKBUDDY_APP_PATH="/路径/WorkBuddy.app" ./scripts/run-checkin.sh
```

> 定时任务不继承这条临时环境变量。若要让其他安装路径也能定时运行，请在 `scripts/run-checkin.sh` 中修改默认路径后重新安装任务。

## 安装与定时

克隆仓库后，在项目目录执行：

```sh
./scripts/install.sh
```

这会生成并加载用户级 LaunchAgent：

```text
~/Library/LaunchAgents/com.workbuddy.daily-checkin.plist
```

默认每天 `00:30` 运行。要改为每天 `09:05`：

```sh
./scripts/install.sh --hour 9 --minute 5
```

每次改动调度时间、模板或安装脚本后，都要重新运行安装命令，使已加载的 LaunchAgent 更新。

## 手动运行与验证

先直接运行一次，确认权限、窗口布局和验证流程均正常：

```sh
./scripts/run-checkin.sh
```

成功时会看到类似输出：

```text
VERIFIED: WorkBuddy claim button is in the completed (今日已领) state.
SUCCESS: claim flow completed and verified.
```

也可立即触发已安装的定时任务：

```sh
launchctl kickstart -k "gui/$(id -u)/com.workbuddy.daily-checkin"
```

日志位于项目目录：

```text
workbuddy-checkin.log
```

查看任务当前状态：

```sh
launchctl print "gui/$(id -u)/com.workbuddy.daily-checkin"
```

## 排障

| 现象 | 处理方式 |
| --- | --- |
| `not allowed assistive access` / `不允许辅助访问` | 检查辅助功能中是否已启用 `osascript` 和 `cliclick`。 |
| 日志显示 `WorkBuddy claim button is still in the unclaimed state` | 确认窗口未缩放、卡片仍为当前紧凑布局，以及当天确实仍可领取；必要时调整 `scripts/run-checkin.sh` 的领取按钮横向偏移量。 |
| `WorkBuddy window did not become available` | 检查 WorkBuddy 是否能正常打开、是否被登录弹窗挡住，以及 Mac 是否处于已登录状态。 |
| `macOS could not launch WorkBuddy`、`kLSNoExecutableErr` | WorkBuddy 的安装或 macOS 应用登记可能异常。请从官方来源重装，并手动启动一次客户端。 |

## 卸载

```sh
./scripts/uninstall.sh
```

卸载只会移除 LaunchAgent，不会删除项目、日志或验证截图。

## 开发

提交前执行：

```sh
./scripts/validate.sh
sh -n scripts/run-checkin.sh
```

- `workbuddy-checkin.applescript`：选择 WorkBuddy 的可见主窗口并返回坐标。
- `scripts/run-checkin.sh`：启动、点击、取色验证编排。
- `com.workbuddy.daily-checkin.plist.template`：`launchd` 调度模板。

不要提交日志、用户目录文件或已安装的 LaunchAgent 副本。
