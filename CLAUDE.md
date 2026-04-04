# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Project Overview

This is a Model Context Protocol (MCP) server that provides JMAP (JSON Meta
Application Protocol) email management tools. It's built with Deno and
integrates with JMAP-compliant email servers like FastMail, Cyrus IMAP, and
Stalwart Mail Server. Published to JSR as `@temikus/jmap-mcp`.

## Development Commands

### Building and Running

- `deno task start` / `just start` - Run the MCP server
- `deno task watch` / `just watch` - Run with file watching

### Testing

- `deno task test` / `just test` - Run all tests
- `deno test --allow-env --allow-net src/tools/email_test.ts` - Run a single
  test file

### Code Quality

- `just check` - Run all checks: `deno fmt --check && deno lint && deno check`
- `just fmt` - Auto-format code
- `deno task hooks:install` - Install pre-commit/pre-push git hooks

### Release

- `just release [patch|minor|major]` - Bump version in deno.json, commit, tag,
  and push to `fork` branch, which triggers CI publish to JSR
- `just publish-dry` - Validate package without publishing

### Required Environment Variables

```bash
JMAP_SESSION_URL="https://your-jmap-server.com/.well-known/jmap"
JMAP_BEARER_TOKEN="your-bearer-token"
JMAP_ACCOUNT_ID="account-id"  # Optional, auto-detected if not provided
```

## Architecture

### Core Structure

- **Entry point**: `src/mod.ts` - Loads env vars, validates config with Zod,
  initializes `JamClient`, auto-detects account ID and capabilities, then
  registers tools based on available capabilities
- **Tool modules**: `src/tools/` - Each exports a
  `registerXxxTools(server, jam, accountId, ...)` function
  - `email.ts` - Email search, retrieval, mailbox management, and state-change
    operations
  - `submission.ts` - Email composition and sending
- **Tests**: `src/tools/email_test.ts` - Uses in-memory mock `JamClient` to
  avoid external JMAP server dependency
- **Utilities**: `src/utils.ts` - `formatError()` for consistent error handling

### Capability-Based Tool Registration

Tools are conditionally registered based on JMAP server capabilities reported at
session init:

- `urn:ietf:params:jmap:mail` → core email tools always registered
- Non-read-only account → mutation tools (`mark_emails`, `move_emails`,
  `delete_emails`)
- `urn:ietf:params:jmap:submission` + non-read-only → `send_email`,
  `reply_to_email`

### Tool Categories

1. **Email Search & Retrieval**: `search_emails`, `get_emails`, `get_threads`
2. **Incremental Sync**: `get_email_changes`, `get_search_updates` (state-based
   delta tracking)
3. **Mailbox Management**: `get_mailboxes`
4. **Email Actions** (non-read-only): `mark_emails`, `move_emails`,
   `delete_emails`
5. **Email Composition** (submission capability): `send_email`, `reply_to_email`

### Key Design Patterns

- **Functional programming style** - Pure functions where possible, side effects
  contained
- **Runtime validation** - All tool inputs validated with Zod schemas; types
  inferred via `z.infer<>`
- **Error handling** - All async operations wrapped in try-catch using
  `formatError()` utility
- **Console output** - Use `console.warn()` for server status messages (stdout
  reserved for MCP protocol)

### JMAP Integration

- Uses `jmap-jam` client library for JMAP RFC 8620/8621 compliance
- JMAP API accessed via `jam.api.Email.*`, `jam.api.Mailbox.*`,
  `jam.api.Thread.*`, `jam.api.EmailSubmission.*`
- Email IDs and thread IDs are server-specific strings, not UUIDs
- Mailbox hierarchies use parent-child relationships via `parentId`
- Keywords like `$seen`, `$flagged`, `$draft` control email state
- Date filters must use ISO 8601 format
- Pagination uses `position` and `limit` parameters

### Adding New Tools

1. Create Zod validation schemas for input parameters
2. Implement tool logic with proper error handling using `formatError()`
3. Register in the appropriate module (`email.ts` or `submission.ts`) inside its
   `registerXxxTools()` function
4. Conditionally register based on JMAP capabilities if needed
5. Add tests using the mock `JamClient` pattern in `email_test.ts`

## CI/CD

GitHub Actions (`.github/workflows/publish.yml`) runs on push to `fork` branch
or version tags:

1. Format check, lint, type check
2. Publishes to JSR only when a version tag is present (OIDC auth, no secrets
   needed)
