#!/usr/bin/env bash
# Idempotent Azure DevOps project creation script
# Usage: ./create-project.sh <org-url> <project-name> [visibility] [description]

set -euo pipefail

ORG_URL="${1:-}"
PROJECT_NAME="${2:-}"
VISIBILITY="${3:-private}"
DESCRIPTION="${4:-Created by automation script}"

err(){ echo "ERROR: $*" >&2; exit 1; }

if [[ -z "$ORG_URL" || -z "$PROJECT_NAME" ]]; then
  echo "Usage: $0 <org-url> <project-name> [visibility] [description]"
  exit 2
fi

command -v az >/dev/null 2>&1 || err "Azure CLI (az) not found. Install from https://aka.ms/azcli"

# Ensure azure-devops extension
if ! az extension show --name azure-devops >/dev/null 2>&1; then
  echo "Installing azure-devops extension..."
  az extension add --name azure-devops >/dev/null || err "Failed to install azure-devops extension"
fi

# If local PAT file exists, source it to set AZDO_PAT, then export for az devops
if [[ -f "$(dirname "$0")/.azdo_pat" ]]; then
  # shellcheck disable=SC1090
  source "$(dirname "$0")/.azdo_pat"
  if [[ -n "${AZDO_PAT:-}" ]]; then
    export AZURE_DEVOPS_EXT_PAT="$AZDO_PAT"
  fi
fi

az devops configure --defaults organization="$ORG_URL" >/dev/null

# Idempotent check: project exists?
if az devops project show --project "$PROJECT_NAME" --org "$ORG_URL" >/dev/null 2>&1; then
  echo "Project '$PROJECT_NAME' already exists in '$ORG_URL'. Skipping creation."
  exit 0
fi

echo "Creating Azure DevOps project: $PROJECT_NAME (visibility: $VISIBILITY)"
create_output=$(az devops project create --name "$PROJECT_NAME" --visibility "$VISIBILITY" --description "$DESCRIPTION" --org "$ORG_URL" 2>&1) || {
  echo "Failed to create project:" >&2
  echo "$create_output" >&2
  exit 3
}

echo "Project created: $PROJECT_NAME"
echo "$create_output"
# Retrieve project ID and persist local env file
proj_id=$(az devops project show --project "$PROJECT_NAME" --org "$ORG_URL" --query id -o tsv 2>/dev/null || true)
env_file="$(dirname "$0")/.azdo_env"
{
  echo "AZDO_ORG_URL=$ORG_URL"
  echo "AZDO_PROJECT=$PROJECT_NAME"
  echo "AZDO_PROJECT_ID=$proj_id"
} > "$env_file"

echo "Wrote project info to $env_file"
exit 0
