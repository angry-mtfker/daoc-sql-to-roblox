"""Build Agent using Microsoft Agent Framework in Python
# Run this python script
> pip install anthropic agent-framework==1.0.0b260107
> python <this-script-path>.py
"""

import asyncio
import os

from agent_framework import MCPStdioTool, MCPStreamableHTTPTool, ToolProtocol, FunctionCallContent
from agent_framework.openai import OpenAIChatClient
from agent_framework.anthropic import AnthropicClient
from anthropic import AsyncAnthropicFoundry
from openai import AsyncOpenAI

# To authenticate with the model you will need to generate a personal access token (PAT) in your GitHub settings.
# Create your PAT token by following instructions here: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
openaiClient = AsyncOpenAI(
    base_url = "https://models.github.ai/inference",
    api_key = os.environ["GITHUB_TOKEN"],
)

AGENT_NAME = "ai-agent"
AGENT_INSTRUCTIONS = "Your only job is the recursively seach through every file for errors and to inact fixes for these errors in a way that is the least destructive to the code"

# User inputs for the conversation
USER_INPUTS = [
    "Hello",
]

def create_mcp_tools() -> list[ToolProtocol]:
    return [
    ]

async def main() -> None:
    async with (
        OpenAIChatClient(
            async_client=AsyncOpenAI(
                base_url = "https://models.github.ai/inference",
                api_key = os.environ["GITHUB_TOKEN"],
                default_query = {
                    "api-version": "2024-08-01-preview",
                },
            ),
            model_id="openai/gpt-4.1-mini"
        ).create_agent(
            instructions="Your job is to recursively check the Roblox Experience scripts for ways to improve on the existing code",
            temperature=1,
            top_p=1,
            tools=[
                MCPStreamableHTTPTool(
                    name="AmplitudeMCPServer".replace("-", "_"),
                    description="MCP server for AmplitudeMCPServer",
                    url="https://mcp.amplitude.com/mcp"
                ),
            ]
        ) as Optimization_agent,
        OpenAIChatClient(
            async_client=openaiClient,
            model_id="ai21-labs/AI21-Jamba-1.5-Mini"
        ).create_agent(
            instructions=AGENT_INSTRUCTIONS,
            temperature=0.8,
            top_p=0.1,
            tools=[
                *create_mcp_tools(),
                Optimization_agent.as_tool(
                    name="Optimization",
                    description="Always active",
                ),
            ],
        ) as agent
    ):
        # Process user messages
        for user_input in USER_INPUTS:
            print(f"\n# User: '{user_input}'")
            printed_tool_calls = set()
            async for chunk in agent.run_stream([user_input]):
                # log tool calls if any
                function_calls = [
                    c for c in chunk.contents 
                    if isinstance(c, FunctionCallContent)
                ]
                for call in function_calls:
                    if call.call_id not in printed_tool_calls:
                        print(f"Tool calls: {call.name}")
                        printed_tool_calls.add(call.call_id)
                if chunk.text:
                    print(chunk.text, end="")
            print("")
        
        print("\n--- All tasks completed successfully ---")

    # Give additional time for all async cleanup to complete
    await asyncio.sleep(1.0)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nProgram interrupted by user")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        import traceback
        traceback.print_exc()
    finally:
        print("Program finished.")
