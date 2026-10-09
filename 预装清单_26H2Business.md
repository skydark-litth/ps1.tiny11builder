# Windows 11 Business 26H2（zh-cn, x64）预装清单（全量：应用 / 驱动 / 字体 / 组件）

> **数据来源**：直接从 `zh-cn_windows_11_business_editions_version_26h2_x64_dvd_74d48a06.iso` 的 `sources\install.wim`（映像 3 = 专业版，与脚本构建所用索引一致）逐文件列取，非推测。分类与评分规则与 `tiny11builder.ps1` 当前实现一致；无法从 INF/字体名可靠判断用途的条目，已在说明中标注「按名称推断」。
>
> **评分**：1 = 完全没必要保留，10 = 必须保留（面向普通桌面用户）。**排序**：已精简在前、未精简在后。**三种模式** = 一般模式 / 激进模式（移除 Edge） / 激进模式（保留 Edge）；Appx 与 OneDrive 等三种模式均移除；驱动与字体裁剪仅激进模式且仅「制作 ISO」分支执行；WinRE 全模式保留。

## 一、Appx 应用（60 个包名 / 185 个包目录）

### 1.1 已精简（26 个）——被精简的模式：三种模式均移除

| 包名 | 包目录数 | 功能 | 评分 | 说明 |
|------|:---:|------|:---:|------|
| `Clipchamp.Clipchamp` | 5 | Clipchamp 视频编辑器 | 1 | 在线视频编辑器套壳，依赖联网与微软账号 |
| `MSTeams` | 1 | Teams 消费版残留包 | 1 | 个人版 Teams |
| `Microsoft.BingNews` | 5 | 必应资讯 | 1 | 新闻聚合，含推荐流 |
| `Microsoft.BingSearch` | 5 | 必应搜索 | 1 | Bing 搜索客户端壳 |
| `Microsoft.BingWeather` | 5 | 必应天气 | 2 | 天气预报 |
| `Microsoft.GamingApp` | 3 | Xbox 游戏应用（Game Pass 入口） | 2 | Game Pass 用户建议自装 |
| `Microsoft.GetHelp` | 5 | 获取帮助（微软支持工单） | 1 | 联系微软客服 |
| `Microsoft.MicrosoftOfficeHub` | 6 | Office 中心 | 1 | Office 门户与订阅推广 |
| `Microsoft.MicrosoftSolitaireCollection` | 4 | 微软纸牌合集 | 2 | 含广告与内购 |
| `Microsoft.MicrosoftStickyNotes` | 5 | 便笺 | 5 | 实用便签，支持同步 |
| `Microsoft.OutlookForWindows` | 1 | 新版 Outlook（邮件/日历） | 2 | 重度邮件用户可自装 |
| `Microsoft.PowerAutomateDesktop` | 6 | Power Automate Desktop | 3 | 桌面 RPA 自动化 |
| `Microsoft.StorePurchaseApp` | 2 | Store 购买应用 | 2 | 随 Store 一并移除 |
| `Microsoft.Todos` | 5 | 微软待办 | 3 | 任务/清单管理 |
| `Microsoft.Windows.DevHome` | 5 | Dev Home | 1 | 开发者仪表盘，微软已弃用 |
| `Microsoft.WindowsAlarms` | 5 | 时钟（闹钟/计时器） | 4 | 闹钟、世界时钟 |
| `Microsoft.WindowsCamera` | 5 | 相机 | 1 | 摄像头驱动已裁剪，本就不可用 |
| `Microsoft.WindowsFeedbackHub` | 3 | 反馈中心 | 1 | 向微软提交反馈 |
| `Microsoft.WindowsStore` | 2 | Microsoft Store | 5 | 按需求移除；删后 UWP 应用走 winget/官网安装包 |
| `Microsoft.Xbox.TCUI` | 3 | Xbox 界面组件 | 4 | 部分游戏登录/成就依赖；不玩游戏可删 |
| `Microsoft.XboxGamingOverlay` | 5 | Xbox Game Bar | 4 | 录屏/性能叠加；有录屏需求建议保留 |
| `Microsoft.XboxIdentityProvider` | 5 | Xbox 身份提供程序 | 3 | Xbox Live 登录支持 |
| `Microsoft.XboxSpeechToTextOverlay` | 4 | Xbox 语音转文字 | 1 | 游戏语音字幕 |
| `Microsoft.YourPhone` | 5 | 手机连接（Phone Link） | 4 | 短信/通话/照片投屏 |
| `Microsoft.ZuneMusic` | 5 | 媒体播放器（音乐） | 2 | 本地/流媒体音乐 |
| `MicrosoftCorporationII.QuickAssist` | 5 | 快速助手（远程协助） | 4 | 远程协助会话 |

### 1.2 未精简（34 个）——被精简的模式：未精简

