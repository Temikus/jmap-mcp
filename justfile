# jmap-mcp justfile

# List available recipes
default:
    @just --list

# Run the MCP server
start:
    deno task start

# Run with file watching
watch:
    deno task watch

# Run tests
test:
    deno task test

# Check formatting, lint, and types
check:
    deno fmt --check
    deno lint
    deno check

# Format code
fmt:
    deno fmt

# Dry-run publish (validate without publishing)
publish-dry:
    deno publish --dry-run

# Tag and push a release to trigger JSR publishing
# Usage: just release [patch|minor|major]
release bump="patch":
    #!/usr/bin/env bash
    set -euo pipefail
    current=$(grep '"version"' deno.json | head -1 | sed 's/.*"version": "\(.*\)".*/\1/')
    IFS='.' read -r major minor patch <<< "$current"
    case "{{ bump }}" in
        major) major=$((major + 1)); minor=0; patch=0 ;;
        minor) minor=$((minor + 1)); patch=0 ;;
        patch) patch=$((patch + 1)) ;;
        *) echo "Error: bump must be patch, minor, or major"; exit 1 ;;
    esac
    next="$major.$minor.$patch"
    echo "Bumping $current → $next..."
    sed -i '' "s/\"version\": \"$current\"/\"version\": \"$next\"/" deno.json
    git add deno.json
    git commit -m "chore: bump version to $next"
    git tag "$next"
    git push fork fork
    git push fork "$next"
    echo "Tag $next pushed — CI will publish to @temikus/jmap-mcp on JSR."
