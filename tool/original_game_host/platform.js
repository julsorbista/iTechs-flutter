// Native orientation is controlled by GameplayPage in Flutter. The embedded
// React game must not attempt to call Capacitor plugins in a Flutter WebView.
export const Capacitor = {isNativePlatform: () => false};
export const ScreenOrientation = {lock: async () => {}};