| 包名 | 包目录数 | 功能 | 评分 | 说明 |
|------|:---:|------|:---:|------|
| `Deleted` | 1 | 系统依赖/按需组件 | 6 | 未列入精简清单，保留现状 |
| `Merged` | 1 | 系统依赖/按需组件 | 6 | 未列入精简清单，保留现状 |
| `Microsoft.AV1VideoExtension` | 2 | AV1 视频编解码扩展 | 7 | 播放 AV1 视频需要 |
| `Microsoft.AVCEncoderVideoExtension` | 2 | AVC(H.264) 编码扩展 | 6 | 视频录制编码 |
| `Microsoft.ApplicationCompatibilityEnhancements` | 2 | 应用兼容性增强 | 7 | 老应用兼容补丁组件 |
| `Microsoft.DesktopAppInstaller` | 2 | 应用安装器（App Installer / winget） | 9 | winget 与双击安装 appx/msix 的底层 |
| `Microsoft.HEIFImageExtension` | 2 | HEIF/HEIC 图片编解码扩展 | 7 | 查看 iPhone 照片需要 |
| `Microsoft.HEVCVideoExtension` | 2 | HEVC(H.265) 视频扩展 | 6 | 播放 H.265 视频需要（收费项） |
| `Microsoft.MPEG2VideoExtension` | 2 | MPEG-2 视频扩展 | 5 | 播放 MPEG-2 视频 |
| `Microsoft.NET.Native.Framework.2.2` | 1 | .NET Native Framework 2.2（UWP） | 8 | UWP 应用依赖 |
| `Microsoft.NET.Native.Runtime.2.2` | 1 | .NET Native Runtime 2.2（UWP） | 8 | UWP 应用依赖 |
| `Microsoft.Paint` | 5 | 画图（新版） | 6 | 基础图片编辑 |
| `Microsoft.RawImageExtension` | 2 | 相机 RAW 格式扩展 | 6 | 单反/微单 RAW 预览 |
| `Microsoft.ScreenSketch` | 5 | 截图和草图（截图工具） | 8 | Win+Shift+S 截图依赖 |
| `Microsoft.SecHealthUI` | 1 | Windows 安全中心现代 UI | 9 | 安全中心界面本体 |
| `Microsoft.UI.Xaml.2.8` | 1 | WinUI 2.8 框架库 | 8 | 系统组件依赖 |
| `Microsoft.VCLibs.140.00.UWPDesktop` | 1 | Visual C++ 2013 UWP Desktop 运行库 | 8 | 桌面桥应用依赖 |
| `Microsoft.VCLibs.140.00` | 1 | Visual C++ 2013 UWP 运行库 | 8 | UWP 应用依赖 |
| `Microsoft.VP9VideoExtensions` | 2 | VP9 视频扩展 | 6 | 网页 VP9 视频 |
| `Microsoft.WebMediaExtensions` | 2 | Web 媒体扩展 | 6 | WebM/OGG 播放 |
| `Microsoft.WebpImageExtension` | 2 | WebP 图片扩展 | 7 | 网页常见格式 |
| `Microsoft.Windows.Photos` | 5 | 照片 | 7 | 看图工具（无替代时需要） |
| `Microsoft.WindowsAppRuntime.1.6` | 1 | Windows App SDK 运行时 1.6 | 8 | 新版应用依赖 |
| `Microsoft.WindowsAppRuntime.1.8` | 1 | Windows App SDK 运行时 1.8 | 8 | 新版应用依赖 |
| `Microsoft.WindowsAppRuntime.2` | 1 | Windows App SDK 运行时 2 | 8 | 新版应用依赖 |
| `Microsoft.WindowsCalculator` | 5 | 计算器 | 8 | 实用工具 |
| `Microsoft.WindowsNotepad` | 5 | 记事本（新版） | 8 | 基础文本编辑 |
| `Microsoft.WindowsSoundRecorder` | 5 | 录音机 | 5 | 录音 |
| `Microsoft.WindowsTerminal` | 2 | Windows Terminal | 7 | 现代终端 |
| `MicrosoftWindows.Client.WebExperience` | 2 | Windows 网络体验包（含 Outlook 日历/小组件托架） | 6 | 任务栏小组件依赖 |
| `MicrosoftWindows.CrossDevice` | 5 | 跨设备体验主机 | 4 | 手机互联底层 |
| `Mutable` | 1 | 系统依赖/按需组件 | 6 | 未列入精简清单，保留现状 |
| `MutableBackup` | 1 | 系统依赖/按需组件 | 6 | 未列入精简清单，保留现状 |
| `Projected` | 1 | 系统依赖/按需组件 | 6 | 未列入精简清单，保留现状 |

## 二、驱动（DriverStore\FileRepository：717 个组件目录，按 INF 归并 715 项）

### 2.1 已精简（15 项）——被精简的模式：仅激进模式，且仅「制作 ISO」

| INF | 目录数 | 功能 | 评分 | 说明 |
|------|:---:|------|:---:|------|
| `prnge001.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `prnms002.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `prnms003.inf` | 2 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `prnms004.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `prnms005.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `prnms007.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `prnms008.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `prnms010.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `prnms011.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `prnms012.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `prnms013.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `prnms014.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `prnms015.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `usbprint.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `usbvideo.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |

### 2.2 未精简（700 项）——被精简的模式：未精简

