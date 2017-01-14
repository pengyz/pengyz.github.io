cls
@ECHO OFF
set base_dir=%~dp0
ECHO Now Deploying Pengyz's Personal Blog
ECHO.
ECHO Upload Static Resources To Qiniu Cloud
call %base_dir%/qshell/upload.bat
pushd %base_dir%
ECHO .

ECHO Deploy Hexo Blog To Github

hexo d
ECHO.
ECHO All Finished
