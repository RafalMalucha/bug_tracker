#!/bin/bash
# submodule_sync.sh

echo "Syncing all submodules to latest main..."

git submodule foreach '
  echo "In $name"
  git checkout main
  git pull origin main
'

git add .
git commit -m "Sync submodules to latest main branches"
git push

echo "Submodule sync complete."
