import { createContext, PropsWithChildren, useContext, useEffect, useMemo, useState } from 'react';

import {
  AppSettings,
  AppData,
  Lesson,
  NewStudentInput,
  ProgressStatus,
  RecurringLesson,
  Student,
  StudentProgress,
} from '@/types';
import { createWeeklyDates } from '@/utils/timeSlots';
import { emptyAppData, loadAppData, saveAppData } from '@/utils/storage';

type AppStateContextValue = AppData & {
  loading: boolean;
  addStudent: (student: NewStudentInput) => string;
  importStudents: (students: NewStudentInput[]) => number;
  updateStudent: (studentId: string, updates: Partial<NewStudentInput>) => void;
  deleteStudent: (studentId: string) => void;
  addLesson: (
    lesson: Omit<Lesson, 'id' | 'createdAt' | 'note' | 'paid' | 'amount' | 'kind'> &
      Partial<Pick<Lesson, 'note' | 'paid' | 'amount' | 'kind' | 'recurringSeriesId'>>,
  ) => string;
  addWeeklyLesson: (lesson: Omit<RecurringLesson, 'id' | 'createdAt' | 'amount'> & { amount?: number }) => { firstLessonId?: string; createdCount: number };
  updateLesson: (lessonId: string, updates: Partial<Pick<Lesson, 'note' | 'amount'>>) => void;
  deleteLesson: (lessonId: string) => void;
  toggleLessonPaid: (lessonId: string) => void;
  updateSettings: (updates: Partial<AppSettings>) => void;
  updateProgressStatus: (studentId: string, partId: number, updates: { status?: ProgressStatus; note?: string }) => void;
  toggleLessonTreatment: (lessonId: string, studentId: string, partId: number) => void;
  getStudentProgress: (studentId: string, partId: number) => StudentProgress;
  getOutstandingAmount: (studentId?: string) => number;
};

const AppStateContext = createContext<AppStateContextValue | null>(null);

const now = () => new Date().toISOString();

