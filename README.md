# TAKWatch

<img src="https://raw.githubusercontent.com/TDF-PL/TAKWatch-IQ/main/images/screenshot-2.jpeg" width="200" height="200">

## Description
TAKWatch is an ATAK plugin that communicates with Garmin devices running TAKWatch-IQ (https://github.com/TDF-PL/TAKWatch-IQ) application.

## Features
- Sending heart rate to ATAK
- Receiving waypoints from ATAK (persisted on the watch)
- Receiving markers from ATAK (not persisted on the watch)
- Triggering Emergency alert from watch (when SELECT button pressed 5 times rapidly)
- Creating vectors to markers
- Sending routes from ATAK to watch
- Sending chat messages
- Triggering ATAK wipe from watch (when BACK button pressed 5 times rapidly)

## Equipment supported
- epix™ (Gen 2) / quatix® 7 Sapphire
- epix™ Pro (Gen 2) 42mm
- epix™ Pro (Gen 2) 47mm
- epix™ Pro (Gen 2) 51mm
- Forerunner® 945 LTE
- Forerunner® 945
- Forerunner® 955 / Solar
- Forerunner® 965
- fēnix® 5 Plus
- fēnix® 5S Plus
- fēnix® 5X / tactix® Charlie
- fēnix® 5X Plus
- fēnix® 6 Pro / 6 Sapphire / 6 Pro Solar / 6 Pro Dual Power / quatix® 6
- fēnix® 6S Pro / 6S Sapphire / 6S Pro Solar / 6S Pro Dual Power
- fēnix® 6X Pro / 6X Sapphire / 6X Pro Solar / tactix® Delta Sapphire / Delta Solar / Delta Solar - Ballistics Edition / quatix® 6X / 6X Solar / 6X Dual Power
- fēnix® 7 / quatix® 7
- fēnix® 7 Pro
- fēnix® 7S Pro
- fēnix® 7S
- fēnix® 7X / tactix® 7 / quatix® 7X Solar / Enduro™ 2
- fēnix® 7X Pro

## Screenshots

<img src="https://raw.githubusercontent.com/TDF-PL/TAKWatch-IQ/main/images/screenshot-1.png" width="200" height="200">
<img src="https://raw.githubusercontent.com/TDF-PL/TAKWatch-IQ/main/images/screenshot-3.jpeg" width="200" height="200">

## Build instructions
For detailed instructions please read this: https://developer.garmin.com/connect-iq/reference-guides/visual-studio-code-extension/

java.exe -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true -jar <PATH_TO_SDK>\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-6.3.0-2023-08-29-fc81ed416\bin\monkeybrains.jar -o <PATH_TO_PROJECT>\TAKWatch-IQ\bin\TAKWatchIQ.prg -f <PATH_TO_PROJECT>\TAKWatch-IQ\monkey.jungle -y <PATH_TO_DEV_KEY>\connectiq-android-sdk\developer_key -d <WATCH_MODEL> -w 

You can also use one of the builds provided in the releases section. 

## Releases
https://apps.garmin.com/en-US/apps/9f3aa645-f24f-49f2-af0f-328b98a7be70#0

