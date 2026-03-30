# Track 2 Deployment: News Intelligence Agent (MCP + BigQuery)

This agent uses MCP Toolbox for Databases to connect to BigQuery's public
Google Cloud Release Notes dataset and answer questions about latest releases.

## Step-by-Step (Run in Google Cloud Shell)

### Step 1: Open Cloud Shell & set project
```bash
gcloud config set project smart-assistant-491814
```

### Step 2: Enable APIs (if not done already)
```bash
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  aiplatform.googleapis.com \
  compute.googleapis.com \
  bigquery.googleapis.com
```

### Step 3: Create project directory
```bash
cd ~ && mkdir -p news_agent && cd news_agent
```

### Step 4: Create __init__.py
```bash
cat > __init__.py << 'EOF'
from . import agent
EOF
```

### Step 5: Create agent.py
```bash
cat > agent.py << 'AGENT_EOF'
import os
import logging
from dotenv import load_dotenv
from google.adk.agents import Agent
from toolbox_core import ToolboxSyncClient

load_dotenv()

model_name = os.getenv("MODEL", "gemini-2.5-flash")
toolbox_url = os.getenv("TOOLBOX_URL", "http://127.0.0.1:5000")

toolbox = ToolboxSyncClient(toolbox_url)
tools = toolbox.load_toolset('release_notes_toolset')

root_agent = Agent(
    model=model_name,
    name="news_intelligence_agent",
    description="An AI agent that retrieves and analyzes Google Cloud release notes using MCP.",
    instruction="""You are a Google Cloud News Intelligence Agent.

You help users stay up-to-date with the latest Google Cloud product releases and updates.

You have access to a tool connected via MCP Toolbox for Databases that queries the
Google Cloud Release Notes dataset in BigQuery.

When a user asks about Google Cloud updates, releases, or product news:
1. Use the available tool to retrieve the latest release notes data
2. Organize the results by product and date
3. Provide a clear, well-structured summary

Format your response with:
- Product name in bold
- Brief description of the update
- Publication date

If the user asks about something not related to Google Cloud releases, politely let them
know you specialize in Google Cloud release notes and suggest relevant queries.
""",
    tools=tools,
)
AGENT_EOF
```

### Step 6: Create .env
```bash
PROJECT_ID=$(gcloud config get-value project)
cat > .env << EOF
GOOGLE_GENAI_USE_VERTEXAI=1
GOOGLE_CLOUD_PROJECT=$PROJECT_ID
GOOGLE_CLOUD_LOCATION=us-central1
MODEL=gemini-2.5-flash
TOOLBOX_URL=http://127.0.0.1:5000
EOF
```

### Step 7: Create requirements.txt
```bash
cat > requirements.txt << 'EOF'
google-adk==1.14.0
toolbox-core
EOF
```

### Step 8: Create tools.yaml for MCP Toolbox
```bash
PROJECT_ID=$(gcloud config get-value project)
cat > tools.yaml << EOF
sources:
  release-notes-bq:
    kind: bigquery
    project: $PROJECT_ID

tools:
  search_release_notes:
    kind: bigquery-sql
    source: release-notes-bq
    statement: |
      SELECT
        product_name, description, published_at
      FROM
        \`bigquery-public-data\`.\`google_cloud_release_notes\`.\`release_notes\`
      WHERE
        DATE(published_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
      GROUP BY product_name, description, published_at
      ORDER BY published_at DESC
      LIMIT 50
    description: |
      Retrieves the latest Google Cloud release notes from the past 7 days.
      Returns product name, description, and publication date.

toolsets:
  release_notes_toolset:
    - search_release_notes
EOF
```

### Step 9: Download and set up MCP Toolbox for Databases
```bash
cd ~/news_agent
export VERSION=0.23.0
curl -O https://storage.googleapis.com/genai-toolbox/v$VERSION/linux/amd64/toolbox
chmod +x toolbox
```

### Step 10: Test MCP Toolbox locally (Terminal 1)
```bash
cd ~/news_agent
./toolbox --tools-file="tools.yaml"
```
You should see: "Server ready to serve!" on port 5000.

### Step 11: Test Agent locally (Terminal 2 -- open a new terminal tab)
```bash
cd ~
source .venv/bin/activate
pip install google-adk==1.14.0 toolbox-core
adk run news_agent
```
Test with: "Get me the latest Google Cloud release notes"
Type "exit" when done.

### Step 12: Deploy MCP Toolbox to Cloud Run first
```bash
cd ~/news_agent
PROJECT_ID=$(gcloud config get-value project)
SA_NAME=news-agent-sa

# Create service account (skip if already exists)
gcloud iam service-accounts create ${SA_NAME} \
    --display-name="News Agent Service Account" 2>/dev/null || true

sleep 10

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/bigquery.user"

# Upload tools.yaml as a secret
gcloud secrets create tools-yaml --data-file=tools.yaml 2>/dev/null || \
gcloud secrets versions add tools-yaml --data-file=tools.yaml

# Deploy Toolbox to Cloud Run
export IMAGE=us-central1-docker.pkg.dev/database-toolbox/toolbox/toolbox:latest

gcloud run deploy toolbox-server \
  --image $IMAGE \
  --service-account ${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
  --region us-central1 \
  --set-secrets "/app/tools.yaml=tools-yaml:latest" \
  --args="--tools-file=/app/tools.yaml","--address=0.0.0.0","--port=8080" \
  --allow-unauthenticated
```
Copy the Toolbox Service URL (e.g., https://toolbox-server-XXXXX.us-central1.run.app)

### Step 13: Update agent to use deployed Toolbox URL
Update the .env file with the Toolbox Cloud Run URL:
```bash
TOOLBOX_URL=https://toolbox-server-XXXXX.us-central1.run.app
```
Replace XXXXX with your actual Toolbox URL from Step 12.

```bash
TOOLBOX_URL="https://toolbox-server-XXXXX.us-central1.run.app"
PROJECT_ID=$(gcloud config get-value project)
cat > .env << EOF
GOOGLE_GENAI_USE_VERTEXAI=1
GOOGLE_CLOUD_PROJECT=$PROJECT_ID
GOOGLE_CLOUD_LOCATION=us-central1
MODEL=gemini-2.5-flash
TOOLBOX_URL=$TOOLBOX_URL
EOF
```

### Step 14: Deploy the Agent to Cloud Run
```bash
cd ~
uvx --from google-adk==1.14.0 \
adk deploy cloud_run \
  --project=$PROJECT_ID \
  --region=us-central1 \
  --service_name=news-agent \
  --with_ui \
  news_agent \
  -- \
  --service-account=${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
```

### Step 15: Get the Agent URL & Test
Copy the Service URL. Open it in your browser. Test with:
- "What are the latest Google Cloud releases?"
- "Any updates on Compute Engine?"
- "Tell me about recent security announcements"

Take screenshots for the PPT!
