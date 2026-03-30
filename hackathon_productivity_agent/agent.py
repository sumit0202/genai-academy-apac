import os
from dotenv import load_dotenv
from google.adk.agents import Agent
from google.adk.tools.tool_context import ToolContext
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
    instruction="""You are a Multi-Agent Productivity Assistant. You coordinate three specialized sub-agents
to help users manage their productivity.

Your sub-agents are:
1. **task_agent** - For task management (create, list, update, delete tasks)
2. **schedule_agent** - For schedule/calendar management (create, list, delete events)
3. **notes_agent** - For notes management (create, list, search, delete notes)

When a user makes a request:
- Analyze what they need
- Route to the appropriate sub-agent
- For multi-step requests (e.g., "Create a task and schedule a meeting for it"),
  coordinate between multiple sub-agents sequentially

For greetings or general questions, respond directly and explain your capabilities.

Example routing:
- "Add a task to review the report" -> task_agent
- "Schedule a meeting for tomorrow at 3pm" -> schedule_agent
- "Save a note about project ideas" -> notes_agent
- "Create a task and schedule a follow-up" -> task_agent then schedule_agent
""",
    sub_agents=[task_agent, schedule_agent, notes_agent],
)
