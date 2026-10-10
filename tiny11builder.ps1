<#
.SYNOPSIS
    精简 Windows 11：制作精简 ISO / 精简当前系统 / 独立维护小工具（多模式中文版）。
#>

# 版本 3.8

#---------[ 参数 ]---------#
param (
    [ValidatePattern('^[c-zC-Z]$')][string]$ISO,
    [ValidatePattern('^[c-zC-Z]$')][string]$SCRATCH,
    [string]$Mode,
    [switch]$NetFx3
)

#---------[ 输出时间戳 ]---------#
# 为每条输出加上 [yyyy-MM-dd HH:mm:ss] 前缀。
# 空白行与非字符串对象原样输出，保持原有排版与语义不变。
function Write-Output {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [object]$InputObject
    )
    process {
        if ($InputObject -is [string] -and -not [string]::IsNullOrWhiteSpace($InputObject)) {
            Microsoft.PowerShell.Utility\Write-Output ('[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $InputObject)
        } else {
            Microsoft.PowerShell.Utility\Write-Output $InputObject
        }
    }
}

#---------[ 运行对象标记 ]---------#
# $script:LiveMode = $false → 制作全新 ISO（操作挂载的映像）
# $script:LiveMode = $true  → 精简当前正在使用的系统（操作宿主机本身）
# 先给默认值，函数里读它来判断走哪条路径；真正的取值在「选择操作对象」处赋值。
$script:LiveMode = $false

# 是否启用 .NET Framework 3.5（仅制作 ISO 时可启用；取值在 ISO 分支的输入收集阶段确定）
$enableNetFx3 = $false

#---------[ 临时目录布局 ]---------#
# 本工具的临时目录统一放在 <临时盘>\temp\ 这个专用容器下：
#     <临时盘>\temp\tiny11      —— 解包出来的 ISO 树（也是最终 ISO 的源目录）
#     <临时盘>\temp\scratchdir  —— 映像挂载点
# 「收尾清理」与「启动时清理上次残留」都只处理容器内这两层固定路径，
# 注意：容器目录 temp 本身只在它已空时才删除。
$script:ScratchContainer = 'temp'

#---------[ 任务清单（图形界面与命令行选单的唯一顺序来源）]---------#
# 数组下标 + 1 就是用户看到的编号（[1]-[7]）。图形界面窗口与命令行选单都由这一张表生成，
# 因此两边的编号与顺序永远一致 —— 以后新增 / 调整 / 换序任务时只改这里一处即可。
#   Title     选项标题（两边共用）
#   TitleNote 标题末尾的补充（如「（推荐）」），没有则留空
#   GuiDesc   图形界面里显示在选项下方的灰色单行说明
#   CliDesc   命令行里缩进显示的多行说明
#   CliMatch  命令行中输入非数字时用于识别该任务的匹配式（正则）
$script:TaskMenu = @(
    @{
        Key       = 'iso'
        Title     = '制作全新的精简 ISO'
        TitleNote = '（推荐）'
        GuiDesc   = '把官方 ISO 精简成可启动的镜像；不改动本机，可反复重来。'
        CliDesc   = @(
            '精简已挂载的 Windows 11 ISO，输出可启动的精简 ISO（文件名带语言 / 版型 / 版本 / 模式 / 时间戳）；',
            '不改动本机，可反复重来。'
        )
        CliMatch  = '制作|iso|镜像'
    },
    @{
        Key       = 'live'
        Title     = '精简当前正在使用的系统'
        TitleNote = ''
        GuiDesc   = '直接精简本机，改动立即生效且不可逆；请先确认重要数据已有备份。'
        CliDesc   = @(
            '直接对本机执行精简，改动立即生效，【不可逆】——请先确认重要数据已有备份。',
            '动作：移除预置应用（并把当前用户已安装的同类应用一并卸掉）、写入广告 / 遥测 / Copilot /',
            'Teams 等策略注册表；只跳过 OOBE 目录（\CurrentVersion\OOBE）下仅对全新安装有意义的项',
            '（BypassNRO、DisableOnline）；硬件绕过键（LabConfig、MoSetup）仍会写入，供日后就地升级 / 重装使用。',
            '应答文件与映像挂载只用于制作 ISO。所有模式都会移除 Microsoft Store / Store 购买应用 /',
            '安全评估浏览器。激进模式额外：禁用 Defender 与 Windows Update、清理计划任务；',
            'WinSxS 用官方 Dism /Online /Cleanup-Image /ResetBase 压缩（活动系统不做整体替换）。'
        )
        CliMatch  = 'live|活动|本机精简|精简当前'
    },
    @{
        Key       = 'clean-junk'
        Title     = '清理本机垃圾文件'
        TitleNote = ''
        GuiDesc   = '清理临时文件、各类缓存、日志、崩溃转储、回收站、旧版安装源等；不可逆。'
        CliDesc   = @(
            '独立小工具：按 62 项清理清单清本机垃圾（临时文件、各类缓存、日志、崩溃转储、回收站、',
            '各类安装源缓存等），逐项输出清理数量；不涉及应用移除与注册表优化。'
        )
        CliMatch  = '清理|垃圾|clean'
    },
    @{
        Key       = 'disable-defender'
        Title     = '禁用本机系统的 Windows Defender'
        TitleNote = ''
        GuiDesc   = '停止并禁用 Defender（服务与驱动 Start=4）并隐藏「病毒和威胁防护」页；可用第 5 项恢复。'
        CliDesc   = @(
            '独立小工具：仅禁用 Defender（服务与驱动 Start=4 + 隐藏「病毒和威胁防护」设置页），可随时用 [5] 恢复。'
        )
        CliMatch  = '禁用.*defender|disable.*defender'
    },
    @{
        Key       = 'restore-defender'
        Title     = '恢复本机系统的 Windows Defender'
        TitleNote = ''
        GuiDesc   = '恢复为 Windows 官方默认的防护状态（重启后生效）。'
        CliDesc   = @(
            '独立小工具：恢复为 26H2 实测官方默认启动值（WinDefend=2、WdNisSvc=3、Sense=3、WdNisDrv=3、WdFilter=0）。'
        )
        CliMatch  = '恢复.*defender|restore.*defender'
    },
    @{
        Key       = 'disable-wu'
        Title     = '禁用本机系统的 Windows Update'
        TitleNote = ''
        GuiDesc   = '停止并屏蔽 Windows Update（含传递优化）并隐藏「Windows 更新」页；可用第 7 项恢复。'
        CliDesc   = @(
            '独立小工具：仅禁用不删除（wuauserv / UsoSvc / WaaSMedicSvc / DoSvc 全部 Start=4 + 更新策略指向 localhost',
            '+ 隐藏「Windows 更新」设置页），可随时用 [7] 恢复。'
        )
        CliMatch  = '禁用.*update|disable.*update'
    },
    @{
        Key       = 'restore-wu'
        Title     = '恢复本机系统的 Windows Update'
        TitleNote = ''
        GuiDesc   = '恢复更新相关服务与策略（前提：相关服务键未被「物理精简」删除）。'
        CliDesc   = @(
            '独立小工具：相关服务恢复为手动启动、删除更新策略与 RunOnce 残留（前提：服务键未被「物理精简」删除）。'
        )
        CliMatch  = '恢复.*update|restore.*update'
    }
)

#---------[ 函数 ]---------#
function Set-RegistryValue {
    param (
        [string]$path,
        [string]$name,
        [string]$type,
        [string]$value
    )
    if (Test-LiveSkipRegPath $path) {
        Write-Output "（活动系统：跳过只对 OOBE 有意义的项）$path\$name"
        return
    }
    $target = Get-TargetRegPath $path
    # reg 失败时不抛异常，只设置退出码，因此必须显式检查 $LASTEXITCODE，否则会误报成功
    # 空值名 = 写「默认值」，必须用 /ve（reg add 不接受空白的 /v）
    if ([string]::IsNullOrEmpty($name)) {
        & 'reg' 'add' $target '/ve' '/t' $type '/d' $value '/f' | Out-Null
    } else {
        & 'reg' 'add' $target '/v' $name '/t' $type '/d' $value '/f' | Out-Null
    }
    $regTarget = if ([string]::IsNullOrEmpty($name)) { "$target（默认值）" } else { "$target\$name" }
    if ($LASTEXITCODE -eq 0) {
        Write-Output "已设置注册表项：$regTarget"
    } else {
        Write-Output "设置注册表项失败（reg 退出码 $LASTEXITCODE）：$regTarget"
    }
}

function New-RegistryKey {
    param (
        [string]$path
    )
    if (Test-LiveSkipRegPath $path) {
        Write-Output "（活动系统：跳过只对 OOBE 有意义的项）$path"
        return
    }
    $target = Get-TargetRegPath $path
    & 'reg' 'add' $target '/f' | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Output "已创建注册表项：$target"
    } else {
        Write-Output "创建注册表项失败（reg 退出码 $LASTEXITCODE）：$target"
    }
}

# 判断注册表键是否存在。故意用 reg query 而不是 PowerShell 注册表提供程序（Test-Path）：
# 提供程序可能在本进程里留下指向已加载 hive 的未释放句柄，导致紧随其后的 reg unload 失败
# （激进模式 Store 预处理处两台机器实测复现）；reg.exe 是独立进程，退出即释放，不残留句柄。
function Test-RegKeyExists {
    param (
        [string]$path
    )
    # stderr 用 2>&1 并入管道后交给 Out-Null 丢弃 —— PS 5.1 下「2>$null」配合 Start-Transcript
    # 仍会把 reg 的「找不到注册表项」错误渲染进日志（NativeCommandError），合并式抑制才彻底。
    & 'reg' 'query' $path 2>&1 | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Remove-RegistryValue {
    param (
        [string]$path
    )
    if (Test-LiveSkipRegPath $path) {
        Write-Output "（活动系统：跳过只对 OOBE 有意义的项）$path"
        return
    }
    $target = Get-TargetRegPath $path
    # reg delete 对「键本来就不存在」和真失败都返回 1，无法从退出码区分，
    # 因此先判断存在性：不存在属正常情况（不同版本镜像里的键不一样），
    # 直接跳过并说明，避免把预期情况误报成「失败」。
    # 必须用 reg query 而非注册表提供程序 —— 见 Test-RegKeyExists 开头的说明。
    if (-not (Test-RegKeyExists $target)) {
        Write-Output "注册表项不存在（跳过删除）：$target"
        return
    }
    & 'reg' 'delete' $target '/f' | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Output "已删除注册表项：$target"
    } else {
        Write-Output "删除注册表项失败（reg 退出码 $LASTEXITCODE）：$target"
    }
}

#---------[ 本机默认用户配置单元（活动系统用）]---------#
# 活动系统的「用户级设置」要双写：当前用户（HKCU）+ 默认用户模板（Users\Default\ntuser.dat）。
# 模板需要临时加载成 zDEFUSER 才能写；加载失败不中止（只影响模板侧，当前用户侧照常写入）。
# 注意：本函数返回布尔值、且调用方是赋值接收（$script:LiveDefaultHiveMounted = 本函数）。
# 因此提示必须走 Write-Host —— 用 Write-Output 会让日志行混进返回值，赋值结果变成非空数组，
# 「恒为真」，于是即便加载失败，后面仍会去卸载一个根本没挂上的 hive。
function Mount-DefaultUserHiveLive {
    $file = Join-Path $env:SystemDrive 'Users\Default\ntuser.dat'
    if (-not (Test-Path -LiteralPath $file)) {
        Write-Host "未找到默认用户配置单元（$file），用户级设置只写当前用户。"
        return $false
    }
    & 'reg' 'load' 'HKLM\zDEFUSER' $file | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "默认用户配置单元加载失败（reg 退出码 $LASTEXITCODE），用户级设置只写当前用户。"
        return $false
    }
    Write-Host "已加载默认用户配置单元：$file"
    return $true
}

#---------[ 用户级设置的「双落点」写入 ]---------#
# 制作 ISO ：默认用户模板 Users\Default\ntuser.dat（zNTUSER）+ 系统默认配置单元 config\default（zDEFAULT）
# 精简本机 ：当前用户 HKCU（zNTUSER 的既有映射）+ 默认用户模板（已加载为 zDEFUSER）
function Set-UserRegistryValue {
    param (
        [string]$path,
        [string]$name,
        [string]$type,
        [string]$value
    )
    if (Test-LiveSkipRegPath $path) {
        Write-Output "（活动系统：跳过只对 OOBE 有意义的项）$path\$name"
        return
    }
    Set-RegistryValue $path $name $type $value
    if (-not $script:LiveMode) {
        Set-RegistryValue ($path -replace '^HKLM\\zNTUSER', 'HKLM\zDEFAULT') $name $type $value
    } elseif ($script:LiveDefaultHiveMounted) {
        Set-RegistryValue ($path -replace '^HKLM\\zNTUSER', 'HKLM\zDEFUSER') $name $type $value
    }
}

# 系统默认配置单元（HKEY_USERS\.DEFAULT）：活动系统直接写真实位置；制作 ISO 写镜像的 config\default
function Set-SystemDefaultRegistryValue {
    param (
        [string]$path,
        [string]$name,
        [string]$type,
        [string]$value
    )
    if (-not $script:LiveMode) {
        Set-RegistryValue $path $name $type $value
    } else {
        Set-RegistryValue ($path -replace '^HKLM\\zDEFAULT', 'HKU\.DEFAULT') $name $type $value
    }
}

#---------[ 注册表键重命名 ]---------#
# Dism++ 规则里「禁用右键菜单 / 文件预览」用的就是把键名搬到带前缀或备份位置的写法。
# reg.exe 没有重命名命令，这里用「复制子树 + 删除源键」等效实现；源不存在或目标已存在时只报告不报错。
function Move-RegistryKey {
    param (
        [string]$path,
        [string]$newPath
    )
    if (Test-LiveSkipRegPath $path) { return }
    $src = Get-TargetRegPath $path
    $dst = Get-TargetRegPath $newPath
    if (-not (Test-RegKeyExists $src)) {
        Write-Output "键不存在（跳过重命名）：$src"
        return
    }
    if (Test-RegKeyExists $dst) {
        Write-Output "目标键已存在（跳过重命名）：$dst"
        return
    }
    & 'reg' 'copy' $src $dst '/s' '/f' | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Output "复制键失败（reg 退出码 $LASTEXITCODE）：$src"
        return
    }
    & 'reg' 'delete' $src '/f' | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Output "已重命名注册表键：$src → $dst"
    } else {
        Write-Output "删除源键失败（reg 退出码 $LASTEXITCODE）：$src"
    }
}

#---------[ 管理员完全控制（takeown + icacls 复用助手）]---------#
# 裁剪段与垃圾清理多处需要先取得所有权再授权；统一走本助手，避免每处重复两个外部调用。
function Grant-AdminFullAccess {
    param ([string]$path, [switch]$Recurse)
    if ($Recurse) {
        & 'takeown' '/f' $path '/r' | Out-Null
        & 'icacls' $path '/grant' "$($adminGroup.Value):(F)" '/T' '/C' | Out-Null
    } else {
        & 'takeown' '/f' $path | Out-Null
        & 'icacls' $path '/grant' "$($adminGroup.Value):(F)" '/C' | Out-Null
    }
}

#---------[ 注册表项的「管理员完全控制」（.NET 访问控制助手）]---------#
# 个别服务键（如 DPS / TrkWks）在系统镜像里带有独立的严格 ACL，其安全描述符与同父键下的
# 其它服务不同（实测：这两个键的 SD 偏移与 PcaSvc/WSearch 明显不同），因此 reg add 直接写
# Start 会返回退出码 1 —— 即便是管理员身份。要写进去必须先取得所有权并把完全控制授予管理员组。
#
# 用 .NET 的注册表访问控制对象 + Set-Acl，而不是改键路径指向、也不是调用外部授权工具：
#   - 不动键本身，只替换它的安全描述符，语义干净；
#   - 不必落盘临时文件、不依赖额外 exe，参数由类型系统校验，出错会抛异常而不是静默失败；
#   - 与文件侧的 Grant-AdminFullAccess 对位，注册表现有访问控制也统一走本助手。
#
# 权限结构：三项完全控制必须一次写全，不能只补管理员一项 —— 授权是「整体替换」而非追加，
# 只写 Administrators 会把 SYSTEM 与 Creator Owner 的权限一并抹掉，反而破坏系统对该键的访问。
# 因此固定给出三项：Administrators（管理员组，供本脚本写入）、Creator Owner（创建者）、
# SYSTEM（系统账户），与 Windows 对服务键的默认授权结构保持一致。
#
# 注意 SetOwner 需要 SeTakeOwnershipPrivilege（管理员令牌默认持有），脚本已要求管理员身份运行。
function Grant-RegistryFullAccess {
    param ([string]$Key)
    try {
        # 统一用 Registry:: 前缀，避免 HKLM: 驱动器在 hive 频繁装卸后短暂失效导致读取失败。
        $subKey = $Key -replace '^HKLM\\', '' -replace '^HKEY_LOCAL_MACHINE\\', ''
        $acl = Get-Acl -Path "Registry::$Key" -ErrorAction Stop
        $acl.SetOwner($adminGroup)
        foreach ($identity in @($adminGroup, (New-Object System.Security.Principal.NTAccount('CREATOR OWNER')),
                (New-Object System.Security.Principal.NTAccount('SYSTEM')))) {
            $rule = New-Object System.Security.AccessControl.RegistryAccessRule($identity,
                [System.Security.AccessControl.RegistryRights]::FullControl,
                [System.Security.AccessControl.InheritanceFlags]::ContainerInherit,
                [System.Security.AccessControl.PropagationFlags]::None,
                [System.Security.AccessControl.AccessControlType]::Allow)
            $acl.AddAccessRule($rule)
        }
        Set-Acl -Path "Registry::$Key" -AclObject $acl -ErrorAction Stop
        return $true
    } catch {
        Write-Host "      注册表授权失败（$subKey）：$($_.Exception.Message)"
        return $false
    }
}

#---------[ 映像 / 活动系统 的注册表路径映射 ]---------#
# 全脚本的注册表调用统一写成「映像」形式（HKLM\zSYSTEM、zSOFTWARE、zNTUSER、zDEFAULT）。
# 活动系统模式下由本函数映射成宿主机上真实存在的等价路径；
# 映像模式下原样返回。
function Get-TargetRegPath {
    param (
        [string]$path
    )
    if (-not $script:LiveMode) { return $path }
    $p = $path
    # 运行中的系统上 ControlSet001 应写作 CurrentControlSet
    $p = $p -replace '\\ControlSet001\\', '\CurrentControlSet\'
    $p = $p -replace '^HKLM\\zSYSTEM', 'HKLM\SYSTEM'
    $p = $p -replace '^HKLM\\zSOFTWARE', 'HKLM\SOFTWARE'
    $p = $p -replace '^HKLM\\zCOMPONENTS', 'HKLM\COMPONENTS'
    # 运行中的系统没有「默认用户配置单元」可写，NTUSER / DEFAULT 两类都落到当前用户 HKCU
    $p = $p -replace '^HKLM\\zNTUSER', 'HKCU'
    $p = $p -replace '^HKLM\\zDEFAULT', 'HKCU'
    return $p
}

# 只对「全新安装 / OOBE」有意义的项：活动系统模式下跳过，不写入
function Test-LiveSkipRegPath {
    param (
        [string]$path
    )
    if (-not $script:LiveMode) { return $false }
    if ($path -match '\\CurrentVersion\\OOBE(\\|$)') { return $true }
    return $false
}

# 活动系统专用：卸载「当前用户已安装」的同类应用。
# 上面的 DISM 预置包移除只保证新建用户不再预装；已经装在当前用户下的应用需要这一步才会真正消失。
function Remove-InstalledAppx {
    param (
        [string[]]$prefixes
    )
    Write-Output "正在卸载当前用户已安装的同类应用（预置包移除不影响已安装的应用）..."
    # 一次性枚举当前用户全部应用，再在内存里匹配前缀。
    # 原因：逐个前缀调用 Get-AppxPackage -Name "<前缀>*" 会执行几十次独立查询，明显更慢；
    # 一次全量枚举后内存匹配要快得多。匹配规则保持与原来一致（按名称前缀匹配）。
    $allApps = @(Get-AppxPackage -ErrorAction SilentlyContinue)
    $ok = 0
    $fail = 0
    foreach ($app in $allApps) {
        if (@($prefixes | Where-Object { $app.Name -like "$_*" }).Count -eq 0) { continue }
        Write-Output "正在卸载（当前用户）：$($app.Name)..."
        try {
            Remove-AppxPackage -Package $app.PackageFullName -ErrorAction Stop
            $ok++
        } catch {
            $fail++
            Write-Output "卸载失败：$($app.Name)：$_"
        }
    }
    Write-Output "当前用户应用卸载完成：成功 $ok / 失败 $fail。"
}

function Mount-RegistryHive {
    param (
        [string]$key,
        [string]$file
    )
    reg load $key $file | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Output "注册表配置单元加载失败：$key（reg 退出码 $LASTEXITCODE）"
        Write-Output "继续执行会把本应写进映像的改动写到位错的宿主机注册表位置，因此脚本就此中止。"
        Write-Output "请重启后重试：残留的配置单元会在重启时释放。"
        Stop-AndExit
    }
}

# 强制结束滞留的 DISM worker 进程。它们是「挂载映像 / 离线 hive 句柄被长时间持有」的已知来源
# （多次实测：DISM 应用移除后 worker 滞留数分钟，令 reg unload 与后续 DISM 全部失败）。
# wimserv / DismHost 只服务于 WIM 挂载与 DISM 会话，结束它们不影响系统其它部分；
# TiWorker 是 Windows 模块安装程序的 worker，可能仍在消化上一轮的应用移除 —— 结束它正是
# 「终结上一轮全部状态」的一部分（其未完成的工作本就随会话丢弃）。
function Stop-LingeringDismWorkers {
    # 统计实际结束掉的进程数。不要用「循环里的 $procs 变量在循环外判断」——
    # PowerShell 里那是同一个变量，循环结束后只剩最后一轮（TiWorker）的值；
    # 典型失效场景：系统里只有滞留的 wimserv（最常见），$procs 末轮为空 → 判定为「没杀过」
    # → 跳过下面的等待 → 紧随的 reg unload / Dismount 撞在尚未释放的句柄上而失败。
    $killed = 0
    foreach ($n in 'wimserv', 'DismHost', 'TiWorker') {
        foreach ($p in @(Get-Process -Name $n -ErrorAction SilentlyContinue)) {
            Write-Output "正在结束滞留的 $n（PID $($p.Id)）..."
            try {
                Stop-Process -Id $p.Id -Force -ErrorAction Stop
                $killed++
            } catch {
                Write-Output "结束失败：$_"
            }
        }
    }
    # 只要真的结束过进程就等一下：进程对象虽已消失，内核与文件系统仍需要时间释放它持有的
    # hive / WIM 文件句柄，否则紧随其后的 reg unload / Dismount-WindowsImage 会报共享冲突。
    if ($killed -gt 0) { Start-Sleep -Seconds 3 }
}

function Dismount-RegistryHive {
    param (
        [string]$key
    )
    # 卸载紧跟在 DISM 操作之后时，DISM 的 worker 进程（DismHost / TiWorker）可能仍滞留并持有
    # hive 文件句柄，导致 reg unload 失败（两台机器已在 Store 预处理处实测复现）。卸载失败会让
    # hive 文件被内核锁定，后续所有 DISM 操作都会报退出码 32，继续执行只会产出带伤的镜像 ——
    # 因此先重试给 worker 退出时间，仍失败则中止脚本，绝不带伤继续。
    $unloadOk = $false
    foreach ($attempt in 1, 2, 3, 4, 5) {
        reg unload $key | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $unloadOk = $true
            break
        }
        if ($attempt -lt 5) {
            Write-Output "注册表配置单元卸载失败（reg 退出码 $LASTEXITCODE），等待 60 秒后重试..."
            Start-Sleep -Seconds 60
        }
    }
    if (-not $unloadOk) {
        # 常规重试仍失败 → 升级：结束滞留的 DISM worker（已知的句柄持有者）后再试两次
        Write-Output "常规重试仍失败，升级处理：结束滞留的 DISM worker 进程后重试..."
        Stop-LingeringDismWorkers
        foreach ($attempt in 6, 7) {
            reg unload $key | Out-Null
            if ($LASTEXITCODE -eq 0) {
                $unloadOk = $true
                break
            }
            Start-Sleep -Seconds 30
        }
    }
    if (-not $unloadOk) {
        Write-Output "注册表配置单元卸载失败：$key（含 6 次重试与 worker 清理，reg 退出码 $LASTEXITCODE）。"
        Write-Output "影响：该配置单元仍被内核锁定，后续所有 DISM 操作都会失败，继续执行只会产出带伤的镜像。"
        Write-Output "处理：重启一次（彻底释放被占用的配置单元）后重新运行本脚本，届时残留检查会自动清理。"
        Stop-AndExit
    }
}

