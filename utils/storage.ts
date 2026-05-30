import AsyncStorage from '@react-native-async-storage/async-storage';

import { AppData, AppSettings, Lesson, Student } from '@/types';
import {
  DEFAULT_DAY_END_TIME,
  DEFAULT_DAY_START_TIME,
  DEFAULT_LESSON_MINUTES,
} from '@/utils/timeSlots';

const STORAGE_KEY = 'rijschool-katronic:data:v1';

export const defaultSettings: AppSettings = {
  theme: 'Donker',
  dayStartTime: DEFAULT_DAY_START_TIME,
  dayEndTime: DEFAULT_DAY_END_TIME,
  lessonMinutes: DEFAULT_LESSON_MINUTES,
  defaultLessonAmount: 55,
};

export const emptyAppData: AppData = {
  students: [],
  lessons: [],
  recurringLessons: [],
  progress: [],
  lessonTreatments: [],
  settings: defaultSettings,
};

type LegacyStudent = Partial<Student> & {
  age?: string;
  cbrAuthorization?: boolean;
  focusPoints?: string;
  medicalNotes?: string;
  anxietyNotes?: string;
  languageNotes?: string;
  instructorNotes?: string;
};

type LegacyLesson = Partial<Lesson>;

const normalizeStudent = (student: LegacyStudent): Student => ({
  id: student.id ?? '',
  name: student.name ?? '',
  address: student.address ?? '',
  birthDate: student.birthDate ?? '',
  phone: student.phone ?? '',
  email: student.email ?? '',
  status: student.status ?? 'Actief',
  healthDeclaration: student.healthDeclaration ?? 'Niet gestart',
  theoryStatus: student.theoryStatus ?? 'Niet gestart',
  notes: student.notes ?? student.instructorNotes ?? '',
  pickupAddress: student.pickupAddress ?? '',
  createdAt: student.createdAt ?? new Date().toISOString(),
});

const normalizeLesson = (lesson: LegacyLesson): Lesson => ({
  id: lesson.id ?? '',
  studentId: lesson.studentId ?? '',
  kind: lesson.kind ?? 'lesson',
  date: lesson.date ?? '',
  startTime: lesson.startTime ?? '',
  endTime: lesson.endTime ?? '',
  note: lesson.note ?? '',
  amount: lesson.amount ?? defaultSettings.defaultLessonAmount,
  paid: lesson.paid ?? false,
  recurringSeriesId: lesson.recurringSeriesId,
  createdAt: lesson.createdAt ?? new Date().toISOString(),
});

const normalizeSettings = (settings?: Partial<AppSettings>): AppSettings => ({
  ...defaultSettings,
  ...settings,
});

export async function loadAppData(): Promise<AppData> {
  const raw = await AsyncStorage.getItem(STORAGE_KEY);
  if (!raw) {
    return emptyAppData;
  }

  try {
    const parsed = JSON.parse(raw) as Partial<AppData>;
    return {
      students: (parsed.students ?? []).map(normalizeStudent),
      lessons: (parsed.lessons ?? []).map(normalizeLesson),
      recurringLessons: parsed.recurringLessons ?? [],
      progress: parsed.progress ?? [],
      lessonTreatments: parsed.lessonTreatments ?? [],
      settings: normalizeSettings(parsed.settings),
    };
  } catch {
    return emptyAppData;
  }
}

export async function saveAppData(data: AppData) {
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(data));
}
