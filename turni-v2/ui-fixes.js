(()=>{
'use strict';
const OFFICIAL_LOGO='https://www.eurospin.it/wp-content/uploads/Eurospin-piatto.jpg';
function fix(){
  document.querySelectorAll('img.brandlogo,img.herologo,.loginbrand img,.boot img').forEach(img=>{
    if(img.getAttribute('src')!==OFFICIAL_LOGO) img.setAttribute('src',OFFICIAL_LOGO);
  });
  document.querySelectorAll('.generator,.hero').forEach(root=>{
    const walker=document.createTreeWalker(root,NodeFilter.SHOW_TEXT);
    const nodes=[]; while(walker.nextNode()) nodes.push(walker.currentNode);
    for(const n of nodes){
      n.nodeValue=n.nodeValue
        .replace(/con 2 assenti/gi,'con 2 persone in ferie')
        .replace(/Con 2 persone assenti/g,'Con 2 persone in ferie')
        .replace(/con 2 persone assenti/gi,'con 2 persone in ferie');
    }
  });
}
const obs=new MutationObserver(()=>fix());
obs.observe(document.documentElement,{subtree:true,childList:true});
window.addEventListener('load',fix);
fix();
})();