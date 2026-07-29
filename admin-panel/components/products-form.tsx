"use client";

import { ArrowDown, ArrowUp, Plus, Save, Trash2 } from "lucide-react";
import { useActionState, useState } from "react";
import { useFormStatus } from "react-dom";
import {
  updateProducts,
  type ProductState,
} from "@/app/(app)/products/actions";

export type ProductItem = {
  name?: string;
  quantity_label?: string;
  cans?: number | null;
  image_url?: string;
  description?: string;
  ideal_for?: string;
  enabled?: boolean;
};
const input =
  "h-11 w-full rounded-xl border border-line bg-canvas px-3 text-[13px] font-semibold text-ink outline-none focus:border-brand";

function Submit() {
  const { pending } = useFormStatus();
  return (
    <button
      disabled={pending}
      className="inline-flex h-12 items-center gap-2 rounded-2xl bg-brand px-7 font-bold text-white disabled:opacity-60"
    >
      <Save className="h-4 w-4" />
      {pending ? "Saving…" : "Save products"}
    </button>
  );
}

export function ProductsForm({
  initialProducts,
}: {
  initialProducts: ProductItem[];
}) {
  const [items, setItems] = useState(initialProducts);
  const [state, action] = useActionState<ProductState, FormData>(
    updateProducts,
    {},
  );
  const move = (from: number, to: number) => {
    if (to < 0 || to >= items.length) return;
    const next = [...items];
    const [item] = next.splice(from, 1);
    next.splice(to, 0, item);
    setItems(next);
  };
  return (
    <form action={action} className="mt-6 space-y-4">
      <input type="hidden" name="count" value={items.length} />
      <div className="flex justify-end">
        <button
          type="button"
          onClick={() =>
            setItems([
              ...items,
              {
                name: "",
                quantity_label: "",
                cans: null,
                image_url: "",
                description: "",
                ideal_for: "",
                enabled: true,
              },
            ])
          }
          className="inline-flex items-center gap-2 rounded-xl bg-brand/10 px-4 py-2.5 text-[13px] font-bold text-brand"
        >
          <Plus className="h-4 w-4" /> Add product
        </button>
      </div>
      {items.map((item, index) => (
        <section
          key={`${item.image_url}-${index}`}
          className="rounded-3xl border border-line bg-surface p-5 shadow-soft"
        >
          <div className="mb-5 flex items-center justify-between">
            <h2 className="text-[16px] font-extrabold text-ink">
              {item.name || `New product ${index + 1}`}
            </h2>
            <div className="flex gap-1">
              <IconButton onClick={() => move(index, index - 1)}>
                <ArrowUp />
              </IconButton>
              <IconButton onClick={() => move(index, index + 1)}>
                <ArrowDown />
              </IconButton>
              <IconButton
                danger
                onClick={() => setItems(items.filter((_, i) => i !== index))}
              >
                <Trash2 />
              </IconButton>
            </div>
          </div>
          <div className="grid gap-5 lg:grid-cols-[220px_1fr]">
            <div>
              <div className="grid h-40 place-items-center overflow-hidden rounded-2xl bg-canvas">
                {item.image_url ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={item.image_url}
                    alt=""
                    className="h-full w-full object-contain"
                  />
                ) : (
                  <span className="text-xs text-ink-faint">Choose an image</span>
                )}
              </div>
              <input
                type="hidden"
                name={`current_${index}`}
                value={item.image_url ?? ""}
              />
              <input
                className="mt-3 w-full text-xs"
                type="file"
                name={`file_${index}`}
                accept="image/*"
              />
            </div>
            <div className="grid gap-3 sm:grid-cols-2">
              <Field name={`name_${index}`} value={item.name} label="Name" />
              <Field
                name={`quantity_${index}`}
                value={item.quantity_label}
                label="Quantity label"
              />
              <Field
                name={`cans_${index}`}
                value={item.cans ?? ""}
                label="Cans (blank for custom)"
                type="number"
              />
              <label className="flex items-center gap-2 pt-6 text-sm font-bold">
                <input
                  type="checkbox"
                  name={`enabled_${index}`}
                  defaultChecked={item.enabled !== false}
                  className="h-4 w-4 accent-[#004fda]"
                />
                Show in app
              </label>
              <Area
                name={`description_${index}`}
                value={item.description}
                label="Description"
              />
              <Area
                name={`ideal_${index}`}
                value={item.ideal_for}
                label="Ideal for"
              />
            </div>
          </div>
        </section>
      ))}
      <div className="sticky bottom-4 flex items-center gap-4 rounded-2xl border border-line bg-white/95 p-4 shadow-xl">
        <Submit />
        <span className={state.error ? "text-danger" : "text-ok"}>
          {state.error ?? state.ok}
        </span>
      </div>
    </form>
  );
}

function IconButton({
  children,
  onClick,
  danger = false,
}: {
  children: React.ReactNode;
  onClick: () => void;
  danger?: boolean;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`grid h-9 w-9 place-items-center rounded-xl ${danger ? "bg-danger-bg text-danger" : "bg-canvas text-brand"} [&_svg]:h-4 [&_svg]:w-4`}
    >
      {children}
    </button>
  );
}
function Field({
  label,
  name,
  value,
  type = "text",
}: {
  label: string;
  name: string;
  value: string | number | undefined;
  type?: string;
}) {
  return (
    <label className="space-y-1.5 text-xs font-bold">
      <span>{label}</span>
      <input
        className={input}
        name={name}
        type={type}
        min={type === "number" ? 1 : undefined}
        defaultValue={value}
      />
    </label>
  );
}
function Area({
  label,
  name,
  value,
}: {
  label: string;
  name: string;
  value?: string;
}) {
  return (
    <label className="space-y-1.5 text-xs font-bold">
      <span>{label}</span>
      <textarea
        className={`${input} min-h-24 py-3`}
        name={name}
        defaultValue={value}
      />
    </label>
  );
}
