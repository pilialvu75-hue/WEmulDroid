# Video, audio, mouse/touch e Work

Questa pagina distingue il supporto dell'Android Emulator ufficiale da ciò che WEmulDroid è riuscito a verificare. **Non è stato ancora effettuato il collaudo sul PC Windows.**

## Video / schermo

L'emulatore simula un display con risoluzione e densità proprie. La finestra Windows può essere ridimensionata indipendentemente dalla risoluzione simulata.

Controlli previsti nella GUI v0.4:
- Profilo Leggero: 720 x 1280 a 320 dpi.
- Profilo Smartphone: 1080 x 2400 a 420 dpi.
- Profilo Tablet: 1600 x 2560 a 320 dpi.
- Applica schermo: invia i comandi Android wm size e wm density solo all'AVD selezionato.
- Ripristina: annulla le impostazioni risoluzione e densità modificate.
- Screenshot: acquisisce un PNG nell'AVD e lo trasferisce nella directory locale WEmulDroid/Screenshots.
- Misura risorse: include risoluzione e DPI nel report per permettere confronti ripetibili.

Per la prima prova preferire Leggero. Cambiare la risoluzione può aumentare il carico grafico. I cambi sono reversibili.

## Audio

L'Android Emulator normalmente usa l'audio Windows in uscita, e possiede pulsanti volume sul pannello laterale.
Per privacy il microfono host è inizialmente disabilitato. Se necessario, in Extended controls > Microphone attiva Enable Host Microphone Access e autorizza l'accesso in Windows.
Il nostro codice non abilita il microfono automaticamente. Driver audio problematici possono richiedere l'opzione -no-audio: da valutare in una fase successiva.

Da verificare sul PC: uscita casse/cuffie, volume, microfono, latenza e sincronizzazione audio-video.

## Input touch / mouse

| Android | Windows |
| --- | --- |
| Toccare | Clic sinistro |
| Doppio tocco | Doppio clic |
| Tenere premuto | Clic mantenuto |
| Swipe o trascinare | Clic, trascina e rilascia |
| Scroll | Rotella |
| Pinch/spread | Ctrl + mouse con gesti multitouch supportati dall'emulatore |
| Scrittura | Tastiera del PC |

Il comando Touch / Audio nella GUI apre una guida rapida. Per i giochi, rimappature WASD, gamepad e tocchi simultanei complessi devono essere sviluppati e verificati separatamente.

## Work come collaudatore

Possibilità futura, non ancora integrata: Work con accesso al desktop Windows e Computer Use autorizzato potrebbe vedere e usare la finestra Android come un'applicazione Windows. Per automatizzare scenari ripetibili, saranno utili ADB, UI Automator, acquisizione screenshot e report. Work cloud non ha automaticamente accesso al PC; Computer Use su Windows richiede il desktop attivo e i permessi necessari.

Criteri prima di dichiarare i test automatici funzionanti:
1. WEmulDroid si installa e Android effettua il boot su un PC fisico.
2. Il controllo seleziona soltanto il dispositivo virtuale richiesto.
3. Acquisizione screenshot, tocco e misurazioni superano prove ripetibili.
4. Work dispone dei permessi necessari per l'app Windows.
5. Si prova Impostazioni, poi una piccola app indipendente consentita.
6. I report distinguono script eseguito, UI verificata, app funzionante e confronto prestazionale.

Regola vincolante: non modificare Ai-orchestrator-riserva. L'eventuale test dell'APK principale sarà deciso in seguito, non costituisce prerequisito del progetto.

## Fonti
- https://developer.android.com/studio/run/emulator
- https://developer.android.com/studio/run/managing-avds
- https://developer.android.com/studio/run/emulator-extended-controls
- https://developer.android.com/studio/run/emulator-commandline
- https://learn.chatgpt.com/docs/computer-use
