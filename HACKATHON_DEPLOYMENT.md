# Hackathon: Multi-Agent Productivity Assistant Deployment

## FAST DEPLOYMENT (~30 min) - Run all in Google Cloud Shell

### Step 1: Set project
```bash
gcloud config set project smart-assistant-491814
export PROJECT_ID=$(gcloud config get-value project)
```

### Step 2: Create BigQuery dataset and tables
```bash
bq mk --dataset ${PROJECT_ID}:productivity_assistant

bq query --use_legacy_sql=false "
CREATE TABLE IF NOT EXISTS \`${PROJECT_ID}.productivity_assistant.tasks\` (
  task_id STRING,
  title STRING,
  description STRING,
  priority STRING,
  status STRING,
  created_at TIMESTAMP
)"

bq query --use_legacy_sql=false "
CREATE TABLE IF NOT EXISTS \`${PROJECT_ID}.productivity_assistant.schedule\` (
  event_id STRING,
  title STRING,
  event_date DATE,
  event_time TIME,
  created_at TIMESTAMP
)"

bq query --use_legacy_sql=false "
CREATE TABLE IF NOT EXISTS \`${PROJECT_ID}.productivity_assistant.notes\` (
  note_id STRING,
  title STRING,
  content STRING,
  created_at TIMESTAMP
)"
```

### Step 3: Insert sample data
```bash
bq query --use_legacy_sql=false "
INSERT INTO \`${PROJECT_ID}.productivity_assistant.tasks\` VALUES
  (GENERATE_UUID(), 'Review Q3 Report', 'Review quarterly financial report', 'high', 'pending', CURRENT_TIMESTAMP()),
  (GENERATE_UUID(), 'Update Documentation', 'Update API docs for v2', 'medium', 'in_progress', CURRENT_TIMESTAMP()),
  (GENERATE_UUID(), 'Team Standup Prep', 'Prepare agenda for standup', 'low', 'completed', CURRENT_TIMESTAMP())
"

bq query --use_legacy_sql=false "
INSERT INTO \`${PROJECT_ID}.productivity_assistant.schedule\` VALUES
  (GENERATE_UUID(), 'Team Standup', '2026-03-31', '09:00:00', CURRENT_TIMESTAMP()),
  (GENERATE_UUID(), 'Sprint Planning', '2026-04-01', '14:00:00', CURRENT_TIMESTAMP())
"

bq query --use_legacy_sql=false "
INSERT INTO \`${PROJECT_ID}.productivity_assistant.notes\` VALUES
  (GENERATE_UUID(), 'Project Ideas', 'Explore using ADK for customer support automation', CURRENT_TIMESTAMP()),
  (GENERATE_UUID(), 'Meeting Notes', 'Discussed Q3 roadmap priorities with stakeholders', CURRENT_TIMESTAMP())
"
```

### Step 4: Create agent project files
```bash
cd ~ && mkdir -p productivity_agent && cd productivity_agent
```

Create __init__.py:
```bash
cat > __init__.py << 'EOF'
from . import agent
EOF
```

Create agent.py:
```bash
cat > agent.py << 'AGENT_EOF'
import os
from dotenv import load_dotenv
from google.adk.agents import Agent
from toolbox_core import ToolboxSyncClient

load_dotenv()

model_name = os.getenv("MODEL", "gemini-2.5-flash")
toolbox_url = os.getenv("TOOLBOX_URL", "http://127.0.0.1:5000")

toolbox = ToolboxSyncClient(toolbox_url)
task_tools = toolbox.load_toolset("task_toolset")
schedule_tools = toolbox.load_toolset("schedule_toolset")
notes_tools = toolbox.load_toolset("notes_toolset")

task_agent = Agent(
    model=model_name,
    name="task_agent",
    description="Manages tasks: create, list, update status, and delete tasks.",
    instruction="""You are the Task Management Agent. You handle all task-related operations.
When a user wants to:
- CREATE a task: Use the 'create_task' tool. Ask for title and priority (high/medium/low) if not provided.
- LIST tasks: Use the 'list_tasks' tool to show all tasks.
- UPDATE a task: Use the 'update_task_status' tool to change status (pending/in_progress/completed).
- DELETE a task: Use the 'delete_task' tool.
Always confirm the action taken and show the result clearly.""",
    tools=task_tools,
)

schedule_agent = Agent(
    model=model_name,
    name="schedule_agent",
    description="Manages schedule: create events, list upcoming events, and delete events.",
    instruction="""You are the Schedule Management Agent. You handle all calendar/schedule operations.
When a user wants to:
- CREATE an event: Use the 'create_event' tool. Need title, event_date (YYYY-MM-DD), and event_time (HH:MM).
- LIST events: Use the 'list_events' tool to show upcoming events.
- DELETE an event: Use the 'delete_event' tool.
Always confirm the action and display event details clearly.""",
    tools=schedule_tools,
)

notes_agent = Agent(
    model=model_name,
    name="notes_agent",
    description="Manages notes: create, search, list, and delete notes.",
    instruction="""You are the Notes Management Agent. You handle all note-taking operations.
When a user wants to:
- CREATE a note: Use the 'create_note' tool. Need a title and content.
- LIST notes: Use the 'list_notes' tool.
- SEARCH notes: Use the 'search_notes' tool to find notes by keyword.
- DELETE a note: Use the 'delete_note' tool.
Always confirm the action and show the note content.""",
    tools=notes_tools,
)

root_agent = Agent(
    model=model_name,
    name="productivity_assistant",
    description="A multi-agent productivity assistant that coordinates task, schedule, and notes management.",
    instruction="""You are a Multi-Agent Productivity Assistant. You coordinate three specialized sub-agents.

Your sub-agents are:
1. task_agent - For task management (create, list, update, delete tasks)
2. schedule_agent - For schedule/calendar management (create, list, delete events)
3. notes_agent - For notes management (create, list, search, delete notes)

When a user makes a request:
- Analyze what they need and route to the appropriate sub-agent
- For multi-step requests, coordinate between multiple sub-agents
- For greetings, respond directly and explain your capabilities

Routing examples:
- "Add a task" -> task_agent
- "Schedule a meeting" -> schedule_agent
- "Save a note" -> notes_agent
""",
    sub_agents=[task_agent, schedule_agent, notes_agent],
)
AGENT_EOF
```

