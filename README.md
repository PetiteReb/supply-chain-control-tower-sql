# Supply Chain Control Tower SQL Data Warehouse (IN PROGRESS)

Building a supply-chain analytics warehouse from raw data to business KPIs: **CSV → PostgreSQL staging → star schema → analysis-ready KPIs**, with a Power BI dashboard layer on top.

## Business Context

Supply chain teams need a "control tower": one place to monitor orders, delays and shipping performance. Drawing on my experience in aerospace supply chain (Airbus, Toulouse), this project rebuilds that logic end-to-end on a public dataset  including the transparent, reproducible SQL layer a real BI team needs *behind* the dashboard.

## Dataset

- **DataCo Smart Supply Chain**  public dataset ([Kaggle](https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis))
- **180,519 order lines**, 53 columns: orders, customers, products, geography, shipping performance
- The raw CSV (~95 MB) is not committed (see `.gitignore`)  download it from Kaggle into `data/raw/`

## Architecture

```
DataCoSupplyChainDataset.csv     raw file (ISO-8859-1)
        │   COPY ... ENCODING 'LATIN1'
        ▼
staging.raw_orders               1:1 copy, all TEXT — load fidelity first
        │   typing · cleaning · conforming
        ▼
warehouse.*                      star schema: fact_order_items + dimensions
        │
        ▼
analysis views & KPIs   ───►     Power BI dashboard
```

**Why an all-TEXT staging layer?** Loading the raw file as-is guarantees ingestion never fails on a bad value. Every typing and cleaning decision then happens downstream in SQL  explicit, testable, and versioned, instead of hidden in a loader.

## Tech Stack

PostgreSQL 16 (Docker) · SQL · DBeaver · Power BI · Git

## Project Structure

```
supply-chain-control-tower-sql/
├── docker-compose.yml        # PostgreSQL 16, reproducible local setup
├── data/raw/                 # Source CSV (git-ignored)
├── docs/                     # Data dictionary
└── sql/
    ├── 01_schema/            # Staging DDL + raw load
    ├── 02_transform/         # Star schema build (in progress)
    ├── 03_quality/           # Data quality checks (planned)
    └── 04_analysis/          # KPI queries (planned)
```

## Roadmap

- [x] **Environment**  PostgreSQL 16 in Docker, one-command setup
- [x] **Staging layer** raw schema + `COPY` load with LATIN1 encoding handling  **180,519 rows loaded and verified**
- [ ] **Star schema**  `dim_date`, `dim_customer`, `dim_product`, `dim_geography`, `dim_shipping_mode`, `fact_order_items`
- [ ] **Data quality checks** row counts, orphan keys, duplicates
- [ ] **KPI queries**  on-time delivery %, real vs scheduled shipping days, profitability
- [ ] **Power BI dashboard**  delivery-performance control tower (built in parallel, will be added here)

## How to Run

1. Start the database (host port **5544** to avoid clashing with a native PostgreSQL):

```bash
docker compose up -d
```

2. Create the staging schema  run `sql/01_schema/01_staging.sql` (e.g. in DBeaver, connected to `localhost:5544`, db `control_tower`).

3. Load the raw data:

```bash
docker cp "data/raw/DataCoSupplyChainDataset.csv" control_tower_db:/tmp/orders.csv
```

then run `sql/01_schema/02_load_staging.sql`.

## About Me

**Rebecca Olivier**  Data & Analytics Consultant
Aerospace & supply chain background (Airbus, Bombardier, Thales) · relocating to Ontario, Canada 🇨🇦
[LinkedIn](https://linkedin.com/in/rebeccaolivier-/) · rebecca.olivier28@gmail.com
