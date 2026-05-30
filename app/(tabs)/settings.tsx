import { useMemo, useState } from 'react';
import {
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { useAppState } from '@/data/AppState';
import { AppTheme, NewStudentInput } from '@/types';
import { successFeedback, tapFeedback } from '@/utils/haptics';

const themes: AppTheme[] = ['Donker', 'Blauw'];

const exampleImportText = `Naam;Telefoon;Email;Adres;Geboortedatum;Ophaaladres;Notitie
Samira El Idrissi;06 1234 5801;samira@example.nl;Stationsweg 14, Almere;12-04-2004;Stationsweg 14, Almere;Rustig opbouwen
Daan Vermeer;06 1234 5802;daan@example.nl;Kerkstraat 8, Lelystad;03-09-2002;Kerkstraat 8, Lelystad;Snelweg extra oefenen`;

export default function SettingsScreen() {
  const {
    lessons,
    settings,
    students,
    getOutstandingAmount,
    importStudents,
    updateSettings,
  } = useAppState();
  const [dayStartTime, setDayStartTime] = useState(settings.dayStartTime);
  const [dayEndTime, setDayEndTime] = useState(settings.dayEndTime);
  const [defaultLessonAmount, setDefaultLessonAmount] = useState(
    String(settings.defaultLessonAmount),
  );
  const [importText, setImportText] = useState('');
  const [importMessage, setImportMessage] = useState('');

  const debtRows = useMemo(
    () =>
      students
        .map((student) => {
          const unpaidLessons = lessons
            .filter(
              (lesson) =>
                lesson.kind !== 'exam' && lesson.studentId === student.id && !lesson.paid,
            )
            .sort((a, b) => `${a.date} ${a.startTime}`.localeCompare(`${b.date} ${b.startTime}`));
          return {
            student,
            amount: getOutstandingAmount(student.id),
            unpaidLessons,
          };
        })
        .filter((row) => row.amount > 0),
    [getOutstandingAmount, lessons, students],
  );

  const saveScheduleSettings = () => {
    const parsedAmount = Number(defaultLessonAmount.replace(',', '.'));
    successFeedback();
    updateSettings({
      dayStartTime: dayStartTime.trim() || settings.dayStartTime,
      dayEndTime: dayEndTime.trim() || settings.dayEndTime,
      defaultLessonAmount: Number.isNaN(parsedAmount)
        ? settings.defaultLessonAmount
        : parsedAmount,
    });
  };

  const parseImportRows = (text: string): NewStudentInput[] => {
    const rows = text
      .split(/\r?\n/)
      .map((row) => row.trim())
      .filter(Boolean);
    const dataRows = rows[0]?.toLowerCase().includes('naam') ? rows.slice(1) : rows;

    return dataRows
      .map((row) => row.split(';').map((cell) => cell.trim()))
      .filter(([name]) => Boolean(name))
      .map(([name, phone = '', email = '', address = '', birthDate = '', pickupAddress = '', notes = '']) => ({
        name,
        phone,
        email,
        address,
        birthDate,
        pickupAddress,
        notes,
        status: 'Actief',
        healthDeclaration: 'Niet gestart',
        theoryStatus: 'Niet gestart',
      }));
  };

  const importPastedStudents = () => {
    const parsedStudents = parseImportRows(importText);
    if (parsedStudents.length === 0) {
      setImportMessage('Geen geldige leerlingen gevonden.');
      return;
    }

    const count = importStudents(parsedStudents);
    successFeedback();
    setImportText('');
    setImportMessage(`${count} leerlingen geïmporteerd.`);
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        style={styles.keyboard}
      >
        <ScrollView
          contentContainerStyle={styles.content}
          keyboardDismissMode="interactive"
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          <View style={styles.header}>
            <Text style={styles.title}>Instellingen</Text>
            <Text style={styles.subtitle}>Agenda, prijs en openstaande bedragen</Text>
          </View>

          <View style={styles.card}>
            <Text style={styles.sectionTitle}>Thema</Text>
            <View style={styles.optionRow}>
              {themes.map((theme) => (
                <Pressable
                  key={theme}
                  onPress={() => {
                    tapFeedback();
                    updateSettings({ theme });
                  }}
                  style={({ pressed }) => [
                    styles.optionButton,
                    settings.theme === theme && styles.activeOption,
                    pressed && styles.pressed,
                  ]}
                >
                  <Text
                    style={[
                      styles.optionText,
                      settings.theme === theme && styles.activeOptionText,
                    ]}
                  >
                    {theme}
                  </Text>
                </Pressable>
              ))}
            </View>
          </View>

          <View style={styles.card}>
            <Text style={styles.sectionTitle}>Lestijden</Text>
            <Text style={styles.hint}>
              Bestaande vaste lessen blijven staan. Als je eerder of later gaat werken, verschijnen
              er extra vrije plekken in de agenda.
            </Text>
            <Field label="Starttijd" value={dayStartTime} onChangeText={setDayStartTime} />
            <Field label="Eindtijd" value={dayEndTime} onChangeText={setDayEndTime} />
            <Field
              label="Standaard lesprijs"
              value={defaultLessonAmount}
              onChangeText={setDefaultLessonAmount}
              keyboardType="decimal-pad"
            />
            <Pressable
              onPress={saveScheduleSettings}
              style={({ pressed }) => [styles.saveButton, pressed && styles.pressed]}
            >
              <Text style={styles.saveText}>Instellingen bewaren</Text>
            </Pressable>
          </View>

          <View style={styles.card}>
            <Text style={styles.sectionTitle}>Openstaand</Text>
            <Text style={styles.totalAmount}>EUR {getOutstandingAmount().toFixed(2)}</Text>
            {debtRows.length === 0 ? (
              <Text style={styles.emptyText}>Geen openstaande lessen.</Text>
            ) : (
              debtRows.map((row) => (
                <View key={row.student.id} style={styles.debtBlock}>
                  <View style={styles.debtHeader}>
                    <Text style={styles.debtName}>{row.student.name}</Text>
                    <Text style={styles.debtAmount}>EUR {row.amount.toFixed(2)}</Text>
                  </View>
                  {row.unpaidLessons.map((lesson) => (
                    <Text key={lesson.id} style={styles.lessonLine}>
                      {lesson.date} · {lesson.startTime}-{lesson.endTime} · EUR{' '}
                      {lesson.amount.toFixed(2)}
                    </Text>
                  ))}
                </View>
              ))
            )}
          </View>

          <View style={styles.card}>
            <Text style={styles.sectionTitle}>Leerlingen importeren</Text>
            <Text style={styles.hint}>
              Plak per leerling één regel. Gebruik puntkomma&apos;s tussen de velden.
            </Text>
            <TextInput
              multiline
              value={importText}
              onChangeText={setImportText}
              placeholder={exampleImportText}
              placeholderTextColor="#64748b"
              style={[styles.input, styles.importInput]}
            />
            {importMessage ? <Text style={styles.importMessage}>{importMessage}</Text> : null}
            <Pressable
              onPress={importPastedStudents}
              style={({ pressed }) => [styles.saveButton, pressed && styles.pressed]}
            >
              <Text style={styles.saveText}>Leerlingen importeren</Text>
            </Pressable>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

function Field({
  label,
  value,
  onChangeText,
  keyboardType,
}: {
  label: string;
  value: string;
  onChangeText: (value: string) => void;
  keyboardType?: 'default' | 'decimal-pad';
}) {
  return (
    <View style={styles.field}>
      <Text style={styles.label}>{label}</Text>
      <TextInput
        value={value}
        onChangeText={onChangeText}
        keyboardType={keyboardType}
        placeholder={label}
        placeholderTextColor="#64748b"
        style={styles.input}
      />
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
  content: {
    gap: 14,
    padding: 18,
    paddingBottom: 42,
  },
  header: {
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
  card: {
    backgroundColor: '#111827',
    borderColor: '#1f2937',
    borderRadius: 22,
    borderWidth: 1,
    padding: 16,
    boxShadow: '0 10px 22px rgba(0, 0, 0, 0.14)',
  },
  sectionTitle: {
    color: '#ffffff',
    fontSize: 20,
    fontWeight: '900',
    marginBottom: 12,
  },
  hint: {
    color: '#94a3b8',
    fontSize: 14,
    lineHeight: 20,
    marginBottom: 14,
  },
  optionRow: {
    flexDirection: 'row',
    gap: 8,
  },
  optionButton: {
    alignItems: 'center',
    backgroundColor: '#0f172a',
    borderColor: '#1f2937',
    borderRadius: 999,
    borderWidth: 1,
    flex: 1,
    paddingVertical: 11,
  },
  activeOption: {
    backgroundColor: '#2563eb',
    borderColor: '#2563eb',
  },
  optionText: {
    color: '#cbd5e1',
    fontSize: 14,
    fontWeight: '900',
  },
  activeOptionText: {
    color: '#ffffff',
  },
  pressed: {
    opacity: 0.84,
    transform: [{ scale: 0.985 }],
  },
  field: {
    marginBottom: 12,
  },
  label: {
    color: '#cbd5e1',
    fontSize: 14,
    fontWeight: '800',
    marginBottom: 8,
  },
  input: {
    backgroundColor: '#0f172a',
    borderColor: '#1f2937',
    borderRadius: 16,
    borderWidth: 1,
    color: '#ffffff',
    fontSize: 16,
    paddingHorizontal: 14,
    paddingVertical: 13,
  },
  importInput: {
    minHeight: 170,
    textAlignVertical: 'top',
  },
  importMessage: {
    color: '#22c55e',
    fontSize: 14,
    fontWeight: '800',
    marginBottom: 12,
  },
  saveButton: {
    alignItems: 'center',
    backgroundColor: '#2563eb',
    borderRadius: 18,
    paddingVertical: 16,
  },
  saveText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '900',
  },
  totalAmount: {
    color: '#ffffff',
    fontSize: 34,
    fontWeight: '900',
    marginBottom: 12,
  },
  emptyText: {
    color: '#94a3b8',
    fontSize: 15,
  },
  debtBlock: {
    borderTopColor: '#1f2937',
    borderTopWidth: 1,
    paddingVertical: 12,
  },
  debtHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  debtName: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '900',
  },
  debtAmount: {
    color: '#ef4444',
    fontSize: 15,
    fontWeight: '900',
  },
  lessonLine: {
    color: '#cbd5e1',
    fontSize: 13,
    lineHeight: 20,
  },
});
