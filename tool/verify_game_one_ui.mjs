import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {spawn} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const assets = path.join(root, 'assets/original_games');
const out = path.join(root, 'build/game-one-ui-check');
fs.mkdirSync(out, {recursive:true});
const delay = ms => new Promise(resolve=>setTimeout(resolve, ms));
const bootstrap = `<script>
window.ItechsBridge={postMessage(raw){const m=JSON.parse(raw);if(m.type==='ready')setTimeout(()=>window.itechsReceive({channel:'itechs-original-games',type:'configure',game:'GAME_ONE',number:2,user:{id:'ui-check',username:'ui-check',role:'STUDENT'},coins:3,musicVolume:0,sfxVolume:0}),0);if(m.type==='start')setTimeout(()=>window.itechsReceive({channel:'itechs-original-games',type:'response',id:m.id,result:{sessionId:'ui-check',attemptNumber:2,retryMultiplier:1,isFirstGamePlay:false}}),0)}};
</script>`;
const server = http.createServer((req,res)=>{
  const relative = decodeURIComponent(new URL(req.url,'http://localhost').pathname).replace(/^\//,'') || 'index.html';
  const target = path.resolve(assets, relative);
  if (!target.startsWith(assets+path.sep)) {res.writeHead(403).end();return;}
  try {
    let body=fs.readFileSync(target);
    if(relative==='index.html') body=Buffer.from(body.toString().replace('<head>','<head>'+bootstrap));
    if(/^game-.*\.js$/.test(relative)) body=Buffer.from(body.toString().replace('return P.current=Ne,','return window.__uiTestGame=Ne,P.current=Ne,'));
    const type={'.js':'text/javascript','.css':'text/css','.html':'text/html','.png':'image/png','.json':'application/json','.svg':'image/svg+xml'}[path.extname(target)]||'application/octet-stream';
    res.writeHead(200,{'Content-Type':type});res.end(body);
  }catch {res.writeHead(404).end();}
});
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
const profile=fs.mkdtempSync(path.join(out,'browser-profile-'));
const browser=spawn('C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',[
  '--headless=new','--no-first-run','--no-default-browser-check','--remote-debugging-port=0',
  '--disable-background-networking',`--user-data-dir=${profile}`,'about:blank',
],{windowsHide:true,stdio:'ignore'});
let ws;
try {
  const portFile=path.join(profile,'DevToolsActivePort');
  for(let i=0;i<100&&!fs.existsSync(portFile);i++)await delay(200);
  const port=fs.readFileSync(portFile,'utf8').split('\n')[0];
  const tabs=await(await fetch(`http://127.0.0.1:${port}/json/list`)).json();
  ws=new WebSocket(tabs.find(t=>t.type==='page').webSocketDebuggerUrl);
  await new Promise(resolve=>ws.addEventListener('open',resolve,{once:true}));
  let serial=0;const pending=new Map();
  ws.addEventListener('message',e=>{const m=JSON.parse(e.data);if(m.id){const cb=pending.get(m.id);pending.delete(m.id);m.error?cb.reject(m.error):cb.resolve(m.result);}});
  const call=(method,params={})=>new Promise((resolve,reject)=>{const id=++serial;pending.set(id,{resolve,reject});ws.send(JSON.stringify({id,method,params}));});
  const evaluate=async expression=>{const r=await call('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});if(r.exceptionDetails)throw new Error(JSON.stringify(r.exceptionDetails));return r.result.value;};
  const screenshot=async name=>{
    const disk=fs.statfsSync(out);
    if(disk.bavail*disk.bsize<80*1024*1024){console.log('Screenshot skipped: low disk space');return;}
    fs.writeFileSync(path.join(out,name),Buffer.from((await call('Page.captureScreenshot')).data,'base64'));
  };
  await call('Emulation.setDeviceMetricsOverride',{width:852,height:393,deviceScaleFactor:1,mobile:false});
  await call('Page.navigate',{url:`http://127.0.0.1:${server.address().port}/`});
  let ready=false;
  for(let i=0;i<100;i++) {ready=await evaluate('!!window.__uiTestGame?.scene?.keys?.LevelScene?.player');if(ready)break;await delay(300);}
  if(!ready)throw new Error('Game did not boot');
  console.log('Booted original game.');
  const stage=await evaluate(`(()=>{const canvas=document.querySelector('canvas').getBoundingClientRect();return {canvas:{x:canvas.x,y:canvas.y,width:canvas.width,height:canvas.height},controls:[...document.querySelectorAll('.game-one-mobile-control-button')].map(e=>({text:e.textContent,display:getComputedStyle(e).display,height:e.getBoundingClientRect().height})),viewport:{width:innerWidth,height:innerHeight}}})()`);
  console.log(JSON.stringify(stage));
  console.log(await evaluate(`JSON.stringify((()=>{let e=document.querySelector('canvas');const list=[];while(e){const r=e.getBoundingClientRect(),s=getComputedStyle(e);list.push({tag:e.tagName,cls:e.className,w:r.width,h:r.height,y:r.y,padding:s.padding,background:s.backgroundColor,display:s.display});e=e.parentElement;}return list;})())`));
  if(Math.abs(stage.canvas.width/stage.canvas.height-16/9)>.03)throw new Error('Stage aspect ratio changed');
  const expectedHeight=Math.min(stage.viewport.height-40,stage.viewport.width*9/16);
  if(stage.canvas.height<expectedHeight-3||Math.abs(stage.canvas.y)>2)throw new Error('Gameplay is smaller than the available stage');
  if(stage.controls.length!==5||stage.controls.some(c=>c.height<35))throw new Error('Touch controls are missing or too small');
  await screenshot('gameplay.png');
  await evaluate(`(()=>{const game=window.__uiTestGame,level=game.scene.keys.LevelScene;level.physics.world.pause();level.player.freeze(true);game.scene.pause('HudScene');const question=level.levelData.questions[0];level.scene.launch('QuestionScene',{question,questionId:question.id,hintCoinCost:1,availableCoins:3,revealedHintCount:0});})()`);
  await delay(500);
  const prompt=await evaluate(`(()=>{const s=window.__uiTestGame.scene.keys.QuestionScene;return s.children.list.filter(o=>o.type==='Text').map(o=>o.text)})()`);
  if(!prompt.some(t=>t.includes('What am I?')))throw new Error('Riddle text is not on the canvas');
  await screenshot('riddle.png');
  await evaluate(`(()=>{const s=window.__uiTestGame.scene.keys.QuestionScene,label=s.children.list.find(o=>o.text==='Hint');const button=s.children.list.find(o=>o.type==='Rectangle'&&o.input&&Math.abs(o.x-label.x)<35&&Math.abs(o.y-label.y)<10);button.emit('pointerup');})()`);
  const hint=await evaluate(`(()=>{const s=window.__uiTestGame.scene.keys.QuestionScene;return {text:s.feedbackText.text,popup:s.children.list.some(o=>o.type==='Container'&&o.visible&&o.list.some(t=>t.text?.includes('Hint')))}})()`);
  if(!hint.text.startsWith('Hint: ')||hint.popup)throw new Error('Hint must display inline without a popup');
  await screenshot('inline-hint.png');
  const wallet=await evaluate('({coins:window.__uiTestGame.scene.keys.QuestionScene.availableCoins,hints:window.__uiTestGame.scene.keys.QuestionScene.hintIndex})');
  if(wallet.coins!==2||wallet.hints!==1)throw new Error('Hint purchase changed the wrong amount');
  console.log('PASS: full-height 16:9 gameplay, five controls, visible riddle, inline hint without a popup, and one-coin purchase.');
  console.log('Screenshots: build/game-one-ui-check');
  await call('Browser.close');
} finally {
  ws?.close();browser.kill();server.close();
}
