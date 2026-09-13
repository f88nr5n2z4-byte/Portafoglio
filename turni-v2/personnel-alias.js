(()=>{
'use strict';
const INTERNAL='Prova', DISPLAY='Vanessa';
function replaceVisible(root=document.body){
  if(!root)return;
  const walker=document.createTreeWalker(root,NodeFilter.SHOW_TEXT,{acceptNode:n=>{
    const p=n.parentElement;
    if(!p||['SCRIPT','STYLE','NOSCRIPT'].includes(p.tagName))return NodeFilter.FILTER_REJECT;
    return n.nodeValue?.includes(INTERNAL)?NodeFilter.FILTER_ACCEPT:NodeFilter.FILTER_REJECT;
  }});
  const nodes=[];while(walker.nextNode())nodes.push(walker.currentNode);
  for(const n of nodes){
    const p=n.parentElement;
    if(p?.tagName==='OPTION'&&!p.hasAttribute('value'))p.setAttribute('value',INTERNAL);
    n.nodeValue=n.nodeValue.replace(/\bProva\b/g,DISPLAY);
  }
}
let timer=0;
const obs=new MutationObserver(()=>{clearTimeout(timer);timer=setTimeout(()=>replaceVisible(),20)});
obs.observe(document.documentElement,{childList:true,subtree:true,characterData:true});
document.addEventListener('DOMContentLoaded',()=>replaceVisible());
setTimeout(()=>replaceVisible(),100);
})();
