# Thaka Thok Water Delivery App

README Version: v1.1

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
- Codebase will be multi-branch ready. Future branches can be added from the Admin Panel without code changes for the standard branch setup.
- Basic branch creation and management will be planned in the code structure.
- Any future advanced branch-specific custom feature, separate workflow, or major customization will be handled separately if required.

## Technology Stack

- Mobile App: Flutter
- Admin Dashboard: Web-based dashboard
- Backend/API: Secure backend architecture
- Database: Structured database for customers, orders, payments, cans, staff, and reports
- Hosting/Deployment: Client-owned AWS account as discussed
- Repository: Client-owned GitHub repository

## Milestone 1 Target

The first testable version will target Customer Login, Order Flow, SMS/OTP setup, Branch Filter, and Combined Reports within 7-10 working days from payment confirmation and required access/API details shared by the client side.

## Review Process

Weekly review calls will be planned every Friday at 4:00 PM once development starts.

## SMS/OTP DLT Setup

Jio DLT can be used for SMS/OTP configuration with Fast2SMS after approval. The required details from the client side are Entity ID, Header/Sender ID, and Template IDs.

## Project Status

Initial project setup commit created.

## Developed By

Solvinex Team  
Website: https://solvinex.com  
Email: hello@solvinex.com  
LinkedIn: https://www.linkedin.com/company/solvinex  
Instagram: https://www.instagram.com/solvinex_com/
