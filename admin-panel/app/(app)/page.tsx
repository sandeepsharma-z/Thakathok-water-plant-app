import {
  OrdersOverview,
  OrdersStatusDonut,
  StatCards,
} from "@/components/dash-charts";
import {
  CansSummary,
  PaymentSummary,
  QuickActions,
  RecentOrders,
  TopBranches,
} from "@/components/dash-panels";
import { Topbar } from "@/components/topbar";

export const dynamic = "force-dynamic";

const NAME = "Sandeep Sharma";

export default function DashboardPage() {
  return (
    <div className="space-y-5">
      <Topbar title="Dashboard" name={NAME} />

      {/* 5 stat cards */}
      <StatCards />

      {/* main bento */}
      <div className="grid gap-4 xl:grid-cols-12">
        {/* left */}
        <div className="space-y-4 xl:col-span-9">
          <div className="grid gap-4 lg:grid-cols-5">
            <Panel className="lg:col-span-3">
              <PanelHead title="Orders Overview">
                <select className="rounded-lg border border-line px-2.5 py-1 text-[11.5px] font-semibold text-ink-muted outline-none">
                  <option>Last 7 Days</option>
                </select>
              </PanelHead>
              <div className="mb-1 flex items-center gap-4 text-[12px] text-ink-body">
                <Legend color="#2f7cf6" label="Orders" />
                <Legend color="#1aa971" label="Delivered" />
              </div>
              <OrdersOverview />
            </Panel>

            <Panel className="lg:col-span-2">
              <PanelHead title="Orders by Status" />
              <OrdersStatusDonut />
            </Panel>
          </div>

          <div className="grid gap-4 lg:grid-cols-5">
            <div className="lg:col-span-2">
              <TopBranches />
            </div>
            <div className="lg:col-span-3">
              <CansSummary />
            </div>
          </div>

          <QuickActions />
        </div>

        {/* right */}
        <div className="space-y-4 xl:col-span-3">
          <RecentOrders />
          <PaymentSummary />
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
    <div
      className={`rounded-2xl border border-line bg-surface p-5 shadow-soft ${className}`}
    >
      {children}
    </div>
  );
}

function PanelHead({
  title,
  children,
}: {
  title: string;
  children?: React.ReactNode;
}) {
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
