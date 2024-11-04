<p align="center">
  <img width="300" alt="Android tools logo" src= "./Documentation/light-banner.png#gh-light-mode-only"/>
  <img width="300" alt="Android tools logo" src= "./Documentation/dark-banner.png#gh-dark-mode-only"/>
</p>

---
<p align="center">
   <img alt="API" src="https://github.com/ThomasBernard03/AndroidTools/actions/workflows/main.yml/badge.svg?branch=main"/>
  <img alt="API" src="https://img.shields.io/badge/language-swift-orange"/>
  <img alt="API" src="https://img.shields.io/badge/UI%20framework-SwiftUI-orange"/> 
  <img alt="API" src="https://img.shields.io/badge/plateform-Macos-blue"/> 
</p>


Android tools makes the communication between Macos and Android devices easier. You can view devices informations, install applications and browse files...

## ⚡️ Installation

You can install application from Github releases, using .dmg file. In app update is available to keep your application up to date.
If your application displays strange command results, don't hesitate to change the path to ADB in the application settings. To find out which path to put in the parameters, type the command `which adb`. I'm currently working on the application to improve error handling.

## Features

### 💾 Install Applications 

You can install an application from any .apk file on your Mac. You can drag and drop it into the application, or load it from the finder.

https://github.com/ThomasBernard03/AndroidTools/assets/67638928/ff896cb9-346e-4c6a-93a1-3faa6c21141d

### 📁 File explorer

The File Explorer in AndroidTools allows for easy and intuitive file management on your Android devices directly from your Mac. Here are the key features:

- Adding Files: You can add files to your Android device either by using drag-and-drop or by selecting them through Finder.
- Deleting Files and Folders: Easily delete files or folders from your Android device with a simple action in the explorer interface.
- Downloading Files: Download files from your Android device to your Mac to back up data or for local use.


https://github.com/ThomasBernard03/AndroidTools/assets/67638928/73b733b6-b16f-4701-8f4f-6e36daf0ddd4


### 🐱 Logcat

You can now view logcat logs into Android Tools, you can filter by package name, refresh and clear all logcat.

https://github.com/ThomasBernard03/AndroidTools/assets/67638928/eb3b4248-d17e-4af3-a73d-57d521303dbc


### 🚀 Road map

- General
  1. Better error handling
  
- Device information :
  1. New design
  2. Screenshot
  3. Record video
  
- Logcat
  1. Clean architecture

- Use emulators
- Screen miroring (like Vysor)
- Database viewer


# Build application

```shell
./gradlew packageDmg
./gradlew packageExe
```