const createId = (prefix: string) => `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;

const createEmptyProgress = (studentId: string, partId: number): StudentProgress => ({
  studentId,
  partId,
  treatedCount: 0,
  status: 'Matig',
  note: '',
  updatedAt: now(),
});

const lessonsOverlap = (
  a: Pick<Lesson, 'date' | 'startTime' | 'endTime'>,
  b: Pick<Lesson, 'date' | 'startTime' | 'endTime'>,
) => a.date === b.date && a.startTime < b.endTime && a.endTime > b.startTime;

export function AppStateProvider({ children }: PropsWithChildren) {
  const [data, setData] = useState<AppData>(emptyAppData);
  const [loading, setLoading] = useState(true);
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    loadAppData().then((savedData) => {
      setData(savedData);
      setLoading(false);
      setHydrated(true);
    });
  }, []);

  useEffect(() => {
    if (hydrated) {
      saveAppData(data);
    }
  }, [data, hydrated]);

  const value = useMemo<AppStateContextValue>(() => {
    const ensureProgress = (studentId: string, partId: number, progressList: StudentProgress[]) =>
      progressList.find((item) => item.studentId === studentId && item.partId === partId) ??
      createEmptyProgress(studentId, partId);

    return {
      ...data,
      loading,
      addStudent: (studentInput) => {
        const id = createId('student');
        const student: Student = {
          ...studentInput,
          id,
          createdAt: now(),
        };
        setData((current) => ({
          ...current,
          students: [student, ...current.students],
        }));
        return id;
      },
      importStudents: (studentInputs) => {
        const importedStudents = studentInputs.map((studentInput) => ({
          ...studentInput,
          id: createId('student'),
          createdAt: now(),
        }));
        setData((current) => ({
          ...current,
          students: [...importedStudents, ...current.students],
        }));
        return importedStudents.length;
      },
      updateStudent: (studentId, updates) => {
        setData((current) => ({
          ...current,
          students: current.students.map((student) =>
            student.id === studentId ? { ...student, ...updates } : student,
          ),
        }));
      },
      deleteStudent: (studentId) => {
        setData((current) => {
          const lessonIds = current.lessons
            .filter((lesson) => lesson.studentId === studentId)
            .map((lesson) => lesson.id);
          return {
            ...current,
            students: current.students.filter((student) => student.id !== studentId),
            lessons: current.lessons.filter((lesson) => lesson.studentId !== studentId),
            recurringLessons: current.recurringLessons.filter(
              (lesson) => lesson.studentId !== studentId,
            ),
            progress: current.progress.filter((item) => item.studentId !== studentId),
            lessonTreatments: current.lessonTreatments.filter(
              (item) => !lessonIds.includes(item.lessonId),
            ),
          };
        });
      },
      addLesson: (lessonInput) => {
        const id = createId('lesson');
        const lesson: Lesson = {
          id,
          studentId: lessonInput.studentId,
          kind: lessonInput.kind ?? 'lesson',
          date: lessonInput.date,
          startTime: lessonInput.startTime,
          endTime: lessonInput.endTime,
          note: lessonInput.note ?? '',
          amount: lessonInput.amount ?? data.settings.defaultLessonAmount,
          paid: lessonInput.paid ?? false,
          recurringSeriesId: lessonInput.recurringSeriesId,
          createdAt: now(),
        };
        setData((current) => ({
          ...current,
          lessons: [...current.lessons, lesson],
        }));
        return id;
      },
      addWeeklyLesson: (lessonInput) => {
        const seriesId = createId('weekly');
        const amount = lessonInput.amount ?? data.settings.defaultLessonAmount;
        const series: RecurringLesson = {
          id: seriesId,
          studentId: lessonInput.studentId,
          startDate: lessonInput.startDate,
          startTime: lessonInput.startTime,
          endTime: lessonInput.endTime,
          amount,
          createdAt: now(),
        };
        let firstLessonId: string | undefined;
        let createdCount = 0;
        setData((current) => {
          const nextLessons = [...current.lessons];
          createWeeklyDates(lessonInput.startDate, 24).forEach((date) => {
            const candidate = {
              date,
              startTime: lessonInput.startTime,
              endTime: lessonInput.endTime,
            };
            const hasConflict = nextLessons.some((lesson) => lessonsOverlap(candidate, lesson));
            if (hasConflict) {
              return;
            }
            const id = createId('lesson');
            firstLessonId ??= id;
            createdCount += 1;
            nextLessons.push({
              id,
              studentId: lessonInput.studentId,
              kind: 'lesson',
              date,
              startTime: lessonInput.startTime,
              endTime: lessonInput.endTime,
              note: '',
              amount,
              paid: false,
              recurringSeriesId: seriesId,
              createdAt: now(),
            });
          });
          return {
            ...current,
            lessons: nextLessons,
            recurringLessons: [...current.recurringLessons, series],
          };
        });
        return { firstLessonId, createdCount };
      },
      updateLesson: (lessonId, updates) => {
        setData((current) => ({
          ...current,
          lessons: current.lessons.map((lesson) =>
            lesson.id === lessonId ? { ...lesson, ...updates } : lesson,
          ),
        }));
      },
      deleteLesson: (lessonId) => {
        setData((current) => ({
          ...current,
          lessons: current.lessons.filter((lesson) => lesson.id !== lessonId),
          lessonTreatments: current.lessonTreatments.filter((item) => item.lessonId !== lessonId),
        }));
      },
      toggleLessonPaid: (lessonId) => {
        setData((current) => ({
          ...current,
          lessons: current.lessons.map((lesson) =>
            lesson.id === lessonId ? { ...lesson, paid: !lesson.paid } : lesson,
          ),
        }));
      },
      updateSettings: (updates) => {
        setData((current) => ({
          ...current,
          settings: {
            ...current.settings,
            ...updates,
          },
        }));
      },
      updateProgressStatus: (studentId, partId, updates) => {
        setData((current) => {
          const existing = ensureProgress(studentId, partId, current.progress);
          const nextProgress = {
            ...existing,
            ...updates,
            updatedAt: now(),
          };
          const hasExisting = current.progress.some(
            (item) => item.studentId === studentId && item.partId === partId,
          );
          return {
            ...current,
            progress: hasExisting
              ? current.progress.map((item) =>
                  item.studentId === studentId && item.partId === partId ? nextProgress : item,
                )
              : [...current.progress, nextProgress],
          };
        });
      },
      toggleLessonTreatment: (lessonId, studentId, partId) => {
        setData((current) => {
          const exists = current.lessonTreatments.some(
            (item) => item.lessonId === lessonId && item.partId === partId,
          );
          const existingProgress = ensureProgress(studentId, partId, current.progress);
          const nextProgress = {
            ...existingProgress,
            treatedCount: exists
              ? Math.max(0, existingProgress.treatedCount - 1)
              : existingProgress.treatedCount + 1,
            updatedAt: now(),
          };
          const hasProgress = current.progress.some(
            (item) => item.studentId === studentId && item.partId === partId,
          );
          return {
            ...current,
            progress: hasProgress
              ? current.progress.map((item) =>
                  item.studentId === studentId && item.partId === partId ? nextProgress : item,
                )
              : [...current.progress, nextProgress],
            lessonTreatments: exists
              ? current.lessonTreatments.filter(
                  (item) => !(item.lessonId === lessonId && item.partId === partId),
                )
              : [...current.lessonTreatments, { lessonId, partId }],
          };
        });
      },
      getStudentProgress: (studentId, partId) => ensureProgress(studentId, partId, data.progress),
      getOutstandingAmount: (studentId) =>
        data.lessons
          .filter(
            (lesson) =>
              lesson.kind !== 'exam' && !lesson.paid && (!studentId || lesson.studentId === studentId),
          )
          .reduce((total, lesson) => total + lesson.amount, 0),
    };
  }, [data, loading]);

  return <AppStateContext.Provider value={value}>{children}</AppStateContext.Provider>;
}

export function useAppState() {
  const context = useContext(AppStateContext);
  if (!context) {
    throw new Error('useAppState must be used inside AppStateProvider');
  }
  return context;
}
