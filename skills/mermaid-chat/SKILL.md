---
name: mermaid-chat
description: Render feature flows and behavioral paths as Mermaid diagrams directly in chat. Use when a user asks to visualize, diagram, map, or sketch a feature flow and wants either a rendered image or terminal-friendly text.
---

# Mermaid Chat

Turn the requested behavior into a compact Mermaid diagram, render it, and show the result in the response. Preserve the `.mmd` source beside rendered artifacts when working in a repository.

## Arguments

- `$mermaid-chat image <request>` selects PNG output. Render with `scripts/render-mermaid.sh image <input.mmd> [output.png]`, then inspect the PNG and embed or link it in the response.
- `$mermaid-chat ascii <request>` selects terminal-safe text. Render with `scripts/render-mermaid.sh ascii <input.mmd>` and include the output in a fenced `text` block.
- Treat the argument as authoritative. This lets the user retry the same diagram with the other renderer when one renders poorly.
- When the argument is omitted, choose `image` if the chat can display images; otherwise choose `ascii`.
- If rendering cannot run, return the Mermaid source in a fenced `mermaid` block and state the missing dependency briefly.

## Model the flow

Prefer `flowchart TD` for feature behavior and `flowchart LR` for short pipelines. Use sequence diagrams only when message order between actors is the point. Keep labels short, split dense flows into subgraphs, and label decision edges.

Make status understandable without color:

- Pass: prefix the node label with `✓` (`[OK]` in ASCII mode).
- Fail: prefix with `✕` (`[X]` in ASCII mode).
- Warning: prefix with `!`.
- Neutral: no status prefix.

For image output, also apply these classes:

```mermaid
classDef pass fill:#DCFCE7,stroke:#16A34A,color:#14532D
classDef fail fill:#FEE2E2,stroke:#DC2626,color:#7F1D1D
classDef warning fill:#FEF3C7,stroke:#D97706,color:#78350F
classDef neutral fill:#F3F4F6,stroke:#6B7280,color:#111827
```

Assign classes explicitly, for example `class success pass`, `class rejected fail`, and `class retry warning`. Use color as reinforcement, never as the only status signal.

## Verify and present

Render the final source. A successful renderer exit is the syntax check. For PNG, visually inspect the artifact and simplify labels or direction if text overlaps or the flow is hard to scan. Present the diagram first, followed by at most a short legend or explanation unless the user asks for analysis.
