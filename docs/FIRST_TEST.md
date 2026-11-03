# Primo collaudo di AI-Orchestrator su WEmulDroid (Windows)

**Scopo:** avviare **l'APK Android stabile esistente** di [Ai-orchestrator-riserva](https://github.com/pilialvu75-hue/Ai-orchestrator-riserva), senza ricompilarlo e senza modificare il repository originale.

## Passi
1. Scarica lo ZIP di **WEmulDroid** da GitHub (**Code → Download ZIP**) ed estrailo su Windows.
2. Esegui **Installa-Android.cmd** e completa l'installazione dell'Android SDK ufficiale e dell'AVD \`Aivexus_API_35\` (richiede Java 17+, WHPX e connessione Internet).
3. Esegui **Prova-AI-Orchestrator.cmd**. Il programma:
   - avvia l'AVD se non è già attivo;
   - verifica se l'avvio Android è completo;
   - recupera da GitHub la **release stabile più recente** usando \`releases/latest\` (non beta, non draft);
   - chiede consenso prima di scaricare l'APK (circa 236 MB alla release \`v1.0.15+103691\` del 3 novembre 2026);
   - calcola SHA-256 locale del file e analizza le ABI delle librerie nel pacchetto;
   - esegue \`adb install -r\` **solo sull'AVD WEmulDroid** e prova ad aprire \`com.aiorchestrator/.MainActivity\`;
   - raccoglie memoria, CPU e ultime righe logcat in un report locale.
4. Controlla nella finestra dell'emulatore se compare l'interfaccia di AI-Orchestrator e se la chat si apre. **Non avviare per ora modelli locali grandi né benchmark pesanti.**
5. Apri il report in \`%LOCALAPPDATA%\AivexusAndroidLab\Reports\`. In caso di errore, conserva la descrizione precisa di \`adb install\` e i messaggi della finestra.
6. Conferma sul PC fisico: nome ASUS, RAM disponibile e stato della virtualizzazione (solo se desideri condividere quei dettagli).

## Cosa stiamo misurando
**Prima prova (P0):** installazione, avvio, compatibilità ABI, comparsa dell'interfaccia, RAM e CPU diagnostiche.
**Non ancora P0:** GPU %, energia reale, consumo batteria, stress test IA locale o prestazioni rappresentative di S24 FE.

## Compatibilità ARM su un emulatore x86_64
Il progetto principale **attualmente limita la build a \`arm64-v8a\`**. L'Android Emulator con immagini Google APIs può includere traduzione ARM/x86, ma è indispensabile verificare quanto dichiarato da \`ro.product.cpu.abilist\` e l'effettivo risultato di \`adb install\`.

Se l'installazione restituisce \`INSTALL_FAILED_NO_MATCHING_ABIS\` oppure l'app si avvia senza che le librerie native funzionino, il test è **fallito**. Registrare errore e valutare prima compatibilità bridge ARM, poi una build x86_64 dedicata *solo se le dipendenze native lo consentono*. Nessuna modifica alla versione Android pubblicata sui telefoni.

**Nota:** il comando di avvio \`am start\` eseguito senza errori non dimostra che l'interfaccia o l'inferenza funzionino. Serve osservazione nella finestra Android e successivi collaudi funzionali.

## Dove vengono salvati i dati
- Download APK: \`%LOCALAPPDATA%\AivexusAndroidLab\Downloads\`
- Report: \`%LOCALAPPDATA%\AivexusAndroidLab\Reports\`
- Android SDK: \`%LOCALAPPDATA%\AivexusAndroidLab\Sdk\`

Il test non usa i canali di aggiornamento di AI-Orchestrator installato su dispositivi reali, che restano indipendenti.

## Fonti tecniche
- [Google: Run ARM apps on the Android Emulator](https://android-developers.googleblog.com/2020/03/run-arm-apps-on-android-emulator.html)
- [Google: Android Emulator](https://developer.android.com/studio/run/emulator)
- [Google: SDK Command-line tools](https://developer.android.com/studio)
- [Android app release GitHub](https://github.com/pilialvu75-hue/Ai-orchestrator-riserva/releases/latest)
