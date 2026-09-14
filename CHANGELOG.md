# Changelog

Notable changes to AdServer are recorded here. Versions use Semantic Versioning
(`MAJOR.MINOR.PATCH`); dates use `YYYY-MM-DD`.

## Unreleased

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
