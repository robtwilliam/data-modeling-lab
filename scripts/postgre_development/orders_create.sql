CREATE TABLE sales.orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    order_date DATE,
    order_status TEXT,
    total_amount NUMERIC(10,2)
);