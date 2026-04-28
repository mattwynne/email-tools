# Manulife Claims Submission Tool

**Date:** 2026-04-27

## Overview

A CLI script that takes a PDF receipt, extracts claim details via Claude API, asks the user to confirm, then submits the claim to the Manulife GroupNet portal via Playwright.

## Usage

```
npx ts-node scripts/manulife-claim.ts receipt.pdf
```

## Architecture

Single TypeScript script (`scripts/manulife-claim.ts`) with three sequential stages:

1. **Extract** — read the PDF, send to Claude API, get back structured claim data
2. **Confirm** — print extracted fields, allow inline corrections, press Enter to proceed
3. **Submit** — Playwright logs into Manulife GroupNet and fills/submits the claim form

## Extracted Fields

Claude extracts the following from the PDF:

| Field | Notes |
|---|---|
| `patient_name` | Matched against configured list of family members |
| `provider_name` | Name of the healthcare provider |
| `service_date` | YYYY-MM-DD format |
| `amount` | Dollar amount |
| `claim_type` | Extracted from receipt (e.g. "family therapy") — not defaulted |

If Claude cannot confidently extract a field, it is left blank. Blank required fields block submission until filled in at the confirmation step.

## Confirmation Step

Prints extracted fields as a numbered list. User can type corrections in `2=John` style before pressing Enter to proceed. A final `Submit? (y/n)` prompt is shown before Playwright clicks the submit button.

## Playwright Behaviour

- Runs in **headed mode** (visible browser) so the user can see what's happening and intervene
- Navigates to `https://groupnet.manulife.ca`
- Logs in with credentials from env vars
- Navigates to Submit a Claim
- Fills the form with confirmed claim data
- Waits for final `Submit? (y/n)` confirmation before clicking submit

## Configuration

Credentials and family member list stored in `.env`:

```
MANULIFE_USERNAME=...
MANULIFE_PASSWORD=...
MANULIFE_FAMILY_MEMBERS=Matt,Jane,Child1
ANTHROPIC_API_KEY=...
```

Loaded via `dotenv`.

## Dependencies to Add

- `playwright` — browser automation
- `dotenv` — env var loading
- `@anthropic-ai/sdk` — Claude API client (supports PDFs natively as document content blocks, no separate PDF parser needed)

## Out of Scope

- Multiple claim types beyond what the portal supports
- Batch/multi-receipt submission
- Headless mode (intentionally headed for safety)
- Storing submission history
