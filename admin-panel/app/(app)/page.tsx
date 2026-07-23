import {
  BookingsOverview,
  StatCards,
  StatusDonut,
  type StatCard,
} from "@/components/dash-charts";
import {
  CansSummary,
  PaymentSummary,
  QuickActions,
  RecentBookings,
  TopVillages,
} from "@/components/dash-panels";
import { Topbar } from "@/components/topbar";
import { getDashboardData, rupee } from "@/lib/dashboard-queries";
import { getProfile } from "@/lib/profile";

export const dynamic = "force-dynamic";

export default async function DashboardPage() {
  const [d, profile] = await Promise.all([getDashboardData(), getProfile()]);
  const spark = d.trend.map((t) => t.bookings);

  const cards: StatCard[] = [
    {
      key: "total",
      label: "Total Bookings",
      value: `${d.counts.total}`,
      sub: "this week",
      deltaPct: d.weekDelta,
      icon: "total",
      color: "#2f7cf6",
      tint: "#e7f0ff",
      spark,
    },
    {
      key: "confirmed",
      label: "Confirmed",
      value: `${d.counts.confirmed}`,
      sub: "dates blocked",
      icon: "confirmed",
      color: "#1aa971",
      tint: "#e5f7ef",
      spark,
    },
    {
      key: "pending",
      label: "Awaiting Confirmation",
      value: `${d.counts.pending}`,
      sub: "cash not received",
      icon: "pending",
      color: "#f0a013",
      tint: "#fff3dd",
      spark,
    },
    {
      key: "collected",
      label: "Advance Collected",
      value: rupee(d.money.advanceCollected),
      sub: "from confirmed",
      icon: "wallet",
      color: "#12b0c9",
      tint: "#e2f7fb",
      spark,
    },
    {
      key: "dues",
      label: "Pending Dues (COD)",
      value: rupee(d.money.pendingDues),
      sub: "balance on delivery",
      icon: "dues",
      color: "#ef4b6c",
      tint: "#fdeaee",
      spark,
    },
  ];

  return (
    <div className="space-y-5">
      <Topbar title="Dashboard" name={profile.name} avatarUrl={profile.avatarUrl} />

      {!d.ok ? (
        <div className="rounded-2xl border border-line bg-surface p-5 text-[13px] text-ink-muted shadow-soft">
          Could not load bookings — check the connection and that the database
          tables exist.
        </div>
      ) : null}

      <StatCards cards={cards} />

      <div className="grid gap-4 xl:grid-cols-12">
        <div className="space-y-4 xl:col-span-9">
          <div className="grid gap-4 lg:grid-cols-5">
            <Panel className="lg:col-span-3">
              <PanelHead title="Bookings Overview">
                <span className="rounded-lg border border-line px-2.5 py-1 text-[11.5px] font-semibold text-ink-muted">
                  Last 7 Days
                </span>
              </PanelHead>
              <div className="mb-1 flex items-center gap-4 text-[12px] text-ink-body">
                <Legend color="#2f7cf6" label="Bookings" />
                <Legend color="#1aa971" label="Confirmed" />
              </div>
              <BookingsOverview trend={d.trend} />
            </Panel>

            <Panel className="lg:col-span-2">
              <PanelHead title="Bookings by Status" />
              <StatusDonut data={d.statusData} />
            </Panel>
          </div>

          <div className="grid gap-4 lg:grid-cols-5">
            <div className="lg:col-span-2">
              <TopVillages items={d.villages} max={d.villageMax} />
            </div>
            <div className="lg:col-span-3">
              <CansSummary
                total={d.totalCans}
                confirmed={d.confirmedCans}
                pending={d.pendingCans}
                bookings={d.counts.total}
              />
            </div>
          </div>

          <QuickActions />
        </div>

        <div className="space-y-4 xl:col-span-3">
          <RecentBookings items={d.recent} />
          <PaymentSummary
            total={d.payment.total}
            online={d.payment.online}
            cash={d.payment.cash}
          />
        </div>
      </div>
    </div>
  );
}

function Panel({
  children,
  className = "",
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <div className={`rounded-2xl border border-line bg-surface p-5 shadow-soft ${className}`}>
      {children}
    </div>
  );
}

function PanelHead({ title, children }: { title: string; children?: React.ReactNode }) {
  return (
    <div className="mb-3 flex items-center justify-between">
      <h3 className="text-[15px] font-bold text-ink">{title}</h3>
      {children}
    </div>
  );
}

function Legend({ color, label }: { color: string; label: string }) {
  return (
    <span className="flex items-center gap-1.5">
      <span className="h-2.5 w-2.5 rounded-full" style={{ background: color }} />
      {label}
    </span>
  );
}
