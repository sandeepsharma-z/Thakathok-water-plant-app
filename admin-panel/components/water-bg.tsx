"use client";

import { useMemo } from "react";

/**
 * Decorative animated water backdrop: soft drifting colour blobs plus a
 * field of rising bubbles. Purely visual, pointer-events-none.
 */
export function WaterBackground({
  bubbles = 14,
  className = "",
}: {
  bubbles?: number;
  className?: string;
}) {
  const drops = useMemo(
    () =>
      Array.from({ length: bubbles }).map((_, i) => {
        const size = 6 + Math.round(Math.random() * 22);
        return {
          id: i,
          size,
          left: Math.round(Math.random() * 100),
          delay: Math.round(Math.random() * 8000) / 1000,
          dur: 7 + Math.round(Math.random() * 9),
        };
      }),
    [bubbles],
  );

  return (
    <div
      aria-hidden
      className={`pointer-events-none absolute inset-0 overflow-hidden ${className}`}
    >
      {/* drifting gradient blobs */}
      <div className="animate-float-slow absolute -left-24 -top-24 h-80 w-80 rounded-full bg-[radial-gradient(circle,rgba(0,162,255,0.28),transparent_70%)] blur-2xl" />
      <div className="animate-float absolute -right-16 top-10 h-72 w-72 rounded-full bg-[radial-gradient(circle,rgba(0,79,218,0.22),transparent_70%)] blur-2xl" />
      <div className="animate-float-slow absolute bottom-0 left-1/3 h-72 w-72 rounded-full bg-[radial-gradient(circle,rgba(55,182,255,0.22),transparent_70%)] blur-2xl" />

      {/* rising bubbles */}
      {drops.map((d) => (
        <span
          key={d.id}
          className="bubble"
          style={{
            left: `${d.left}%`,
            width: d.size,
            height: d.size,
            animationDelay: `${d.delay}s`,
            animationDuration: `${d.dur}s`,
          }}
        />
      ))}
    </div>
  );
}
