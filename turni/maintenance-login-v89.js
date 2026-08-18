(()=>{
'use strict';
const style=document.createElement('style');
style.textContent=`
.maint-login{min-height:100vh;background:linear-gradient(155deg,#003d7c 0%,#0067b1 48%,#00539a 100%);padding:env(safe-area-inset-top) 16px env(safe-area-inset-bottom);box-sizing:border-box;display:flex;align-items:center;justify-content:center;position:relative;overflow:hidden}
.maint-login:before,.maint-login:after{content:'';position:absolute;border-radius:999px;background:rgba(255,209,0,.13)}
.maint-login:before{width:300px;height:300px;right:-130px;top:-80px}.maint-login:after{width:230px;height:230px;left:-110px;bottom:-80px}
.maint-shell{width:min(470px,100%);position:relative;z-index:1}
.maint-brand{display:flex;align-items:center;gap:12px;color:#fff;margin-bottom:14px;padding:0 4px}.maint-brand-mark{width:52px;height:52px;border-radius:16px;background:#ffd100;color:#003d7c;display:grid;place-items:center;font-size:28px;font-weight:1000;box-shadow:0 8px 24px rgba(0,0,0,.2)}.maint-brand strong{display:block;font-size:18px}.maint-brand small{display:block;opacity:.85;margin-top:2px}
.maint-card{background:#fff;border-radius:25px;padding:22px;box-shadow:0 24px 60px rgba(0,30,70,.3);border-bottom:6px solid #ffd100}
.maint-badge{display:inline-flex;align-items:center;gap:7px;background:#fff1a8;color:#6b5500;border:1px solid #ebce3d;border-radius:999px;padding:7px 11px;font-size:11px;font-weight:950;text-transform:uppercase;letter-spacing:.04em}.maint-dot{width:8px;height:8px;border-radius:50%;background:#d59f00;animation:maintPulse 1.4s infinite}@keyframes maintPulse{50%{opacity:.3}}
.maint-card h1{margin:14px 0 7px;color:#003d7c;font-size:30px;line-height:1.02}.maint-card .lead{margin:0;color:#49677c;line-height:1.45;font-size:14px}.maint-warning{margin:16px 0;padding:13px 14px;border-radius:15px;background:#eef6fc;border-left:5px solid #0067b1;color:#244d69;font-size:13px;line-height:1.4}.maint-warning b{color:#003d7c}
.maint-divider{display:flex;align-items:center;gap:9px;margin:18px 0;color:#7b8c98;font-size:11px;font-weight:900;text-transform:uppercase}.maint-divider:before,.maint-divider:after{content:'';height:1px;background:#dbe5ec;flex:1}
.maint-card .field{margin:11px 0}.maint-card label{display:block;font-size:11px;font-weight:950;color:#425e70;margin-bottom:5px}.maint-card input{width:100%;box-sizing:border-box;border:1px solid #c8d9e6;border-radius:13px;padding:13px 14px;font-size:16px;background:#fbfdff;color:#003d7c;outline:none}.maint-card input:focus{border-color:#0067b1;box-shadow:0 0 0 3px rgba(0,103,177,.11)}
.maint-enter{width:100%;border:0;border-radius:14px;background:#0067b1;color:#fff;padding:14px;font-weight:950;font-size:15px;margin-top:5px;box-shadow:0 6px 16px rgba(0,103,177,.22)}.maint-enter:active{transform:scale(.99)}.maint-note{text-align:center;color:#78909e;font-size:10px;margin:11px 0 0}.maint-card .error{margin-top:11px}
@media(max-width:420px){.maint-card{padding:19px}.maint-card h1{font-size:27px}.maint-login{align-items:flex-start;padding-top:max(28px,env(safe-area-inset-top))}}
`;
document.head.appendChild(style);
function maintenanceLogin(err=''){
 app.innerHTML=`<main class="maint-login"><div class="maint-shell"><div class="maint-brand"><div class="maint-brand-mark">E</div><div><strong>Eurospin Torre Maura</strong><small>Portale turnazioni personale</small></div></div><section class="maint-card"><div class="maint-badge"><span class="maint-dot"></span> Manutenzione in corso</div><h1>App temporaneamente in manutenzione</h1><p class="lead">Stiamo aggiornando e controllando il portale turni per renderlo più stabile e preciso.</p><div class="maint-warning"><b>Per il momento ti chiediamo di non entrare nell'app</b> se non è necessario, perché alcune sezioni potrebbero essere ancora in aggiornamento.</div><div class="maint-divider">Accesso comunque disponibile</div><form id="loginForm"><div class="field"><label>Nome</label><input id="name" autocomplete="username" autocapitalize="none" required></div><div class="field"><label>Password</label><input id="pass" type="password" inputmode="numeric" autocomplete="current-password" required></div><button class="maint-enter" type="submit">Entra comunque</button>${err?`<div class="error">${esc(err)}</div>`:''}</form><p class="maint-note">Accesso riservato al personale autorizzato.</p></section></div></main>`;
 const form=document.getElementById('loginForm');
 if(form)form.onsubmit=e=>{e.preventDefault();const raw=document.getElementById('name').value.trim().toLowerCase(),key=Object.keys(USERS).find(k=>k.toLowerCase()===raw),pass=document.getElementById('pass').value;if(!key||USERS[key].password!==pass)return maintenanceLogin('Nome o password non corretti.');state.user={key,...USERS[key]};setSession(state.user);boot()};
}
try{loginView=maintenanceLogin}catch{}
if(!getSession())maintenanceLogin();
})();