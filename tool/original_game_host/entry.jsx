import React, {useState} from 'react';
import {createRoot} from 'react-dom/client';
import {MemoryRouter} from 'react-router-dom';
import {Toaster} from 'react-hot-toast';
import StudentGameOverlay from '@original/components/student/StudentGameOverlay';
import '@original/index.css';
import '@original/student-mobile.css';
import '@original/student-game-mobile.css';
import '@fontsource/manrope/400.css';
import '@fontsource/manrope/500.css';
import '@fontsource/manrope/600.css';
import '@fontsource/manrope/700.css';
import '@fontsource/manrope/800.css';
import '@fontsource/oxanium/500.css';
import '@fontsource/oxanium/600.css';
import '@fontsource/oxanium/700.css';
import '@fontsource/oxanium/800.css';
import '@fontsource/pixelify-sans/500.css';
import '@fontsource/pixelify-sans/700.css';
import '@fontsource/space-grotesk/400.css';
import '@fontsource/space-grotesk/500.css';
import '@fontsource/space-grotesk/700.css';
import {send} from './bridge';
import './host.css';

const root = createRoot(document.getElementById('root'));
let configured = false;
const interval = window.setInterval.bind(window);
window.setInterval = (callback,delay,...args) => interval(() => {
  if (!window.__itechsSuspended) callback(...args);
},delay);
function App({config}) {
  const [number, setNumber] = useState(config.number);
  return <MemoryRouter><StudentGameOverlay key={`${config.game}-${number}`} gameType={config.game}
    levelNumber={number} onClose={() => send({type:'exit'})}
    onAdvanceToLevel={setNumber} forceFullReloadOnAdvance={false}
    onContinueToGame={() => send({type:'exit'})}/>
    <Toaster position="top-center"/>
  </MemoryRouter>;
}
window.addEventListener('itechs-configure', event => {
  if (configured) return;
  configured = true;
  const config = event.detail;
  window.__ITECHS_LOCAL_CONFIG__ = config;
  localStorage.setItem('user',JSON.stringify(config.user));
  localStorage.setItem('itechsSharedUserCoins', JSON.stringify({[config.user.id]: {balance:config.coins, completedSubLevels:{}}}));
  localStorage.setItem('studentMenuPreferences', JSON.stringify({musicVolume:config.musicVolume, sfxVolume:config.sfxVolume}));
  // Keep the original shared wallet synchronized with Flutter's persisted wallet.
  const setItem = Storage.prototype.setItem;
  Storage.prototype.setItem = function(name, value) {
    setItem.call(this,name,value);
    if (this === localStorage && name === 'itechsSharedUserCoins') {
      try {send({type:'coins', balance:JSON.parse(value)[config.user.id]?.balance || 0});} catch { /* Ignore unrelated storage. */ }
    }
  };
  root.render(<App config={config}/>);
});
window.addEventListener('error', event => send({type:'error', message:event.message}));
send({type:'ready'});
