# Turni app - architettura modulare

Questa cartella contiene il runtime nuovo e leggero dell'app.

## Regole
- Nessun service worker o cache forzata nelle pagine operative.
- Nessun handler globale touchstart/touchend.
- Nessun MutationObserver permanente.
- Nessun location.reload automatico per applicare modifiche.
- Una funzione deve avere un solo modulo proprietario: evitare catene fix-vXYZ.
- Le pagine nuove usano app/runtime.js e app/base.css.
- Nuovi Turni usa app/new-turns.js come unica UI.
- Supabase resta l'unico backend persistente; localStorage contiene solo sessione, bozza locale e vincoli locali già previsti dall'app.

## Backup
Lo stato precedente al refactor è conservato nel branch backup-v142-pre-refactor-2026-08-19.
