@echo off
setlocal
if "%WEMULDROID_SIGNTOOL%"=="" exit /b 2
if "%WEMULDROID_SIGN_PFX%"=="" exit /b 2
if "%WEMULDROID_SIGN_PWD%"=="" exit /b 2
if "%~1"=="" exit /b 2
"%WEMULDROID_SIGNTOOL%" sign /f "%WEMULDROID_SIGN_PFX%" /p "%WEMULDROID_SIGN_PWD%" /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 "%~1"
exit /b %ERRORLEVEL%
