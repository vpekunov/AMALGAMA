@echo off
@echo Content-type: text/html>%2
@echo X-Powered-By: NNET_SIMPLIFY>>%2
@set newline=^& echo.
@echo %newline%>>%2
@nnets_simplify.exe %1 Y 4 1000>>%2
echo %errorlevel% >_.err
