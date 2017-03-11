@echo off
rem This file is the script to set path for ARM eabi tool chain.

set WORKDIR=%cd%
set APIF_DB_PATH=%WORKDIR%\chipmodel\
set APIF_PRG_PATH=%WORKDIR%\agen\
set OUTPUTS_PATH=%WORKDIR%\npi-data\
set PATH=%APIF_PRG_PATH%;%PATH%
cmd /s /k pushd "%WORKDIR%"
rem 
 
