import { ProductsForm, type ProductItem } from "@/components/products-form";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export default async function ProductsPage() {
  const supabase = await createClient();
  const { data } = await supabase
    .from("settings")
    .select("home_products")
    .eq("id", 1)
    .single();
  const products = (data?.home_products ?? []) as unknown as ProductItem[];
  return (
    <>
      <header>
        <h1 className="text-[27px] font-extrabold tracking-tight text-ink">
          Products
        </h1>
        <p className="mt-1 text-[13px] text-ink-muted">
          Add, edit, arrange or hide customer-app product packs.
        </p>
      </header>
      <ProductsForm initialProducts={products} />
    </>
  );
}
