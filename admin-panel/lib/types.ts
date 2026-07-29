export type BookingStatus =
  | "pending"
  | "confirmed"
  | "cancelled"
  | "delivered";

export type PaymentMethod = "online" | "cash" | "wallet";

export interface Booking {
  id: string;
  booking_code: string;
  customer_name: string;
  event_type: string;
  cans: number;
  per_can_rate: number;
  subtotal: number;
  delivery_charge: number;
  grand_total: number;
  advance: number;
  balance: number;
  fully_paid_at: string | null;
  all_done_at: string | null;
  all_done_by: string | null;
  village: string;
  mobile: string;
  address: string;
  event_date: string; // YYYY-MM-DD
  event_time: string; // "10:30 AM"
  payment_method: PaymentMethod;
  offer_code: string | null;
  offer_discount_percent: number;
  discount_amount: number;
  status: BookingStatus;
  cancellation_reason: string | null;
  cancelled_at: string | null;
  cancelled_by: string | null;
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
  razorpay_key_id: string;
  razorpay_key_secret: string;
  fast2sms_api_key: string;
  sms_template_order: string;
  sms_template_delivery: string;
  sms_template_dues: string;
  sms_template_cash_alert: string;
  offer_enabled: boolean;
  offer_title: string;
  offer_description: string;
  offer_code: string;
  offer_discount_percent: number;
  offer_min_subtotal: number;
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
