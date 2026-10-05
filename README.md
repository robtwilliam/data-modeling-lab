# Data Modeling Strategies Lab

A local data-engineering project for practicing and comparing three enterprise data modeling approaches:

- **Inmon**
- **Kimball**
- **Data Vault 2.0**

The project uses synthetic retail data and a local stack built around PostgreSQL, PySpark, and Parquet. The same source data is ingested into a Bronze layer, modeled three different ways in Silver, and then queried into comparable Gold-layer outputs.

The goal is to make the tradeoffs between the three modeling strategies concrete rather than purely theoretical.

---

## Project Goals

This project demonstrates how the same business data can be modeled using different warehouse design philosophies.

It focuses on:

- Building a local lakehouse-style workflow with PostgreSQL, PySpark, and Parquet
- Creating a normalized **Inmon-style enterprise model**
- Creating a **Kimball dimensional model** with facts, dimensions, surrogate keys, and SCD Type 2 history
- Creating a **Data Vault 2.0 model** with Hubs, Links, Satellites, hash keys, and historization
- Building equivalent Gold-layer business outputs from each Silver-layer model
- Comparing the strengths, weaknesses, and best-fit use cases of each approach

---

## Architecture

The project follows this high-level flow:

```text
PostgreSQL source systems
        |
        v
PySpark JDBC ingestion
        |
        v
Bronze Parquet layer
        |
        +---------------------+---------------------+
        |                     |                     |
        v                     v                     v
   Inmon Silver          Kimball Silver       Data Vault Silver
   normalized 3NF        facts/dimensions      hubs/links/satellites
        |                     |                     |
        +---------------------+---------------------+
                              |
                              v
                        Gold comparison
```

The synthetic PostgreSQL source systems are organized into three schemas:

- `crm`
- `sales`
- `erp`

Source tables include:

- `crm.customers`
- `sales.orders`
- `sales.order_items`
- `erp.products`

---

## Project Structure

```text
.
├── data/
├── notebooks/
│   ├── bronze_layer_ingestion.ipynb
│   ├── data_vault_cust_history.ipynb
│   ├── data_vault_silver.ipynb
│   ├── gold_layer_summary.ipynb
│   ├── inmon_silver_layer.ipynb
│   ├── kimball_scd2.ipynb
│   └── kimball_silver_layer.ipynb
├── requirements.txt
└── scripts/
    ├── postgre_development/
    │   ├── customers_create.sql
    │   ├── customers_insert.sql
    │   ├── order_items_create.sql
    │   ├── order_items_insert.sql
    │   ├── orders_create.sql
    │   ├── orders_insert.sql
    │   ├── products_create.sql
    │   ├── products_insert.sql
    │   └── schemas_create.sql
    └── scd2_scenario/
        └── update_customer_information.sql
```

The `data/` directory is populated by the notebooks as Parquet datasets are created.

---

## Prerequisites

The project was developed with:

- Python 3
- PySpark **3.5.4**
- PostgreSQL
- Java compatible with Spark 3.5.x
- Jupyter or VS Code notebook support

The exact Python dependencies are listed in `requirements.txt`.

---

## 1. Clone the Repository

```bash
git clone <repository-url>
cd data-modeling-lab
```

---

## 2. Create a Virtual Environment

Create a project-specific Python environment:

```bash
python3 -m venv .venv
```

Activate it:

