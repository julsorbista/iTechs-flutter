# iTECHS Flutter student simulation

Implemented: student login/logout, home menu, Profile Editor, Settings,
Leaderboards, and My Class with Java lessons, quizzes, and results.
My Progress shows actual lesson and quiz records in a landscape view.
Uses setState, TextEditingController, named routes, for loops, and shared
Lists/Maps. No database or server. Audio playback uses audioplayers.

Sample admin-provided account:
- Username: student01
- Password: Student123!

The active demo student's name is Juan Dela Cruz. Classmate standings are
sample records. The active student's stars start at zero and come from actual
quiz results. Password updates are saved locally as hashes using shared_preferences
and remain after refresh/restart on the same browser/device and web address.
Clearing app/browser storage removes saved password updates. Avatar, course,
progress, and scores remain in memory. No database or student registration is included.

## Run and check

From this project directory:
- Browser preview: flutter run -d chrome --web-port=7357 --no-pub
- Check: flutter analyze
- Tests: flutter test --no-pub --concurrency=1

Fully stop and run after new assets/plugins are added. Do not remove temporary
Flutter folders while a debug session is active. Windows Developer Mode may be
required for plugin symlinks during flutter pub get or Windows desktop builds.
Native audio playback on a physical phone has not been verified here.

## Screens and assets

The supplied screenshots guide the layout. Logo, login background, avatars,
pixel fonts, menu music, click sounds, lesson text, and lesson images come from
the original ZIP. The original AVIF menu background has a PNG copy with the same
artwork. The menu's initial avatar is girl-avatar-3.

Profile selection previews an avatar; Customize saves it and refreshes the menu.
Settings changes the account password and independent music/Sound FX volumes.

My Class contains three Java modules from the ZIP uploads, with original text
and 18 lesson images. LessonData stores the content directly in Dart Lists/Maps;
there is no runtime JSON loader. Each module has ten sample quiz questions,
a 20-minute timer, and an 80% passing score. Course-code examples are FN2LH4CF
(initial) and JAVA2026 (second demo course).

Read every lesson section to unlock its quiz. Pass the quiz to unlock the next
module. Course Outline and module audio controls work. Draft answers resume when
returning to a quiz; submitting removes the draft and creates an attempt record.
Timeout submits once, treating unanswered questions as incorrect.

## Working leaderboard

ClassData holds per-student, per-course progress and quiz attempt history.
Quiz stars use the original thresholds: 85%+ = 3, 70-84% = 2, 50-69% = 1,
below 50% = 0. A retake replaces the stars from that module's previous result;
it does not add duplicate points. Leaderboards recalculates from the latest
results and ranks by stars, completed activities, then name, like the original.
Game stars include locally saved best results for Games 1, 3, and 5.

The regression tests cover login, navigation, profile, settings, ranking, lesson progress,
quiz timeout, star thresholds, retakes, course isolation, and the actual
My Class -> lesson -> quiz -> result -> leaderboard flow. Mobile previews are
in test/previews. Native audio is mocked in automated tests.

My Progress uses average lesson-reading percentage, completed-module count,
latest quiz scores (including zero), and recorded lesson-viewing time. Lesson
time pauses when another route covers the viewer and saves when leaving.
XP and coins remain zero until activities that award them are implemented.
My Progress requests landscape on entry and restores portrait on exit. In browser
windows that remain portrait, its content rotates to preserve the landscape view.
The module table shows status, reading percentage, and latest score.
Progress is scoped to the current student and course, and resets on app restart.

Play includes all six game entries from the ZIP, including Code Robot, game details,
and level selection. Selecting a game opens its overview first. Open Levels then
shows level selection and selected-level details. Back to Games returns to the
six-game menu. Back buttons
remain at the top. Level counts are 5, 5, 10, 5, 5, and 5. Students can inspect
level details and toggle guidelines. First levels are Ready; remaining levels
are Locked. Games 1, 3, and 5 have playable Flutter implementations;
the other three entries retain their existing browsing screens. Browsing levels
does not award stars or attempts. Tests cover all six navigation paths.

## Playable games from iTECHS-mobile.zip

