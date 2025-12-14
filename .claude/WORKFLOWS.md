# Claude Code Marketplace Workflows

This project uses a standardized workflow system for research, planning, implementation, and quality assurance.

## Generated for: Claude Code Plugin Marketplace

---

## Available Commands

### /elixir-interview

Gather context through interactive questioning to guide workflow execution.

**Usage**:
```bash
/elixir-interview              # Auto-detect workflow phase
/elixir-interview research     # Before research phase
/elixir-interview plan         # Before planning phase
/elixir-interview implement    # Before implementation phase
```

**Output**: Interview documents saved to `.thoughts/interview/interview-YYYY-MM-DD-phase-topic.md`

**What it does**:
- Intelligently detects workflow phase (pre-research, pre-plan, pre-implement)
- Formulates context-specific questions based on actual task
- Captures user preferences and constraints
- Generates actionable directives for next workflow step
- Creates interview document for reference

---

### /elixir-research

Research the codebase to answer questions and document existing implementations.

**Usage**:
```bash
/elixir-research "How does the plugin hook system work?"
/elixir-research "What is the marketplace structure?"
```

**Output**: Research documents saved to `.thoughts/research/research-YYYY-MM-DD-topic.md`

**What it does**:
- Spawns parallel research agents (finder, analyzer)
- Documents findings with file:line references
- Creates comprehensive research document with YAML frontmatter
- Can detect and use interview context if available

---

### /elixir-plan

Create detailed implementation plans with success criteria.

**Usage**:
```bash
/elixir-plan "Add monitoring plugin"
/elixir-plan "Refactor hook test framework"
```

**Output**: Plans saved to `.thoughts/plans/YYYY-MM-DD-description.md`

**Plan Structure**: Detailed phases

**What it does**:
- Gathers context via research agents
- Presents design options with pros/cons
- Creates phased plan with specific file changes
- Includes automated and manual success criteria
- Can detect and use interview context if available

---

### /elixir-implement

Execute implementation plans with automated verification.

**Usage**:
```bash
/elixir-implement "2025-10-27-monitoring-plugin"
/elixir-implement   # Will prompt for plan selection
```

**Verification Commands**:
- Test: `./test/run-all-tests.sh`
- JSON validation: `jq . <file>`
- Script execution tests: Based on plan

---

### /elixir-qa

Validate implementation against success criteria and project quality standards.

**Usage**:
```bash
/elixir-qa                    # General health check
/elixir-qa "plan-name"        # Validate specific plan implementation
```

**Quality Gates**:
- All hook tests pass (`./test/run-all-tests.sh`)
- JSON structure validation (marketplace.json, plugin.json, hooks.json)
- Documentation completeness
- Script correctness and exit codes
- Version management consistency

---

### /elixir-oneshot

Complete workflow - research, plan, implement, and validate a feature.

**Usage**:
```bash
/elixir-oneshot "Add security scanning plugin"
```

**What it does**:
1. Research existing patterns
2. Create implementation plan
3. Execute plan with verification
4. Validate against quality gates
5. Present comprehensive summary

---

## Workflow Sequence

The recommended workflow for new features:

1. **Interview** (`/elixir-interview`) - Gather context and preferences
2. **Research** (`/elixir-research`) - Understand current implementation
3. **Plan** (`/elixir-plan`) - Create detailed implementation plan
4. **Implement** (`/elixir-implement`) - Execute plan with verification
5. **QA** (`/elixir-qa`) - Validate against success criteria

**Alternative: One-shot workflow**

For simpler features, use `/elixir-oneshot` to execute all steps automatically.

---

## Customization

These commands were generated based on your project configuration. You can edit them directly:

- `.claude/commands/elixir-interview.md`
- `.claude/commands/elixir-research.md`
- `.claude/commands/elixir-plan.md`
- `.claude/commands/elixir-implement.md`
- `.claude/commands/elixir-qa.md`
- `.claude/commands/elixir-oneshot.md`

To regenerate: `/workflow-generator`

---

## Project Configuration

**Project Type**: Claude Code Plugin Marketplace
**Test Command**: `./test/run-all-tests.sh`
**Documentation**: `.thoughts/`
**Planning Style**: Detailed phases

**Quality Tools**:
- Hook test validation (exit codes, JSON output)
- JSON structure validation with jq
- Script correctness verification
- Documentation completeness checks

---

## Document Structure

```
.thoughts/
├── interview/          # Interview context documents
├── research/           # Research documents
└── plans/              # Implementation plans
```

---

## Quick Start

### 1. Gather Context (Optional but Recommended)

```bash
/elixir-interview
```

This will:
- Auto-detect workflow phase
- Ask context-specific questions
- Generate actionable directives
- Save to `.thoughts/interview/interview-YYYY-MM-DD-phase-topic.md`

### 2. Research the Codebase

```bash
/elixir-research "How do PostToolUse hooks work?"
```

This will:
- Spawn parallel research agents
- Document findings with file:line references
- Use interview context if available
- Save to `.thoughts/research/research-YYYY-MM-DD-topic.md`

### 3. Create an Implementation Plan

```bash
/elixir-plan "Add performance monitoring plugin"
```

This will:
- Gather context via research
- Present design options
- Create phased plan with success criteria
- Use interview context if available
- Save to `.thoughts/plans/YYYY-MM-DD-feature.md`

### 4. Execute the Plan

```bash
/elixir-implement "2025-10-27-performance-monitoring"
```

This will:
- Read the plan
- Execute phase by phase
- Run verification after each phase
- Update checkmarks in plan
- Pause for confirmation between phases

### 5. Validate Implementation

```bash
/elixir-qa "performance-monitoring"
```

This will:
- Run all quality gate checks
- Validate against plan success criteria
- Generate validation report
- Provide actionable feedback

---

## Workflow Example

**Scenario**: Adding a new security scanning plugin

```bash
# 1. Gather context about requirements
/elixir-interview plan

# 2. Research existing security plugin patterns
/elixir-research "How are security plugins like sobelow structured?"

# 3. Create implementation plan
/elixir-plan "Add SAST security scanning plugin"

# 4. Execute the plan
/elixir-implement "2025-10-27-sast-plugin"

# 5. Validate implementation
/elixir-qa "sast-plugin"
```

---

## Interview-Driven Workflow

The `/elixir-interview` command helps gather context before each workflow phase:

**Before Research:**
```bash
/elixir-interview research
/elixir-research "Your research query"
```

**Before Planning:**
```bash
/elixir-interview plan
/elixir-plan "Your feature description"
```

**Before Implementation:**
```bash
/elixir-interview implement
/elixir-implement "plan-name"
```

The interview command asks context-specific questions and generates directives that guide the subsequent workflow step.

---

## Re-generate Commands

To regenerate these commands with different settings:

```bash
/workflow-generator
```

This will ask questions again and regenerate all commands.

---

## Next Steps

1. ✅ Try your first interview: `/elixir-interview`
2. ✅ Try your first research: `/elixir-research "marketplace structure"`
3. Read full workflow docs (you're reading it!)
4. Customize commands as needed (edit `.claude/commands/elixir-*.md`)
5. Start your first planned feature!

**Need help?** Each command has detailed instructions in its markdown file.
