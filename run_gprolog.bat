@echo off
set MAXSZ=16384
gprolog.exe --query-goal change_directory('%1') --query-goal consult('%2') --query-goal %3 --query-goal ! --query-goal end_of_file
@cls