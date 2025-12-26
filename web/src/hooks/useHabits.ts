import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { supabase } from "../lib/supabaseClient";
import {
  Habit,
  HabitSelection,
  TimePeriod,
  buildPieChartData,
  buildHabitChartData,
  shiftReference,
  toggleCompletion,
  toDayString,
} from "../types";

const TABLE = "habits";

type Status = "idle" | "loading" | "error";

interface UseHabitsOptions {
  initialSelection?: HabitSelection;
  userId?: string | null;
}

interface UpsertHabitInput {
  id?: string;
  name: string;
  color?: string;
}

export function useHabits(options: UseHabitsOptions = {}) {
  const [habits, setHabits] = useState<Habit[]>([]);
  const [selection, setSelection] = useState<HabitSelection>(
    options.initialSelection ?? { type: "all" },
  );
  const [status, setStatus] = useState<Status>("idle");
  const [error, setError] = useState<string | null>(null);
  const userId = options.userId ?? null;

  // Chart controls
  const [period, setPeriod] = useState<TimePeriod>("week");
  const [referenceDate, setReferenceDate] = useState<Date>(new Date());

  const loadingRef = useRef(false);

  const loadHabits = useCallback(async () => {
    if (loadingRef.current) return;
    loadingRef.current = true;
    setStatus("loading");
    setError(null);

    if (!userId) {
      setStatus("idle");
      setError(null);
      loadingRef.current = false;
      return;
    }

    const { data, error: err } = await supabase
      .from(TABLE)
      .select()
      .eq("user_id", userId)
      .order("created_at");

    if (err) {
      setError(err.message);
      setStatus("error");
    } else if (data) {
      const mapped: Habit[] = data.map((row: any) => ({
        id: row.id,
        name: row.name,
        color: row.color ?? "#007AFF",
        completions: row.completions ?? [],
        createdAt: row.created_at,
      }));
      setHabits(mapped);
      setStatus("idle");
    }
    loadingRef.current = false;
  }, [userId]);

  const upsertHabit = useCallback(
    async ({ id, name, color = "#007AFF" }: UpsertHabitInput) => {
      if (!userId) {
        setError("No authenticated user. Please sign in.");
        setStatus("error");
        return;
      }

      const payload = {
        id,
        name,
        color,
        completions: [],
        user_id: userId,
        created_at: id ? undefined : new Date().toISOString(),
      };

      const { data, error: err } = await supabase
        .from(TABLE)
        .upsert(payload)
        .select()
        .single();
      if (err) throw err;

      setHabits((prev) => {
        const exists = prev.find((h) => h.id === data.id);
        if (exists) {
          return prev.map((h) =>
            h.id === data.id
              ? {
                  ...h,
                  name: data.name,
                  color: data.color ?? "#007AFF",
                  completions: data.completions ?? [],
                }
              : h,
          );
        }
        return [
          ...prev,
          {
            id: data.id,
            name: data.name,
            color: data.color ?? "#007AFF",
            completions: data.completions ?? [],
            createdAt: data.created_at,
          },
        ];
      });
    },
    [userId],
  );

  const deleteHabit = useCallback(
    async (id: string) => {
      if (!userId) {
        setError("No authenticated user. Please sign in.");
        setStatus("error");
        return;
      }
      const { error: err } = await supabase
        .from(TABLE)
        .delete()
        .eq("id", id)
        .eq("user_id", userId);
      if (err) throw err;
      setHabits((prev) => prev.filter((h) => h.id !== id));
      setSelection((sel) => {
        if (sel.type === "all") return sel;
        const ids = new Set(sel.ids);
        ids.delete(id);
        return ids.size === 0 ? { type: "all" } : { type: "specific", ids };
      });
    },
    [userId],
  );

  const toggleHabitCompletion = useCallback(
    async (habitId: string, date: Date = new Date()) => {
      if (!userId) {
        setError("No authenticated user. Please sign in.");
        setStatus("error");
        return;
      }
      const target = habits.find((h) => h.id === habitId);
      if (!target) return;
      const updated = toggleCompletion(target, date);
      setHabits((prev) => prev.map((h) => (h.id === habitId ? updated : h)));

      const { error: err } = await supabase
        .from(TABLE)
        .update({ completions: updated.completions })
        .eq("id", habitId)
        .eq("user_id", userId);

      if (err) {
        // revert on failure
        setHabits((prev) => prev.map((h) => (h.id === habitId ? target : h)));
        setError(err.message);
        setStatus("error");
      }
    },
    [habits, userId],
  );

  const selectAll = useCallback(() => setSelection({ type: "all" }), []);
  const toggleSelection = useCallback(
    (id: string) => {
      setSelection((prev) => {
        if (prev.type === "all") {
          const ids = new Set(habits.map((h) => h.id));
          ids.delete(id);
          return { type: "specific", ids };
        }
        const ids = new Set(prev.ids);
        if (ids.has(id)) {
          ids.delete(id);
          return ids.size === 0 ? { type: "all" } : { type: "specific", ids };
        }
        ids.add(id);
        return ids.size === habits.length
          ? { type: "all" }
          : { type: "specific", ids };
      });
    },
    [habits],
  );

  const selectOnly = useCallback((id: string) => {
    setSelection({ type: "specific", ids: new Set([id]) });
  }, []);

  const nextPeriod = useCallback(
    () => setReferenceDate((d) => shiftReference(d, period, 1)),
    [period],
  );
  const prevPeriod = useCallback(
    () => setReferenceDate((d) => shiftReference(d, period, -1)),
    [period],
  );
  const resetReference = useCallback(() => setReferenceDate(new Date()), []);

  useEffect(() => {
    // userId now provided by caller
  }, []);

  useEffect(() => {
    setHabits([]);
    setSelection(options.initialSelection ?? { type: "all" });
    setError(null);
    setStatus("idle");
    loadingRef.current = false;
  }, [userId, options.initialSelection]);

  useEffect(() => {
    void loadHabits();
  }, [loadHabits]);

  useEffect(() => {
    if (!userId) return;

    const channel = supabase
      .channel("habit-changes")
      .on(
        "postgres_changes",
        {
          event: "*",
          schema: "public",
          table: TABLE,
          filter: `user_id=eq.${userId}`,
        },
        (payload: any) => {
          const row = payload.new ?? payload.old;
          if (!row) return;

          if (payload.eventType === "DELETE") {
            setHabits((prev) => prev.filter((h) => h.id !== row.id));
            return;
          }

          const mapped: Habit = {
            id: row.id,
            name: row.name,
            color: row.color ?? "#007AFF",
            completions: row.completions ?? [],
            createdAt: row.created_at,
          };

          setHabits((prev) => {
            const exists = prev.find((h) => h.id === mapped.id);
            if (exists) {
              return prev.map((h) => (h.id === mapped.id ? mapped : h));
            }
            return [...prev, mapped];
          });
        },
      )
      .subscribe();

    return () => {
      void supabase.removeChannel(channel);
    };
  }, [userId]);

  const todayCompletionRate = useMemo(() => {
    if (habits.length === 0) return 0;
    const todayKey = toDayString(new Date());
    const completed = habits.filter((h) =>
      h.completions.includes(todayKey),
    ).length;
    return completed / habits.length;
  }, [habits]);

  const pieData = useMemo(
    () => buildPieChartData(habits, selection, period, referenceDate),
    [habits, selection, period, referenceDate],
  );

  const chartData = useMemo(
    () =>
      habits.map((h) => ({
        ...buildHabitChartData(h, period, referenceDate),
      })),
    [habits, period, referenceDate],
  );

  return {
    habits,
    selection,
    status,
    error,
    period,
    referenceDate,
    todayCompletionRate,
    pieData,
    chartData,
    setPeriod,
    setReferenceDate,
    nextPeriod,
    prevPeriod,
    resetReference,
    selectAll,
    toggleSelection,
    selectOnly,
    loadHabits,
    upsertHabit,
    deleteHabit,
    toggleHabitCompletion,
  };
}
