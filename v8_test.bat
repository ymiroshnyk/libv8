@echo off

setlocal

set "dir=%~dp0"

if not exist "%dir%\v8" (
  echo V8 not found
  exit /b 1
)

rem Detect pointer compression
set "ptrCompDefs="
findstr /C:"v8_enable_pointer_compression=true" "%dir%\args\Windows.gn" >nul 2>nul
if not errorlevel 1 (
  set "ptrCompDefs=/DV8_COMPRESS_POINTERS /DV8_31BIT_SMIS_ON_64BIT_ARCH"
)

rem Check if component (DLL) or monolithic build
findstr /C:"is_component_build=true" "%dir%\args\Windows.gn" >nul 2>nul
if errorlevel 1 (
  set "linkLibs=%dir%\v8\out\release\obj\v8_monolith.lib"
) else (
  set "linkLibs=%dir%\v8\out\release\v8.dll.lib %dir%\v8\out\release\v8_libplatform.dll.lib %dir%\v8\out\release\v8_libbase.dll.lib"
  rem Copy DLLs next to test exe
  copy /Y "%dir%\v8\out\release\v8.dll" . >nul 2>nul
  copy /Y "%dir%\v8\out\release\v8_libbase.dll" . >nul 2>nul
  copy /Y "%dir%\v8\out\release\v8_libplatform.dll" . >nul 2>nul
  copy /Y "%dir%\v8\out\release\third_party_abseil-cpp_absl.dll" . >nul 2>nul
  copy /Y "%dir%\v8\out\release\third_party_zlib.dll" . >nul 2>nul
)

call cl.exe /EHsc /std:c++20 /Zc:__cplusplus %ptrCompDefs% /I"%dir%\v8" /I"%dir%\v8\include" ^
  /Fe".\hello-world" "%dir%\v8\samples\hello-world.cc" ^
  /link %linkLibs% ^
  /DEFAULTLIB:advapi32.lib /DEFAULTLIB:dbghelp.lib /DEFAULTLIB:winmm.lib

if errorlevel 1 (
  echo Compilation failed
  exit /b %errorlevel%
)

call .\hello-world.exe

endlocal
