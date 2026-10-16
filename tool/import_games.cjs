// Import the ZIP's own level data, including the published Operators Level 3.
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const source = path.join(root, '.reference/mobile/Frontend/src');
const catalog = require(path.join(source, 'games/game-three/data/levelCatalog.cjs'));
const robot = fs.readFileSync(path.join(source, 'games/game-five/ui/GameCanvasGameFive.jsx'), 'utf8');
const wordBlock = robot.match(/const WORDS_BY_LEVEL = Object.freeze\(([\s\S]*?)\);/)[1];
const words = Function('return (' + wordBlock + ')')();
const data = {one: [], three: Object.values(catalog.GAME_THREE_LEVEL_SEEDS), five: []};
for (let n = 1; n <= 5; n++) {
  const file = 'level-' + String(n).padStart(2, '0') + '.json';
  data.one.push(JSON.parse(fs.readFileSync(path.join(source, 'games/game-one/data/levels', n === 3 ? 'level-03-operators.json' : file))));
  data.five.push({...JSON.parse(fs.readFileSync(path.join(source, 'games/game-five/data/levels', file))), words: words[n]});
}
fs.mkdirSync(path.join(root, 'assets/games'), {recursive:true});
fs.writeFileSync(path.join(root, 'assets/games/levels.json'), JSON.stringify(data));
console.log('Imported 5 original adventure levels, 10 memory levels and 5 robot levels.');
