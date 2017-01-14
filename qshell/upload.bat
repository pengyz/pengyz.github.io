cls
@ECHO OFF
set base_path=%~dp0
%base_path%/qshell_windows_386.exe qupload 5 %base_path%/upload-confg.json
ECHO Upload Finished.
