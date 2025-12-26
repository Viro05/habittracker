import React, { useEffect, useMemo, useState } from "react";
import ReactDOM from "react-dom/client";
import "./styles.css";
import { supabase } from "./lib/supabaseClient";
import { useHabits } from "./hooks/useHabits";
import { Habit, TimePeriod, formatPeriodLabel, toDayString } from "./types";

type ViewMode = "list" | "chart";

const PERIOD_LABELS: Record<TimePeriod, string> = {
  day: "Today",
  week: "Week",
  month: "Month",
  year: "Year",
};

function App() {
  const [view, setView] = useState<ViewMode>("list");
  const [showAdd, setShowAdd] = useState(false);
  const [newHabitName, setNewHabitName] = useState("");
  const [sessionEmail, setSessionEmail] = useState("");
  const [sessionError, setSessionError] = useState<string | null>(null);
  const [sessionStatus, setSessionStatus] = useState<"idle" | "loading">(
    "idle",
  );
  const [userId, setUserId] = useState<string | null>(null);

  useEffect(() => {
    let ignore = false;

    supabase.auth.getSession().then(({ data, error }) => {
      if (ignore) return;
      if (error) {
        setSessionError(error.message);
        return;
      }
      setUserId(data.session?.user?.id ?? null);
    });

    const { data: authListener } = supabase.auth.onAuthStateChange(
      (_event, nextSession) => {
        if (ignore) return;
        setUserId(nextSession?.user?.id ?? null);
      },
    );

    return () => {
      ignore = true;
      authListener?.subscription.unsubscribe();
    };
  }, []);

  const {
    habits,
    selection,
    status,
    period,
    referenceDate,
    todayCompletionRate,
    pieData,
    setPeriod,
    nextPeriod,
    prevPeriod,
    resetReference,
    selectAll,
    toggleSelection,
    selectOnly,
    upsertHabit,
    deleteHabit,
    toggleHabitCompletion,
    error,
  } = useHabits({ userId });

  const sortedHabits = useMemo(
    () => [...habits].sort((a, b) => a.createdAt.localeCompare(b.createdAt)),
    [habits],
  );

  const addHabit = async () => {
    const name = newHabitName.trim();
    if (!name) return;
    await upsertHabit({ name });
    setNewHabitName("");
    setShowAdd(false);
  };

  const handleLogin = async () => {
    const email = sessionEmail.trim();
    if (!email) return;
    setSessionError(null);
    setSessionStatus("loading");
    const { error: signInError } = await supabase.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: window.location.origin },
    });
    if (signInError) {
      setSessionError(signInError.message);
    } else {
      setSessionError(
        "Check your email for the magic link. Open it on any device; it will bring you back here.",
      );
    }
    setSessionStatus("idle");
  };

  const handleLogout = async () => {
    await supabase.auth.signOut();
    setUserId(null);
  };

  if (!userId) {
    return (
      <div className="app-shell">
        <div
          className="card"
          style={{ padding: 24, maxWidth: 480, margin: "0 auto" }}
        >
          <div className="heading-xl" style={{ marginBottom: 8 }}>
            Sign in
          </div>
          <div className="text-muted" style={{ marginBottom: 16 }}>
            Enter your email to get a magic link. Open it on any device; it will
            return you here and keep your habits synced across devices.
          </div>
          <div className="grid gap-md">
            <input
              type="email"
              placeholder="you@example.com"
              value={sessionEmail}
              onChange={(e) => setSessionEmail(e.target.value)}
            />
            <button
              className="btn btn-primary"
              onClick={handleLogin}
              disabled={!sessionEmail.trim() || sessionStatus === "loading"}
            >
              {sessionStatus === "loading" ? "Sending..." : "Send magic link"}
            </button>
            {sessionError && (
              <div className="text-muted" style={{ color: "#ff9d9d" }}>
                {sessionError}
              </div>
            )}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="app-shell">
      <header className="flex-between" style={{ gap: 12, marginBottom: 18 }}>
        <div>
          <div className="heading-xl">Habits</div>
          <div className="text-muted" style={{ marginTop: 6 }}>
            {status === "loading"
              ? "Syncing..."
              : `${sortedHabits.length} habit${sortedHabits.length === 1 ? "" : "s"}`}
          </div>
        </div>

        <div className="toolbar">
          <button
            className="btn"
            onClick={() => setView(view === "list" ? "chart" : "list")}
          >
            {view === "list" ? "📊 Chart" : "📃 List"}
          </button>
          <button className="btn btn-primary" onClick={() => setShowAdd(true)}>
            ➕ Add
          </button>
          <button className="btn" onClick={handleLogout}>
            Sign out
          </button>
        </div>
      </header>

      {error && (
        <div className="card" style={{ padding: 12, marginBottom: 12 }}>
          <div className="text-muted" style={{ color: "#ff9d9d" }}>
            {error}
          </div>
        </div>
      )}

      {sortedHabits.length > 0 && (
        <div className="card" style={{ padding: 18, marginBottom: 20 }}>
          <div className="flex-between">
            <div className="text-muted">Today's Progress</div>
            <div className="text-muted">
              {Math.round(todayCompletionRate * 100)}%
            </div>
          </div>
          <div className="progress-track" style={{ marginTop: 10 }}>
            <div
              className="progress-fill"
              style={{ width: `${Math.round(todayCompletionRate * 100)}%` }}
            />
          </div>
        </div>
      )}

      {view === "list" ? (
        <HabitList
          habits={sortedHabits}
          onToggle={(id) => toggleHabitCompletion(id)}
          onDelete={(id) => deleteHabit(id)}
          selection={selection}
          selectAll={selectAll}
          toggleSelection={toggleSelection}
        />
      ) : (
        <ChartView
          habits={sortedHabits}
          selection={selection}
          selectAll={selectAll}
          toggleSelection={toggleSelection}
          selectOnly={selectOnly}
          period={period}
          setPeriod={setPeriod}
          referenceDate={referenceDate}
          nextPeriod={nextPeriod}
          prevPeriod={prevPeriod}
          resetReference={resetReference}
          pieData={pieData}
        />
      )}

      {showAdd && (
        <Modal onClose={() => setShowAdd(false)} title="New Habit">
          <div className="grid gap-md" style={{ marginTop: 8 }}>
            <label className="text-muted-2" htmlFor="habit-name">
              Name
            </label>
            <input
              id="habit-name"
              placeholder="Drink Water"
              value={newHabitName}
              onChange={(e) => setNewHabitName(e.target.value)}
            />
            <div className="flex" style={{ gap: 10, marginTop: 6 }}>
              <button className="btn" onClick={() => setShowAdd(false)}>
                Cancel
              </button>
              <button
                className="btn btn-primary"
                onClick={addHabit}
                disabled={!newHabitName.trim()}
              >
                Add
              </button>
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
}

function HabitList({
  habits,
  selection,
  selectAll,
  toggleSelection,
  onToggle,
  onDelete,
}: {
  habits: Habit[];
  selection: { type: "all" } | { type: "specific"; ids: Set<string> };
  selectAll: () => void;
  toggleSelection: (id: string) => void;
  onToggle: (id: string) => void;
  onDelete: (id: string) => void;
}) {
  if (habits.length === 0) {
    return (
      <div className="card" style={{ padding: 32, textAlign: "center" }}>
        <div style={{ fontSize: 48, opacity: 0.4, marginBottom: 12 }}>✅</div>
        <div className="heading-lg" style={{ marginBottom: 6 }}>
          No habits yet
        </div>
        <div className="text-muted">Add your first habit to get started</div>
      </div>
    );
  }

  return (
    <div className="card" style={{ padding: 18 }}>
      <div
        className="flex"
        style={{ gap: 10, flexWrap: "wrap", marginBottom: 16 }}
      >
        <Chip active={selection.type === "all"} onClick={selectAll}>
          All Habits
        </Chip>
        {habits.map((h) => (
          <Chip
            key={h.id}
            active={selection.type === "all" ? true : selection.ids.has(h.id)}
            onClick={() => toggleSelection(h.id)}
          >
            {h.name}
          </Chip>
        ))}
      </div>

      <div className="list">
        {habits.map((habit) => {
          const doneToday = habit.completions.includes(toDayString(new Date()));
          return (
            <div key={habit.id} className="list-item">
              <button
                className={`checkbox-circle ${doneToday ? "checked" : ""}`}
                style={{
                  borderColor: habit.color,
                  background: doneToday ? habit.color : undefined,
                }}
                onClick={() => onToggle(habit.id)}
              >
                {doneToday ? "✓" : ""}
              </button>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600, opacity: doneToday ? 0.6 : 1 }}>
                  {habit.name}
                </div>
                <div className="text-muted-2" style={{ fontSize: 12 }}>
                  Created {new Date(habit.createdAt).toLocaleDateString()}
                </div>
              </div>
              <button
                className="btn btn-danger"
                onClick={() => onDelete(habit.id)}
              >
                Delete
              </button>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function ChartView({
  habits,
  selection,
  selectAll,
  toggleSelection,
  selectOnly,
  period,
  setPeriod,
  referenceDate,
  nextPeriod,
  prevPeriod,
  resetReference,
  pieData,
}: {
  habits: Habit[];
  selection: { type: "all" } | { type: "specific"; ids: Set<string> };
  selectAll: () => void;
  toggleSelection: (id: string) => void;
  selectOnly: (id: string) => void;
  period: TimePeriod;
  setPeriod: (p: TimePeriod) => void;
  referenceDate: Date;
  nextPeriod: () => void;
  prevPeriod: () => void;
  resetReference: () => void;
  pieData: {
    completedPercentage: number;
    notCompletedPercentage: number;
    completedDays: number;
    totalDays: number;
    selectedHabits: string[];
  };
}) {
  return (
    <div className="grid gap-lg">
      <div className="card" style={{ padding: 18 }}>
        <div className="flex-between" style={{ gap: 10, flexWrap: "wrap" }}>
          <div className="flex" style={{ gap: 10, flexWrap: "wrap" }}>
            {(Object.keys(PERIOD_LABELS) as TimePeriod[]).map((p) => (
              <Chip key={p} active={period === p} onClick={() => setPeriod(p)}>
                {PERIOD_LABELS[p]}
              </Chip>
            ))}
          </div>

          <div className="flex" style={{ gap: 8, alignItems: "center" }}>
            <button className="btn" onClick={prevPeriod}>
              ←
            </button>
            <div className="pill">
              {formatPeriodLabel(period, referenceDate)}
            </div>
            <button className="btn" onClick={nextPeriod}>
              →
            </button>
            <button className="btn" onClick={resetReference}>
              Current
            </button>
          </div>
        </div>
      </div>

      <div className="card" style={{ padding: 18 }}>
        <div
          className="flex"
          style={{ gap: 10, flexWrap: "wrap", marginBottom: 16 }}
        >
          <Chip active={selection.type === "all"} onClick={selectAll}>
            All Habits
          </Chip>
          {habits.map((h) => (
            <Chip
              key={h.id}
              active={selection.type === "all" ? true : selection.ids.has(h.id)}
              onClick={() => toggleSelection(h.id)}
              onDoubleClick={() => selectOnly(h.id)}
            >
              {h.name}
            </Chip>
          ))}
        </div>

        <div
          style={{ display: "grid", placeItems: "center", padding: "12px 0" }}
        >
          <PieChart percentage={pieData.completedPercentage} />
          {pieData.totalDays > 0 && (
            <div style={{ textAlign: "center", marginTop: 14 }}>
              <div className="heading-lg">
                {Math.round(pieData.completedPercentage)}% Complete
              </div>
              <div className="text-muted" style={{ marginTop: 6 }}>
                {pieData.completedDays} of {pieData.totalDays} check-ins
              </div>
              {pieData.selectedHabits.length > 0 && (
                <div className="text-muted-2" style={{ marginTop: 6 }}>
                  {pieData.selectedHabits.join(" · ")}
                </div>
              )}
            </div>
          )}
          {pieData.totalDays === 0 && (
            <div className="text-muted" style={{ marginTop: 10 }}>
              No data in this range
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function PieChart({ percentage }: { percentage: number }) {
  const radius = 80;
  const circumference = 2 * Math.PI * radius;
  const progress = Math.min(Math.max(percentage, 0), 100);
  const offset = circumference * (1 - progress / 100);

  return (
    <svg width="220" height="220" viewBox="0 0 220 220">
      <g transform="rotate(-90 110 110)">
        <circle
          cx="110"
          cy="110"
          r={radius}
          stroke="rgba(255,255,255,0.2)"
          strokeWidth="16"
          fill="none"
        />
        <circle
          cx="110"
          cy="110"
          r={radius}
          stroke="#ffffff"
          strokeWidth="16"
          strokeDasharray={circumference}
          strokeDashoffset={offset}
          strokeLinecap="round"
          fill="none"
        />
      </g>
      <text
        x="110"
        y="115"
        textAnchor="middle"
        fill="#ffffff"
        fontSize="42"
        fontWeight="200"
      >
        {Math.round(progress)}%
      </text>
    </svg>
  );
}

function Chip({
  active,
  onClick,
  onDoubleClick,
  children,
}: {
  active?: boolean;
  onClick?: () => void;
  onDoubleClick?: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      className={`chip ${active ? "active" : ""}`}
      onClick={onClick}
      onDoubleClick={onDoubleClick}
      type="button"
    >
      {children}
    </button>
  );
}

function Modal({
  title,
  onClose,
  children,
}: {
  title: string;
  onClose: () => void;
  children: React.ReactNode;
}) {
  return (
    <div className="modal-backdrop">
      <div className="modal">
        <div className="flex-between" style={{ marginBottom: 12 }}>
          <div className="heading-lg">{title}</div>
          <button className="btn" onClick={onClose}>
            ✕
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root") as HTMLElement).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
