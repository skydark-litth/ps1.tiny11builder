@echo off
title tiny11builder
setlocal
cd /d "%~dp0"

rem ==================================================================
rem  tiny11builder 启动器
rem  让不使用命令行的人也能运行本工具：自动请求管理员权限、自动放开
rem  执行策略、自动切到脚本所在目录，运行结束后保留窗口以便查看结果。
rem  用法：直接双击本文件即可（也可以在本文件后面跟 -ISO/-SCRATCH/
rem        -Mode 等参数，走原来的命令行方式）。
rem ==================================================================

rem ---------- 1. 脚本文件是否存在 ----------
if not exist "%~dp0tiny11builder.ps1" (
    echo.
    echo   [错误] 找不到 tiny11builder.ps1。
    echo   请确认本文件与 tiny11builder.ps1 放在同一个文件夹里。
    echo.
    pause
    exit /b 1
)

rem ---------- 2. 当前文件夹是否可写 ----------
rem  从光盘 / ISO 镜像里直接运行会因为只读而无法保存日志与成品，先拦下来并给出办法。
set "WRITETEST=%~dp0.tiny11_write_test.tmp"
echo t > "%WRITETEST%" 2>nul
if not exist "%WRITETEST%" (
    echo.
    echo   [错误] 当前文件夹无法写入。
    echo   如果是直接从光盘或 ISO 镜像里打开本工具，将无法保存日志文件和做好的 ISO。
    echo   请先把整个 tiny11builder 文件夹复制到硬盘（例如复制到 D:\tiny11builder）再运行。
    echo.
    pause
    exit /b 1
)
del "%WRITETEST%" >nul 2>&1

rem ---------- 3. 申请管理员权限 ----------
rem  已经是管理员就直接继续；不是则用系统弹窗请求提权（用户无需知道要右键运行）。
set "PSCHECK=$p=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()); if(-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){ try{ Start-Process -FilePath '%~f0' -Verb RunAs -ErrorAction Stop }catch{ exit 4 }; exit 3 }"
powershell -NoProfile -ExecutionPolicy Bypass -Command "%PSCHECK%"
if "%errorlevel%"=="4" (
    echo.
    echo   [错误] 未取得管理员权限（可能在上一个窗口里点了「否」）。
    echo   本工具需要管理员权限才能挂载映像、修改系统设置，因此无法继续。
    echo.
    pause
    exit /b 1
)
if "%errorlevel%"=="3" exit /b

rem ---------- 4. 运行脚本 ----------
rem  -ExecutionPolicy Bypass 只作用于本次启动，不会改动系统原有的执行策略；
rem  -STA 是为了让图形界面（如需）能正常显示。
echo 正在启动 tiny11builder，请稍候...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0tiny11builder.ps1" %*
set "RC=%errorlevel%"
echo.
if "%RC%"=="0" (
    echo 运行结束。
) else (
    echo 运行结束，但未能正常完成（退出码 %RC%）。
    echo 请把本窗口最后几行内容发给维护者；日志文件在本文件夹的 LOG 子目录里。
)
echo.
echo 按任意键关闭本窗口...
pause >nul
endlocal
