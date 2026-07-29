import { AlertTriangle, History, PackageCheck, RotateCcw } from "lucide-react";

import {
  CanReturnForm,
  InventoryAdjustmentForm,
} from "@/components/can-inventory-actions";
import { PageHead } from "@/components/management-ui";
import { Card, EmptyState, StatTile } from "@/components/ui";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

type Inventory = {
  total_cans: number;
  available_cans: number;
  reserved_cans: number;
  out_for_delivery: number;
  damaged_cans: number;
};

export default async function CansManagementPage() {
  const db = await createClient();
  const [
    { data: branchRows },
    { data: inventoryRows },
    { data: allocations },
    { data: movements },
  ] =
    await Promise.all([
      db
        .from("branches")
        .select("id,name,code,enabled")
        .order("name"),
      db
        .from("can_inventory")
        .select(
          "branch_id,total_cans,available_cans,reserved_cans,out_for_delivery,damaged_cans",
        ),
      db
        .from("booking_can_allocations")
        .select(
          "id,booking_id,branch_id,quantity,returned_quantity,damaged_quantity,state,updated_at,bookings(booking_code,customer_name,mobile,village,event_date)",
        )
        .in("state", ["waiting", "reserved", "delivered"])
        .order("updated_at", { ascending: false }),
      db
        .from("can_inventory_movements")
        .select(
          "id,movement_type,quantity,note,created_at,branches(name),bookings(booking_code)",
        )
        .order("created_at", { ascending: false })
        .limit(30),
    ]);

  const inventoryByBranch = new Map(
    (inventoryRows ?? []).map((inventory) => [
      inventory.branch_id,
      inventory as Inventory & { branch_id: string },
    ]),
  );
  const branches = (branchRows ?? []).map((branch) => ({
    ...branch,
    inventory: (inventoryByBranch.get(branch.id) ?? {
      total_cans: 0,
      available_cans: 0,
      reserved_cans: 0,
      out_for_delivery: 0,
      damaged_cans: 0,
    }) as Inventory,
  }));
  const sum = (key: keyof Inventory) =>
    branches.reduce(
      (total, branch) => total + Number(branch.inventory[key] ?? 0),
      0,
    );
  const activeAllocations = allocations ?? [];
  const waiting = activeAllocations.filter((row) => row.state === "waiting");
  const withCustomers = activeAllocations.filter(
    (row) => row.state === "delivered",
  );

  return (
    <>
      <PageHead
        title="Cans Management"
        body="Automatic stock reservation, deliveries, customer returns, damage and complete movement history."
      />

      <div className="mt-5 grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
        <StatTile label="Total cans" value={sum("total_cans")} icon="package" />
        <StatTile
          label="Available"
          value={sum("available_cans")}
          icon="check"
          accent="ok"
        />
        <StatTile
          label="Reserved"
          value={sum("reserved_cans")}
          icon="clipboard"
          accent="brand"
        />
        <StatTile
          label="With customers"
          value={sum("out_for_delivery")}
          icon="truck"
          accent="aqua"
        />
        <StatTile
          label="Damaged"
          value={sum("damaged_cans")}
          icon="alert"
          accent="warn"
        />
      </div>

      <Card className="mt-5 p-5">
        <h2 className="flex items-center gap-2 font-extrabold text-ink">
          <PackageCheck className="h-5 w-5 text-brand" />
          Stock adjustment
        </h2>
        <p className="mt-1 text-[12px] text-ink-muted">
          Every adjustment is recorded. Adding or repairing cans automatically
          reserves stock for the oldest waiting bookings.
        </p>
        <InventoryAdjustmentForm
          branches={branches.map(({ id, name }) => ({ id, name }))}
        />
      </Card>

      <div className="mt-5 grid gap-4 lg:grid-cols-2">
        {branches.map((branch) => {
          const inventory = branch.inventory;
          const accounted =
            inventory.available_cans +
            inventory.reserved_cans +
            inventory.out_for_delivery +
            inventory.damaged_cans;
          return (
            <Card key={branch.id} className="p-5">
              <div className="flex items-center justify-between">
                <div>
                  <h2 className="font-extrabold text-ink">{branch.name}</h2>
                  <p className="text-[10px] font-bold uppercase text-ink-faint">
                    {branch.code} · {branch.enabled ? "Active" : "Hidden"}
                  </p>
                </div>
                <p className="text-2xl font-extrabold text-gradient">
                  {inventory.total_cans}
                </p>
              </div>
              <div className="mt-4 grid grid-cols-4 gap-2 text-center">
                {[
                  ["Available", inventory.available_cans],
                  ["Reserved", inventory.reserved_cans],
                  ["Customer", inventory.out_for_delivery],
                  ["Damaged", inventory.damaged_cans],
                ].map(([label, value]) => (
                  <div key={String(label)} className="rounded-2xl bg-canvas p-3">
                    <p className="text-[10px] text-ink-muted">{label}</p>
                    <p className="mt-1 text-lg font-extrabold text-ink">
                      {value}
                    </p>
                  </div>
                ))}
              </div>
              {accounted !== inventory.total_cans ? (
                <p className="mt-3 flex items-center gap-2 rounded-xl bg-warn-bg px-3 py-2 text-[11px] font-semibold text-warn">
                  <AlertTriangle className="h-4 w-4" />
                  Inventory mismatch: {accounted} cans are accounted against{" "}
                  {inventory.total_cans} total.
                </p>
              ) : null}
            </Card>
          );
        })}
      </div>

      {waiting.length > 0 ? (
        <Card className="mt-5 border-warn/20 p-5">
          <h2 className="flex items-center gap-2 font-extrabold text-ink">
            <AlertTriangle className="h-5 w-5 text-warn" />
            Waiting for stock ({waiting.length})
          </h2>
          <div className="mt-3 divide-y divide-line">
            {waiting.map((allocation) => {
              const booking = Array.isArray(allocation.bookings)
                ? allocation.bookings[0]
                : allocation.bookings;
              return (
                <div
                  key={allocation.id}
                  className="flex flex-wrap justify-between gap-3 py-3 text-[12px]"
                >
                  <div>
                    <p className="font-extrabold text-brand">
                      {booking?.booking_code}
                    </p>
                    <p className="text-ink-muted">
                      {booking?.customer_name} · +91 {booking?.mobile} ·{" "}
                      {booking?.village}
                    </p>
                  </div>
                  <p className="font-extrabold text-warn">
                    {allocation.quantity} cans required
                  </p>
                </div>
              );
            })}
          </div>
        </Card>
      ) : null}

      <Card className="mt-5 p-5">
        <h2 className="flex items-center gap-2 font-extrabold text-ink">
          <RotateCcw className="h-5 w-5 text-brand" />
          Cans pending with customers
        </h2>
        {withCustomers.length === 0 ? (
          <EmptyState
            icon="check"
            title="No cans pending"
            body="Delivered cans awaiting return will appear here."
          />
        ) : (
          <div className="mt-3 divide-y divide-line">
            {withCustomers.map((allocation) => {
              const booking = Array.isArray(allocation.bookings)
                ? allocation.bookings[0]
                : allocation.bookings;
              const pending =
                allocation.quantity -
                allocation.returned_quantity -
                allocation.damaged_quantity;
              return (
                <div key={allocation.id} className="py-4">
                  <div className="flex flex-wrap justify-between gap-3">
                    <div>
                      <p className="font-extrabold text-brand">
                        {booking?.booking_code} · {booking?.customer_name}
                      </p>
                      <p className="text-[11px] text-ink-muted">
                        +91 {booking?.mobile} · {booking?.village}
                      </p>
                    </div>
                    <p className="font-extrabold text-warn">
                      {pending} cans pending
                    </p>
                  </div>
                  <CanReturnForm
                    bookingId={allocation.booking_id}
                    pending={pending}
                  />
                </div>
              );
            })}
          </div>
        )}
      </Card>

      <Card className="mt-5 overflow-hidden">
        <div className="border-b border-line p-5">
          <h2 className="flex items-center gap-2 font-extrabold text-ink">
            <History className="h-5 w-5 text-brand" />
            Inventory movement history
          </h2>
        </div>
        {!movements?.length ? (
          <EmptyState
            icon="clipboard"
            title="No movements yet"
            body="Stock and booking movements will be recorded here."
          />
        ) : (
          <div className="divide-y divide-line">
            {movements.map((movement) => {
              const branch = Array.isArray(movement.branches)
                ? movement.branches[0]
                : movement.branches;
              const booking = Array.isArray(movement.bookings)
                ? movement.bookings[0]
                : movement.bookings;
              return (
                <div
                  key={movement.id}
                  className="grid gap-2 p-4 text-[12px] sm:grid-cols-[1fr_auto_auto]"
                >
                  <div>
                    <p className="font-bold capitalize text-ink">
                      {movement.movement_type.replaceAll("_", " ")}
                    </p>
                    <p className="text-[11px] text-ink-muted">
                      {branch?.name}
                      {booking?.booking_code
                        ? ` · ${booking.booking_code}`
                        : ""}
                      {movement.note ? ` · ${movement.note}` : ""}
                    </p>
                  </div>
                  <p className="font-extrabold text-brand">
                    {movement.quantity} cans
                  </p>
                  <p className="text-[11px] text-ink-faint">
                    {new Date(movement.created_at).toLocaleString("en-IN")}
                  </p>
                </div>
              );
            })}
          </div>
        )}
      </Card>
    </>
  );
}
