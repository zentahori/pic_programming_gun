@echo off

rem -------------------------------------------------
rem icd3_gun uses MPLAB RealICE/ICD3 Command Line Interface.
rem This batch script is a pic firmware programmer that can load more than one hex file and protect the device from the duplicated writing.
rem -------------------------------------------------

setlocal ENABLEDELAYEDEXPANSION
set TARGET_CMD="icd3cmd.exe"
set USED_FIRMWARE_LIST=used_list.txt


rem ********* main routine *********
rem call :clear_arr

call :get_arg %1
if %errorlevel%==-1 exit /b 0

call :cmd_search
if %errorlevel%==-1 exit /b 0
call :read_used_list

for /F "usebackq delims=" %%j in (`dir /A-D /s /b %target_dir%\*.hex`) do (
    rem call :start_message
    rem pause

    call :is_used_firmware "%%j"

    if !errorlevel!==1 (
        rem --- continue ---
        echo continue..
    ) else (
        rem --- execute writing ---
        call :start_message
        pause

        echo writing "%%j"
        call :write_firmware "%%j"
        if !errorlevel!==-1 (
            echo Device error : !errorlevel!
            exit /b 0
        )

        call :append_used_firmware "%%j"
        call :end_message
    )
)

call :clear_arr
echo ---- All processes done ----
exit /b 0
rem ----- main end -----



rem ********* sub routines *********

rem ----- Get argument -----
:get_arg (
    if "%1"=="" (
        echo ERROR : Specify the path to the hex files.
        exit /b -1
    )
    set target_dir=%~f1
    exit /b 0
)

rem ----- Search for mplab_ipe cli -----
:cmd_search (
    pushd C:\
    for /F "usebackq delims=" %%i in (`dir /A-D /s /b %TARGET_CMD%`) do (
        set cli_cmd="%%i"
    )

    if "%cli_cmd%" EQU "" (
        echo %TARGET_CMD% is not found.
        pushd %0\..
        exit /b -1
    )

    echo %cli_cmd% was found.
    pushd %0\..
    exit /b 0
)

rem ----- read the used firmware list -----
:read_used_list (

    if Not exist %~dp0%USED_FIRMWARE_LIST% (
        echo %~dp0%USED_FIRMWARE_LIST% is not found.
        exit /b 0
    )

    rem -- extract list to memory --
    set /a cnt=0
    for /f "delims=" %%k in (%~dp0%USED_FIRMWARE_LIST%) do (
        set /a cnt+=1
        set list[!cnt!]=%%k
    )
    set /a max_cnt=%cnt%
    exit /b 0
)

rem ----- check if the hex file is used -----
:is_used_firmware (

    if "%list[1]%" EQU "" (
        echo No used file detected.
        exit /b 0
    )

    for /L %%l in (1,1,%max_cnt%) do (
        if "!%~nx1"=="!list[%%l]!" (
            echo %~nx1 was already used. Skip.
            exit /b 1
        )
    )
    exit /b 0
)

rem ------ Append the used firmware to the list ------
:append_used_firmware (
    if Not exist %~dp0%USED_FIRMWARE_LIST% (
        echo %~nx1> %~dp0%USED_FIRMWARE_LIST%
        exit /b 0
    )
    echo %~nx1>> %~dp0%USED_FIRMWARE_LIST%
    exit /b 0
)

rem ----- Program writing routine -----
:write_firmware (
    rem %cli_cmd% -P16LF1938 -E
    rem --- if power is supplied from the writer, use -V3.3.
    rem %cli_cmd% -P16LF1938 -F%1 -M -V3.3
    %cli_cmd% -P16LF1938 -F%1 -M
    if Not !errorlevel!==0 exit /b -1
    exit /b 0
)

rem ----- Start Message -----
:start_message (
    echo;
    echo;
    echo #######################################################
    echo set a pic device you are about to write the firmware in.
    echo #######################################################
    exit /b 0
)

rem ----- End Message -----
:end_message (
    echo;
    echo #######################################################
    echo Writing the firmware is done. Replace this pic device. 
    echo #######################################################
    exit /b 0
)

:check (
    for /L %%i in (1,1,%max_cnt%) do (
        echo %%i : !list[%%i]!
    )
    exit /b 0
)

:clear_arr (
    for /L %%l in (1,1,%max_cnt%) do (
        set list[%%l]=
    )
    exit /b 0
)
