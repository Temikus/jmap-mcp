#!/bin/sh
set -e

# Validate required environment variables (output to stderr to preserve MCP stdio protocol)
if [ -z "$JMAP_SESSION_URL" ]; then
    echo "ERROR: JMAP_SESSION_URL environment variable is required" >&2
    exit 1
fi

if [ -z "$JMAP_BEARER_TOKEN" ]; then
    echo "ERROR: JMAP_BEARER_TOKEN environment variable is required" >&2
    exit 1
fi

MCP_TRANSPORT="${MCP_TRANSPORT:-stdio}"
MCP_HOST="${MCP_HOST:-0.0.0.0}"
MCP_PORT="${MCP_PORT:-3000}"

DENO_CMD="deno run \
    --allow-net \
    --allow-env=JMAP_SESSION_URL,JMAP_BEARER_TOKEN,JMAP_ACCOUNT_ID \
    jsr:@temikus/jmap-mcp@${JMAP_MCP_VERSION}"

case "${MCP_TRANSPORT}" in
    stdio)
        exec $DENO_CMD "$@"
        ;;
    sse)
        exec catatonit -- mcp-proxy \
            --port="${MCP_PORT}" \
            --host="${MCP_HOST}" \
            --pass-environment \
            -- $DENO_CMD "$@"
        ;;
    *)
        echo "ERROR: Unknown MCP_TRANSPORT value '${MCP_TRANSPORT}'. Use 'stdio' or 'sse'." >&2
        exit 1
        ;;
esac
