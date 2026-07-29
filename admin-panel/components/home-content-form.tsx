"use client";

import {
  ArrowDown,
  ArrowUp,
  CheckCircle2,
  ImageIcon,
  Plus,
  Save,
  Trash2,
} from "lucide-react";
import { useActionState, useState } from "react";
import { useFormStatus } from "react-dom";

import {
  updateHomeContent,
  type HomeContentState,
} from "@/app/(app)/home-content/actions";

type Item = Record<string, unknown>;
export type HomeContentData = {
  home_hero_banners: Item[];
  home_promo_banners: Item[];
  home_products: Item[];
  home_categories: Item[];
  support_content: Item;
  home_ui_content: Item;
  booking_event_types: string[];
};

const value = (item: Item, key: string) => String(item?.[key] ?? "");
const checked = (item: Item, key = "enabled") => item?.[key] !== false;

function Submit() {
  const { pending } = useFormStatus();
  return (
    <button
      disabled={pending}
      className="inline-flex h-12 items-center gap-2 rounded-2xl bg-brand px-7 text-[14px] font-bold text-white shadow-soft disabled:opacity-60"
    >
      <Save className="h-4 w-4" />
      {pending ? "Uploading & saving…" : "Save home screen"}
    </button>
  );
}

function ImageInput({
  prefix,
  current,
}: {
  prefix: string;
  current: string;
}) {
  return (
    <div className="flex items-center gap-4">
      <div className="grid h-24 w-36 shrink-0 place-items-center overflow-hidden rounded-2xl border border-line bg-canvas">
        {current.startsWith("http") ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={current} alt="" className="h-full w-full object-contain" />
        ) : (
          <ImageIcon className="h-7 w-7 text-ink-faint" />
        )}
      </div>
      <div className="min-w-0 flex-1">
        <input type="hidden" name={`${prefix}_current`} value={current} />
        <input
          type="file"
          name={`${prefix}_file`}
          accept="image/png,image/jpeg,image/webp"
          className="block w-full text-[12px] text-ink-muted file:mr-3 file:rounded-xl file:border-0 file:bg-brand/10 file:px-3 file:py-2 file:font-bold file:text-brand"
        />
        <p className="mt-2 text-[11px] text-ink-faint">
          PNG, JPG or WebP · maximum 5 MB
        </p>
      </div>
    </div>
  );
}

function Toggle({ name, item }: { name: string; item: Item }) {
  return (
    <label className="inline-flex items-center gap-2 text-[12px] font-bold text-ink">
      <input
        type="checkbox"
        name={name}
        defaultChecked={checked(item)}
        className="h-4 w-4 accent-[#004fda]"
      />
      Show in app
    </label>
  );
}

const inputClass =
  "mt-1.5 h-11 w-full rounded-xl border border-line bg-canvas px-3 text-[13px] font-semibold text-ink outline-none focus:border-brand";
const areaClass =
  "mt-1.5 min-h-20 w-full rounded-xl border border-line bg-canvas px-3 py-2.5 text-[13px] text-ink outline-none focus:border-brand";

