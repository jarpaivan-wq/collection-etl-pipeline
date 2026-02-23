# SQL Analytics Portfolio

![SQL](https://img.shields.io/badge/SQL-MySQL%20|%20SQLite-blue)
![Experience](https://img.shields.io/badge/Experience-12%20Years-green)
![Projects](https://img.shields.io/badge/Projects-7-orange)

## About Me

**Senior BI Analyst** with 12+ years of experience in data analytics, specializing in SQL development, business intelligence, and process automation. Proven track record of delivering measurable results:

- 📊 **300K+ records** processed monthly
- ⚡ **60-96% time reductions** through automation
- 💼 **12 years** of hands-on data analysis experience
- 🎓 **MBA** in Business Administration

Currently transitioning to freelance SQL analysis work, seeking opportunities in fintech, scale-ups, and data-driven organizations.

## Portfolio Projects

This repository contains **7 complete SQL projects** demonstrating real-world analytics capabilities across multiple industries. Each project includes schema design, sample data, and analytical queries solving specific business problems.

### 📦 1. E-Commerce Analytics
**Files:** `ecommerce_01_schema.sql`, `ecommerce_02_data.sql`, `ecommerce_03_queries.sql`

**Business Problem:** Track customer behavior, product performance, and revenue metrics for online retail operations.

**Key Features:**
- Customer segmentation and RFM analysis
- Product category performance tracking
- Order fulfillment metrics
- Revenue trend analysis

**SQL Techniques:**
- Window functions for ranking
- Date functions for cohort analysis
- Aggregate functions for KPIs
- JOINs across multiple tables

---

### 💼 2. HR & Talent Management (TalentCore)
**Files:** `hr_talentcore_01_schema.sql`, `hr_talentcore_02_sample_data.sql`, `hr_talentcore_03_queries.sql`

**Business Problem:** Manage employee data, track performance reviews, and analyze compensation trends.

**Key Features:**
- Employee hierarchy and reporting structures
- Performance evaluation tracking
- Salary analysis and compensation planning
- Department-level metrics

**SQL Techniques:**
- Self-joins for organizational hierarchies
- Subqueries for complex filtering
- Aggregate functions for compensation analysis
- Date calculations for tenure metrics

---

### 🏋️ 3. Gym Membership Management
**Files:** `gym_01_schema.sql`, `gym_02_data.sql`, `gym_03_queries.sql`

**Business Problem:** Track member attendance, class bookings, and revenue from memberships and classes.

**Key Features:**
- Membership lifecycle analysis
- Class attendance tracking
- Revenue forecasting
- Member retention metrics

**SQL Techniques:**
- Time-series analysis
- Retention rate calculations
- Revenue aggregation
- Active vs. expired membership tracking

---

### 🍽️ 4. Restaurant Operations
**Files:** `restaurant_01_schema.sql`, `restaurant_02_sample_data.sql`, `restaurant_03_queries.sql`

**Business Problem:** Optimize menu performance, track table turnover, and analyze staff efficiency.

**Key Features:**
- Menu item profitability analysis
- Peak hours identification
- Server performance metrics
- Customer visit patterns

**SQL Techniques:**
- GROUP BY with HAVING clauses
- Percentage calculations
- Time-based aggregations
- Multi-table JOINs

---

### 💳 5. SaaS Subscription Analytics
**Files:** `saas_01_schema.sql`, `saas_02_sample_data.sql`, `saas_03_queries.sql`

**Business Problem:** Monitor subscription metrics, calculate MRR/ARR, and identify churn risks.

**Key Features:**
- Monthly Recurring Revenue (MRR) tracking
- Churn analysis and prediction
- Customer lifetime value (LTV)
- Subscription tier performance

**SQL Techniques:**
- CTEs for complex metrics
- CASE statements for categorization
- Date arithmetic for subscription periods
- Cohort analysis

---

### 💰 6. Collections Management ETL Pipeline
**Files:** `collections_01_schema.sql`, `collections_02_sample_data.sql`, `collections_03_analytical_query.sql`

**Business Problem:** Daily processing of debt collections portfolio with automated activity tracking and KPI generation for 700+ accounts.

**Key Features:**
- Automated CSV import workflow
- Multi-channel activity tracking (phone, email, field visits)
- Contact quality classification
- Portfolio risk assessment
- Executive reporting (80+ column output)

**Real-World Context:**
This project demonstrates **production-grade SQL** designed for business integration rather than theoretical optimization. The 80+ column structure exists to meet:
- Legacy system requirements
- Regulatory compliance needs
- Multi-department reporting
- BI tool integration

**SQL Techniques:**
- Advanced CTEs with multiple levels
- Window functions (ROW_NUMBER with complex ordering)
- Defensive NULL handling with COALESCE
- Conditional aggregation (CASE within COUNT)
- Date transformation (DD/MM/YYYY to ISO)
- LEFT JOINs with comprehensive NULL strategies

**Daily Workflow:**
```sql
-- 1. Clear staging tables
DELETE FROM stg_collections_activity;
DELETE FROM stg_account_assignment;

-- 2. Import CSV files via DBeaver
-- 3. Execute analytical query
-- 4. Export to BI dashboard
```

**Performance:**
- Processes 700+ accounts in <1 second
- View-based pre-aggregation
- Single LEFT JOIN in final query

---

### 🎯 7. [Future Project Placeholder]
Coming soon: Additional analytics projects showcasing different SQL capabilities.

---

## Core Competencies

### SQL Skills
- **Query Optimization:** Complex joins, subqueries, CTEs, window functions
- **Data Modeling:** Schema design, normalization, indexing strategies
- **ETL Development:** Data transformation pipelines, CSV imports, data validation
- **Analytical Functions:** Aggregations, rankings, cohort analysis, KPI calculations
- **Database Systems:** MySQL (primary), SQLite, SQL Server

### Business Intelligence
- **Power BI:** Dashboard development, DAX formulas, data modeling
- **Excel:** Power Query, Power Pivot, VBA automation
- **Python/Pandas:** Data transformation and automation (developing)

### Industry Experience
- Collections & Debt Recovery (12 years)
- Financial Services
- Process Automation
- Operational Analytics
- Executive Reporting

## Project Methodology

Each project in this portfolio follows a consistent structure:

1. **Schema (`_01_schema.sql`):**
   - Table definitions with proper data types
   - Primary and foreign key constraints
   - Indexes for performance
   - Views for analytical abstractions

2. **Sample Data (`_02_data.sql` or `_02_sample_data.sql`):**
   - Realistic test datasets
   - Edge cases covered
   - Sufficient volume for meaningful queries

3. **Analytical Queries (`_03_queries.sql` or `_03_analytical_query.sql`):**
   - Business-focused questions
   - Progressively complex queries
   - Commented explanations
   - Performance considerations

## Technical Approach

### Philosophy
**"Production-ready code over textbook perfection"**

My projects demonstrate:
- ✅ Real business requirements (sometimes messy)
- ✅ Defensive coding (explicit NULL handling)
- ✅ Clear documentation (business context + technical notes)
- ✅ Proven reliability (tested in production environments)
- ✅ Performance awareness (indexing, optimization)

### Why This Portfolio Is Different

Most SQL portfolios show clean queries on perfect data. Mine shows:
- Working with CSV imports (daily reality for analysts)
- Meeting inflexible reporting requirements
- Handling missing/dirty data gracefully
- Balancing readability with performance
- Documenting business logic, not just technical syntax

**This is what data analysis actually looks like in production.**

## How to Use This Repository

### Prerequisites
- MySQL 8.0+ or SQLite 3.x
- SQL client (MySQL Workbench, DBeaver, DataGrip, or similar)

### Running a Project

```bash
# 1. Choose a project (e.g., ecommerce)
# 2. Create database
mysql -u root -p -e "CREATE DATABASE ecommerce_analytics;"

# 3. Run schema
mysql -u root -p ecommerce_analytics < ecommerce_01_schema.sql

# 4. Load sample data
mysql -u root -p ecommerce_analytics < ecommerce_02_data.sql

# 5. Execute analytical queries
mysql -u root -p ecommerce_analytics < ecommerce_03_queries.sql
```

For SQLite projects (Collections):
```bash
sqlite3 collections.db < collections_01_schema.sql
sqlite3 collections.db < collections_02_sample_data.sql
sqlite3 collections.db < collections_03_analytical_query.sql
```

## Key Achievements

### Process Improvements
- **96% time reduction** in monthly reporting (manual → automated)
- **60% time reduction** in data validation workflows
- **300K+ records** processed monthly with zero errors

### Technical Deliverables
- Automated ETL pipelines reducing manual work from days to hours
- Executive dashboards serving C-level stakeholders
- Data quality frameworks ensuring 99%+ accuracy
- Cross-functional analytics supporting multiple departments

## What I'm Looking For

**Freelance/Contract Opportunities:**
- SQL analysis and optimization projects
- ETL pipeline development
- Business intelligence implementations
- Data quality and validation
- Financial/collections analytics

**Ideal Engagements:**
- Fintech companies
- Scale-ups needing data infrastructure
- Organizations valuing experience over formal CS degrees
- Remote-first teams

## Contact

- 💼 **LinkedIn:** [Connect for opportunities]
- 🐱 **GitHub:** You're here!
- 📧 **Email:** [Available upon request]

## Repository Stats

- **Total Projects:** 7
- **SQL Files:** 21
- **Lines of Code:** 2,000+
- **Industries Covered:** 6
- **Database Systems:** MySQL, SQLite

---

## License

All code in this repository is provided for educational and portfolio demonstration purposes. Sample data is fictional and generated for testing.

---

**Last Updated:** February 2026

*This portfolio demonstrates 12 years of real-world SQL experience. Each project solves actual business problems I've encountered in my career, with sanitized data and generalized contexts for public sharing.*
