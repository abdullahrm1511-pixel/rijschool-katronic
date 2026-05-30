import { Pressable, StyleSheet, Text, View } from 'react-native';

import { getWeekDays, sameDay } from '@/utils/timeSlots';
import { tapFeedback } from '@/utils/haptics';

type WeekStripProps = {
  selectedDate: Date;
  onSelectDate: (date: Date) => void;
};

const dayLetters = ['M', 'D', 'W', 'D', 'V', 'Z', 'Z'];

export function WeekStrip({ selectedDate, onSelectDate }: WeekStripProps) {
  const days = getWeekDays(selectedDate);

  return (
    <View style={styles.container}>
      {days.map((day, index) => {
        const selected = sameDay(day, selectedDate);
        return (
          <Pressable
            key={day.toISOString()}
            onPress={() => {
              tapFeedback();
              onSelectDate(day);
            }}
            style={({ pressed }) => [styles.day, pressed && styles.pressed]}
          >
            <Text style={styles.letter}>{dayLetters[index]}</Text>
            <View style={[styles.numberCircle, selected && styles.selectedCircle]}>
              <Text style={[styles.number, selected && styles.selectedNumber]}>{day.getDate()}</Text>
            </View>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 18,
  },
  day: {
    alignItems: 'center',
    minHeight: 58,
    width: 42,
  },
  pressed: {
    opacity: 0.75,
    transform: [{ scale: 0.94 }],
  },
  letter: {
    color: '#94a3b8',
    fontSize: 12,
    fontWeight: '700',
    marginBottom: 6,
  },
  numberCircle: {
    alignItems: 'center',
    borderRadius: 999,
    height: 34,
    justifyContent: 'center',
    width: 34,
  },
  selectedCircle: {
    backgroundColor: '#ef4444',
  },
  number: {
    color: '#ffffff',
    fontSize: 15,
    fontWeight: '800',
  },
  selectedNumber: {
    color: '#ffffff',
  },
});
