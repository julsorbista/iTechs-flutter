import levels from '@flutter-levels';
import {request} from './bridge';
const groups = {GAME_ONE: 'one', GAME_THREE: 'three', GAME_FIVE: 'five'};
const success = data => ({status: 'success', data});
export const levelAPI = {
  async getPlayableLevelContent(game, number) {
    const levelData = levels[groups[game]]?.[number - 1];
    return levelData ? success({levelData: structuredClone(levelData)}) : {status: 'unavailable'};
  },
  async startLevelSession(game, number) {
    const result = await request('start', {game, number});
    return success({...result, gameType: game, levelNumber: number,
      policy: {freeMistakes: 3, hintCoinCost: 1, hintStarCost: 1}});
  },
  async submitLevelSession(game, number, session, payload) {
    return success(await request('finish', {game, number, session, payload}));
  },
  async generateGameQuestions(game, number, data) {
    // Use the ZIP's own offline fallback content; no model service is called.
    return success({questions: data.fallbackQuestions, tasks: data.fallbackTasks, source: 'local'});
  },
  async generateGameHint(game, number, data) { return success({hint: data.fallbackHint}); },
};
export const handleAPIError = error => ({message: error?.message || 'Local storage is unavailable.'});
export const authAPI = {};
export const userAPI = {};
export default {};
