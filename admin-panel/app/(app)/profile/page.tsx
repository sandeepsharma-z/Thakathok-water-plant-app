import { getProfile } from "@/lib/profile";
import { ProfileForm } from "./profile-form";

export const dynamic = "force-dynamic";

export default async function ProfilePage() {
  const profile = await getProfile();

  return (
    <>
      <header>
        <h1 className="text-[26px] font-extrabold tracking-tight text-ink">
          My Profile
        </h1>
        <p className="mt-1 text-[13px] text-ink-muted">
          Update your name and profile photo.
        </p>
      </header>

      <ProfileForm
        name={profile.name}
        email={profile.email}
        avatarUrl={profile.avatarUrl}
      />
    </>
  );
}
