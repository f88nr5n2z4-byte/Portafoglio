self.addEventListener('install',event=>{self.skipWaiting()});
self.addEventListener('activate',event=>{
 event.waitUntil((async()=>{
  try{const keys=await caches.keys();await Promise.all(keys.map(k=>caches.delete(k)))}catch{}
  await self.clients.claim();
 })());
});
self.addEventListener('push',event=>{
 let data={title:'Eurospin Torre Maura',body:'Nuovo aggiornamento',url:'./'};
 if(event.data){try{data={...data,...event.data.json()}}catch{}}
 event.waitUntil(self.registration.showNotification(data.title,{body:data.body,icon:'icon.svg',badge:'icon.svg',data:{url:data.url}}));
});
self.addEventListener('notificationclick',event=>{
 event.notification.close();
 const url=event.notification.data&&event.notification.data.url?event.notification.data.url:'./';
 event.waitUntil(clients.matchAll({type:'window',includeUncontrolled:true}).then(list=>{
  for(const c of list){if('focus'in c)return c.navigate(url).then(()=>c.focus())}
  return clients.openWindow(url);
 }));
});