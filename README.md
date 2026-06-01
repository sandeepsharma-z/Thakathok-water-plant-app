# Thaka Thok Water Delivery App

Thaka Thok Water Delivery App is a complete water plant delivery management system developed for managing customer orders, pending payments, empty jar/can returns, delivery staff updates, admin approval, and delivery workflow in one centralized platform.

## Project Modules

1. Customer Mobile App
2. Admin Dashboard
3. Delivery Staff Panel
4. Backend API
5. Database Setup
6. Deployment Setup
7. Documentation & Handover

## Main Features

### Customer App

- Mobile OTP login
- Customer profile management
- Water jar/can order placement
- Order status tracking
- Pending payment visibility
- Pending empty jar/can visibility
- Next order restriction if previous dues or cans are pending

### Admin Dashboard

- Customer management
- Delivery area management
- Product/rate management
- Order management
- Delivery staff management
- Pending payment tracking
- Empty jar/can tracking
- Monthly dues report
- Customer-wise order/payment history
- Admin "All Done" approval process

### Delivery Staff Panel

- Delivery staff login
- Assigned order visibility
- Delivery status updates
- Payment collection update
- Empty jar/can return update
- Route/order visibility
- Daily delivery workflow

## Phase 1 Aadhaar Number Duplicate Check

- Aadhaar number-based duplicate check and pending dues tracking for water delivery
- No Aadhaar eKYC/API integration involved
- If a customer registers again with another mobile number but the same Aadhaar number, previous pending dues and empty can records will remain linked
- Customers with pending dues or pending empty cans cannot place another order until previous records are cleared and verified
- The same app structure can support additional branches/business locations in the future with proper configuration

## Technology Stack

- Mobile App: Flutter
- Admin Dashboard: Web-based dashboard
- Backend/API: Secure backend architecture
- Database: Structured database for customers, orders, payments, cans, staff, and reports
- Hosting/Deployment: Client-owned AWS account as discussed
- Repository: Client-owned GitHub repository

## Project Status

Initial project setup commit created.

## Developed By

Solvinex Team  
Website: https://solvinex.com  
Email: hello@solvinex.com  
LinkedIn: https://www.linkedin.com/company/solvinex  
Instagram: https://www.instagram.com/solvinex_com/
