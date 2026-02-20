"""
agents/boss_agent.py
────────────────────
Builds and exposes the Boss food-ordering agent.

  create_agent()  — returns a configured LangGraph ReAct agent
  run_chat_loop() — interactive CLI chat loop (mirrors the notebook)

Usage:
    python -m agents.boss_agent
"""

import os
import uuid
import warnings
from datetime import datetime

from langchain_openai import ChatOpenAI
from langgraph.checkpoint.memory import MemorySaver
from langgraph.prebuilt import create_react_agent

from prompts import BASE_SYSTEM_PROMPT
from budget import build_cart
from cart import add_to_cart, get_cart
from favorites import search_favorites
from meals import search_meals

warnings.filterwarnings(
    "ignore",
    message="create_react_agent has been moved",
)

# All tools exposed to the agent
AGENT_TOOLS = [search_meals, search_favorites, build_cart, add_to_cart, get_cart]


def create_agent(model: str = "google/gemini-2.0-flash-001"):
    """
    Instantiate the Boss agent with memory checkpointing.

    Args:
        model: OpenRouter model identifier.
               Defaults to Gemini Flash for reliable tool-calling.

    Returns:
        A compiled LangGraph ReAct agent.
    """
    llm = ChatOpenAI(
        api_key=os.environ["OPENROUTER_API_KEY"],
        base_url="https://openrouter.ai/api/v1",
        model=model,
        temperature=0.0,
        max_tokens=2048,  # Reduce token usage
    )

    return create_react_agent(
        model=llm,
        tools=AGENT_TOOLS,
        prompt=BASE_SYSTEM_PROMPT,
        checkpointer=MemorySaver(),
    )


def run_chat_loop(agent=None, model: str = "google/gemini-2.0-flash-001") -> None:
    """
    Run an interactive CLI chat session with the Boss agent.

    Args:
        agent : Pre-built agent (optional). If None, one is created via create_agent().
        model : Model to use when building a fresh agent.
    """
    if agent is None:
        agent = create_agent(model=model)

    thread_id = str(uuid.uuid4())
    config = {"configurable": {"thread_id": thread_id}}

    print(f"Boss ready! Thread: {thread_id}")
    print("Type 'exit' / 'quit' / 'bye' to stop.\n")

    while True:
        user_input = input("You: ").strip()
        if not user_input:
            continue
        if user_input.lower() in {"exit", "quit", "bye"}:
            print("Goodbye! 👋")
            break

        # Inject current time and location as hidden context
        now = datetime.now().strftime("%Y-%m-%d %H:%M")
        msg = f"[context: current time={now}, location=Cairo EG]\n{user_input}"

        result = agent.invoke(
            {"messages": [{"role": "user", "content": msg}]},
            config,
        )
        print("Boss:", result["messages"][-1].content)
        print("-" * 70)


if __name__ == "__main__":
    run_chat_loop()