# 读取 Windows 映像挂载记录。免提权可读（HKLM\SOFTWARE\Microsoft\WIMMount\Mounted Images）。
function Get-WimmountRecords {
    $out = @()
    try {
        foreach ($r in @(Get-ChildItem -LiteralPath 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WIMMount\Mounted Images' -ErrorAction Stop)) {
            $p = Get-ItemProperty -LiteralPath $r.PSPath -ErrorAction SilentlyContinue
            $out += [pscustomobject]@{
                MountPath = [string]$p.'Mount Path'
                WimPath   = [string]$p.'WIM Path'
                Index     = [string]$p.'Image Index'
            }
        }
    } catch { }
    return $out
}

# 检测上次运行留下的状态：仍加载的配置单元、仍挂载的映像、遗留的临时目录。
# 只做只读检测，不修改任何东西。每条都带 Ours 标记 —— 只有能确认是本工具留下的才允许清理：
#   · 配置单元用 z 前缀命名，是本工具（承袭上游）的专有约定 → 认定为本工具所有；
#   · 挂载记录要求 WIM 路径符合本工具固定布局 <盘>\tiny11\sources\install.wim，其它来源的挂载只报告；
#   · tiny11 目录要求内含 sources\install.wim；scratchdir 目录要求有本工具的挂载记录指向它。
function Get-StaleState {
    $hives = @()
    foreach ($h in 'zCOMPONENTS', 'zDEFAULT', 'zNTUSER', 'zSOFTWARE', 'zSYSTEM') {
        # 用 reg query 判断（Test-RegKeyExists）：提供程序会触碰可能仍处于加载状态的残留 hive，
        # 给随后的清理卸载留下句柄隐患
        if (Test-RegKeyExists "HKLM\$h") { $hives += "HKLM\$h" }
    }

    $records = @(Get-WimmountRecords)
    $mounts = @()
    $ourMountPaths = @()
    foreach ($r in $records) {
        $mp = $r.MountPath
        if (-not $mp) { $mp = '（未记录挂载点）' }
        $wp = $r.WimPath
        if (-not $wp) { $wp = '（未记录 WIM 路径）' }
        $ix = $r.Index
        if (-not $ix) { $ix = '?' }
        $ours = ($r.WimPath -match '(?i)\\tiny11\\sources\\install\.wim$')
        $mounts += [pscustomobject]@{ Text = "$mp   <=   $wp（索引 $ix）"; Ours = $ours; MountPath = $r.MountPath; WimPath = $r.WimPath }
        if ($ours) { $ourMountPaths += $r.MountPath }
    }

    # 临时目录可能落在脚本目录（-SCRATCH 留空回车时的默认值），也可能落在某个盘符根目录
    $roots = @()
    if ($PSScriptRoot) { $roots += ($PSScriptRoot -replace '[\\]+$', '') }
    foreach ($d in [System.IO.DriveInfo]::GetDrives()) {
        if ($d.IsReady -and $d.DriveType -eq [System.IO.DriveType]::Fixed) { $roots += ($d.Name -replace '[\\]+$', '') }
    }
    $dirs = @()
    foreach ($root in ($roots | Select-Object -Unique)) {
        # $PSScriptRoot 正常时是脚本目录；若为空（例如被当作命令片段执行）会跳过，
        # 否则 Join-Path 会因空路径报错，导致本轮残留检测静默漏检。
        if ([string]::IsNullOrWhiteSpace($root)) { continue }

        # —— 新版布局：<盘>\temp\tiny11 与 <盘>\temp\scratchdir ——
        # 两者是同一次运行一起创建的兄弟目录，因此只要其中任一具备签名，就认定两个都属于本工具。
        $container = Join-Path $root $script:ScratchContainer
        $newExtract = Join-Path $container 'tiny11'
        $newScratch = Join-Path $container 'scratchdir'
        $anchor = Test-Path -LiteralPath (Join-Path $newExtract 'sources\install.wim')
        if (-not $anchor) {
            foreach ($mp in $ourMountPaths) { if ($mp -and ($mp.TrimEnd('\') -ieq $newScratch)) { $anchor = $true } }
        }
        foreach ($p in @($newExtract, $newScratch)) {
            if (-not (Test-Path -LiteralPath $p)) { continue }
            if ($anchor) { $reason = "位于专用容器 $container 内，容器内有本工具的产物签名" }
            else { $reason = "位于专用容器 $container 内，但容器内没有本工具的产物签名" }
            $dirs += [pscustomobject]@{ Path = $p; Ours = $anchor; Reason = $reason }
        }

    }

    [pscustomobject]@{ Hives = @($hives); Mounts = @($mounts); Dirs = @($dirs) }
}

# 按用户确认过的清单执行残留清理。目标：无论上一轮以何种方式中断，本轮都要把它「终结」干净 ——
# 配置单元卸载 → 挂载映像丢弃式卸载（异常中止的会话改动不完整，一律不保存）→ 孤儿记录清理 →
# 全部终结确认后才删除临时目录。
# 关键认知（实测）：Dism.exe /Cleanup-WIM 只清理「孤儿」记录，不会卸载仍然活着的挂载；
# 因此必须先 Dismount，失败则升级为结束滞留的 DISM worker 后重试。
# 返回 $true = 全部清理完成；$false = 仍有无法终结的挂载（调用方应中止，重启是最后手段）。
function Clear-StaleState {
    param (
        [string[]]$Hives,
        [object[]]$Mounts,
        [object[]]$Dirs
    )

    foreach ($h in @($Hives)) {
        Dismount-RegistryHive $h
    }

    if (@($Mounts).Count -gt 0) {
        foreach ($m in @($Mounts)) {
            if (-not $m.MountPath -or ($m.MountPath -notmatch '^[A-Za-z]:\\')) {
                Write-Host "跳过卸载：挂载记录缺少有效的挂载点（$($m.Text)），交给 Dism.exe /Cleanup-WIM 处理。"
                continue
            }
            Write-Host "正在丢弃式卸载遗留的挂载映像：$($m.MountPath) ..."
            try {
                Dismount-WindowsImage -Path $m.MountPath -Discard -ErrorAction Stop
                Write-Host "已卸载（未提交的改动已丢弃）：$($m.MountPath)"
            } catch {
                Write-Host "卸载未成功：$_"
            }
        }
        Write-Host "正在执行 Dism.exe /Cleanup-WIM 清理孤儿挂载记录..."
        & Dism.exe '/Cleanup-WIM'
        Write-Host "Dism.exe /Cleanup-WIM 返回码 $LASTEXITCODE。"
        $left = @(@(Get-WimmountRecords) | Where-Object { $_.WimPath -match '(?i)\\tiny11\\sources\\install\.wim$' })
        if (@($left).Count -gt 0) {
            Write-Host "挂载仍未卸载，升级处理：结束滞留的 DISM worker 进程后重试..."
            Stop-LingeringDismWorkers
            foreach ($m in $left) {
                Write-Host "正在丢弃式卸载遗留的挂载映像：$($m.MountPath) ..."
                try {
                    Dismount-WindowsImage -Path $m.MountPath -Discard -ErrorAction Stop
                    Write-Host "已卸载（未提交的改动已丢弃）：$($m.MountPath)"
                } catch {
                    Write-Host "卸载仍未成功：$_"
                }
            }
            Write-Host "正在执行 Dism.exe /Cleanup-WIM 清理孤儿挂载记录..."
            & Dism.exe '/Cleanup-WIM'
            Write-Host "Dism.exe /Cleanup-WIM 返回码 $LASTEXITCODE。"
        }
    }

    # 挂载未终结前绝不删目录：挂载点背后是挂载卷的内容；挂载中的 WIM 源目录（tiny11）
    # 被删会掏空正在挂载的映像（实测发生过 tiny11 被删而挂载仍在）。
    $ourMountsLeft = @(@(Get-WimmountRecords) | Where-Object { $_.WimPath -match '(?i)\\tiny11\\sources\\install\.wim$' })
    if (@($ourMountsLeft).Count -gt 0) {
        Write-Host "仍有 $($ourMountsLeft.Count) 个本工具的挂载未能终结，所有临时目录都不删除。"
        foreach ($m in $ourMountsLeft) { Write-Host "      · 挂载点 $($m.MountPath)   <=   $($m.WimPath)" }
        return $false
    }
    # 内核层交叉确认：注册表记录可能已清但实际挂载仍在（两者可能不同步）。读不到就按仍有挂载处理。
    $kernelMountPaths = @()
    $kernelUnknown = $false
    try {
        foreach ($mi in @(Get-WindowsImage -Mounted -ErrorAction Stop)) {
            foreach ($prop in $mi.PSObject.Properties) {
                if (($prop.Value -is [string]) -and $prop.Value) { $kernelMountPaths += ($prop.Value.TrimEnd('\')) }
            }
        }
    } catch {
        $kernelUnknown = $true
        Write-Host "无法查询内核挂载状态（$_），为安全起见按「仍有挂载」处理。"
    }
    if ($kernelUnknown) { return $false }
    foreach ($dp in @(@($Dirs) | ForEach-Object { $_.Path.TrimEnd('\') })) {
        if ($kernelMountPaths -contains $dp) {
            Write-Host "内核中仍有挂载落在 $dp 上，所有临时目录都不删除。"
            return $false
        }
    }

    foreach ($d in @($Dirs)) {
        Write-Host "正在删除遗留的临时目录：$($d.Path)"
        & cmd /c rd /s /q "$($d.Path)"
        # 若它正位于专用容器下，容器空了就一并收掉。rd 不带 /s：目录非空会直接失败、不动任何东西，
        # 所以即使该容器里还有别的东西，也绝不会被连带删除。
        $parent = Split-Path -Path $d.Path -Parent
        if ($parent -and ((Split-Path -Path $parent -Leaf) -ieq $script:ScratchContainer)) {
            if ((Test-Path -LiteralPath $parent) -and (@(Get-ChildItem -LiteralPath $parent -Force -ErrorAction SilentlyContinue).Count -eq 0)) {
                & cmd /c rd /q "$parent"
            }
        }
    }
    return $true
}

#---------[ 单实例锁 ]---------#
# 两个实例会争用同一套临时目录、挂载点与配置单元。更危险的是：若不识别出「另一个实例正在运行」，
# 本实例会把它当成残留清理掉（清掉挂载、删掉临时目录），直接毁掉对方正在做的工作。
# 锁文件放在 LOG\ 下（该目录已被 .gitignore 排除）。用 PID 判断锁是否仍有效，
# 避免上次异常退出留下的死锁文件永久挡住后续运行。
function Get-RunningInstance {
    $lockFile = Join-Path $PSScriptRoot 'LOG\tiny11.running'
    if (-not (Test-Path -LiteralPath $lockFile)) { return $null }
    $text = ''
    try { $text = [string](Get-Content -LiteralPath $lockFile -First 1 -ErrorAction Stop) } catch { return $null }
    if (-not $text) { return $null }
    $parts = $text -split '\s+'
    $otherPid = 0
    [void][int]::TryParse($parts[0], [ref]$otherPid)
    if ($otherPid -le 0) { return $null }
    $proc = Get-Process -Id $otherPid -ErrorAction SilentlyContinue
    if (-not $proc) { return $null }                       # 进程已不存在 → 锁是陈旧的
    # 同时接受 Windows PowerShell（进程名 powershell）与 PowerShell 7+（进程名 pwsh）。
    # 只认 powershell 的话，在 7 下运行时会把对方活着的锁误判为陈旧锁，并发检测直接失效。
    if ($proc.ProcessName -notin @('powershell', 'pwsh')) { return $null }
    return [pscustomobject]@{ Pid = $otherPid; Started = ($parts | Select-Object -Skip 1) -join ' ' }
}

# 加锁：用「只创建、不覆盖」保证原子性 —— New-Item 在文件已存在时会失败，
# 因此两个实例几乎同时启动时也只能有一个拿到锁（若只用 Set-Content 会互相覆盖，挡不住竞争）。
# 返回 $true = 拿到锁；返回 $false = 锁被另一个活着的实例持有，或反复失败。
# 陈旧锁（持有进程已消失）会自动删掉后重试一次。
function Set-RunningLock {
    $lockFile = Join-Path $PSScriptRoot 'LOG\tiny11.running'
    for ($attempt = 1; $attempt -le 2; $attempt++) {
        try {
            New-Item -ItemType File -Path $lockFile -ErrorAction Stop | Out-Null
            Set-Content -LiteralPath $lockFile -Value ("{0} {1}" -f $PID, (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding ASCII -ErrorAction Stop
            return $true
        } catch {
            if (Get-RunningInstance) { return $false }      # 持有者是活着的本脚本实例 → 让位
            try { Remove-Item -LiteralPath $lockFile -Force -ErrorAction Stop } catch { }
        }
    }
    return $false
}

function Remove-RunningLock {
    try {
        $lockFile = Join-Path $PSScriptRoot 'LOG\tiny11.running'
        if (-not (Test-Path -LiteralPath $lockFile)) { return }
        $text = [string](Get-Content -LiteralPath $lockFile -First 1 -ErrorAction SilentlyContinue)
        # 只删本进程加的锁：若锁属于另一个实例（例如本实例因检测到它而退出），绝不能动它
        if ($text -and (($text -split '\s+')[0]) -ne "$PID") { return }
        Remove-Item -LiteralPath $lockFile -Force -ErrorAction Stop
    } catch { }
}

# 统一的「执行结果横幅」：脚本执行阶段（含成功、取消、异常）都用它把结果醒目地打在控制台上。
# 之所以自己画框而不用 Write-Output，是因为输出要带颜色、且不能被脚本自定义的时间戳 Write-Output 加工。
# Color 取值：Green=成功 / Yellow=取消 / Red=失败。
function Write-ResultBanner {
    param (
        [string]$Color = 'Green',
        [string[]]$Lines = @()
    )
    $bar = '  ============================================================'
    Write-Host ''
    Write-Host $bar -ForegroundColor $Color
    foreach ($ln in $Lines) { Write-Host "    $ln" -ForegroundColor $Color }
    Write-Host $bar -ForegroundColor $Color
    Write-Host ''
}

# 弹出图形界面流程中由本脚本装载的 ISO（收尾清理，正常完成与中止两条路径都会走到）。
# 只弹「本脚本挂的」（Mount-GuiIso 里 MountedNow 为真的才记录在案）；用户事先自己挂载的 ISO 不动。
# 施工阶段的全部操作都针对临时目录里的副本，不占用 ISO 盘符，因此任何时点弹出都安全。
# 失败容忍：弹不掉只提示手动弹出，不中止脚本。返回 $true = 无需弹出或全部弹出成功。
function Dismount-GuiMountedIsos {
    if (-not $script:GuiMountedByUs) { return $true }
    $allOk = $true
    $isoPaths = @($script:GuiMountedIsoPaths) | Select-Object -Unique
    foreach ($isoPath in $isoPaths) {
        try {
            Dismount-DiskImage -ImagePath $isoPath -ErrorAction Stop | Out-Null
            Write-Host "已自动弹出参数窗口中装载的 ISO：$isoPath"
        } catch {
            $allOk = $false
            Write-Host "自动弹出 ISO 失败（$isoPath）：$_"
            Write-Host "可在「此电脑」中右键该 ISO 选择「弹出」。"
        }
    }
    return $allOk
}

function Stop-AndExit {
    param (
        [int]$Code = 1,
        [string]$Reason = ''
    )
    # 中止脚本前先弹出本脚本装载的 ISO（失败容忍），再释放单实例锁，最后停掉转录，
    # 保证日志有结尾标记且内容已刷盘。未开启转录时 Stop-Transcript 会抛异常，故忽略。
    Dismount-GuiMountedIsos | Out-Null
    Remove-RunningLock
    try { Stop-Transcript | Out-Null } catch { }
    # 执行阶段的提示一律走控制台（窗口只用于开头的参数收集）：
    # 若开启过转录，先清屏抹掉 Stop-Transcript 自带的「已停止脚本」那行，再打结果横幅。
    try { Clear-Host } catch { }
    if ($Code -eq 0) {
        # 正常退出：没有特别说明时按「用户主动取消」处理
        if (-not $Reason) { $Reason = '已取消，本次未做任何改动。' }
        Write-ResultBanner -Color 'Yellow' -Lines @($Reason)
    } else {
        if (-not $Reason) { $Reason = '脚本已中止，本次没有完成。' }
        Write-ResultBanner -Color 'Red' -Lines @(
            $Reason + "（退出码 $Code）",
            '请把本窗口最后几行内容（或 LOG 目录下的日志文件）发给维护者：',
            "$PSScriptRoot\LOG"
        )
    }
    exit $Code
}

#---------[ 图形界面（WinForms）参数收集 ]---------#
# 目标：让完全不用命令行的人也能用 —— 双击入口后由窗口收集参数，界面里可直接选 .iso 文件并由脚本
# 自动挂载；用户不需要理解「执行策略」「管理员提权」「盘符」「映像索引」这些概念。
# 约定：窗口只负责【收集参数】，收集完立即关闭；后续构建全部在控制台窗口里进行 ——
#       包括各种提示、操作、结果展示、异常报警，一直到最后的「按任意键关闭」。
#       （长任务的日志在控制台里更易读，出错时也便于整段复制排查。）
# 静默用法（-ISO / -SCRATCH / -Mode 三者齐全）不经过窗口，行为与以前完全一致。
#
# 说明：以下所有控件都挂到 $script: 作用域。原因：按钮的 Click 事件脚本块在不同作用域下
#       执行，引用函数内局部变量并不可靠，挂到 $script: 才能保证事件里取得到。
#
# 另一条必须遵守的写法：坐标里一旦出现运算符，就不能用 New-Object 的简写形式，
#   错误：New-Object System.Drawing.Point(26, $y + 10)
#         → PS 5.1 会把 `$y + 10` 拆成两个参数，报「找不到 Point 的重载，参数计数为 3」
#   正确：New-Object System.Drawing.Point -ArgumentList @(26, ($y + 10))
#   （纯字面量或单个变量如 Point(18, 16)、Point(26, $y) 用简写是安全的。）

function New-GuiFont {
    # 界面字体：优先微软雅黑（中文清晰），取不到时回退 Arial
    try { return (New-Object System.Drawing.Font('Microsoft YaHei UI', 9)) } catch { }
    try { return (New-Object System.Drawing.Font('Microsoft YaHei', 9)) } catch { }
    return (New-Object System.Drawing.Font('Arial', 9))
}

# 下面两个弹窗只在【参数收集窗口】内部使用（校验输入、装载 ISO 失败等），
# 属于「用户还在窗口里」的阶段。执行阶段的任何提示都不要再用它们，一律走控制台输出。
function Show-GuiError {
    param ([string]$Text, [string]$Title = 'tiny11builder')
    try { [void][System.Windows.Forms.MessageBox]::Show($Text, $Title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) } catch { }
}

function Show-GuiConfirm {
    param ([string]$Text, [string]$Title = 'tiny11builder')
    try {
        return ([System.Windows.Forms.MessageBox]::Show($Text, $Title, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning) -eq [System.Windows.Forms.DialogResult]::Yes)
    } catch { return $false }
}

function Mount-GuiIso {
    # 挂载用户选定的 ISO 并读取映像清单。返回哈希表：Letter / Images / MountedNow / Error
    param ([string]$IsoPath)
    $r = @{ Letter = ''; Images = @(); MountedNow = $false; Error = '' }

    if (-not (Test-Path -LiteralPath $IsoPath)) { $r.Error = "找不到文件：`n$IsoPath"; return $r }

    try {
        $img = Get-DiskImage -ImagePath $IsoPath -ErrorAction SilentlyContinue
        if (-not $img -or -not $img.Attached) {
            $img = Mount-DiskImage -ImagePath $IsoPath -PassThru -ErrorAction Stop
            $r.MountedNow = $true
        }
    } catch {
        $r.Error = "装载 ISO 失败：`n$_`n`n请确认该文件是完整的 Windows 安装镜像。"
        return $r
    }

    # 挂载后卷可能需短暂等待才可见，重试几次
    $letter = ''
    for ($i = 0; $i -lt 12 -and -not $letter; $i++) {
        $vol = $img | Get-Volume -ErrorAction SilentlyContinue
        if ($vol -and $vol.DriveLetter) { $letter = [string]$vol.DriveLetter }
        if (-not $letter) { Start-Sleep -Milliseconds 300 }
    }
    if (-not $letter) {
        $r.Error = "ISO 已装载，但没能取得它的盘符。`n`n请关闭本窗口，用「资源管理器」右键该 ISO 选择「装载」后重新运行本工具。"
        return $r
    }
    $r.Letter = $letter

    if (-not (Test-Path -LiteralPath "${letter}:\sources\boot.wim")) {
        $r.Error = "该 ISO 的 sources 目录下没有 boot.wim，可能不是 Windows 安装镜像。`n`n请重新选择微软官方下载的 Windows 11 ISO。"
        return $r
    }
    $src = ''
    if (Test-Path -LiteralPath "${letter}:\sources\install.wim") { $src = "${letter}:\sources\install.wim" }
    elseif (Test-Path -LiteralPath "${letter}:\sources\install.esd") { $src = "${letter}:\sources\install.esd" }
    if (-not $src) {
        $r.Error = "该 ISO 的 sources 目录下既没有 install.wim 也没有 install.esd。"
        return $r
    }

    try {
        $r.Images = @(Get-WindowsImage -ImagePath $src -ErrorAction Stop)
    } catch {
        # DISM 模块不可用时回退到命令行解析（只解析 Index / Name 两行，不依赖模块加载）
        try {
            $out = @(& 'dism' '/English' '/Get-WimInfo' "/WimFile:$src" 2>&1)
            $tmp = @()
            $cur = $null
            foreach ($line in $out) {
                $s = [string]$line
                if ($s -match '^\s*Index\s*:\s*(\d+)\s*$') {
                    $cur = [ordered]@{ ImageIndex = [int]$Matches[1]; ImageName = '' }
                    $tmp += , $cur
                } elseif ($s -match '^\s*Name\s*:\s*(.+?)\s*$' -and $cur -and -not $cur.ImageName) {
                    $cur.ImageName = $Matches[1]
                }
            }
            $r.Images = @($tmp | ForEach-Object { [pscustomobject]$_ })
        } catch {
            $r.Images = @()
        }
    }
    return $r
}

function New-GuiTaskForm {
    # 任务选择窗口（返回表单对象，由调用方 ShowDialog）
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'tiny11builder — 请选择要执行的操作'
    $form.ClientSize = New-Object System.Drawing.Size(660, 480)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true
    $form.Font = New-GuiFont

    $head = New-Object System.Windows.Forms.Label
    $head.Text = '请选择要执行的操作，然后点击「下一步」：'
    $head.Location = New-Object System.Drawing.Point(18, 16)
    $head.Size = New-Object System.Drawing.Size(620, 20)
    $form.Controls.Add($head)

    # 选项清单由脚本级 $script:TaskMenu 生成 —— 与命令行选单同源同序，编号不会各自跑偏
    $items = @(
        for ($i = 0; $i -lt $script:TaskMenu.Count; $i++) {
            @{
                Key  = $script:TaskMenu[$i].Key
                Text = ('{0}. {1}{2}' -f ($i + 1), $script:TaskMenu[$i].Title, $script:TaskMenu[$i].TitleNote)
                Desc = $script:TaskMenu[$i].GuiDesc
            }
        }
    )
    $radios = New-Object System.Collections.ArrayList
    $y = 44
    foreach ($it in $items) {
        $rb = New-Object System.Windows.Forms.RadioButton
        $rb.Text = $it.Text
        $rb.Tag = $it.Key
        $rb.Location = New-Object System.Drawing.Point(26, $y)
        $rb.Size = New-Object System.Drawing.Size(600, 22)
        [void]$form.Controls.Add($rb)
        [void]$radios.Add($rb)

        # 每个选项下面配一行灰色说明（缩进对齐到选项文字），看不懂的人也能判断该选哪个
        $descLabel = New-Object System.Windows.Forms.Label
        $descLabel.Text = $it.Desc
        $descLabel.ForeColor = [System.Drawing.Color]::DimGray
        $descLabel.Location = New-Object System.Drawing.Point -ArgumentList @(44, ($y + 21))
        $descLabel.Size = New-Object System.Drawing.Size(586, 18)
        [void]$form.Controls.Add($descLabel)

        $y += 44
    }
    $radios[0].Checked = $true

    $note = New-Object System.Windows.Forms.Label
    $note.Text = '提示：第 1 项不会改动本机；第 2 项起直接作用于本机，其中第 2 项（精简系统）与第 3 项（清理垃圾）不可逆。'
    $note.ForeColor = [System.Drawing.Color]::DimGray
    $note.Location = New-Object System.Drawing.Point -ArgumentList @(26, ($y + 10))
    $note.Size = New-Object System.Drawing.Size(610, 34)
    $form.Controls.Add($note)

    $btnNext = New-Object System.Windows.Forms.Button
    $btnNext.Text = '下一步'
    $btnNext.Size = New-Object System.Drawing.Size(110, 30)
    $btnNext.Location = New-Object System.Drawing.Point -ArgumentList @(416, ($y + 62))
    $btnNext.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($btnNext)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = '取消'
    $btnCancel.Size = New-Object System.Drawing.Size(110, 30)
    $btnCancel.Location = New-Object System.Drawing.Point -ArgumentList @(536, ($y + 62))
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($btnCancel)

    $form.AcceptButton = $btnNext
    $form.CancelButton = $btnCancel
    $form | Add-Member -NotePropertyName RadioButtons -NotePropertyValue $radios
    return $form
}

function New-GuiDetailForm {
    # 详细参数窗口（按任务显示不同控件），返回表单对象
    param ([string]$TaskKey)

    $needIso = ($TaskKey -eq 'iso')
    # 高度刻意留足：底部按钮下方必须留出空白（曾出现按钮紧贴窗口底部的问题）
    $height = $(if ($needIso) { 550 } else { 300 })

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $(if ($needIso) { 'tiny11builder — 制作精简 ISO' } else { 'tiny11builder — 精简当前系统' })
    $form.ClientSize = New-Object System.Drawing.Size(680, $height)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true
    $form.Font = New-GuiFont
    $script:GuiDlgForm = $form

    # —— 精简模式（两种任务都要）——
    $gbMode = New-Object System.Windows.Forms.GroupBox
    $gbMode.Text = '精简模式'
    $gbMode.Location = New-Object System.Drawing.Point(16, 12)
    $gbMode.Size = New-Object System.Drawing.Size(648, 104)
    $form.Controls.Add($gbMode)

    $modeItems = @(
        @{ Key = 'normal'; Text = '一般模式（推荐）—— 删预装应用与广告遥测，系统仍可打补丁、加语言、加功能' },
        @{ Key = 'aggressive'; Text = '激进模式（最小系统）—— 额外移除 Edge、重建组件存储、禁 Defender / 更新、裁剪驱动与字体' },
        @{ Key = 'aggressive_keepedge'; Text = '激进模式（保留 Edge）—— 同上，但保留 Edge 浏览器' }
    )
    $modeRadios = New-Object System.Collections.ArrayList
    $my = 22
    foreach ($it in $modeItems) {
        $rb = New-Object System.Windows.Forms.RadioButton
        $rb.Text = $it.Text
        $rb.Tag = $it.Key
        $rb.Location = New-Object System.Drawing.Point(12, $my)
        $rb.Size = New-Object System.Drawing.Size(624, 22)
        [void]$gbMode.Controls.Add($rb)
        [void]$modeRadios.Add($rb)
        $my += 26
    }
    $modeRadios[0].Checked = $true
    # 事件处理器里要用，必须挂到 $script: 作用域（跨作用域引用函数内局部变量不可靠）
    $script:GuiDlgModeRadios = $modeRadios

    $y = 126

    # —— 以下仅「制作 ISO」需要 ——
    if ($needIso) {
        $gbIso = New-Object System.Windows.Forms.GroupBox
        $gbIso.Text = 'Windows 安装镜像（选择后会自动装载，无需手动操作）'
        $gbIso.Location = New-Object System.Drawing.Point(16, $y)
        $gbIso.Size = New-Object System.Drawing.Size(648, 126)
        $form.Controls.Add($gbIso)

        $lblFile = New-Object System.Windows.Forms.Label
        $lblFile.Text = 'ISO 文件：'
        $lblFile.Location = New-Object System.Drawing.Point(12, 26)
        $lblFile.Size = New-Object System.Drawing.Size(70, 20)
        $gbIso.Controls.Add($lblFile)

        $txtIso = New-Object System.Windows.Forms.TextBox
        $txtIso.Location = New-Object System.Drawing.Point(84, 23)
        $txtIso.Size = New-Object System.Drawing.Size(436, 23)
        $txtIso.ReadOnly = $true
        $gbIso.Controls.Add($txtIso)

        $btnBrowse = New-Object System.Windows.Forms.Button
        $btnBrowse.Text = '浏览…'
        $btnBrowse.Size = New-Object System.Drawing.Size(110, 26)
        $btnBrowse.Location = New-Object System.Drawing.Point(526, 22)
        $gbIso.Controls.Add($btnBrowse)

        $lblImg = New-Object System.Windows.Forms.Label
        $lblImg.Text = '映像版本：'
        $lblImg.Location = New-Object System.Drawing.Point(12, 60)
        $lblImg.Size = New-Object System.Drawing.Size(70, 20)
        $gbIso.Controls.Add($lblImg)

        $cmbImage = New-Object System.Windows.Forms.ComboBox
        $cmbImage.Location = New-Object System.Drawing.Point(84, 57)
        $cmbImage.Size = New-Object System.Drawing.Size(436, 23)
        $cmbImage.DropDownStyle = 'DropDownList'
        $gbIso.Controls.Add($cmbImage)

        $lblMount = New-Object System.Windows.Forms.Label
        $lblMount.Text = '（尚未选择文件）'
        $lblMount.ForeColor = [System.Drawing.Color]::DimGray
        $lblMount.Location = New-Object System.Drawing.Point(84, 88)
        $lblMount.Size = New-Object System.Drawing.Size(552, 24)
        $gbIso.Controls.Add($lblMount)

        # 事件里一律使用 $script: 变量引用控件
        $script:GuiDlgTxtIso = $txtIso
        $script:GuiDlgCmbImage = $cmbImage
        $script:GuiDlgLblMount = $lblMount
        $script:GuiDlgIndexMap = @()
        $script:GuiDlgIsoPath = ''
        $script:GuiDlgIsoLetter = ''

        $btnBrowse.Add_Click({
            $ofd = New-Object System.Windows.Forms.OpenFileDialog
            $ofd.Title = '请选择 Windows 11 的 ISO 文件'
            $ofd.Filter = 'Windows 安装镜像 (*.iso)|*.iso|所有文件 (*.*)|*.*'
            if ($ofd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
            $script:GuiDlgIsoPath = $ofd.FileName
            $script:GuiDlgIsoLetter = ''
            $script:GuiDlgIndexMap = @()
            $script:GuiDlgCmbImage.Items.Clear()
            $script:GuiDlgTxtIso.Text = ''
            $script:GuiDlgLblMount.Text = '正在装载并读取映像清单，请稍候…'
            $script:GuiDlgLblMount.Refresh()
            $res = Mount-GuiIso -IsoPath $ofd.FileName
            if ($res.Error) {
                $script:GuiDlgLblMount.Text = '（装载失败）'
                Show-GuiError $res.Error
                return
            }
            $script:GuiDlgIsoLetter = $res.Letter
            $script:GuiDlgTxtIso.Text = $ofd.FileName
            if ($res.MountedNow) {
                $script:GuiMountedByUs = $true
                # 记录镜像文件路径（而非盘符）：收尾时 Dismount-DiskImage 按路径弹出；
                # 用户反复换选不同 ISO 时逐个累积，收尾一并弹出。
                $script:GuiMountedIsoPaths = @($script:GuiMountedIsoPaths) + @($ofd.FileName)
            }
            if (@($res.Images).Count -gt 0) {
                foreach ($im in $res.Images) {
                    $script:GuiDlgIndexMap += [int]$im.ImageIndex
                    [void]$script:GuiDlgCmbImage.Items.Add(('{0} — {1}' -f $im.ImageIndex, $im.ImageName))
                }
            } else {
                $script:GuiDlgIndexMap += 1
                [void]$script:GuiDlgCmbImage.Items.Add('1 — （未能读取映像名，将使用第 1 个映像）')
            }
            $script:GuiDlgCmbImage.SelectedIndex = 0
            $script:GuiDlgLblMount.Text = ('已装载完成：{0} 盘' -f $res.Letter)
        })

        $y += 142

        # —— 临时盘 ——
        $gbScratch = New-Object System.Windows.Forms.GroupBox
        $gbScratch.Text = '临时文件与最终 ISO 所在盘符（需预留 20GB+ 空闲）'
        $gbScratch.Location = New-Object System.Drawing.Point(16, $y)
        $gbScratch.Size = New-Object System.Drawing.Size(648, 68)
        $form.Controls.Add($gbScratch)

        $lblScratch = New-Object System.Windows.Forms.Label
        $lblScratch.Text = '选择盘符：'
        $lblScratch.Location = New-Object System.Drawing.Point(12, 28)
        $lblScratch.Size = New-Object System.Drawing.Size(70, 20)
        $gbScratch.Controls.Add($lblScratch)

        $cmbScratch = New-Object System.Windows.Forms.ComboBox
        $cmbScratch.Location = New-Object System.Drawing.Point(84, 25)
        $cmbScratch.Size = New-Object System.Drawing.Size(546, 23)
        $cmbScratch.DropDownStyle = 'DropDownList'
        $gbScratch.Controls.Add($cmbScratch)

        $defaultLetter = ([string]$PSScriptRoot).Substring(0, 1)
        $seen = New-Object System.Collections.ArrayList
        foreach ($d in [System.IO.DriveInfo]::GetDrives()) {
            try {
                if ($d.DriveType -ne [System.IO.DriveType]::Fixed -or -not $d.IsReady) { continue }
                $lt = ([string]$d.Name).Substring(0, 1)
                $free = [math]::Round($d.AvailableFreeSpace / 1GB, 1)
                [void]$cmbScratch.Items.Add(('{0} 盘    可用 {1} GB' -f $lt, $free))
                [void]$seen.Add($lt)
            } catch { }
        }
        if ($cmbScratch.Items.Count -eq 0) {
            [void]$cmbScratch.Items.Add(('{0} 盘（脚本所在盘）' -f $defaultLetter))
            [void]$seen.Add($defaultLetter)
        }
        $script:GuiDlgScratchLetters = @($seen)
        $script:GuiDlgCmbScratch = $cmbScratch
        $idx = [array]::IndexOf($script:GuiDlgScratchLetters, $defaultLetter)
        $cmbScratch.SelectedIndex = $(if ($idx -ge 0) { $idx } else { 0 })

        $y += 84

        # —— 选项 ——
        $gbOpt = New-Object System.Windows.Forms.GroupBox
        $gbOpt.Text = '其他选项'
        $gbOpt.Location = New-Object System.Drawing.Point(16, $y)
        $gbOpt.Size = New-Object System.Drawing.Size(648, 114)
        $form.Controls.Add($gbOpt)

        $chkNetFx = New-Object System.Windows.Forms.CheckBox
        $chkNetFx.Text = '启用 .NET Framework 3.5（默认启用、可取消；很多老软件需要它）'
        $chkNetFx.Location = New-Object System.Drawing.Point(12, 20)
        $chkNetFx.Size = New-Object System.Drawing.Size(620, 24)
        $chkNetFx.Checked = $true
        $gbOpt.Controls.Add($chkNetFx)

        $lblWu = New-Object System.Windows.Forms.Label
        $lblWu.Text = 'Windows Update 处理方式（影响装好后能否在线搜索驱动）：'
        $lblWu.Location = New-Object System.Drawing.Point(12, 20)
        $lblWu.Size = New-Object System.Drawing.Size(500, 20)
        $gbOpt.Controls.Add($lblWu)

        $rbWuPhysical = New-Object System.Windows.Forms.RadioButton
        $rbWuPhysical.Text = '物理精简（装好后无法在线搜索驱动，且无法完整恢复）'
        $rbWuPhysical.Location = New-Object System.Drawing.Point(24, 44)
        $rbWuPhysical.Size = New-Object System.Drawing.Size(390, 22)
        $gbOpt.Controls.Add($rbWuPhysical)

        $rbWuBlock = New-Object System.Windows.Forms.RadioButton
        $rbWuBlock.Text = '仅屏蔽（默认，可随时恢复）'
        $rbWuBlock.Location = New-Object System.Drawing.Point(420, 44)
        $rbWuBlock.Size = New-Object System.Drawing.Size(212, 22)
        $rbWuBlock.Checked = $true
        $gbOpt.Controls.Add($rbWuBlock)

        $script:GuiDlgChkNetFx = $chkNetFx
        $script:GuiDlgLblWu = $lblWu
        $script:GuiDlgRbWuPhysical = $rbWuPhysical
        $script:GuiDlgRbWuBlock = $rbWuBlock

        # 两个选项各自只在用得上的模式里出现（两者互不重叠，因此不必挪动任何布局）：
        #   .NET Framework 3.5 → 仅一般模式（默认勾选，可取消）
        #   Windows Update     → 仅激进模式（一般模式不涉及）
        $script:GuiDlgOptGroup = $gbOpt
        $script:GuiDlgSyncOptVisibility = {
            $sel = $script:GuiDlgModeRadios | Where-Object { $_.Checked } | Select-Object -First 1
            $isNormal = [bool]($sel -and ([string]$sel.Tag -eq 'normal'))
            if ($script:GuiDlgChkNetFx) { $script:GuiDlgChkNetFx.Visible = $isNormal }
            foreach ($c in @($script:GuiDlgLblWu, $script:GuiDlgRbWuPhysical, $script:GuiDlgRbWuBlock)) {
                if ($c) { $c.Visible = -not $isNormal }
            }
            if ($script:GuiDlgOptGroup) {
                $script:GuiDlgOptGroup.Size = New-Object System.Drawing.Size -ArgumentList @(648, $(if ($isNormal) { 54 } else { 78 }))
            }
        }
        foreach ($rb in $modeRadios) { $rb.Add_CheckedChanged($script:GuiDlgSyncOptVisibility) }

        $y += 94
    } else {
        $lblLiveWarn = New-Object System.Windows.Forms.Label
        $lblLiveWarn.Text = '注意：本操作直接修改当前正在运行的系统，改动立即生效且不可逆；' + [char]13 + [char]10 +
                            '脚本不会创建还原点、也不备份注册表。确认重要数据已有备份后再继续。'
        $lblLiveWarn.ForeColor = [System.Drawing.Color]::Firebrick
        $lblLiveWarn.Location = New-Object System.Drawing.Point -ArgumentList @(20, ($y + 6))
        $lblLiveWarn.Size = New-Object System.Drawing.Size(640, 44)
        $form.Controls.Add($lblLiveWarn)
        $y += 60
    }

    # —— 底部按钮 ——
    $btnStart = New-Object System.Windows.Forms.Button
    $btnStart.Text = $(if ($needIso) { '开始制作 ISO' } else { '开始精简本机' })
    $btnStart.Size = New-Object System.Drawing.Size(150, 32)
    $btnStart.Location = New-Object System.Drawing.Point(376, $y)
    $form.Controls.Add($btnStart)

    $btnBack = New-Object System.Windows.Forms.Button
    $btnBack.Text = '取消'
    $btnBack.Size = New-Object System.Drawing.Size(110, 32)
    $btnBack.Location = New-Object System.Drawing.Point(536, $y)
    $btnBack.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($btnBack)

    $script:GuiDlgNeedIso = $needIso
    # 让「其他选项」里的选项按当前模式就位（默认一般模式 → 只显示 .NET 3.5）
    if ($needIso) { & $script:GuiDlgSyncOptVisibility }

    $btnStart.Add_Click({
        # 这里不设 DialogResult，先校验；通过后再设 OK 让窗口关闭
        if ($script:GuiDlgNeedIso) {
            if (-not $script:GuiDlgIsoLetter) {
                Show-GuiError '请先点击「浏览…」选择 Windows 11 的 ISO 文件。'
                return
            }
            if ($script:GuiDlgCmbScratch.SelectedIndex -lt 0) {
                Show-GuiError '请选择用于存放临时文件与成品的盘符。'
                return
            }
            $sel = $script:GuiDlgScratchLetters[$script:GuiDlgCmbScratch.SelectedIndex]
            try {
                $freeGB = [math]::Round(([System.IO.DriveInfo]::new(($sel + ':'))).AvailableFreeSpace / 1GB, 1)
                if ($freeGB -lt 20) {
                    if (-not (Show-GuiConfirm ("所选盘（{0}:）可用空间只有 {1} GB，制作过程需要 20GB 以上，可能中途失败。`n`n仍要继续吗？" -f $sel, $freeGB))) { return }
                }
            } catch { }
        }
        $script:GuiDlgForm.DialogResult = [System.Windows.Forms.DialogResult]::OK
    })

    $form.AcceptButton = $btnStart
    $form.CancelButton = $btnBack
    return $form
}

function Invoke-GuiParameterCollection {
    # 依次显示两个窗口收集参数。用户取消时返回 $null。
    $taskForm = New-GuiTaskForm
    $taskResult = $taskForm.ShowDialog()
    $picked = $taskForm.RadioButtons | Where-Object { $_.Checked } | Select-Object -First 1
    $taskKey = $(if ($picked) { [string]$picked.Tag } else { 'iso' })
    $taskForm.Dispose()
    if ($taskResult -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $r = @{
        TaskKey     = $taskKey
        Mode        = ''
        IsoPath     = ''
        IsoLetter   = ''
        Scratch     = ''
        ImageIndex  = 0
        NetFx3      = $false
        WUHandling  = ''
    }

    if ($taskKey -ne 'iso' -and $taskKey -ne 'live') { return $r }

    $detailForm = New-GuiDetailForm -TaskKey $taskKey
    $detailResult = $detailForm.ShowDialog()
    if ($detailResult -ne [System.Windows.Forms.DialogResult]::OK) { $detailForm.Dispose(); return $null }

    $mp = $script:GuiDlgModeRadios | Where-Object { $_.Checked } | Select-Object -First 1
    if ($mp) { $r.Mode = [string]$mp.Tag }

    if ($taskKey -eq 'iso') {
        $r.IsoPath = [string]$script:GuiDlgIsoPath
        $r.IsoLetter = [string]$script:GuiDlgIsoLetter
        if ($script:GuiDlgCmbScratch.SelectedIndex -ge 0) {
            $r.Scratch = [string]$script:GuiDlgScratchLetters[$script:GuiDlgCmbScratch.SelectedIndex]
        }
        if ($script:GuiDlgCmbImage.SelectedIndex -ge 0 -and @($script:GuiDlgIndexMap).Count -gt $script:GuiDlgCmbImage.SelectedIndex) {
            $r.ImageIndex = [int]$script:GuiDlgIndexMap[$script:GuiDlgCmbImage.SelectedIndex]
        }
        $r.NetFx3 = [bool]$script:GuiDlgChkNetFx.Checked
        $r.WUHandling = $(if ($script:GuiDlgRbWuBlock.Checked) { 'block' } else { 'physical' })
    }
    $detailForm.Dispose()
    return $r
}

#---------[ 执行前准备 ]---------#
# 权限检查：挂载映像、加载注册表配置单元都需要管理员权限。
# 不做自动提权重启（自动重启会丢失 -ISO/-SCRATCH/-Mode 参数，且新窗口未带
# -ExecutionPolicy Bypass 时会被执行策略直接拦下），改为报错并给出提权方法。
$adminSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
$adminGroup = $adminSID.Translate([System.Security.Principal.NTAccount])
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
if (! $myWindowsPrincipal.IsInRole($adminRole))
{
    Write-Output "错误：本脚本需要管理员权限，当前窗口不是管理员。"
    Write-Output "脚本不会自动提权重启，请手动以管理员身份重新运行："
    Write-Output "  1) 开始菜单搜索 PowerShell 或 Windows Terminal，右键选择「以管理员身份运行」；"
    Write-Output "  2) 在新窗口中执行下面这条命令（可直接复制）："
    Write-Output "     Set-ExecutionPolicy Bypass -Scope Process -Force; & `"$($myInvocation.MyCommand.Definition)`""
    Write-Output "说明：命令里的 -ExecutionPolicy Bypass 不能省 —— 执行策略设置不跨进程继承，新窗口仍可能处于 Restricted。"
    exit 1
}

# 开始记录日志（日志统一放在脚本目录下的 LOG 子目录）
New-Item -ItemType Directory -Force -Path "$PSScriptRoot\LOG" | Out-Null
Start-Transcript -Path "$PSScriptRoot\LOG\tiny11_$(get-date -f yyyyMMdd_HHmmss).log"

$Host.UI.RawUI.WindowTitle = "Tiny11 镜像制作工具 (skydark)"
Clear-Host
Write-Output "本工具基于 tiny11builder修改合并而来，支持多种精简模式。"
Write-Output " "

#---------[ 图形界面模式判定 ]---------#
# 规则（刻意做得简单、可预期）：
#   · 不带任何参数启动（典型场景：双击入口）→ 使用图形界面收集参数；
#   · 带任意参数启动（-ISO / -SCRATCH / -Mode / -NetFx3）→ 沿用命令行问答，行为与以前完全一致。
# 这样不会出现「命令行给了一半参数、窗口又让你重选一次」的别扭情况。
# 判断能否加载 WinForms：加载失败时自动退回命令行问答（例如精简过的系统缺组件），不会卡住用户。
$script:GuiMode = $false
$script:GuiAnswer = $null
$script:GuiTaskInput = ''
$script:GuiImageIndex = 0
$script:GuiWuHandling = ''
$script:GuiMountedByUs = $false
$script:GuiMountedIsoPaths = @()
$hasAnyArg = [bool]($ISO -or $SCRATCH -or $Mode -or $NetFx3)
if (-not $hasAnyArg) {
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        $script:GuiMode = $true
    } catch {
        Write-Output "提示：无法加载图形界面组件，改为在命令行里回答问题（原因：$_）"
        $script:GuiMode = $false
    }
}

#---------[ 第一步：检查上次运行的残留 ]---------#
# 先确认没有另一个本脚本实例在跑：两个实例会争用同一套临时目录、挂载点与配置单元，
# 更危险的是本实例会把对方正在使用的东西当成残留清理掉。
$otherInstance = Get-RunningInstance
if ($otherInstance) {
    Write-Output "错误：检测到本脚本的另一个实例正在运行（进程 PID $($otherInstance.Pid)，启动于 $($otherInstance.Started)）。"
    Write-Output "两个实例会争用同一套临时目录、挂载点与注册表配置单元，因此不能同时运行。"
    Write-Output "处理：切换到那个窗口让它跑完或关掉它，再重新运行本脚本。"
    Stop-AndExit
}
if (-not (Set-RunningLock)) {
    # 走到这里通常是「两个实例几乎同时启动」：上面那次检查时对方还没写锁，加锁时才撞上。
    Write-Output "错误：未能取得单实例锁，判断为本脚本的另一个实例正在运行。"
    Write-Output "两个实例会争用同一套临时目录、挂载点与注册表配置单元，因此不能同时运行。"
    Write-Output "锁文件：$PSScriptRoot\LOG\tiny11.running"
    Write-Output "处理：切换到那个窗口让它跑完或关掉它；若确认没有其它实例在跑，删除上面的锁文件后重试。"
    Stop-AndExit
}

Write-Output "正在检查上次运行的残留..."
$stale = Get-StaleState
# 只有确认是本工具留下的（Ours）才允许清理；其余只报告，避免误删用户自己的同名目录或其它工具的挂载
$cleanHives  = @($stale.Hives)
$cleanMounts = @($stale.Mounts | Where-Object { $_.Ours })
$cleanDirs   = @($stale.Dirs   | Where-Object { $_.Ours })
$skipMounts  = @($stale.Mounts | Where-Object { -not $_.Ours })
$skipDirs    = @($stale.Dirs   | Where-Object { -not $_.Ours })
$cleanCount  = $cleanHives.Count + $cleanMounts.Count + $cleanDirs.Count
$skipCount   = $skipMounts.Count + $skipDirs.Count

if ($cleanCount -eq 0 -and $skipCount -eq 0) {
    Write-Output "未发现上次运行的残留。"
} else {
    Write-Output " "
    if ($cleanCount -gt 0) {
        Write-Output "发现上次运行留下的状态（共 $cleanCount 项），需要先清除："
        if ($cleanHives.Count -gt 0) {
            Write-Output "  · 仍处于加载状态的注册表配置单元："
            foreach ($h in $cleanHives) { Write-Output "      $h" }
        }
        if ($cleanMounts.Count -gt 0) {
            Write-Output "  · 仍处于挂载状态的映像："
            foreach ($m in $cleanMounts) { Write-Output "      $($m.Text)" }
        }
        if ($cleanDirs.Count -gt 0) {
            Write-Output "  · 遗留的临时目录："
            foreach ($d in $cleanDirs) { Write-Output "      $($d.Path)   （$($d.Reason)）" }
        }
        Write-Output " "
        Write-Output "为什么必须清除：残留的挂载会让本次「挂载映像」失败，甚至让脚本操作到上次遗留的映像上；"
        Write-Output "                残留的配置单元会让本次加载同名键失败；临时目录还会占着几十 GB 磁盘空间。"
        Write-Output " "
    }
    if ($skipCount -gt 0) {
        Write-Output "另有 $skipCount 项同名状态，但无法确认是本工具留下的，脚本不会删除（只报告）："
        foreach ($m in $skipMounts) { Write-Output "      · 挂载记录的 WIM 路径不是本工具的布局：$($m.Text)" }
        foreach ($d in $skipDirs) { Write-Output "      · 目录 $($d.Path)   （$($d.Reason)）" }
        Write-Output "      确认无用后请自行手动删除。"
        Write-Output " "
    }

    if ($cleanCount -eq 0) {
        Write-Output "本次没有需要脚本清除的项目，继续后续步骤。"
    } else {
        Write-Output "将要执行：卸载上述配置单元 → 丢弃式卸载上述挂载映像（中止会话的改动一律不保存）→ 必要时结束滞留的 DISM worker → 清理孤儿记录 → 全部终结后才删除上述临时目录。"
        Write-Output "不会动其它任何文件，也不会动上面「只报告」的那些。"
        Write-Output " "
        # 残留清除发生在施工之前，因此图形界面下仍用弹窗确认（与其它施工前的交互一致）。
        if ($script:GuiMode) {
            $cleanConfirm = $(if (Show-GuiConfirm "检测到上次运行留下的残留（明细见前方的控制台窗口）。`n`n必须清除这些残留才能继续，否则本次挂载映像可能失败。`n`n确认清除并继续吗？") { 'Y' } else { 'N' })
        } else {
            $cleanConfirm = Read-Host "确认清除以上残留并继续？(Y/N)（输入其它内容则退出脚本，不做任何改动）"
        }
        if ($cleanConfirm -notmatch '^[Yy]') {
            Write-Output "已取消。脚本未做任何改动，就此退出。"
            Stop-AndExit 0
        }
        Write-Output " "
        Write-Output "正在清除上次运行的残留..."
        $cleaned = Clear-StaleState -Hives $cleanHives -Mounts $cleanMounts -Dirs $cleanDirs
        if (-not $cleaned) {
            Write-Output "仍有无法终结的挂载，脚本就此中止 —— 在脏状态下继续会导致挂载失败或操作到错误的映像上。"
            Write-Output "处理：重启一次（重启会卸载所有挂载映像并释放被占用的配置单元）后重新运行本脚本，届时会自动清理。"
            Stop-AndExit
        }

        Write-Output "正在复核清除结果..."
        $after = Get-StaleState
        $leftCount = @($after.Hives).Count + @($after.Mounts | Where-Object { $_.Ours }).Count + @($after.Dirs | Where-Object { $_.Ours }).Count
        if ($leftCount -eq 0) {
            Write-Output "残留已全部清除，继续后续步骤。"
        } else {
            Write-Output "清除后仍有 $leftCount 项本工具的残留，脚本就此中止 —— 在脏状态下继续会导致挂载失败或操作到错误的映像上。"
            foreach ($h in @($after.Hives)) { Write-Output "      · 仍处于加载状态的配置单元：$h" }
            foreach ($m in @($after.Mounts | Where-Object { $_.Ours })) { Write-Output "      · 仍处于挂载状态的映像：$($m.Text)" }
            foreach ($d in @($after.Dirs | Where-Object { $_.Ours })) { Write-Output "      · 仍存在的临时目录：$($d.Path)" }
            Write-Output "处理：重启一次（可释放被占用的配置单元与挂载资源）后重新运行本脚本。"
            Stop-AndExit
        }
    }
}
Write-Output " "

#---------[ 图形界面：收集参数（在残留清理之后、选择操作对象之前）]---------#
# 顺序刻意放在「残留清理」之后：上次运行的残留无论如何都要先处理完，再让用户做选择。
# 边界：窗口只用于【开头收集参数】，收集完立即关闭；之后的选择、确认、提示、
#       结果展示与异常报警全部在控制台里完成（不再出现任何窗口）。
if ($script:GuiMode) {
    # 以下整段是窗口成功时的参数注入；窗口出错时上面已把界面模式关掉，这段会被跳过
    Write-Output "正在打开操作窗口，请在窗口中完成选择..."
    try {
        $script:GuiAnswer = Invoke-GuiParameterCollection
    } catch {
        # 窗口出任何问题时不让工具彻底不可用：退回命令行问答方式继续（后续 Read-Host 会照常生效）
        Write-Output "错误：操作窗口出现异常，将改用命令行问答方式继续。"
        Write-Output "详细信息：$_"
        try { Show-GuiError ("操作窗口出现异常，将改用命令行问答方式继续。`n`n错误信息：`n{0}`n`n请把这段信息发给维护者。" -f $_) } catch { }
        $script:GuiMode = $false
        $script:GuiAnswer = $null
    }
    if ($script:GuiMode) {
        if (-not $script:GuiAnswer) {
            Write-Output "已在窗口中取消，脚本退出，未做任何改动。"
            Stop-AndExit 0
        }
        # 把窗口选中的任务换算成选单编号：编号 = 该任务在 $script:TaskMenu 中的位置 + 1。
        # 与命令行选单共用同一张表，因此两边的编号必然一致（不再各写一份映射，避免以后改序时漏改）。
        $script:GuiTaskInput = '1'
        for ($ti = 0; $ti -lt $script:TaskMenu.Count; $ti++) {
            if ($script:TaskMenu[$ti].Key -eq $script:GuiAnswer.TaskKey) { $script:GuiTaskInput = [string]($ti + 1); break }
        }
        if ($script:GuiAnswer.Mode) { $Mode = $script:GuiAnswer.Mode }
        if ($script:GuiAnswer.Scratch) { $SCRATCH = $script:GuiAnswer.Scratch }
        if ($script:GuiAnswer.IsoLetter) { $ISO = $script:GuiAnswer.IsoLetter }
        if ($script:GuiAnswer.ImageIndex -gt 0) { $script:GuiImageIndex = [int]$script:GuiAnswer.ImageIndex }
        if ($script:GuiAnswer.NetFx3) { $NetFx3 = $true }
        if ($script:GuiAnswer.WUHandling) { $script:GuiWuHandling = [string]$script:GuiAnswer.WUHandling }
        Write-Output "已在窗口中完成选择，即将开始。"
        Write-Output " "
    }
}

#---------[ 本机 Defender / Windows Update 单独禁用与恢复（选单 4-7 用）]---------#
# 四个任务只操作本机真实注册表与服务（reg.exe 直接读写），不涉及映像与临时目录。
# Start 目标值来自对 26H2 本机的实测官方默认：WinDefend=2、WdNisSvc=3、Sense=3、WdNisDrv=3、WdFilter=0。
function Add-HiddenSettingsPage {
    param ([string]$page)
    # 合并式隐藏：保留 SettingsPageVisibility 中已隐藏的其它设置页，避免两个禁用任务互相覆盖
    $explorerKey = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
    $cur = (Get-ItemProperty -Path "Registry::$explorerKey" -Name SettingsPageVisibility -ErrorAction SilentlyContinue).SettingsPageVisibility
    if ($cur -match '^hide:(.+)$') {
        $list = $Matches[1] -split ';' | Where-Object { $_ -and $_ -ne $page }
        $val = 'hide:' + (($list + $page) -join ';')
    } else {
        $val = "hide:$page"
    }
    & 'reg' 'add' $explorerKey '/v' 'SettingsPageVisibility' '/t' 'REG_SZ' '/d' $val '/f' | Out-Null
    Write-Output "已设置注册表项：$explorerKey\SettingsPageVisibility = $val"
}
function Disable-LocalDefender {
    foreach ($t in 'WinDefend','WdNisSvc','WdNisDrv','WdFilter','Sense') {
        & 'reg' 'add' "HKLM\SYSTEM\CurrentControlSet\Services\$t" '/v' 'Start' '/t' 'REG_DWORD' '/d' '4' '/f' | Out-Null
        Write-Output "已禁用：$t（Start=4）"
    }
    Add-HiddenSettingsPage -page 'virus'
    Write-Output "已隐藏设置中的「病毒和威胁防护」页。"
    foreach ($t in 'WinDefend','WdNisSvc','Sense') {
        Stop-Service -Name $t -Force -ErrorAction SilentlyContinue
    }
    Write-Output "提示：若系统开启了「篡改防护」，上述改动可能被系统自动改回，需先在 Windows 安全中心手动关闭。"
    Write-Output "建议重启一次，确保 Defender 驱动与服务全部按禁用状态卸载。"
}
function Restore-LocalDefender {
    # 恢复为 26H2 实测官方默认值：WinDefend=2、WdNisSvc=3、Sense=3、WdNisDrv=3、WdFilter=0
    $restoreMap = [ordered]@{
        'WinDefend' = 2; 'WdNisSvc' = 3; 'Sense' = 3; 'WdNisDrv' = 3; 'WdFilter' = 0
    }
    foreach ($t in $restoreMap.Keys) {
        & 'reg' 'add' "HKLM\SYSTEM\CurrentControlSet\Services\$t" '/v' 'Start' '/t' 'REG_DWORD' '/d' $restoreMap[$t] '/f' | Out-Null
        Write-Output "已恢复：$t（Start=$($restoreMap[$t])）"
    }
    & 'reg' 'delete' 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' '/v' 'SettingsPageVisibility' '/f' 2>&1 | Out-Null
    Write-Output "已删除注册表值：HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\SettingsPageVisibility"
    Write-Output "已恢复设置页（该值整条删除，「Windows 更新」设置页也会一并恢复）。"
    Write-Output "重启后 Defender 服务与驱动将按官方默认启动类型运行。"
}
function Disable-LocalWindowsUpdate {
    foreach ($t in 'wuauserv','UsoSvc','WaaSMedicSvc','DoSvc') {
        Stop-Service -Name $t -Force -ErrorAction SilentlyContinue
        & 'reg' 'add' "HKLM\SYSTEM\CurrentControlSet\Services\$t" '/v' 'Start' '/t' 'REG_DWORD' '/d' '4' '/f' | Out-Null
        Write-Output "已禁用：$t（Start=4）"
    }
    # 逐条设置并逐条输出：这些策略是「改了什么」的关键证据，需要能按行核对
    $wuPolicies = @(
        @{ Key = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate';    Name = 'DisableWindowsUpdateAccess'; Type = 'REG_DWORD'; Data = '1' },
        @{ Key = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate';    Name = 'WUServer';                   Type = 'REG_SZ';    Data = 'localhost' },
        @{ Key = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate';    Name = 'WUStatusServer';             Type = 'REG_SZ';    Data = 'localhost' },
        @{ Key = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'; Name = 'NoAutoUpdate';               Type = 'REG_DWORD'; Data = '1' },
        @{ Key = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'; Name = 'UseWUServer';                Type = 'REG_DWORD'; Data = '1' }
    )
    foreach ($pol in $wuPolicies) {
        & 'reg' 'add' $pol.Key '/v' $pol.Name '/t' $pol.Type '/d' $pol.Data '/f' | Out-Null
        Write-Output "已设置注册表项：$($pol.Key)\$($pol.Name) = $($pol.Data)"
    }
    Add-HiddenSettingsPage -page 'windowsupdate'
    Write-Output "已隐藏设置中的「Windows 更新」页，并把更新服务器指向 localhost。"
}
function Restore-LocalWindowsUpdate {
    foreach ($t in 'wuauserv','UsoSvc','WaaSMedicSvc','DoSvc') {
        & 'reg' 'add' "HKLM\SYSTEM\CurrentControlSet\Services\$t" '/v' 'Start' '/t' 'REG_DWORD' '/d' '3' '/f' | Out-Null
        Write-Output "已恢复：$t（Start=3，手动）"
        Start-Service -Name $t -ErrorAction SilentlyContinue
    }
    & 'reg' 'delete' 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' '/f' 2>&1 | Out-Null
    Write-Output "已删除注册表项：HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate（整棵子树，含 AU 子键）"
    & 'reg' 'delete' 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' '/v' 'SettingsPageVisibility' '/f' 2>&1 | Out-Null
    Write-Output "已删除注册表值：HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\SettingsPageVisibility"
    foreach ($r in 'StopWUPostOOBE1','StopWUPostOOBE2','StopWUPostOOBE3','DisbaleWUPostOOBE1','DisbaleWUPostOOBE2') {
        # 先探测再删：不存在的项不打日志，避免 5 行噪音盖住真正被清理的内容
        & 'reg' 'query' 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' '/v' $r > $null 2>&1
        if ($LASTEXITCODE -eq 0) {
            & 'reg' 'delete' 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' '/v' $r '/f' 2>&1 | Out-Null
            Write-Output "已删除注册表值：HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce\$r"
        }
    }
    Write-Output "RunOnce 残留检查完毕（不存在的项不列出）。"
    Write-Output "说明：若系统镜像曾以「物理精简」方式构建（UsoSvc / WaaSMedicSVC 服务键不存在），Windows Update 仍无法完整恢复。"
}

#---------[ 垃圾清理（选单 [3] 与精简流程共用）]---------#
# 基准目录 Root：制作 ISO 时为挂载映像目录 $ScratchDir；精简本机时为系统盘（如 C:）。
# 逐项执行、逐项计数；单项失败只累计不中止（沿用本工具「不因个别失败而中断」的一贯做法）。
# 每一项带一个 Id（清单内序号，J01 起）作为日志定位标签；Kind/Paths/Pattern 决定怎么删，

# 从注册表读取字符串值（用于按注册表定位软件安装目录的清理项）。
# 同样使用 reg.exe 而非注册表提供程序，避免在进程内残留 hive 句柄。
function Get-RegValueString {
    param ([string]$key, [string]$name)
    $out = & 'reg' 'query' $key '/v' $name 2>&1
    if ($LASTEXITCODE -ne 0) { return $null }
    foreach ($line in $out) {
        if ($line -match "^\s+\S+\s+REG_\S+\s+(.*)$") { return $Matches[1].Trim() }
    }
    return $null
}

# 读取 DWORD 值（十进制整数）。读不到（键/值不存在，或 reg 失败）返回 $null。
function Get-RegValueDword {
    param ([string]$path, [string]$name)
    $target = Get-TargetRegPath $path
    $s = Get-RegValueString $target $name
    if ($null -eq $s) { return $null }
    $n = 0
    # reg query 对 DWORD 输出十六进制（0x...）；统一按 0x 前缀解析，失败则退回十进制。
    if ($s -match '^0x([0-9a-fA-F]+)$') {
        return [int64][Convert]::ToInt64($Matches[1], 16)
    }
    if ([int64]::TryParse($s, [ref]$n)) { return $n }
    return $null
}

# 按位或写入 DWORD：Attributes |= mask。
# 用途：ShellFolder\Attributes 这类「标志位集合」不能直接赋值（会把其它位清零），
# 必须先读原值再 OR。原值不存在时按 0 起算（等价于直接写 mask）。
function Set-RegistryValueOr {
    param ([string]$path, [string]$name, [int64]$mask)
    if (Test-LiveSkipRegPath $path) {
        Write-Output "（活动系统：跳过只对 OOBE 有意义的项）$path\$name"
        return
    }
    $cur = Get-RegValueDword $path $name
    if ($null -eq $cur) { $cur = 0 }
    $new = $cur -bor $mask
    if ($cur -eq $new) {
        Write-Output "注册表项已含目标位（跳过）：$(Get-TargetRegPath $path)\$name"
        return
    }
    Set-RegistryValue $path $name 'REG_DWORD' ('0x{0:x}' -f $new)
}

# 写服务的 Start=4（禁用）。多数服务键可直接写，但个别键（实测 DPS / TrkWks）在镜像里带
# 独立严格 ACL，reg add 会返回退出码 1。这里做成「先试写、失败则授权重试、仍失败才报失败」：
#   1) 先直接写一次。成功即返回（绝大多数服务走这条快路，且不会平白改动键的 ACL）。
#   2) 失败则用 Grant-RegistryFullAccess 把该键授权给管理员完全控制，再写一次。
#   3) 仍失败才输出失败行（保持与 Set-RegistryValue 一致的日志措辞，便于按行核对）。
# 只在需要时才动 ACL —— 授权会替换键的权限，无必要就不碰。
function Set-ServiceStartValue {
    param ([string]$path, [string]$serviceName)
    if (Test-LiveSkipRegPath $path) {
        Write-Output "（活动系统：跳过只对 OOBE 有意义的项）$path\Start"
        return
    }
    if ($script:LiveMode) {
        # 活动系统：DPS / TrkWks 这两个键带独立严格 ACL，写注册表必被拒；而授权重试（Grant-RegistryFullAccess）
        # 改的是本机真实键的所有者与权限，副作用不可取。故改用 SCM 禁用（以 SYSTEM 操作服务对象，绕过键 ACL）。
        Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
        Set-Service -Name $serviceName -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Output "已禁用服务启动（活动系统）：$serviceName"
        return
    }
    $target = Get-TargetRegPath $path
    & 'reg' 'add' $target '/v' 'Start' '/t' 'REG_DWORD' '/d' '4' '/f' | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Output "服务键带受限 ACL，正在取得所有权后重试：$target"
        if (Grant-RegistryFullAccess $target) {
            & 'reg' 'add' $target '/v' 'Start' '/t' 'REG_DWORD' '/d' '4' '/f' | Out-Null
        }
    }
    if ($LASTEXITCODE -eq 0) {
        Write-Output "已设置注册表项：$target\Start"
        if ($script:LiveMode) { Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue }
    } else {
        Write-Output "设置注册表项失败（reg 退出码 $LASTEXITCODE）：$target\Start"
    }
}

# 带日志的「按注册表定位清理目标」：这类项的目标目录是从注册表读出来的，
# 只报「清理 N 项」用户无法核对清的是哪个目录，因此把定位结果一并写进日志。
# 注意：提示必须走 Write-Host（直写宿主，不进输出流）。若用 Write-Output，
# 这些日志行会与 return $p 一起被当作函数返回值返回，调用方拿到的 $p 就是个数组
# （甚至当注册表无记录时，$p 会变成日志字符串本身，后半段 if ($p) 仍然为真），
# 于是日志文本被当成路径传给 Get-ChildItem，整项清理静默失效。
function Get-JunkPathFromReg {
    param ([string]$Key, [string]$Name)
    $p = Get-RegValueString $Key $Name
    if ($p) {
        Write-Host "      注册表定位：$Key → $p"
    } else {
        Write-Host "      已检查：注册表无记录，本机未安装该软件，跳过：$Key"
    }
    return $p
}

# 删除一个路径目标：Kind 决定语义；路径或模式里可含通配符
#   tree      —— 删除匹配到的项本身
#   contents  —— 删除匹配到的目录里的全部内容（目录本身保留）
#   files     —— 在匹配到的目录里按 Pattern 删文件
#   childdirs —— 在匹配到的目录里按 Pattern 删子目录
function Remove-JunkTarget {
    param ([string]$Root, [string]$Rel, [string]$Kind, [string[]]$Pattern)
    $removed = 0; $failed = 0
    $full = Join-Path $Root $Rel
    $hasWildcard = ($Rel -match '[\*\?]')
    switch ($Kind) {
        'tree' {
            $targets = @(Get-Item -Path $full -Force -ErrorAction SilentlyContinue)
            foreach ($t in $targets) {
                try {
                    Grant-AdminFullAccess $t.FullName -Recurse
                    Remove-Item -LiteralPath $t.FullName -Recurse -Force -ErrorAction Stop
                    $removed++
                } catch { $failed++ }
            }
        }
        'contents' {
            $dirs = if ($hasWildcard) { @(Get-Item -Path $full -Force -ErrorAction SilentlyContinue) }
                    else { @(Get-Item -LiteralPath $full -Force -ErrorAction SilentlyContinue) }
            foreach ($d in $dirs) {
                foreach ($kid in @(Get-ChildItem -LiteralPath $d.FullName -Force -ErrorAction SilentlyContinue)) {
                    try {
                        Remove-Item -LiteralPath $kid.FullName -Recurse -Force -ErrorAction Stop
                        $removed++
                    } catch { $failed++ }
                }
            }
        }
        'files' {
            foreach ($pat in $Pattern) {
                $q = if ($hasWildcard) { Join-Path $full $pat } else { Join-Path $full $pat }
                foreach ($f in @(Get-ChildItem -Path $q -File -Force -ErrorAction SilentlyContinue)) {
                    try { Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop; $removed++ } catch { $failed++ }
                }
            }
        }
        'childdirs' {
            foreach ($pat in $Pattern) {
                $q = Join-Path $full $pat
                foreach ($d in @(Get-ChildItem -Path $q -Directory -Force -ErrorAction SilentlyContinue)) {
                    try {
                        Grant-AdminFullAccess $d.FullName -Recurse
                        Remove-Item -LiteralPath $d.FullName -Recurse -Force -ErrorAction Stop
                        $removed++
                    } catch { $failed++ }
                }
            }
        }
    }
    return @($removed, $failed)
}

# 需要专用命令或需要先按注册表定位路径的清理项。
# 分派依据是清单里的 Action 标签（不是序号）—— 以后增删条目或调整顺序都不必回来改这里。
function Invoke-SpecialJunk {
    param ([string]$Root, [string]$Action)
    $removed = 0; $failed = 0
    switch ($Action) {
        # —— 按注册表定位安装目录，再清其下的旧版本备份目录 ——
        'alibaba-ww' {
            $k = 'HKLM\SOFTWARE\Alibaba\WWLights\EE76A38A6C9E01F42C551FE3BE585C3B'
            $p = Get-JunkPathFromReg $k 'Path'
            if ($p) { $r = Remove-JunkTarget $Root ($p -replace [regex]::Escape($env:SystemDrive), '') 'childdirs' @('*.*.*'); $removed += $r[0]; $failed += $r[1] }
        }
        'alibaba-qt' {
            $k = 'HKLM\SOFTWARE\Alibaba\WWLights\810588CDA60249EB05C110B0DED77CD8'
            $p = Get-JunkPathFromReg $k 'Path'
            if ($p) { $r = Remove-JunkTarget $Root ($p -replace [regex]::Escape($env:SystemDrive), '') 'childdirs' @('*.*.*'); $removed += $r[0]; $failed += $r[1] }
        }
        'chrome' {
            foreach ($k in @('HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe', 'HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe')) {
                $p = Get-JunkPathFromReg $k 'Path'
                if ($p) { $r = Remove-JunkTarget $Root ($p -replace [regex]::Escape($env:SystemDrive), '') 'childdirs' @('*.*.*.*'); $removed += $r[0]; $failed += $r[1] }
            }
        }
        'opera' {
            foreach ($k in @('HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths\opera.exe', 'HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\opera.exe')) {
                $p = Get-JunkPathFromReg $k 'Path'
                if ($p) { $r = Remove-JunkTarget $Root ($p -replace [regex]::Escape($env:SystemDrive), '') 'childdirs' @('*.*.*.*'); $removed += $r[0]; $failed += $r[1] }
            }
        }
        'pplive' {
            $p = Get-JunkPathFromReg 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\PPLive.exe' 'Path'
            if ($p) { $r = Remove-JunkTarget $Root ($p -replace [regex]::Escape($env:SystemDrive), '') 'childdirs' @('*.*.*.*'); $removed += $r[0]; $failed += $r[1] }
        }
        'kugou' {
            $p = Get-JunkPathFromReg 'HKCU\Software\kugou' 'AppPath'
            if ($p) { $r = Remove-JunkTarget $Root ($p -replace [regex]::Escape($env:SystemDrive), '') 'childdirs' @('*.*.*.*'); $removed += $r[0]; $failed += $r[1] }
        }
        '2345pinyin' {
            $p = Get-JunkPathFromReg 'HKLM\SOFTWARE\2345Pinyin' 'Path'
            if ($p) { $r = Remove-JunkTarget $Root ($p -replace [regex]::Escape($env:SystemDrive), '') 'childdirs' @('*.*.*.*'); $removed += $r[0]; $failed += $r[1] }
        }
        'wps' {
            $p = Get-JunkPathFromReg 'HKCU\SOFTWARE\kingsoft\office\6.0\Common' 'InstallRoot'
            if ($p) { $p = Split-Path $p -Parent; $r = Remove-JunkTarget $Root ($p -replace [regex]::Escape($env:SystemDrive), '') 'childdirs' @('*.*.*.*'); $removed += $r[0]; $failed += $r[1] }
        }
        # —— 需要专用命令 ——
        'eventlog' {
            # 事件日志属于运行中的系统：制作 ISO 时镜像里没有日志可清，直接跳过，
            # 否则 wevtutil 会去清宿主机的日志（与目标镜像无关的破坏）。
            if (-not $script:LiveMode) { return @(0, 0) }
            # 清空事件日志（保留 System / Security，避免影响排障与审计）
            foreach ($log in @(& 'wevtutil' 'el' 2>$null)) {
                if ($log -in @('System', 'Security')) { continue }
                & 'wevtutil' 'cl' $log 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) { $removed++ } else { $failed++ }
            }
        }
        'wudatastore' {
            # 清空「更新安装记录」：清 SoftwareDistribution\DataStore 内容
            if ($script:LiveMode) { Stop-Service -Name 'wuauserv' -Force -ErrorAction SilentlyContinue }
            $r = Remove-JunkTarget $Root (Join-Path 'Windows\SoftwareDistribution' 'DataStore') 'contents' @(); $removed += $r[0]; $failed += $r[1]
            if ($script:LiveMode) { Start-Service -Name 'wuauserv' -ErrorAction SilentlyContinue }
        }
        'installer-msp' {
            # Installer 目录：删除未被「已注册补丁」引用的 .msp
            $referenced = @{}
            $patchOut = & 'reg' 'query' 'HKLM\SOFTWARE\Classes\Installer\Patches' '/s' 2>&1
            foreach ($line in $patchOut) { if ($line -match '(.+?\.msp)\s*$') { $referenced[$Matches[1].ToLower()] = $true } }
            # 同样是给用户看的提示，必须走 Write-Host —— 否则会混进 return @($removed, $failed)，
            # 把 $removed 污染成日志字符串，调用方累加时抛「无法转换为 System.Int32」。
            Write-Host "      注册表定位：HKLM\SOFTWARE\Classes\Installer\Patches 下登记补丁 $($referenced.Count) 个（未被登记的 .msp 视为可删）"
            $installerDir = Join-Path $Root 'Windows\Installer'
            foreach ($f in @(Get-ChildItem -LiteralPath $installerDir -Filter '*.msp' -File -Force -ErrorAction SilentlyContinue)) {
                if (-not $referenced.ContainsKey($f.Name.ToLower())) {
                    try { Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop; $removed++ } catch { $failed++ }
                }
            }
        }
        'wudownload' {
            if ($script:LiveMode) { Stop-Service -Name 'wuauserv' -Force -ErrorAction SilentlyContinue }
            $r = Remove-JunkTarget $Root 'Windows\SoftwareDistribution\Download' 'contents' @(); $removed += $r[0]; $failed += $r[1]
            if ($script:LiveMode) { Start-Service -Name 'wuauserv' -ErrorAction SilentlyContinue }
        }
        'delivery-opt' {
            if ($script:LiveMode -and (Get-Command 'Delete-DeliveryOptimizationCache' -ErrorAction SilentlyContinue)) {
                try { Delete-DeliveryOptimizationCache -Force -ErrorAction Stop; $removed++ } catch { $failed++ }
            } else {
                foreach ($rel in @('Windows\SoftwareDistribution\DeliveryOptimization', 'Windows\DeliveryOptimization')) {
                    $r = Remove-JunkTarget $Root $rel 'contents' @(); $removed += $r[0]; $failed += $r[1]
                }
            }
        }
        'wininet-cache'  { if ($script:LiveMode) { & 'RunDll32' 'InetCpl.cpl,ClearMyTracksByProcess' '8' | Out-Null; $removed++ } }
        'wininet-cookie' { if ($script:LiveMode) { & 'RunDll32' 'InetCpl.cpl,ClearMyTracksByProcess' '2' | Out-Null; $removed++ } }
        'recyclebin'     { if ($script:LiveMode) { try { Clear-RecycleBin -Force -ErrorAction Stop; $removed++ } catch { $failed++ } } }
    }
    return @($removed, $failed)
}

# 清理清单：Id 只用作日志里的定位标签，与任何外部工具的编号无关。顺序即编号递进。
# 条目顺序按「系统级大件 → 缓存/日志 → 第三方软件 → 专项」排列。
# Kind=special 的条目由 Invoke-SpecialJunk 按 Action 标签分派（需要专用命令或先按注册表定位）。
$script:JunkItems = @(
    @{ Id = 'J01'; Name = '以前的Windows系统'; Kind = 'tree'; Paths = @('Windows.old') },
    @{ Id = 'J02'; Name = 'Windows临时安装文件'; Kind = 'tree'; Paths = @('$Windows.~BT', '$Windows.~WS', '$Windows.~LS') },
    @{ Id = 'J03'; Name = 'Installer基线缓存'; Kind = 'tree'; Paths = @('Windows\Installer\$PatchCache$') },
    @{ Id = 'J04'; Name = '最后一次正确配置'; Kind = 'tree'; Paths = @('Windows\lastgood', 'Windows\lastgood.tmp') },
    @{ Id = 'J05'; Name = 'Boot备份信息'; Kind = 'tree'; Paths = @('Windows\pss') },
    @{ Id = 'J06'; Name = '崩溃转储文件'; Kind = 'files'; Paths = @('Windows'); Pattern = @('MEMORY.DMP') },
    @{ Id = 'J07'; Name = '崩溃转储文件（小型转储）'; Kind = 'tree'; Paths = @('Windows\Minidump', 'Users\*\AppData\Local\CrashDumps') },
    @{ Id = 'J08'; Name = 'WinSxS临时文件'; Kind = 'contents'; Paths = @('Windows\WinSxS\Temp') },
    @{ Id = 'J09'; Name = '临时文件'; Kind = 'contents'; Paths = @('Windows\Temp', 'Users\*\AppData\Local\Temp') },
    @{ Id = 'J10'; Name = 'Windows日志'; Kind = 'files'; Paths = @('Windows', 'Windows\Performance\WinSAT', 'Windows\Panther', 'Users\*\AppData\Local\Microsoft\Windows', 'Users\*\AppData\Roaming\Microsoft\Windows', 'Users\*\AppData\Local\MigWiz'); Pattern = @('*.log', '*.bak', '*log.txt', 'SchedLgU.txt') },
    @{ Id = 'J11'; Name = 'Windows预读取文件'; Kind = 'files'; Paths = @('Windows\Prefetch'); Pattern = @('*.pf') },
    @{ Id = 'J12'; Name = '缩略图与图标缓存'; Kind = 'files'; Paths = @('Users\*\AppData\Local\Microsoft\Windows\Explorer'); Pattern = @('thumbcache_*.db', 'iconcache_*.db') },
    @{ Id = 'J13'; Name = 'Windows报告'; Kind = 'contents'; Paths = @('ProgramData\Microsoft\Windows\WER\ReportQueue', 'ProgramData\Microsoft\Windows\WER\ReportArchive', 'ProgramData\Microsoft\Windows\WER\ReportHistory', 'Users\*\AppData\Local\Microsoft\Windows\WER') },
    @{ Id = 'J14'; Name = 'Package Cache目录'; Kind = 'contents'; Paths = @('ProgramData\Package Cache') },
    @{ Id = 'J15'; Name = 'Appx缓存文件'; Kind = 'contents'; Paths = @('Users\*\AppData\Local\Packages\*\AC', 'Users\*\AppData\Local\Packages\*\LocalCache', 'Users\*\AppData\Local\Packages\*\TempState') },
    @{ Id = 'J16'; Name = 'NET程序集缓存'; Kind = 'contents'; Paths = @('Windows\assembly\NativeImages_v*') },
    @{ Id = 'J17'; Name = '零售演示离线内容'; Kind = 'contents'; Paths = @('ProgramData\Microsoft\Windows\RetailDemo') },
    @{ Id = 'J18'; Name = 'Defender保护历史记录'; Kind = 'contents'; Paths = @('ProgramData\Microsoft\Windows Defender\Scans\History') },
    @{ Id = 'J19'; Name = '微软系安软无用文件'; Kind = 'files'; Paths = @('ProgramData\Microsoft\Windows Defender\Support', 'ProgramData\Microsoft\Microsoft Antimalware\Support'); Pattern = @('*.log', '*.etl') },
    @{ Id = 'J20'; Name = 'Terminal Server Client缓存'; Kind = 'contents'; Paths = @('Users\*\AppData\Local\Microsoft\Terminal Server Client\Cache') },
    @{ Id = 'J21'; Name = '常见的驱动临时解压目录'; Kind = 'tree'; Paths = @('AMD', 'Intel', 'NVIDIA', 'Prog') },
    @{ Id = 'J22'; Name = 'NuGet包缓存'; Kind = 'tree'; Paths = @('Users\*\.nuget', 'Users\*\AppData\Local\NuGet\v3-cache') },
    @{ Id = 'J23'; Name = 'XDE缓存文件'; Kind = 'tree'; Paths = @('ProgramData\Microsoft\XDE') },
    @{ Id = 'J24'; Name = 'PDB缓存文件'; Kind = 'tree'; Paths = @('Users\*\AppData\Local\DBG') },
    @{ Id = 'J25'; Name = 'WebPI缓存'; Kind = 'tree'; Paths = @('Users\*\AppData\Local\Microsoft\Web Platform Installer') },
    @{ Id = 'J26'; Name = 'Visual Studio智能跟踪'; Kind = 'tree'; Paths = @('ProgramData\Microsoft Visual Studio\10.0\TraceDebugging') },
    @{ Id = 'J27'; Name = 'Visual Studio安装源缓存'; Kind = 'contents'; Paths = @('ProgramData\Microsoft\VisualStudio\Packages') },
    @{ Id = 'J28'; Name = 'Visual Studio日志'; Kind = 'files'; Paths = @('ProgramData\Microsoft\VisualStudio'); Pattern = @('*.log') },
    @{ Id = 'J29'; Name = '瑞昱声卡驱动安装源缓存'; Kind = 'contents'; Paths = @('Program Files\Realtek\Audio') },
    @{ Id = 'J30'; Name = 'Intel驱动安装源缓存'; Kind = 'tree'; Paths = @('ProgramData\Intel\Package Cache') },
    @{ Id = 'J31'; Name = '英伟达驱动安装源缓存'; Kind = 'contents'; Paths = @('Program Files\NVIDIA Corporation\Installer2') },
    @{ Id = 'J32'; Name = '英伟达驱动安装包'; Kind = 'tree'; Paths = @('ProgramData\NVIDIA Corporation\Downloader') },
    @{ Id = 'J33'; Name = '.NET安装缓存'; Kind = 'tree'; Paths = @('Program Files\Microsoft.NET\Multi-Targeting Pack\*\SetupCache', 'Program Files (x86)\Microsoft.NET\Multi-Targeting Pack\*\SetupCache') },
    @{ Id = 'J34'; Name = 'Adobe Acrobat安装源缓存'; Kind = 'tree'; Paths = @('Program Files (x86)\Adobe\Acrobat DC\Setup Files') },
    @{ Id = 'J35'; Name = 'SQL Server更新缓存'; Kind = 'childdirs'; Paths = @('Program Files\Microsoft SQL Server\*\Setup Bootstrap', 'Program Files (x86)\Microsoft SQL Server\*\Setup Bootstrap', 'Program Files\Microsoft SQL Server\*\Setup Bootstrap\Log', 'Program Files (x86)\Microsoft SQL Server\*\Setup Bootstrap\Log'); Pattern = @('Update Cache', 'SQLServer2008R2') },
    @{ Id = 'J36'; Name = 'Office安装源'; Kind = 'tree'; Paths = @('MSOCache') },
    @{ Id = 'J37'; Name = 'Office 365/2016安装源'; Kind = 'contents'; Paths = @('ProgramData\Microsoft\ClickToRun') },
    @{ Id = 'J38'; Name = 'Java安装源缓存'; Kind = 'childdirs'; Paths = @('Users\*\AppData\Roaming\Oracle\Java'); Pattern = @('jre*', 'installcache', 'tmpinstall') },
    @{ Id = 'J39'; Name = '微软拼音安装文件'; Kind = 'tree'; Paths = @('Users\*\AppData\LocalLow\KunlunInput') },
    @{ Id = 'J40'; Name = 'QQ临时数据'; Kind = 'tree'; Paths = @('Users\*\AppData\Roaming\Tencent\AndroidAssist', 'Users\*\AppData\Roaming\Tencent\AndroidServer', 'Users\*\AppData\Roaming\Tencent\Logs', 'Users\*\AppData\Roaming\Tencent\TXSSO\SetupLogs', 'Users\*\AppData\Roaming\Tencent\TXSSO\SSOTemp') },
    @{ Id = 'J41'; Name = '腾讯相关软件下载目录'; Kind = 'tree'; Paths = @('ProgramData\temp') },
    @{ Id = 'J42'; Name = 'YY临时文件'; Kind = 'tree'; Paths = @('Users\*\AppData\Roaming\duowan\yy\log', 'Users\*\AppData\Roaming\duowan\yy\Cache') },
    @{ Id = 'J43'; Name = '百度网盘日志'; Kind = 'tree'; Paths = @('Users\*\AppData\Roaming\BaiduYunKernel\Data', 'Users\*\AppData\Roaming\BaiduYunGuanjia\logs') },
    @{ Id = 'J44'; Name = '飞信日志'; Kind = 'tree'; Paths = @('Users\*\AppData\Roaming\FetionV5') },
    @{ Id = 'J45'; Name = 'IDM临时文件'; Kind = 'tree'; Paths = @('Users\*\AppData\Roaming\IDM\DwnlData') },
    @{ Id = 'J46'; Name = '360浏览器老版本备份'; Kind = 'childdirs'; Paths = @('Users\*\AppData\Roaming\360se6\Application'); Pattern = @('*.*.*.*') },
    @{ Id = 'J47'; Name = '小红伞临时文件'; Kind = 'childdirs'; Paths = @('ProgramData\Avira\*'); Pattern = @('TEMP', 'BACKUP') },
    @{ Id = 'J48'; Name = '阿里旺旺老版本备份'; Kind = 'special'; Action = 'alibaba-ww' },
    @{ Id = 'J49'; Name = '阿里亲淘老版本备份'; Kind = 'special'; Action = 'alibaba-qt' },
    @{ Id = 'J50'; Name = 'Chrome老版本备份'; Kind = 'special'; Action = 'chrome' },
    @{ Id = 'J51'; Name = 'Opera老版本备份'; Kind = 'special'; Action = 'opera' },
    @{ Id = 'J52'; Name = 'PPLive老版本备份'; Kind = 'special'; Action = 'pplive' },
    @{ Id = 'J53'; Name = '酷狗音乐老版本备份'; Kind = 'special'; Action = 'kugou' },
    @{ Id = 'J54'; Name = '2345拼音输入法老版本备份'; Kind = 'special'; Action = '2345pinyin' },
    @{ Id = 'J55'; Name = 'WPS老版本备份'; Kind = 'special'; Action = 'wps' },
    @{ Id = 'J56'; Name = 'Windows事件日志'; Kind = 'special'; Action = 'eventlog' },
    @{ Id = 'J57'; Name = 'Windows更新安装记录'; Kind = 'special'; Action = 'wudatastore' },
    @{ Id = 'J58'; Name = 'Installer目录（被取代的补丁）'; Kind = 'special'; Action = 'installer-msp' },
    @{ Id = 'J59'; Name = 'Windows下载缓存'; Kind = 'special'; Action = 'wudownload' },
    @{ Id = 'J60'; Name = '传递优化缓存'; Kind = 'special'; Action = 'delivery-opt' },
    @{ Id = 'J61'; Name = 'WinINet网页缓存'; Kind = 'special'; Action = 'wininet-cache' },
    @{ Id = 'J62'; Name = 'WinINet Cookies'; Kind = 'special'; Action = 'wininet-cookie' },
    @{ Id = 'J63'; Name = '回收站'; Kind = 'special'; Action = 'recyclebin' }
)

function Invoke-JunkCleanup {
    param ([string]$Root)
    if (-not (Test-Path -LiteralPath $Root)) {
        Write-Output "基准目录不存在，跳过垃圾清理：$Root"
        return
    }
    Write-Output "正在清理垃圾文件（基准目录：$Root）..."
    $sumRemoved = 0; $sumFailed = 0
    foreach ($item in $script:JunkItems) {
        $removed = 0; $failed = 0
        if ($item.Kind -eq 'special') {
            $r = Invoke-SpecialJunk $Root $item.Action
            $removed = $r[0]; $failed = $r[1]
        } else {
            foreach ($rel in $item.Paths) {
                $pat = if ($item.ContainsKey('Pattern')) { $item.Pattern } else { @() }
                $r = Remove-JunkTarget $Root $rel $item.Kind $pat
                $removed += $r[0]; $failed += $r[1]
            }
        }
        $sumRemoved += $removed; $sumFailed += $failed
        Write-Output ("  [{0}] {1}：清理 {2} 项{3}" -f $item.Id, $item.Name, $removed, $(if ($failed -gt 0) { "（失败 $failed 项）" } else { "" }))
    }
    Write-Output "垃圾清理完成：共清理 $sumRemoved 项，失败 $sumFailed 项。"
}

Write-Output "第一步：请选择操作对象（输入数字或名称）："
# 选单由 $script:TaskMenu 生成 —— 与图形界面窗口同一张表、同一顺序
$menuNo = 0
foreach ($menuItem in $script:TaskMenu) {
    $menuNo++
    Write-Output "  [$menuNo] $($menuItem.Title)$($menuItem.TitleNote)"
    foreach ($descLine in $menuItem.CliDesc) { Write-Output "      $descLine" }
    Write-Output " "
}
$targetInput = $(if ($script:GuiMode) { $script:GuiTaskInput } else { Read-Host "请输入 1-7（1 = 制作 ISO，2 = 精简当前系统，3 = 清理垃圾文件，4-7 = 本机 Defender / Windows Update 的禁用与恢复；直接回车 = 1）" })

# 解析选择：纯数字按表内位置取任务，中文数字（一~七）与关键词按 CliMatch 识别，无法识别时按第 1 项处理。
$script:TaskType = $null
$cnNumber = @{ '一' = 1; '二' = 2; '三' = 3; '四' = 4; '五' = 5; '六' = 6; '七' = 7 }
$pickIndex = 0
if ([string]::IsNullOrWhiteSpace($targetInput)) {
    $pickIndex = 1
} elseif ($targetInput -match '^\s*([1-7])\s*$') {
    $pickIndex = [int]$Matches[1]
} elseif ($cnNumber.ContainsKey($targetInput.Trim())) {
    $pickIndex = $cnNumber[$targetInput.Trim()]
}
if ($pickIndex -ge 1 -and $pickIndex -le $script:TaskMenu.Count) {
    $script:TaskType = $script:TaskMenu[$pickIndex - 1].Key
} else {
    foreach ($menuItem in $script:TaskMenu) {
        if ($targetInput -match $menuItem.CliMatch) { $script:TaskType = $menuItem.Key; break }
    }
    if (-not $script:TaskType) { $script:TaskType = $script:TaskMenu[0].Key }
}

if ($script:TaskType -in @('disable-defender', 'restore-defender', 'disable-wu', 'restore-wu', 'clean-junk')) {
    # 独立小任务：执行后直接收尾退出，不进入精简主管线（无需临时盘 / ISO / 残留清理之外的任何交互）
    switch ($script:TaskType) {
        'disable-defender' { Write-Output "已选择：【禁用本机系统的 Windows Defender】"; Disable-LocalDefender }
        'restore-defender' { Write-Output "已选择：【恢复本机系统的 Windows Defender】"; Restore-LocalDefender }
        'disable-wu'       { Write-Output "已选择：【禁用本机系统的 Windows Update】"; Disable-LocalWindowsUpdate }
        'restore-wu'       { Write-Output "已选择：【恢复本机系统的 Windows Update】"; Restore-LocalWindowsUpdate }
        'clean-junk'       { Write-Output "已选择：【清理本机垃圾文件】"; Invoke-JunkCleanup -Root $env:SystemDrive }
    }
    Write-Output " "
    Stop-AndExit 0 -Reason "所选操作已完成。日志保存在：$PSScriptRoot\LOG"
}
$script:LiveMode = ($script:TaskType -eq 'live')
if ($script:LiveMode) {
    Write-Output "已选择：【精简当前正在使用的系统】"
} else {
    Write-Output "已选择：【制作全新的精简 ISO】"
}
Write-Output " "
Write-Output "第二步：请选择精简模式（输入数字或名称）："
Write-Output "  [1] 一般模式（推荐，可维护）"
Write-Output "      删除 Xbox / Clipchamp / 邮件日历 / Teams / Copilot / OneDrive 等预装应用与组件，"
Write-Output "      并关闭广告、遥测、跳过硬件与微软账号检查。"
Write-Output "      装完仍可打补丁、加语言、加功能。适合日常装机。"
Write-Output " "
Write-Output "  [2] 激进模式（最小系统）"
Write-Output "      在一般模式基础上，彻底移除 Microsoft Edge（含 Edge、EdgeUpdate、EdgeCore、Microsoft-Edge-Webview 等组件）、"
Write-Output "      精简重建 WinSxS 组件存储、禁用 Windows Defender、禁用 Windows Update，"
Write-Output "      并裁剪打印 / 扫描 / 传真 / 摄像头驱动（保留 Spooler，打印成 PDF 不受影响；"
Write-Output "      手机 USB 传文件保留），同时精简极少使用的外语字体"
Write-Output "      （蒙古文 / 藏文 / 缅甸文 / 印度语系等，其余字体一概保留）。"
Write-Output "      制作 ISO 时会询问 Windows Update 的处理方式：物理精简（无法完整恢复）或仅屏蔽（可恢复）。"
Write-Output "      系统最小，但装完无法再加语言、打补丁、加功能。"
Write-Output "      注意：此模式会移除 Edge，请勿在需要使用浏览器的环境使用。"
Write-Output " "
Write-Output "  [3] 激进模式（保留 Edge）"
Write-Output "      与激进模式相同（精简重建 WinSxS、禁用 Defender / Windows Update；外设驱动与扩展字体同样裁剪），"
Write-Output "      但保留 Microsoft Edge 及其组件与注册表，浏览器仍可正常使用。"
Write-Output "      仍属最小系统，装完无法再加语言、打补丁、加功能。"
Write-Output " "
if ($Mode) {
    switch -Regex ($Mode) {
        '^[3三]$|激进保留edge|激进.*保留|aggressive.*keep|keepedge' { $Mode = 'aggressive_keepedge' }
        '^[2二]$|激进|aggressive' { $Mode = 'aggressive' }
        default { $Mode = 'normal' }
    }
} else {
    $modeInput = Read-Host "请输入 1 / 2 / 3（也可输入 一般 / 激进 / 激进保留edge）"
    switch -Regex ($modeInput) {
        '^[3三]$|激进保留edge|激进.*保留|aggressive.*keep|keepedge' { $Mode = 'aggressive_keepedge' }
        '^[2二]$|激进|aggressive' { $Mode = 'aggressive' }
        default { $Mode = 'normal' }
    }
}
if ($Mode -eq 'aggressive') {
    Write-Output "已选择：【激进模式】"
} elseif ($Mode -eq 'aggressive_keepedge') {
    Write-Output "已选择：【激进模式（保留 Edge）】"
} else {
    Write-Output "已选择：【一般模式】"
}
# 派生布尔量：是否执行激进核心动作（WinSxS / Update / Defender）、是否移除 Edge
$aggressiveCore = ($Mode -in @('aggressive', 'aggressive_keepedge'))
$removeEdge = ($Mode -eq 'aggressive')
# Windows Update 处理方式（默认仅屏蔽；制作 ISO 的两种激进模式会在确认前询问用户）
$script:WUHandling = 'block'
Write-Output " "

$hostArchitecture = $Env:PROCESSOR_ARCHITECTURE

# ===== 活动系统：只需一次确认，之后全程无人值守 =====
if ($script:LiveMode) {
    if ($NetFx3) {
        Write-Output "提示：-NetFx3 仅对「制作 ISO」生效（启用 .NET 3.5 需要 ISO 内的 sources\sxs 安装源），本次精简当前系统将忽略该参数。"
    }
    Write-Output "即将对【当前正在使用的系统】执行上述精简。"
    Write-Output "提示：本操作不可逆，脚本不会自动创建还原点、也不备份注册表，需要的话请先自行处理。"
    if ($aggressiveCore) {
        Write-Output "      过程中会停用 Windows Update 与 Defender；若系统开启了「篡改防护」，Defender 的相关"
        Write-Output "      改动可能被系统自动改回（需要先在 Windows 安全中心手动关闭篡改防护）。"
    }
    Write-Output " "
    # 与「制作 ISO」的最终确认一致：发生在真正开始施工之前，属参数/意图确认阶段，
    # 图形界面下走弹窗，命令行下走问答。
    $confirm = $(if ($script:GuiMode) { $(if (Show-GuiConfirm "即将对【当前正在使用的系统】执行精简。`n`n此操作不可逆：脚本不会创建还原点、也不备份注册表，改动立即生效。`n`n确认开始吗？") { 'Y' } else { 'N' }) } else { Read-Host "确认对当前系统执行精简？(Y/N)（确认后一路自动执行到结束，中途不再需要按键）" })
    if ($confirm -notmatch '^[Yy]') {
        Write-Output "已取消，脚本退出。"
        Stop-AndExit 0
    }
    Write-Output " "
}

# ===== 制作 ISO：确保应答文件存在，并一次性收集临时盘 / ISO 盘符 / 映像索引，最后确认 =====
if (-not $script:LiveMode) {
    # 若同目录没有 autounattend.xml，则从本项目仓库联网获取（跳过微软账号登录 + /compact 部署）
    if (-not (Test-Path -Path "$PSScriptRoot/autounattend.xml")) {
        Write-Output "本地缺少 autounattend.xml，正在从本项目仓库下载..."
        try {
            Invoke-RestMethod "https://raw.githubusercontent.com/skydark-litth/ps1.tiny11builder/main/autounattend.xml" -OutFile "$PSScriptRoot/autounattend.xml" -ErrorAction Stop
        } catch {
            Write-Output "下载 autounattend.xml 失败：$_"
            Write-Output "该文件负责跳过微软账号登录并创建本地账户，缺失会让做出来的镜像失去这些能力，因此不再继续。"
            Write-Output "处理：确认网络可用后重试，或手动把 autounattend.xml 放到脚本目录 $PSScriptRoot 下再运行。"
            Stop-AndExit
        }
    }
    if (-not (Test-Path -Path "$PSScriptRoot\autounattend.xml")) {
        Write-Output "autounattend.xml 仍不存在，脚本不再继续。"
        Write-Output "处理：手动把 autounattend.xml 放到脚本目录 $PSScriptRoot 下再运行。"
        Stop-AndExit
    }

    # 解析临时盘（SCRATCH）：未通过参数指定时交互输入，默认使用脚本所在盘
    if (-not $SCRATCH) {
        $defaultScratch = $PSScriptRoot -replace '[\\]+$', ''
        $scratchInput = Read-Host "请输入临时文件与最终 ISO 所在盘符（需预留 20GB+ 空闲，直接回车使用 $defaultScratch）"
        if ($scratchInput -match '^[c-zC-Z]$') {
            $ScratchDisk = $scratchInput + ":"
        } else {
            $ScratchDisk = $defaultScratch
        }
    } else {
        $ScratchDisk = $SCRATCH + ":"
    }

    # 临时目录全部落在 <临时盘>\temp\ 容器下（见文件开头的「临时目录布局」说明）
    $ScratchRoot = Join-Path $ScratchDisk $script:ScratchContainer
    $ExtractDir  = Join-Path $ScratchRoot 'tiny11'
    $ScratchDir  = Join-Path $ScratchRoot 'scratchdir'

    New-Item -ItemType Directory -Force -Path (Join-Path $ExtractDir 'sources') | Out-Null

    # 输入并校验 ISO 盘符
    do {
        if (-not $ISO) {
            $DriveLetter = Read-Host "请输入已挂载的 Windows 11 ISO 盘符（如 E）"
        } else {
            $DriveLetter = $ISO
        }
        if ($DriveLetter -match '^[c-zC-Z]$') {
            $DriveLetter = $DriveLetter + ":"
            Write-Output "已设置 ISO 盘符为 $DriveLetter"
        } else {
            Write-Output "盘符无效，请输入 C 到 Z 之间的字母。"
            # 界面模式下不能循环等键盘输入（盘符来自自动装载，正常情况下不会走到这里）
            if ($script:GuiMode) {
                Write-Output "错误：界面提供的 ISO 盘符无法使用，请重新运行本工具并重新选择 ISO 文件。"
                Stop-AndExit
            }
        }
    } while ($DriveLetter -notmatch '^[c-zC-Z]:$')

    # —— 到此把需要用户输入的项目一次性收齐；确认之后全程无人值守，不再有任何等待输入的环节 ——

    # 校验 ISO 内容
    $isoInstallWim = "$DriveLetter\sources\install.wim"
    $isoInstallEsd = "$DriveLetter\sources\install.esd"
    if ((-not (Test-Path "$DriveLetter\sources\boot.wim")) -or ((-not (Test-Path $isoInstallWim)) -and (-not (Test-Path $isoInstallEsd)))) {
        Write-Output "在指定盘符下找不到 Windows 安装文件。"
        Write-Output "需要 $DriveLetter\sources\boot.wim，以及 install.wim 或 install.esd。"
        Write-Output "请输入正确的 DVD / 虚拟光驱盘符后重新运行。"
        Stop-AndExit
    }

    # 选定映像索引：直接读 ISO 上的 install.wim / install.esd，无需先复制到临时目录
    $isoImageSource = if (Test-Path $isoInstallWim) { $isoInstallWim } else { $isoInstallEsd }
    Write-Output " "
    Write-Output "ISO 中可用的映像版本："
    $isoImages = Get-WindowsImage -ImagePath $isoImageSource
    $isoImages
    $availableIndexes = $isoImages.ImageIndex
    $index = 0
    if ($script:GuiMode -and $script:GuiImageIndex -gt 0 -and ($availableIndexes -contains $script:GuiImageIndex)) {
        $index = [int]$script:GuiImageIndex
        Write-Output "已按界面选择映像索引：$index"
    }
    while ($availableIndexes -notcontains $index) {
        if ($script:GuiMode) {
            # 界面模式下不能停下来等键盘输入：界面给的索引若有问题，自动改用第一个可用索引
            $index = @($availableIndexes)[0]
            Write-Output "界面提供的索引不可用，已自动选择第一个可用索引：$index"
            if ($availableIndexes -notcontains $index) {
                Write-Output "错误：镜像里没有可用的映像索引，无法继续。"
                Stop-AndExit
            }
            break
        }
        $indexInput = Read-Host "请输入要精简的映像索引（上表中最左侧的编号）"
        $index = 0
        if ($indexInput -match '^\d+$') { $index = [int]$indexInput }
        if ($availableIndexes -notcontains $index) {
            Write-Output "索引无效，可用索引：$($availableIndexes -join ' / ')"
        }
    }
    Write-Output "已选择映像索引：$index"
    # 捕获所选映像的版本名（如「Windows 11 专业版」），映射为英文用于 ISO 文件名
    # （家庭版=Home、教育版=Education、专业版=Professional、企业版=Enterprise、
    #   专业教育版/专业工作站版=ProfessionalEducation/ProfessionalWorkstation，
    #   无法识别时回退 Consumer）。映射顺序刻意从长到短，避免「专业版」抢先命中「专业教育版」。
    $selectedImageName = ([string]($isoImages | Where-Object { $_.ImageIndex -eq $index }).ImageName).Trim()
    $editionPatterns = [ordered]@{
        '*专业工作站版*'         = 'ProfessionalWorkstation'
        '*专业教育版*'           = 'ProfessionalEducation'
        '*专业版*'               = 'Professional'
        '*企业版*'               = 'Enterprise'
        '*教育版*'               = 'Education'
        '*家庭中文版*'           = 'HomeChina'
        '*家庭单语言版*'         = 'HomeSingleLanguage'
        '*家庭版*'               = 'Home'
        '*Pro for Workstations*' = 'ProfessionalWorkstation'
        '*Pro Education*'        = 'ProfessionalEducation'
        '*Enterprise G*'         = 'EnterpriseG'
        '*Enterprise*'           = 'Enterprise'
        '*Education*'            = 'Education'
        '*Home Single Language*' = 'HomeSingleLanguage'
        '*Home China*'           = 'HomeChina'
        '*Home*'                 = 'Home'
        '*Consumer*'             = 'Consumer'
        '*Business*'             = 'Business'
    }
    $script:OSEdition = 'Consumer'
    foreach ($ep in $editionPatterns.Keys) {
        if ($selectedImageName -like $ep) { $script:OSEdition = $editionPatterns[$ep]; break }
    }
    Write-Output "已识别版本：$script:OSEdition（$selectedImageName）"

    # 是否启用 .NET Framework 3.5：镜像做好之后无法再补装，必须现在决定。
    # 按「确认后全程无人值守」的约定，此问收集在最终确认之前。
    # 激进模式不启用：功能启用会给镜像留下「挂起操作」（挡 /ResetBase），而激进模式要整体重建
    # WinSxS、保留清单也不含 .NET 3.5 的组件负载，两者不兼容，强做需要赌挂起事务能跨重建存活。
    if ($aggressiveCore) {
        if ($NetFx3) {
            Write-Output "提示：-NetFx3 在激进模式下不可用（WinSxS 白名单重建会清掉 .NET 3.5 组件负载），本次不启用；需要 .NET 3.5 请用一般模式。"
        }
        $enableNetFx3 = $false
    } elseif ($NetFx3) {
        $enableNetFx3 = $true
        Write-Output "已通过 -NetFx3 参数指定：启用 .NET Framework 3.5。"
    } elseif ($script:GuiMode) {
        # 界面模式下不能停下来等键盘：以窗口里的复选框为准（窗口里默认已勾选「启用」）
        $enableNetFx3 = $false
        Write-Output "已按界面选择：不启用 .NET Framework 3.5。"
    } else {
        $netfxInput = Read-Host "是否启用 .NET Framework 3.5？（镜像做好后无法再启用；Y/N，直接回车 = 启用）"
        $enableNetFx3 = ($netfxInput -notmatch '^[Nn]')
    }
    if ($aggressiveCore) {
        Write-Output "激进模式不启用 .NET Framework 3.5。"
    } elseif ($enableNetFx3) {
        Write-Output "将在构建时启用 .NET Framework 3.5（在组件存储压缩之后执行）。"
    } else {
        Write-Output "不启用 .NET Framework 3.5。"
    }

    # Windows Update 处理方式（两种激进模式、仅制作 ISO 时询问）：物理精简 or 仅屏蔽。
    # 物理精简 = 删除 UsoSvc / WaaSMedicSVC 服务键：装好的系统无法使用 Windows
    #            自动在线搜索驱动，且无法完整恢复。
    # 仅屏蔽   = 不删任何服务键，只禁用服务（含传递优化 DoSvc）并屏蔽更新策略：
    #            装好后可按 README《解除禁用》章节随时恢复或再次屏蔽。
    # 默认值 = 仅屏蔽（更安全、可恢复）；静默传参（-Mode）不询问时也走这个默认值。
    if ($aggressiveCore) {
        Write-Output " "
        Write-Output "Windows Update 处理方式（影响装好后的系统能否使用 Windows 自动在线搜索驱动）："
        Write-Output "  1 = 物理精简：删除 Windows Update 编排服务键（UsoSvc / WaaSMedicSVC），无法完整恢复。"
        Write-Output " "
        Write-Output "  2 = 仅屏蔽  ：不删服务键，只禁用服务（含传递优化）并屏蔽更新策略，可随时恢复。（默认）"
        Write-Output " "
        $wuInput = $(if ($script:GuiMode -and $script:GuiWuHandling) { '' } else { Read-Host "请选择 Windows Update 处理方式（1/2，直接回车 = 2 仅屏蔽）" })
        if ($script:GuiMode -and $script:GuiWuHandling) {
            $script:WUHandling = [string]$script:GuiWuHandling
            Write-Output "已按界面选择的处理方式执行：$($script:WUHandling)。"
        } else {
            switch -Regex ($wuInput) {
                '^[1一]$|物理|physical' { $script:WUHandling = 'physical' }
                default { $script:WUHandling = 'block' }
            }
        }
        if ($script:WUHandling -eq 'block') {
            Write-Output "已选择：仅屏蔽（装好后可按 README《解除禁用》章节恢复或再次屏蔽）。"
        } else {
            Write-Output "已选择：物理精简（Windows Update 编排服务键将被删除，无法完整恢复）。"
        }
    }

    # 最终确认。确认之后脚本不再打断，会一路自动执行到结束（含收尾清理）
    # 这一确认发生在真正开始施工之前，仍属「参数/意图确认」阶段：图形界面下走弹窗，
    # 命令行下走问答。（开始施工之后的提示、结果、异常才一律只用控制台。）
    Write-Output " "
    $confirm = $(if ($script:GuiMode) { $(if (Show-GuiConfirm "确认开始制作精简镜像？`n`n确认后将一路自动执行到结束，中途不再需要按键。") { 'Y' } else { 'N' }) } else { Read-Host "确认开始制作精简镜像？(Y/N)（确认后将一路自动执行到结束，中途不再需要按键）" })
    if ($confirm -notmatch '^[Yy]') {
        Write-Output "已取消，脚本退出。"
        Stop-AndExit 0
    }
    Write-Output " "

}

if (-not $script:LiveMode) {
    # —— 以下为 ISO 专属：esd 转换、复制、索引校验、挂载映像、读语言与架构 ——
    # install.esd 源：先转换为 install.wim（索引已在上面确定，此处不再询问）
    if (-not (Test-Path $isoInstallWim)) {
        Write-Output "检测到 install.esd，正在转换为 install.wim..."
        Write-Output ' '
        Write-Output '正在将 install.esd 转换为 install.wim，此步骤可能耗时较久...'
        try {
            Export-WindowsImage -SourceImagePath $isoInstallEsd -SourceIndex $index -DestinationImagePath $ExtractDir\sources\install.wim -Compressiontype Maximum -CheckIntegrity -ErrorAction Stop
            Write-Output "install.esd 转换完成。"
        } catch {
            Write-Output "install.esd 转换为 install.wim 失败：$_"
            Write-Output "请检查 $DriveLetter 与 $ScratchDisk 的可用空间后重试。"
            Stop-AndExit
        }
    }

    Write-Output "正在复制 Windows 映像..."
    Copy-Item -Path "$DriveLetter\*" -Destination "$ExtractDir" -Recurse -Force | Out-Null
    Set-ItemProperty -Path "$ExtractDir\sources\install.esd" -Name IsReadOnly -Value $false > $null 2>&1
    Remove-Item "$ExtractDir\sources\install.esd" > $null 2>&1
    Write-Output "复制完成！"
    Start-Sleep -Seconds 2
    Clear-Host
    Write-Output "正在获取映像信息："
    $ImagesIndex = (Get-WindowsImage -ImagePath $ExtractDir\sources\install.wim).ImageIndex
    if ($ImagesIndex -notcontains $index) {
        Write-Output "复制的 install.wim 中不存在索引 $index（可用索引：$($ImagesIndex -join ' / ')）。"
        Write-Output "按「确认后全程无人值守」的约定，此处不再停下来等待输入，脚本就此中止；请重新运行并选择正确的索引。"
        Stop-AndExit
    }
    Write-Output "映像索引 $index 校验通过。"
    Write-Output "正在挂载 Windows 映像，此步骤可能耗时较久。"
    $wimFilePath = "$ExtractDir\sources\install.wim"
    & takeown "/F" $wimFilePath | Out-Null
    & icacls $wimFilePath "/grant" "$($adminGroup.Value):(F)" | Out-Null
    try {
        Set-ItemProperty -Path $wimFilePath -Name IsReadOnly -Value $false -ErrorAction Stop
    } catch {
        # 清只读属性失败不致命：文件本就不是只读时可忽略，真的没有写权限时后面的挂载会报更具体的错。
        Write-Output "清除 $wimFilePath 的只读属性失败：$_"
        Write-Output "常见原因：权限不足或所在卷为只读。若该文件本就不是只读，可忽略本提示。"
    }
    New-Item -ItemType Directory -Force -Path "$ScratchDir" > $null
    try {
        Mount-WindowsImage -ImagePath $ExtractDir\sources\install.wim -Index $index -Path $ScratchDir -ErrorAction Stop
    } catch {
        Write-Output "挂载 install.wim 失败：$_"
        Write-Output "常见原因：上次运行遗留的挂载未清理。请以管理员身份执行 Dism.exe /Cleanup-WIM 后重试。"
        Stop-AndExit
    }

    $imageIntl = & dism /English /Get-Intl "/Image:$ScratchDir"
    # 逐个匹配并就地取出语言代码：不能写成「先 Where-Object -match 落变量，再用 $Matches[1]」——
    # $Matches 是全局自动变量，中间只要出现任何其它 -match 就会被覆盖，届时 $languageCode 静默变空，
    # ISO 文件名会悄悄退回 multi 前缀（不报错，只出错）。这里把取值放在判断的当场，消除该隐患。
    $languageCode = ''
    foreach ($intlLine in @($imageIntl -split '\r?\n')) {
        if ($intlLine -match 'Default system UI language\s*:\s*([a-zA-Z]{2}-[a-zA-Z]{2})') {
            $languageCode = $Matches[1]
            break
        }
    }
    if ($languageCode) {
        Write-Output "默认系统界面语言代码：$languageCode"
    } else {
        Write-Output "未找到默认系统界面语言代码。"
    }

    $imageInfo = & 'dism' '/English' '/Get-WimInfo' "/wimFile:$ExtractDir\sources\install.wim" "/index:$index"
    $lines = $imageInfo -split '\r?\n'

    foreach ($line in $lines) {
        if ($line -like '*Architecture : *') {
            $architecture = $line -replace 'Architecture : ',''
            # 若为 x64，则统一为 amd64
            if ($architecture -eq 'x64') {
                $architecture = 'amd64'
            }
            Write-Output "体系结构：$architecture"
            break
        }
    }

    if (-not $architecture) {
        Write-Output "未找到体系结构信息。"
    }
}


# ===== 以下为两种操作对象「共用」的精简流程 =====
# 映像用 /image:<挂载点>，活动系统用 /Online —— 除此之外逻辑完全一致，因此共用同一份代码。
if ($script:LiveMode) {
    # 活动系统：架构直接取自当前系统（不回读映像）
    if ($Env:PROCESSOR_ARCHITECTURE -eq 'AMD64') { $architecture = 'amd64' }
    elseif ($Env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { $architecture = 'arm64' }
    else { $architecture = $Env:PROCESSOR_ARCHITECTURE.ToLower() }
    Write-Output "体系结构：$architecture"
    $dismImageArg = '/Online'
    Write-Output "即将移除本机预置应用..."
} else {
    $dismImageArg = "/image:$ScratchDir"
    Write-Output "挂载完成！正在移除预装应用..."
}
Write-Output " "

$packages = & 'dism' '/English' $dismImageArg '/Get-ProvisionedAppxPackages' |
    ForEach-Object {
        if ($_ -match 'PackageName : (.*)') {
            $matches[1]
        }
    }

$packagePrefixes = 'Clipchamp.Clipchamp',
'Microsoft.BingNews',
'Microsoft.BingSearch',
'Microsoft.BingWeather',
'Microsoft.Copilot',
'Microsoft.Windows.CrossDevice',
'Microsoft.GamingApp',
'Microsoft.GetHelp',
'Microsoft.Getstarted',
'Microsoft.Microsoft3DViewer',
'Microsoft.MicrosoftOfficeHub',
'Microsoft.MicrosoftSolitaireCollection',
'Microsoft.MicrosoftStickyNotes',
'Microsoft.MixedReality.Portal',
'Microsoft.MSPaint',
'Microsoft.Office.OneNote',
'Microsoft.OfficePushNotificationUtility',
'Microsoft.OutlookForWindows',
'Microsoft.People',
'Microsoft.PowerAutomateDesktop',
'Microsoft.SkypeApp',
'Microsoft.StartExperiencesApp',
'Microsoft.Todos',
'Microsoft.Wallet',
'Microsoft.Windows.DevHome',
'Microsoft.Windows.Copilot',
'Microsoft.Windows.ContentDeliveryManager',
'Microsoft.Windows.PeopleExperienceHost',
'Microsoft.Windows.ParentalControls',
'Microsoft.Windows.Teams',
'Microsoft.WindowsAlarms',
'Microsoft.WindowsCamera',
'microsoft.windowscommunicationsapps',
'Microsoft.WindowsFeedbackHub',
'Microsoft.WindowsMaps',
'Microsoft.Xbox.TCUI',
'Microsoft.XboxApp',
'Microsoft.XboxGameOverlay',
'Microsoft.XboxGamingOverlay',
'Microsoft.XboxIdentityProvider',
'Microsoft.XboxSpeechToTextOverlay',
'Microsoft.YourPhone',
'Microsoft.ZuneMusic',
'Microsoft.ZuneVideo',
'MicrosoftCorporationII.MicrosoftFamily',
'MicrosoftCorporationII.QuickAssist',
'MSTeams',
'MicrosoftTeams',
'Microsoft.549981C3F5F10',
'Microsoft.WindowsStore',
'Microsoft.StorePurchaseApp',
'Microsoft.Windows.SecureAssessmentBrowser'

# 移除提示用的中文名映射：前 52 项与上面的 $packagePrefixes 一一对应，
# 末尾 3 项为激进模式专属包（Microsoft Store / Store 购买应用 / 安全评估浏览器）。
$appDisplayNames = @{
    'Clipchamp.Clipchamp' = 'Clipchamp 视频编辑器'
    'Microsoft.BingNews' = '必应资讯'
    'Microsoft.BingSearch' = '必应搜索'
    'Microsoft.BingWeather' = '必应天气'
    'Microsoft.Copilot' = 'Copilot（旧包名）'
    'Microsoft.Windows.CrossDevice' = '跨设备互联'
    'Microsoft.GamingApp' = 'Xbox 游戏应用'
    'Microsoft.GetHelp' = '获取帮助'
    'Microsoft.Getstarted' = '入门（Get Started）'
    'Microsoft.Microsoft3DViewer' = '3D 查看器'
    'Microsoft.MicrosoftOfficeHub' = 'Office 中心'
    'Microsoft.MicrosoftSolitaireCollection' = '微软纸牌合集'
    'Microsoft.MicrosoftStickyNotes' = '便笺'
    'Microsoft.MixedReality.Portal' = '混合现实门户'
    'Microsoft.MSPaint' = '画图'
    'Microsoft.Office.OneNote' = 'OneNote'
    'Microsoft.OfficePushNotificationUtility' = 'Office 推送通知组件'
    'Microsoft.OutlookForWindows' = '新版 Outlook'
    'Microsoft.People' = '联系人'
    'Microsoft.PowerAutomateDesktop' = 'Power Automate'
    'Microsoft.SkypeApp' = 'Skype'
    'Microsoft.StartExperiencesApp' = '开始菜单推荐内容'
    'Microsoft.Todos' = '微软待办'
    'Microsoft.Wallet' = '钱包'
    'Microsoft.Windows.DevHome' = 'Dev Home'
    'Microsoft.Windows.Copilot' = 'Windows Copilot'
    'Microsoft.Windows.ContentDeliveryManager' = '内容交付管理器'
    'Microsoft.Windows.PeopleExperienceHost' = '联系人体验主机'
    'Microsoft.Windows.ParentalControls' = '家长控制'
    'Microsoft.Windows.Teams' = 'Teams（系统组件）'
    'Microsoft.WindowsAlarms' = '时钟'
    'Microsoft.WindowsCamera' = '相机'
    'microsoft.windowscommunicationsapps' = '邮件和日历'
    'Microsoft.WindowsFeedbackHub' = '反馈中心'
    'Microsoft.WindowsMaps' = '地图'
    'Microsoft.Xbox.TCUI' = 'Xbox 界面组件'
    'Microsoft.XboxApp' = 'Xbox 应用（旧版）'
    'Microsoft.XboxGameOverlay' = 'Xbox 游戏叠加'
    'Microsoft.XboxGamingOverlay' = 'Xbox Game Bar'
    'Microsoft.XboxIdentityProvider' = 'Xbox 身份提供程序'
    'Microsoft.XboxSpeechToTextOverlay' = 'Xbox 语音转文字'
    'Microsoft.YourPhone' = '手机连接'
    'Microsoft.ZuneMusic' = '媒体播放器'
    'Microsoft.ZuneVideo' = '电影和电视'
    'MicrosoftCorporationII.MicrosoftFamily' = '微软家庭'
    'MicrosoftCorporationII.QuickAssist' = '快速助手'
    'MSTeams' = 'Teams（旧包名）'
    'MicrosoftTeams' = 'Teams（旧包名）'
    'Microsoft.549981C3F5F10' = 'Cortana'
    'Microsoft.WindowsStore' = 'Microsoft Store'
    'Microsoft.StorePurchaseApp' = 'Store 购买应用'
    'Microsoft.Windows.SecureAssessmentBrowser' = '安全评估浏览器'
}

$packagesToRemove = $packages | Where-Object {
    $packageName = $_
    # 判据：只要有一个前缀出现在包名里就算命中。
    # 不要写成 $packagePrefixes -contains (<管道结果>)：当一个包名同时命中两个前缀时，
    # 管道返回的是数组，而 -contains 会把整个数组当作一个值去比较，结果恒为 False，
    # 该包就会被静默漏删。
    @($packagePrefixes | Where-Object { $packageName -like "*$_*" }).Count -gt 0
}
$removeSucceeded = 0
$removeFailed = 0
foreach ($package in $packagesToRemove) {
    # 先取匹配到的前缀，再查中文名；不可直接用哈希表索引管道结果，
    # 无匹配时管道返回 AutomationNull，哈希表会返回最后一项的值（错名）。
    $appPrefix = $packagePrefixes | Where-Object { $package -like "*$_*" } | Select-Object -First 1
    $appDisplayName = if ($appPrefix) { $appDisplayNames[$appPrefix] } else { $package }
    Write-Output "正在移除应用：$appDisplayName（$package）..."
    & 'dism' '/English' $dismImageArg '/Remove-ProvisionedAppxPackage' "/PackageName:$package"
    if ($LASTEXITCODE -eq 0) {
        $removeSucceeded++
    } else {
        $removeFailed++
        Write-Output "移除失败（DISM 退出码 $LASTEXITCODE）：$appDisplayName（$package）"
    }
}
Write-Output "预装应用移除完成：成功 $removeSucceeded / 失败 $removeFailed。"
if ($script:LiveMode) {
    Remove-InstalledAppx $packagePrefixes
}

# ===== Microsoft Store / StorePurchaseApp / SecureAssessmentBrowser（所有模式均移除）=====
# 说明：这三个包已并入上面的 $packagePrefixes 主清单（所有模式共用同一段移除代码）。
# 与它们相关的注册表（Deprovisioned 标记、Store 策略）统一在后面的主注册表段写入
# （见「将 Store / Store 购买应用 / 安全评估浏览器标记为已取消预置」）——注册表操作与 DISM
# 调用彻底解耦，避免 hive 卸载与 DISM 滞留 worker 互持句柄（三台次实测复现的失败模式）。

# Edge 处理：一般模式与「激进保留 Edge」模式均保留，仅纯激进模式彻底移除
if ($removeEdge) {
    if ($script:LiveMode) {
        # 活动系统：只走 Edge 官方卸载程序，不硬删目录（Edge 在 25H2 里是系统组件）
        Write-Output "【激进模式】正在移除 Microsoft Edge（调用 Edge 官方卸载程序）..."
        $edgeSetupExe = Get-ChildItem -Path "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\*\Installer\setup.exe" -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending | Select-Object -First 1
        if ($edgeSetupExe) {
            Write-Output "使用卸载程序：$($edgeSetupExe.FullName)"
            & $edgeSetupExe.FullName '--uninstall' '--system-level' '--verbose-logging' '--force-uninstall'
            if ($LASTEXITCODE -eq 0) {
                Write-Output "Edge 卸载程序返回成功。"
            } else {
                Write-Output "Edge 卸载程序返回码 $LASTEXITCODE（浏览器正在使用或受系统组件保护时可能未完全卸载）。"
            }
        } else {
            Write-Output "未找到 Edge 卸载程序（${env:ProgramFiles(x86)}\Microsoft\Edge\Application\*\Installer\setup.exe），跳过移除 Edge。"
        }
    } else {
        Write-Output "【激进模式】正在移除 Microsoft Edge（含 Edge、EdgeUpdate、EdgeCore、Microsoft-Edge-Webview 等组件）..."
        Remove-Item -Path "$ScratchDir\Program Files (x86)\Microsoft\Edge" -Recurse -Force | Out-Null
        Remove-Item -Path "$ScratchDir\Program Files (x86)\Microsoft\EdgeUpdate" -Recurse -Force | Out-Null
        Remove-Item -Path "$ScratchDir\Program Files (x86)\Microsoft\EdgeCore" -Recurse -Force | Out-Null
        & 'takeown' '/f' "$ScratchDir\Windows\System32\Microsoft-Edge-Webview" '/r' | Out-Null
        & 'icacls' "$ScratchDir\Windows\System32\Microsoft-Edge-Webview" '/grant' "$($adminGroup.Value):(F)" '/T' '/C' | Out-Null
        Remove-Item -Path "$ScratchDir\Windows\System32\Microsoft-Edge-Webview" -Recurse -Force | Out-Null
        # WinSxS 里的 edge-webview 组件目录（参考上游 tiny11Coremaker：按架构匹配组件名前缀）
        $edgeWebviewFilter = if ($architecture -eq 'arm64') { 'arm64_microsoft-edge-webview_31bf3856ad364e35*' } else { 'amd64_microsoft-edge-webview_31bf3856ad364e35*' }
        $edgeWebviewDirs = @(Get-ChildItem -Path "$ScratchDir\Windows\WinSxS" -Filter $edgeWebviewFilter -Directory -ErrorAction SilentlyContinue)
        if ($edgeWebviewDirs.Count -gt 0) {
            foreach ($edgeWebviewDir in $edgeWebviewDirs) {
                & 'takeown' '/f' $edgeWebviewDir.FullName '/r' | Out-Null
                & 'icacls' $edgeWebviewDir.FullName '/grant' "$($adminGroup.Value):(F)" '/T' '/C' | Out-Null
                Remove-Item -Path $edgeWebviewDir.FullName -Recurse -Force | Out-Null
            }
            Write-Output "已删除 WinSxS 中的 edge-webview 组件目录（共 $($edgeWebviewDirs.Count) 个）。"
        } else {
            Write-Output "WinSxS 中未找到 edge-webview 组件目录（$edgeWebviewFilter），跳过。"
        }
        Write-Output "Microsoft Edge 移除完成。"
    }
} else {
    Write-Output "保留 Edge。"
}
Write-Output "正在移除 OneDrive："
if ($script:LiveMode) {
    $oneDriveSetup = "$env:SystemRoot\System32\OneDriveSetup.exe"
    if (Test-Path $oneDriveSetup) {
        Write-Output "调用 OneDrive 卸载程序：$oneDriveSetup /uninstall"
        & $oneDriveSetup '/uninstall'
        Write-Output "OneDrive 卸载程序返回码 $LASTEXITCODE。"
        Remove-Item -Path $oneDriveSetup -Force -ErrorAction SilentlyContinue
    } else {
        Write-Output "未找到 $oneDriveSetup（本机可能没有预装 OneDrive），跳过。"
    }
} else {
    & 'takeown' '/f' "$ScratchDir\Windows\System32\OneDriveSetup.exe" | Out-Null
    & 'icacls' "$ScratchDir\Windows\System32\OneDriveSetup.exe" '/grant' "$($adminGroup.Value):(F)" '/T' '/C' | Out-Null
    Remove-Item -Path "$ScratchDir\Windows\System32\OneDriveSetup.exe" -Force | Out-Null
}
Write-Output "移除完成！"
Start-Sleep -Seconds 2
Clear-Host

#---------[ 启用 .NET Framework 3.5（仅制作 ISO 的一般模式调用）]---------#
# 源用 ISO 自带的 sources\sxs（netfx3 按需功能包），加 /LimitAccess 避免联网去 Windows Update 找。
# 注意：离线启用功能必然给镜像留下「挂起操作」（要等装好系统首次引导时由 CBS 完成），因此只能在
# /ResetBase 之后调用（否则挂起会让压缩报 0x800f0806）。激进模式与 .NET 3.5 不兼容，不调用本函数。
function Enable-NetFx3InImage {
    Write-Output "正在启用 .NET Framework 3.5（源：ISO 内的 sources\sxs，此步会在镜像中留下待首次引导完成的挂起操作）..."
    $netFx3Source = "$ExtractDir\sources\sxs"
    if (Test-Path $netFx3Source) {
        & dism.exe "/image:$ScratchDir" '/enable-feature' '/featurename:NetFX3' '/All' "/source:$netFx3Source" '/LimitAccess'
        if ($LASTEXITCODE -eq 0) {
            Write-Output ".NET Framework 3.5 已启用。"
        } else {
            Write-Output ".NET Framework 3.5 启用失败（DISM 退出码 $LASTEXITCODE）。不影响后续步骤，继续执行。"
        }
    } else {
        Write-Output "未找到 $netFx3Source（本 ISO 不含 .NET 3.5 功能包），跳过启用。"
    }
}

# 注意：/ResetBase 必须排在「整体替换 WinSxS」之前执行。
# WinSxS 被整体替换后，DISM 会报 0xc1510114「指定的映像需要重新加载」，清理必然失败，
# 并连带使挂载会话失效（后续「卸载并保存」会长时间卡死）。在替换前执行才是受支持的次序。
if ($script:LiveMode) {
    Write-Output "正在清理组件存储（官方 ResetBase，这一步可能较久且没有进度输出）..."
} else {
    Write-Output "正在清理映像..."
}
dism.exe $dismImageArg /Cleanup-Image /StartComponentCleanup /ResetBase
$cleanupExitCode = $LASTEXITCODE
if ($cleanupExitCode -eq 0) {
    Write-Output "清理完成。"
} elseif ($script:LiveMode) {
    # 活动系统：清理失败不影响后续步骤，也无需探测挂载会话
    Write-Output "组件存储清理失败：DISM 退出码 $cleanupExitCode。不影响后续步骤，继续执行。"
} elseif (-not $aggressiveCore) {
    # 一般模式（制作 ISO）：后面没有 WinSxS 替换，清理失败只是镜像少做一次压缩精简，可以继续
    Write-Output "映像清理失败：DISM 退出码 $cleanupExitCode。"
    Write-Output "一般模式下这不影响后续步骤（镜像只是少做一次压缩精简），继续执行。"
} else {
    # 激进模式（制作 ISO）：清理失败必须中止 —— 接下来要整体替换 WinSxS。
    # 清理中途死亡（如退出码 32）会让组件数据库（CBS）停留在中间状态，此时再掏空 WinSxS，
    # 安装阶段的服务操作有很高概率失败并回滚（26H2 上已实测：文件复制完成重启后报
    # 「Windows 安装失败」，再次重启找不到启动盘）。
    Write-Output "映像清理失败：DISM 退出码 $cleanupExitCode。"
    Write-Output "激进模式下 /ResetBase 之后还要整体替换 WinSxS；清理中途失败会让组件数据库（CBS）"
    Write-Output "停留在中间状态，此时再替换 WinSxS，安装阶段的服务操作很可能失败并回滚，因此就此中止。"
    Write-Output "常见含义：前面 DISM 操作的 worker 仍持有挂载映像中的文件（退出码 32），通常稍等片刻便会自行退出；"
    Write-Output "或是镜像带「挂起操作」（0x800f0806，例如刚启用过可选功能）——本脚本已把一般模式的 .NET 3.5 启用"
    Write-Output "挪到 /ResetBase 之后执行，激进模式则不启用 .NET 3.5，正常流程不应再出现这一种。"
    Write-Output "处理：直接重新运行本脚本即可；若启动时检出挂载残留，残留检查会先清理。"
    Stop-AndExit
}

# WinRE 在所有模式下都不再移除（用户决定，所有模式均保留）：
# 26H2 的新安装器在 Downlevel 阶段会无条件从 install.wim 提取 winre.wim 到
# \$WINDOWS.~BT\Sources\SafeOS 并挂载，用于安装的离线完成阶段（安装器本体就跑在这个环境里）：
# 空文件占位报 0x8007000B（格式无效）、彻底删除报 0x80070003（找不到文件），均导致安装失败回滚
# （E1/E3 实测），保留合法的 winre.wim 是唯一可行做法；活动系统上删除它也没有收益，故不再触碰。

# ===== 激进模式专属：精简重建 WinSxS（纯激进与保留 Edge 激进模式均执行，仅制作 ISO 分支）=====
if ($aggressiveCore) {
    if ($script:LiveMode) {
        # 活动系统：绝不做整体替换（会直接损坏运行中的系统），组件存储已由前面的官方 ResetBase 压缩
        Write-Output "【激进模式】活动系统不做「整体替换 WinSxS」（会直接损坏运行中的系统）；"
        Write-Output "             组件存储已在前面用官方 Dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase 压缩。"
    } else {
        Write-Output "【激进模式】正在精简重建 WinSxS 组件存储（此步骤耗时较长）..."
        & 'takeown' '/f' "$ScratchDir\Windows\WinSxS" '/r' | Out-Null
        & 'icacls' "$ScratchDir\Windows\WinSxS" '/grant' "$($adminGroup.Value):(F)" '/T' '/C' | Out-Null
        $sourceDirectory = "$ScratchDir\Windows\WinSxS"
        $destinationDirectory = "$ScratchDir\Windows\WinSxS_edit"
        New-Item -Path $destinationDirectory -ItemType Directory -Force | Out-Null
        if ($architecture -eq "amd64") {
            $dirsToCopy = @(
                "x86_microsoft.windows.common-controls_6595b64144ccf1df_*",
                "x86_microsoft.windows.gdiplus_6595b64144ccf1df_*",
                "x86_microsoft.windows.i..utomation.proxystub_6595b64144ccf1df_*",
                "x86_microsoft.windows.isolationautomation_6595b64144ccf1df_*",
                "x86_microsoft-windows-s..ngstack-onecorebase_31bf3856ad364e35_*",
                "x86_microsoft-windows-s..stack-termsrv-extra_31bf3856ad364e35_*",
                "x86_microsoft-windows-servicingstack_31bf3856ad364e35_*",
                "x86_microsoft-windows-servicingstack-inetsrv_*",
                "x86_microsoft-windows-servicingstack-onecore_*",
                "amd64_microsoft.vc80.crt_1fc8b3b9a1e18e3b_*",
                "amd64_microsoft.vc90.crt_1fc8b3b9a1e18e3b_*",
                "amd64_microsoft.windows.c..-controls.resources_6595b64144ccf1df_*",
                "amd64_microsoft.windows.common-controls_6595b64144ccf1df_*",
                "amd64_microsoft.windows.gdiplus_6595b64144ccf1df_*",
                "amd64_microsoft.windows.i..utomation.proxystub_6595b64144ccf1df_*",
                "amd64_microsoft.windows.isolationautomation_6595b64144ccf1df_*",
                "amd64_microsoft-windows-s..stack-inetsrv-extra_31bf3856ad364e35_*",
                "amd64_microsoft-windows-s..stack-msg.resources_31bf3856ad364e35_*",
                "amd64_microsoft-windows-s..stack-termsrv-extra_31bf3856ad364e35_*",
                "amd64_microsoft-windows-servicingstack_31bf3856ad364e35_*",
                "amd64_microsoft-windows-servicingstack-inetsrv_31bf3856ad364e35_*",
                "amd64_microsoft-windows-servicingstack-msg_31bf3856ad364e35_*",
                "amd64_microsoft-windows-servicingstack-onecore_31bf3856ad364e35_*",
                "Catalogs",
                "FileMaps",
                "Fusion",
                "InstallTemp",
                "Manifests",
                "x86_microsoft.vc80.crt_1fc8b3b9a1e18e3b_*",
                "x86_microsoft.vc90.crt_1fc8b3b9a1e18e3b_*",
                "x86_microsoft.windows.c..-controls.resources_6595b64144ccf1df_*"
            )
        }
        elseif ($architecture -eq "arm64") {
            $dirsToCopy = @(
                "arm64_microsoft-windows-servicingstack-onecore_31bf3856ad364e35_*",
                "Catalogs",
                "FileMaps",
                "Fusion",
                "InstallTemp",
                "Manifests",
                "SettingsManifests",
                "Temp",
                "x86_microsoft.vc80.crt_1fc8b3b9a1e18e3b_*",
                "x86_microsoft.vc90.crt_1fc8b3b9a1e18e3b_*",
                "x86_microsoft.windows.c..-controls.resources_6595b64144ccf1df_*",
                "x86_microsoft.windows.common-controls_6595b64144ccf1df_*",
                "x86_microsoft.windows.gdiplus_6595b64144ccf1df_*",
                "x86_microsoft.windows.i..utomation.proxystub_6595b64144ccf1df_*",
                "x86_microsoft.windows.isolationautomation_6595b64144ccf1df_*",
                "arm_microsoft.windows.c..-controls.resources_6595b64144ccf1df_*",
                "arm_microsoft.windows.common-controls_6595b64144ccf1df_*",
                "arm_microsoft.windows.gdiplus_6595b64144ccf1df_*",
                "arm_microsoft.windows.i..utomation.proxystub_6595b64144ccf1df_*",
                "arm_microsoft.windows.isolationautomation_6595b64144ccf1df_*",
                "arm64_microsoft.vc80.crt_1fc8b3b9a1e18e3b_*",
                "arm64_microsoft.vc90.crt_1fc8b3b9a1e18e3b_*",
                "arm64_microsoft.windows.c..-controls.resources_6595b64144ccf1df_*",
                "arm64_microsoft.windows.common-controls_6595b64144ccf1df_*",
                "arm64_microsoft.windows.gdiplus_6595b64144ccf1df_*",
                "arm64_microsoft.windows.i..utomation.proxystub_6595b64144ccf1df_*",
                "arm64_microsoft.windows.isolationautomation_6595b64144ccf1df_*",
                "arm64_microsoft-windows-servicing-adm_31bf3856ad364e35_*",
                "arm64_microsoft-windows-servicingcommon_31bf3856ad364e35_*",
                "arm64_microsoft-windows-servicing-onecore-uapi_31bf3856ad364e35_*",
                "arm64_microsoft-windows-servicingstack_31bf3856ad364e35_*",
                "arm64_microsoft-windows-servicingstack-inetsrv_31bf3856ad364e35_*",
                "arm64_microsoft-windows-servicingstack-msg_31bf3856ad364e35_*"
            )
        }
        else {
            # 没有对应清单时绝不能继续：$dirsToCopy 未赋值 → 下面的 foreach 零次迭代 →
            # 原 WinSxS 被删除、空目录被改名回去，镜像将无法启动。
            Write-Output "无法识别的体系结构 [$architecture]：脚本没有对应的 WinSxS 保留清单。"
            Write-Output "继续执行会把组件存储清空并导致镜像无法启动，因此中止；可改用一般模式（不做 WinSxS 重建）。"
            Stop-AndExit
        }
        $copiedCount = 0
        foreach ($dir in $dirsToCopy) {
            $sourceDirs = Get-ChildItem -Path $sourceDirectory -Filter $dir -Directory -ErrorAction SilentlyContinue
            foreach ($sourceDir in $sourceDirs) {
                $destDir = Join-Path -Path $destinationDirectory -ChildPath $sourceDir.Name
                Write-Output "正在复制 $($sourceDir.FullName) 到 $destDir"
                Copy-Item -Path $sourceDir.FullName -Destination $destDir -Recurse -Force | Out-Null
                $copiedCount++
            }
        }
        # 安全闸门：WinSxS 一旦删除就无法恢复，所以必须先确认确实复制到了东西再删。
        # 复制数为 0 的另一种可能：本镜像的组件命名与脚本内置清单不匹配（新版本 Windows 调整命名即可能命中）。
        if ($copiedCount -eq 0) {
            Write-Output "安全中止：没有从 WinSxS 复制到任何目录（复制数 = 0）。"
            Write-Output "继续执行会先删除原有 WinSxS、再把空目录改名回去，导致镜像无法启动，因此中止。"
            Write-Output "可能原因：本镜像的组件命名与脚本内置的保留清单不匹配（多见于较新的 Windows 版本）。"
            Write-Output "处理：改用一般模式，或按本镜像的实际组件名更新脚本中的 `$dirsToCopy 清单后重试。"
            Stop-AndExit
        }
        Write-Output "已复制 $copiedCount 个保留目录，正在删除原有 WinSxS（此步骤耗时较长）..."
        Remove-Item -Path "$ScratchDir\Windows\WinSxS" -Recurse -Force | Out-Null
        Rename-Item -Path "$ScratchDir\Windows\WinSxS_edit" -NewName "WinSxS" | Out-Null
        Write-Output "WinSxS 精简重建完成。"
    }
}

# ===== 启用 .NET Framework 3.5（一般模式的执行点）=====
# 必须排在 /ResetBase 之后：离线启用功能会给镜像留下「挂起操作」（要等装好系统首次引导时由 CBS
# 完成），挂起操作会让压缩报 0x800f0806，所以先压缩组件存储，最后一步再启用功能
# （离线预装 .NET 3.5 本就是微软文档记载的标准部署做法）。激进模式不启用 .NET 3.5（见输入收集处）。
if (-not $script:LiveMode) {
    if ($enableNetFx3) {
        Enable-NetFx3InImage
    } else {
        Write-Output "不启用 .NET Framework 3.5，跳过。"
    }
}

if (-not $script:LiveMode) {
    Write-Output "正在加载注册表..."
    Mount-RegistryHive 'HKLM\zCOMPONENTS' "$ScratchDir\Windows\System32\config\COMPONENTS"
    Mount-RegistryHive 'HKLM\zDEFAULT' "$ScratchDir\Windows\System32\config\default"
    Mount-RegistryHive 'HKLM\zNTUSER' "$ScratchDir\Users\Default\ntuser.dat"
    Mount-RegistryHive 'HKLM\zSOFTWARE' "$ScratchDir\Windows\System32\config\SOFTWARE"
    Mount-RegistryHive 'HKLM\zSYSTEM' "$ScratchDir\Windows\System32\config\SYSTEM"
    # 读取系统版本标识（DisplayVersion，如 26H2 / 25H2），用于 ISO 卷标 WIN11_<版本>_<模式>
    Write-Output "正在读取系统版本标识（用于 ISO 卷标）..."
    $script:OSDisplayVersion = 'WIN'
    $cvOutput = & 'reg' 'query' 'HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion' 2>&1
    foreach ($cvLine in $cvOutput) {
        if ($cvLine -match '^\s*DisplayVersion\s+REG_\S+\s+(\S+)') { $script:OSDisplayVersion = $Matches[1] }
    }
    # 清洗：仅保留字母数字并转大写，防止卷标含非法字符；读不到时回退为 WIN
    $script:OSDisplayVersion = ($script:OSDisplayVersion -replace '[^A-Za-z0-9]', '').ToUpper()
    if (-not $script:OSDisplayVersion) { $script:OSDisplayVersion = 'WIN' }
    Write-Output "系统版本标识：$($script:OSDisplayVersion)"
} else {
    # 活动系统：直接写宿主机注册表，无需加载任何配置单元（zNTUSER / zDEFAULT 会映射为 HKCU）
    Write-Output "正在写入注册表（活动系统：HKLM 与当前用户 HKCU）..."
}

if ($script:LiveMode) {
    Write-Output "正在绕过系统要求（活动系统）："
} else {
    Write-Output "正在绕过系统要求（系统映像）："
}
Set-RegistryValue 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' 'SV1' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' 'SV2' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' 'SV1' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' 'SV2' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassCPUCheck' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassRAMCheck' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassSecureBootCheck' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassStorageCheck' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassTPMCheck' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSYSTEM\Setup\MoSetup' 'AllowUpgradesWithUnsupportedTPMOrCPU' 'REG_DWORD' '1'
Write-Output "正在禁用赞助应用（广告应用）："
Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'OemPreInstalledAppsEnabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'PreInstalledAppsEnabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SilentInstalledAppsEnabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'ContentDeliveryAllowed' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\PolicyManager\current\device\Start' 'ConfigureStartPins' 'REG_SZ' '{"pinnedList": [{}]}'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'FeatureManagementEnabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'PreInstalledAppsEverEnabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SoftLandingEnabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContentEnabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-310093Enabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338388Enabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338389Enabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338393Enabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-353694Enabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-353696Enabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SystemPaneSuggestionsEnabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\PushToInstall' 'DisablePushToInstall' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\MRT' 'DontOfferThroughWUAU' 'REG_DWORD' '1'
Remove-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions'
Remove-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps'
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableConsumerAccountStateContent' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableCloudOptimizedContent' 'REG_DWORD' '1'
Write-Output "正在启用 OOBE 本地账户："
Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE' 'BypassNRO' 'REG_DWORD' '1'
if (-not $script:LiveMode) {
    Copy-Item -Path "$PSScriptRoot\autounattend.xml" -Destination "$ScratchDir\Windows\System32\Sysprep\autounattend.xml" -Force | Out-Null
}

Write-Output "正在禁用保留存储空间："
Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager' 'ShippedWithReserves' 'REG_DWORD' '0'
Write-Output "正在禁用 BitLocker 设备加密"
Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\BitLocker' 'PreventDeviceEncryption' 'REG_DWORD' '1'
Write-Output "正在禁用聊天图标："
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Chat' 'ChatIcon' 'REG_DWORD' '3'
Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarMn' 'REG_DWORD' '0'
# Edge 卸载注册表项：一般模式与「激进保留 Edge」模式均保留，仅纯激进模式删除（参考原版 tiny11builder.ps1）
if ($removeEdge) {
    Write-Output "【激进模式】正在删除 Edge 相关卸载注册表项..."
    Remove-RegistryValue "HKLM\zSOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge"
    Remove-RegistryValue "HKLM\zSOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update"
    Write-Output "Edge 卸载注册表项已删除。"
} else {
    Write-Output "保留 Edge 卸载注册表项（按本地要求跳过删除）。"
}
Write-Output "正在禁用 OneDrive 文件夹备份"
Set-RegistryValue "HKLM\zSOFTWARE\Policies\Microsoft\Windows\OneDrive" "DisableFileSyncNGSC" "REG_DWORD" "1"
Write-Output "正在禁用遥测："
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' 'HasAccepted' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Input\TIPC' 'Enabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization\TrainedDataStore' 'HarvestContacts' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Personalization\Settings' 'AcceptedPrivacyPolicy' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\DataCollection' 'DoNotShowFeedbackNotifications' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\dmwappushservice' 'Start' 'REG_DWORD' '4'
# 禁用 SysMain（预读 + 内存压缩）：服务键保留，完全可逆（Start 改回 2 或 Set-Service Manual 即恢复）。
# 副作用：应用冷启动略慢（SSD 上几乎无感）、「已压缩内存」归零（同等负载物理内存占用升高）。
Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\SysMain' 'Start' 'REG_DWORD' '4'
Write-Output "已禁用 SysMain（预读与内存压缩）。"
if ($script:LiveMode) {
    Stop-Service -Name 'SysMain' -Force -ErrorAction SilentlyContinue
    Write-Output "活动系统：SysMain 服务已停止并设为禁用，立即生效。"
}
# 禁用 DiagTrack（连接用户体验和遥测，社区优化清单第一位的后台采集服务）：
# 服务键保留，完全可逆（Start 改回 3 或 Set-Service Manual 即恢复，官方默认为手动=3）。
# 无任何服务依赖它，与裁剪项零交集；Stop 仅在活动系统执行（ISO 阶段服务尚未运行）。
Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\DiagTrack' 'Start' 'REG_DWORD' '4'
Write-Output "已禁用 DiagTrack（连接用户体验和遥测）。"
if ($script:LiveMode) {
    Stop-Service -Name 'DiagTrack' -Force -ErrorAction SilentlyContinue
    Write-Output "活动系统：DiagTrack 服务已停止并设为禁用，立即生效。"
}
# 禁用 Xbox Live 服务四件套：Xbox 应用层已在预装应用清单移除，这四个后台服务本就没有可用的前端，
# 禁用只省后台资源；服务键保留，完全可逆（官方默认均为手动=3）。副作用：依赖 Xbox Live 登录的
# 第三方场景（如 PC Game Pass）不可用。
foreach ($xboxSvc in 'XblAuthManager', 'XblGameSave', 'XboxNetApiSvc', 'XboxGipSvc') {
    Set-RegistryValue "HKLM\zSYSTEM\ControlSet001\Services\$xboxSvc" 'Start' 'REG_DWORD' '4'
    if ($script:LiveMode) {
        Stop-Service -Name $xboxSvc -Force -ErrorAction SilentlyContinue
    }
}
Write-Output "已禁用 Xbox Live 服务（XblAuthManager / XblGameSave / XboxNetApiSvc / XboxGipSvc）。"
## 阻止 DevHome 与 Outlook 自行安装
Write-Output "正在阻止 DevHome 与 Outlook 自行安装："
Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate' 'workCompleted' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate' 'workCompleted' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate' 'workCompleted' 'REG_DWORD' '1'
Remove-RegistryValue 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate'
Remove-RegistryValue 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate'
Write-Output "正在禁用 Copilot"
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Edge' 'HubsSidebarEnabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 'REG_DWORD' '1'
Write-Output "正在阻止 Teams 安装："
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Teams' 'DisableInstallation' 'REG_DWORD' '1'
Write-Output "正在阻止新版 Outlook 安装："
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Mail' 'PreventRun' 'REG_DWORD' '1'

if ($script:LiveMode) {
    # 活动系统：这些任务文件在 System32\Tasks 下且受系统 ACL 保护，直接删易受权限阻碍，
    # 故改用计划任务接口逐条注销（效果等效，且不需要 takeown）。
    Write-Output "正在注销计划任务（活动系统）..."
    $liveTasks = @(
        @{ TaskPath = '\Microsoft\Windows\Application Experience\'; TaskName = 'Microsoft Compatibility Appraiser' },
        @{ TaskPath = '\Microsoft\Windows\Application Experience\'; TaskName = 'ProgramDataUpdater' },
        @{ TaskPath = '\Microsoft\Windows\Chkdsk\'; TaskName = 'Proxy' },
        @{ TaskPath = '\Microsoft\Windows\Windows Error Reporting\'; TaskName = 'QueueReporting' }
    )
    $taskOk = 0
    $taskFail = 0
    foreach ($t in $liveTasks) {
        if (Get-ScheduledTask -TaskPath $t.TaskPath -TaskName $t.TaskName -ErrorAction SilentlyContinue) {
            try {
                Unregister-ScheduledTask -TaskPath $t.TaskPath -TaskName $t.TaskName -Confirm:$false -ErrorAction Stop
                Write-Output "已注销计划任务：$($t.TaskPath)$($t.TaskName)"
                $taskOk++
            } catch {
                $taskFail++
                Write-Output "注销失败：$($t.TaskPath)$($t.TaskName)：$_"
            }
        } else {
            Write-Output "计划任务不存在（跳过）：$($t.TaskPath)$($t.TaskName)"
        }
    }
    # 客户体验改进计划：注销该目录下的全部任务
    foreach ($t in @(Get-ScheduledTask -TaskPath '\Microsoft\Windows\Customer Experience Improvement Program\' -ErrorAction SilentlyContinue)) {
        try {
            Unregister-ScheduledTask -TaskPath $t.TaskPath -TaskName $t.TaskName -Confirm:$false -ErrorAction Stop
            Write-Output "已注销计划任务：$($t.TaskPath)$($t.TaskName)"
            $taskOk++
        } catch {
            $taskFail++
            Write-Output "注销失败：$($t.TaskPath)$($t.TaskName)：$_"
        }
    }
    Write-Output "计划任务注销完成：成功 $taskOk / 失败 $taskFail。"
} else {

    Write-Output "正在删除计划任务定义文件..."
    $tasksPath = "$ScratchDir\Windows\System32\Tasks"

    # 应用程序兼容性评估器
    Remove-Item -Path "$tasksPath\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" -Force -ErrorAction SilentlyContinue

    # 客户体验改进计划（递归删除整个目录及其中的全部任务）
    Remove-Item -Path "$tasksPath\Microsoft\Windows\Customer Experience Improvement Program" -Recurse -Force -ErrorAction SilentlyContinue

    # 程序数据更新器
    Remove-Item -Path "$tasksPath\Microsoft\Windows\Application Experience\ProgramDataUpdater" -Force -ErrorAction SilentlyContinue

    # Chkdsk 代理
    Remove-Item -Path "$tasksPath\Microsoft\Windows\Chkdsk\Proxy" -Force -ErrorAction SilentlyContinue

    # Windows 错误报告（QueueReporting）
    Remove-Item -Path "$tasksPath\Microsoft\Windows\Windows Error Reporting\QueueReporting" -Force -ErrorAction SilentlyContinue
    Write-Output "计划任务文件已删除。"
}

# Store / StorePurchaseApp / SecureAssessmentBrowser 已在前面的 DISM 步骤移除（所有模式）；
# 这里补写「已取消预置」标记与 Store 策略，防止功能更新把它们回装。
# 放在主注册表段（而不是移除之前）是有意的：这样注册表操作与 DISM 调用彻底解耦，
# 避免 hive 卸载与 DISM 滞留 worker 互持句柄（三台次实测复现的失败模式）。
# Deprovisioned 键在移除之后写入功能等价 —— 它供未来的功能更新/服务操作读取，与移除动作本身无关。
Write-Output "正在设置注册表：将 Store / Store 购买应用 / 安全评估浏览器标记为已取消预置（防止功能更新回装）..."
New-RegistryKey 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.WindowsStore_8wekyb3d8bbwe'
New-RegistryKey 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.StorePurchaseApp_8wekyb3d8bbwe'
New-RegistryKey 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.Windows.SecureAssessmentBrowser_cw5n1h2txyewy'
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\WindowsStore' 'RemoveWindowsStore' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'NoWindowsStore' 'REG_DWORD' '1'

# 活动系统：用户级设置需要「默认用户模板」，先把 Users\Default\ntuser.dat 临时加载为 zDEFUSER
$script:LiveDefaultHiveMounted = $false
if ($script:LiveMode) {
    $script:LiveDefaultHiveMounted = Mount-DefaultUserHiveLive
}
Write-Output ' '
# ===== Dism++ 选定项：系统优化（三种模式 × 两种操作对象，共用本段）=====
# 规则来源：Chuyu-Team/Dism-Multi-language 的 Data.xml（MIT）。本段按选定的 O 编号逐项实现，
# 取值一律取规则中「勾选（True）」分支。写注册表统一用映像式路径，活动系统由 Get-TargetRegPath 自动映射。
# 用户级（默认用户）项的落点：
#   · 制作 ISO   → 默认用户模板 Users\Default\ntuser.dat（zNTUSER）+ 系统默认配置单元 config\default（zDEFAULT）
#   · 精简本机   → 当前用户（HKCU）+ 默认用户模板（临时加载为 zDEFUSER）
Write-Output "正在应用 Dism++ 优化项..."

# O015 优化非活动窗口标题栏颜色：规则值为 ?ColorDialog()（交互取色），脚本无法实现，跳过。
# O040 隐藏可执行文件小盾牌：需要在 Dism++ 的 Config\default.ui.zip 中提取资源文件，跳过。
# O041 隐藏NTFS蓝色双箭头压缩标识（by IT之家）：需要在 Dism++ 的 Config\default.ui.zip 中提取资源文件，跳过。

# --- 一、系统级设置（HKLM，含 HKCR 等价路径 HKLM\SOFTWARE\Classes）---
# O010 *隐藏某些SATA硬盘任务栏图标（by 原罪）
Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\nvata' 'DisableRemovable' 'REG_DWORD' '1'
# O014 使任务栏更透明（by 518516.net）
Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'UseOLEDTaskbarTransparency' 'REG_DWORD' '1'
# O017 将用户账号控制程序（UAC）调整为
Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' 'ConsentPromptBehaviorAdmin' 'REG_DWORD' '5'
Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' 'PromptOnSecureDesktop' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' 'EnableLUA' 'REG_DWORD' '1'
# O018 用于内置管理员帐户的管理员批准模式 (by 坏坏小生)
Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' 'FilterAdministratorToken' 'REG_DWORD' '1'
# O019 关闭Smartscreen应用筛选器（by Windows 10优化辅助工具）
Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' 'SmartScreenEnabled' 'REG_SZ' 'off'
# O020 关闭Smartscreen应用筛选器（by 、Cloud）
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\MicrosoftEdge\PhishingFilter' 'EnabledV9' 'REG_DWORD' '0'
# O025 关闭在应用商店中查找关联应用（by Asoft）
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Explorer' 'NoUseStoreOpenWith' 'REG_DWORD' '1'
# O032 登录界面默认打开小键盘（by IT之家）
Set-SystemDefaultRegistryValue 'HKLM\zDEFAULT\Control Panel\Keyboard' 'InitialKeyboardIndicators' 'REG_SZ' '2'
# O033 关闭OneDrive（by Rambin）
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\OneDrive' 'DisableFileSyncNGSC' 'REG_DWORD' '1'
# O034 关闭多嘴的小娜（by 朽木）
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Search' 'AllowCortana' 'REG_DWORD' '0'
# O075 隐藏资源管理器导航窗口中的OneDrive（by 莫失莫忘）
# Attributes 是标志位集合，原规则用「按位或」置位（Attributes |= 0x100000），
# 直接赋值会把该 CLSID 上其它 ShellFolder 行为位清零，故走 OR 助手。
Set-RegistryValueOr 'HKLM\zSOFTWARE\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\ShellFolder' 'Attributes' 0x100000
# O102 关闭Adobe Flash即点即用
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\MicrosoftEdge\Security' 'FlashClickToRunMode' 'REG_DWORD' '0'
# O133 *关闭默认共享（by 518516.net）
Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\LanmanServer\Parameters' 'AutoShareServer' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\LanmanServer\Parameters' 'AutoShareWks' 'REG_DWORD' '0'
# O135 *关闭远程协助（by 原罪）
Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\Remote Assistance' 'fAllowToGetHelp' 'REG_DWORD' '0'
# O136 *禁用SMB1网络协议（by MS-PC2）
Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\LanmanServer\Parameters' 'SMB1' 'REG_DWORD' '0'
# O144 禁用客户体验改善计划（by Windows 10优化辅助工具）
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\SQMClient\Windows' 'CEIPEnable' 'REG_DWORD' '0'
# O151 *隐藏Windows 10升级助手GWX
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Gwx' 'DisableGwx' 'REG_DWORD' '1'
# O152 *VHD启动时不要将VHD动态文件扩展到最大（以节省空间）
Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\services\FsDepends\Parameters' 'VirtualDiskExpandOnMount' 'REG_DWORD' '4'
# O153 蓝屏时自动重启（by 原罪）
Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\CrashControl' 'AutoReboot' 'REG_DWORD' '1'
# O154 关闭快速启动
Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\Session Manager\Power' 'HiberbootEnabled' 'REG_DWORD' '0'
# O156 禁用组件堆栈（Component Based Servicing）日志
Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing' 'EnableLog' 'REG_DWORD' '0'
# O157 禁用更新解压模块（Delta Package Expander）日志
Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing' 'EnableDpxLog' 'REG_DWORD' '0'
# O159 禁用组件堆栈（Component Based Servicing）文件备份
Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\SideBySide\Configuration' 'DisableComponentBackups' 'REG_DWORD' '1'
# O160 崩溃时写入调试信息
Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\CrashControl' 'CrashDumpEnabled' 'REG_DWORD' '0'
# O162 禁用WfpDiag.ETL日志（by powerxing04）
Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\BFE\Parameters\Policy\Options' 'CollectNetEvents' 'REG_DWORD' '0'

# --- 二、服务禁用（写 Start=4；活动系统额外停止服务，立即生效）---
# O137 禁用程序兼容性助手（by 一叶微风TM）
Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\PcaSvc' 'Start' 'REG_DWORD' '4'
if ($script:LiveMode) { Stop-Service -Name 'PcaSvc' -Force -ErrorAction SilentlyContinue }
# O138 禁用远程修改注册表（by 一叶微风TM）
Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\RemoteRegistry' 'Start' 'REG_DWORD' '4'
if ($script:LiveMode) { Stop-Service -Name 'RemoteRegistry' -Force -ErrorAction SilentlyContinue }
# O139 禁用诊断服务
# DPS 与 TrkWks 两个键带独立严格 ACL（见 Grant-RegistryFullAccess 的说明），直接写会失败，
# 因此走「先试写、失败则授权后重试」的入口。
Set-ServiceStartValue 'HKLM\zSYSTEM\ControlSet001\Services\DPS' 'DPS'
# O141 禁用Windows Search
Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\WSearch' 'Start' 'REG_DWORD' '4'
if ($script:LiveMode) { Stop-Service -Name 'WSearch' -Force -ErrorAction SilentlyContinue }
# O142 禁用错误报告
Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\WerSvc' 'Start' 'REG_DWORD' '4'
if ($script:LiveMode) { Stop-Service -Name 'WerSvc' -Force -ErrorAction SilentlyContinue }
# O145 禁用NTFS链接跟踪服务（by 某宅）
Set-ServiceStartValue 'HKLM\zSYSTEM\ControlSet001\Services\TrkWks' 'TrkWks'

# --- 三、用户级设置（默认用户模板 + 系统默认配置单元；活动系统为当前用户 + 模板）---
# O001 将任务栏中的Cortana调整为
Set-UserRegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' 'SearchboxTaskbarMode' 'REG_DWORD' '0'
# O006 当任务栏被占满时
Set-UserRegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarGlomLevel' 'REG_DWORD' '2'
# O007 锁定任务栏
Set-UserRegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarSizeMove' 'REG_DWORD' '0'
# O009 隐藏任务栏上的人脉（by 、Cloud.）
Set-UserRegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People' 'PeopleBand' 'REG_DWORD' '0'
# O012 显示开始菜单、任务栏、操作中心和标题栏的颜色（by Rambin）
Set-UserRegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'ColorPrevalence' 'REG_DWORD' '1'
Set-UserRegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\DWM' 'ColorPrevalence' 'REG_DWORD' '1'
# O013 使开始菜单、任务栏、操作中心透明
Set-UserRegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 'REG_DWORD' '1'
# O016 *桌面壁纸质量调整为（by IT之家）
Set-UserRegistryValue 'HKLM\zNTUSER\Control Panel\Desktop' 'JPEGImportQuality' 'REG_DWORD' '256'
# O023 不允许在开始菜单显示建议
Set-UserRegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SystemPaneSuggestionsEnabled' 'REG_DWORD' '0'
# O024 不允许在开始菜单显示建议（by powerxing04）
Set-UserRegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338388Enabled' 'REG_DWORD' '0'
# 338389 = 「使用 Windows 时获取提示、技巧和建议」。Dism++ 原规则在 O024 下把它置 1（保持 Tips 开启），
# 但本工具的意图是关闭推广，故这里置 0 与 §一「禁用赞助应用」段保持一致（原段已是 0，此处属重复兜底）。
Set-UserRegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338389Enabled' 'REG_DWORD' '0'
# O026 关闭商店应用推广（by 、Cloud.）
Set-UserRegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'PreInstalledAppsEnabled' 'REG_DWORD' '0'
# O027 关闭锁屏时的Windows 聚焦推广（by 、Cloud.）
Set-UserRegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'RotatingLockScreenEnable' 'REG_DWORD' '0'
# O028 关闭“使用Windows时获取技巧和建议”（by 、Cloud.）
Set-UserRegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SoftLandingEnabled' 'REG_DWORD' '0'
# O030 禁止自动安装推荐的应用程序（by IT之家）
Set-UserRegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SilentInstalledAppsEnabled' 'REG_DWORD' '0'
# O031 关闭游戏录制工具（by 、Cloud.）
Set-UserRegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 'REG_DWORD' '0'
Set-UserRegistryValue 'HKLM\zNTUSER\System\GameConfigStore' 'GameDVR_Enabled' 'REG_DWORD' '0'
# O036 打开资源管理器时显示此电脑
Set-UserRegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'LaunchTo' 'REG_DWORD' '1'
# O037 显示所有文件扩展名
Set-UserRegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt' 'REG_DWORD' '0'
# O043 创建快捷方式时不添&quot;快捷方式&quot;文字（by 518516.net）
Set-UserRegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer' 'Link' 'REG_BINARY' '00000000'
# O049 禁止自动播放（by Rambin）
Set-UserRegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers' 'DisableAutoplay' 'REG_DWORD' '1'
# O055 快速访问不显示常用文件夹（by 溯汐潮）
Set-UserRegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' 'ShowFrequent' 'REG_DWORD' '0'
# O056 快速访问不显示最近使用的文件（by 溯汐潮）
Set-UserRegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' 'ShowRecent' 'REG_DWORD' '0'
# O057 将语言栏隐藏到任务栏（by 溯汐潮）
Set-UserRegistryValue 'HKLM\zNTUSER\Software\Microsoft\CTF\LangBar' 'ShowStatus' 'REG_DWORD' '4'
Set-UserRegistryValue 'HKLM\zNTUSER\Software\Microsoft\CTF\LangBar' 'ExtraIconsOnMinimized' 'REG_DWORD' '0'
# O058 隐藏语言栏上的帮助按钮（by 溯汐潮）
Set-UserRegistryValue 'HKLM\zNTUSER\Software\Microsoft\CTF\LangBar\ItemState\{ED9D5450-EBE6-4255-8289-F8A31E687228}' 'DemoteLevel' 'REG_DWORD' '3'
# O059 禁用Win11加入的新右键菜单，默认显示更多选项（by LittleCircleOO）
Set-UserRegistryValue 'HKLM\zNTUSER\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' '' 'REG_SZ' ''
# O108 关闭建议的网站（by 原罪）
Set-UserRegistryValue 'HKLM\zNTUSER\Software\Microsoft\Internet Explorer\Suggested Sites' 'Enabled' 'REG_DWORD' '0'
# O117 隐藏Internet Explorer右上角的笑脸反馈按钮（by IT之家）
Set-UserRegistryValue 'HKLM\zNTUSER\Software\Policies\Microsoft\Internet Explorer\Restrictions' 'NoHelpItemSendFeedback' 'REG_DWORD' '1'
# O119 关闭微软拼音云计算（by Rambin）
Set-UserRegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\InputMethod\Settings\CHS' 'Enable Cloud Candidate' 'REG_DWORD' '0'
# O131 启用自动换行（by 一叶微风TM）
Set-UserRegistryValue 'HKLM\zNTUSER\Software\Microsoft\Notepad' 'fWrap' 'REG_DWORD' '1'
# O132 始终显示状态栏（by 一叶微风TM）
Set-UserRegistryValue 'HKLM\zNTUSER\Software\Microsoft\Notepad' 'StatusBar' 'REG_DWORD' '1'

# --- 四、注册表键重命名（右键菜单/预览的禁用方式即"键前缀加 -"，与规则一致）---
# O053 关闭视频文件预览，提高资源管理器响应速度（by ‍莫失莫忘）
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\.mp4\ShellEx' 'HKLM\zSOFTWARE\Classes\.mp4\-ShellEx'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\.3gp\ShellEx' 'HKLM\zSOFTWARE\Classes\.3gp\-ShellEx'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\.m4v\ShellEx' 'HKLM\zSOFTWARE\Classes\.m4v\-ShellEx'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\.mkv\ShellEx' 'HKLM\zSOFTWARE\Classes\.mkv\-ShellEx'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\.m4a\ShellEx' 'HKLM\zSOFTWARE\Classes\.m4a\-ShellEx'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\.mod\ShellEx' 'HKLM\zSOFTWARE\Classes\.mod\-ShellEx'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\.avi\ShellEx' 'HKLM\zSOFTWARE\Classes\.avi\-ShellEx'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\.wmv\ShellEx' 'HKLM\zSOFTWARE\Classes\.wmv\-ShellEx'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\.mpg\ShellEx' 'HKLM\zSOFTWARE\Classes\.mpg\-ShellEx'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\.mpeg\ShellEx' 'HKLM\zSOFTWARE\Classes\.mpeg\-ShellEx'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\.rmvb\ShellEx' 'HKLM\zSOFTWARE\Classes\.rmvb\-ShellEx'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\.mov\ShellEx' 'HKLM\zSOFTWARE\Classes\.mov\-ShellEx'
# O054 关闭音乐文件图片预览，提高资源管理器响应速度（by ‍莫失莫忘）
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\.ape\ShellEx' 'HKLM\zSOFTWARE\Classes\.ape\-ShellEx'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\.mp3\ShellEx' 'HKLM\zSOFTWARE\Classes\.mp3\-ShellEx'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\.flac\ShellEx' 'HKLM\zSOFTWARE\Classes\.flac\-ShellEx'
# O077 禁用桌面的英特尔集显右键菜单（by 莫失莫忘）
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Directory\Background\ShellEx\ContextMenuHandlers\igfxDTCM' 'HKLM\zSOFTWARE\Classes\Directory\Background\ShellEx\-ContextMenuHandlers\igfxDTCM'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Directory\Background\ShellEx\ContextMenuHandlers\igfxOSP' 'HKLM\zSOFTWARE\Classes\Directory\Background\ShellEx\-ContextMenuHandlers\igfxOSP'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Directory\Background\ShellEx\ContextMenuHandlers\igfxcui' 'HKLM\zSOFTWARE\Classes\Directory\Background\ShellEx\-ContextMenuHandlers\igfxcui'
# O078 禁用可执行文件的“兼容性疑难解答”右键菜单（by 莫失莫忘）
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\exefile\shellex\ContextMenuHandlers\Compatibility' 'HKLM\zSOFTWARE\Classes\exefile\shellex\-ContextMenuHandlers\Compatibility'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Msi.Package\ShellEx\ContextMenuHandlers\Compatibility' 'HKLM\zSOFTWARE\Classes\Msi.Package\ShellEx\-ContextMenuHandlers\Compatibility'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\lnkfile\shellex\ContextMenuHandlers\Compatibility' 'HKLM\zSOFTWARE\Classes\lnkfile\shellex\-ContextMenuHandlers\Compatibility'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\batfile\ShellEx\ContextMenuHandlers\Compatibility' 'HKLM\zSOFTWARE\Classes\batfile\ShellEx\-ContextMenuHandlers\Compatibility'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\cmdfile\ShellEx\ContextMenuHandlers\Compatibility' 'HKLM\zSOFTWARE\Classes\cmdfile\ShellEx\-ContextMenuHandlers\Compatibility'
# O079 禁用文件、文件夹以及磁盘的“使用Windows Defender扫描”右键菜单（by 莫失莫忘）
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Drive\ShellEx\ContextMenuHandlers\EPP' 'HKLM\zSOFTWARE\Classes\Drive\ShellEx\-ContextMenuHandlers\EPP'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Directory\ShellEx\ContextMenuHandlers\EPP' 'HKLM\zSOFTWARE\Classes\Directory\ShellEx\-ContextMenuHandlers\EPP'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\*\ShellEx\ContextMenuHandlers\EPP' 'HKLM\zSOFTWARE\Classes\*\ShellEx\-ContextMenuHandlers\EPP'
# O080 禁用磁盘的“启用Bitlocker”右键菜单（by 莫失莫忘）
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Drive\shell\encrypt-bde' 'HKLM\zSOFTWARE\Classes\Drive\-shell\encrypt-bde'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Drive\shell\encrypt-bde-elev' 'HKLM\zSOFTWARE\Classes\Drive\-shell\encrypt-bde-elev'
# O081 禁用磁盘的“以便携式方式打开”右键菜单（by 莫失莫忘）
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Drive\shellex\ContextMenuHandlers\{D6791A63-E7E2-4fee-BF52-5DED8E86E9B8}' 'HKLM\zSOFTWARE\Classes\Drive\shellex\-ContextMenuHandlers\{D6791A63-E7E2-4fee-BF52-5DED8E86E9B8}'
# O082 禁用磁盘的“复制磁盘”右键菜单
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Drive\shellex\ContextMenuHandlers\{59099400-57FF-11CE-BD94-0020AF85B590}' 'HKLM\zSOFTWARE\Classes\Drive\shellex\-ContextMenuHandlers\{59099400-57FF-11CE-BD94-0020AF85B590}'
# O083 禁用新建的“联系人”右键菜单（by 莫失莫忘）
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\.contact\ShellNew' 'HKLM\zSOFTWARE\Classes\.contact\-ShellNew'
# O084 禁用新建、文件以及文件夹的“公文包”右键菜单
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Briefcase\ShellNew' 'HKLM\zSOFTWARE\Classes\Briefcase\-ShellNew'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\*\shellex\ContextMenuHandlers\BriefcaseMenu' 'HKLM\zSOFTWARE\Classes\*\shellex\-ContextMenuHandlers\BriefcaseMenu'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Folder\ShellEx\ContextMenuHandlers\BriefcaseMenu' 'HKLM\zSOFTWARE\Classes\Folder\ShellEx\-ContextMenuHandlers\BriefcaseMenu'
# O085 禁用新建“ZIP/RAR文件”右键菜单（by 莫失莫忘）
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\.rar\ShellNew' 'HKLM\zSOFTWARE\Classes\.rar\-ShellNew'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\.zip\ShellNew' 'HKLM\zSOFTWARE\Classes\.zip\-ShellNew'
# O086 禁用文件、磁盘以及属性的“还原以前版本”右键菜单（by 莫失莫忘）
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\AllFilesystemObjects\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}' 'HKLM\zSOFTWARE\Classes\AllFilesystemObjects\shellex\-ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\AllFilesystemObjects\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}' 'HKLM\zSOFTWARE\Classes\AllFilesystemObjects\shellex\-PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\CLSID\{450D8FBA-AD25-11D0-98A8-0800361B1103}\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}' 'HKLM\zSOFTWARE\Classes\CLSID\{450D8FBA-AD25-11D0-98A8-0800361B1103}\shellex\-ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\CLSID\{450D8FBA-AD25-11D0-98A8-0800361B1103}\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}' 'HKLM\zSOFTWARE\Classes\CLSID\{450D8FBA-AD25-11D0-98A8-0800361B1103}\shellex\-PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Directory\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}' 'HKLM\zSOFTWARE\Classes\Directory\shellex\-ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Directory\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}' 'HKLM\zSOFTWARE\Classes\Directory\shellex\-PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Drive\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}' 'HKLM\zSOFTWARE\Classes\Drive\shellex\-ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Drive\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}' 'HKLM\zSOFTWARE\Classes\Drive\shellex\-PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}'
# O087 禁用桌面的“小工具”右键菜单
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Directory\Background\shellex\ContextMenuHandlers\Gadgets' 'HKLM\zSOFTWARE\Classes\Directory\Background\shellex\-ContextMenuHandlers\Gadgets'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\DesktopBackground\Shell\Gadgets' 'HKLM\zSOFTWARE\Classes\DesktopBackground\-Shell\Gadgets'
# O088 禁用文件、文件夹、桌面以及所有对象的“共享文件夹同步”右键菜单
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Directory\Background\shellex\ContextMenuHandlers\XXX Groove GFS Context Menu Handler XXX' 'HKLM\zSOFTWARE\Classes\Directory\Background\shellex\-ContextMenuHandlers\XXX Groove GFS Context Menu Handler XXX'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\*\shellex\ContextMenuHandlers\XXX Groove GFS Context Menu Handler XXX' 'HKLM\zSOFTWARE\Classes\*\shellex\-ContextMenuHandlers\XXX Groove GFS Context Menu Handler XXX'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Directory\shellex\ContextMenuHandlers\XXX Groove GFS Context Menu Handler XXX' 'HKLM\zSOFTWARE\Classes\Directory\shellex\-ContextMenuHandlers\XXX Groove GFS Context Menu Handler XXX'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Folder\ShellEx\ContextMenuHandlers\XXX Groove GFS Context Menu Handler XXX' 'HKLM\zSOFTWARE\Classes\Folder\ShellEx\-ContextMenuHandlers\XXX Groove GFS Context Menu Handler XXX'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\AllFilesystemObjects\shellex\ContextMenuHandlers\XXX Groove GFS Context Menu Handler XXX' 'HKLM\zSOFTWARE\Classes\AllFilesystemObjects\shellex\-ContextMenuHandlers\XXX Groove GFS Context Menu Handler XXX'
# O089 禁用磁盘的“刻录到光盘”右键菜单
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Drive\shellex\ContextMenuHandlers\{fbeb8a05-beee-4442-804e-409d6c4515e9}' 'HKLM\zSOFTWARE\Classes\Drive\shellex\-ContextMenuHandlers\{fbeb8a05-beee-4442-804e-409d6c4515e9}'
# O095 禁用文件的“OneDrive文件同步”右键菜单
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\*\shellex\ContextMenuHandlers\ FileSyncEx' 'HKLM\zSOFTWARE\Classes\*\-shellex\ContextMenuHandlers\ FileSyncEx'
# O096 禁用文件、目录、桌面、所有对象的“工作文件夹”右键菜单
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\*\shellex\ContextMenuHandlers\WorkFolders' 'HKLM\zSOFTWARE\Classes\*\-shellex\ContextMenuHandlers\WorkFolders'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Directory\shellex\ContextMenuHandlers\WorkFolders' 'HKLM\zSOFTWARE\Classes\Directory\-shellex\ContextMenuHandlers\WorkFolders'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Directory\background\shellex\ContextMenuHandlers\WorkFolders' 'HKLM\zSOFTWARE\Classes\Directory\background\-shellex\ContextMenuHandlers\WorkFolders'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\AllFilesystemObjects\shell\LaunchWorkfoldersControl' 'HKLM\zSOFTWARE\Classes\AllFilesystemObjects\-shell\LaunchWorkfoldersControl'
# O097 禁用文件的“View 3D”右键菜单（by Cloud）
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\SystemFileAssociations\.bmp\Shell\T3D Print' 'HKLM\zSOFTWARE\Classes\DismRegBackup\SystemFileAssociations\.bmp\Shell\T3D Print'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\SystemFileAssociations\.jpg\Shell\T3D Print' 'HKLM\zSOFTWARE\Classes\DismRegBackup\SystemFileAssociations\.jpg\Shell\T3D Print'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\SystemFileAssociations\.png\Shell\T3D Print' 'HKLM\zSOFTWARE\Classes\DismRegBackup\SystemFileAssociations\.png\Shell\T3D Print'
# O098 禁用文件的“画图 3D”右键菜单（by Cloud）
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\SystemFileAssociations\.tiff\Shell\3D Edit' 'HKLM\zSOFTWARE\Classes\DismRegBackup\SystemFileAssociations\.tiff\Shell\3D Edit'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\SystemFileAssociations\.tif\Shell\3D Edit' 'HKLM\zSOFTWARE\Classes\DismRegBackup\SystemFileAssociations\.tif\Shell\3D Edit'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\SystemFileAssociations\.png\Shell\3D Edit' 'HKLM\zSOFTWARE\Classes\DismRegBackup\SystemFileAssociations\.png\Shell\3D Edit'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\SystemFileAssociations\.jpg\Shell\3D Edit' 'HKLM\zSOFTWARE\Classes\DismRegBackup\SystemFileAssociations\.jpg\Shell\3D Edit'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\SystemFileAssociations\.jpeg\Shell\3D Edit' 'HKLM\zSOFTWARE\Classes\DismRegBackup\SystemFileAssociations\.jpeg\Shell\3D Edit'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\SystemFileAssociations\.jpe\Shell\3D Edit' 'HKLM\zSOFTWARE\Classes\DismRegBackup\SystemFileAssociations\.jpe\Shell\3D Edit'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\SystemFileAssociations\.jfif\Shell\3D Edit' 'HKLM\zSOFTWARE\Classes\DismRegBackup\SystemFileAssociations\.jfif\Shell\3D Edit'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\SystemFileAssociations\.gif\Shell\3D Edit' 'HKLM\zSOFTWARE\Classes\DismRegBackup\SystemFileAssociations\.gif\Shell\3D Edit'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\SystemFileAssociations\.fbx\Shell\3D Edit' 'HKLM\zSOFTWARE\Classes\DismRegBackup\SystemFileAssociations\.fbx\Shell\3D Edit'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\SystemFileAssociations\.bmp\Shell\3D Edit' 'HKLM\zSOFTWARE\Classes\DismRegBackup\SystemFileAssociations\.bmp\Shell\3D Edit'
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\SystemFileAssociations\.3mf\Shell\3D Edit' 'HKLM\zSOFTWARE\Classes\DismRegBackup\SystemFileAssociations\.3mf\Shell\3D Edit'
# O099 禁用文件夹的“包含到库中”右键菜单（by choyri）
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Folder\shellex\ContextMenuHandlers\Library Location' 'HKLM\zSOFTWARE\Classes\Folder\shellex\-ContextMenuHandlers\Library Location'
# O100 禁用桌面的“NVIDIA 控制面板”右键菜单（by choyri）
Move-RegistryKey 'HKLM\zSOFTWARE\Classes\Directory\Background\shellex\ContextMenuHandlers\NvCplDesktopContext' 'HKLM\zSOFTWARE\Classes\Directory\Background\shellex\-ContextMenuHandlers\NvCplDesktopContext'

Write-Output "Dism++ 优化项应用完成。"
if ($script:LiveDefaultHiveMounted) {
    Dismount-RegistryHive 'HKLM\zDEFUSER'
    $script:LiveDefaultHiveMounted = $false
}
Write-Output ' '

# ===== 激进模式专属：禁用 Windows Update 与 Windows Defender（纯激进与保留 Edge 激进模式均执行）=====
if ($aggressiveCore) {
    Write-Output "【激进模式】正在禁用 Windows Update..."
    Write-Output "正在设置注册表：写入「下次登录时」停止 Windows 更新服务的 RunOnce 项（net stop wuauserv）..."
    Set-RegistryValue "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" 'StopWUPostOOBE1' 'REG_SZ' 'net stop wuauserv'
    Write-Output "正在设置注册表：写入「下次登录时」停止 Windows 更新服务的 RunOnce 项（sc stop wuauserv）..."
    Set-RegistryValue "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" 'StopWUPostOOBE2' 'REG_SZ' 'sc stop wuauserv'
    Write-Output "正在设置注册表：写入「下次登录时」禁用 wuauserv 服务启动的 RunOnce 项..."
    Set-RegistryValue "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" 'StopWUPostOOBE3' 'REG_SZ' 'sc config wuauserv start= disabled'
    Write-Output "正在设置注册表：写入「下次登录时」禁用 wuauserv 的 RunOnce 项（CurrentControlSet）..."
    Set-RegistryValue "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" 'DisbaleWUPostOOBE1' 'REG_SZ' 'reg add HKLM\SYSTEM\CurrentControlSet\Services\wuauserv /v Start /t REG_DWORD /d 4 /f'
    Write-Output "正在设置注册表：写入「下次登录时」禁用 wuauserv 的 RunOnce 项（ControlSet001）..."
    Set-RegistryValue "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" 'DisbaleWUPostOOBE2' 'REG_SZ' 'reg add HKLM\SYSTEM\ControlSet001\Services\wuauserv /v Start /t REG_DWORD /d 4 /f'
    Write-Output "正在设置注册表：禁止连接 Windows Update 联网位置..."
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'DoNotConnectToWindowsUpdateInternetLocations' 'REG_DWORD' '1'
    Write-Output "正在设置注册表：禁用 Windows Update 访问..."
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'DisableWindowsUpdateAccess' 'REG_DWORD' '1'
    Write-Output "正在设置注册表：将更新服务器指向 localhost（WUServer）..."
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'WUServer' 'REG_SZ' 'localhost'
    Write-Output "正在设置注册表：将更新状态服务器指向 localhost（WUStatusServer）..."
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'WUStatusServer' 'REG_SZ' 'localhost'
    Write-Output "正在设置注册表：将备用更新服务地址指向 localhost..."
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'UpdateServiceUrlAlternate' 'REG_SZ' 'localhost'
    Write-Output "正在设置注册表：启用本地更新服务器（UseWUServer）..."
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'UseWUServer' 'REG_DWORD' '1'
    Write-Output "正在设置注册表：OOBE 阶段禁用联机..."
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE' 'DisableOnline' 'REG_DWORD' '1'
    Write-Output "正在设置注册表：禁用 wuauserv 服务启动（Start=4）..."
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\wuauserv' 'Start' 'REG_DWORD' '4'
    if ($script:LiveMode) {
        # 活动系统：这两个是真实的服务键，删掉后要恢复只能手工重建（SFC/DISM 一般不还原服务键），
        # 而本段后面已经用 Stop-Service + Set-Service -StartupType Disabled 达到禁用目的，故不删。
        Write-Output "活动系统：跳过删除 WaaSMedicSVC / UsoSvc 服务项（删键难以回滚，改用禁用服务的方式）。"
    } elseif ($script:WUHandling -eq 'block') {
        # 仅屏蔽：不删任何服务键，改为禁用（Start=4），装好后可按 README《解除禁用》章节恢复。
        # DoSvc（传递优化）一并禁用，堵住更新/驱动内容传输通道。
        Write-Output "【仅屏蔽】禁用 Windows Update 编排服务与传递优化（服务键全部保留，可恢复）..."
        Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\UsoSvc' 'Start' 'REG_DWORD' '4'
        Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\WaaSMedicSVC' 'Start' 'REG_DWORD' '4'
        Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\DoSvc' 'Start' 'REG_DWORD' '4'
    } else {
        Write-Output "正在删除注册表：WaaSMedicSVC 服务项..."
        Remove-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\WaaSMedicSVC'
        Write-Output "正在删除注册表：UsoSvc 服务项..."
        Remove-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\UsoSvc'
    }
    Write-Output "正在设置注册表：关闭自动更新（NoAutoUpdate）..."
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'NoAutoUpdate' 'REG_DWORD' '1'

    Write-Output "【激进模式】正在禁用 Windows Defender..."
    $servicePaths = @("WinDefend","WdNisSvc","WdNisDrv","WdFilter","Sense")
    foreach ($path in $servicePaths) {
        Write-Output "正在设置注册表：禁用 Defender 服务 $path（Start=4）..."
        if ($script:LiveMode) {
            # 活动系统：走 helper 以套用路径映射（zSYSTEM → SYSTEM、ControlSet001 → CurrentControlSet）
            Set-RegistryValue "HKLM\zSYSTEM\ControlSet001\Services\$path" 'Start' 'REG_DWORD' '4'
        } else {
            # 制作 ISO：与活动系统一致走 helper（映像模式下路径原样返回），
            # 避免注册表提供程序写入已加载的 hive、给随后的卸载留下句柄隐患
            Set-RegistryValue "HKLM\zSYSTEM\ControlSet001\Services\$path" 'Start' 'REG_DWORD' '4'
        }
    }
    Write-Output "正在设置注册表：隐藏病毒防护与 Windows 更新设置页..."
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'SettingsPageVisibility' 'REG_SZ' 'hide:virus;windowsupdate'
    if ($script:LiveMode) {
        # 活动系统：注册表只代表"下次启动"的状态，这里直接把服务停掉并禁用，立即生效
        Write-Output "正在停止并禁用相关服务（活动系统）..."
        foreach ($svc in @('wuauserv','UsoSvc','WaaSMedicSvc','WinDefend','WdNisSvc','Sense')) {
            try {
                Stop-Service -Name $svc -Force -ErrorAction Stop
                Write-Output "已停止服务：$svc"
            } catch {
                Write-Output "停止服务未成功（可能未在运行或受系统保护）：$svc"
            }
            try {
                Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop
                Write-Output "已禁用服务启动：$svc"
            } catch {
                Write-Output "禁用服务启动未成功（通常受系统保护）：$svc"
            }
        }
        Write-Output "提示：若系统开启了「篡改防护」，Windows Defender 相关设置可能被系统自动改回。"
    }
    Write-Output "Windows Update 与 Defender 已禁用。"
}

# ===== 激进模式专属（仅制作 ISO）：外设驱动/服务裁剪 + 字体裁剪 =====
# 范围（按用户确认的清单执行，全部不可逆 —— 激进模式装完无法加回）：
#   - 打印机：只删驱动，保留 Spooler / PrintWorkflow / PrintNotify 服务 —— 保住「打印成 PDF」，
#     将来需要时仍可安装厂商打印驱动；同时清空打印驱动缓存目录（目录本身保留）。
#   - 扫描仪：删 scan* 驱动 + WIA 服务（stisvc）。
#   - 传真机：删 Fax 服务与 fxs* 文件/驱动。
#   - 摄像头：删 usbvideo 驱动 + 帧服务器服务（frameserver / FrameServerMonitor）。
#   - 手机：App 层已在预装应用清单移除；USB 传文件（WPD/MTP）按用户要求保留，此处不动。
#   - 字体：只删「极少使用的外语字体」（蒙古文 / 藏文 / 缅甸文 / 印度语系等，删除名单制），
#     其余字体一概不精简；文件与 Fonts 注册表值成对清理
#     （FNTCACHE.DAT 系统会自动重建，无需处理）。
if ($aggressiveCore -and -not $script:LiveMode) {

    # --- 外设驱动：DriverStore\FileRepository 与 Windows\INF 成对清理 ---
    # 采用精确全名匹配（INF 基名），不使用通配符，避免误删。
    # INF 基名 = 组件目录名去掉「_架构_哈希」后缀，是驱动跨镜像的稳定全名；
    # 名单来自对 26H2 Business x64 镜像（映像 3）的实际枚举（16 个组件目录 / 15 个 INF）。
    # 注：该镜像不含扫描仪与传真类驱动（FileRepository 与 INF 层均无 scan*/fxs* 条目），
    #     扫描与传真在本镜像中仅涉及 stisvc / Fax 两个服务键（见下方服务清理）。
    Write-Output "【激进模式】正在裁剪外设驱动（打印类 13 项 + USB 打印 + USB 摄像头）..."
    $trimInfNames = @(
        # 微软类打印驱动
        'prnge001.inf', 'prnms002.inf', 'prnms003.inf', 'prnms004.inf', 'prnms005.inf',
        'prnms007.inf', 'prnms008.inf', 'prnms010.inf', 'prnms011.inf', 'prnms012.inf',
        'prnms013.inf', 'prnms014.inf', 'prnms015.inf',
        # USB 打印支持
        'usbprint.inf',
        # USB 摄像头
        'usbvideo.inf'
    )
    $driverRepo = "$ScratchDir\Windows\System32\DriverStore\FileRepository"
    $peripheralRemoved = 0
    $drvDirs = @(Get-ChildItem -Path $driverRepo -Directory -ErrorAction SilentlyContinue)
    foreach ($dir in $drvDirs) {
        # 组件目录名格式：<INF 基名>_<架构>_<哈希>；截取 .inf 为止做精确比对
        $m = [regex]::Match($dir.Name, '^(.+\.inf)_')
        $infName = if ($m.Success) { $m.Groups[1].Value } else { $dir.Name }
        if ($trimInfNames -icontains $infName) {
            Grant-AdminFullAccess $dir.FullName -Recurse
            Remove-Item -Path $dir.FullName -Recurse -Force | Out-Null
            $peripheralRemoved++
        }
    }
    Write-Output "已删除 FileRepository 中的外设驱动目录（共 $peripheralRemoved 个）。"

    $infDir = "$ScratchDir\Windows\INF"
    $infRemoved = 0
    $infAll = @(Get-ChildItem -Path $infDir -File -ErrorAction SilentlyContinue)
    foreach ($infFile in $infAll) {
        # xxx.inf / xxx.pnf → 基名 + .inf，与名单中的 INF 全名精确比对（大小写不敏感）
        $ext = $infFile.Extension.ToLower()
        if ($ext -ne '.inf' -and $ext -ne '.pnf') { continue }
        $infFullName = [IO.Path]::GetFileNameWithoutExtension($infFile.Name) + '.inf'
        if ($trimInfNames -icontains $infFullName) {
            Grant-AdminFullAccess $infFile.FullName
            Remove-Item -Path $infFile.FullName -Force | Out-Null
            $infRemoved++
        }
    }
    Write-Output "已删除 INF 目录中的同名驱动定义（共 $infRemoved 个）。"

    # 打印驱动缓存：清空内容、保留目录本身（Spooler 服务仍在，启动时会自动重建空缓存）
    $spoolDrivers = "$ScratchDir\Windows\System32\spool\drivers"
    if (Test-Path $spoolDrivers) {
        Grant-AdminFullAccess $spoolDrivers -Recurse
        $spoolChildren = @(Get-ChildItem -Path $spoolDrivers -ErrorAction SilentlyContinue)
        foreach ($child in $spoolChildren) {
            Remove-Item -Path $child.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
        Write-Output "已清空打印驱动缓存目录（共 $($spoolChildren.Count) 项，目录本身保留）：$spoolDrivers"
    }

    # --- 外设相关服务注册表项（打印机相关服务按要求保留）---
    Write-Output "【激进模式】正在删除外设相关服务注册表项..."
    Remove-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\stisvc'              # 扫描仪：Windows 图像采集 (WIA)
    Remove-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\Fax'                 # 传真机
    Remove-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\frameserver'         # 摄像头：帧服务器
    Remove-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\FrameServerMonitor'  # 摄像头：帧服务器监视
    Write-Output "打印机相关服务（Spooler / PrintWorkflow / PrintNotify）已保留。"

    # --- 字体裁剪：只删「极少使用的外语字体」，其余字体一概不精简 ---
    # 采用删除名单制 + 精确全名匹配（比保留名单制+通配符安全：名单外的字体一律保留，
    # 不会再出现图标变方块一类误删）。
    # 教训：SegoeIcons.ttf（= Segoe Fluent Icons）曾因文件名不在保留名单被误删，导致任务栏与
    # 截图工具等系统图标全部变方块（实机复现）；改为删除名单后此类风险即从机制上消除。
    Write-Output "【激进模式】正在裁剪极少使用的外语字体（其余字体一概保留）..."
    $fontsDir = "$ScratchDir\Windows\Fonts"
    # 精确全名匹配（大小写不敏感），不使用通配符；名单来自对 26H2 镜像 Fonts 目录的实际枚举。
    $fontTrimList = @(
        'monbaiti.ttf',                  # 传统蒙古文
        'himalaya.ttf',                  # 藏文（Microsoft Himalaya）
        'ntailu.ttf', 'ntailub.ttf',     # 新傣仂文
        'taile.ttf', 'taileb.ttf',       # 傣哪文（Tai Le）
        'phagspa.ttf', 'phagspab.ttf',   # 八思巴文
        'msyi.ttf',                      # 彝文（Microsoft Yi Baiti）
        'javatext.ttf',                  # 爪哇文
        'mmrtext.ttf', 'mmrtextb.ttf',   # 缅甸文
        'gadugi.ttf', 'gadugib.ttf',     # 埃塞俄比亚文（吉兹字母）
        'ebrima.ttf', 'ebrimabd.ttf',    # 西非文种（Ebrima UI 回退）
        'Nirmala.ttc',                   # 印度语系（Nirmala UI 回退）
        'LeelUIsl.ttf', 'LeelaUIb.ttf', 'LeelawUI.ttf',  # Leelawadee UI（泰文等 UI 回退）
        'seguihis.ttf'                   # Segoe UI Historic（古文字）
    )
    $fontExts = @('.ttf', '.ttc', '.otf', '.fon')  # 只删字体文件：StaticCache.dat / desktop.ini 等非字体文件不动
    $deletedFontFiles = @{}
    $allFonts = @(Get-ChildItem -Path $fontsDir -File -ErrorAction SilentlyContinue)
    $fontDeletedCount = 0
    foreach ($font in $allFonts) {
        if ($font.Extension -notin $fontExts) { continue }  # 非字体文件（缓存/ini 等）一律不动
        if ($fontTrimList -icontains $font.Name) {  # -icontains 大小写不敏感的精确全名比对
            Remove-Item -Path $font.FullName -Force -ErrorAction SilentlyContinue
            $deletedFontFiles[$font.Name.ToLower()] = $true
            $fontDeletedCount++
        }
    }
    Write-Output "已删除极少使用的外语字体（共 $fontDeletedCount 个，其余 $($allFonts.Count - $fontDeletedCount) 个字体文件全部保留）。"

    # 同步清理 Fonts 注册表值：值的数据就是字体文件名，只删文件会留下指向空文件的注册表残值
    $fontsRegKey = 'HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    if (Test-RegKeyExists $fontsRegKey) {
        $queryOutput = & 'reg' 'query' $fontsRegKey 2>&1
        $fontValueRemoved = 0
        foreach ($line in $queryOutput) {
            # reg query 行格式：<值名>    REG_SZ    <字体文件名>
            if ($line -match '^\s*(.+?)\s+REG_(?:SZ|EXPAND_SZ)\s+(\S+)\s*$') {
                if ($deletedFontFiles.ContainsKey($Matches[2].ToLower())) {
                    & 'reg' 'delete' $fontsRegKey '/v' $Matches[1] '/f' | Out-Null
                    $fontValueRemoved++
                }
            }
        }
        Write-Output "已同步清理 Fonts 注册表值（共 $fontValueRemoved 个）。"
    }
    Write-Output "外设驱动与字体裁剪完成。"
}

if (-not $script:LiveMode) {
    Write-Output "正在卸载注册表..."
    Dismount-RegistryHive 'HKLM\zCOMPONENTS'
    Dismount-RegistryHive 'HKLM\zDEFAULT'
    Dismount-RegistryHive 'HKLM\zNTUSER'
    Dismount-RegistryHive 'HKLM\zSOFTWARE'
    Dismount-RegistryHive 'HKLM\zSYSTEM'
}

# ===== 垃圾清理（三种模式 × 两种操作对象共用）=====
# 基准目录：制作 ISO 为挂载映像目录（$ScratchDir）；精简本机为系统盘（如 C:）。
$junkRoot = if ($script:LiveMode) { $env:SystemDrive } else { $ScratchDir }
Invoke-JunkCleanup -Root $junkRoot

Write-Output ' '
# ===== 以下为 ISO 专属：卸载映像 → 导出 → 处理 boot.wim → 生成 ISO → 收尾清理 =====
if (-not $script:LiveMode) {
    Write-Output "注意：接下来要把本次全部改动压缩写回 install.wim。整体替换 WinSxS 之后，"
    Write-Output "      这一步要提交数万条文件删除并重新压缩保留的组件目录，是全程最慢的一步，"
    Write-Output "      需要耐心等待很长时间，且期间不会输出任何进度 —— 不是卡死，请勿中断、勿关闭窗口。"
    Write-Output "正在卸载映像（压缩写回中，请耐心等待）..."
    try {
        Dismount-WindowsImage -Path $ScratchDir -Save -ErrorAction Stop
        Write-Output "映像卸载并保存完成。"
    } catch {
        Write-Output "卸载映像失败：$_"
        Write-Output "请以管理员身份执行 Dism.exe /Cleanup-WIM 清理挂载，并检查 $ExtractDir\sources\install.wim 是否仍可用。"
        Stop-AndExit
    }
    Write-Output "正在导出映像..."
    Dism.exe /Export-Image /SourceImageFile:"$ExtractDir\sources\install.wim" /SourceIndex:$index /DestinationImageFile:"$ExtractDir\sources\install2.wim" /Compress:max
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path "$ExtractDir\sources\install2.wim")) {
        Write-Output "导出映像失败：DISM 退出码 $LASTEXITCODE，且未生成 install2.wim。"
        Write-Output "为避免丢失原始 install.wim，脚本不删除它，就此退出。"
        Write-Output "处理：确认磁盘剩余空间（建议 30GB 以上）后重新运行。"
        Stop-AndExit
    }
    Write-Output "导出完成，替换 install.wim。"
    Remove-Item -Path "$ExtractDir\sources\install.wim" -Force | Out-Null
    Rename-Item -Path "$ExtractDir\sources\install2.wim" -NewName "install.wim" | Out-Null
    Write-Output "Windows 映像已完成。继续处理 boot.wim。"
    Start-Sleep -Seconds 2
    Clear-Host
    Write-Output "正在挂载启动映像："
    $wimFilePath = "$ExtractDir\sources\boot.wim"
    & takeown "/F" $wimFilePath | Out-Null
    & icacls $wimFilePath "/grant" "$($adminGroup.Value):(F)" | Out-Null
    Set-ItemProperty -Path $wimFilePath -Name IsReadOnly -Value $false
    try {
        Mount-WindowsImage -ImagePath $ExtractDir\sources\boot.wim -Index 2 -Path $ScratchDir -ErrorAction Stop
    } catch {
        Write-Output "挂载 boot.wim 失败：$_"
        Write-Output "请以管理员身份执行 Dism.exe /Cleanup-WIM 清理挂载后重试。"
        Stop-AndExit
    }
    # 把应答文件注入 boot.wim 根部（即 WinPE 运行时的 X:\Autounattend.xml）：确保安装程序必然读到 windowsPE 段，
    # 并由安装程序自动流转为 %WINDIR%\Panther\unattend.xml，供 specialize / oobeSystem 等后续阶段使用
    Copy-Item -Path "$PSScriptRoot\autounattend.xml" -Destination "$ScratchDir\Autounattend.xml" -Force | Out-Null
    Write-Output "已将应答文件注入 boot.wim 根目录（Autounattend.xml）。"
    Write-Output "正在加载注册表..."
    Mount-RegistryHive 'HKLM\zCOMPONENTS' "$ScratchDir\Windows\System32\config\COMPONENTS"
    Mount-RegistryHive 'HKLM\zDEFAULT' "$ScratchDir\Windows\System32\config\default"
    Mount-RegistryHive 'HKLM\zNTUSER' "$ScratchDir\Users\Default\ntuser.dat"
    Mount-RegistryHive 'HKLM\zSOFTWARE' "$ScratchDir\Windows\System32\config\SOFTWARE"
    Mount-RegistryHive 'HKLM\zSYSTEM' "$ScratchDir\Windows\System32\config\SYSTEM"

    Write-Output "正在绕过系统要求（安装映像）："
    Set-RegistryValue 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' 'SV1' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' 'SV2' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' 'SV1' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' 'SV2' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassCPUCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassRAMCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassSecureBootCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassStorageCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassTPMCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\MoSetup' 'AllowUpgradesWithUnsupportedTPMOrCPU' 'REG_DWORD' '1'
    Write-Output "调整完成！"

    Write-Output "正在卸载注册表..."
    Dismount-RegistryHive 'HKLM\zCOMPONENTS'
    Dismount-RegistryHive 'HKLM\zDEFAULT'
    Dismount-RegistryHive 'HKLM\zNTUSER'
    Dismount-RegistryHive 'HKLM\zSOFTWARE'
    Dismount-RegistryHive 'HKLM\zSYSTEM'

    Write-Output "正在卸载映像..."
    try {
        Dismount-WindowsImage -Path $ScratchDir -Save -ErrorAction Stop
        Write-Output "boot.wim 卸载并保存完成。"
    } catch {
        Write-Output "卸载 boot.wim 失败：$_"
        Write-Output "请以管理员身份执行 Dism.exe /Cleanup-WIM 清理挂载后重试。"
        Stop-AndExit
    }
    Clear-Host
    Write-Output "tiny11 映像已完成。正在制作 ISO..."
    Write-Output "正在复制用于绕过 OOBE 微软账号的应答文件..."
    Copy-Item -Path "$PSScriptRoot\autounattend.xml" -Destination "$ExtractDir\autounattend.xml" -Force | Out-Null
    # 把整个项目放进 ISO 的 tiny11builder\ 子目录（脚本 / 文档 / 应答文件），
    # 拿到镜像的人可直接运行脚本或阅读说明；根目录只放一个 readme.txt 做指引。
    # 文件清单与 GitHub 仓库内容对应 —— 新增项目文件时需同步维护此清单。
    Write-Output "正在复制项目文件到 ISO 的 tiny11builder\ 目录..."
    $projectFiles = @(
        'tiny11builder.ps1',
        '启动.cmd',
        'README.md',
        'autounattend.xml',
        '预装清单_26H2Business.md',
        '.gitignore'
    )
    New-Item -ItemType Directory -Force -Path "$ExtractDir\tiny11builder" | Out-Null
    $copiedCount = 0
    foreach ($pf in $projectFiles) {
        if (Test-Path -LiteralPath "$PSScriptRoot\$pf") {
            Copy-Item -LiteralPath "$PSScriptRoot\$pf" -Destination "$ExtractDir\tiny11builder\$pf" -Force
            $copiedCount++
        }
    }
    Write-Output "已复制 $copiedCount 个项目文件到 ISO 的 tiny11builder\ 目录。"
    # 根目录生成单行指引（UTF-8 BOM，记事本可直接正常显示中文）
    Set-Content -Path "$ExtractDir\readme.txt" -Value '如需精简系统或制作精简镜像，请先把 tiny11builder 文件夹复制到硬盘，再运行其中的「启动.cmd」。详细说明见 tiny11builder\README.md' -Encoding UTF8
    Write-Output "已生成根目录 readme.txt 指引。"
    Write-Output "正在创建 ISO 映像..."
    $ADKDepTools = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\$hostarchitecture\Oscdimg"
    $localOSCDIMGPath = "$PSScriptRoot\oscdimg.exe"

    if ([System.IO.Directory]::Exists($ADKDepTools)) {
        Write-Output "将使用系统 ADK 中的 oscdimg.exe。"
        $OSCDIMG = "$ADKDepTools\oscdimg.exe"
    } else {
        Write-Output "未找到 ADK 目录，将使用随附的 oscdimg.exe。"

        $url = "https://msdl.microsoft.com/download/symbols/oscdimg.exe/3D44737265000/oscdimg.exe"

        if (-not (Test-Path -Path $localOSCDIMGPath)) {
            Write-Output "正在下载 oscdimg.exe..."
            Invoke-WebRequest -Uri $url -OutFile $localOSCDIMGPath

            if (Test-Path $localOSCDIMGPath) {
                Write-Output "oscdimg.exe 下载成功。"
            } else {
                Write-Output "无法下载 oscdimg.exe（网络不可用或被拦截）。"
                Write-Output "处理：确认网络可用后重试，或手动获取 oscdimg.exe 放到脚本目录 $PSScriptRoot 下。"
                Stop-AndExit
            }
        } else {
            Write-Output "oscdimg.exe 已存在于本地。"
        }

        $OSCDIMG = $localOSCDIMGPath
    }

    # 输出文件名带生成时刻的时间戳，避免多次运行互相覆盖。
    # 格式：WIN11_<版型>_<版本>_<精简模式>_<时间戳>.iso；与运行日志名（LOG\tiny11_<时间戳>.log）的时间戳一致，便于把产物与它的构建日志配对。
    $modeTag = switch ($Mode) {
        'normal' { 'TINY' }
        'aggressive' { 'CORE' }
        'aggressive_keepedge' { 'CORE_EDGE' }
        default { 'TINY' }
    }
    # 语言前缀（微软官方 ISO 命名风格，如 zh-cn）：取默认系统界面语言代码小写，读不到回退 multi
    $langPrefix = if ($languageCode) { $languageCode.ToLower() } else { 'multi' }
    $isoOutputPath = "$PSScriptRoot\${langPrefix}_windows_11_$($script:OSEdition)_$($script:OSDisplayVersion)_${modeTag}_$(Get-Date -Format 'yyyyMMdd_HHmmss').iso"
    # ISO 卷标：WIN11_<版本>_<精简模式>（版本如 26H2/25H2，取自镜像注册表 DisplayVersion）
    $isoVolumeLabel = "WIN11_$($script:OSDisplayVersion)_$modeTag"
    if ($isoVolumeLabel.Length -gt 32) { $isoVolumeLabel = $isoVolumeLabel.Substring(0, 32) }  # 卷标上限 32 字符
    Write-Output "正在生成 ISO：$isoOutputPath（卷标 $isoVolumeLabel）"
    & "$OSCDIMG" '-m' '-o' '-u2' '-udfver102' "-l$isoVolumeLabel" "-bootdata:2#p0,e,b$ExtractDir\boot\etfsboot.com#pEF,e,b$ExtractDir\efi\microsoft\boot\efisys.bin" "$ExtractDir" "$isoOutputPath"
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $isoOutputPath)) {
        Write-Output "生成 ISO 失败：oscdimg 退出码 $LASTEXITCODE，且未生成 $isoOutputPath。"
        Write-Output "临时目录 $ExtractDir 与 $ScratchDir 已保留便于排查，不会自动清理。"
        Stop-AndExit
    }
    Write-Output "ISO 已生成：$isoOutputPath"

    # 收尾：按「确认后全程无人值守」的约定，此处不再等待按键，直接清理
    Write-Output "制作完成！"
    Write-Output "正在清理..."
    # rd /s /q 是 cmd 内建命令，必须经 cmd /c 调用（PowerShell 中 rd 是 Remove-Item 的别名，
    # 直接写 rd /s /q 会报「找不到参数 s」）。相比 Remove-Item -Recurse -Force，删上万个小文件快一个数量级。
    & cmd /c rd /s /q "$ExtractDir"
    & cmd /c rd /s /q "$ScratchDir"
    if ((Test-Path "$ExtractDir") -or (Test-Path "$ScratchDir")) {
        Write-Output "部分临时目录未能删除，请手动清理：$ExtractDir 与 $ScratchDir"
    }
    # 专用容器 temp 只在已空时才删除（rd 不带 /s，目录非空会直接失败、不动任何东西），
    # 这样万一用户在同一个 temp 下放了自己的东西，也绝不会被连带删掉。
    if (Test-Path -LiteralPath $ScratchRoot) {
        if (@(Get-ChildItem -LiteralPath $ScratchRoot -Force -ErrorAction SilentlyContinue).Count -eq 0) {
            & cmd /c rd /q "$ScratchRoot"
        } else {
            Write-Output "容器目录 $ScratchRoot 下还有其他内容，未删除："
            foreach ($item in @(Get-ChildItem -LiteralPath $ScratchRoot -Force -ErrorAction SilentlyContinue)) {
                Write-Output "      $($item.FullName)"
            }
        }
    }
    Write-Output "正在删除 oscdimg.exe..."
    Remove-Item -Path "$PSScriptRoot\oscdimg.exe" -Force -ErrorAction SilentlyContinue
}


if ($script:LiveMode) {
    Write-Output "精简完成！"
    Write-Output "建议重启一次，让服务禁用、组件存储清理等改动完全生效。"
}

#---------[ 收尾：先释放单实例锁、结束日志，再打完成横幅 ]---------#
# 顺序很关键：先把日志与锁收干净，最后才把结果打到控制台上。
# 图形界面流程中由本脚本装载的 ISO 在这里自动弹出（只弹「本脚本挂的」），
# 用户做完就能立即移动 / 删除 / 重命名成品；弹不掉时会在横幅里提示手动弹出。
# Stop-Transcript 会由 PowerShell 自身在控制台上打印一行「已停止脚本，输出文件为 …」，
# 这行无法被重定向或抑制（它不经 PowerShell 输出流），紧跟在「制作完成」之后容易被误读成
# 「脚本异常停止」。因此停掉转录后立刻清屏并重打完成横幅，让用户看到的最后画面是明确的结果。
$isoDismounted = Dismount-GuiMountedIsos
Remove-RunningLock
Stop-Transcript | Out-Null
try { Clear-Host } catch { }
if ($script:LiveMode) {
    Write-ResultBanner -Color 'Green' -Lines @(
        '精简已完成。',
        '建议重启一次，让服务禁用、组件存储清理等改动完全生效。',
        "日志保存在：$PSScriptRoot\LOG"
    )
} else {
    $bannerLines = @(
        '制作已完成。',
        '生成的 ISO 文件：',
        $isoOutputPath,
        '',
        "日志保存在：$PSScriptRoot\LOG"
    )
    if (-not $isoDismounted) {
        $bannerLines += '参数窗口中装载的 ISO 未能自动弹出，请在「此电脑」中右键它选择「弹出」。'
    }
    Write-ResultBanner -Color 'Green' -Lines $bannerLines
}

exit
