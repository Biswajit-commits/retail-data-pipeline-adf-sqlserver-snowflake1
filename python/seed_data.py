"""
FILE: sql_server/02_seed_data.py
PURPOSE: Generate realistic retail data and load into SQL Server (RetailDB)
REQUIRES: pip install pyodbc pandas numpy faker
RUN AFTER: 01_create_tables.sql
"""

import pyodbc
import pandas as pd
import numpy as np
from faker import Faker
from datetime import timedelta
import random

# ── CONFIG — update before running ──────────────────────────────────────────
CONN_STR = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost;"          # or your server name
    "DATABASE=RetailDB;"
    "UID=sa;"
    "PWD=YourPasswordHere;"      # replace with your SA password
    # For Windows Auth instead: "Trusted_Connection=yes;"
)
SEED        = 42
N_CUSTOMERS = 500
N_PRODUCTS  = 200
N_ORDERS    = 2000
# ────────────────────────────────────────────────────────────────────────────

fake = Faker("en_IN")
random.seed(SEED)
np.random.seed(SEED)
Faker.seed(SEED)

CATEGORIES   = ["Electronics", "Clothing", "Home & Garden", "Sports", "Books", "Beauty"]
BRANDS       = ["BrandA", "BrandB", "BrandC", "BrandD", "BrandE"]
DEPARTMENTS  = ["Men", "Women", "Unisex", "Kids"]
ORDER_STATUS = ["complete", "shipped", "processing", "returned", "cancelled"]


# ── generators ───────────────────────────────────────────────────────────────

def generate_customers():
    rows = []
    for i in range(1, N_CUSTOMERS + 1):
        rows.append({
            "customer_id": i,
            "first_name":  fake.first_name(),
            "last_name":   fake.last_name(),
            "email":       fake.unique.email(),
            "age":         random.randint(18, 70),
            "gender":      random.choice(["M", "F"]),
            "city":        fake.city(),
            "country":     "India",
            "created_at":  fake.date_time_between(start_date="-2y", end_date="-6m"),
        })
    return pd.DataFrame(rows)


def generate_products():
    rows = []
    for i in range(1, N_PRODUCTS + 1):
        cost = round(random.uniform(100, 5000), 2)
        rows.append({
            "product_id":   i,
            "name":         fake.bs().title(),
            "brand":        random.choice(BRANDS),
            "category":     random.choice(CATEGORIES),
            "department":   random.choice(DEPARTMENTS),
            "cost":         cost,
            "retail_price": round(cost * random.uniform(1.2, 2.5), 2),
        })
    return pd.DataFrame(rows)


def generate_orders(customers_df):
    rows = []
    cust_ids = customers_df["customer_id"].tolist()
    for i in range(1, N_ORDERS + 1):
        created = fake.date_time_between(start_date="-1y", end_date="now")
        status  = random.choice(ORDER_STATUS)
        rows.append({
            "order_id":     i,
            "customer_id":  random.choice(cust_ids),
            "status":       status,
            "num_of_items": random.randint(1, 5),
            "created_at":   created,
            "shipped_at":   created + timedelta(days=random.randint(1, 3))
                            if status not in ["processing", "cancelled"] else None,
            "delivered_at": created + timedelta(days=random.randint(4, 10))
                            if status == "complete" else None,
            "returned_at":  created + timedelta(days=random.randint(11, 30))
                            if status == "returned" else None,
        })
    return pd.DataFrame(rows)


def generate_order_items(orders_df, products_df):
    rows = []
    item_id = 1
    for _, order in orders_df.iterrows():
        for _ in range(int(order["num_of_items"])):
            product = products_df.sample(1).iloc[0]
            rows.append({
                "item_id":    item_id,
                "order_id":   order["order_id"],
                "customer_id": order["customer_id"],
                "product_id": product["product_id"],
                "status":     order["status"],
                "sale_price": round(float(product["retail_price"]) * random.uniform(0.8, 1.0), 2),
                "created_at": order["created_at"],
            })
            item_id += 1
    return pd.DataFrame(rows)


# ── loader ───────────────────────────────────────────────────────────────────

def bulk_insert(conn, table: str, df: pd.DataFrame, columns: list[str]):
    cursor = conn.cursor()
    cursor.fast_executemany = True
    placeholders = ", ".join(["?" for _ in columns])
    col_list     = ", ".join(columns)
    sql = f"INSERT INTO dbo.{table} ({col_list}) VALUES ({placeholders})"
    data = [tuple(row) for row in df[columns].itertuples(index=False)]
    cursor.executemany(sql, data)
    conn.commit()
    print(f"  ✓ {len(df):,} rows → dbo.{table}")


# ── main ─────────────────────────────────────────────────────────────────────

def main():
    print("Generating data …")
    customers_df  = generate_customers()
    products_df   = generate_products()
    orders_df     = generate_orders(customers_df)
    order_items_df = generate_order_items(orders_df, products_df)

    # Introduce intentional quality issues to be caught by validate.py
    null_mask = customers_df.sample(frac=0.02).index
    customers_df.loc[null_mask, "age"] = None          # ~1% null ages
    dup_idx   = order_items_df.sample(frac=0.01).index
    order_items_df = pd.concat([order_items_df, order_items_df.loc[dup_idx]])  # ~1% dups

    print("Connecting to SQL Server …")
    conn = pyodbc.connect(CONN_STR, autocommit=False)

    print("Loading tables …")
    bulk_insert(conn, "customers", customers_df, [
        "customer_id","first_name","last_name","email","age","gender","city","country","created_at"
    ])
    bulk_insert(conn, "products", products_df, [
        "product_id","name","brand","category","department","cost","retail_price"
    ])
    bulk_insert(conn, "orders", orders_df, [
        "order_id","customer_id","status","num_of_items","created_at",
        "shipped_at","delivered_at","returned_at"
    ])
    bulk_insert(conn, "order_items", order_items_df, [
        "item_id","order_id","customer_id","product_id","status","sale_price","created_at"
    ])

    conn.close()
    print("\nDone. SQL Server source is ready.")


if __name__ == "__main__":
    main()