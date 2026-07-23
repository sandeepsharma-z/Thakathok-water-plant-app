import { redirect } from "next/navigation";

import { MobileBar, Sidebar } from "@/components/nav";
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

  const name = "Sandeep Sharma";

  return (
    <div className="relative min-h-dvh bg-canvas">
      <Sidebar name={name} />
      <MobileBar name={name} />
      <main className="pb-10 lg:pl-[250px]">
        <div className="mx-auto max-w-[1600px] px-4 py-5 sm:px-6 lg:px-7 lg:py-6">
          {children}
        </div>
      </main>
    </div>
  );
}
