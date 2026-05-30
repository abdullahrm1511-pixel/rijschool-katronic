import { useMemo, useState } from 'react';
import {
  KeyboardAvoidingView,
  LayoutAnimation,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { StudentCard } from '@/components/StudentCard';
import { StudentDetailPage } from '@/components/StudentDetailPage';
import { ScreenTransition } from '@/components/ScreenTransition';
import { useAppState } from '@/data/AppState';
import { HealthDeclarationStatus, NewStudentInput, TheoryStatus } from '@/types';
import { actionFeedback, successFeedback, tapFeedback } from '@/utils/haptics';
import { calculateAge } from '@/utils/student';

const healthOptions: HealthDeclarationStatus[] = [
  'Niet gestart',
  'Aangevraagd',
  'Goedgekeurd',
  'Extra beoordeling',
];

const theoryOptions: TheoryStatus[] = ['Niet gestart', 'Bezig', 'Gehaald', 'Verlopen'];

const emptyForm: NewStudentInput = {
  name: '',
  address: '',
  birthDate: '',
  phone: '',
  email: '',
  status: 'Actief',
  healthDeclaration: 'Niet gestart',
  theoryStatus: 'Niet gestart',
  notes: '',
  pickupAddress: '',
};

export default function StudentsScreen() {
  const { students, lessons, addStudent, getOutstandingAmount } = useAppState();
  const [query, setQuery] = useState('');
  const [addVisible, setAddVisible] = useState(false);
  const [selectedStudentId, setSelectedStudentId] = useState<string | null>(null);
  const [form, setForm] = useState<NewStudentInput>(emptyForm);
  const [showGraduated, setShowGraduated] = useState(false);

  const filteredStudents = useMemo(
    () =>
      students.filter((student) =>
        (showGraduated ? student.status === 'Geslaagd' : student.status !== 'Geslaagd') &&
        [student.name, student.phone, student.email, student.address]
          .join(' ')
          .toLowerCase()
          .includes(query.toLowerCase()),
      ),
    [query, showGraduated, students],
  );

  const activeCount = students.filter((student) => student.status !== 'Geslaagd').length;
  const graduatedCount = students.filter((student) => student.status === 'Geslaagd').length;
  const canSave = form.name.trim().length > 0;
  const showStudentGroup = (graduated: boolean) => {
    tapFeedback();
    LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
    setShowGraduated(graduated);
  };
  const closeAddForm = () => {
    tapFeedback();
    setForm(emptyForm);
    setAddVisible(false);
  };
  const saveStudent = () => {
    if (!canSave) {
      return;
    }
    successFeedback();
    const studentId = addStudent({
      ...form,
      name: form.name.trim(),
    });
    setForm(emptyForm);
    setAddVisible(false);
    setSelectedStudentId(studentId);
  };

  if (selectedStudentId) {
    return (
      <ScreenTransition>
        <StudentDetailPage
          studentId={selectedStudentId}
          onBack={() => setSelectedStudentId(null)}
        />
      </ScreenTransition>
    );
  }
  return (
    <SafeAreaView style={styles.safeArea}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        style={styles.keyboard}
      >
        <View style={styles.header}>
          <View>
            <Text style={styles.title}>Leerlingen</Text>
            <Text style={styles.subtitle}>
              {activeCount} actief, {graduatedCount} geslaagd
            </Text>
          </View>
        </View>

        <ScrollView
          contentContainerStyle={styles.content}
          automaticallyAdjustKeyboardInsets
          keyboardDismissMode="interactive"
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          <TextInput
            placeholder="Zoek leerling"
            placeholderTextColor="#64748b"
            value={query}
            onChangeText={setQuery}
            style={styles.searchInput}
          />
          <View style={styles.segmentedControl}>
            <Pressable
              onPress={() => showStudentGroup(false)}
              style={({ pressed }) => [
                styles.segmentButton,
                !showGraduated && styles.activeSegment,
                pressed && styles.pressedSegment,
              ]}
            >
              <Text style={[styles.segmentText, !showGraduated && styles.activeSegmentText]}>
                Actief
              </Text>
            </Pressable>
            <Pressable
              onPress={() => showStudentGroup(true)}
              style={({ pressed }) => [
                styles.segmentButton,
                showGraduated && styles.activeSegment,
                pressed && styles.pressedSegment,
              ]}
            >
              <Text style={[styles.segmentText, showGraduated && styles.activeSegmentText]}>
                Geslaagd
              </Text>
            </Pressable>
          </View>
          {filteredStudents.length === 0 ? (
            <View style={styles.emptyCard}>
              <Text style={styles.emptyTitle}>
                {showGraduated ? 'Geen geslaagde leerlingen' : 'Geen actieve leerlingen'}
              </Text>
              <Text style={styles.emptyText}>
                Voeg een leerling toe om lessen te plannen en voortgang bij te houden.
              </Text>
            </View>
          ) : (
            filteredStudents.map((student) => (
              <StudentCard
                key={student.id}
                student={student}
                lessonCount={lessons.filter((lesson) => lesson.studentId === student.id).length}
                outstandingAmount={getOutstandingAmount(student.id)}
                onPress={() => setTimeout(() => setSelectedStudentId(student.id), 70)}
              />
            ))
          )}
          <Pressable
            onPress={() => {
              actionFeedback();
              setAddVisible(true);
            }}
            style={({ pressed }) => [styles.bottomAddButton, pressed && styles.pressedButton]}
          >
            <Text style={styles.addButtonText}>Leerling toevoegen</Text>
          </Pressable>
        </ScrollView>

        <Modal
          animationType="slide"
          presentationStyle="pageSheet"
          visible={addVisible}
          onRequestClose={closeAddForm}
        >
          <SafeAreaView style={styles.modalSafeArea}>
            <KeyboardAvoidingView
              behavior={Platform.OS === 'ios' ? 'padding' : undefined}
              style={styles.keyboard}
            >
              <View style={styles.modalHeader}>
                <View style={styles.headerSpacer} />
                <Text style={styles.modalTitle}>Nieuwe leerling</Text>
                <View style={styles.headerSpacer} />
              </View>
              <ScrollView
                contentContainerStyle={styles.formContent}
                automaticallyAdjustKeyboardInsets
                keyboardDismissMode="interactive"
                keyboardShouldPersistTaps="handled"
              >
                <Field label="Naam" value={form.name} onChangeText={(name) => setForm({ ...form, name })} />
                <Field label="Adres" value={form.address} onChangeText={(address) => setForm({ ...form, address })} />
                <Field
                  label="Geboortedatum"
                  value={form.birthDate}
                  onChangeText={(birthDate) => setForm({ ...form, birthDate })}
                />
                <View style={styles.agePreview}>
                  <Text style={styles.fieldLabel}>Leeftijd</Text>
                  <Text style={styles.ageText}>{calculateAge(form.birthDate) || '-'}</Text>
                </View>
                <Field label="Telefoonnummer" value={form.phone} onChangeText={(phone) => setForm({ ...form, phone })} keyboardType="phone-pad" />
                <Field label="E-mail" value={form.email} onChangeText={(email) => setForm({ ...form, email })} keyboardType="email-address" />
                <OptionGroup
                  label="Gezondheidsverklaring"
                  options={healthOptions}
                  value={form.healthDeclaration}
                  onChange={(healthDeclaration) => setForm({ ...form, healthDeclaration })}
                />
                <OptionGroup
                  label="Theorie status"
                  options={theoryOptions}
                  value={form.theoryStatus}
                  onChange={(theoryStatus) => setForm({ ...form, theoryStatus })}
                />
                <Field label="Ophaaladres" value={form.pickupAddress} onChangeText={(pickupAddress) => setForm({ ...form, pickupAddress })} />
                <Field label="Notities" value={form.notes} onChangeText={(notes) => setForm({ ...form, notes })} multiline />
                <View style={styles.formActions}>
                  <Pressable
                    onPress={closeAddForm}
                    style={({ pressed }) => [styles.cancelBottomButton, pressed && styles.pressedButton]}
                  >
                    <Text style={styles.cancelBottomText}>Annuleer</Text>
                  </Pressable>
                  <Pressable
                    disabled={!canSave}
                    onPress={saveStudent}
                    style={({ pressed }) => [
                      styles.saveBottomButton,
                      !canSave && styles.disabledButton,
                      pressed && canSave && styles.pressedButton,
                    ]}
                  >
                    <Text style={[styles.saveBottomText, !canSave && styles.disabledText]}>
                      Bewaar leerling
                    </Text>
                  </Pressable>
                </View>
              </ScrollView>
            </KeyboardAvoidingView>
          </SafeAreaView>
        </Modal>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

function Field({
  label,
  value,
  onChangeText,
  multiline,
  keyboardType,
}: {
  label: string;
  value: string;
  onChangeText: (value: string) => void;
  multiline?: boolean;
  keyboardType?: 'default' | 'email-address' | 'number-pad' | 'phone-pad';
}) {
  return (
    <View style={styles.field}>
      <Text style={styles.fieldLabel}>{label}</Text>
      <TextInput
        value={value}
        onChangeText={onChangeText}
        keyboardType={keyboardType}
        multiline={multiline}
        placeholder={label}
        placeholderTextColor="#64748b"
        style={[styles.input, multiline && styles.multilineInput]}
      />
    </View>
  );
}

function OptionGroup<T extends string>({
  label,
  options,
  value,
  onChange,
}: {
  label: string;
  options: T[];
  value: T;
  onChange: (value: T) => void;
}) {
  return (
    <View style={styles.field}>
      <Text style={styles.fieldLabel}>{label}</Text>
      <View style={styles.optionWrap}>
        {options.map((option) => (
          <Pressable
            key={option}
            onPress={() => {
              tapFeedback();
              onChange(option);
            }}
            style={({ pressed }) => [
              styles.optionButton,
              value === option && styles.activeOption,
              pressed && styles.pressedOption,
            ]}
          >
            <Text style={[styles.optionText, value === option && styles.activeOptionText]}>
              {option}
            </Text>
          </Pressable>
        ))}
      </View>
    </View>
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
    paddingTop: 8,
  },
  title: {
    color: '#ffffff',
    fontSize: 32,
    fontWeight: '900',
  },
  subtitle: {
    color: '#94a3b8',
    fontSize: 14,
    marginTop: 3,
  },
  addButtonText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '900',
  },
  content: {
    padding: 18,
    paddingBottom: 180,
  },
  searchInput: {
    backgroundColor: '#111827',
    borderColor: '#1f2937',
    borderRadius: 18,
    borderWidth: 1,
    color: '#ffffff',
    fontSize: 16,
    marginBottom: 16,
    paddingHorizontal: 15,
    paddingVertical: 14,
    boxShadow: '0 8px 18px rgba(0, 0, 0, 0.12)',
  },
  segmentedControl: {
    backgroundColor: '#111827',
    borderColor: '#1f2937',
    borderRadius: 18,
    borderWidth: 1,
    flexDirection: 'row',
    gap: 6,
    marginBottom: 16,
    padding: 5,
    boxShadow: '0 8px 18px rgba(0, 0, 0, 0.12)',
  },
  segmentButton: {
    alignItems: 'center',
    borderRadius: 13,
    flex: 1,
    paddingVertical: 10,
  },
  activeSegment: {
    backgroundColor: '#2563eb',
  },
  pressedSegment: {
    opacity: 0.84,
    transform: [{ scale: 0.97 }],
  },
  segmentText: {
    color: '#94a3b8',
    fontSize: 14,
    fontWeight: '900',
  },
  activeSegmentText: {
    color: '#ffffff',
  },
  emptyCard: {
    backgroundColor: '#111827',
    borderColor: '#1f2937',
    borderRadius: 22,
    borderWidth: 1,
    padding: 20,
    boxShadow: '0 10px 22px rgba(0, 0, 0, 0.16)',
  },
  emptyTitle: {
    color: '#ffffff',
    fontSize: 20,
    fontWeight: '900',
    marginBottom: 8,
  },
  emptyText: {
    color: '#94a3b8',
    fontSize: 15,
    lineHeight: 22,
  },
  bottomAddButton: {
    alignItems: 'center',
    backgroundColor: '#2563eb',
    borderRadius: 18,
    marginTop: 10,
    paddingVertical: 16,
    boxShadow: '0 12px 24px rgba(37, 99, 235, 0.22)',
  },
  pressedButton: {
    opacity: 0.84,
    transform: [{ scale: 0.985 }],
  },
  modalSafeArea: {
    backgroundColor: '#080b10',
    flex: 1,
  },
  modalHeader: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: 18,
    paddingVertical: 10,
  },
  modalTitle: {
    color: '#ffffff',
    fontSize: 17,
    fontWeight: '900',
  },
  headerSpacer: {
    width: 78,
  },
  disabledText: {
    color: '#475569',
  },
  disabledButton: {
    backgroundColor: '#1e293b',
  },
  formContent: {
    padding: 18,
    paddingBottom: 180,
  },
  field: {
    marginBottom: 15,
  },
  fieldLabel: {
    color: '#cbd5e1',
    fontSize: 14,
    fontWeight: '800',
    marginBottom: 8,
  },
  input: {
    backgroundColor: '#111827',
    borderColor: '#1f2937',
    borderRadius: 17,
    borderWidth: 1,
    color: '#ffffff',
    fontSize: 16,
    paddingHorizontal: 14,
    paddingVertical: 13,
  },
  agePreview: {
    backgroundColor: '#111827',
    borderColor: '#1f2937',
    borderRadius: 17,
    borderWidth: 1,
    marginBottom: 15,
    paddingHorizontal: 14,
    paddingVertical: 13,
  },
  ageText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '800',
  },
  multilineInput: {
    minHeight: 92,
    textAlignVertical: 'top',
  },
  optionWrap: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  optionButton: {
    backgroundColor: '#111827',
    borderColor: '#1f2937',
    borderRadius: 999,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  pressedOption: {
    opacity: 0.82,
    transform: [{ scale: 0.96 }],
  },
  activeOption: {
    backgroundColor: '#2563eb',
    borderColor: '#2563eb',
  },
  optionText: {
    color: '#cbd5e1',
    fontSize: 13,
    fontWeight: '800',
  },
  activeOptionText: {
    color: '#ffffff',
  },
  formActions: {
    gap: 10,
    marginTop: 4,
  },
  cancelBottomButton: {
    alignItems: 'center',
    backgroundColor: '#111827',
    borderColor: '#334155',
    borderRadius: 18,
    borderWidth: 1,
    paddingVertical: 15,
  },
  cancelBottomText: {
    color: '#cbd5e1',
    fontSize: 16,
    fontWeight: '900',
  },
  saveBottomButton: {
    alignItems: 'center',
    backgroundColor: '#2563eb',
    borderRadius: 18,
    paddingVertical: 16,
    boxShadow: '0 12px 24px rgba(37, 99, 235, 0.2)',
  },
  saveBottomText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '900',
  },
});
