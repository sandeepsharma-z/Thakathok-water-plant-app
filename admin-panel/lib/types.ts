export type BookingStatus =
  | "pending"
  | "confirmed"
  | "cancelled"
  | "delivered";

export type PaymentMethod = "online" | "cash";

export interface Booking {
  id: string;
  booking_code: string;
  event_type: string;
  cans: number;
  per_can_rate: number;
  subtotal: number;
  delivery_charge: number;
  grand_total: number;
  advance: number;
  balance: number;
  village: string;
  mobile: string;
  address: string;
  event_date: string; // YYYY-MM-DD
  event_time: string; // "10:30 AM"
  payment_method: PaymentMethod;
  status: BookingStatus;
  created_at: string;
}

export interface Settings {
  id: number;
  per_can_rate: number;
  delivery_charge: number;
  delivery_free_threshold: number;
  free_delivery_village: string;
  plant_name: string;
  plant_phone: string;
  updated_at: string;
}

export const rupees = (n: number) => `₹${n.toLocaleString("en-IN")}`;

export const formatDate = (iso: string) => {
  const d = new Date(`${iso}T00:00:00`);
  if (Number.isNaN(d.getTime())) return iso;
  return d.toLocaleDateString("en-IN", {
    day: "numeric",
    month: "short",
    year: "numeric",
  });
};
