export type HealthDeclarationStatus =
  | 'Niet gestart'
  | 'Aangevraagd'
  | 'Goedgekeurd'
  | 'Extra beoordeling';

export type TheoryStatus = 'Niet gestart' | 'Bezig' | 'Gehaald' | 'Verlopen';

export type ProgressStatus = 'Slecht' | 'Matig' | 'Goed' | 'Beheerst';

export type StudentStatus = 'Actief' | 'Geslaagd';

export type LessonKind = 'lesson' | 'exam';

export type AppTheme = 'Donker' | 'Blauw';

export type Student = {
  id: string;
  name: string;
  address: string;
  birthDate: string;
  phone: string;
  email: string;
  status: StudentStatus;
  healthDeclaration: HealthDeclarationStatus;
  theoryStatus: TheoryStatus;
  notes: string;
  pickupAddress: string;
  createdAt: string;
};

export type Lesson = {
  id: string;
  studentId: string;
  kind: LessonKind;
  date: string;
  startTime: string;
  endTime: string;
  note: string;
  amount: number;
  paid: boolean;
  recurringSeriesId?: string;
  createdAt: string;
};

export type RecurringLesson = {
  id: string;
  studentId: string;
  startDate: string;
  startTime: string;
  endTime: string;
  amount: number;
  createdAt: string;
};

export type AppSettings = {
  theme: AppTheme;
  dayStartTime: string;
  dayEndTime: string;
  lessonMinutes: number;
  defaultLessonAmount: number;
};

export type InstructionPart = {
  id: number;
  title: string;
};

export type StudentProgress = {
  studentId: string;
  partId: number;
  treatedCount: number;
  status: ProgressStatus;
  note: string;
  updatedAt: string;
};

export type LessonTreatment = {
  lessonId: string;
  partId: number;
};

export type AppData = {
  students: Student[];
  lessons: Lesson[];
  recurringLessons: RecurringLesson[];
  progress: StudentProgress[];
  lessonTreatments: LessonTreatment[];
  settings: AppSettings;
};

export type NewStudentInput = Omit<Student, 'id' | 'createdAt'>;
