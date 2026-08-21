# WorkBuddy Daily Check-in

一个仅面向 macOS 的本地自动化：在指定时间唤起 WorkBuddy，依次点击左下角账号头像、“Buddy 加油站”和“立即领取”。

## 特性

- 不保存账号、密码、Cookie 或 token，复用 WorkBuddy 已登录的客户端状态。
- 时间可配置；默认每天 `00:30`。
- 使用 macOS 原生 `launchd`，由 `cliclick` 发送底层鼠标点击，避免 Electron 无障碍控件树卡死。
- 点击位置以 WorkBuddy 当前窗口左上角和尺寸为基准计算；正常桌面布局下无需固定窗口坐标。
- 点击后会截取加油站卡片，确认按钮由深色“立即领取”切换为浅灰“今日已领”完成态；未确认时任务以失败状态退出，并保留验证截图。

## 前提

1. 安装并登录 WorkBuddy。
2. 安装 `cliclick`：`brew install cliclick`。
3. 在 macOS「系统设置 → 隐私与安全性 → 辅助功能」中，允许 `/usr/bin/osascript` 和 `cliclick` 控制电脑。
4. 安装 Python 3（例如 `brew install python`），用于验证领取完成态。
5. 使用 WorkBuddy 的正常桌面布局；任务触发时 Mac 必须开机且已登录。

默认从 `/Applications/WorkBuddy.app` 启动客户端；若你的安装位置不同，可在运行前设置 `WORKBUDDY_APP_PATH`。例如：

```sh
WORKBUDDY_APP_PATH="/路径/WorkBuddy.app" ./scripts/run-checkin.sh
```

## 安装

```sh
./scripts/install.sh
```

指定时间，例如每天 09:05：

```sh
./scripts/install.sh --hour 9 --minute 5
```

安装器会从 `com.workbuddy.daily-checkin.plist.template` 生成用户级 LaunchAgent，并加载到 `~/Library/LaunchAgents/`。日志会写到项目目录的 `workbuddy-checkin.log`。

## 卸载

```sh
./scripts/uninstall.sh
```

## 排障

如果日志中出现 `not allowed assistive access`、`不允许辅助访问` 或点击没有生效，请在 macOS「系统设置 → 隐私与安全性 → 辅助功能」中点击 `+`，添加并启用 `/usr/bin/osascript` 和 `/opt/homebrew/opt/cliclick/bin/cliclick`。前者读取窗口位置，后者发送鼠标点击。

如果日志中出现 `Unable to find application`、`kLSNoExecutableErr` 或 `macOS could not launch WorkBuddy`，说明 WorkBuddy 的 macOS 应用登记或安装包已损坏。请从官方来源重装 WorkBuddy，并手动打开一次；脚本不会直接启动包内的 Electron 可执行文件，以免导致客户端崩溃。

授予权限后，可立即验证已安装任务：

```sh
launchctl kickstart -k "gui/$(id -u)/com.workbuddy.daily-checkin"
```

然后查看项目目录中的 `workbuddy-checkin.log` 和任务退出码：

```sh
launchctl print "gui/$(id -u)/com.workbuddy.daily-checkin"
```

## 开发与迭代

- 修改 `workbuddy-checkin.applescript` 或 `scripts/run-checkin.sh` 后，执行 `./scripts/validate.sh` 和 `sh -n scripts/run-checkin.sh` 做语法检查。
- 修改调度模板或安装脚本后，重新运行 `./scripts/install.sh` 以更新已加载的任务。
- `CHANGELOG.md` 记录发布变化；提交前请不要提交日志、用户目录或已安装的 LaunchAgent 副本。

## 注意

这是个人桌面自动化示例，并非 WorkBuddy 官方工具。使用者应自行遵守 WorkBuddy 的服务条款、积分规则及当地法律；若界面布局发生变化，需要调整 `scripts/run-checkin.sh` 中的点击偏移量。
