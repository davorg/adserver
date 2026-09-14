# adserver

## What?

This is a simple app to serve ads and track clicks on those ads.

## Why?

Because I'm a programmer. And programmers see any problem as an
excuse to write code.

## Versioning

The application uses Semantic Versioning (`MAJOR.MINOR.PATCH`). The version in
`AdServer/lib/AdServer.pm` is the source of truth for both the root endpoint's
`ver` field and Perl package metadata.

Record changes in [CHANGELOG.md](CHANGELOG.md) under `Unreleased`. When releasing,
bump `$VERSION` and move those entries into a dated version section in the same
commit. Use patch releases for compatible fixes and minor releases for new
functionality. While the application is pre-1.0, breaking changes also require a
minor bump and an explicit changelog note; from 1.0 onward they require a major
bump.

## Tests

From the repository root, run:

```sh
prove -IAdServer/lib AdServer/t
```

Install the application dependencies and the test dependencies in
`AdServer/cpanfile`, plus MariaDB server tools (`mariadb-install-db` and `mariadbd`
on `PATH`). Run as an ordinary user with permission to start a local process and
bind a Unix socket. The current dependency manifests do not yet describe every
application dependency; see [CODEBASE.md](CODEBASE.md).

Database-backed tests automatically start a fresh MariaDB instance in a temporary
directory, with TCP networking disabled, and load `db/adserver.sql`. They ignore
the application's database environment variables and never load the database
dump. Each test process owns its server and stops it and removes its data on exit.
Missing server tools or startup errors fail the tests rather than silently skipping
integration coverage. No pre-existing database or credentials are required.

The suite exercises serving at client/campaign/ad scope, rendered click links,
impressions, redirects, missing records, empty selections, and live flags. Random
selection assertions check eligible membership, not statistical distribution.
Existing links to a live ad continue to redirect when its client or campaign is
disabled; disabling the ad itself blocks both serving and clicks.
