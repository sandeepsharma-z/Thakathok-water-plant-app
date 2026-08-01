"use client";
import {Languages} from "lucide-react";
import {useRouter} from "next/navigation";
import type {Locale} from "@/lib/i18n";

export function LanguageSelector({locale,inverted=false}:{locale:Locale;inverted?:boolean}){
 const router=useRouter();
 return <label className={`flex items-center gap-2 rounded-xl px-3 py-2 text-xs font-bold ${inverted?"bg-white/15 text-white":"border border-blue-100 bg-blue-50 text-blue-800"}`}>
  <Languages className="h-4 w-4"/>
  <select aria-label="Language" value={locale} onChange={event=>{document.cookie=`delivery_language=${event.target.value}; path=/; max-age=31536000; samesite=lax`;router.refresh();}} className="bg-transparent outline-none">
   <option className="text-slate-900" value="en">English</option><option className="text-slate-900" value="hi">हिन्दी</option><option className="text-slate-900" value="mr">मराठी</option>
  </select>
 </label>;
}
