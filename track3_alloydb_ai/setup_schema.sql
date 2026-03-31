-- Track 3: Custom Dataset - IT Support Tickets
-- Use case: "Querying IT support ticket data to analyze trends and resolution times"

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS google_ml_integration CASCADE;
CREATE EXTENSION IF NOT EXISTS vector;

-- Create custom table: IT Support Tickets
CREATE TABLE IF NOT EXISTS support_tickets (
    ticket_id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    priority TEXT NOT NULL CHECK (priority IN ('critical', 'high', 'medium', 'low')),
    status TEXT NOT NULL CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    assigned_to TEXT,
    department TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    resolved_at TIMESTAMP,
    resolution_hours NUMERIC(10,2),
    customer_satisfaction INTEGER CHECK (customer_satisfaction BETWEEN 1 AND 5)
);

-- Insert sample data (30 realistic support tickets)
INSERT INTO support_tickets (title, description, category, priority, status, assigned_to, department, created_at, resolved_at, resolution_hours, customer_satisfaction) VALUES
('VPN connection drops frequently', 'User reports VPN disconnects every 15 minutes during remote work sessions', 'Network', 'high', 'resolved', 'Raj Kumar', 'Engineering', '2026-03-01 09:00:00', '2026-03-01 14:30:00', 5.5, 4),
('Cannot access shared drive', 'Permission denied error when accessing marketing shared drive', 'Access Management', 'medium', 'resolved', 'Priya Singh', 'Marketing', '2026-03-02 10:15:00', '2026-03-02 11:00:00', 0.75, 5),
('Laptop overheating during video calls', 'MacBook Pro runs extremely hot during Zoom meetings with screen sharing', 'Hardware', 'medium', 'resolved', 'Anil Mehta', 'Sales', '2026-03-03 08:30:00', '2026-03-04 10:00:00', 25.5, 3),
('Email not syncing on mobile', 'Outlook app on iPhone not receiving new emails since yesterday', 'Email', 'high', 'resolved', 'Raj Kumar', 'Finance', '2026-03-04 07:45:00', '2026-03-04 09:15:00', 1.5, 5),
('New employee onboarding - software setup', 'Need standard software suite installed for new hire starting Monday', 'Onboarding', 'medium', 'resolved', 'Sneha Patel', 'HR', '2026-03-05 11:00:00', '2026-03-06 16:00:00', 29.0, 4),
('Production server high CPU usage', 'Server CPU consistently above 95% causing application slowdowns', 'Infrastructure', 'critical', 'resolved', 'Vikram Reddy', 'Engineering', '2026-03-06 02:30:00', '2026-03-06 05:45:00', 3.25, 4),
('Password reset request', 'User locked out of Active Directory account after failed attempts', 'Access Management', 'low', 'resolved', 'Priya Singh', 'Sales', '2026-03-07 08:00:00', '2026-03-07 08:20:00', 0.33, 5),
('Printer not working on 3rd floor', 'HP LaserJet showing offline status, no one on floor can print', 'Hardware', 'medium', 'resolved', 'Anil Mehta', 'Operations', '2026-03-08 14:00:00', '2026-03-08 16:30:00', 2.5, 4),
('Software license expired - Adobe Creative Suite', 'Design team cannot open Photoshop, license shows as expired', 'Software', 'high', 'resolved', 'Sneha Patel', 'Marketing', '2026-03-09 09:30:00', '2026-03-09 12:00:00', 2.5, 3),
('Database backup failure', 'Nightly backup job failed for customer database with storage error', 'Infrastructure', 'critical', 'resolved', 'Vikram Reddy', 'Engineering', '2026-03-10 06:00:00', '2026-03-10 08:30:00', 2.5, 5),
('Slack integration broken with Jira', 'Jira ticket notifications stopped appearing in Slack channels', 'Software', 'low', 'resolved', 'Raj Kumar', 'Engineering', '2026-03-11 10:00:00', '2026-03-12 14:00:00', 28.0, 3),
('WiFi slow in conference room B', 'Video calls buffering and dropping in conference room B only', 'Network', 'medium', 'in_progress', 'Anil Mehta', 'Operations', '2026-03-12 13:00:00', NULL, NULL, NULL),
('Request for second monitor', 'Developer requesting additional 27-inch monitor for dual setup', 'Hardware', 'low', 'resolved', 'Sneha Patel', 'Engineering', '2026-03-13 09:00:00', '2026-03-15 11:00:00', 50.0, 4),
('MFA not working on new phone', 'User switched phones and cannot complete two-factor authentication', 'Access Management', 'high', 'resolved', 'Priya Singh', 'Finance', '2026-03-14 07:30:00', '2026-03-14 08:45:00', 1.25, 5),
('CI/CD pipeline failing', 'GitHub Actions workflow fails at deploy stage with permission error', 'Infrastructure', 'critical', 'resolved', 'Vikram Reddy', 'Engineering', '2026-03-15 11:00:00', '2026-03-15 14:00:00', 3.0, 4),
('Cannot join Teams meeting', 'Getting error code 503 when trying to join any Microsoft Teams call', 'Software', 'high', 'open', 'Raj Kumar', 'Sales', '2026-03-16 08:00:00', NULL, NULL, NULL),
('Data export from CRM taking too long', 'Salesforce report export timing out for large customer datasets', 'Software', 'medium', 'in_progress', 'Sneha Patel', 'Sales', '2026-03-17 10:30:00', NULL, NULL, NULL),
('Security alert - suspicious login attempt', 'Multiple failed login attempts from unknown IP on admin account', 'Security', 'critical', 'resolved', 'Vikram Reddy', 'IT Security', '2026-03-18 03:00:00', '2026-03-18 04:15:00', 1.25, 5),
('Office 365 license assignment', 'New contractor needs Office 365 E3 license for 3-month project', 'Software', 'medium', 'resolved', 'Priya Singh', 'HR', '2026-03-19 09:00:00', '2026-03-19 10:30:00', 1.5, 4),
('Kubernetes pod crash loop', 'Payment service pod restarting every 2 minutes in production cluster', 'Infrastructure', 'critical', 'resolved', 'Vikram Reddy', 'Engineering', '2026-03-20 01:00:00', '2026-03-20 03:30:00', 2.5, 4),
('Request to whitelist website', 'Marketing needs access to a social media analytics tool blocked by firewall', 'Network', 'low', 'resolved', 'Raj Kumar', 'Marketing', '2026-03-21 11:00:00', '2026-03-21 14:00:00', 3.0, 4),
('Zoom recording not saving to cloud', 'Meeting recordings not appearing in cloud storage after meetings end', 'Software', 'medium', 'resolved', 'Anil Mehta', 'HR', '2026-03-22 15:00:00', '2026-03-23 09:00:00', 18.0, 3),
('New department setup - Analytics team', 'Need full IT setup for new 5-person analytics team starting next month', 'Onboarding', 'medium', 'open', 'Sneha Patel', 'Analytics', '2026-03-23 10:00:00', NULL, NULL, NULL),
('SSL certificate expiring in 3 days', 'Production website SSL cert expires March 28, needs urgent renewal', 'Security', 'critical', 'resolved', 'Vikram Reddy', 'Engineering', '2026-03-25 09:00:00', '2026-03-25 11:00:00', 2.0, 5),
('Cannot connect to staging database', 'Developers getting connection refused on staging PostgreSQL instance', 'Infrastructure', 'high', 'in_progress', 'Vikram Reddy', 'Engineering', '2026-03-26 08:00:00', NULL, NULL, NULL),
('Automated test suite broken after update', 'Selenium tests failing across all browsers after Chrome update', 'Software', 'medium', 'open', 'Raj Kumar', 'QA', '2026-03-27 10:00:00', NULL, NULL, NULL),
('Employee offboarding - revoke access', 'Departing employee needs all system access revoked by end of day', 'Access Management', 'high', 'resolved', 'Priya Singh', 'HR', '2026-03-28 08:00:00', '2026-03-28 10:00:00', 2.0, 5),
('Cloud storage quota exceeded', 'Google Drive showing 100% full for engineering shared drive', 'Infrastructure', 'medium', 'resolved', 'Anil Mehta', 'Engineering', '2026-03-28 14:00:00', '2026-03-29 09:00:00', 19.0, 3),
('API rate limiting customers', 'Public API returning 429 errors during peak hours affecting customers', 'Infrastructure', 'critical', 'resolved', 'Vikram Reddy', 'Engineering', '2026-03-29 06:00:00', '2026-03-29 09:30:00', 3.5, 4),
('Laptop replacement request', 'Sales manager laptop 4 years old, battery only lasts 30 minutes', 'Hardware', 'low', 'open', 'Sneha Patel', 'Sales', '2026-03-30 09:00:00', NULL, NULL, NULL);

-- Verify data
SELECT COUNT(*) as total_tickets FROM support_tickets;
SELECT category, COUNT(*) as count FROM support_tickets GROUP BY category ORDER BY count DESC;
