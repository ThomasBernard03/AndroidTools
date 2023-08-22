const { app, BrowserWindow, ipcMain } = require('electron')
const windowStateKeeper = require('electron-window-state') 

let mainWindow

function createWindow() {

  let winState = windowStateKeeper({
    defaultWidth : 1000,
    defaultHeight : 800
  })

  mainWindow = new BrowserWindow({
    width: winState.width,
    height: winState.height,
    x:winState.x,
    y:winState.y,
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