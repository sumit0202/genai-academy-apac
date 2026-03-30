# Deployment Steps: Smart Text Assistant (Track 1)

## Step-by-Step Instructions (Run in Google Cloud Shell)

### Step 1: Open Cloud Shell
Go to: https://console.cloud.google.com/welcome?cloudshell=true

### Step 2: Set your project
```bash
gcloud config set project YOUR_PROJECT_ID
```

### Step 3: Enable required APIs
```bash
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  aiplatform.googleapis.com \
  compute.googleapis.com
```

### Step 4: Create project directory and files
```bash
cd ~ && mkdir -p smart_assistant && cd smart_assistant
```

### Step 5: Create __init__.py
```bash
cat > __init__.py << 'EOF'
from . import agent
EOF
```

### Step 6: Create agent.py
```bash
cat > agent.py << 'AGENT_EOF'
import os
import logging
from dotenv import load_dotenv
from google.adk.agents import Agent
from google.adk.tools.tool_context import ToolContext

load_dotenv()

model_name = os.getenv("MODEL", "gemini-2.5-flash")


def summarize_text(tool_context: ToolContext, text: str) -> dict:
    """Summarizes the given text and extracts key points.
    Takes any block of text as input and saves it to state for processing.
    """
    tool_context.state["input_text"] = text
    logging.info(f"[State updated] Saved input text ({len(text)} chars)")
    return {
        "status": "success",
        "message": f"Text received ({len(text)} characters). Generating summary now."
    }


def classify_priority(tool_context: ToolContext, text: str) -> dict:
    """Classifies the priority level of a task or message.
    Analyzes text content and determines if it is high, medium, or low priority.
    """
    tool_context.state["classify_text"] = text
    logging.info(f"[State updated] Saved text for classification")
    return {
        "status": "success",
        "message": "Text received for priority classification."
    }


root_agent = Agent(
    model=model_name,
    name="smart_assistant",
    description="A smart text assistant that summarizes text, extracts action items, and classifies priority.",
    instruction="""You are a Smart Text Assistant powered by Gemini.
You help users with text processing tasks. You have the following capabilities:

1. **Text Summarization**: When a user provides text and asks for a summary,
   use the 'summarize_text' tool to save the text, then provide:
   - A concise summary (2-3 sentences)
   - Key points as bullet points
   - Any action items found in the text

2. **Priority Classification**: When a user asks to classify priority of a task or message,
   use the 'classify_priority' tool to save the text, then respond with:
   - Priority level: HIGH, MEDIUM, or LOW
   - Brief justification for the classification

3. **General Q&A**: For general questions, answer directly using your knowledge.

Always be helpful, concise, and well-structured in your responses.
Format your output cleanly using markdown.
""",
    tools=[summarize_text, classify_priority],
)
AGENT_EOF
```

### Step 7: Create .env file
Replace YOUR_PROJECT_ID with your actual project ID:
```bash
PROJECT_ID=$(gcloud config get-value project)
cat > .env << EOF
GOOGLE_GENAI_USE_VERTEXAI=1
GOOGLE_CLOUD_PROJECT=$PROJECT_ID
GOOGLE_CLOUD_LOCATION=us-central1
MODEL=gemini-2.5-flash
EOF
```

### Step 8: Create requirements.txt
```bash
cat > requirements.txt << 'EOF'
google-adk==1.14.0
EOF
```

### Step 9: Set up virtual environment and test locally (optional)
```bash
cd ~
uv venv
source .venv/bin/activate
uv pip install -r smart_assistant/requirements.txt
adk run smart_assistant
```
Type "hello" to test. Type "exit" to quit.

### Step 10: Create service account
```bash
PROJECT_ID=$(gcloud config get-value project)
SA_NAME=smart-assistant-sa

gcloud iam service-accounts create ${SA_NAME} \
    --display-name="Smart Assistant Service Account"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"
```

### Step 11: Deploy to Cloud Run
```bash
cd ~

uvx --from google-adk==1.14.0 \
adk deploy cloud_run \
  --project=$PROJECT_ID \
  --region=us-central1 \
  --service_name=smart-assistant \
  --with_ui \
  smart_assistant \
  -- \
  --service-account=${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
```

When prompted:
- "A repository named [cloud-run-source-deploy]..." -> Type Y and press Enter
- "Allow unauthenticated invocations..." -> Type y and press Enter

### Step 12: Get the deployed URL
After deployment completes, you'll see:
```
Service URL: https://smart-assistant-XXXXX.us-central1.run.app
```
COPY THIS URL - you need it for the PPT and submission!

### Step 13: Test the deployed agent
Open the Service URL in your browser. You should see the ADK web UI.
Test with prompts like:
- "Hello, what can you do?"
- "Summarize this: The quarterly report shows revenue increased by 15%..."
- "Classify priority: Server is down and customers cannot access the platform"

Take screenshots of the working agent for the PPT!
