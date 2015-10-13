::http://support.microsoft.com/kb/2570538
::http://robrelyea.wordpress.com/2007/07/13/may-be-helpful-ngen-exe-executequeueditems/
@echo off
echo "Compiling .Net Assemblies"

if "%PROCESSOR_ARCHITECTURE%"=="AMD64" goto 64BIT

%windir%\microsoft.net\framework\v4.0.30319\ngen.exe executequeueditems >nul
%windir%\microsoft.net\framework\v4.0.30319\ngen.exe executequeueditems >nul

exit /b

:64BIT
%windir%\microsoft.net\framework\v4.0.30319\ngen.exe executequeueditems >nul
%windir%\microsoft.net\framework64\v4.0.30319\ngen.exe executequeueditems >nul
%windir%\microsoft.net\framework\v4.0.30319\ngen.exe executequeueditems >nul
%windir%\microsoft.net\framework64\v4.0.30319\ngen.exe executequeueditems >nul
