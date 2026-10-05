INSERT INTO sales.orders (
    order_id,
    customer_id,
    order_date,
    order_status,
    total_amount
)
VALUES
    (5001, 1001, '2026-03-10', 'Completed', 129.99),
    (5002, 1002, '2026-03-11', 'Completed', 84.50),
    (5003, 1001, '2026-03-14', 'Pending', 42.00),
    (5004, 1004, '2026-03-18', 'Completed', 215.75),
    (5005, 1003, '2026-03-20', 'Cancelled', 59.99);