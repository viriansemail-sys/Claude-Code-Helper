# graphify

**graphify** transforms folders of code, documents, papers, and images into navigable knowledge graphs with community detection, audit trails, and multiple output formats.

## Core Capability

"Turn any folder of files into a navigable knowledge graph with community detection, an honest audit trail, and three outputs: interactive HTML, GraphRAG-ready JSON, and a plain-language GRAPH_REPORT.md."

## Key Features

1. **Persistent Graph** – relationships stored in `graph.json` survive across sessions
2. **Honest Audit Trail** – every edge tagged EXTRACTED, INFERRED, or AMBIGUOUS
3. **Cross-Document Discovery** – community detection reveals unexpected connections

## Primary Use Cases

- Understanding unfamiliar codebases before modification
- Synthesizing reading lists (papers, tweets, notes) into one queryable graph
- Citation and concept graph extraction from research corpora
- Growing personal knowledge bases from raw input folders

## Invocation Syntax

```
/graphify [<path>] [--mode deep] [--update] [--cluster-only]
/graphify [<path>] [--html] [--svg] [--graphml] [--neo4j] [--mcp] [--watch] [--wiki]
/graphify query "<question>" [--dfs] [--budget N]
/graphify path "Node A" "Node B"
/graphify explain "Node Name"
/graphify add <url> [--author Name] [--contributor Name]
```

## Execution Pipeline

The agent performs nine steps in order:

1. **Install/verify** graphify package
2. **Detect files** – characterize corpus by type and size
3. **Extract** – structural extraction (AST) runs in parallel with semantic extraction (LLM subagents)
4. **Build graph** – merge results, cluster into communities, compute metrics
5. **Label communities** – assign 2–5 word names based on node content
6. **Visualize** – generate HTML (always), Obsidian vault (if `--obsidian`), Canvas, and optional formats
7. **Export** – Neo4j, SVG, GraphML, or MCP server (as flags specify)
8. **Benchmark** – token compression analysis for large corpora
9. **Report** – save manifest, update cost tracker, present God Nodes, Surprising Connections, and Suggested Questions

## Edge Classification

- **EXTRACTED** (confidence 1.0): explicit in source (imports, calls, citations)
- **INFERRED** (confidence 0.6–0.9): reasonable deduction from structure
- **AMBIGUOUS** (confidence 0.1–0.3): uncertain; flagged for review

## Advanced Options

- `--mode deep`: aggressive INFERRED edges; slower but richer
- `--update`: incremental re-extraction of changed files only
- `--cluster-only`: re-run clustering on existing graph without re-extracting
- `--watch`: monitor folder, auto-rebuild code changes (no LLM cost)
- `--mcp`: expose graph as stdio MCP server for agent queries

## Query Interface

**BFS** (default): broad context—"What is X connected to?"
**DFS** (`--dfs`): trace chains—"How does X reach Y?"

Graph traversals are depth-limited and budget-aware; answers cite source locations.

## Architectural Principles

- **No hallucination**: answer only from graph content; admit gaps
- **Parallel subagents**: all semantic extraction dispatched in one message to enable true parallelism
- **Token tracking**: cumulative cost saved in `cost.json` across runs
- **Safe re-runs**: graph updates use MERGE logic (no duplicates on repeated imports)

## PyPI Package

Install the backend with: `pip install graphifyy` (CLI and skill command remain `graphify`)
Source: https://github.com/safishamsi/graphify
