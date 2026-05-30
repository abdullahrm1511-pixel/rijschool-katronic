import { Pressable, StyleSheet, Text, View } from 'react-native';

import { Lesson, Student } from '@/types';
import { actionFeedback, tapFeedback } from '@/utils/haptics';

type AgendaSlotProps = {
  startTime: string;
  endTime: string;
  lesson?: Lesson;
  student?: Student;
  span?: number;
  onPress: () => void;
  onLongPress?: () => void;
};

export function AgendaSlot({
  startTime,
  endTime,
  lesson,
  student,
  span = 1,
  onPress,
  onLongPress,
}: AgendaSlotProps) {
  const occupied = Boolean(lesson && student);
  const isExam = lesson?.kind === 'exam';

  return (
    <Pressable
      onPress={() => {
        tapFeedback();
        onPress();
      }}
      onLongPress={() => {
        actionFeedback();
        onLongPress?.();
      }}
      style={({ pressed }) => [styles.row, pressed && styles.pressed]}
    >
      <View style={styles.timeColumn}>
        <Text style={styles.time}>{startTime}</Text>
        <Text style={styles.endTime}>{endTime}</Text>
      </View>
      <View
        style={[
          styles.card,
          { minHeight: 88 * span + 12 * (span - 1) },
          occupied ? styles.busyCard : styles.freeCard,
          isExam && styles.examCard,
        ]}
      >
        {occupied && lesson && student ? (
          <>
            <View style={styles.cardHeader}>
              <Text style={styles.title}>{student.name}</Text>
              <View style={[styles.badge, isExam ? styles.examBadge : lesson.paid ? styles.paid : styles.unpaid]}>
                <Text style={styles.badgeText}>
                  {isExam ? 'Examen' : lesson.paid ? 'Betaald' : 'Niet betaald'}
                </Text>
              </View>
            </View>
            <Text style={styles.subtitle}>
              {isExam ? 'Examen ingepland' : student.phone || 'Geen telefoonnummer'}
            </Text>
            <Text style={styles.meta}>
              {lesson.startTime} - {lesson.endTime}
              {lesson.recurringSeriesId ? ' · Wekelijks' : ''}
              {!isExam ? ` · EUR ${lesson.amount.toFixed(2)}` : ''}
            </Text>
          </>
        ) : (
          <>
            <Text style={styles.title}>Vrije plek</Text>
            <Text style={styles.subtitle}>Tik voor les, houd vast voor blokuur</Text>
          </>
        )}
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 12,
  },
  pressed: {
    opacity: 0.82,
    transform: [{ scale: 0.985 }],
  },
  timeColumn: {
    alignItems: 'flex-end',
    paddingTop: 18,
    width: 54,
  },
  time: {
    color: '#ffffff',
    fontSize: 14,
    fontWeight: '700',
  },
  endTime: {
    color: '#64748b',
    fontSize: 12,
    marginTop: 4,
  },
  card: {
    borderRadius: 22,
    borderWidth: 1,
    flex: 1,
    minHeight: 88,
    padding: 16,
    boxShadow: '0 10px 22px rgba(0, 0, 0, 0.18)',
  },
  busyCard: {
    backgroundColor: '#111827',
    borderColor: '#2563eb',
  },
  examCard: {
    backgroundColor: '#2a1115',
    borderColor: '#f97316',
  },
  freeCard: {
    backgroundColor: '#0f172a',
    borderColor: '#1f2937',
  },
  cardHeader: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: 8,
    justifyContent: 'space-between',
  },
  title: {
    color: '#ffffff',
    flex: 1,
    fontSize: 18,
    fontWeight: '800',
  },
  subtitle: {
    color: '#94a3b8',
    fontSize: 14,
    marginTop: 8,
  },
  meta: {
    color: '#cbd5e1',
    fontSize: 13,
    marginTop: 8,
  },
  badge: {
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 5,
  },
  paid: {
    backgroundColor: '#16a34a',
  },
  unpaid: {
    backgroundColor: '#dc2626',
  },
  examBadge: {
    backgroundColor: '#f97316',
  },
  badgeText: {
    color: '#ffffff',
    fontSize: 11,
    fontWeight: '800',
  },
});
