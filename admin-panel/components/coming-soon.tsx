import { Card, EmptyState } from "@/components/ui";

/** A dedicated placeholder screen for features that aren't built yet. Each
 *  gets its own route so the sidebar always opens a real, separate screen. */
export function ComingSoon({
  title,
  subtitle,
  body,
}: {
  title: string;
  subtitle: string;
  body: string;
}) {
  return (
    <>
      <header className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-[27px] font-extrabold tracking-tight text-ink">
            {title}
          </h1>
          <p className="mt-1 text-[13px] text-ink-muted">{subtitle}</p>
        </div>
        <span className="mt-1 rounded-full bg-tint px-3 py-1 text-[11px] font-bold tracking-wide text-brand">
          COMING SOON
        </span>
      </header>
      <Card className="mt-6">
        <EmptyState icon="clock" title="We're building this" body={body} />
      </Card>
    </>
  );
}