Create .env:
```bash
PROJECT_ID=$(gcloud config get-value project)
TOOLBOX_URL=$(gcloud run services describe toolbox-server --region=us-central1 --format="value(status.url)" 2>/dev/null || echo "http://127.0.0.1:5000")
cat > .env << EOF
GOOGLE_GENAI_USE_VERTEXAI=1
GOOGLE_CLOUD_PROJECT=$PROJECT_ID
GOOGLE_CLOUD_LOCATION=us-central1
MODEL=gemini-2.5-flash
TOOLBOX_URL=$TOOLBOX_URL
EOF
```

Create requirements.txt:
```bash
cat > requirements.txt << 'EOF'
google-adk==1.14.0
toolbox-core
EOF
```

### Step 5: Create tools.yaml and update MCP Toolbox
```bash
PROJECT_ID=$(gcloud config get-value project)
cat > tools.yaml << TOOLSEOF
sources:
  productivity-db:
    kind: bigquery
    project: ${PROJECT_ID}

tools:
  create_task:
    kind: bigquery-sql
    source: productivity-db
    description: Creates a new task with a title, priority level, and optional description.
    parameters:
      - name: title
        type: string
        description: The title of the task
      - name: priority
        type: string
        description: Priority level - high, medium, or low
      - name: task_description
        type: string
        description: Optional description of the task
    statement: |
      INSERT INTO \`${PROJECT_ID}.productivity_assistant.tasks\`
        (task_id, title, description, priority, status, created_at)
      VALUES
        (GENERATE_UUID(), \$1, \$3, \$2, 'pending', CURRENT_TIMESTAMP())

  list_tasks:
    kind: bigquery-sql
    source: productivity-db
    description: Lists all tasks with their status and priority.
    statement: |
      SELECT task_id, title, description, priority, status, created_at
      FROM \`${PROJECT_ID}.productivity_assistant.tasks\`
      ORDER BY created_at DESC LIMIT 20

  update_task_status:
    kind: bigquery-sql
    source: productivity-db
    description: Updates the status of a task by its title.
    parameters:
      - name: title
        type: string
        description: The title of the task to update
      - name: new_status
        type: string
        description: The new status - pending, in_progress, or completed
    statement: |
      UPDATE \`${PROJECT_ID}.productivity_assistant.tasks\`
      SET status = \$2
      WHERE LOWER(title) LIKE LOWER(CONCAT('%', \$1, '%'))

  delete_task:
    kind: bigquery-sql
    source: productivity-db
    description: Deletes a task by its title.
    parameters:
      - name: title
        type: string
        description: The title of the task to delete
    statement: |
      DELETE FROM \`${PROJECT_ID}.productivity_assistant.tasks\`
      WHERE LOWER(title) LIKE LOWER(CONCAT('%', \$1, '%'))

  create_event:
    kind: bigquery-sql
    source: productivity-db
    description: Creates a new calendar event with title, date, and time.
    parameters:
      - name: title
        type: string
        description: The title of the event
      - name: event_date
        type: string
        description: Date in YYYY-MM-DD format
      - name: event_time
        type: string
        description: Time in HH:MM format
    statement: |
      INSERT INTO \`${PROJECT_ID}.productivity_assistant.schedule\`
        (event_id, title, event_date, event_time, created_at)
      VALUES
        (GENERATE_UUID(), \$1, PARSE_DATE('%Y-%m-%d', \$2), PARSE_TIME('%H:%M', \$3), CURRENT_TIMESTAMP())

  list_events:
    kind: bigquery-sql
    source: productivity-db
    description: Lists all upcoming events from the schedule.
    statement: |
      SELECT event_id, title, event_date, event_time, created_at
      FROM \`${PROJECT_ID}.productivity_assistant.schedule\`
      ORDER BY event_date ASC, event_time ASC LIMIT 20

  delete_event:
    kind: bigquery-sql
    source: productivity-db
    description: Deletes a scheduled event by title.
    parameters:
      - name: title
        type: string
        description: The title of the event to delete
    statement: |
      DELETE FROM \`${PROJECT_ID}.productivity_assistant.schedule\`
      WHERE LOWER(title) LIKE LOWER(CONCAT('%', \$1, '%'))

  create_note:
    kind: bigquery-sql
    source: productivity-db
    description: Creates a new note with title and content.
    parameters:
      - name: title
        type: string
        description: The title of the note
      - name: content
        type: string
        description: The content of the note
    statement: |
      INSERT INTO \`${PROJECT_ID}.productivity_assistant.notes\`
        (note_id, title, content, created_at)
      VALUES
        (GENERATE_UUID(), \$1, \$2, CURRENT_TIMESTAMP())

  list_notes:
    kind: bigquery-sql
    source: productivity-db
    description: Lists all notes.
    statement: |
      SELECT note_id, title, content, created_at
      FROM \`${PROJECT_ID}.productivity_assistant.notes\`
      ORDER BY created_at DESC LIMIT 20

  search_notes:
    kind: bigquery-sql
    source: productivity-db
    description: Searches notes by keyword in title or content.
    parameters:
      - name: keyword
        type: string
        description: Keyword to search for in notes
    statement: |
      SELECT note_id, title, content, created_at
      FROM \`${PROJECT_ID}.productivity_assistant.notes\`
      WHERE LOWER(title) LIKE LOWER(CONCAT('%', \$1, '%'))
         OR LOWER(content) LIKE LOWER(CONCAT('%', \$1, '%'))
      ORDER BY created_at DESC

  delete_note:
    kind: bigquery-sql
    source: productivity-db
    description: Deletes a note by title.
    parameters:
      - name: title
        type: string
        description: The title of the note to delete
    statement: |
      DELETE FROM \`${PROJECT_ID}.productivity_assistant.notes\`
      WHERE LOWER(title) LIKE LOWER(CONCAT('%', \$1, '%'))

toolsets:
  task_toolset:
    - create_task
    - list_tasks
    - update_task_status
    - delete_task
  schedule_toolset:
    - create_event
    - list_events
    - delete_event
  notes_toolset:
    - create_note
    - list_notes
    - search_notes
    - delete_note
TOOLSEOF
```

