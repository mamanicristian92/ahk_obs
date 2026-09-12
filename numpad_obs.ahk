#Requires AutoHotkey v2.0

#Include Lib\AutoHotInterception.ahk
#Include Lib\OBSWebSocket.ahk


; =========================
; CONFIGURACIÓN
; =========================

configFile := A_ScriptDir "\config.ini"
passwordFile := A_ScriptDir "\password.ini"

obsHost := IniRead(configFile, "OBS", "Host", "127.0.0.1")
obsPort := IniRead(configFile, "OBS", "Port", "4455")
obsPassword := IniRead(passwordFile, "OBS", "Password", "")

global obsConnected := false

scene1 := IniRead(configFile, "Scenes", "P1", "")
scene2 := IniRead(configFile, "Scenes", "P2", "")
scene3 := IniRead(configFile, "Scenes", "P3", "")
scene4 := IniRead(configFile, "Scenes", "P4", "")
scene5 := IniRead(configFile, "Scenes", "P5", "")
scene6 := IniRead(configFile, "Scenes", "P6", "")
scene7 := IniRead(configFile, "Scenes", "P7", "")
scene8 := IniRead(configFile, "Scenes", "P8", "")
scene9 := IniRead(configFile, "Scenes", "P9", "")


; =========================
; CONFIGURACIÓN DEL FADE
; =========================

global audioSource := IniRead(configFile, "Audio", "Source", "Audio del escritorio")

global audioMute := IniRead(configFile, "Audio", "Mute", -100)
global audioCanto := IniRead(configFile, "Audio", "Canto", -12)
global audioMax := IniRead(configFile, "Audio", "Max", 0)

global fadeDuration := IniRead(configFile, "Audio", "FadeDuration", 2000)
global fadeSteps := IniRead(configFile, "Audio", "FadeSteps", 40)
global fadeInterval := fadeDuration / fadeSteps

global currentVolume := audioMute

global fadeRunning := false
global fadeCurrentStep := 0
global fadeStartVolume := 0
global fadeTargetVolume := 0


; =========================
; AUTOHOTINTERCEPTION
; =========================

keyboardVid := Integer(IniRead(configFile, "Keyboard", "VID", "0"))
keyboardPid := Integer(IniRead(configFile, "Keyboard", "PID", "0"))

global AHI := AutoHotInterception()

keyboardId := AHI.GetKeyboardId(keyboardVid, keyboardPid)

cm := AHI.CreateContextManager(keyboardId)


; =========================
; VENTANA
; =========================

mainGui := Gui("-AlwaysOnTop", "Control de Stream")
mainGui.SetFont("s10")

mainGui.AddText("w250 Center", "CONTROL DE STREAM")

statusText := mainGui.AddText(
    "w250 Center",
    "● Conectando con OBS..."
)

mainGui.AddText("w250", "")
mainGui.AddText("w250", "NUMPAD → ESCENAS")

sceneTexts := [
    mainGui.AddText("w250", "1  " scene1),
    mainGui.AddText("w250", "2  " scene2),
    mainGui.AddText("w250", "3  " scene3),
    mainGui.AddText("w250", "4  " scene4),
    mainGui.AddText("w250", "5  " scene5),
    mainGui.AddText("w250", "6  " scene6),
]


mainGui.AddText("w250", "")
mainGui.AddText(
    "w250 Center",
    "Numpad activo"
)

mainGui.OnEvent("Close", (*) => ExitApp())

mainGui.Show("AutoSize")


; =========================
; OBS WEBSOCKET
; =========================

class MyOBSController extends OBSWebSocket {

    AfterIdentified() {
        global obsConnected
        obsConnected := true
        UpdateStatus("● OBS conectado",true)
    }
    onClose(status, reason) {
        super.onClose(status, reason)
        UpdateStatus("● OBS desconectado",false)
        MsgBox(
            "OBS se cerró o se perdió la conexión.",
            "Conexión perdida",
            "Iconx"
        )

        ExitApp()
    }
}


