import {send} from './bridge';
export function useAuth() {
  return {user: window.__ITECHS_LOCAL_CONFIG__.user, logout: () => send({type: 'exit'})};
}
