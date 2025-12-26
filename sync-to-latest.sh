#!/bin/bash

# Sync essentials-claude-code to latest version
# Run this on any environment stuck on old commits

set -e

echo "🔍 Current commit:"
git log --oneline -1

echo ""
echo "📥 Fetching latest from origin..."
git fetch origin

echo ""
echo "📊 Commits you're behind:"
git log --oneline HEAD..origin/main

echo ""
echo "⬇️  Pulling latest changes..."
git pull origin main

echo ""
echo "✅ Updated to:"
git log --oneline -1

echo ""
echo "📝 Recent changes pulled:"
git log --oneline -5

echo ""
echo "✨ Sync complete! You are now on the latest version."
echo ""
echo "Note: If you're running Claude Code, you may need to restart it to pick up the new prompts."
