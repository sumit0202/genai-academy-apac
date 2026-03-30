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
