@echo off
setlocal
cd /d "%~dp0"
if defined GODOT_EXE if exist "%GODOT_EXE%" goto launch
set "GODOT_EXE=%USERPROFILE%\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe"
if exist "%GODOT_EXE%" goto launch
for %%G in (godot.exe godot4.exe) do for %%P in (%%~$PATH:G) do set "GODOT_EXE=%%P"
if exist "%GODOT_EXE%" goto launch
echo Abra project.godot no Godot 4.7 e pressione F5.
echo Ou defina GODOT_EXE com o caminho para o Godot.
pause
exit /b 1
:launch
start "Astro - Um Pequeno Recomeco" "%GODOT_EXE%" --path "%~dp0."
