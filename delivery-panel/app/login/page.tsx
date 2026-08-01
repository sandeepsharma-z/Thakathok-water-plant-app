import {cookies} from "next/headers";
import {LoginForm} from "@/components/login-form";
import {normalizeLocale} from "@/lib/i18n";

export default async function LoginPage(){
  const locale=normalizeLocale((await cookies()).get("delivery_language")?.value);
  return <LoginForm locale={locale}/>;
}
