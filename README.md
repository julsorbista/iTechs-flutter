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
- Browser preview: flutter run -d chrome --no-pub
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
Game stars will be connected when games are implemented.

Twenty-three tests cover login, navigation, profile, settings, ranking, lesson progress,
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

Play includes all six games from the ZIP, including Code Snowman, game details,
and level selection. Selecting a game opens its overview first. Open Levels then
shows level selection and selected-level details. Back to Games returns to the
six-game menu. Back buttons
remain at the top. Level counts are 5, 5, 10, 5, 5, and 5. Students can inspect
level details and toggle guidelines. First levels are Ready; remaining levels
are Locked. Start Level is disabled until gameplay is implemented. Browsing
levels does not award stars or attempts. Tests cover all six navigation paths.
