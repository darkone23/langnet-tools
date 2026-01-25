# Development Guide for langnet-tools

## Build/Test Commands
- `just compose up -D` - Start all services (diogenes, langnet, zombie_reaper)
- `just compose list` - List running processes
- `just compose attach` - Attach to process-compose session
- `shellcheck .justscripts/*` - Lint all shell scripts
- `devenv shell` - Enter development environment with Python venv

## Code Style
- Shell scripts in `.justscripts/` must pass `shellcheck`
- Use `just` for task automation (not npm scripts or Makefiles)
- Process definitions belong in `process-compose.yaml`, not justfile
- Python code uses ruff for linting (defined in dependent repos)
- Activate venv with `source $DEVENV_STATE/venv/bin/activate` in shell

## Architecture
- This repo orchestrates langnet, diogenes, and whitakers-words services
- Each subproject has its own repository and devenv configuration
- Run `just clone <project>` to set up dependencies (langnet|whitakers|diogenes)