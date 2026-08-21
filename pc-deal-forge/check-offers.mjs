import fs from 'node:fs/promises';
const base=[
{id:'cpu9800',cat:'CPU',name:'AMD Ryzen 7 9800X3D',shop:'BPM Power',url:'https://www.bpm-power.com/it/online/componenti-pc/processori/processore-amd-ryzen-7-b2243294',socket:'AM5',tdp:120},
{id:'mbb850',cat:'Motherboard',name:'ASRock B850 Riptide WiFi',shop:'BPM Power',url:'https://www.bpm-power.com/it/online/componenti-pc/schede-madri/scheda-madre-asrock-b850-b2254118',socket:'AM5',ram:'DDR5',form:'ATX'},
{id:'ram32',cat:'RAM',name:'Kingston Fury Beast RGB 32GB DDR5-6000 CL30',shop:'BPM Power',url:'https://www.bpm-power.com/it/online/componenti-pc/memorie/ram-dimm-ddr5-2x16gb-b2210889',ram:'DDR5',gb:32},
{id:'gpu5070',cat:'GPU',name:'PNY RTX 5070 EPIC-X RGB OC 12GB',shop:'BPM Power',url:'https://www.bpm-power.com/it/online/componenti-pc/schede-video/rtx5070-pny-5070-b2267077',watts:250,length:300},
{id:'ssd2tb',cat:'SSD',name:'Lexar NM790 2TB NVMe Gen4',shop:'BPM Power',url:'https://www.bpm-power.com/it/online/componenti-pc/ssd/2tb-lexar-nm790-m-b2087723',gb:2000},
{id:'psu850',cat:'PSU',name:'Seasonic Core GX 850W ATX 3.1 Gold',shop:'BPM Power',url:'https://www.bpm-power.com/it/online/componenti-pc/alimentatori-pc/alimentatore-850w-seasonic-serie-b2252025',watts:850,atx31:true},
{id:'caseh7',cat:'Case',name:'NZXT H7 Flow 2024',shop:'BPM Power',url:'https://www.bpm-power.com/it/online/componenti-pc/case-pc/nzxt-h7-flow-2024-b2207796',form:['ATX','mATX','ITX'],gpuMax:410},
{id:'coolnhd15',cat:'Cooler',name:'Noctua NH-D15',shop:'BPM Power',url:'https://www.bpm-power.com/it/online/componenti-pc/dissipatori/dissipatore-cpu-noctua-nh-b0367016',sockets:['AM5','AM4','LGA1700']}
];
function text(html){return html.replace(/<script[\s\S]*?<\/script>/gi,' ').replace(/<style[\s\S]*?<\/style>/gi,' ').replace(/<[^>]+>/g,' ').replace(/&nbsp;/gi,' ').replace(/&euro;|&#8364;/gi,'€').replace(/\s+/g,' ')}
function parsePrice(t){const m=t.match(/Prezzo\s*:\s*([0-9.]+(?:,[0-9]{1,2})?)\s*€/i)||t.match(/Prezzo\s*:\s*([0-9]+(?:\.[0-9]{1,2})?)\s*EUR/i);if(!m)return null;return Number(m[1].replace(/\./g,'').replace(',','.'))}
const now=new Date().toISOString();const offers=[];
for(const item of base){let status='unknown',price=null;try{const r=await fetch(item.url,{headers:{'user-agent':'Mozilla/5.0 PCDealForge/1.0'},redirect:'follow'});if(r.ok){const t=text(await r.text());price=parsePrice(t);if(/\bDisponibile\b/i.test(t)||/\bUltimi pezzi\b/i.test(t))status='active';if(/\bEsaurito\b/i.test(t)||/\bNon disponibile\b/i.test(t))status='expired';if(!price||price<=0)status='expired';}}catch{}offers.push({...item,price:price??0,status,verifiedAt:now});}
await fs.writeFile(new URL('./offers-live.json',import.meta.url),JSON.stringify({updatedAt:now,source:'BPM Power automatic checker',offers},null,2));
