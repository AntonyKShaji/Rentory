#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

git config core.hooksPath "$repo_root/.githooks"

echo "✅ Local Git protection enabled:"
echo "   - commits to main are blocked"
echo "   - pushes to main are blocked"
echo "   - use the dev branch for active development"
