"use client";

import { motion } from "framer-motion";
import { Camera, CheckCircle2, Save } from "lucide-react";
import { useActionState, useRef, useState } from "react";
import { useFormStatus } from "react-dom";

import { updateProfile, type ProfileState } from "./actions";

function SaveButton() {
  const { pending } = useFormStatus();
  return (
    <button
      type="submit"
      disabled={pending}
      className="inline-flex h-12 items-center gap-2 rounded-2xl bg-gradient-to-r from-[#004fda] to-[#2e8bf0] px-8 text-[14px] font-bold tracking-wide text-white shadow-[0_14px_30px_-12px_rgba(0,79,218,0.8)] transition hover:brightness-105 disabled:opacity-70"
    >
      <Save className="h-4 w-4" />
      {pending ? "Saving…" : "Save changes"}
    </button>
  );
}

export function ProfileForm({
  name,
  email,
  avatarUrl,
}: {
  name: string;
  email: string;
  avatarUrl: string | null;
}) {
  const [state, action] = useActionState<ProfileState, FormData>(
    updateProfile,
    {},
  );
  const [preview, setPreview] = useState<string | null>(avatarUrl);
  const fileRef = useRef<HTMLInputElement>(null);

  return (
    <form action={action} className="mt-6 max-w-xl space-y-6">
      {/* avatar */}
      <div className="flex items-center gap-5 rounded-3xl border border-line bg-surface p-5 shadow-soft">
        <div className="relative h-24 w-24 shrink-0">
          <div className="grid h-24 w-24 place-items-center overflow-hidden rounded-full bg-gradient-to-br from-[#004fda] to-[#37b6ff] text-[26px] font-bold text-white ring-4 ring-white shadow-lg">
            {preview ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={preview} alt="" className="h-full w-full object-cover" />
            ) : (
              name.slice(0, 1).toUpperCase()
            )}
          </div>
          <button
            type="button"
            onClick={() => fileRef.current?.click()}
            className="absolute -bottom-1 -right-1 grid h-9 w-9 place-items-center rounded-full bg-brand text-white shadow-md ring-2 ring-white"
            aria-label="Change photo"
          >
            <Camera className="h-4 w-4" />
          </button>
        </div>
        <div>
          <p className="text-[15px] font-bold text-ink">Profile photo</p>
          <p className="mt-0.5 text-[12.5px] text-ink-muted">
            PNG or JPG, up to 3 MB.
          </p>
          <button
            type="button"
            onClick={() => fileRef.current?.click()}
            className="mt-2 rounded-xl border border-line px-3.5 py-2 text-[12.5px] font-semibold text-ink-body hover:bg-tint"
          >
            Upload new photo
          </button>
        </div>
        <input
          ref={fileRef}
          type="file"
          name="avatar"
          accept="image/png,image/jpeg,image/webp"
          className="hidden"
          onChange={(e) => {
            const f = e.target.files?.[0];
            if (f) setPreview(URL.createObjectURL(f));
          }}
        />
      </div>

      {/* fields */}
      <div className="rounded-3xl border border-line bg-surface p-5 shadow-soft">
        <label htmlFor="name" className="block text-[13px] font-semibold text-ink">
          Full name
        </label>
        <input
          id="name"
          name="name"
          defaultValue={name}
          required
          className="mt-2 h-12 w-full rounded-xl border border-line bg-canvas px-3.5 text-[14px] text-ink outline-none focus:border-brand focus:ring-4 focus:ring-brand/10"
        />

        <label className="mt-5 block text-[13px] font-semibold text-ink">
          Email
        </label>
        <input
          value={email}
          disabled
          className="mt-2 h-12 w-full rounded-xl border border-line bg-tint px-3.5 text-[14px] text-ink-muted outline-none"
        />
        <p className="mt-1.5 text-[11.5px] text-ink-faint">
          Email can only be changed from the Supabase dashboard.
        </p>
      </div>

      <div className="flex flex-wrap items-center gap-4">
        <SaveButton />
        {state.error ? (
          <motion.p
            initial={{ opacity: 0, x: -6 }}
            animate={{ opacity: 1, x: 0 }}
            role="alert"
            className="rounded-2xl bg-danger-bg px-3.5 py-2.5 text-[12.5px] font-semibold text-danger"
          >
            {state.error}
          </motion.p>
        ) : null}
        {state.ok ? (
          <motion.p
            initial={{ opacity: 0, x: -6 }}
            animate={{ opacity: 1, x: 0 }}
            role="status"
            className="inline-flex items-center gap-1.5 rounded-2xl bg-ok-bg px-3.5 py-2.5 text-[12.5px] font-semibold text-ok"
          >
            <CheckCircle2 className="h-4 w-4" />
            {state.ok}
          </motion.p>
        ) : null}
      </div>
    </form>
  );
}
