# PC GAME EMPIRE

Versione: Beta v0.1.0 Native (Windows x86_64)
Engine: Godot 4.7.2

## Avvio
Estrai `PC_GAME_EMPIRE_BETA_v0.1.0_WINDOWS.zip` e avvia `PC-GAME-EMPIRE.exe`.

## Controlli
- WASD / Frecce: movimento
- E: interazione
- TAB / I: inventario
- J: lavori
- U: miglioramenti negozio
- Mouse: UI e drag & drop componenti
- ESC: pausa / indietro
- Controller: stick sinistro movimento, A interazione/installazione, B indietro, D-Pad navigazione

## Gameplay
Cliente → richiesta → diagnostica/preventivo → shop → consegna componenti → inventario → assemblaggio/riparazione → benchmark → consegna → pagamento → reputazione → upgrade → giorno successivo.

Sono inclusi lavori di assemblaggio, riparazione e upgrade, compatibilità hardware, mercato usato con rischio guasti, economia, progressione, inventario, consegne, benchmark simulati, tutorial, salvataggio, audio sintetizzato, impostazioni video/audio, italiano/inglese e riepilogo giornata.

## Salvataggi
I dati vengono salvati nella cartella `user://` di Godot per PC GAME EMPIRE. Il salvataggio contiene economia, reputazione, XP/livello, inventario, lavoro attivo, build, diagnostica, ordini, upgrade, usato, giorno e posizione. Le impostazioni sono persistenti in un file separato.

## Risoluzioni
UI di riferimento 1920×1080 con scaling Godot. Preset selezionabili: 1280×720, 1366×768, 1600×900, 1920×1080, 2560×1440 e 3840×2160.

## Requisiti indicativi
- Windows 10/11 64-bit
- CPU x86_64 moderna
- 8 GB RAM
- GPU compatibile OpenGL 3.3 / Vulkan-capable consigliata
- Tastiera e mouse; controller opzionale

## Build e QA
La pipeline GitHub Actions esegue su Windows: import pulito, QA logica end-to-end, export Godot release, avvio dell'EXE esportato, creazione ZIP, estrazione dello ZIP e secondo avvio dell'EXE estratto. L'artefatto viene pubblicato solo se l'intero gate passa.