```bash
source .venv/bin/activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

If using VS Code or Jupyter, make sure the notebook kernel points to the Python interpreter inside `.venv`.

You can verify the active interpreter with:

```python
import sys
print(sys.executable)
```

---

## 3. Configure Environment Variables

Create a local environment file based on the sample environment file included with the repository.

For example:

```bash
cp env.sample .env
```

Update `.env` with your local PostgreSQL settings.

Example:

```text
POSTGRES_USER=your_postgres_username
POSTGRES_URL=jdbc:postgresql://localhost:5432/data_modeling_lab
```

If your PostgreSQL instance requires a password, add:

```text
POSTGRES_PASSWORD=your_postgres_password
```

The real `.env` file should remain excluded from Git.

---

## 4. Start PostgreSQL

Make sure your local PostgreSQL server is running before continuing.

A simple readiness check is:

```bash
pg_isready
```

A successful result should indicate that PostgreSQL is accepting connections on port `5432`.

---

## 5. Create the Development Database

Create the project database:

```bash
createdb data_modeling_lab
```

Connect to it:

```bash
psql data_modeling_lab
```

You can verify the connection with:

```sql
SELECT current_database();
```

---

## 6. Create the Source Schemas

Run:

```bash
psql data_modeling_lab -f scripts/postgre_development/schemas_create.sql
```

This creates the source schemas used by the project:

```text
crm
sales
erp
```

---

## 7. Create the Source Tables

Run the table creation scripts:

```bash
psql data_modeling_lab -f scripts/postgre_development/customers_create.sql
psql data_modeling_lab -f scripts/postgre_development/orders_create.sql
psql data_modeling_lab -f scripts/postgre_development/order_items_create.sql
psql data_modeling_lab -f scripts/postgre_development/products_create.sql
```

---

## 8. Load the Synthetic Source Data

Run:

```bash
psql data_modeling_lab -f scripts/postgre_development/customers_insert.sql
psql data_modeling_lab -f scripts/postgre_development/orders_insert.sql
psql data_modeling_lab -f scripts/postgre_development/order_items_insert.sql
psql data_modeling_lab -f scripts/postgre_development/products_insert.sql
```

At this point the PostgreSQL source system is ready.

---

## 9. Run the Bronze Ingestion Notebook

Open:

```text
notebooks/bronze_layer_ingestion.ipynb
```

This notebook:

1. Creates a Spark session
2. Connects to PostgreSQL through JDBC
3. Reads the CRM, Sales, and ERP source tables
4. Writes the source data into the local Bronze Parquet layer

The PostgreSQL JDBC package used by the project is:

```text
org.postgresql:postgresql:42.7.4
```

The Bronze outputs are written beneath:

```text
data/bronze/
```

At this point, the Bronze layer represents the original source state before any customer-history scenario is introduced.

---

## 10. Build the Inmon Silver Layer

Run:

```text
notebooks/inmon_silver_layer.ipynb
```

This notebook builds a normalized enterprise model containing entities such as:

```text
Customer
Order
Order Item
Product
```

The model emphasizes:

- normalized enterprise entities
- reduced redundancy
- relational integrity
- separation of business concepts

Outputs are written beneath:

```text
data/inmon/
```

---

## 11. Build the Kimball Silver Layer

Run:

```text
notebooks/kimball_silver_layer.ipynb
```

This notebook models the Sales business process using a dimensional star schema.

The grain of the fact table is:

> One row per product per order.

The model includes:

```text
fact_sales
dim_customer
dim_product
dim_date
```

Concepts demonstrated include:

- dimensional modeling
- fact-table grain
- surrogate keys
- degenerate dimensions
- additive measures
- date dimensions

Outputs are written beneath:

```text
data/kimball/
```

---

## 12. Build the Data Vault Silver Layer

Run:

```text
notebooks/data_vault_silver.ipynb
```

This notebook builds the baseline Data Vault 2.0 model using:

### Hubs

```text
hub_customer
hub_order
hub_product
```

### Links

```text
link_customer_order
link_order_product
```

### Satellites

```text
sat_customer
sat_order
sat_product
sat_order_product
```

The project uses deterministic MD5 hashes for Data Vault technical keys and hashdiffs.

Concepts demonstrated include:

- business keys
- Hub hash keys
- Link hash keys
- descriptive Satellites
- Link Satellites
- record source metadata
- load timestamps
- hashdiff-based change detection

Outputs are written beneath:

```text
data/data_vault/
```

At this stage, all three Silver-layer approaches represent the same original business data.

---

## 13. Apply the Customer Attribute Change Scenario

After the baseline Bronze and Silver layers have been created, introduce a source-system change:

```bash
psql data_modeling_lab -f scripts/scd2_scenario/update_customer_information.sql
```

This script changes a customer attribute in PostgreSQL so that the project can demonstrate how Kimball and Data Vault handle history differently.

After applying the SQL update, re-run the CRM customer ingestion portion of:

```text
notebooks/bronze_layer_ingestion.ipynb
```

The Bronze customer dataset should now reflect the updated source value.

Do **not** rebuild the baseline Silver models before running the history exercises. The existing Silver state is intentionally preserved so that each approach can detect and historize the incoming change.

---

## 14. Run the Kimball SCD Type 2 Exercise

Run:

```text
notebooks/kimball_scd2.ipynb
```

This notebook compares the changed Bronze customer record against the existing Kimball customer dimension and demonstrates SCD Type 2 processing.

The exercise:

1. Identifies changed dimension attributes
2. Expires the previous dimension row
3. Generates a new surrogate key
4. Inserts a new current dimension version
5. Preserves both historical states

For example, a customer may retain the same business key:

```text
customer_id = 1001
```

while receiving multiple warehouse surrogate keys:

```text
customer_key = 1   -> historical version
customer_key = 6   -> current version
```

The dimension uses:

```text
effective_from
effective_to
is_current
```

to represent historical validity.

The key Kimball concept is:

> The business key stays the same, while each historical dimension version receives its own surrogate key.

---

## 15. Run the Data Vault Customer History Exercise

Run:

```text
notebooks/data_vault_cust_history.ipynb
```

This notebook processes the **same customer attribute change** using the existing Data Vault structures.

Unlike Kimball SCD Type 2, the customer Hub key does not change.

Instead:

1. The existing customer Hub remains unchanged
2. A new Satellite hashdiff is generated from the changed descriptive attributes
3. The new hashdiff is compared with existing Satellite history
4. A new Satellite version is added only when a descriptive change is detected

Conceptually:

```text
hub_customer
    |
    +--> sat_customer: historical version
    |
    +--> sat_customer: new version
