import {
  KeyboardAvoidingView,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { useMemo, useState } from 'react';

import { Student } from '@/types';
import { successFeedback, tapFeedback } from '@/utils/haptics';

export type BookingMode = 'lesson' | 'weekly' | 'exam';

type StudentPickerModalProps = {
  visible: boolean;
  students: Student[];
  slotLabel: string;
  onClose: () => void;
  onSelectStudent: (studentId: string, mode: BookingMode) => void;
};

export function StudentPickerModal({
  visible,
  students,
  slotLabel,
  onClose,
  onSelectStudent,
}: StudentPickerModalProps) {
  const [query, setQuery] = useState('');
  const [mode, setMode] = useState<BookingMode>('lesson');
  const filteredStudents = useMemo(
    () =>
      students.filter((student) =>
        student.status !== 'Geslaagd' &&
        [student.name, student.phone, student.email]
          .join(' ')
          .toLowerCase()
          .includes(query.toLowerCase()),
      ),
    [query, students],
  );

  return (
    <Modal animationType="slide" transparent visible={visible} onRequestClose={onClose}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        style={styles.keyboardBackdrop}
      >
        <Pressable
          style={styles.backdrop}
          onPress={() => {
            tapFeedback();
            onClose();
          }}
        >
          <Pressable style={styles.sheet}>
            <View style={styles.grabber} />
            <View style={styles.header}>
              <View>
                <Text style={styles.title}>Leerling kiezen</Text>
                <Text style={styles.subtitle}>{slotLabel}</Text>
              </View>
              <Pressable
                onPress={() => {
                  tapFeedback();
                  onClose();
                }}
                style={({ pressed }) => [styles.closeButton, pressed && styles.pressedInline]}
              >
                <Text style={styles.closeText}>Sluit</Text>
              </Pressable>
            </View>
            <TextInput
              placeholder="Zoek leerling"
              placeholderTextColor="#64748b"
              value={query}
              onChangeText={setQuery}
              style={styles.input}
            />
            <View style={styles.modeRow}>
              <ModeButton label="Les" active={mode === 'lesson'} onPress={() => setMode('lesson')} />
              <ModeButton
                label="Wekelijks"
                active={mode === 'weekly'}
                onPress={() => setMode('weekly')}
              />
              <ModeButton label="Examen" active={mode === 'exam'} onPress={() => setMode('exam')} />
            </View>
            <ScrollView
              automaticallyAdjustKeyboardInsets
              contentContainerStyle={styles.listContent}
              keyboardDismissMode="interactive"
              keyboardShouldPersistTaps="handled"
              style={styles.list}
            >
              {filteredStudents.length === 0 ? (
                <Text style={styles.empty}>
                  {students.length === 0
                    ? 'Voeg eerst een leerling toe op het tabblad Leerlingen.'
                    : 'Geen leerling gevonden.'}
                </Text>
              ) : (
                filteredStudents.map((student) => (
                  <Pressable
                    key={student.id}
                    onPress={() => {
                      successFeedback();
                      onSelectStudent(student.id, mode);
                      setQuery('');
                      onClose();
                    }}
                    style={({ pressed }) => [styles.studentRow, pressed && styles.pressed]}
                  >
                    <Text style={styles.studentName}>{student.name}</Text>
                    <Text style={styles.studentMeta}>{student.phone || student.email || 'Geen contactgegevens'}</Text>
                  </Pressable>
                ))
              )}
            </ScrollView>
          </Pressable>
        </Pressable>
      </KeyboardAvoidingView>
    </Modal>
  );
}

function ModeButton({
  label,
  active,
  onPress,
}: {
  label: string;
  active: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable
      onPress={() => {
        tapFeedback();
        onPress();
      }}
      style={({ pressed }) => [
        styles.modeButton,
        active && styles.activeModeButton,
        pressed && styles.pressed,
      ]}
    >
      <Text style={[styles.modeText, active && styles.activeModeText]}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  keyboardBackdrop: {
    flex: 1,
  },
  backdrop: {
    backgroundColor: 'rgba(0,0,0,0.58)',
    flex: 1,
    justifyContent: 'flex-end',
  },
  sheet: {
    backgroundColor: '#080b10',
    borderColor: '#1f2937',
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    borderWidth: 1,
    maxHeight: '82%',
    padding: 20,
    boxShadow: '0 -18px 36px rgba(0, 0, 0, 0.28)',
  },
  grabber: {
    alignSelf: 'center',
    backgroundColor: '#475569',
    borderRadius: 999,
    height: 5,
    marginBottom: 16,
    width: 42,
  },
  header: {
    alignItems: 'flex-start',
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 16,
  },
  title: {
    color: '#ffffff',
    fontSize: 22,
    fontWeight: '800',
  },
  subtitle: {
    color: '#94a3b8',
    fontSize: 14,
    marginTop: 4,
  },
  closeButton: {
    padding: 8,
  },
  closeText: {
    color: '#2563eb',
    fontSize: 16,
    fontWeight: '700',
  },
  input: {
    backgroundColor: '#111827',
    borderColor: '#1f2937',
    borderRadius: 16,
    borderWidth: 1,
    color: '#ffffff',
    fontSize: 16,
    marginBottom: 12,
    paddingHorizontal: 14,
    paddingVertical: 13,
  },
  list: {
    maxHeight: 430,
  },
  listContent: {
    paddingBottom: 160,
  },
  modeRow: {
    flexDirection: 'row',
    gap: 8,
    marginBottom: 12,
  },
  modeButton: {
    alignItems: 'center',
    backgroundColor: '#111827',
    borderColor: '#1f2937',
    borderRadius: 999,
    borderWidth: 1,
    flex: 1,
    paddingVertical: 10,
  },
  activeModeButton: {
    backgroundColor: '#2563eb',
    borderColor: '#2563eb',
  },
  modeText: {
    color: '#cbd5e1',
    fontSize: 13,
    fontWeight: '900',
  },
  activeModeText: {
    color: '#ffffff',
  },
  studentRow: {
    backgroundColor: '#111827',
    borderColor: '#1f2937',
    borderRadius: 18,
    borderWidth: 1,
    marginBottom: 10,
    padding: 15,
  },
  pressed: {
    opacity: 0.82,
    transform: [{ scale: 0.985 }],
  },
  pressedInline: {
    opacity: 0.72,
  },
  studentName: {
    color: '#ffffff',
    fontSize: 17,
    fontWeight: '800',
  },
  studentMeta: {
    color: '#94a3b8',
    fontSize: 14,
    marginTop: 5,
  },
  empty: {
    color: '#94a3b8',
    fontSize: 15,
    lineHeight: 22,
    padding: 18,
    textAlign: 'center',
  },
});
