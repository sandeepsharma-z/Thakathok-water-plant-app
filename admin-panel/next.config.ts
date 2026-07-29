import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  async redirects() {
    const staffPanel =
      process.env.NEXT_PUBLIC_DELIVERY_PANEL_URL ??
      "https://thakathok-delivery.vercel.app";
    return [
      {
        source: "/staff",
        destination: staffPanel,
        permanent: false,
      },
      {
        source: "/staff/login",
        destination: `${staffPanel}/login`,
        permanent: false,
      },
    ];
  },
};

export default nextConfig;
