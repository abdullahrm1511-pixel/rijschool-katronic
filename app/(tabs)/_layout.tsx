import { Tabs } from 'expo-router';
import React from 'react';
import { StyleSheet, Text, View } from 'react-native';

import { HapticTab } from '@/components/haptic-tab';

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        sceneStyle: { backgroundColor: '#080b10' },
        tabBarButton: HapticTab,
        tabBarActiveTintColor: '#ffffff',
        tabBarInactiveTintColor: '#94a3b8',
        tabBarStyle: {
          backgroundColor: '#0b1120',
          borderTopColor: '#1f2937',
          height: 82,
          paddingBottom: 24,
          paddingTop: 10,
          boxShadow: '0 -10px 24px rgba(0, 0, 0, 0.22)',
        },
        tabBarLabelStyle: {
          fontSize: 12,
          fontWeight: '800',
        },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Agenda',
          tabBarIcon: ({ color }) => <TabIcon color={color} label="A" />,
        }}
      />
      <Tabs.Screen
        name="explore"
        options={{
          title: 'Leerlingen',
          tabBarIcon: ({ color }) => <TabIcon color={color} label="L" />,
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: 'Instellingen',
          tabBarIcon: ({ color }) => <TabIcon color={color} label="I" />,
        }}
      />
    </Tabs>
  );
}

function TabIcon({ color, label }: { color: string; label: string }) {
  return (
    <View style={[styles.icon, { borderColor: color }]}>
      <Text style={[styles.iconText, { color }]}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  icon: {
    alignItems: 'center',
    borderRadius: 9,
    borderWidth: 1.5,
    height: 24,
    justifyContent: 'center',
    width: 24,
  },
  iconText: {
    fontSize: 12,
    fontWeight: '900',
  },
});
