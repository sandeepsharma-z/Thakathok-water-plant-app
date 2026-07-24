/** Date-range presets shared by the top-bar filter and the dashboard query. */

export const RANGE_PRESETS = [
  { key: "today", label: "Today" },
  { key: "7d", label: "Last 7 Days" },
  { key: "30d", label: "Last 30 Days" },
  { key: "month", label: "This Month" },
  { key: "all", label: "All Time" },
] as const;

export type RangeKey = (typeof RANGE_PRESETS)[number]["key"];

export const DEFAULT_RANGE: RangeKey = "7d";

export function normalizeRange(v?: string): RangeKey {
  return RANGE_PRESETS.some((r) => r.key === v) ? (v as RangeKey) : DEFAULT_RANGE;
}

/** Inclusive start date for a preset (null = no lower bound / all time). */
export function rangeStart(key: RangeKey): Date | null {
  const now = new Date();
  const midnight = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  switch (key) {
    case "today":
      return midnight;
    case "30d": {
      const s = new Date(midnight);
      s.setDate(midnight.getDate() - 29);
      return s;
    }
    case "month":
      return new Date(now.getFullYear(), now.getMonth(), 1);
    case "all":
      return null;
    case "7d":
    default: {
      const s = new Date(midnight);
      s.setDate(midnight.getDate() - 6);
      return s;
    }
  }
}

function fmt(d: Date) {
  return d.toLocaleDateString("en-IN", {
    day: "numeric",
    month: "short",
    year: "numeric",
  });
}

/** Human label for the button, e.g. "19 Jul 2026 – 25 Jul 2026". */
export function rangeLabel(key: RangeKey): string {
  const today = new Date();
  if (key === "all") return "All Time";
  const start = rangeStart(key)!;
  if (key === "today") return fmt(today);
  return `${fmt(start)} – ${fmt(today)}`;
}
