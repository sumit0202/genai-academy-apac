# Track 3: AlloyDB AI Natural Language - Deployment Guide

**Use case:** Querying IT support ticket data using natural language  
**Dataset:** Custom IT Support Tickets (30 records, 12 fields)

---

## Step 1: Set Project Variables

Open **Google Cloud Shell** and run:

```bash
PROJECT_ID=$(gcloud config get-value project)
echo "Project: $PROJECT_ID"
```

## Step 2: Enable Required APIs

```bash
gcloud services enable \
  alloydb.googleapis.com \
  aiplatform.googleapis.com \
  compute.googleapis.com \
  servicenetworking.googleapis.com \
  cloudresourcemanager.googleapis.com
```

Wait 1-2 minutes for propagation.

## Step 3: Set Up AlloyDB (One-Click Method)

Use the one-click AlloyDB setup from the codelab:

```bash
git clone https://github.com/GoogleCloudPlatform/devrel-demos.git
cd devrel-demos/infrastructure/easy-alloydb-setup
sh run.sh
```

This opens a web UI. Enter:
- **Project ID:** your project ID (e.g., `smart-assistant-491814`)
- **Cluster name:** `support-tickets-cluster`
- **Instance name:** `support-tickets-instance`
- **Password:** `alloydb` (or your choice -- remember it!)
- **Region:** `us-central1`

**Wait ~10-15 minutes** for the cluster and instance to be provisioned.

You can verify at: https://console.cloud.google.com/alloydb/clusters

## Step 4: Connect to AlloyDB Studio

1. Go to **AlloyDB** in the Cloud Console: https://console.cloud.google.com/alloydb/clusters
2. Click on your cluster → click on the primary instance
3. Click **"AlloyDB Studio"** in the left menu
4. Sign in with:
   - **Username:** `postgres`
   - **Database:** `postgres`
   - **Password:** `alloydb` (or whatever you set)

## Step 5: Create Schema and Load Custom Dataset

In **AlloyDB Studio**, paste and run the following SQL. You can also find this in `track3_alloydb_ai/setup_schema.sql`:

```sql
-- Enable extensions
CREATE EXTENSION IF NOT EXISTS google_ml_integration CASCADE;
CREATE EXTENSION IF NOT EXISTS vector;

-- Create IT Support Tickets table
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
```

Then run the INSERT statements from `track3_alloydb_ai/setup_schema.sql` (all 30 rows).

Verify with:
```sql
SELECT COUNT(*) as total_tickets FROM support_tickets;
-- Should return 30

SELECT category, COUNT(*) as count FROM support_tickets GROUP BY category ORDER BY count DESC;
```

## Step 6: Grant Vertex AI User Role to AlloyDB Service Account

Go back to **Cloud Shell** and run:

```bash
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-alloydb.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"
```

## Step 7: Enable AlloyDB AI Natural Language

1. In the **Cloud Console**, go to **AlloyDB** > your cluster > your instance
2. Click **"Edit Primary Instance"**
3. Scroll down to **"AlloyDB AI"** section
4. Toggle **"Enable AlloyDB AI natural language"** to ON
5. Click **"Update Instance"**

**Alternative via gcloud (if UI option is available):**
```bash
gcloud alloydb instances update support-tickets-instance \
  --cluster=support-tickets-cluster \
  --region=us-central1 \
  --database-flags=google_ml_integration.enable_model_support=on
```

## Step 8: Configure Natural Language for Your Dataset

Go back to **AlloyDB Studio** and run the following to set up the AI natural language configuration:

### Option A: Using AlloyDB AI Natural Language UI (Recommended)

1. In AlloyDB Studio, look for the **"Natural Language"** tab or icon
2. Click **"Create Configuration"**
3. Select the `postgres` database
4. Select the `support_tickets` table
5. Add context/description: "IT support ticket tracking system. Contains tickets with priority levels (critical, high, medium, low), status (open, in_progress, resolved, closed), categories, assigned support agents, departments, resolution times in hours, and customer satisfaction scores from 1 to 5."
6. Save the configuration

### Option B: Using SQL (if the NL config API is available)

```sql
-- Register Gemini model for natural language queries
CALL google_ml.create_model(
    model_id => 'gemini-2.5-flash',
    model_request_url => 'https://aiplatform.googleapis.com/v1/projects/YOUR_PROJECT_ID/locations/us-central1/publishers/google/models/gemini-2.5-flash:generateContent',
    model_qualified_name => 'gemini-2.5-flash',
    model_provider => 'google',
    model_type => 'llm',
    model_auth_type => 'alloydb_service_agent_iam'
);
```
Replace `YOUR_PROJECT_ID` with your actual project ID.

## Step 9: Test Natural Language Queries

Use the AlloyDB Studio Natural Language feature to run these queries:

**Query 1:** "Show me all critical tickets that are still open"

**Query 2:** "What is the average resolution time for high priority tickets?"

**Query 3:** "Which support agent resolved the most tickets?"

**Query 4:** "Show me all network related issues from March 2026"

**Query 5 (Custom):** "Find tickets with customer satisfaction below 4 and show their resolution time"

**Query 6 (Custom):** "What is the average customer satisfaction score by category?"

**Query 7 (Custom):** "What departments raised the most support tickets this month?"

For each query, the system will:
1. Convert your natural language to SQL
2. Execute the SQL against AlloyDB
3. Return the results

**Take screenshots** of the natural language queries and their results for your submission!

## Step 10: Get the AlloyDB Instance URL for Submission

Your submission URL is your AlloyDB cluster/instance page in the Cloud Console:

```
https://console.cloud.google.com/alloydb/clusters/locations/us-central1/clusters/support-tickets-cluster/instances/support-tickets-instance?project=YOUR_PROJECT_ID
```

Or the Cloud Run URL if you deploy a frontend app.

---

## Cleanup (After Submission)

**IMPORTANT: Do this AFTER submission to avoid ongoing charges.**

```bash
# Delete AlloyDB instance and cluster
gcloud alloydb instances delete support-tickets-instance \
  --cluster=support-tickets-cluster \
  --region=us-central1 \
  --quiet

gcloud alloydb clusters delete support-tickets-cluster \
  --region=us-central1 \
  --quiet
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| AlloyDB Studio login fails | Verify password; reset via instance Edit page |
| Extensions not found | Wait for instance to finish provisioning |
| Model registration fails | Check IAM roles; wait for propagation |
| Natural language queries not working | Ensure AI natural language is enabled on instance |
| Quota exceeded | Try a different region (us-east1) |
