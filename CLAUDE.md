# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Workflow Orchestration

### 1. Plan Node Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately - don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One tack per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes - don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests - then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management

1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimat Impact**: Changes should only touch what's necessary. Avoid introducing bugs.


## Workspace Overview

This is a home directory workspace containing multiple independent projects spanning Python backends, Next.js frontends, and MCP protocol tooling. The primary active projects are:

- **bitflyer-autotrade-ai** — Python crypto trading bot for bitFlyer (BTC/JPY)
- **retailnext-ai** — Python/FastAPI AI-powered retail demo with OpenSearch
- **Project/mcp-server-quickstart** — TypeScript MCP server template
- **Project/fitness_nextjs_clean**, **Project/fitness-program** — Next.js fitness program sites

## Build & Run Commands

### bitflyer-autotrade-ai (Python 3.11+)

```bash
make setup          # Create venv, install deps
make lint           # Run ruff linter
make test           # Run pytest
make run            # Start paper trading

# Manual:
python -m bfbot.main --config configs/policy.yaml --paper
python -m bfbot.main --config configs/policy.yaml --live
python -m bfbot.backtest --config configs/policy.yaml --csv data/btcjpy_1m.csv
uvicorn bfbot.server:app --port 8000 --reload   # Web dashboard
```

### retailnext-ai (Python 3.9+)

```bash
docker-compose up -d                  # Start OpenSearch + Dashboards
pip install -r requirements.txt
python init_data.py                   # Initialize product data
uvicorn app:app --reload              # Run on :8000
```

Services: OpenSearch API `:9200`, Dashboards `:5601`, App `:8000`

### Project/mcp-server-quickstart (TypeScript)

```bash
npm install
npm run build       # Compile TypeScript (tsc)
npm start           # Run compiled server
npm run dev         # Build + run
npm run client      # Build + run test client
```

### Next.js Projects (fitness_nextjs_clean, fitness-program)

```bash
npm install
npm run dev         # Dev server on :3000
npm run build       # Production build
npm run start       # Production server
```

## Architecture Notes

### bitflyer-autotrade-ai

Source lives in `src/bfbot/`. Entry point is `main.py`. Key modules:

- `exchange.py` — CCXT wrapper for bitFlyer API
- `strategy/` — Trading strategy implementations (MA crossover)
- `risk.py` — Position sizing and risk limits
- `ledger.py` — Paper trading order/position tracking
- `backtest.py` — Backtesting engine against historical CSV data
- `server.py` — FastAPI dashboard with REST API and WebSocket ticker (`/ws/ticker`)
- `config.py` — Pydantic-based config loader from `configs/policy.yaml`

Configuration: `.env` for API credentials, `configs/policy.yaml` for strategy parameters. CI runs lint + test via `.github/workflows/ci.yml`.

### retailnext-ai

Single-app architecture in `app.py` (FastAPI) with `cookbook_rag.py` handling OpenAI embeddings and RAG logic. Frontend is vanilla HTML/JS/CSS served from root. Uses OpenSearch for product full-text search and OpenAI API for chatbot and image-based recommendations. Config in `config.py` and `.env` (OpenAI key).

### mcp-server-quickstart

TypeScript MCP server in `src/index.ts` using `@modelcontextprotocol/sdk`. Implements `ListToolsRequestSchema` and `CallToolRequestSchema` handlers. Currently exposes a `get_forecast` tool using the NWS API. Uses `StdioServerTransport`. Add new tools by extending the handlers in `index.ts`. Type declarations in `src/types.d.ts`. Output compiles to `build/`.
