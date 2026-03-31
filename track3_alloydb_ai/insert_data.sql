-- Insert sample IT support ticket data
INSERT INTO support_tickets (title, description, category, priority, status, assigned_to, reporter_name, department, resolution, created_at, resolved_at, satisfaction_rating) VALUES
('VPN Connection Failing', 'Unable to connect to corporate VPN from home network. Error: Connection timed out after 30 seconds.', 'Network', 'high', 'resolved', 'Mike Chen', 'Alice Johnson', 'Engineering', 'Reset VPN client configuration and updated certificates. Issue was expired SSL cert.', '2026-03-15 09:00:00', '2026-03-15 11:30:00', 5),

('Laptop Overheating During Meetings', 'MacBook Pro gets extremely hot during video calls with screen sharing. Fan runs at max speed.', 'Hardware', 'medium', 'resolved', 'Sarah Lee', 'Bob Williams', 'Marketing', 'Cleared dust from vents. Recommended using external monitor to reduce GPU load.', '2026-03-16 14:00:00', '2026-03-17 10:00:00', 4),

('Cannot Access SharePoint', 'Getting 403 Forbidden error when trying to access the Finance team SharePoint site.', 'Access', 'high', 'resolved', 'Mike Chen', 'Carol Davis', 'Finance', 'Added user to the Finance SharePoint security group in Azure AD.', '2026-03-18 08:30:00', '2026-03-18 09:15:00', 5),

('Email Not Syncing on Mobile', 'Outlook on iPhone stopped syncing emails 2 days ago. Shows last sync was March 20.', 'Email', 'medium', 'in_progress', 'James Park', 'David Brown', 'Sales', NULL, '2026-03-22 11:00:00', NULL, NULL),

('Printer Jam on 3rd Floor', 'HP LaserJet on 3rd floor keeps jamming. Paper tray 2 seems misaligned.', 'Hardware', 'low', 'open', NULL, 'Emma Wilson', 'HR', NULL, '2026-03-23 15:30:00', NULL, NULL),

('Software License Expired - Adobe', 'Adobe Creative Cloud license expired. Need renewal for design team (5 seats).', 'Software', 'high', 'resolved', 'Sarah Lee', 'Frank Miller', 'Design', 'Renewed 5-seat Adobe CC enterprise license. Updated license server.', '2026-03-10 10:00:00', '2026-03-11 14:00:00', 4),

('Two-Factor Auth Not Working', 'Microsoft Authenticator app not generating codes. Cannot log into any corporate systems.', 'Security', 'critical', 'resolved', 'Mike Chen', 'Grace Taylor', 'Engineering', 'Re-enrolled device in MFA. Old phone was deregistered after OS update.', '2026-03-20 07:45:00', '2026-03-20 08:30:00', 5),

('Slow Internet in Conference Room B', 'WiFi speed in Conference Room B drops to under 5 Mbps during meetings with 10+ people.', 'Network', 'medium', 'in_progress', 'James Park', 'Henry Anderson', 'Operations', NULL, '2026-03-24 09:00:00', NULL, NULL),

('New Employee Laptop Setup', 'Need a new MacBook Pro 16-inch configured with standard dev tools for new hire starting April 1.', 'Hardware', 'medium', 'open', NULL, 'Isabella Thomas', 'Engineering', NULL, '2026-03-25 13:00:00', NULL, NULL),

('Database Backup Failure Alert', 'Automated backup for production PostgreSQL database failed last night. Error in cron job logs.', 'Infrastructure', 'critical', 'resolved', 'Mike Chen', 'Jack Martinez', 'Engineering', 'Disk space was full on backup server. Cleaned old backups and increased volume size.', '2026-03-19 06:00:00', '2026-03-19 07:30:00', 5),

('Zoom Audio Echo Issue', 'Multiple users reporting audio echo during Zoom calls from the 2nd floor open area.', 'Software', 'low', 'resolved', 'James Park', 'Karen White', 'Marketing', 'Installed acoustic panels and configured default audio settings to use headsets.', '2026-03-14 16:00:00', '2026-03-21 12:00:00', 3),

('Password Reset Request', 'Locked out of Active Directory account after too many failed login attempts.', 'Security', 'high', 'resolved', 'Sarah Lee', 'Leo Harris', 'Finance', 'Unlocked AD account and forced password reset. Enabled self-service password reset portal.', '2026-03-22 08:00:00', '2026-03-22 08:20:00', 5),

('Monitor Flickering', 'Dell 27-inch monitor connected via USB-C keeps flickering every few minutes.', 'Hardware', 'low', 'open', NULL, 'Mia Clark', 'Design', NULL, '2026-03-26 10:30:00', NULL, NULL),

('Cloud Storage Quota Exceeded', 'Google Drive storage is full at 15GB. Cannot save any new files or receive email attachments.', 'Software', 'medium', 'resolved', 'Sarah Lee', 'Noah Lewis', 'Sales', 'Upgraded to Google Workspace Business plan with 2TB storage per user.', '2026-03-17 11:00:00', '2026-03-18 15:00:00', 4),

('Suspicious Login Alert', 'Received alert for login attempt from unrecognized IP in another country on my corporate account.', 'Security', 'critical', 'resolved', 'Mike Chen', 'Olivia Robinson', 'Finance', 'Blocked IP, forced password change, reviewed audit logs. No data breach confirmed.', '2026-03-21 03:00:00', '2026-03-21 05:00:00', 5);