export function HomeContentForm({ content }: { content: HomeContentData }) {
  const [state, action] = useActionState<HomeContentState, FormData>(
    updateHomeContent,
    {},
  );
  const [heroes, setHeroes] = useState<(Item & { _key: string })[]>(
    (content.home_hero_banners ?? []).map((item, index) => ({
      ...item,
      _key: `saved-${index}-${String(item.image_url ?? "")}`,
    })),
  );
  const promos = content.home_promo_banners ?? [];
  const categories = content.home_categories ?? [];
  const support = content.support_content ?? {};
  const homeUi = content.home_ui_content ?? {};
  const searchPhrases = Array.isArray(homeUi.search_phrases)
    ? (homeUi.search_phrases as unknown[]).map(String)
    : [];
  const quickActions = Array.isArray(homeUi.quick_actions)
    ? (homeUi.quick_actions as Item[])
    : [];
  const trustItems = Array.isArray(homeUi.trust_items)
    ? (homeUi.trust_items as Item[])
    : [];
  const eventTypes = content.booking_event_types?.length
    ? content.booking_event_types
    : ["Wedding", "Birthday", "Other"];
  const faqs = Array.isArray(support.faqs) ? (support.faqs as Item[]) : [];

  return (
    <form action={action} className="mt-6 space-y-8">
      <Section
        title="Home text & shortcuts"
        hint="Greeting, section headings, animated search text, quick actions and trust badges shown on the customer home screen."
      >
        <div className="grid gap-4 xl:grid-cols-2">
          <ContentCard title="Headings & greeting">
            <Field label="Greeting tagline" name="greeting_tagline" defaultValue={value(homeUi, "greeting_tagline")} />
            <Field label="Popular products heading" name="popular_heading" defaultValue={value(homeUi, "popular_heading")} />
            <Field label="Shop categories heading" name="shop_heading" defaultValue={value(homeUi, "shop_heading")} />
          </ContentCard>
          <ContentCard title="Animated search phrases">
            <TextArea
              label="One phrase per line"
              name="search_phrases"
              defaultValue={searchPhrases.join("\n")}
            />
          </ContentCard>
        </div>
        <h3 className="mb-3 mt-5 text-[14px] font-extrabold text-ink">Quick actions</h3>
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-5">
          {[0,1,2,3,4].map((index) => {
            const item = quickActions[index] ?? {};
            return <ContentCard key={index} title={`Shortcut ${index + 1}`}>
              <Field label="Title" name={`quick_title_${index}`} defaultValue={value(item, "title")} />
              <Field label="Subtitle" name={`quick_subtitle_${index}`} defaultValue={value(item, "subtitle")} />
            </ContentCard>;
          })}
        </div>
        <h3 className="mb-3 mt-5 text-[14px] font-extrabold text-ink">Trust strip</h3>
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {[0,1,2,3].map((index) => {
            const item = trustItems[index] ?? {};
            return <ContentCard key={index} title={`Trust item ${index + 1}`}>
              <Field label="Text" name={`trust_title_${index}`} defaultValue={value(item, "title")} />
            </ContentCard>;
          })}
        </div>
      </Section>

      <Section
        title="Hero banner slider"
        hint="Add as many slides as needed, change their order, replace images or hide individual slides."
      >
        <input type="hidden" name="hero_count" value={heroes.length} />
        <div className="mb-4 flex justify-end">
          <button
            type="button"
            onClick={() =>
              setHeroes([
                ...heroes,
                {
                  image_url: "",
                  enabled: true,
                  action: "none",
                  _key: `new-${crypto.randomUUID()}`,
                },
              ])
            }
            className="inline-flex items-center gap-2 rounded-xl bg-brand px-4 py-2.5 text-[13px] font-bold text-white"
          >
            <Plus className="h-4 w-4" /> Add banner slide
          </button>
        </div>
        <div className="grid gap-4 xl:grid-cols-2">
          {heroes.map((item, index) => {
            const move = (to: number) => {
              if (to < 0 || to >= heroes.length) return;
              const next = [...heroes];
              const [selected] = next.splice(index, 1);
              next.splice(to, 0, selected);
              setHeroes(next);
            };
            return (
              <ContentCard
                key={String(item._key)}
                title={`Hero slide ${index + 1}`}
                actions={
                  <div className="flex gap-1">
                    <MiniButton onClick={() => move(index - 1)}>
                      <ArrowUp />
                    </MiniButton>
                    <MiniButton onClick={() => move(index + 1)}>
                      <ArrowDown />
                    </MiniButton>
                    <MiniButton
                      danger
                      onClick={() =>
                        setHeroes(heroes.filter((_, itemIndex) => itemIndex !== index))
                      }
                    >
                      <Trash2 />
                    </MiniButton>
                  </div>
                }
              >
                <ImageInput
                  prefix={`hero_${index}`}
                  current={value(item, "image_url")}
                />
                <Toggle name={`hero_enabled_${index}`} item={item} />
              </ContentCard>
            );
          })}
        </div>
      </Section>

      <Section
        title="Promotional banners"
        hint="The first banner opens the order form; the second is the lower strip."
      >
        <div className="grid gap-4 xl:grid-cols-2">
          {[0, 1].map((index) => {
            const item = promos[index] ?? {};
            return (
              <ContentCard
                key={index}
                title={index === 0 ? "Delivery banner" : "Lower banner"}
              >
                <ImageInput
                  prefix={`promo_${index}`}
                  current={value(item, "image_url")}
                />
                <Toggle name={`promo_enabled_${index}`} item={item} />
              </ContentCard>
            );
          })}
        </div>
      </Section>

      <Section
        title="Shop By Need"
        hint="Edit the four circular categories and their order-form behavior."
      >
        <div className="grid gap-4 xl:grid-cols-2">
          {[0, 1, 2, 3].map((index) => {
            const item = categories[index] ?? {};
            return (
              <ContentCard key={index} title={`Category ${index + 1}`}>
                <ImageInput
                  prefix={`category_${index}`}
                  current={value(item, "image_url")}
                />
                <div className="grid gap-3 sm:grid-cols-2">
                  <Field
                    label="Category name"
                    name={`category_name_${index}`}
                    defaultValue={value(item, "name")}
                  />
                  <label className="text-[12px] font-bold text-ink">
                    Event type
                    <select
                      name={`category_event_${index}`}
                      defaultValue={value(item, "event_type") || "Other"}
                      className={inputClass}
                    >
                      {eventTypes.map((eventType) => (
                        <option key={eventType}>{eventType}</option>
                      ))}
                    </select>
                  </label>
                </div>
                <div className="flex flex-wrap gap-5">
                  <Toggle name={`category_enabled_${index}`} item={item} />
                  <label className="inline-flex items-center gap-2 text-[12px] font-bold text-ink">
                    <input
                      type="checkbox"
                      name={`category_custom_${index}`}
                      defaultChecked={item.custom_quantity === true}
                      className="h-4 w-4 accent-[#004fda]"
                    />
                    Ask custom quantity
                  </label>
                </div>
              </ContentCard>
            );
          })}
        </div>
      </Section>

      <Section
        title="Help & Support"
        hint="Contact-card copy and FAQ content shown in the customer app."
      >
        <ContentCard title="Support headings">
          <div className="grid gap-3 lg:grid-cols-3">
            <Field
              label="Main heading"
              name="support_heading"
              defaultValue={value(support, "heading")}
            />
            <Field
              label="Description"
              name="support_description"
              defaultValue={value(support, "description")}
            />
            <Field
              label="FAQ section title"
              name="support_section_title"
              defaultValue={value(support, "section_title")}
            />
          </div>
        </ContentCard>
        <div className="mt-4 grid gap-4 xl:grid-cols-2">
          {[0, 1, 2, 3, 4].map((index) => {
            const faq = faqs[index] ?? {};
            return (
              <ContentCard key={index} title={`FAQ ${index + 1}`}>
                <Field
                  label="Question"
                  name={`faq_question_${index}`}
                  defaultValue={value(faq, "question")}
                />
                <TextArea
                  label="Answer"
                  name={`faq_answer_${index}`}
                  defaultValue={value(faq, "answer")}
                />
              </ContentCard>
            );
          })}
        </div>
      </Section>

      <div className="sticky bottom-4 flex flex-wrap items-center gap-4 rounded-2xl border border-line bg-surface/95 p-4 shadow-xl backdrop-blur">
        <Submit />
        {state.error ? (
          <p className="text-[12.5px] font-semibold text-danger">{state.error}</p>
        ) : null}
        {state.ok ? (
          <p className="inline-flex items-center gap-2 text-[12.5px] font-semibold text-ok">
            <CheckCircle2 className="h-4 w-4" />
            {state.ok}
          </p>
        ) : null}
      </div>
    </form>
  );
}

