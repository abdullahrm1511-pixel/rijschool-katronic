import { DarkTheme, ThemeProvider } from '@react-navigation/native';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import 'react-native-reanimated';

import { AppStateProvider } from '@/data/AppState';

export const unstable_settings = {
  anchor: '(tabs)',
};

export default function RootLayout() {
  return (
    <AppStateProvider>
      <ThemeProvider value={DarkTheme}>
        <Stack
          screenOptions={{
            animation: 'ios_from_right',
            contentStyle: { backgroundColor: '#080b10' },
          }}
        >
          <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        </Stack>
        <StatusBar style="light" />
      </ThemeProvider>
    </AppStateProvider>
  );
}
