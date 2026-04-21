@echo off

setlocal

set "dir=%~dp0"

set "archiveName=%~1"
set "outputDir=%dir%\pack"

set "os=%RUNNER_OS%"
if "%os%"=="" (
  set "os=Windows"
)

if "%archiveName%"=="" (
  if "%RUNNER_ARCH%"=="X86" (
    set "arch=x86"
  ) else if "%RUNNER_ARCH%"=="X64" (
    set "arch=x64"
  ) else if "%RUNNER_ARCH%"=="ARM64" (
    set "arch=arm64"
  ) else if "%RUNNER_ARCH%"=="ARM" (
    set "arch=arm"
  ) else (
    if "%PROCESSOR_ARCHITECTURE%"=="x86" (
      set "arch=x86"
    ) else if "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
      set "arch=arm64"
    ) else (
      set "arch=x64"
    )
  )

  set "archive=v8_%os%_%arch%.7z"
) else (
  set "archive=%archiveName%.7z"
)

if not exist "%outputDir%" (
  mkdir "%outputDir%"
)

xcopy /E /I /Q /Y "%dir%\v8\include" "%outputDir%"
copy /Y "%dir%\gn-args_%os%.txt" "%outputDir%"

rem Check if component (DLL) build
findstr /C:"is_component_build=true" "%dir%\args\%os%.gn" >nul 2>nul
if errorlevel 1 (
  rem Monolithic static build
  copy /Y "%dir%\v8\out\release\obj\v8_monolith.lib" "%outputDir%"
) else (
  rem Component (DLL) build — copy all DLLs, import libs, and data files
  copy /Y "%dir%\v8\out\release\v8.dll" "%outputDir%"
  copy /Y "%dir%\v8\out\release\v8.dll.lib" "%outputDir%"
  copy /Y "%dir%\v8\out\release\v8_libbase.dll" "%outputDir%"
  copy /Y "%dir%\v8\out\release\v8_libbase.dll.lib" "%outputDir%"
  copy /Y "%dir%\v8\out\release\v8_libplatform.dll" "%outputDir%"
  copy /Y "%dir%\v8\out\release\v8_libplatform.dll.lib" "%outputDir%"
  rem Third-party dependencies that V8 component build produces
  if exist "%dir%\v8\out\release\third_party_abseil-cpp_absl.dll" (
    copy /Y "%dir%\v8\out\release\third_party_abseil-cpp_absl.dll" "%outputDir%"
  )
  if exist "%dir%\v8\out\release\third_party_zlib.dll" (
    copy /Y "%dir%\v8\out\release\third_party_zlib.dll" "%outputDir%"
  )
  if exist "%dir%\v8\out\release\icuuc.dll" (
    copy /Y "%dir%\v8\out\release\icuuc.dll" "%outputDir%"
    copy /Y "%dir%\v8\out\release\icudtl.dat" "%outputDir%"
  )
  if exist "%dir%\v8\out\release\third_party_icu_icui18n.dll" (
    copy /Y "%dir%\v8\out\release\third_party_icu_icui18n.dll" "%outputDir%"
  )
)

where 7z >nul 2>nul
if errorlevel 1 (
  echo 7z not found
  exit /b %errorlevel%
)

pushd "%outputDir%"

call 7z a -r "%dir%\%archive%" .
if errorlevel 1 (
  echo Failed to archive.
  exit /b %errorlevel%
)

popd

dir "%dir%\%archive%"

endlocal
