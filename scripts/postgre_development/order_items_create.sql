CREATE TABLE sales.order_items (
    order_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    unit_price NUMERIC(10,2),
    PRIMARY KEY (order_id, product_id)
);