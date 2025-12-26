import {
  addDays,
  addMonths,
  addYears,
  endOfMonth,
  endOfWeek,
  endOfYear,
  format,
  startOfDay,
  startOfMonth,
  startOfWeek,
  startOfYear,
} from 'date-fns';

/** Time buckets that mirror the macOS app */
export type TimePeriod = 'day' | 'week' | 'month' | 'year';

export interface Habit {
  id: string;
  name: string;
  color: string; // hex string, e.g. #007AFF
  completions: string[]; // ISO date strings (yyyy-MM-dd)
  createdAt: string; // ISO string
}

export type HabitSelection =
  | { type: 'all' }
  | { type: 'specific'; ids: Set<string> };

export interface HabitChartData {
  habit: Habit;
  completedDays: number;
  totalDays: number;
  completionRate: number;
}

export interface PieChartData {
  completedPercentage: number;
  notCompletedPercentage: number;
  completedDays: number;
  totalDays: number;
  selectedHabits: string[];
}

/** Date helpers */

export const DAY_FORMAT = 'yyyy-MM-dd';

export function toDayString(date: Date): string {
  return format(date, DAY_FORMAT);
}

export function isCompletedOn(habit: Habit, date: Date): boolean {
  const key = toDayString(date);
  return habit.completions.includes(key);
}

export function toggleCompletion(habit: Habit, date: Date): Habit {
  const key = toDayString(date);
  const completions = new Set(habit.completions);
  if (completions.has(key)) {
    completions.delete(key);
  } else {
    completions.add(key);
  }
  return { ...habit, completions: Array.from(completions) };
}

export interface DateRange {
  start: Date;
  end: Date;
}

export function getDateRange(period: TimePeriod, reference: Date = new Date()): DateRange {
  switch (period) {
    case 'day': {
      const start = startOfDay(reference);
      return { start, end: addDays(start, 1) };
    }
    case 'week': {
      const start = startOfWeek(reference, { weekStartsOn: 1 }); // Monday
      const end = endOfWeek(reference, { weekStartsOn: 1 });
      return { start, end: addDays(endOfWeek(reference, { weekStartsOn: 1 }), 1) };
    }
    case 'month': {
      const start = startOfMonth(reference);
      const end = addDays(endOfMonth(reference), 1);
      return { start, end };
    }
    case 'year': {
      const start = startOfYear(reference);
      const end = addDays(endOfYear(reference), 1);
      return { start, end };
    }
  }
}

export function formatPeriodLabel(period: TimePeriod, reference: Date): string {
  switch (period) {
    case 'day':
      return format(reference, 'LLL d, yyyy');
    case 'week': {
      const start = startOfWeek(reference, { weekStartsOn: 1 });
      const end = endOfWeek(reference, { weekStartsOn: 1 });
      return `${format(start, 'LLL d')} - ${format(end, 'LLL d')}`;
    }
    case 'month':
      return format(reference, 'LLLL yyyy');
    case 'year':
      return format(reference, 'yyyy');
  }
}

/** Aggregations */

export function countCompletionsInRange(habit: Habit, range: DateRange): number {
  let count = 0;
  let cursor = range.start;
  while (cursor < range.end) {
    if (isCompletedOn(habit, cursor)) {
      count += 1;
    }
    cursor = addDays(cursor, 1);
  }
  return count;
}

export function buildHabitChartData(
  habit: Habit,
  period: TimePeriod,
  reference: Date = new Date()
): HabitChartData {
  const range = getDateRange(period, reference);
  let totalDays = 0;
  let cursor = range.start;
  while (cursor < range.end) {
    totalDays += 1;
    cursor = addDays(cursor, 1);
  }
  const completedDays = countCompletionsInRange(habit, range);
  const completionRate = totalDays > 0 ? completedDays / totalDays : 0;
  return { habit, completedDays, totalDays, completionRate };
}

export function buildPieChartData(
  habits: Habit[],
  selection: HabitSelection,
  period: TimePeriod,
  reference: Date = new Date()
): PieChartData {
  const selected = selection.type === 'all' ? habits : habits.filter((h) => selection.ids.has(h.id));

  if (selected.length === 0) {
    return {
      completedPercentage: 0,
      notCompletedPercentage: 0,
      completedDays: 0,
      totalDays: 0,
      selectedHabits: [],
    };
  }

  const range = getDateRange(period, reference);
  let dayCount = 0;
  let cursor = range.start;
  while (cursor < range.end) {
    dayCount += 1;
    cursor = addDays(cursor, 1);
  }

  const totalPossible = dayCount * selected.length;
  let completed = 0;

  for (const habit of selected) {
    completed += countCompletionsInRange(habit, range);
  }

  const completionRate = totalPossible > 0 ? completed / totalPossible : 0;

  return {
    completedPercentage: completionRate * 100,
    notCompletedPercentage: (1 - completionRate) * 100,
    completedDays: completed,
    totalDays: totalPossible,
    selectedHabits: selected.map((h) => h.name),
  };
}

/** Navigation helpers for moving the reference date */
export function shiftReference(reference: Date, period: TimePeriod, delta: number): Date {
  switch (period) {
    case 'day':
      return addDays(reference, delta);
    case 'week':
      return addDays(reference, delta * 7);
    case 'month':
      return addMonths(reference, delta);
    case 'year':
      return addYears(reference, delta);
  }
}
