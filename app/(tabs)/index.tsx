import { useCallback, useMemo, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Animated,
  LayoutAnimation,
  PanResponder,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  useWindowDimensions,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { AgendaSlot } from '@/components/AgendaSlot';
import { LessonPage } from '@/components/LessonPage';
import { MonthPickerModal } from '@/components/MonthPickerModal';
import { ScreenTransition } from '@/components/ScreenTransition';
import { BookingMode, StudentPickerModal } from '@/components/StudentPickerModal';
import { WeekStrip } from '@/components/WeekStrip';
import { useAppState } from '@/data/AppState';
import {
  addDays,
  createTimeSlots,
  dutchMonths,
  formatDateKey,
  formatDutchDateTitle,
  getWeekDays,
  getNextSlotEndTime,
  getSlotSpan,
  timeToMinutes,
} from '@/utils/timeSlots';
import { tapFeedback } from '@/utils/haptics';

type PendingSlot = {
  startTime: string;
  endTime: string;
} | null;

export default function AgendaScreen() {
  const { loading, lessons, settings, students, addLesson, addWeeklyLesson } = useAppState();
  const { width } = useWindowDimensions();
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [monthPickerVisible, setMonthPickerVisible] = useState(false);
  const [pendingSlot, setPendingSlot] = useState<PendingSlot>(null);
  const [selectedLessonId, setSelectedLessonId] = useState<string | null>(null);
  const translateX = useMemo(() => new Animated.Value(0), []);
  const weekTranslateX = useMemo(() => new Animated.Value(0), []);
  const pageWidth = Math.max(1, width - 36);

  const dateKey = formatDateKey(selectedDate);
  const getDaySlots = useCallback((date: Date) => {
    const targetDateKey = formatDateKey(date);
    const configuredSlots = createTimeSlots({
      startTime: settings.dayStartTime,
      endTime: settings.dayEndTime,
      lessonMinutes: settings.lessonMinutes,
    });
    const missingLessonSlots = lessons
      .filter((lesson) => lesson.date === targetDateKey)
      .filter((lesson) => !configuredSlots.some((slot) => slot.startTime === lesson.startTime))
      .map((lesson) => ({ startTime: lesson.startTime, endTime: lesson.endTime }));

    return [...configuredSlots, ...missingLessonSlots].sort(
      (a, b) => timeToMinutes(a.startTime) - timeToMinutes(b.startTime),
    );
  }, [lessons, settings.dayEndTime, settings.dayStartTime, settings.lessonMinutes]);
  const getWeekKey = (date: Date) => formatDateKey(getWeekDays(date)[0]);
  const animateToDate = useCallback((direction: -1 | 1) => {
    tapFeedback();
    const nextDate = addDays(selectedDate, direction);
    const weekChanges = getWeekKey(nextDate) !== getWeekKey(selectedDate);
    if (weekChanges) {
      Animated.timing(weekTranslateX, {
        toValue: -direction * pageWidth,
        duration: 180,
        useNativeDriver: true,
      }).start();
    }
    Animated.timing(translateX, {
      toValue: -direction * pageWidth,
      duration: 180,
      useNativeDriver: true,
    }).start(() => {
      LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
      setSelectedDate(nextDate);
      translateX.setValue(0);
      if (weekChanges) {
        weekTranslateX.setValue(direction * pageWidth);
      }
      if (weekChanges) {
        Animated.spring(weekTranslateX, {
          toValue: 0,
          damping: 18,
          stiffness: 180,
          mass: 0.75,
          useNativeDriver: true,
        }).start();
      }
    });
  }, [pageWidth, selectedDate, translateX, weekTranslateX]);

  const panResponder = useMemo(
    () =>
      PanResponder.create({
        onMoveShouldSetPanResponder: (_, gesture) =>
          Math.abs(gesture.dx) > 28 && Math.abs(gesture.dy) < 22,
        onPanResponderMove: (_, gesture) => {
          translateX.setValue(
            Math.max(-pageWidth * 0.92, Math.min(pageWidth * 0.92, gesture.dx)),
          );
        },
        onPanResponderRelease: (_, gesture) => {
          if (gesture.dx < -70) {
            animateToDate(1);
            return;
          }
          if (gesture.dx > 70) {
            animateToDate(-1);
            return;
          }
          Animated.spring(translateX, {
            toValue: 0,
            damping: 18,
            stiffness: 180,
            useNativeDriver: true,
          }).start();
        },
        onPanResponderTerminate: () => {
          Animated.spring(translateX, {
            toValue: 0,
            damping: 18,
            stiffness: 180,
            useNativeDriver: true,
          }).start();
        },
      }),
    [animateToDate, pageWidth, translateX],
  );

  const renderDay = (date: Date, interactive: boolean) => {
    const targetDateKey = formatDateKey(date);
    const targetDayLessons = lessons.filter((lesson) => lesson.date === targetDateKey);
    const targetDaySlots = getDaySlots(date);
    const targetExamLessons = targetDayLessons.filter((lesson) => lesson.kind === 'exam');

    return (
      <View style={[styles.dayPage, { width: pageWidth }]} key={targetDateKey}>
        <View style={styles.dayHeader}>
          <Text style={styles.dayTitle}>{formatDutchDateTitle(date)}</Text>
        </View>
        {targetExamLessons.length > 0 ? (
          <View style={styles.examBanner}>
            <Text style={styles.examBannerTitle}>Examen vandaag</Text>
            {targetExamLessons.map((lesson) => {
              const student = students.find((item) => item.id === lesson.studentId);
              return (
                <Text key={lesson.id} style={styles.examBannerText}>
                  {lesson.startTime} - {student?.name ?? 'Leerling'}
                </Text>
              );
            })}
          </View>
        ) : null}

        {loading ? (
          <ActivityIndicator color="#2563eb" style={styles.loader} />
        ) : (
          <View style={styles.slots}>
            {targetDaySlots.map((slot) => {
              const coveredByEarlierLesson = targetDayLessons.some(
                (item) =>
                  timeToMinutes(item.startTime) < timeToMinutes(slot.startTime) &&
                  timeToMinutes(item.endTime) > timeToMinutes(slot.startTime),
              );
              if (coveredByEarlierLesson) {
                return null;
              }
              const lesson = targetDayLessons.find((item) => item.startTime === slot.startTime);
              const student = students.find((item) => item.id === lesson?.studentId);
              const span = lesson
                ? getSlotSpan(lesson.startTime, lesson.endTime, settings.lessonMinutes)
                : 1;

              return (
                <AgendaSlot
                  key={slot.startTime}
                  startTime={slot.startTime}
                  endTime={slot.endTime}
                  lesson={lesson}
                  student={student}
                  span={span}
                    onPress={() => {
                      if (!interactive) {
                        return;
                      }
                      if (lesson) {
                        setTimeout(() => setSelectedLessonId(lesson.id), 70);
                      } else {
                        setPendingSlot(slot);
                      }
                  }}
                  onLongPress={() => {
                    if (!interactive || lesson) {
                      return;
                    }
                    const blockEndTime = getNextSlotEndTime(slot.startTime, targetDaySlots);
                    const hasConflict = targetDayLessons.some(
                      (item) =>
                        timeToMinutes(item.startTime) < timeToMinutes(blockEndTime) &&
                        timeToMinutes(item.endTime) > timeToMinutes(slot.startTime),
                    );
                    setPendingSlot({
                      startTime: slot.startTime,
                      endTime: hasConflict ? slot.endTime : blockEndTime,
                    });
                  }}
                />
              );
            })}
          </View>
        )}
      </View>
    );
  };

  if (selectedLessonId) {
    return (
      <ScreenTransition>
        <LessonPage lessonId={selectedLessonId} onBack={() => setSelectedLessonId(null)} />
      </ScreenTransition>
    );
  }

  return (
    <SafeAreaView style={styles.safeArea} {...panResponder.panHandlers}>
      <View style={styles.header}>
        <Pressable
          onPress={() => {
            tapFeedback();
            setMonthPickerVisible(true);
          }}
          style={({ pressed }) => [styles.monthPill, pressed && styles.pressedPill]}
        >
          <Text style={styles.monthText}>{dutchMonths[selectedDate.getMonth()]}</Text>
        </Pressable>
        <Pressable
          onPress={() => {
            tapFeedback();
            LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
            setSelectedDate(new Date());
          }}
          style={({ pressed }) => [styles.todayButton, pressed && styles.pressedPill]}
        >
          <Text style={styles.todayText}>Vandaag</Text>
        </Pressable>
      </View>

      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        <Animated.View style={{ transform: [{ translateX: weekTranslateX }] }}>
          <WeekStrip selectedDate={selectedDate} onSelectDate={setSelectedDate} />
        </Animated.View>
        <View style={[styles.swipeViewport, { width: pageWidth }]}>
          <Animated.View
            style={[
              styles.swipeRow,
              {
                width: pageWidth * 3,
                transform: [{ translateX: Animated.add(translateX, -pageWidth) }],
              },
            ]}
          >
            {renderDay(addDays(selectedDate, -1), false)}
            {renderDay(selectedDate, true)}
            {renderDay(addDays(selectedDate, 1), false)}
          </Animated.View>
        </View>
      </ScrollView>

      <MonthPickerModal
        visible={monthPickerVisible}
        selectedDate={selectedDate}
        onClose={() => setMonthPickerVisible(false)}
        onSelect={(date) => setSelectedDate(date)}
      />

      <StudentPickerModal
        visible={Boolean(pendingSlot)}
        students={students}
        slotLabel={pendingSlot ? `${dateKey} om ${pendingSlot.startTime}` : ''}
        onClose={() => setPendingSlot(null)}
        onSelectStudent={(studentId, mode: BookingMode) => {
          if (!pendingSlot) {
            return;
          }
          if (mode === 'weekly') {
            const result = addWeeklyLesson({
              studentId,
              startDate: dateKey,
              startTime: pendingSlot.startTime,
              endTime: pendingSlot.endTime,
            });
            setPendingSlot(null);
            Alert.alert(
              'Wekelijkse lessen ingepland',
              `${result.createdCount} lessen aangemaakt. Weken met een conflict zijn overgeslagen.`,
            );
            return;
          }
          addLesson({
            studentId,
            kind: mode === 'exam' ? 'exam' : 'lesson',
            date: dateKey,
            startTime: pendingSlot.startTime,
            endTime: pendingSlot.endTime,
            amount: mode === 'exam' ? 0 : settings.defaultLessonAmount,
            paid: mode === 'exam',
          });
          setPendingSlot(null);
        }}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    backgroundColor: '#080b10',
    flex: 1,
  },
  header: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: 18,
    paddingTop: 8,
  },
  monthPill: {
    backgroundColor: '#111827',
    borderColor: '#1f2937',
    borderRadius: 999,
    borderWidth: 1,
    paddingHorizontal: 18,
    paddingVertical: 10,
  },
  pressedPill: {
    opacity: 0.82,
    transform: [{ scale: 0.96 }],
  },
  monthText: {
    color: '#ffffff',
    fontSize: 17,
    fontWeight: '900',
    textTransform: 'capitalize',
  },
  todayButton: {
    backgroundColor: '#2563eb',
    borderRadius: 999,
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
  todayText: {
    color: '#ffffff',
    fontSize: 14,
    fontWeight: '900',
  },
  content: {
    padding: 18,
    paddingBottom: 40,
  },
  swipeViewport: {
    overflow: 'hidden',
  },
  swipeRow: {
    alignItems: 'flex-start',
    flexDirection: 'row',
  },
  dayPage: {
    flexShrink: 0,
  },
  dayTitle: {
    color: '#ffffff',
    fontSize: 24,
    fontWeight: '900',
    textTransform: 'capitalize',
  },
  dayHeader: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 14,
    marginTop: 16,
  },
  examBanner: {
    backgroundColor: '#2a1115',
    borderColor: '#f97316',
    borderRadius: 18,
    borderWidth: 1,
    marginBottom: 14,
    padding: 14,
  },
  examBannerTitle: {
    color: '#fed7aa',
    fontSize: 15,
    fontWeight: '900',
    marginBottom: 6,
  },
  examBannerText: {
    color: '#ffffff',
    fontSize: 14,
    fontWeight: '800',
  },
  loader: {
    marginTop: 50,
  },
  slots: {
    paddingBottom: 12,
  },
});
