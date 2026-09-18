# Changelog

Notable changes to AdServer are recorded here. Versions use Semantic Versioning
(`MAJOR.MINOR.PATCH`); dates use `YYYY-MM-DD`.

## Unreleased

## 0.4.0 — 2026-09-18

### Added

- Daily activity graph on `/dashboard` with an impressions/clicks selector and
  filters for all ads, a client, a campaign, or a single ad, including inactive ads.
- Editable inclusive date range, defaulting to the last 30 days, with a maximum
  of 366 days. Missing days appear as zero; dates use the database session time zone.
- Browser-rendered SVG graph with daily-value tooltips and an accessible expandable
  table. JavaScript fetches `/dashboard/graph` JSON and updates on filter changes
  without a page reload. Selections persist in the URL; no CDN is used.
- Integration coverage for date boundaries, zero days, both metrics, scopes,
  rendered selections, and invalid input. No database migration is required.

## 0.3.0 — 2026-09-14

### Added

- An unauthenticated, read-only `/dashboard` with all-time impressions, clicks,
  CTR, serving-ad totals, and per-ad figures grouped visually by client/campaign.
- Responsive table, empty state, manual refresh, and escaped names. Inactive ads
  retain their history; serving status includes parent live flags.
- Integration tests for aggregates, zero-event ads, disabled parents, historical
  unassigned events, safe rendering, and read-only requests.

No database migration or new dependencies are required.

## 0.2.1 — 2026-09-14

### Fixed

- Render headings, body text, display URLs, and image-path attributes with HTML
  escaping. `body_text` is plain text; embedded markup is displayed literally.
- Correct the advertisement template's closing body tag.
- Return `application/json` from the root and client-list routes.
- Require absolute HTTP/HTTPS destinations with a host and no whitespace, control
  characters, or backslashes on ORM ad inserts and updates. Reject invalid stored
  destinations at click time with HTTP 422, without redirecting or recording a click.

### Added

- Regression tests for markup/attribute injection, JSON response types, destination
  validation, and invalid destinations already stored in the database.
- URI declared as a runtime dependency. No database migration is required.

## 0.2.0 — 2026-09-14

### Added

- Each served impression gets a random 128-bit token. Both click links carry that
  token instead of the publisher URL; clicks link to the matching impression and
  copy its recorded referer.
- Nullable impression tokens and click-to-impression foreign keys, with forward
  and rollback migrations. Historical records remain unlinked.
- Integration coverage for valid, missing, malformed, unknown, and wrong-ad tokens,
  repeated clicks, missing publisher metadata, and migration/rollback behavior.

### Compatibility and deployment

- Apply `db/patch_5.sql` to an existing database before deploying this version.
  Fresh databases created with `db/adserver.sql` already include the change.
- Install the now-required `Crypt::URandom` dependency.
- Existing hash-only links still redirect and accept the legacy `referer`
  parameter. Invalid or wrong-ad tokens still redirect but record no attribution.
- Roll back the application before using `db/unpatch_5.sql`; the reverse migration
  removes tokens and impression links but preserves event rows and referer values.

## 0.1.0 — 2026-09-14

First SemVer release, replacing the previous `0.1` version string. Earlier
development was not assigned separate release versions in this changelog.

### Added

- A codebase overview covering architecture, configuration, utilities, and known
  limitations.
- Regression tests for image and text click links, including referer URL encoding.
- Isolated MariaDB integration tests for ad selection, impression and click
  recording, redirects, missing records, empty selections, and live flags.
- Test setup instructions and explicit test dependencies.

### Changed

- `$AdServer::VERSION` now uses SemVer; the root endpoint reports `0.1.0`.
- Database-backed tests use disposable local MariaDB instances instead of the
  application's configured database.

### Fixed

- Image click links now pass the referer, matching text links. Both links use a
  shared tracking URL with URL-encoded attribution and HTML-escaped attributes.
- Direct lookups now retain the live-flag condition when DBIx::Class resolves a
  unique key. Disabled ads cannot serve or redirect, and disabled clients and
  campaigns cannot serve ads. Existing click links to live ads still work when
  their client or campaign is disabled.

### Existing functionality

- Serve a specific ad or randomly select a live ad within a campaign or client.
- Record impressions with request metadata and clicks before redirecting to the
  advertiser.
- List live clients and report application version and hostname.
- Manage clients, campaigns, ads, hashes, and database imports/exports through
  command-line utilities.
