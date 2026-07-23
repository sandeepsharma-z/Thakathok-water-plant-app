/**
 * Demo data for the dashboard, matching the approved design mockup.
 * Swap these for live queries once the retail data model is wired up.
 */

export const STATS = [
  {
    key: "orders",
    label: "Total Orders",
    value: "1,248",
    delta: "18.6%",
    up: true,
    icon: "orders",
    color: "#2f7cf6",
    tint: "#e7f0ff",
    spark: [30, 42, 38, 55, 48, 66, 60, 74, 70, 88],
  },
  {
    key: "revenue",
    label: "Total Revenue",
    value: "₹1,24,560",
    delta: "22.4%",
    up: true,
    icon: "revenue",
    color: "#1aa971",
    tint: "#e5f7ef",
    spark: [40, 44, 52, 48, 60, 58, 72, 68, 82, 90],
  },
  {
    key: "collections",
    label: "Total Collections",
    value: "₹98,750",
    delta: "20.1%",
    up: true,
    icon: "collections",
    color: "#f0a013",
    tint: "#fff3dd",
    spark: [35, 40, 38, 50, 46, 58, 55, 66, 72, 80],
  },
  {
    key: "dues",
    label: "Pending Dues",
    value: "₹25,810",
    delta: "8.3%",
    up: true,
    icon: "dues",
    color: "#ef4b6c",
    tint: "#fdeaee",
    spark: [60, 55, 62, 50, 58, 46, 52, 44, 50, 42],
  },
  {
    key: "cans",
    label: "Empty Cans",
    value: "342",
    delta: "5.6%",
    up: false,
    icon: "cans",
    color: "#9b6cf0",
    tint: "#f1eafe",
    spark: [50, 46, 54, 44, 52, 40, 48, 44, 52, 46],
  },
] as const;

export const ORDERS_TREND = [
  { day: "13 Jun", orders: 460, delivered: 210 },
  { day: "14 Jun", orders: 600, delivered: 340 },
  { day: "15 Jun", orders: 720, delivered: 330 },
  { day: "16 Jun", orders: 790, delivered: 450 },
  { day: "17 Jun", orders: 520, delivered: 300 },
  { day: "18 Jun", orders: 690, delivered: 420 },
  { day: "19 Jun", orders: 800, delivered: 470 },
];

export const ORDER_STATUS = [
  { name: "Delivered", value: 842, pct: "67.6%", color: "#1aa971" },
  { name: "Pending", value: 276, pct: "22.1%", color: "#f0a013" },
  { name: "Cancelled", value: 78, pct: "6.2%", color: "#ef4b6c" },
  { name: "Returned", value: 52, pct: "4.1%", color: "#9b6cf0" },
];

export const RECENT_ORDERS = [
  { name: "Rahul Patil", id: "#ORD1248", status: "Delivered", amt: "₹120.00", time: "10:30 AM" },
  { name: "Sunita Jadhav", id: "#ORD1247", status: "Pending", amt: "₹80.00", time: "10:15 AM" },
  { name: "Vikram Deshmukh", id: "#ORD1246", status: "Delivered", amt: "₹160.00", time: "10:10 AM" },
  { name: "Meena Kolekar", id: "#ORD1245", status: "Pending", amt: "₹120.00", time: "09:58 AM" },
  { name: "Suresh Yadav", id: "#ORD1244", status: "Delivered", amt: "₹80.00", time: "09:45 AM" },
];

export const TOP_BRANCHES = [
  { name: "Latur Branch", revenue: 35860, max: 35860 },
  { name: "Nilanga Branch", revenue: 28450, max: 35860 },
  { name: "Udgir Branch", revenue: 22780, max: 35860 },
  { name: "Ausa Branch", revenue: 18640, max: 35860 },
  { name: "Renapur Branch", revenue: 10830, max: 35860 },
];

export const CANS_SUMMARY = {
  total: "2,540",
  rows: [
    { label: "In Circulation", value: "2,120", color: "#2f7cf6" },
    { label: "With Customers", value: "1,890", color: "#1aa971" },
    { label: "In Stock", value: "230", color: "#f0a013" },
    { label: "Damaged", value: "120", color: "#ef4b6c" },
    { label: "Not Returned (7+ days)", value: "200", color: "#f0a013" },
  ],
};

export const PAYMENT_SUMMARY = {
  totalCollected: "₹98,750",
  totalDelta: "20.1%",
  breakdown: [
    { label: "Cash", value: "₹65,450", pct: "66.2%", bg: "#e5f7ef", fg: "#1aa971" },
    { label: "UPI", value: "₹23,100", pct: "23.4%", bg: "#f1eafe", fg: "#9b6cf0" },
    { label: "Other", value: "₹10,200", pct: "10.4%", bg: "#fff3dd", fg: "#f0a013" },
  ],
};

export const QUICK_ACTIONS = [
  { label: "Add Order", icon: "add-order", color: "#2f7cf6", bg: "#e7f0ff" },
  { label: "Add Customer", icon: "add-customer", color: "#1aa971", bg: "#e5f7ef" },
  { label: "Add Expense", icon: "add-expense", color: "#ef4b6c", bg: "#fdeaee" },
  { label: "Cans In/Out", icon: "cans", color: "#12b0c9", bg: "#e2f7fb" },
  { label: "Send SMS", icon: "sms", color: "#9b6cf0", bg: "#f1eafe" },
  { label: "View Reports", icon: "reports", color: "#1aa971", bg: "#e5f7ef" },
] as const;
