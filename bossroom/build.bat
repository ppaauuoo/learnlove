@echo off
if exist bossgame.love del bossgame.love
if exist bossgame.zip del bossgame.zip

powershell -Command "$items = Get-ChildItem -Exclude love.exe -Name | Where-Object { $_ -ne 'dist' -and $_ -ne 'build.bat' -and $_ -ne 'bossgame.love' -and $_ -ne 'bossgame.zip' -and $_ -ne 'graphify-out' }; Compress-Archive -Path $items -DestinationPath bossgame.zip -Force"
rename bossgame.zip bossgame.love
echo Built bossgame.love

if not exist dist mkdir dist
if exist love.exe (
    copy /b love.exe+bossgame.love dist\bossgame.exe
    echo Built dist\bossgame.exe
)
