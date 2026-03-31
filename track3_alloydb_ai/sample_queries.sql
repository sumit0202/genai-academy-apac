-- Sample Natural Language Queries for IT Support Tickets Dataset
-- These demonstrate AlloyDB AI natural language capability

-- Query 1: "Show me all critical tickets that are still open"
-- Expected SQL: SELECT * FROM support_tickets WHERE priority = 'critical' AND status != 'resolved' AND status != 'closed';

-- Query 2: "What is the average resolution time for high priority tickets?"
-- Expected SQL: SELECT AVG(resolution_hours) FROM support_tickets WHERE priority = 'high' AND resolution_hours IS NOT NULL;

-- Query 3: "Which support agent resolved the most tickets?"
-- Expected SQL: SELECT assigned_to, COUNT(*) as tickets_resolved FROM support_tickets WHERE status = 'resolved' GROUP BY assigned_to ORDER BY tickets_resolved DESC;

-- Query 4: "Show me all network related issues from March 2026"
-- Expected SQL: SELECT * FROM support_tickets WHERE category = 'Network' AND created_at >= '2026-03-01';

-- Query 5: "What departments raised the most support tickets?"
-- Expected SQL: SELECT department, COUNT(*) FROM support_tickets GROUP BY department ORDER BY count DESC;

-- Query 6 (Custom - NOT from any lab): "Find tickets with customer satisfaction below 4 and show their resolution time"
-- Expected SQL: SELECT title, category, priority, resolution_hours, customer_satisfaction FROM support_tickets WHERE customer_satisfaction < 4 ORDER BY customer_satisfaction ASC;

-- Query 7 (Custom): "What is the average customer satisfaction score by category?"
-- Expected SQL: SELECT category, ROUND(AVG(customer_satisfaction), 1) as avg_satisfaction FROM support_tickets WHERE customer_satisfaction IS NOT NULL GROUP BY category ORDER BY avg_satisfaction DESC;
