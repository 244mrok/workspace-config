# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
