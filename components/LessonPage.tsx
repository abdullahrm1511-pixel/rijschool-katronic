import { useMemo, useRef } from 'react';
import {
  Alert,
  KeyboardAvoidingView,
  PanResponder,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { ProgressChecklist } from '@/components/ProgressChecklist';
import { useAppState } from '@/data/AppState';
import { actionFeedback, tapFeedback, warningFeedback } from '@/utils/haptics';

type LessonPageProps = {
  lessonId: string;
  onBack: () => void;
};

export function LessonPage({ lessonId, onBack }: LessonPageProps) {
  const { deleteLesson, lessons, students, toggleLessonPaid, updateLesson } = useAppState();
  const lesson = lessons.find((item) => item.id === lessonId);
  const student = students.find((item) => item.id === lesson?.studentId);

  const panResponder = useMemo(
    () =>
      PanResponder.create({
        onMoveShouldSetPanResponder: (_, gesture) =>
          Math.abs(gesture.dx) > 28 && Math.abs(gesture.dy) < 18,
        onPanResponderRelease: (_, gesture) => {
          if (gesture.dx > 80) {
            onBack();
          }
        },
      }),
    [onBack],
  );

  const amountText = useRef(String(lesson?.amount ?? 0));

  if (!lesson || !student) {
    return (
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.missing}>
          <Text style={styles.title}>Les niet gevonden</Text>
          <Pressable onPress={onBack} style={styles.primaryButton}>
            <Text style={styles.primaryButtonText}>Terug</Text>
          </Pressable>
        </View>
      </SafeAreaView>
    );
  }

  amountText.current = String(lesson.amount);
  const isExam = lesson.kind === 'exam';

  return (
    <SafeAreaView style={styles.safeArea} {...panResponder.panHandlers}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        style={styles.keyboard}
      >
        <View style={styles.header}>
          <Pressable
            onPress={() => {
              tapFeedback();
              onBack();
            }}
            style={({ pressed }) => [styles.backButton, pressed && styles.pressedInline]}
          >
            <Text style={styles.backText}>Terug</Text>
          </Pressable>
          <Text style={styles.headerTitle}>Les</Text>
          <View style={styles.headerSpacer} />
        </View>
        <ScrollView
          contentContainerStyle={styles.content}
          keyboardDismissMode="interactive"
          keyboardShouldPersistTaps="handled"
        >
          <View style={styles.heroCard}>
            {isExam ? (
              <View style={styles.examBadge}>
                <Text style={styles.examBadgeText}>Examen</Text>
              </View>
            ) : null}
            <Text style={styles.name}>{student.name}</Text>
            <Text style={styles.meta}>{student.phone || 'Geen telefoonnummer'}</Text>
            <Text style={styles.dateLine}>
              {lesson.date} om {lesson.startTime} - {lesson.endTime}
            </Text>
          </View>

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Algemene lesnotitie</Text>
            <TextInput
              multiline
              placeholder="Wat viel op tijdens deze les?"
              placeholderTextColor="#64748b"
              value={lesson.note}
              onChangeText={(note) => updateLesson(lesson.id, { note })}
              style={styles.noteInput}
            />
          </View>

          {!isExam ? (
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>Behandelde onderdelen</Text>
              <ProgressChecklist studentId={student.id} lessonId={lesson.id} />
            </View>
          ) : null}

          {!isExam ? (
            <View style={styles.paymentCard}>
              <Text style={styles.sectionTitle}>Betaling</Text>
              <Text style={styles.label}>Bedrag</Text>
              <TextInput
                keyboardType="decimal-pad"
                placeholder="55"
                placeholderTextColor="#64748b"
                defaultValue={amountText.current}
                onEndEditing={(event) => {
                  const parsed = Number(event.nativeEvent.text.replace(',', '.'));
                  if (!Number.isNaN(parsed)) {
                    updateLesson(lesson.id, { amount: parsed });
                  }
                }}
                style={styles.amountInput}
              />
              <Pressable
                onPress={() => {
                  actionFeedback();
                  toggleLessonPaid(lesson.id);
                }}
                style={({ pressed }) => [
                  styles.paymentButton,
                  lesson.paid ? styles.paidButton : styles.unpaidButton,
                  pressed && styles.pressedButton,
                ]}
              >
                <Text style={styles.paymentButtonText}>
                  {lesson.paid ? 'Betaald' : 'Niet betaald'}
                </Text>
              </Pressable>
            </View>
          ) : null}

          <Pressable
            onPress={() => {
              warningFeedback();
              Alert.alert(
                isExam ? 'Examen verwijderen' : 'Les verwijderen',
                isExam
                  ? 'Dit examen wordt uit de agenda gehaald.'
                  : 'Deze les wordt weer een vrije plek in de agenda.',
                [
                  { text: 'Annuleer', style: 'cancel' },
                  {
                    text: isExam ? 'Verwijder examen' : 'Verwijder les',
                    style: 'destructive',
                    onPress: () => {
                      deleteLesson(lesson.id);
                      onBack();
                    },
                  },
                ],
              );
            }}
            style={({ pressed }) => [styles.deleteButton, pressed && styles.pressedButton]}
          >
            <Text style={styles.deleteText}>{isExam ? 'Examen verwijderen' : 'Les verwijderen'}</Text>
          </Pressable>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    backgroundColor: '#080b10',
    flex: 1,
  },
  keyboard: {
    flex: 1,
  },
  header: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: 18,
    paddingVertical: 10,
  },
  backButton: {
    minWidth: 70,
    paddingVertical: 10,
  },
  backText: {
    color: '#2563eb',
    fontSize: 16,
    fontWeight: '800',
  },
  headerTitle: {
    color: '#ffffff',
    fontSize: 17,
    fontWeight: '900',
  },
  headerSpacer: {
    width: 70,
  },
  content: {
    padding: 18,
    paddingBottom: 42,
  },
  missing: {
    flex: 1,
    justifyContent: 'center',
    padding: 24,
  },
  heroCard: {
    backgroundColor: '#111827',
    borderColor: '#1f2937',
    borderRadius: 24,
    borderWidth: 1,
    padding: 18,
    boxShadow: '0 12px 24px rgba(0, 0, 0, 0.16)',
  },
  title: {
    color: '#ffffff',
    fontSize: 24,
    fontWeight: '900',
    marginBottom: 18,
  },
  name: {
    color: '#ffffff',
    fontSize: 30,
    fontWeight: '900',
  },
  meta: {
    color: '#94a3b8',
    fontSize: 16,
    marginTop: 8,
  },
  dateLine: {
    color: '#cbd5e1',
    fontSize: 15,
    fontWeight: '700',
    marginTop: 16,
  },
  examBadge: {
    alignSelf: 'flex-start',
    backgroundColor: '#f97316',
    borderRadius: 999,
    marginBottom: 12,
    paddingHorizontal: 11,
    paddingVertical: 6,
  },
  examBadgeText: {
    color: '#ffffff',
    fontSize: 12,
    fontWeight: '900',
  },
  section: {
    marginTop: 22,
  },
  sectionTitle: {
    color: '#ffffff',
    fontSize: 20,
    fontWeight: '900',
    marginBottom: 12,
  },
  noteInput: {
    backgroundColor: '#111827',
    borderColor: '#1f2937',
    borderRadius: 20,
    borderWidth: 1,
    color: '#ffffff',
    fontSize: 16,
    minHeight: 130,
    padding: 14,
    textAlignVertical: 'top',
  },
  paymentCard: {
    backgroundColor: '#111827',
    borderColor: '#1f2937',
    borderRadius: 24,
    borderWidth: 1,
    marginTop: 24,
    padding: 18,
    boxShadow: '0 10px 22px rgba(0, 0, 0, 0.14)',
  },
  label: {
    color: '#94a3b8',
    fontSize: 14,
    fontWeight: '700',
    marginBottom: 8,
  },
  amountInput: {
    backgroundColor: '#0f172a',
    borderColor: '#1f2937',
    borderRadius: 16,
    borderWidth: 1,
    color: '#ffffff',
    fontSize: 18,
    fontWeight: '800',
    marginBottom: 12,
    paddingHorizontal: 14,
    paddingVertical: 13,
  },
  paymentButton: {
    alignItems: 'center',
    borderRadius: 18,
    paddingVertical: 16,
  },
  paidButton: {
    backgroundColor: '#16a34a',
  },
  unpaidButton: {
    backgroundColor: '#dc2626',
  },
  paymentButtonText: {
    color: '#ffffff',
    fontSize: 17,
    fontWeight: '900',
  },
  pressedInline: {
    opacity: 0.72,
  },
  pressedButton: {
    opacity: 0.84,
    transform: [{ scale: 0.985 }],
  },
  deleteButton: {
    alignItems: 'center',
    backgroundColor: '#7f1d1d',
    borderColor: '#b91c1c',
    borderRadius: 18,
    borderWidth: 1,
    marginTop: 18,
    paddingVertical: 16,
  },
  deleteText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '900',
  },
  primaryButton: {
    alignItems: 'center',
    backgroundColor: '#2563eb',
    borderRadius: 18,
    paddingVertical: 16,
  },
  primaryButtonText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '900',
  },
});
