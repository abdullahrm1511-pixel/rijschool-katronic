export type TimeSlot = {
  startTime: string;
  endTime: string;
};

export const DEFAULT_DAY_START_TIME = '08:20';
export const DEFAULT_DAY_END_TIME = '18:00';
export const DEFAULT_LESSON_MINUTES = 50;

const toTime = (minutes: number) => {
  const hours = Math.floor(minutes / 60);
  const mins = minutes % 60;
  return `${String(hours).padStart(2, '0')}:${String(mins).padStart(2, '0')}`;
};

export const timeToMinutes = (time: string) => {
  const [hours, minutes] = time.split(':').map(Number);
  return hours * 60 + minutes;
};

export const minutesToTime = toTime;

export const createTimeSlots = ({
  startTime = DEFAULT_DAY_START_TIME,
  endTime = DEFAULT_DAY_END_TIME,
  lessonMinutes = DEFAULT_LESSON_MINUTES,
}: {
  startTime?: string;
  endTime?: string;
  lessonMinutes?: number;
}) => {
  const startMinutes = timeToMinutes(startTime);
  const endMinutes = timeToMinutes(endTime);
  const safeLessonMinutes = Math.max(15, lessonMinutes);
  if (!Number.isFinite(startMinutes) || !Number.isFinite(endMinutes) || endMinutes <= startMinutes) {
    return [];
  }

  return Array.from(
    { length: Math.floor((endMinutes - startMinutes) / safeLessonMinutes) },
    (_, index) => {
      const start = startMinutes + index * safeLessonMinutes;
      return {
        startTime: toTime(start),
        endTime: toTime(start + safeLessonMinutes),
      };
    },
  );
};

export const timeSlots: TimeSlot[] = createTimeSlots({});

export const getNextSlotEndTime = (startTime: string, slots: TimeSlot[] = timeSlots) => {
  const index = slots.findIndex((slot) => slot.startTime === startTime);
  return slots[index + 1]?.endTime ?? slots[index]?.endTime ?? startTime;
};

export const getSlotSpan = (
  startTime: string,
  endTime: string,
  lessonMinutes = DEFAULT_LESSON_MINUTES,
) => {
  const minutes = Math.max(lessonMinutes, timeToMinutes(endTime) - timeToMinutes(startTime));
  return Math.max(1, Math.round(minutes / lessonMinutes));
};

export const createWeeklyDates = (startDate: string, weeks: number) => {
  const date = new Date(startDate);
  return Array.from({ length: weeks }, (_, index) => {
    const next = new Date(date);
    next.setDate(date.getDate() + index * 7);
    return formatDateKey(next);
  });
};

export const formatDateKey = (date: Date) => {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

export const addDays = (date: Date, amount: number) => {
  const next = new Date(date);
  next.setDate(next.getDate() + amount);
  return next;
};

export const sameDay = (a: Date, b: Date) => formatDateKey(a) === formatDateKey(b);

export const getWeekDays = (date: Date) => {
  const day = date.getDay();
  const mondayOffset = day === 0 ? -6 : 1 - day;
  const monday = addDays(date, mondayOffset);
  return Array.from({ length: 7 }, (_, index) => addDays(monday, index));
};

export const dutchMonths = [
  'januari',
  'februari',
  'maart',
  'april',
  'mei',
  'juni',
  'juli',
  'augustus',
  'september',
  'oktober',
  'november',
  'december',
];

export const dutchWeekDays = [
  'zondag',
  'maandag',
  'dinsdag',
  'woensdag',
  'donderdag',
  'vrijdag',
  'zaterdag',
];

export const formatDutchDateTitle = (date: Date) =>
  `${dutchWeekDays[date.getDay()]} ${date.getDate()} ${dutchMonths[date.getMonth()]}`;