| INF | 目录数 | 功能 | 评分 | 说明 |
|------|:---:|------|:---:|------|
| `1394.inf` | 1 | IEEE 1394（火线） | 2 | 老式 DV/外置盘接口 |
| `3ware.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `61883.inf` | 1 | IEEE 1394（火线） | 2 | 老式 DV/外置盘接口 |
| `acpi.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `acpiaudiocompositor.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `acpidev.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `acpipagr.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `acpipmi.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `acpitime.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `acxhdaudiop.inf` | 1 | 音频 | 8 | 声音输出/录制 |
| `adp80xx.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `amdgpio2.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `amdi2c.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `amdsata.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `amdsbs.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `amdwps.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `applessd.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `apxunit.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `arcsas.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `athw8x.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `audioendpoint.inf` | 1 | 音频 | 8 | 声音输出/录制 |
| `avc.inf` | 1 | IEEE 1394（火线） | 2 | 老式 DV/外置盘接口 |
| `b57nd60a.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `basicdisplay.inf` | 1 | 显示适配器/监视器 | 8 | 显示输出；虚拟机里为基础显示 |
| `basicrender.inf` | 1 | 显示适配器/监视器 | 8 | 显示输出；虚拟机里为基础显示 |
| `battery.inf` | 1 | 电源/电池/温控 | 8 | 供电与温度管理 |
| `bcmdhd64.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `bcmfn2.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `bcmwdidhdpcie.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `bda.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `btampm.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `bth.inf` | 1 | 蓝牙 | 7 | 蓝牙无线连接 |
| `bthlcpen.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `bthleenum.inf` | 1 | 蓝牙 | 7 | 蓝牙无线连接 |
| `bthmtpenum.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `bthoob.inf` | 1 | 蓝牙 | 7 | 蓝牙无线连接 |
| `bthpan.inf` | 1 | 蓝牙 | 7 | 蓝牙无线连接 |
| `bthprint.inf` | 1 | 蓝牙 | 7 | 蓝牙无线连接 |
| `bthspp.inf` | 1 | 蓝牙 | 7 | 蓝牙无线连接 |
| `buttonconverter.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_1394.inf` | 1 | IEEE 1394（火线） | 2 | 老式 DV/外置盘接口 |
| `c_61883.inf` | 1 | IEEE 1394（火线） | 2 | 老式 DV/外置盘接口 |
| `c_apo.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_avc.inf` | 1 | IEEE 1394（火线） | 2 | 老式 DV/外置盘接口 |
| `c_barcodescanner.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_battery.inf` | 1 | 电源/电池/温控 | 8 | 供电与温度管理 |
| `c_biometric.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_bluetooth.inf` | 1 | 蓝牙 | 7 | 蓝牙无线连接 |
| `c_camera.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_cashdrawer.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_cdrom.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_computeaccelerator.inf` | 1 | 传感器 | 6 | 加速度计/光线传感器 |
| `c_computer.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_diskdrive.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_display.inf` | 1 | 显示适配器/监视器 | 8 | 显示输出；虚拟机里为基础显示 |
| `c_dot4.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_dot4print.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_extension.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_fdc.inf` | 1 | 软盘 | 2 | 软盘控制器 |
| `c_firmware.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_floppydisk.inf` | 1 | 软盘 | 2 | 软盘控制器 |
| `c_fsactivitymonitor.inf` | 1 | 显示适配器/监视器 | 8 | 显示输出；虚拟机里为基础显示 |
| `c_fsantivirus.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_fscfsmetadataserver.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_fscompression.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_fscontentscreener.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_fscontinuousbackup.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `c_fscopyprotection.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_fsencryption.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_fshsm.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_fsinfrastructure.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_fsopenfilebackup.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `c_fsphysicalquotamgmt.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_fsquotamgmt.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_fsreplication.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_fssecurityenhancer.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_fssystem.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_fssystemrecovery.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_fsundelete.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_fsvirtualization.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_generic.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_hdc.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_hidclass.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `c_i3c.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_image.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_infrared.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_keyboard.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `c_legacydriver.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_linedisplay.inf` | 1 | 显示适配器/监视器 | 8 | 显示输出；虚拟机里为基础显示 |
| `c_magneticstripereader.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_mcx.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_media.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_mediumchanger.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_memory.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_midi.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_modem.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `c_monitor.inf` | 1 | 显示适配器/监视器 | 8 | 显示输出；虚拟机里为基础显示 |
| `c_mouse.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `c_mtd.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_multifunction.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_multiportserial.inf` | 1 | 并口/串口 | 5 | 老式外设接口 |
| `c_net.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_netclient.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_netdriver.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_netservice.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_nettrans.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_nvmedisk.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `c_pcmcia.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `c_pnpprinters.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_ports.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_primitive.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_printer.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_processor.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_proximity.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_ramdisk.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_receiptprinter.inf` | 1 | 便携设备（MTP/PTP） | 7 | USB 连手机传文件，按需求保留 |
| `c_sbp2.inf` | 1 | IEEE 1394（火线） | 2 | 老式 DV/外置盘接口 |
| `c_scmdisk.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_scmvolume.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `c_scsiadapter.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_sdhost.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_securitydevices.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_sensor.inf` | 1 | 传感器 | 6 | 加速度计/光线传感器 |
| `c_smartcard.inf` | 1 | 智能卡 | 5 | 读卡器/智能卡 |
| `c_smartcardfilter.inf` | 1 | 智能卡 | 5 | 读卡器/智能卡 |
| `c_smartcardreader.inf` | 1 | 智能卡 | 5 | 读卡器/智能卡 |
| `c_smrdisk.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_smrvolume.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `c_sslaccel.inf` | 1 | 传感器 | 6 | 加速度计/光线传感器 |
| `c_swcomponent.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_swdevice.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_system.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_tapedrive.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_thermal.inf` | 1 | 电源/电池/温控 | 8 | 供电与温度管理 |
| `c_ucm.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_unknown.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `c_usb.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `c_usbdevice.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `c_usbfn.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `c_volsnap.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `c_volume.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `c_wceusbs.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `c_wpd.inf` | 1 | 便携设备（MTP/PTP） | 7 | USB 连手机传文件，按需求保留 |
| `cdrom.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `chargearbitration.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `cht4nulx64.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `cht4sx64.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `cht4vx64.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `circlass.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `cmbatt.inf` | 1 | 电源/电池/温控 | 8 | 供电与温度管理 |
| `compdev.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `compositebus.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `cpu.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `dc1-controller.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `dc21x4vm.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `devmap.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `digitalmediadevice.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `disk.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `display.inf` | 1 | 显示适配器/监视器 | 8 | 显示输出；虚拟机里为基础显示 |
| `displaymux.inf` | 1 | 显示适配器/监视器 | 8 | 显示输出；虚拟机里为基础显示 |
| `displayoverride.inf` | 1 | 显示适配器/监视器 | 8 | 显示输出；虚拟机里为基础显示 |
| `e2xw10x64.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `eaphost.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `ehstorpwddrv.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `ehstortcgdrv.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `errdev.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `escl.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `eyegazeioctl.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `fdc.inf` | 1 | 软盘 | 2 | 软盘控制器 |
| `fidohid.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `flpydisk.inf` | 1 | 软盘 | 2 | 软盘控制器 |
| `fusionv2.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `gameport.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `genericusbfn.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `genpass.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `hal.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `halextintclpiodma.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `halextintcpsedma.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `halextpl080.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `hdaudbus.inf` | 1 | 音频 | 8 | 声音输出/录制 |
| `hdaudio.inf` | 1 | 音频 | 8 | 声音输出/录制 |
| `hdaudss.inf` | 1 | 音频 | 8 | 声音输出/录制 |
| `heat.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `helloface.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `hidbatt.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `hidbth.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `hidbthle.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `hidcfu.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `hiddigi.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `hidgamepad.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `hidi2c.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `hidi3c.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `hidinterrupt.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `hidir.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `hidirkbd.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `hidlamparray.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `hidscanner.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `hidserv.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `hidspi_km.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `hidtelephonydriver.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `hidvhf.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `hpsamd.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `hsp.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `hvservice.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `i3chost.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `iagpio.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `iai2c.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `ialpss2i_gpio2_bxt_p.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `ialpss2i_gpio2_cnl.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `ialpss2i_gpio2_glk.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `ialpss2i_gpio2_skl.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `ialpss2i_i2c_bxt_p.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `ialpss2i_i2c_cnl.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `ialpss2i_i2c_glk.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `ialpss2i_i2c_skl.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `ialpssi_gpio.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `ialpssi_i2c.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `iastorav.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `iastorv.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `idtsec.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `image.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `input.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `intelpep.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `intelpmax.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `intelpmt.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `ipmidrv.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `ipoib6x.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `iscsi.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `itsas35i.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `kdnic.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `kdnic_legacy.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `keyboard.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `ks.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `kscaptur.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `ksfilter.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `lltdio.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `lsi_sas.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `lsi_sas2i.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `lsi_sas3i.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `machine.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `mausbhost.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `mbtr8897w81x64.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `mchgr.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `mdm3com.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdm5674a.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmadc.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmagm64.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmags64.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmairte.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmaiwa.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmaiwa3.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmaiwa4.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmaiwa5.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmaiwat.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmar1.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmarch.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmarn.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmati.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmatm2k.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmaus.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmboca.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmbsb.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmbtmdm.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmbug3.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmbw561.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmc26a.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmcdp.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmcm28.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmcodex.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmcom1.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmcommu.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmcomp.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmcpq.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmcpq2.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmcpv.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmcrtix.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmcxhv6.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmcxpv6.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmdcm5.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmdcm6.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmdf56f.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmdgitn.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmdp2.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmdsi.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmdyna.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmeiger.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmelsa.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmeric.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmeric2.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmetech.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmfj2.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmgatew.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmgcs.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmgen.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmgl001.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmgl002.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmgl003.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmgl004.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmgl005.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmgl006.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmgl007.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmgl008.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmgl009.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmgl010.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmgsm.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmhaeu.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmhandy.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmhay2.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmhayes.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdminfot.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmiodat.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmirmdm.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmisdn.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmjf56e.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmke.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmkortx.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmlasat.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmlasno.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmlucnt.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmmc288.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmmcd.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmmcom.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmmct.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmmega.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmmetri.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmmhrtz.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmmhzel.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmminij.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmmod.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmmot64.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmmoto1.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmmotou.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmmts.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmneuhs.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmnis1u.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmnis2u.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmnis3t.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmnis5t.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmnokia.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmnova.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmntt1.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmnttd2.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmnttd6.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmnttme.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmnttp.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmnttp2.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmnttte.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmolic.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmomrn3.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmoptn.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmosi.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmpace.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmpenr.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `mdmpin.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmpn1.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmpp.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmpsion.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmracal.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmrock.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmrock3.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmrock4.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmrock5.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmsier.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmsii64.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmsmart.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmsonyu.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmsun1.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmsun2.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmsupr3.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmsupra.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmsuprv.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmtdk.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmtdkj2.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmtdkj3.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmtdkj4.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmtdkj5.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmtdkj6.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmtdkj7.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmtexas.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmti.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmtkr.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmtron.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmusrf.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmusrg.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmusrgl.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmusrk1.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmusrsp.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmvdot.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmvv.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmwhql0.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmx5560.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmzoom.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmzyp.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmzyxel.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `mdmzyxlg.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `megasas2i.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `megasas35i.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `megasr.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `memory.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `mf.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `mgtdyn.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `microsoft_bluetooth_a2dp.inf` | 1 | 蓝牙 | 7 | 蓝牙无线连接 |
| `microsoft_bluetooth_a2dp_snk.inf` | 1 | 蓝牙 | 7 | 蓝牙无线连接 |
| `microsoft_bluetooth_a2dp_src.inf` | 1 | 蓝牙 | 7 | 蓝牙无线连接 |
| `microsoft_bluetooth_avrcptransport.inf` | 1 | 蓝牙 | 7 | 蓝牙无线连接 |
| `microsoft_bluetooth_hfp.inf` | 1 | 蓝牙 | 7 | 蓝牙无线连接 |
| `microsoft_bluetooth_hfp_ag.inf` | 1 | 蓝牙 | 7 | 蓝牙无线连接 |
| `microsoft_bluetooth_hfp_hf.inf` | 1 | 蓝牙 | 7 | 蓝牙无线连接 |
| `miradisp.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `mlx4_bus.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `modemcsa.inf` | 1 | 调制解调器 | 2 | 拨号时代产物 |
| `monitor.inf` | 1 | 显示适配器/监视器 | 8 | 显示输出；虚拟机里为基础显示 |
| `mpi3drvi.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `mptfcore.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `mptfcustomizeiosignalclient.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `mptfpowerlimitclient.inf` | 1 | 电源/电池/温控 | 8 | 供电与温度管理 |
| `mptfpowersourceclient.inf` | 1 | 电源/电池/温控 | 8 | 供电与温度管理 |
| `mptfpowertrackercore.inf` | 1 | 电源/电池/温控 | 8 | 供电与温度管理 |
| `mptfthermalpolicy.inf` | 1 | 电源/电池/温控 | 8 | 供电与温度管理 |
| `mrvlpcie8897.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `msclmd.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `mscustomizedio.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `msdri.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `msdv.inf` | 1 | IEEE 1394（火线） | 2 | 老式 DV/外置盘接口 |
| `msgpiowin32.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `mshdc.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `mshidkmdf.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `mshidumdf.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `msmouse.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `msports.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `mssmbios.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `mstape.inf` | 1 | IEEE 1394（火线） | 2 | 老式 DV/外置盘接口 |
| `mstemperaturesensor.inf` | 1 | 传感器 | 6 | 加速度计/光线传感器 |
| `msux64w10.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `mtconfig.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `mvumis.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `ndiscap.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `ndisimplatform.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `ndisimplatformmp.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `ndisuio.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `ndisvirtualbus.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `net1ic64.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `net1yx64.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `net2ic68.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `net44amd.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `net7400-x64-n650.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `net7500-x64-n650f.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `net7800-x64-n650f.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `net8187bv64.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `net8192se64.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `net9500-x64-n650f.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netathr10x.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netathrx.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netavpna.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netax88179_178a.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netax88772.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netbc63a.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netbc64.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netbrdg.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netbvbda.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netbxnd0a.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netbxnda.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netcxrd.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `nete1e3e.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `nete1g3e.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netefe3e.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netelx.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netevbd0a.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netevbda.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netg664.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netimm.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netip6.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netirda.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netjme.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netk57a.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netl160a.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netl1c63x64.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netl1e64.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netl260a.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netlldp.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netloop.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netmlx4eth63.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netmlx5.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netmscli.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netmyk64.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netnb.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netnvm64.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netnvma.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netnwifi.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netpacer.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netpgm.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netr28ux.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netr28x.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netr7364.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netrasa.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netrass.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netrast.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netrndis.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netrtl64.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netrtwlane.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netrtwlane01.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netrtwlane_13.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netrtwlans.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netrtwlanu.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netserv.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netsstpa.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `nett4x64.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `nettcpip.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netv1x64.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netvchannel.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netvf63a.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netvg63a.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netvwifibus.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netvwififlt.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netvwifimp.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netvwwanmp.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netwbw02.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netwew00.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netwew01.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netwlv64.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netwmbclass.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netwns64.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `networkprivacypolicy.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netwsw00.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netwtw02.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netwtw04.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netwtw06.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netwtw08.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netwtw10.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `netxex64.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `npsvctrig.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `ntprint.inf` | 2 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `ntprint4.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `nulhpopr.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `nulhprs8.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `nvdimm.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `nvmedisk.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `nvraid.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `oposdrv.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `pci.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `pcmcia.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `percsas2i.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `percsas3i.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `pluton-heci.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `plutonhsp2.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `pmem.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `pnpxinternetgatewaydevices.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `printqueue.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `prm.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `pvscsii.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `qcwlan64.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `qd3x64.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `ramdisk.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `rawsilo.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `rdcameradriver.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `rdlsbuscbs.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `rdpbus.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `rdpidd.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `remoteposdrv.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `rhproxy.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `rndiscmp.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `routepolicy.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `rspndr.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `rt640x64.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `rtcx21x64.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `rtucx21x64.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `rtux64w10.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `rtvdevx64.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `rtwlanu_oldic.inf` | 1 | 网络适配器/网络栈 | 9 | 有线/无线联网核心 |
| `sbp2.inf` | 1 | IEEE 1394（火线） | 2 | 老式 DV/外置盘接口 |
| `scmbus.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `scmvolume.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `scrawpdo.inf` | 1 | 便携设备（MTP/PTP） | 7 | USB 连手机传文件，按需求保留 |
| `scsidev.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `scunknown.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `sdbus.inf` | 1 | 存储卡读卡 | 6 | SD/CF 读卡 |
| `sdcaaggregator.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `sdcaclass.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `sdcahid.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `sdcamfd.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `sdstor.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `sensorsalsdriver.inf` | 1 | 传感器 | 6 | 加速度计/光线传感器 |
| `sensorshidclassdriver.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `sensorsservicedriver.inf` | 1 | 传感器 | 6 | 加速度计/光线传感器 |
| `sisraid2.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `sisraid4.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `smartsamd.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `smrdisk.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `smrvolume.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `spaceport.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `stexstor.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `sti.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `storfwupdate.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `stornvme.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `storufs.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `swenum.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `tape.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `tdibth.inf` | 1 | 蓝牙 | 7 | 蓝牙无线连接 |
| `termbus.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `termkbd.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `termmou.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `tpm.inf` | 1 | 可信平台/安全 | 7 | BitLocker、Windows Hello 依赖 |
| `tpmvsc.inf` | 1 | 可信平台/安全 | 7 | BitLocker、Windows Hello 依赖 |
| `transfercable.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `ts_generic.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `ts_wpdmtp.inf` | 1 | 便携设备（MTP/PTP） | 7 | USB 连手机传文件，按需求保留 |
| `tsgenericusbdriver.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `tsprint.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `tsusbhub.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `tsusbhubfilter.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `uaspstor.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `ucmucsiacpiclient.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `uefi.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `ufxchipidea.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `ufxsynopsys.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `uicciso.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `uiomap.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `umbus.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `umpass.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `unknown.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `urschipidea.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `urssynopsys.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `usb-platformdetection.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `usb.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `usb4devicerouter.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `usb4hostrouter.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `usb4p2pnetadapter.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `usbaudio2.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `usbcciddriver.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `usbcir.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `usbhub3.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `usbmidi2.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `usbncm.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `usbncmum.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `usbnet.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `usbport.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `usbser.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `usbstor.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `usbxhci.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `v_mscdsc.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `vca.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `vdrvroot.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `vhdmp.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `virtdisk.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `vmxnet3.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `vocaeffectpack-extension.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `volmgr.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `volsnap.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `volume.inf` | 1 | 存储控制器/存储栈 | 10 | 磁盘与存储链路核心，不可裁剪 |
| `vrd.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `vsmraid.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `vstxraid.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `wave.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `wceisvista.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `wdma_usb.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `wdmaudio.inf` | 1 | 音频 | 8 | 声音输出/录制 |
| `wdmaudioapo.inf` | 1 | 音频 | 8 | 声音输出/录制 |
| `wdmvsc.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `wfcvsc.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `wfpcapture.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `wgencounter.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `whvcrash.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `whyperkbd.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `windowstrustedrtproxy.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `wini3ctarget.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `winusb.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `wmbclass_wmc_union.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `wmiacpi.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `wnetvsc.inf` | 1 | Hyper-V 虚拟化集成组件 | 8 | 虚拟机客户机组件；物理机闲置但无害 |
| `wnetvsc_vfpp.inf` | 1 | Hyper-V 虚拟化集成组件 | 8 | 虚拟机客户机组件；物理机闲置但无害 |
| `wpdcomp.inf` | 1 | 便携设备（MTP/PTP） | 7 | USB 连手机传文件，按需求保留 |
| `wpdfs.inf` | 1 | 便携设备（MTP/PTP） | 7 | USB 连手机传文件，按需求保留 |
| `wpdmtp.inf` | 1 | 便携设备（MTP/PTP） | 7 | USB 连手机传文件，按需求保留 |
| `wpdmtphw.inf` | 1 | 便携设备（MTP/PTP） | 7 | USB 连手机传文件，按需求保留 |
| `ws3cap.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `wsdprint.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `wsdscdrv.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `wstorflt.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `wstorvsc.inf` | 1 | Hyper-V 虚拟化集成组件 | 8 | 虚拟机客户机组件；物理机闲置但无害 |
| `wudfrd.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `wudfusbcciddriver.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `wvid.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `wvmbus.inf` | 1 | Hyper-V 虚拟化集成组件 | 8 | 虚拟机客户机组件；物理机闲置但无害 |
| `wvmbushid.inf` | 1 | Hyper-V 虚拟化集成组件 | 8 | 虚拟机客户机组件；物理机闲置但无害 |
| `wvmbusvideo.inf` | 1 | Hyper-V 虚拟化集成组件 | 8 | 虚拟机客户机组件；物理机闲置但无害 |
| `wvmgid.inf` | 1 | Hyper-V 虚拟化集成组件 | 8 | 虚拟机客户机组件；物理机闲置但无害 |
| `wvmic.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `wvmic_ext.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `wvmic_guestinterface.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `wvmic_heartbeat.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `wvmic_kvpexchange.inf` | 1 | Hyper-V 虚拟化集成组件 | 8 | 虚拟机客户机组件；物理机闲置但无害 |
| `wvmic_shutdown.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `wvmic_timesync.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `wvmic_vss.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `wvpci.inf` | 1 | Hyper-V 虚拟化集成组件 | 8 | 虚拟机客户机组件；物理机闲置但无害 |
| `xboxgip.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |
| `xboxgipsynthetic.inf` | 1 | Hyper-V 虚拟化集成组件 | 8 | 虚拟机客户机组件；物理机闲置但无害 |
| `xinputhid.inf` | 1 | 键盘/鼠标/HID 输入 | 9 | 输入设备基础 |
| `xusb22.inf` | 1 | USB/总线/系统基础 | 9 | 设备枚举与供电基础 |
| `ykinx64.inf` | 1 | 设备驱动（类别按 INF 名推断） | 6 | 未匹配常见类别；未列入裁剪名单，保留现状 |

> 说明：`Windows\INF` 下共 755 个同名驱动定义文件，与 FileRepository 一一对应，其中与 INF 精确全名名单匹配的 15 个已随驱动同步清理；`System32\spool\drivers` 打印缓存与扫描（stisvc）、传真（Fax）、摄像头（frameserver / FrameServerMonitor）服务键随本节一并处理。功能/评分无法从 INF 名可靠判断的条目按「未匹配常见类别」处理（保留现状）。

## 三、字体（Windows\Fonts，共 346 个文件）


### 3.1 已精简（21 个）——被精简的模式：仅激进模式，且仅「制作 ISO」

| 字体文件 | 功能 | 评分 | 说明 |
|----------|------|:---:|------|
| `ebrima.ttf` | Ebrima（西非文种 UI 回退） | 2 | 极少使用的外语字体，随字体裁剪删除 |
| `ebrimabd.ttf` | Ebrima Bold | 2 | 极少使用的外语字体，随字体裁剪删除 |
| `gadugi.ttf` | Gadugi（埃塞俄比亚文） | 2 | 极少使用的外语字体，随字体裁剪删除 |
| `gadugib.ttf` | Gadugi Bold | 2 | 极少使用的外语字体，随字体裁剪删除 |
| `himalaya.ttf` | 藏文（Microsoft Himalaya） | 1 | 极少使用的外语字体，随字体裁剪删除 |
| `javatext.ttf` | 爪哇文 | 2 | 极少使用的外语字体，随字体裁剪删除 |
| `LeelaUIb.ttf` | 极少使用的外语字体 | 1 | 极少使用的外语字体，随字体裁剪删除 |
| `LeelawUI.ttf` | 极少使用的外语字体 | 1 | 极少使用的外语字体，随字体裁剪删除 |
| `LeelUIsl.ttf` | 极少使用的外语字体 | 1 | 极少使用的外语字体，随字体裁剪删除 |
| `mmrtext.ttf` | 缅甸文 | 2 | 极少使用的外语字体，随字体裁剪删除 |
| `mmrtextb.ttf` | 缅甸文 Bold | 2 | 极少使用的外语字体，随字体裁剪删除 |
| `monbaiti.ttf` | 传统蒙古文 | 1 | 极少使用的外语字体，随字体裁剪删除 |
| `msyi.ttf` | 彝文（Yi Baiti） | 2 | 极少使用的外语字体，随字体裁剪删除 |
| `Nirmala.ttc` | 极少使用的外语字体 | 1 | 极少使用的外语字体，随字体裁剪删除 |
| `ntailu.ttf` | 新傣仂文 | 2 | 极少使用的外语字体，随字体裁剪删除 |
| `ntailub.ttf` | 新傣仂文 Bold | 2 | 极少使用的外语字体，随字体裁剪删除 |
| `phagspa.ttf` | 八思巴文 | 2 | 极少使用的外语字体，随字体裁剪删除 |
| `phagspab.ttf` | 八思巴文 Bold | 2 | 极少使用的外语字体，随字体裁剪删除 |
| `seguihis.ttf` | Segoe UI Historic（古文字） | 2 | 极少使用的外语字体，随字体裁剪删除 |
| `taile.ttf` | 傣哪文（Tai Le） | 2 | 极少使用的外语字体，随字体裁剪删除 |
| `taileb.ttf` | 傣哪文 Bold | 2 | 极少使用的外语字体，随字体裁剪删除 |

### 3.2 未精简（322 个）——被精简的模式：未精简（除极少使用的外语字体外一概保留）

| 字体文件 | 功能 | 评分 | 说明 |
|----------|------|:---:|------|
| `8514fix.fon` | 936 | 5 |  |
| `8514fixe.fon` | 936 | 5 |  |
| `8514fixg.fon` | 936 | 5 |  |
| `8514fixr.fon` | 936 | 5 |  |
| `8514fixt.fon` | 936 | 5 |  |
| `8514oem.fon` | 936 | 5 |  |
| `8514oeme.fon` | 936 | 5 |  |
| `8514oemg.fon` | 936 | 5 |  |
| `8514oemr.fon` | 936 | 5 |  |
| `8514oemt.fon` | 936 | 5 |  |
| `8514sys.fon` | 936 | 5 |  |
| `8514syse.fon` | 936 | 5 |  |
| `8514sysg.fon` | 936 | 5 |  |
| `8514sysr.fon` | 936 | 5 |  |
| `8514syst.fon` | 936 | 5 |  |
| `85775.fon` | 936 | 5 |  |
| `85855.fon` | 936 | 5 |  |
| `85f1255.fon` | 936 | 5 |  |
| `85f1256.fon` | 936 | 5 |  |
| `85f1257.fon` | 936 | 5 |  |
| `85f874.fon` | 936 | 5 |  |
| `85s1255.fon` | 936 | 5 |  |
| `85s1256.fon` | 936 | 5 |  |
| `85s1257.fon` | 936 | 5 |  |
| `85s874.fon` | 936 | 5 |  |
| `app775.fon` | 936 | 5 |  |
| `app850.fon` | 936 | 5 |  |
| `app852.fon` | 936 | 5 |  |
| `app855.fon` | 936 | 5 |  |
| `app857.fon` | 936 | 5 |  |
| `app866.fon` | 936 | 5 |  |
| `app932.fon` | 936 | 5 |  |
| `app936.fon` | 936 | 5 |  |
| `app949.fon` | 936 | 5 |  |
| `app950.fon` | 936 | 5 |  |
| `arial.ttf` | 5 | 5 |  |
| `arialbd.ttf` | 5 | 5 |  |
| `arialbi.ttf` | 5 | 5 |  |
| `ariali.ttf` | 5 | 5 |  |
| `ariblk.ttf` | 5 | 5 |  |
| `bahnschrift.ttf` | 3 | 2026 |  |
| `c8514fix.fon` | 936 | 5 |  |
| `c8514oem.fon` | 936 | 5 |  |
| `c8514sys.fon` | 936 | 5 |  |
| `calibri.ttf` | 5 | 5 |  |
| `calibrib.ttf` | 5 | 5 |  |
| `calibrii.ttf` | 5 | 5 |  |
| `calibril.ttf` | 5 | 5 |  |
| `calibrili.ttf` | 5 | 5 |  |
| `calibriz.ttf` | 5 | 5 |  |
| `cambria.ttc` | 5 | 5 |  |
| `cambriab.ttf` | 5 | 5 |  |
| `cambriai.ttf` | 5 | 5 |  |
| `cambriaz.ttf` | 5 | 5 |  |
| `Candara.ttf` | 5 | 2026 |  |
| `Candarab.ttf` | 5 | 2026 |  |
| `Candarai.ttf` | 5 | 2026 |  |
| `Candaral.ttf` | 5 | 2026 |  |
| `Candarali.ttf` | 5 | 2026 |  |
| `Candaraz.ttf` | 5 | 2026 |  |
| `cga40737.fon` | 936 | 5 |  |
| `cga40850.fon` | 936 | 5 |  |
| `cga40852.fon` | 936 | 5 |  |
| `cga40857.fon` | 936 | 5 |  |
| `cga40866.fon` | 936 | 5 |  |
| `cga40869.fon` | 936 | 5 |  |
| `cga40woa.fon` | 936 | 5 |  |
| `cga80737.fon` | 936 | 5 |  |
| `cga80850.fon` | 936 | 5 |  |
| `cga80852.fon` | 936 | 5 |  |
| `cga80857.fon` | 936 | 5 |  |
| `cga80866.fon` | 936 | 5 |  |
| `cga80869.fon` | 936 | 5 |  |
| `cga80woa.fon` | 936 | 5 |  |
| `comic.ttf` | 1 | 2026 |  |
| `comicbd.ttf` | 1 | 2026 |  |
| `comici.ttf` | 1 | 2026 |  |
| `comicz.ttf` | 1 | 2026 |  |
| `consola.ttf` | 5 | 5 |  |
| `consolab.ttf` | 5 | 5 |  |
| `consolai.ttf` | 5 | 5 |  |
| `consolaz.ttf` | 5 | 5 |  |
| `constan.ttf` | 5 | 2026 |  |
| `constanb.ttf` | 5 | 2026 |  |
| `constani.ttf` | 5 | 2026 |  |
| `constanz.ttf` | 5 | 2026 |  |
| `corbel.ttf` | 5 | 2026 |  |
| `corbelb.ttf` | 5 | 2026 |  |
| `corbeli.ttf` | 5 | 2026 |  |
| `corbell.ttf` | 5 | 2026 |  |
| `corbelli.ttf` | 5 | 2026 |  |
| `corbelz.ttf` | 5 | 2026 |  |
| `coue1255.fon` | 936 | 5 |  |
| `coue1256.fon` | 936 | 5 |  |
| `coue1257.fon` | 936 | 5 |  |
| `couf1255.fon` | 936 | 5 |  |
| `couf1256.fon` | 936 | 5 |  |
| `couf1257.fon` | 936 | 5 |  |
| `cour.ttf` | 5 | 5 |  |
| `courbd.ttf` | 5 | 5 |  |
| `courbi.ttf` | 5 | 5 |  |
| `coure.fon` | 5 | 5 |  |
| `couree.fon` | 5 | 5 |  |
| `coureg.fon` | 5 | 5 |  |
| `courer.fon` | 5 | 5 |  |
| `couret.fon` | 5 | 5 |  |
| `courf.fon` | 5 | 5 |  |
| `courfe.fon` | 5 | 5 |  |
| `courfg.fon` | 5 | 5 |  |
| `courfr.fon` | 5 | 5 |  |
| `courft.fon` | 5 | 5 |  |
| `couri.ttf` | 5 | 5 |  |
| `cvgafix.fon` | 936 | 5 |  |
| `cvgasys.fon` | 936 | 5 |  |
| `Deng.ttf` | 5 | 5 |  |
| `Dengb.ttf` | 5 | 5 |  |
| `Dengl.ttf` | 5 | 5 |  |
| `dos737.fon` | 936 | 5 |  |
| `dos869.fon` | 936 | 5 |  |
| `dosapp.fon` | 936 | 5 |  |
| `ega40737.fon` | 936 | 5 |  |
| `ega40850.fon` | 936 | 5 |  |
| `ega40852.fon` | 936 | 5 |  |
| `ega40857.fon` | 936 | 5 |  |
| `ega40866.fon` | 936 | 5 |  |
| `ega40869.fon` | 936 | 5 |  |
| `ega40woa.fon` | 936 | 5 |  |
| `ega80737.fon` | 936 | 5 |  |
| `ega80850.fon` | 936 | 5 |  |
| `ega80852.fon` | 936 | 5 |  |
| `ega80857.fon` | 936 | 5 |  |
| `ega80866.fon` | 936 | 5 |  |
| `ega80869.fon` | 936 | 5 |  |
| `ega80woa.fon` | 936 | 5 |  |
| `framd.ttf` | 3 | 2026 |  |
| `framdit.ttf` | 3 | 2026 |  |
| `Gabriola.ttf` | 5 | 2026 |  |
| `georgia.ttf` | 5 | 2026 |  |
| `georgiab.ttf` | 5 | 2026 |  |
| `georgiai.ttf` | 5 | 2026 |  |
| `georgiaz.ttf` | 5 | 2026 |  |
| `h8514fix.fon` | 936 | 5 |  |
| `h8514oem.fon` | 936 | 5 |  |
| `h8514sys.fon` | 936 | 5 |  |
| `hvgafix.fon` | 936 | 5 |  |
| `hvgasys.fon` | 936 | 5 |  |
| `impact.ttf` | 3 | 2026 |  |
| `Inkfree.ttf` | 5 | 2026 |  |
| `j8514fix.fon` | 936 | 5 |  |
| `j8514oem.fon` | 936 | 5 |  |
| `j8514sys.fon` | 936 | 5 |  |
| `jsmalle.fon` | 936 | 5 |  |
| `jsmallf.fon` | 936 | 5 |  |
| `jvgafix.fon` | 936 | 5 |  |
| `jvgasys.fon` | 936 | 5 |  |
| `l_10646.ttf` | 5 | 5 |  |
| `lucon.ttf` | 5 | 5 |  |
| `malgun.ttf` | 5 | 5 |  |
| `malgunbd.ttf` | 5 | 5 |  |
| `malgunsl.ttf` | 5 | 5 |  |
| `marlett.ttf` | 5 | 5 |  |
| `micross.ttf` | 5 | 5 |  |
| `mingliub.ttc` | 5 | 5 |  |
| `modern.fon` | 936 | 5 |  |
| `msgothic.ttc` | 5 | 5 |  |
| `msjh.ttc` | 5 | 5 |  |
| `msjhbd.ttc` | 5 | 5 |  |
| `msjhl.ttc` | 5 | 5 |  |
| `msyh.ttc` | 5 | 5 |  |
| `msyhbd.ttc` | 5 | 5 |  |
| `msyhl.ttc` | 5 | 5 |  |
| `mvboli.ttf` | 2 | 2026 |  |
| `NotoSansSC-VF.ttf` | 5 | 5 |  |
| `NotoSerifSC-VF.ttf` | 5 | 5 |  |
| `pala.ttf` | 4 | 2026 |  |
| `palab.ttf` | 4 | 2026 |  |
| `palabi.ttf` | 4 | 2026 |  |
| `palai.ttf` | 4 | 2026 |  |
| `roman.fon` | 936 | 5 |  |
| `s8514fix.fon` | 936 | 5 |  |
| `s8514oem.fon` | 936 | 5 |  |
| `s8514sys.fon` | 936 | 5 |  |
| `SansSerifCollection.ttf` | 5 | 5 |  |
| `script.fon` | 936 | 5 |  |
| `segmdl2.ttf` | 5 | 5 |  |
| `SegoeIcons.ttf` | 26 | 5 |  |
| `segoepr.ttf` | 3 | 2026 |  |
| `segoeprb.ttf` | 3 | 2026 |  |
| `segoesc.ttf` | 3 | 2026 |  |
| `segoescb.ttf` | 3 | 2026 |  |
| `segoeui.ttf` | 5 | 5 |  |
| `segoeuib.ttf` | 5 | 5 |  |
| `segoeuii.ttf` | 5 | 5 |  |
| `segoeuil.ttf` | 5 | 5 |  |
| `segoeuisl.ttf` | 5 | 5 |  |
| `segoeuiz.ttf` | 5 | 5 |  |
| `seguibl.ttf` | 5 | 5 |  |
| `seguibli.ttf` | 5 | 5 |  |
| `seguiemj.ttf` | 5 | 5 |  |
| `seguili.ttf` | 5 | 5 |  |
| `seguisb.ttf` | 5 | 5 |  |
| `seguisbi.ttf` | 5 | 5 |  |
| `seguisli.ttf` | 5 | 5 |  |
| `seguisym.ttf` | 5 | 5 |  |
| `SegUIVar.ttf` | 11 | 5 |  |
| `sere1255.fon` | 936 | 5 |  |
| `sere1256.fon` | 936 | 5 |  |
| `sere1257.fon` | 936 | 5 |  |
| `serf1255.fon` | 936 | 5 |  |
| `serf1256.fon` | 936 | 5 |  |
| `serf1257.fon` | 936 | 5 |  |
| `serife.fon` | 936 | 5 |  |
| `serifee.fon` | 936 | 5 |  |
| `serifeg.fon` | 936 | 5 |  |
| `serifer.fon` | 936 | 5 |  |
| `serifet.fon` | 936 | 5 |  |
| `seriff.fon` | 936 | 5 |  |
| `seriffe.fon` | 936 | 5 |  |
| `seriffg.fon` | 936 | 5 |  |
| `seriffr.fon` | 936 | 5 |  |
| `serifft.fon` | 936 | 5 |  |
| `simfang.ttf` | 5 | 5 |  |
| `simhei.ttf` | 5 | 5 |  |
| `simkai.ttf` | 5 | 5 |  |
| `simsun.ttc` | 5 | 5 |  |
| `simsunb.ttf` | 5 | 5 |  |
| `SimsunExtG.ttf` | 5 | 5 |  |
| `SitkaVF-Italic.ttf` | 5 | 2026 |  |
| `SitkaVF.ttf` | 5 | 2026 |  |
| `smae1255.fon` | 936 | 5 |  |
| `smae1256.fon` | 936 | 5 |  |
| `smae1257.fon` | 936 | 5 |  |
| `smaf1255.fon` | 936 | 5 |  |
| `smaf1256.fon` | 936 | 5 |  |
| `smaf1257.fon` | 936 | 5 |  |
| `smalle.fon` | 936 | 5 |  |
| `smallee.fon` | 936 | 5 |  |
| `smalleg.fon` | 936 | 5 |  |
| `smaller.fon` | 936 | 5 |  |
| `smallet.fon` | 936 | 5 |  |
| `smallf.fon` | 936 | 5 |  |
| `smallfe.fon` | 936 | 5 |  |
| `smallfg.fon` | 936 | 5 |  |
| `smallfr.fon` | 936 | 5 |  |
| `smallft.fon` | 936 | 5 |  |
| `ssee1255.fon` | 936 | 5 |  |
| `ssee1256.fon` | 936 | 5 |  |
| `ssee1257.fon` | 936 | 5 |  |
| `ssee874.fon` | 936 | 5 |  |
| `ssef1255.fon` | 936 | 5 |  |
| `ssef1256.fon` | 936 | 5 |  |
| `ssef1257.fon` | 936 | 5 |  |
| `ssef874.fon` | 936 | 5 |  |
| `sserife.fon` | 936 | 5 |  |
| `sserifee.fon` | 936 | 5 |  |
| `sserifeg.fon` | 936 | 5 |  |
| `sserifer.fon` | 936 | 5 |  |
| `sserifet.fon` | 936 | 5 |  |
| `sseriff.fon` | 936 | 5 |  |
| `sseriffe.fon` | 936 | 5 |  |
| `sseriffg.fon` | 936 | 5 |  |
| `sseriffr.fon` | 936 | 5 |  |
| `sserifft.fon` | 936 | 5 |  |
| `svgafix.fon` | 936 | 5 |  |
| `svgasys.fon` | 936 | 5 |  |
| `sylfaen.ttf` | 4 | 2026 |  |
| `symbol.ttf` | 5 | 5 |  |
| `tahoma.ttf` | 5 | 5 |  |
| `tahomabd.ttf` | 5 | 5 |  |
| `times.ttf` | 5 | 5 |  |
| `timesbd.ttf` | 5 | 5 |  |
| `timesbi.ttf` | 5 | 5 |  |
| `timesi.ttf` | 5 | 5 |  |
| `trebuc.ttf` | 5 | 2026 |  |
| `trebucbd.ttf` | 5 | 2026 |  |
| `trebucbi.ttf` | 5 | 2026 |  |
| `trebucit.ttf` | 5 | 2026 |  |
| `verdana.ttf` | 6 | 2026 |  |
| `verdanab.ttf` | 6 | 2026 |  |
| `verdanai.ttf` | 6 | 2026 |  |
| `verdanaz.ttf` | 6 | 2026 |  |
| `vga737.fon` | 936 | 5 |  |
| `vga775.fon` | 936 | 5 |  |
| `vga850.fon` | 936 | 5 |  |
| `vga852.fon` | 936 | 5 |  |
| `vga855.fon` | 936 | 5 |  |
| `vga857.fon` | 936 | 5 |  |
| `vga860.fon` | 936 | 5 |  |
| `vga861.fon` | 936 | 5 |  |
| `vga863.fon` | 936 | 5 |  |
| `vga865.fon` | 936 | 5 |  |
| `vga866.fon` | 936 | 5 |  |
| `vga869.fon` | 936 | 5 |  |
| `vga932.fon` | 936 | 5 |  |
| `vga936.fon` | 936 | 5 |  |
| `vga949.fon` | 936 | 5 |  |
| `vga950.fon` | 936 | 5 |  |
| `vgaf1255.fon` | 936 | 5 |  |
| `vgaf1256.fon` | 936 | 5 |  |
| `vgaf1257.fon` | 936 | 5 |  |
| `vgaf874.fon` | 936 | 5 |  |
| `vgafix.fon` | 936 | 5 |  |
| `vgafixe.fon` | 936 | 5 |  |
| `vgafixg.fon` | 936 | 5 |  |
| `vgafixr.fon` | 936 | 5 |  |
| `vgafixt.fon` | 936 | 5 |  |
| `vgaoem.fon` | 936 | 5 |  |
| `vgas1255.fon` | 936 | 5 |  |
| `vgas1256.fon` | 936 | 5 |  |
| `vgas1257.fon` | 936 | 5 |  |
| `vgas874.fon` | 936 | 5 |  |
| `vgasys.fon` | 936 | 5 |  |
| `vgasyse.fon` | 936 | 5 |  |
| `vgasysg.fon` | 936 | 5 |  |
| `vgasysr.fon` | 936 | 5 |  |
| `vgasyst.fon` | 936 | 5 |  |
| `webdings.ttf` | 5 | 5 |  |
| `wingding.ttf` | 5 | 5 |  |
| `YuGothB.ttc` | 5 | 5 |  |
| `YuGothL.ttc` | 5 | 5 |  |
| `YuGothM.ttc` | 5 | 5 |  |
| `YuGothR.ttc` | 5 | 5 |  |

## 四、其他预装组件

| 组件 | 功能 | 评分 | 被精简的模式 |
|------|------|:---:|------------|
| Microsoft Edge（含 WebView2 等组件） | 系统浏览器 | 7 | 仅激进模式（移除 Edge）；一般模式与激进模式（保留 Edge）未精简 |
| OneDrive（预置安装器） | 微软云同步客户端 | 2 | 三种模式均移除 |
| WinRE（`winre.wim`） | 恢复环境（26H2 安装器硬性依赖） | 9 | 未精简（三种模式均保留） |
| 入门首登卸载（FirstLogonCommands） | 见 1.1 表「入门」行 | 1 | 三种模式（仅制作 ISO，随应答文件注入） |

> 手机 USB 传文件（WPD/MTP 驱动与服务）按需求保留，未精简。





> 修订（2026-10-01）：①SegoeIcons.ttf（= Segoe Fluent Icons，系统图标字体）与 Segoe UI 各字重、Noto 简中、Microsoft Sans Serif、旧符号字体曾因保留名单遗漏被误删导致系统图标变方块，现已恢复；②字体策略改为「删除名单制」——仅精简极少使用的外语字体（本表 3.1 共 21 个文件：蒙古文 / 藏文 / 缅甸文 / 印度语系 / 彝文 / 爪哇文 / 埃塞俄比亚文 / 古文字等），其余 322 个字体文件一概保留（含装饰性西文）；③`StaticCache.dat` / `desktop.ini` 等非字体文件不再删除。
