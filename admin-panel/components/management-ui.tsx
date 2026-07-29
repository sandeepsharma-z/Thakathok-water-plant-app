export const inputClass = "w-full rounded-xl border border-line bg-canvas px-3 py-2.5 text-[13px] text-ink outline-none focus:border-brand";
export const buttonClass = "rounded-xl bg-brand px-4 py-2.5 text-[12px] font-bold text-white shadow-sm hover:brightness-110";
export const dangerClass = "rounded-xl border border-rose-200 px-3 py-2 text-[11px] font-bold text-danger hover:bg-danger-bg";
export function PageHead({title,body}:{title:string;body:string}) {
  return <header><h1 className="text-[27px] font-extrabold tracking-tight text-ink">{title}</h1><p className="mt-1 text-[13px] text-ink-muted">{body}</p></header>;
}
