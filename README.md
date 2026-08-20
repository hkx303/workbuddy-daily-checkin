# WorkBuddy Daily Check-in

一个仅面向 macOS 的本地自动化：在指定时间唤起 WorkBuddy，依次打开左下角账号菜单和“Buddy 加油站”，再点击已启用的“领取”或“签到”按钮。

## 特性

- 不保存账号、密码、Cookie 或 token，复用 WorkBuddy 已登录的客户端状态。
- 已签到或找不到按钮时安全退出，不会重复点击。
- 时间可配置；默认每天 `00:30`。
- 使用 macOS 原生 `launchd`，无需安装第三方依赖。
- 单次运行最长 75 秒；客户端无响应时会安全终止，避免后台进程悬挂。

## 前提

1. 安装并登录 WorkBuddy。
2. 在 macOS「系统设置 → 隐私与安全性 → 辅助功能」中，允许 `/usr/bin/osascript` 控制电脑。
3. 任务触发时 Mac 必须开机且已登录。

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

如果日志中出现 `osascript 不允许辅助访问 (-1719)`，请在 macOS「系统设置 → 隐私与安全性 → 辅助功能」中点击 `+`，添加并启用 `/usr/bin/osascript`。这是脚本读取并点击 WorkBuddy 界面所必需的系统权限。

授予权限后，可立即验证已安装任务：

```sh
launchctl kickstart -k "gui/$(id -u)/com.workbuddy.daily-checkin"
```

然后查看项目目录中的 `workbuddy-checkin.log` 和任务退出码：

```sh
launchctl print "gui/$(id -u)/com.workbuddy.daily-checkin"
```

## 开发与迭代

- 修改 `workbuddy-checkin.applescript` 后可直接执行 `./scripts/validate.sh` 做语法检查。
- 修改调度模板或安装脚本后，重新运行 `./scripts/install.sh` 以更新已加载的任务。
- `CHANGELOG.md` 记录发布变化；提交前请不要提交日志、用户目录或已安装的 LaunchAgent 副本。

## 注意

这是个人桌面自动化示例，并非 WorkBuddy 官方工具。使用者应自行遵守 WorkBuddy 的服务条款、积分规则及当地法律；界面文案变更可能需要调整按钮匹配规则。