### Step 6: Update MCP Toolbox secret and redeploy
```bash
gcloud secrets versions add tools-yaml --data-file=tools.yaml

SA_NAME=news-agent-sa

gcloud run deploy toolbox-server \
  --image us-central1-docker.pkg.dev/database-toolbox/toolbox/toolbox:latest \
  --service-account ${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
  --region us-central1 \
  --set-secrets "/app/tools.yaml=tools-yaml:latest" \
  --args="--tools-file=/app/tools.yaml","--address=0.0.0.0","--port=8080" \
  --allow-unauthenticated
```

### Step 7: Update .env with Toolbox URL
```bash
cd ~/productivity_agent
TOOLBOX_URL=$(gcloud run services describe toolbox-server --region=us-central1 --format="value(status.url)")
PROJECT_ID=$(gcloud config get-value project)
cat > .env << EOF
GOOGLE_GENAI_USE_VERTEXAI=1
GOOGLE_CLOUD_PROJECT=$PROJECT_ID
GOOGLE_CLOUD_LOCATION=us-central1
MODEL=gemini-2.5-flash
TOOLBOX_URL=$TOOLBOX_URL
EOF
```

### Step 8: Deploy agent to Cloud Run
```bash
cd ~
PROJECT_ID=$(gcloud config get-value project)
SA_NAME=news-agent-sa

uvx --from google-adk==1.14.0 \
adk deploy cloud_run \
  --project=$PROJECT_ID \
  --region=us-central1 \
  --service_name=productivity-assistant \
  --with_ui \
  productivity_agent \
  -- \
  --service-account=${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
```

### Step 9: Test the agent
Open the Cloud Run URL. Test with:
- "Hello, what can you do?"
- "Show me all my tasks"
- "Create a task to prepare presentation with high priority"
- "Schedule a team meeting for 2026-04-02 at 15:00"
- "Save a note about deployment steps"
- "What meetings do I have coming up?"

Take screenshots for the PPT!
