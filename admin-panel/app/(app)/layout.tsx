import { redirect } from "next/navigation";

import { MobileBar, Sidebar } from "@/components/nav";
import { createClient } from "@/lib/supabase/server";
import { getProfile } from "@/lib/profile";

export default async function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login");
  const [{ data: staffAccount }, { data: adminAccount }] = await Promise.all([
    supabase.from("delivery_staff").select("id").eq("user_id", user.id).maybeSingle(),
    supabase.from("admin_users").select("user_id").eq("user_id", user.id).maybeSingle(),
  ]);
  if (staffAccount) redirect("/staff");
  if (!adminAccount) redirect("/login");

  const profile = await getProfile();
  const { data: navReads } = await supabase
    .from("admin_nav_reads")
    .select("section,last_seen_at")
    .eq("user_id", user.id);
  const lastSeen = new Map(
    (navReads ?? []).map((row) => [row.section, row.last_seen_at]),
  );
  const unseenSince = (section: "orders" | "customers") =>
    lastSeen.get(section) ?? "1970-01-01T00:00:00.000Z";

  const [
    { count: villages },
    { count: activeOrders },
    { count: customers },
    { count: readyDeliveries },
    { count: waitingForCans },
    { count: pendingDues },
  ] = await Promise.all([
    supabase
      .from("villages")
      .select("*", { count: "exact", head: true })
      .eq("enabled", true),
    supabase
      .from("bookings")
      .select("*", { count: "exact", head: true })
      .gt("created_at", unseenSince("orders")),
    supabase
      .from("customers")
      .select("*", { count: "exact", head: true })
      .gt("updated_at", unseenSince("customers")),
    supabase
      .from("bookings")
      .select("*", { count: "exact", head: true })
      .eq("status", "confirmed"),
    supabase
      .from("booking_can_allocations")
      .select("*", { count: "exact", head: true })
      .eq("state", "waiting"),
    supabase
      .from("bookings")
      .select("*", { count: "exact", head: true })
      .in("status", ["confirmed", "delivered"])
      .gt("balance", 0),
  ]);

  const sidebarCounts: Record<string, number> = {
    "/bookings": activeOrders ?? 0,
    "/customers": customers ?? 0,
    "/delivery": readyDeliveries ?? 0,
    "/cans": waitingForCans ?? 0,
    "/pending-dues": pendingDues ?? 0,
  };

  return (
    <div className="relative min-h-dvh bg-canvas">
      <Sidebar
        name={profile.name}
        avatarUrl={profile.avatarUrl}
        villages={villages ?? 0}
        counts={sidebarCounts}
      />
      <MobileBar name={profile.name} />
      <main className="pb-10 lg:pl-[250px]">
        <div className="mx-auto max-w-[1600px] px-4 py-5 sm:px-6 lg:px-7 lg:py-6">
          {children}
        </div>
      </main>
    </div>
  );
}
