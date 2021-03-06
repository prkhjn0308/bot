@echo off
setlocal
set CURDIR=%CD%

if not exist ..\.gitbot goto skip1
   cd ..\..
   set FMROOT=%CD%
   cd %CURDIR%
   goto endif1
:skip1
   echo ***error: This script must be run in the bot\Scripts directory
   exit /b
:endif1

set tagrepos=fds smv cfast fds-smv
set fdsrepos=exp fds fig out smv
set smvrepos=cfast fds smv fig
set cfastrepos=cfast exp smv fig
set allrepos= cfast cor exp fds fig out radcal smv cad
set wikiwebrepos= fds.wiki fds-smv
set repos=%fdsrepos%
set WIKIWEB=0
set tagrepo=0

call :getopts %*
if %stopscript% == 1 (
  exit /b
)

cd %FMROOT%\bot

set wc=%FMROOT%\bot\Scripts\bin\wc
set grep=%FMROOT%\bot\Scripts\bin\grep
set gawk=%FMROOT%\bot\Scripts\bin\gawk
set head=%FMROOT%\bot\Scripts\bin\head

git remote -v | %grep% origin | %head% -1 | %gawk%  "{print $2}" | %gawk% -F ":" "{print $1}">%CURDIR%\githeader.out
set /p GITHEADER=<%CURDIR%\githeader.out

if "%GITHEADER%" == "git@github.com" (
   set GITHEADER=%GITHEADER%:
   git remote -v | %grep% origin | %head% -1 | %gawk% -F ":" "{print $2}" | %gawk% -F\\/ "{print $1}" > %CURDIR%\gituser.out
   set /p GITUSER=<%CURDIR%\gituser.out
) else (
   set GITHEADER=https://github.com/
   git remote -v | %grep% origin | %head% -1 | %gawk% -F "." "{print $2}" | %gawk% -F\\/ "{print $2}" > %CURDIR%\gituser.out
   set /p GITUSER=<%CURDIR%\gituser.out
)

if exist %CURDIR%\gituser.out erase %CURDIR%\gituser.out
if exist %CURDIR%\githeader.out erase %CURDIR%\githeader.out

echo You are about to clone the repos: %repos%
if "%WIKIWEB%" == "1" (
   echo from git@github.com:firemodels into the directory: %FMROOT%
) else (
   echo from %GITHEADER%%GITUSER% into the directory: %FMROOT%
)
echo.
echo Press any key to continue, CTRL c to abort or type 
echo setup_repos -h for other options
pause >Nul

for %%x in ( %repos% ) do ( call :create_repo %%x )

cd %CURDIR%

goto eof

:create_repo
  set repo=%1
  set repo_out=%repo%
  
  echo -----------------------------------------------------------

  if "%repo%" == "fds.wiki" (
     set repo_out=wikis
     set WIKIWEB=1
  )
  if "%repo%" == "fds-smv" (
     set repo_out=webpages
     set WIKIWEB=1
  )

  if "%tagrepo%" == "1" (
     set repo_out=%repo_out%_tag
  )
  set repo_dir=%FMROOT%\%repo_out%
  
:: check if repo has been cloned locally
  if exist %repo_dir% (
     echo Skipping %repo%, the repo directory:
     echo %repo_dir%
     echo already exists
     exit /b
  )

  if "%WIKIWEB%" == "1" (
     cd %FMROOT%
     git clone %GITHEADER%firemodels/%repo%.git %repo_out%
     exit /b
  )
  
:: check if repo is at github
  call :at_github %repo%
  
  if %git_not_found% GTR 0 (
     echo ***Error: The repo %GITHEADER%%GITUSER%/%repo%.git was not found.
     exit /b
  )

  cd %FMROOT%
  if "%repo%" == "exp" (
     git clone --recursive %GITHEADER%%GITUSER%/%repo%.git %repo_out%
  )  else (
     git clone %GITHEADER%%GITUSER%/%repo%.git %repo_out%
  )
  if "%GITUSER%" == "firemodels"  (
     exit /b
  )
  echo setting up remote tracking
  cd %repo_dir%
  git remote add firemodels %GITHEADER%firemodels/%repo%.git
  if "%tagrepo%" == "1" goto skip_disable
     git remote set-url --push firemodels DISABLE
     git remote update
  :skip_disable
  exit /b

:at_github
  set repo=%1
  git ls-remote %GITHEADER%%GITUSER%/%repo%.git 1> %CURDIR%\gitstatus.out 2>&1
  type %CURDIR%\gitstatus.out | %grep% ERROR | %wc% -l > %CURDIR%\gitstatus2.out
  set /p git_not_found=<%CURDIR%\gitstatus2.out
  exit /b

:getopts
 set stopscript=0
 if (%1)==() exit /b
 set valid=0
 set arg=%1
 if /I "%1" EQU "-h" (
   call :usage
   set stopscript=1
   exit /b
 )
 if /I "%1" EQU "-a" (
   set valid=1
   set repos=%allrepos%
 )
 if /I "%1" EQU "-c" (
   set valid=1
   set repos=%cfastrepos%
 )
 if /I "%1" EQU "-f" (
   set valid=1
   set repos=%fdsrepos%
 )
 if /I "%1" EQU "-s" (
   set valid=1
   set repos=%smvrepos%
 )
 if /I "%1" EQU "-t" (
   set valid=1
   set repos=%tagrepos%
   set tagrepo=1
 )
 if /I "%1" EQU "-w" (
   set valid=1
   set repos=%wikiwebrepos%
 )
 shift
 if %valid% == 0 (
   echo.
   echo ***Error: the input argument %arg% is invalid
   echo.
   echo Usage:
   call :usage
   set stopscript=1
   exit /b
 )
if not (%1)==() goto getopts
exit /b

:usage
echo Setup repos ( default: %repos% ) 
echo used by cfast, fds and/or smokeview
echo.
echo Options:
echo -a - setup all repos: %allrepos%
echo -c - setup repos used by cfastbot: %cfastrepos%
echo -f - setup repos used by firebot: %fdsrepos%
echo -h - display this message%
echo -s - setup repos used by smokebot: %smvrepos%
echo -t - setup fds, smv and webpages repos that can be tagged
echo      (have push access to firemodels)
echo -w - setup wiki and webpage repos cloned from firemodels
exit /b

:eof
if exist %CURDIR%\gitstatus.out erase %CURDIR%\gitstatus.out
if exist %CURDIR%\gitstatus.out erase %CURDIR%\gitstatus2.out
