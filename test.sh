#!/usr/bin/env bash
# Test script for JiraTUI Nix flake

set -e

echo "🔨 Building JiraTUI package..."
nix build .#jiratui

echo "✅ Build successful!"

echo "📦 Checking package info..."
nix flake show

echo "🔍 Testing package..."
./result/bin/jiratui --help

echo "✨ All tests passed!"

echo ""
echo "To use this flake:"
echo "1. Add it to your flake inputs"
echo "2. Import the Home Manager module"
echo "3. Configure your Jira credentials"
echo "4. Run 'jiratui ui' to start the TUI"
echo ""
echo "See README.md for detailed instructions."
