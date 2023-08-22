const { app, BrowserWindow, ipcMain } = require('electron')

const url = require("url");
const path = require("path");

let mainWindow

function createWindow() {

  mainWindow = new BrowserWindow({
    minWidth: 950,
    minHeight: 650,
    //titleBarStyle: 'hiddenInset',
    backgroundColor: '#1B1C21',
    webPreferences: {
      // --- !! IMPORTANT !! ---
      // Disable 'contextIsolation' to allow 'nodeIntegration'
      // 'contextIsolation' defaults to "true" as from Electron v12
      contextIsolation: false,
      nodeIntegration: true,
      enableRemoteModule: false
    }
  })

  mainWindow.loadURL(`file://${__dirname}/dist/android-tools/index.html`)

  // Open the DevTools.
  mainWindow.webContents.openDevTools()

  mainWindow.on('closed', function () {
    mainWindow = null
  })
}

app.on('ready', createWindow)

app.on('window-all-closed', function () {
  if (process.platform !== 'darwin') app.quit()
})

app.on('activate', function () {
  if (mainWindow === null) createWindow()
})

ipcMain.on("logcat", (e, options) => {
  console.log("internet")
})