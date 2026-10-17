let serial = 0;
const pending = new Map();
export function send(message) {
  const data = JSON.stringify({channel: 'itechs-original-games', ...message});
  if (window.ItechsBridge) window.ItechsBridge.postMessage(data);
  else if (window.parent !== window) window.parent.postMessage(data, location.origin);
}
export function request(type, payload = {}) {
  const id = String(++serial);
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {pending.delete(id); reject(new Error('Local game storage did not respond.'));}, 15000);
    pending.set(id, {resolve, reject, timeout});
    send({type, id, ...payload});
  });
}
export function receive(raw) {
  let data;
  try { data = typeof raw === 'string' ? JSON.parse(raw) : raw; } catch { return; }
  if (data?.channel !== 'itechs-original-games') return;
  if (data.type === 'response' && pending.has(data.id)) {
    const waiter = pending.get(data.id); pending.delete(data.id); clearTimeout(waiter.timeout);
    if (data.error) waiter.reject(new Error(data.error)); else waiter.resolve(data.result);
  }
  if (data.type === 'configure') window.dispatchEvent(new CustomEvent('itechs-configure', {detail: data}));
  if (data.type === 'suspend') { window.__itechsSuspended = true; window.dispatchEvent(new Event('blur')); }
  if (data.type === 'resume') { window.__itechsSuspended = false; window.dispatchEvent(new Event('focus')); }
}
window.itechsReceive = receive;
window.addEventListener('message', event => {
  if (event.source === window.parent && event.origin === location.origin) receive(event.data);
});
