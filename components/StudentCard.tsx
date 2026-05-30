import { Pressable, StyleSheet, Text, View } from 'react-native';

import { Student } from '@/types';
import { tapFeedback } from '@/utils/haptics';

type StudentCardProps = {
  student: Student;
  outstandingAmount: number;
  lessonCount: number;
  onPress: () => void;
};

export function StudentCard({ student, outstandingAmount, lessonCount, onPress }: StudentCardProps) {
  return (
    <Pressable
      onPress={() => {
        tapFeedback();
        onPress();
      }}
      style={({ pressed }) => [styles.card, pressed && styles.pressed]}
    >
      <View style={styles.topRow}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>{student.name.trim().charAt(0).toUpperCase() || '?'}</Text>
        </View>
        <View style={styles.main}>
          <Text style={styles.name}>{student.name}</Text>
          <Text style={styles.meta}>{student.phone || student.email || 'Geen contactgegevens'}</Text>
        </View>
      </View>
      <View style={styles.footer}>
        <Text style={styles.footerText}>{lessonCount} lessen</Text>
        <Text style={[styles.statusText, student.status === 'Geslaagd' && styles.graduated]}>
          {student.status}
        </Text>
        <Text style={[styles.footerText, outstandingAmount > 0 && styles.debt]}>
          EUR {outstandingAmount.toFixed(2)} open
        </Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#111827',
    borderColor: '#1f2937',
    borderRadius: 22,
    borderWidth: 1,
    marginBottom: 12,
    padding: 16,
    boxShadow: '0 10px 22px rgba(0, 0, 0, 0.16)',
  },
  pressed: {
    opacity: 0.82,
    transform: [{ scale: 0.985 }],
  },
  topRow: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: 12,
  },
  avatar: {
    alignItems: 'center',
    backgroundColor: '#2563eb',
    borderRadius: 20,
    height: 40,
    justifyContent: 'center',
    width: 40,
  },
  avatarText: {
    color: '#ffffff',
    fontSize: 18,
    fontWeight: '900',
  },
  main: {
    flex: 1,
  },
  name: {
    color: '#ffffff',
    fontSize: 18,
    fontWeight: '800',
  },
  meta: {
    color: '#94a3b8',
    fontSize: 14,
    marginTop: 4,
  },
  footer: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 14,
  },
  footerText: {
    color: '#cbd5e1',
    fontSize: 13,
    fontWeight: '700',
  },
  debt: {
    color: '#ef4444',
  },
  statusText: {
    backgroundColor: '#0f172a',
    borderRadius: 999,
    color: '#cbd5e1',
    fontSize: 12,
    fontWeight: '900',
    paddingHorizontal: 9,
    paddingVertical: 5,
  },
  graduated: {
    backgroundColor: '#16a34a',
    color: '#ffffff',
  },
});
