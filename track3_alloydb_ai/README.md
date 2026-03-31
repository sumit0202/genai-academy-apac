# Track 3: IT Support Tickets - AlloyDB AI Natural Language

**Use case:** Querying IT support ticket data to analyze trends, resolution times, and team performance using natural language.

## Dataset
- 30 realistic IT support tickets
- Categories: Network, Hardware, Software, Infrastructure, Security, Access Management, Onboarding
- Fields: title, description, category, priority, status, assigned_to, department, resolution_hours, customer_satisfaction

## Setup
1. Provision AlloyDB using the one-click setup
2. Run `setup_schema.sql` in AlloyDB Studio
3. Enable AlloyDB AI natural language
4. Query using natural language

## Sample Natural Language Queries
- "Show me all critical tickets that are still open"
- "What is the average resolution time for high priority tickets?"
- "Which support agent resolved the most tickets?"
- "Find tickets with customer satisfaction below 4"
