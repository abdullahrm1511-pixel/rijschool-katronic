import { useMemo, useState } from 'react';
import {
  Alert,
  KeyboardAvoidingView,
  LayoutAnimation,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { ProgressChecklist } from '@/components/ProgressChecklist';
import { useAppState } from '@/data/AppState';
import {
  HealthDeclarationStatus,
  NewStudentInput,
  ProgressStatus,
  Student,
  StudentStatus,
  TheoryStatus,
} from '@/types';
import { actionFeedback, tapFeedback, warningFeedback } from '@/utils/haptics';
import { calculateAge } from '@/utils/student';

type DetailTab = 'Leerling' | 'Aandachtspunten' | 'Onderdelen';
type ProgressFilter = ProgressStatus | 'Alles';

type StudentDetailPageProps = {
  studentId: string;
  onBack: () => void;
};

const detailTabs: DetailTab[] = ['Leerling', 'Aandachtspunten', 'Onderdelen'];
const filters: ProgressFilter[] = ['Alles', 'Slecht', 'Matig', 'Goed', 'Beheerst'];
const studentStatuses: StudentStatus[] = ['Actief', 'Geslaagd'];
const healthOptions: HealthDeclarationStatus[] = [
  'Niet gestart',
  'Aangevraagd',
  'Goedgekeurd',
  'Extra beoordeling',
];
const theoryOptions: TheoryStatus[] = ['Niet gestart', 'Bezig', 'Gehaald', 'Verlopen'];

export function StudentDetailPage({ studentId, onBack }: StudentDetailPageProps) {
  const { students, lessons, deleteStudent, getOutstandingAmount, updateStudent } = useAppState();
  const [activeTab, setActiveTab] = useState<DetailTab>('Leerling');
  const [filter, setFilter] = useState<ProgressFilter>('Alles');
  const student = students.find((item) => item.id === studentId);

  const studentLessons = useMemo(
    () => lessons.filter((lesson) => lesson.studentId === studentId),
    [lessons, studentId],
  );

  if (!student) {
    return (
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.missing}>
          <Text style={styles.title}>Leerling niet gevonden</Text>
          <Pressable onPress={onBack} style={styles.primaryButton}>
            <Text style={styles.primaryButtonText}>Terug</Text>
          </Pressable>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.safeArea}>
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
          <Text style={styles.headerTitle}>Leerling</Text>
          <View style={styles.headerSpacer} />
        </View>
        <ScrollView
          contentContainerStyle={styles.content}
          keyboardDismissMode="interactive"
          keyboardShouldPersistTaps="handled"
        >
          <View style={styles.heroCard}>
            <Text style={styles.name}>{student.name}</Text>
            <Text style={styles.meta}>{student.phone || student.email || 'Geen contactgegevens'}</Text>
          </View>

          <View style={styles.tabs}>
            {detailTabs.map((tab) => (
              <Pressable
                key={tab}
                onPress={() => {
                  tapFeedback();
                  LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
                  setActiveTab(tab);
                }}
                style={({ pressed }) => [
                  styles.tabButton,
                  activeTab === tab && styles.activeTab,
                  pressed && styles.pressedPill,
                ]}
              >
                <Text style={[styles.tabText, activeTab === tab && styles.activeTabText]}>{tab}</Text>
              </Pressable>
            ))}
          </View>

          {activeTab === 'Leerling' ? (
            <StudentInfo
              student={student}
              lessonCount={studentLessons.length}
              outstandingAmount={getOutstandingAmount(student.id)}
              onUpdate={updateStudent}
              onDelete={() => {
                warningFeedback();
                Alert.alert(
                  'Leerling verwijderen',
                  'Weet je zeker dat je deze leerling met alle lessen en voortgang wilt verwijderen?',
                  [
                    { text: 'Annuleer', style: 'cancel' },
                    {
                      text: 'Verwijder',
                      style: 'destructive',
                      onPress: () => {
                        deleteStudent(student.id);
                        onBack();
                      },
                    },
                  ],
                );
              }}
            />
          ) : null}

          {activeTab === 'Aandachtspunten' ? <AttentionInfo student={student} /> : null}

          {activeTab === 'Onderdelen' ? (
            <View>
              <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.filterScroll}>
                {filters.map((item) => (
                  <Pressable
                    key={item}
                    onPress={() => {
                      tapFeedback();
                      LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
                      setFilter(item);
                    }}
                    style={({ pressed }) => [
                      styles.filterButton,
                      filter === item && styles.activeFilter,
                      pressed && styles.pressedPill,
                    ]}
                  >
                    <Text style={[styles.filterText, filter === item && styles.activeFilterText]}>
                      {item}
                    </Text>
                  </Pressable>
                ))}
              </ScrollView>
              <ProgressChecklist studentId={student.id} filter={filter} />
            </View>
          ) : null}
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

function StudentInfo({
  student,
  lessonCount,
  outstandingAmount,
  onUpdate,
  onDelete,
}: {
  student: Student;
  lessonCount: number;
  outstandingAmount: number;
  onUpdate: (studentId: string, updates: Partial<NewStudentInput>) => void;
  onDelete: () => void;
}) {
  return (
    <View style={styles.stack}>
      <View style={styles.infoCard}>
        <InfoRow label="Naam" value={student.name} />
        <InfoRow label="Adres" value={student.address} />
        <InfoRow label="Geboortedatum" value={student.birthDate} />
        <InfoRow label="Leeftijd" value={calculateAge(student.birthDate)} />
        <InfoRow label="Telefoon" value={student.phone} />
        <InfoRow label="E-mail" value={student.email} />
        <InfoRow label="Totaal lessen" value={String(lessonCount)} />
        <InfoRow label="Openstaand bedrag" value={`EUR ${outstandingAmount.toFixed(2)}`} danger={outstandingAmount > 0} />
      </View>
      <View style={styles.infoCard}>
        <EditableOptionGroup
          label="Status"
          options={studentStatuses}
          value={student.status}
          onChange={(status) => onUpdate(student.id, { status })}
        />
        <EditableOptionGroup
          label="Gezondheidsverklaring"
          options={healthOptions}
          value={student.healthDeclaration}
          onChange={(healthDeclaration) => onUpdate(student.id, { healthDeclaration })}
        />
        <EditableOptionGroup
          label="Theorie status"
          options={theoryOptions}
          value={student.theoryStatus}
          onChange={(theoryStatus) => onUpdate(student.id, { theoryStatus })}
        />
      </View>
      <Pressable
        onPress={onDelete}
        style={({ pressed }) => [styles.deleteButton, pressed && styles.pressedButton]}
      >
        <Text style={styles.deleteText}>Leerling verwijderen</Text>
      </Pressable>
    </View>
  );
}

function AttentionInfo({ student }: { student: Student }) {
  return (
    <View style={styles.infoCard}>
      <InfoRow label="Ophaaladres" value={student.pickupAddress} />
      <InfoRow label="Notitie" value={student.notes} />
    </View>
  );
}

function EditableOptionGroup<T extends string>({
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
    <View style={styles.optionSection}>
      <Text style={styles.infoLabel}>{label}</Text>
      <View style={styles.optionWrap}>
        {options.map((option) => (
          <Pressable
            key={option}
            onPress={() => {
              actionFeedback();
              onChange(option);
            }}
            style={({ pressed }) => [
              styles.optionButton,
              value === option && styles.activeOption,
              pressed && styles.pressedPill,
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

function InfoRow({ label, value, danger }: { label: string; value: string; danger?: boolean }) {
  return (
    <View style={styles.infoRow}>
      <Text style={styles.infoLabel}>{label}</Text>
      <Text style={[styles.infoValue, danger && styles.dangerValue]}>{value || '-'}</Text>
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
  title: {
    color: '#ffffff',
    fontSize: 24,
    fontWeight: '900',
    marginBottom: 18,
  },
  heroCard: {
    backgroundColor: '#111827',
    borderColor: '#1f2937',
    borderRadius: 24,
    borderWidth: 1,
    padding: 18,
    boxShadow: '0 12px 24px rgba(0, 0, 0, 0.16)',
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
  tabs: {
    backgroundColor: '#111827',
    borderColor: '#1f2937',
    borderRadius: 18,
    borderWidth: 1,
    flexDirection: 'row',
    gap: 6,
    marginVertical: 18,
    padding: 5,
    boxShadow: '0 8px 18px rgba(0, 0, 0, 0.12)',
  },
  tabButton: {
    alignItems: 'center',
    borderRadius: 13,
    flex: 1,
    paddingVertical: 10,
  },
  activeTab: {
    backgroundColor: '#2563eb',
  },
  pressedInline: {
    opacity: 0.72,
  },
  pressedPill: {
    opacity: 0.82,
    transform: [{ scale: 0.96 }],
  },
  tabText: {
    color: '#94a3b8',
    fontSize: 13,
    fontWeight: '900',
  },
  activeTabText: {
    color: '#ffffff',
  },
  infoCard: {
    backgroundColor: '#111827',
    borderColor: '#1f2937',
    borderRadius: 22,
    borderWidth: 1,
    padding: 16,
    boxShadow: '0 10px 22px rgba(0, 0, 0, 0.14)',
  },
  stack: {
    gap: 12,
  },
  infoRow: {
    borderBottomColor: '#1f2937',
    borderBottomWidth: 1,
    paddingVertical: 13,
  },
  infoLabel: {
    color: '#94a3b8',
    fontSize: 13,
    fontWeight: '700',
    marginBottom: 5,
  },
  infoValue: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '700',
    lineHeight: 22,
  },
  dangerValue: {
    color: '#ef4444',
  },
  filterScroll: {
    marginBottom: 12,
  },
  filterButton: {
    backgroundColor: '#111827',
    borderColor: '#1f2937',
    borderRadius: 999,
    borderWidth: 1,
    marginRight: 8,
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  activeFilter: {
    backgroundColor: '#2563eb',
    borderColor: '#2563eb',
  },
  filterText: {
    color: '#cbd5e1',
    fontSize: 13,
    fontWeight: '900',
  },
  activeFilterText: {
    color: '#ffffff',
  },
  optionSection: {
    borderBottomColor: '#1f2937',
    borderBottomWidth: 1,
    paddingVertical: 13,
  },
  optionWrap: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  optionButton: {
    backgroundColor: '#0f172a',
    borderColor: '#1f2937',
    borderRadius: 999,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 10,
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
  deleteButton: {
    alignItems: 'center',
    backgroundColor: '#7f1d1d',
    borderColor: '#b91c1c',
    borderRadius: 18,
    borderWidth: 1,
    paddingVertical: 15,
  },
  pressedButton: {
    opacity: 0.84,
    transform: [{ scale: 0.985 }],
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
