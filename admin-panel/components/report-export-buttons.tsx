"use client";

import { Download, FileSpreadsheet } from "lucide-react";

type BookingRow = {
  booking_code: string;
  customer_name: string;
  mobile: string;
  village: string;
  status: string;
  cans: number;
  grand_total: number;
  advance: number;
  balance: number;
  created_at: string;
};
type ExpenseRow = {
  expense_date: string;
  category: string;
  description: string;
  amount: number;
};

export function ReportExportButtons({
  month,
  label,
  summary,
  bookings,
  expenses,
  inventory,
}: {
  month: string;
  label: string;
  summary: { bookings: number; cans: number; revenue: number; collected: number; dues: number; expenses: number; margin: number };
  bookings: BookingRow[];
  expenses: ExpenseRow[];
  inventory: { total: number; available: number; out: number; damaged: number };
}) {
  async function exportPdf() {
    const [{ jsPDF }, { default: autoTable }] = await Promise.all([
      import("jspdf"),
      import("jspdf-autotable"),
    ]);
    const pdf = new jsPDF({ orientation: "landscape" });
    pdf.setFontSize(18);
    pdf.text(`Mahalakshmi Water Plant - ${label}`, 14, 16);
    pdf.setFontSize(10);
    pdf.text(`Generated: ${new Date().toLocaleString("en-IN")}`, 14, 23);
    autoTable(pdf, {
      startY: 29,
      head: [["Bookings", "Cans", "Revenue", "Collected", "Pending dues", "Expenses", "Margin"]],
      body: [[summary.bookings, summary.cans, `Rs.${summary.revenue}`, `Rs.${summary.collected}`, `Rs.${summary.dues}`, `Rs.${summary.expenses}`, `Rs.${summary.margin}`]],
      theme: "grid",
      headStyles: { fillColor: [0, 79, 218] },
    });
    autoTable(pdf, {
      startY: (pdf as unknown as { lastAutoTable: { finalY: number } }).lastAutoTable.finalY + 8,
      head: [["Booking ID", "Customer", "Mobile", "Village", "Status", "Cans", "Total", "Advance", "Balance"]],
      body: bookings.map((b) => [b.booking_code, b.customer_name, b.mobile, b.village, b.status, b.cans, `Rs.${b.grand_total}`, `Rs.${b.advance}`, `Rs.${b.balance}`]),
      styles: { fontSize: 8 },
      theme: "striped",
      headStyles: { fillColor: [18, 133, 90] },
    });
    if (expenses.length) {
      pdf.addPage();
      pdf.setFontSize(15);
      pdf.text("Expenses", 14, 16);
      autoTable(pdf, {
        startY: 22,
        head: [["Date", "Category", "Description", "Amount"]],
        body: expenses.map((e) => [e.expense_date, e.category, e.description || "-", `Rs.${e.amount}`]),
        theme: "striped",
        headStyles: { fillColor: [240, 160, 19] },
      });
    }
    pdf.save(`monthly-report-${month}.pdf`);
  }

  function exportExcel() {
    const esc = (value: unknown) =>
      String(value ?? "").replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");
    const row = (cells: unknown[], header = false) =>
      `<tr>${cells.map((cell) => `<${header ? "th" : "td"}>${esc(cell)}</${header ? "th" : "td"}>`).join("")}</tr>`;
    const html = `<!doctype html><html xmlns:x="urn:schemas-microsoft-com:office:excel"><head><meta charset="UTF-8"></head><body>
      <h1>Mahalakshmi Water Plant - ${esc(label)}</h1>
      <h2>Summary</h2><table border="1">${row(["Bookings","Cans","Revenue","Collected","Pending dues","Expenses","Margin"],true)}${row([summary.bookings,summary.cans,summary.revenue,summary.collected,summary.dues,summary.expenses,summary.margin])}</table>
      <h2>Bookings</h2><table border="1">${row(["Booking ID","Customer","Mobile","Village","Status","Cans","Total","Advance","Balance","Created"],true)}${bookings.map((b)=>row([b.booking_code,b.customer_name,b.mobile,b.village,b.status,b.cans,b.grand_total,b.advance,b.balance,new Date(b.created_at).toLocaleString("en-IN")])).join("")}</table>
      <h2>Expenses</h2><table border="1">${row(["Date","Category","Description","Amount"],true)}${expenses.map((e)=>row([e.expense_date,e.category,e.description,e.amount])).join("")}</table>
      <h2>Current Inventory</h2><table border="1">${row(["Total","Available","Out","Damaged"],true)}${row([inventory.total,inventory.available,inventory.out,inventory.damaged])}</table>
      </body></html>`;
    const blob = new Blob(["\ufeff", html], { type: "application/vnd.ms-excel;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = `monthly-report-${month}.xls`;
    anchor.click();
    URL.revokeObjectURL(url);
  }

  const cls = "inline-flex h-11 items-center gap-2 rounded-xl px-4 text-[12px] font-extrabold transition";
  return (
    <div className="flex flex-wrap gap-2">
      <button type="button" onClick={exportPdf} className={`${cls} bg-danger text-white hover:brightness-105`}><Download className="h-4 w-4" />Export PDF</button>
      <button type="button" onClick={exportExcel} className={`${cls} bg-ok text-white hover:brightness-105`}><FileSpreadsheet className="h-4 w-4" />Export Excel</button>
    </div>
  );
}