function Section({
  title,
  hint,
  children,
}: {
  title: string;
  hint: string;
  children: React.ReactNode;
}) {
  return (
    <section>
      <h2 className="text-[19px] font-extrabold text-ink">{title}</h2>
      <p className="mb-4 mt-1 text-[12px] text-ink-muted">{hint}</p>
      {children}
    </section>
  );
}

function ContentCard({
  title,
  children,
  actions,
}: {
  title: string;
  children: React.ReactNode;
  actions?: React.ReactNode;
}) {
  return (
    <div className="space-y-4 rounded-3xl border border-line bg-surface p-5 shadow-soft">
      <div className="flex items-center justify-between gap-3">
        <h3 className="text-[14px] font-extrabold text-ink">{title}</h3>
        {actions}
      </div>
      {children}
    </div>
  );
}

function MiniButton({
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
      className={`grid h-9 w-9 place-items-center rounded-xl ${
        danger ? "bg-danger-bg text-danger" : "bg-canvas text-brand"
      } [&_svg]:h-4 [&_svg]:w-4`}
    >
      {children}
    </button>
  );
}

function Field({
  label,
  name,
  defaultValue,
  type = "text",
}: {
  label: string;
  name: string;
  defaultValue: string;
  type?: string;
}) {
  return (
    <label className="text-[12px] font-bold text-ink">
      {label}
      <input
        name={name}
        type={type}
        min={type === "number" ? 1 : undefined}
        defaultValue={defaultValue}
        className={inputClass}
      />
    </label>
  );
}

function TextArea({
  label,
  name,
  defaultValue,
}: {
  label: string;
  name: string;
  defaultValue: string;
}) {
  return (
    <label className="text-[12px] font-bold text-ink">
      {label}
      <textarea
        name={name}
        defaultValue={defaultValue}
        className={areaClass}
      />
    </label>
  );
}
