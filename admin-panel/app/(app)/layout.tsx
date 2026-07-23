import { redirect } from "next/navigation";

import { Nav } from "@/components/nav";
import { createClient } from "@/lib/supabase/server";

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

  return (
    <div className="relative min-h-dvh">
      {/* subtle page backdrop */}
      <div
        aria-hidden
        className="pointer-events-none fixed inset-0 -z-10 bg-[radial-gradient(1000px_600px_at_100%_-5%,#dcebff_0%,transparent_55%),radial-gradient(800px_500px_at_-5%_100%,#e3f2ff_0%,transparent_55%)]"
      />
      <Nav email={user.email ?? ""} />
      <main className="pb-24 lg:pb-10 lg:pl-[256px]">
        <div className="mx-auto max-w-[1200px] px-4 py-6 sm:px-6 lg:px-8 lg:py-8">
          {children}
        </div>
      </main>
    </div>
  );
}