```

The key Data Vault concept is:

> The stable business identity remains in the Hub while descriptive history accumulates in the Satellite.

Running the Kimball and Data Vault history notebooks back-to-back demonstrates how both approaches preserve the same source-system change using fundamentally different modeling patterns.

---

## 16. Build and Compare the Gold Layer

Finally run:

```text
notebooks/gold_layer_summary.ipynb
```

This notebook defines one common reporting requirement and reconstructs the same business-friendly Gold dataset from all three Silver-layer approaches.

The target Gold grain is:

> One row per product per order.

Example output fields include:

```text
order_id
order_date
customer_id
customer_name
customer_state
product_id
product_name
category
quantity
unit_price
line_amount
```

The Gold result is built independently from:

- the Inmon normalized model
- the Kimball dimensional model
- the Data Vault model

This final comparison demonstrates that the three Silver-layer strategies organize and historize data differently, while each can ultimately support the same downstream analytical requirement.

The comparison also highlights the practical query differences:

- **Inmon** reconstructs the Gold output from normalized enterprise entities
- **Kimball** starts from an analytics-ready fact table and joins dimensions
- **Data Vault** reconstructs the business view across Hubs, Links, and Satellites

---

## Recommended Execution Order

For a clean end-to-end run, use this sequence:

```text
1. Create PostgreSQL database and schemas
2. Create and populate synthetic source tables
3. Run bronze_layer_ingestion.ipynb
4. Run inmon_silver_layer.ipynb
5. Run kimball_silver_layer.ipynb
6. Run data_vault_silver.ipynb
7. Run update_customer_information.sql
8. Re-ingest the changed CRM customer data into Bronze
9. Run kimball_scd2.ipynb
10. Run data_vault_cust_history.ipynb
11. Run gold_layer_summary.ipynb
```

This ordering is intentional:

```text
Original Source State
        |
        v
      Bronze
        |
        +----------+----------+
        |          |          |
      Inmon     Kimball   Data Vault
      Silver     Silver     Silver
        |          |          |
        +----------+----------+
                   |
        Customer Attribute Change
                   |
              Updated Bronze
                   |
          +--------+--------+
          |                 |
     Kimball SCD2     Data Vault History
          |                 |
          +--------+--------+
                   |
                   v
              Gold Comparison
```

# Modeling Strategy Comparison

## Inmon

### Best suited for

- centralized enterprise data warehouses
- highly normalized enterprise models
- strong governance and integration requirements
- organizations that want an EDW before downstream marts

### Advantages

- strong enterprise consistency
- reduced redundancy through normalization
- clear relational entity structure
- good foundation for multiple downstream analytical models

### Tradeoffs

- analytics often require more joins
- less intuitive for direct BI consumption
- reporting commonly requires a downstream dimensional layer
- centralized enterprise modeling can become complex

---

## Kimball

### Best suited for

- BI and analytics
- dashboards
- self-service reporting
- business-process-oriented analytical models

### Advantages

- intuitive fact-and-dimension structure
- fewer joins for analytical queries
- strong alignment with business questions
- effective handling of historical reporting through SCD patterns

### Tradeoffs

- surrogate-key management must be reliable
- SCD Type 2 processing adds ETL complexity
- descriptive dimension data is intentionally denormalized
- separate business processes generally require separate fact tables

---

## Data Vault 2.0

### Best suited for

- complex enterprise integration
- many changing source systems
- auditability and lineage requirements
- frequent schema or source-system change
- long-term historical preservation

### Advantages

- strong historization
- deterministic technical keys
- excellent lineage and auditability
- easy extension through additional Hubs, Links, and Satellites
- separation of business identity, relationships, and descriptive attributes

### Tradeoffs

- significantly more tables
- direct analytical queries require many joins
- historical Satellite querying requires version-resolution logic
- PIT and Bridge structures may be needed for efficient Business Vault querying
- normally requires an additional consumption layer for BI

---

## Key Mental Models

### Inmon

> What are the enterprise entities, and how should they be normalized?

### Kimball

> What business process are we analyzing, what is its grain, and what facts and dimensions describe it?

### Data Vault

> What are the stable business identities, how are they related, and how do their descriptive attributes change over time?

---

## PIT and Bridge Concepts

This project does not implement PIT or Bridge tables, but they are important Data Vault Business Vault concepts.

### PIT — Point-In-Time

A PIT table helps identify which Satellite version was valid for a Hub at a particular point in time.

Think:

> Which version was valid then?

### Bridge

A Bridge pre-resolves paths across multiple Links or complex relationships.

Think:

> How are these business entities connected?

A Link represents an actual business relationship, while a Bridge is a derived helper structure used to simplify traversal across relationships.

---

## Practical Takeaway

These modeling strategies do not have to be mutually exclusive.

A modern analytical architecture could use:

```text
Source Systems
    |
    v
Bronze / Raw
    |
    v
Data Vault or normalized enterprise integration
    |
    v
Business transformations
    |
    v
Kimball dimensional Gold layer
    |
    v
Tableau / Power BI / Analytics
```

In that architecture:

- **Inmon or Data Vault** supports enterprise integration
- **Kimball** supports analytical consumption

The most important architectural decision is often not which methodology is universally best, but which modeling strategy is best suited to each layer and business requirement.

---

## Notes

- All project data is synthetic.
- Local database credentials and environment-specific configuration should remain outside source control.
- Generated Parquet data can be recreated by following the execution order above.