Run `flutter pub get`, then `flutter run -d chrome --web-port=7357`. Log in as
`student01` / `Student123!`, choose Play, select Game 1, 3, or 5, choose
Open Levels, then Start Level. For a connected Android device, use `flutter run`;
the native WebView path still needs a physical-device check.

- Game 1: the original Phaser adventure, including its original HUD, physics,
  enemies, rooms, question gates, guides, tutorials, and results. It requests
  landscape on Android/iOS and rotates the viewport inside portrait browser
  windows. Keyboard: WASD/arrows, Space to jump, Shift to dash, J to attack,
  E to interact, Esc for the original menu. The mobile ZIP supplies its own
  movement, jump, dash, attack, and menu buttons. The third level is the ZIP's
  Operator Fortress curriculum.
- Game 3: ten memory levels with the original card art, shuffled pairs, timed
  preview, and limited comparisons. The current ZIP awards 100 points per match
  immediately; its legacy quiz overlay is not invoked by the matching flow.
  Match at least 75% for two stars and 90% for three stars.
- Game 5: five Code Robot levels from the updated ZIP, replacing the older
  snowman naming. Guess programming terms from clues using touch or a keyboard.
  Wrong guesses remove lives. Solved words earn coins and combo points; a
  one-coin hint reveals a letter. Finish before time or lives run out.

The previous Dart game recreations have been replaced by the original React
components, CSS, Phaser engine, animations, artwork, music, loading screens,
guides, tutorials, and result dialogs from the supplied ZIP. These are packaged
as local Flutter assets. The current bundle uses the newer `iTECHS-mobile.zip`
source, including its mobile controls and phone game layouts. Flutter renders
its existing login/menu/level pages;
Chrome embeds the original games in a local iframe, while Android/iOS use the
system WebView. This is a Flutter app with embedded original web games, not a
native Dart redraw of their interfaces. No external site or backend is needed.
Fonts are bundled for offline use. Filenames are normalized during bundling so
Flutter can serve assets whose original names contain spaces.

Game attempts, best stars/scores, completed-result history, level unlocks, and
coin wallets save through shared_preferences, scoped to student and course.
Saving is local to the device/browser and web origin. Use the same localhost
port between browser runs (`flutter run -d chrome --web-port=7357`) to retain
the same browser storage origin. Clearing browser storage removes saved games.
Active attempts are not resumed after a restart. Earn two stars to unlock the
next level. A failed retry does not erase a previous clear or best score.
Progress saves automatically; the level screen has no saved-results or reset
controls.
The existing profile, lesson, and quiz persistence behavior is unchanged.

The original API imports are replaced only at build time with a local adapter.
Question/hint services use the ZIP's built-in fallback content, and progress,
attempts, scores, coins and unlocks are handled by Flutter's local save bridge.
Android/iOS serve packaged frontend files on loopback for WebView loading; this
file server has no account, database, or business API. Native device performance
and audio still require a physical-device check.

`test/games_test.dart` checks the local bridge, duplicate submissions, saved
results, unlocks, course isolation, reset, original bundle contents, and the
Game 1 landscape viewport. Older class/menu/profile/settings screenshot tests
have known baseline mismatches unrelated to these games.

Browser verification covers the original Game 1 landscape gameplay and menu,
Game 3 matching through its completed result and saved unlock, and Game 5
letter guesses, coins, timeout result, and return to the level screen.
Updated mobile previews are in `test/previews/mobile-game-*.png`. At phone size,
Game 1's own touch Jump and Menu controls were checked in landscape; Game 3's
portrait card board and Game 5's portrait robot/clue/keyboard layout were checked
in Chrome. A solved Game 5 word advanced the round and saved its awarded coins.

To rebuild the bundled original games after changing the ZIP reference:
extract the mobile Frontend into `.reference/mobile/Frontend`. Build dependencies
are reused from `.reference/iTechs/Frontend` (run `npm ci --ignore-scripts` there),
and install @fontsource/manrope, @fontsource/oxanium,
@fontsource/pixelify-sans and @fontsource/space-grotesk into `.reference/game-fonts`.
Run `node tool/import_games.cjs`, then `node tool/build_original_games.mjs`.
Only assets under `assets/original_games` and the level JSON are required at
runtime. Exclude `.reference`, node_modules, build and .dart_tool when packaging.
