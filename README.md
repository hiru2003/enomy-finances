# Enomy-Finances — Institutional Financial Platform

Enomy-Finances is an interactive single-page financial web application built for financial advisors to perform currency conversions, calculate multi-year investment return projections, manage client records with MySQL database persistence, and monitor system diagnostics with network failure simulation.

---

## 🚀 Quick Start & Installation

### Prerequisites
- Web Server with PHP support (XAMPP / WAMP on Windows, or built-in PHP on macOS/Linux)
- MySQL Server (v8.0+)

---

### 🪟 Windows Setup (using XAMPP)

1. **Install XAMPP** from [apachefriends.org](https://www.apachefriends.org).
2. Open XAMPP Control Panel and start **Apache** and **MySQL**.
3. Move the project folder to `C:\xampp\htdocs\enomy-finances`.
4. **Import Database:**
   - Open your browser to `http://localhost/phpmyadmin`
   - Click **Import** ➔ Select `schema.sql` ➔ Click **Go**.
5. **Configure Database Password:**
   - Open `api.php` and set `$db_pass` to your MySQL root password (default in XAMPP is empty `''`):
     ```php
     $db_pass = '';
     ```
6. **Launch App:** Open browser to `http://localhost/enomy-finances/index.html`.

---

### 🍏 macOS / Linux Setup (using Built-in PHP)

1. Open Terminal and navigate to the project directory:
   ```bash
   cd ~/Desktop/enomy-finances
   ```
2. **Import Database:**
   ```bash
   mysql -u root -p < schema.sql
   ```
3. **Configure Database Password:**
   - Open `api.php` and set `$db_pass` to your MySQL root password:
     ```php
     $db_pass = 'YOUR_MYSQL_PASSWORD';
     ```
4. **Start Web Server:**
   ```bash
   php -S localhost:8080
   ```
5. **Launch App:** Open browser to `http://localhost:8080/index.html`.

---

## 🔑 Authentication Credentials

- **Email:** `advisor@enomy.com`
- **Password:** `Finance2026!`

---

## 📂 Project Architecture

```
enomy-finances/
├── index.html   # Single-Page Frontend (HTML5, Tailwind CSS, Chart.js, Lucide, JS)
├── api.php      # Backend REST API layer (PHP PDO connecting to MySQL)
├── schema.sql   # Database Initialization Script (MySQL Schema & Baseline Seed Data)
└── README.md    # Documentation & Setup Guide
```

---

## ✨ Core Modules & Features

1. **Authentication (EFSM Logic):** Extended Finite State Machine tracking login attempts. Locks account after 3 failed attempts.
2. **Currency Converter:** Converts between 6 currencies (GBP, USD, EUR, BRL, JPY, TRY). Validates amount strictly (300 – 5,000) and applies tiered fees (3.5%, 2.7%, 2.0%, 1.5%).
3. **Savings & Investments Calculator:** 3 tiered plans with dynamic limits. Calculates compound returns, monthly fees, and tax bands for 1, 5, and 10-year timeframes with line charts.
4. **Client Database:** Full CRUD interface for client management with MySQL database persistence and local cache fallback.
5. **System Diagnostics:** Terminal console logging live system events, uptime counter, and network failure simulation.
