import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

function inlineHints(source) {
  const journalStart = source.indexOf('zs.on("pointerup",()=>{\n      if(this.hasAnswered)return;');
  if (journalStart >= 0) {
    const journalEnd = source.indexOf('}),qt.on("pointerup"', journalStart);
    if (journalEnd < 0) throw new Error('Cannot locate the end of the added hint popup');
    source = source.slice(0, journalStart) +
      'zs.on("pointerup",()=>{if(pe(),!es){Ws("This question does not have extra hints yet.",ri.textSoft),bt();return}nt()})' +
      source.slice(journalEnd + 2);
  }
  const before = 'this.feedbackText=this.add.dom(Qi,ls,Ai).setOrigin(.5);const Ws=(Ct,ui=ri.textDark)=>{';
  const after = 'this.feedbackText=this.add.text(Qi,ls-(o&&ue?8*L:0),"",{fontFamily:"Manrope, Arial, sans-serif",fontSize:Ia(o&&ue?12:16,o&&ue?L:h),color:ri.textDark,align:"center",wordWrap:{width:$t,useAdvancedWrap:!0},lineSpacing:2}).setOrigin(.5);const Ws=(Ct,ui=ri.textDark)=>{this.feedbackText.setText(Ct).setColor(ui);';
  if (source.split(before).length !== 2) throw new Error('Hint feedback source changed');
  return source.replace(before, after) + '\n/* itechs-game-one-inline-hints-v2 */\n';
}

// The imported mobile sources are not included in this checkout. Keep these
// narrow, guarded repairs reproducible against the checked-in offline bundle.
export function repairGameOneUi(source) {
  source = source.replace('this.feedbackText=this.add.text(Qi,ls,"",',
    'this.feedbackText=this.add.text(Qi,ls-(o&&ue?8*L:0),"",');
  if (source.includes('/* itechs-game-one-inline-hints-v2 */')) return source;
  if (source.includes('/* itechs-game-one-ui-v1 */')) return inlineHints(source);
  function replace(before, after) {
    if (source.split(before).length !== 2) throw new Error(`Game 1 repair needs review: ${before.slice(0, 80)}`);
    source = source.replace(before, after);
  }
  // Canvas text shares the frame's coordinate system. DOM text was clipped or
  // displaced by the mobile canvas/DOM layout overrides.
  replace('const Bs=this.add.dom(kt,ei,Ft).setOrigin(0,0)',
    'const Bs=this.add.text(kt,ei,ni.textContent,{fontFamily:"Manrope, Arial, sans-serif",fontSize:Ia(o&&ue?13:20,o&&ue?L:h),color:ri.textDark,align:"center",wordWrap:{width:Ze,useAdvancedWrap:!0},lineSpacing:Math.round(2*L)}).setOrigin(0,0)');
  // A missing optional scroll texture must not suppress the educational clue.
  replace('if(!i||!this.textures.exists(n))return;', 'if(!i)return;');
  replace('x=this.textures.get(n).getSourceImage()',
    'x=this.textures.exists(n)?this.textures.get(n).getSourceImage():null');
  replace('a=this.add.image(p,w,n).setScrollFactor(0).setDepth(10001).setDisplaySize(r,o)',
    'a=(this.textures.exists(n)?this.add.image(p,w,n).setDisplaySize(r,o):this.add.rectangle(p,w,r,o,0xffe7b3).setStrokeStyle(5,0x79532f)).setScrollFactor(0).setDepth(10001)');
  return inlineHints(source + '\n/* itechs-game-one-ui-v1 */\n');
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const directory = path.join(root, 'assets/original_games');
  const bundle = fs.readdirSync(directory).find(name => /^game-.*\.js$/.test(name));
  const target = path.join(directory, bundle);
  const original = fs.readFileSync(target, 'utf8');
  const repaired = repairGameOneUi(original);
  if (original !== repaired) fs.writeFileSync(target, repaired);
  fs.copyFileSync(path.join(root, 'tool/original_game_host/game-one-ui.css'), path.join(directory, 'game-one-ui.css'));
  const indexPath = path.join(directory, 'index.html');
  let index = fs.readFileSync(indexPath, 'utf8');
  const cssLink = '<link rel="stylesheet" href="./game-one-ui.css?v=2">';
  if (/\<link[^>]+href="\.\/game-one-ui\.css(?:\?[^"]*)?"[^>]*>/.test(index)) {
    index = index.replace(/\<link[^>]+href="\.\/game-one-ui\.css(?:\?[^"]*)?"[^>]*>/, cssLink);
  } else {
    index = index.replace('</head>', cssLink + '\n</head>');
  }
  fs.writeFileSync(indexPath, index);
  console.log('Game 1 riddle and inline hint repairs applied.');
}
