# AI-Multi-Agent-Project-Code_Review_Parallel

Scripts that execute parallel AI agents for project code maintenance.

Щn 2026-04-20, the models used in the script were free (with some limits)

## Overview

This project contains a bash script (`project_Review.sh`) that orchestrates multiple AI agents to perform parallel code reviews using the opencode CLI tool. The system implements a multi-agent architecture where specialized agents analyze different aspects of the codebase simultaneously, then integrate their findings into a comprehensive report.

## How It Works

The review process follows these stages:

1. **Parallel Analysis Phase** - Three agents run concurrently:
   - **Architect** (nemotron-3-super-free): Evaluates architectural compliance with Railway FSM and Token Economy principles
   - **Programmer** (minimax-m2.5-free): Checks code style adherence to Railway FSM coding standards
   - **QA Engineer** (nemotron-3-super-free): Identifies potential issues, error handling problems, and test coverage gaps

2. **Integration Phase** - A fourth agent synthesizes the three reports into a final comprehensive review

## Key Features

- **Parallel Execution**: Reduces total review time by running agents simultaneously
- **Specialized Agents**: Each agent has a specific role and expertise
- **Timing Tracking**: Measures and reports execution time for each agent
- **Specification-Based Review**: Checks against Railway FSM and Token Economy methodologies
- **Automated Report Generation**: Produces markdown reports for each analysis phase
- **Temporary File Management**: Cleans up temporary files after execution

## Requirements

- opencode CLI tool installed (`npm install -g opencode`)
- Bash shell environment
- Project source code to review (typically in `src/` directory)

## Usage

```bash
./project_Review.sh
```

The script will:
1. Clean any previous review reports
2. Validate required specification files exist
3. Check for opencode installation
4. Collect project files for analysis
5. Launch three AI agents in parallel for architectural, code style, and QA reviews
6. Wait for all parallel agents to complete
7. Launch an integrator agent to combine findings
8. Display timing statistics and report locations

## Output

Reports are generated in the `src_Review/` directory:
- `review_Architecture.md` - Architect's analysis
- `review_Code_Style.md` - Programmer's code style review
- `review_QA.md` - QA engineer's findings
- `review_Final.md` - Integrated final report with summary and action plan

## Specifications Used

The review process evaluates code against:
- Railway FSM (Finite State Machine) programming style principles
- Token Economy hierarchical context management

These specifications are loaded from the skills directory during execution.