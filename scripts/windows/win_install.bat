@echo off

@rem This script will install miniconda and git with all dependencies for this project
@rem This enables a user to install this project without manually installing conda and git.

@rem workaround for broken Windows installs
set PATH=%PATH%;%SystemRoot%\system32

cd /D "%~dp0"

echo "%cd%"| findstr /C:" " >nul && call :PrintBigMessage "This script relies on Miniconda which can not be silently installed under a path with spaces. Please put it in a path without spaces and try again" && goto failed
call :PrintBigMessage "WARNING: This script relies on Miniconda which will fail to install if the path is too long."
set "SPCHARMESSAGE="WARNING: Special characters were detected in the installation path!" "         This can cause the installation to fail!""
echo "%CD%"| findstr /R /C:"[!#\$%&()\*+,;<=>?@\[\]\^`{|}~]" >nul && (
  call :PrintBigMessage %SPCHARMESSAGE%
)
set SPCHARMESSAGE=

pause
cls

md 

echo "      ___       ___           ___       ___       ___           ___      "
echo "     /\__\     /\  \         /\__\     /\__\     /\__\         /\  \     "
echo "    /:/  /    /::\  \       /:/  /    /:/  /    /::|  |       /::\  \    "
echo "   /:/  /    /:/\:\  \     /:/  /    /:/  /    /:|:|  |      /:/\ \  \   "
echo "  /:/  /    /:/  \:\  \   /:/  /    /:/  /    /:/|:|__|__   _\:\~\ \  \  "
echo " /:/__/    /:/__/ \:\__\ /:/__/    /:/__/    /:/ |::::\__\ /\ \:\ \ \__\ "
echo " \:\  \    \:\  \ /:/  / \:\  \    \:\  \    \/__/~~/:/  / \:\ \:\ \/__/ "
echo "  \:\  \    \:\  /:/  /   \:\  \    \:\  \         /:/  /   \:\ \:\__\   "
echo "   \:\  \    \:\/:/  /     \:\  \    \:\  \       /:/  /     \:\/:/  /   "
echo "    \:\__\    \::/  /       \:\__\    \:\__\     /:/  /       \::/  /    "
echo "     \/__/     \/__/         \/__/     \/__/     \/__/         \/__/     "
echo By ParisNeo

:retry
echo Please specify if you want to use a GPU or CPU.
echo *Note* that only NVidea GPUs (cuda) or AMD GPUs (rocm) are supported.
echo A) Enable cuda GPU
echo B) Enable ROCm compatible GPU (AMD and other GPUs) (NOT SUPPORTED UNDER WINDOWS)
echo C) Run CPU mode
set /p "gpuchoice=Input> "
set gpuchoice=%gpuchoice:~0,1%

@rem better isolation for virtual environment
SET "CONDA_SHLVL="
SET PYTHONNOUSERSITE=1
SET "PYTHONPATH="
SET "PYTHONHOME="
SET "TEMP=%cd%\installer_files\temp"
SET "TMP=%cd%\installer_files\temp"

set MINICONDA_DIR=%cd%\installer_files\miniconda3
set INSTALL_ENV_DIR=%cd%\installer_files\lollms_env
set MINICONDA_DOWNLOAD_URL=https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe
set REPO_URL=https://github.com/ParisNeo/lollms-webui.git

set "PACKAGES_TO_INSTALL=python=3.11 git"

if not exist "%MINICONDA_DIR%\Scripts\conda.exe" (
  @rem download miniconda
  echo Downloading Miniconda installer from %MINICONDA_DOWNLOAD_URL%
  call curl -LOk "%MINICONDA_DOWNLOAD_URL%"

  @rem install miniconda
  echo. && echo Installing Miniconda To "%MINICONDA_DIR%" && echo Please Wait... && echo.
  start "" /W /D "%cd%" "Miniconda3-latest-Windows-x86_64.exe" /InstallationType=JustMe /NoShortcuts=1 /AddToPath=0 /RegisterPython=0 /NoRegistry=1 /S /D=%MINICONDA_DIR% || ( echo. && echo Miniconda installer not found. && goto failed )
  del /q "Miniconda3-latest-Windows-x86_64.exe"
  if not exist "%MINICONDA_DIR%\Scripts\activate.bat" ( echo. && echo Miniconda install failed. && goto end )
)

@rem activate miniconda
call "%MINICONDA_DIR%\Scripts\activate.bat" || ( echo Miniconda hook not found. && goto end )


@rem create the installer env
if not exist "%INSTALL_ENV_DIR%" (
  echo Packages to install: %PACKAGES_TO_INSTALL%
  call conda create --no-shortcuts -y -k -p "%INSTALL_ENV_DIR%" %CHANNEL% %PACKAGES_TO_INSTALL% || ( echo. && echo Conda environment creation failed. && goto end )
)

@rem check if conda environment was actually created
if not exist "%INSTALL_ENV_DIR%\python.exe" ( echo. && echo Conda environment is empty. && goto end )

@rem activate installer env
call conda activate "%INSTALL_ENV_DIR%" || ( echo. && echo Conda environment activation failed. && goto end )

@rem clone the repository
if exist lollms-webui\ (
  cd lollms-webui
  git pull
) else (
  git clone https://github.com/ParisNeo/lollms-webui.git
  cd lollms-webui 
)
git submodule update --init
cd zoos/bindings_zoo
git checkout main
cd ../personalities_zoo
git checkout main
cd ../extensions_zoo
git checkout main
cd ../models_zoo
git checkout main

cd ../..

cd lollms_core
git checkout main

cd ../utilities/safe_store
git checkout main

cd ../..

@rem create launcher
if exist ..\win_run.bat (
    echo Win run found
) else (
  copy scripts\windows\win_run.bat ..\
)

if exist ..\win_update.bat (
    echo Win update found
) else (
  copy scripts\windows\win_update.bat ..\
)


if exist ..\win_conda_session.bat (
    echo win conda session script found
) else (
  copy scripts\windows\win_conda_session.bat ..\
)

if exist ..\win_update_models.bat (
    echo Win update models found
) else (
  copy scripts\windows\win_update_models.bat ..\
)

setlocal enabledelayedexpansion

endlocal

goto end

:PrintBigMessage
echo. && echo.
echo *******************************************************************
for %%M in (%*) do echo * %%~M
echo *******************************************************************
echo. && echo.
exit /b
goto end
:failed
echo Install failed
goto endend
:end
cd ..
echo Installation complete.
:endend
pause