; =========================
; FUNCIÓN DE ESTADO
; =========================

UpdateStatus(text,connected) {
    global statusText
    statusText.Text := text
    if (!connected)
        statusText.Opt("cRed")
    else
        statusText.Opt("cGreen")
}


; =========================
; UPDATE SCENE INDICATOR
; =========================

UpdateSceneIndicator(number) {
    global sceneTexts
    global scene1, scene2, scene3, scene4, scene5
    global scene6, scene7, scene8, scene9

    scenes := [
        scene1, scene2, scene3, scene4, scene5,
        scene6, scene7, scene8, scene9
    ]

    for index, scene in scenes {
        if (scene != "") {
            if (index = number) {
                sceneTexts[index].Text := index "  " scene " <<<"
                sceneTexts[index].Opt("cGreen")
            }
            else {
                sceneTexts[index].Text := index "  " scene
                sceneTexts[index].Opt("cBlack")
            }
        }
    }
}


; =========================
; SET ESCENES
; =========================

SetScene(scene, number) {
    if (scene = "")
        return

    obsc.SetCurrentProgramScene(scene)

    UpdateSceneIndicator(number)
}


; =========================
; PROGRAMA PRINCIPAL
; =========================

try {
    global obsc := MyOBSController(
        "ws://" obsHost ":" obsPort "/",
        obsPassword
    )
} catch Error as err {
    MsgBox(
        "No se pudo conectar con OBS.`n`n"
        . "Verificá que OBS esté abierto y que obs-websocket esté habilitado.",
        "Error de conexión",
        "Iconx"
    )
    ExitApp()
}


; =========================
; PASO DEL FADE
; =========================

FadeStep() {

    global obsc
    global audioSource
    global fadeRunning
    global fadeCurrentStep
    global fadeSteps
    global fadeStartVolume
    global fadeTargetVolume
    global currentVolume

    if (!fadeRunning) {
        SetTimer(FadeStep, 0)
        return
    }

    ; Progreso: 0.0 → 1.0
    progress := fadeCurrentStep / fadeSteps

    ; Curva en S
    curve := 3 * progress ** 2 - 2 * progress ** 3

    ; Interpolación entre volumen inicial y destino
    volumeDb :=
        fadeStartVolume
        + ((fadeTargetVolume - fadeStartVolume) * curve)

    obsc.SetInputVolume(
        audioSource,
        -200,
        volumeDb
    )

    ; El programa conoce el último volumen que estableció
    currentVolume := volumeDb

    fadeCurrentStep++

    ; Fade terminado
    if (fadeCurrentStep > fadeSteps) {

        currentVolume := fadeTargetVolume
        fadeRunning := false

        SetTimer(FadeStep, 0)
    }
}


; =========================
; SET FADE
; =========================

SetFade(targetVolume) {

    global currentVolume
    global fadeRunning
    global fadeCurrentStep
    global fadeStartVolume
    global fadeTargetVolume
    global fadeInterval

    ; Detener cualquier fade anterior
    SetTimer(FadeStep, 0)

    ; Guardar estado inicial y destino
    fadeStartVolume := currentVolume
    fadeTargetVolume := targetVolume

    fadeCurrentStep := 0
    fadeRunning := true

    ; Ejecutar inmediatamente el primer paso
    FadeStep()

    ; Continuar con el timer
    SetTimer(FadeStep, fadeInterval)
}

; =========================
; NUMPAD → OBS
; =========================

#HotIf cm.IsActive

Numpad1::SetScene(scene1, 1)
Numpad2::SetScene(scene2, 2)
Numpad3::SetScene(scene3, 3)
Numpad4::SetScene(scene4, 4)
Numpad5::SetScene(scene5, 5)
Numpad6::SetScene(scene6, 6)
Numpad7::SetFade(audioMute)
Numpad8::SetFade(audioCanto)
Numpad9::SetFade(audioMax)

#HotIf