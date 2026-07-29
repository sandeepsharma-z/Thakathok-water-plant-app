import type { Metadata } from "next";
import "./globals.css";

export const metadata:Metadata={
  title:"ThakaThok Delivery Staff",
  description:"Assigned delivery orders for Mahalakshmi Water Plant",
  manifest:"/manifest.webmanifest",
};

export default function RootLayout({children}:{children:React.ReactNode}){
  return <html lang="en"><body>{children}</body></html>;
}
