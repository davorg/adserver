# Codebase overview

This document describes the source examined on 14 September 2026. AdServer is a
small Perl/Dancer2 application that selects and renders advertisements, records
impressions, and redirects tracked clicks to advertisers. Administration happens
through command-line scripts and the database; there is no admin web interface,
reporting endpoint, scheduler, or budget-management logic in the application.

## Code layout and runtime

| Path | Responsibility |
| --- | --- |
| `AdServer/lib/AdServer.pm` | All six HTTP GET routes; constructs a shared model and obtains its schema at module load time. |
| `AdServer/lib/AdServer/Model.pm` | Database lookups and live-client listing; optionally prefetches child records. |
| `AdServer/lib/AdServer/Schema.pm` | DBIx::Class schema discovery and MySQL connection configuration. |
| `AdServer/lib/AdServer/Schema/Result/` | Five table mappings and relationships; `Ad.pm` also implements hashing, display URLs, and impression recording. |
| `AdServer/lib/AdServer/Schema/ResultSet/` | Client, campaign, and ad result sets sharing `Role::LiveFlag`. |
| `AdServer/views/standard.tt` | Standalone HTML advertisement with inline CSS. |
| `AdServer/bin/app.psgi` | Plack entry point with static-file middleware. |
| `bin/`, `load_data` | Database administration and content-loading utilities. |
| `db/` | Destructive schema creation, a database snapshot, and a live-flag migration with its reverse. |

The application uses Dancer2 for routing, Template Toolkit for HTML, DBIx::Class
for persistence, Moo for the model, and Moose for the schema classes and role.
Generated schema sections are marked explicitly; custom methods belong below the
Schema::Loader boundary. `adserver.conf.sample` supplies loader configuration,
not runtime application configuration.

## Requests and tracking

| GET route | Behavior |
| --- | --- |
| `/` | Returns JSON text containing application name, SemVer version (from `$AdServer::VERSION`), and hostname. |
| `/client` | Returns JSON text containing all columns of all live clients. |
| `/client/:client_code` | Selects a random live ad across the client's live campaigns. |
| `/client/:client_code/campaign/:campaign_code` | Selects a random live ad in the specified live campaign. |
| `/client/:client_code/campaign/:campaign_code/ad/:ad_code` | Serves a particular live ad under its live campaign and client. |
| `/ad/:hash` | Finds a live ad, inserts a click, then redirects to its stored destination URL. |

Missing clients, campaigns, ads, and empty eligible-ad sets return 404 errors.
Selection materializes the eligible ads in Perl and uses `rand`; there are no
weights, targeting rules, frequency caps, or date windows. Client-wide selection
weights each eligible ad equally, so a campaign with more ads gets more exposure.

Serving calls `Ad::serve(request)`, which inserts an impression before returning
the template name, variables, and `layout => undef` to the route. Impressions store
the ad ID, request IP address, user agent, and HTTP Referer, with fallback strings
when request values are missing. The database supplies the timestamp. This counts
server-side serving attempts, not confirmed browser visibility; a later rendering
failure does not undo the insert. Tracking writes are synchronous and there is no
application-level fallback if they fail.

The template renders the heading, body, optional image, and a shortened display
URL. Images are expected at `/images/client/<client-code>/<image>`. The text link
opens the click route in a new tab. Both links share a tracking URL containing the
impression token, with the complete URL HTML-escaped for the link attribute.
`Ad::serve` generates the token using 16 bytes from Crypt::URandom, encoded as
32 lowercase hexadecimal characters.
The click route resolves a token within the clicked ad's impressions, copies the
recorded referer, and stores `impression_id`. Without a token it uses the legacy
`referer` parameter. Invalid or wrong-ad tokens record an unlinked click with no
referer and still redirect. It does not capture the click request's IP or user agent.
Neither route populates the tables' `medium` column.

`display_url` removes an initial HTTP/HTTPS scheme, a trailing fragment matching
`#[-\w]+`, and a final slash. It changes the label only, not the redirect target.

## Database model

```text
client 1 ──< campaign 1 ──< ad 1 ──< impression
                             1 ──< click
```

All tables use auto-increment integer primary keys. Client codes and names are
individually unique; campaign codes are unique within a client, and ad codes
within a campaign. Ads also have a globally unique 32-character hash. Foreign-key
columns are nullable in SQL, although normal application paths assume the
client/campaign/ad hierarchy exists. Relationships do not enable cascading deletes.

Impressions have nullable, uniquely indexed tokens; clicks have a nullable foreign
key to an impression. Nulls preserve compatibility with historical rows and old
writers. `db/patch_5.sql` adds these fields to existing databases; apply it before
0.2.0. See README for deployment and rollback details.

Client, campaign, and ad each have `is_live`, defaulting to true. The shared
`search_live` and `find_live` helpers add `is_live = 1` to their search conditions;
they do not recursively enforce parent status. Serving routes explicitly traverse
live parents. The hash-based click route checks only the ad's flag, so an existing
link can still redirect when its campaign or client has been disabled.

On ad insertion, an absent hash is generated as
`md5_hex(client_code . ':' . campaign_code . ':' . ad_code)`. It is a deterministic
identifier, not an access token. Supplying a hash bypasses generation. Editing a
code does not automatically regenerate the hash; `bin/ad_hash` recalculates and
updates every ad's hash, potentially changing existing click links. The insert
hook currently also emits a Data::Printer diagnostic through `warn`.

`db/adserver.sql` drops and recreates all five tables. It already includes live
flags: `db/patch_4.sql` is for an older schema and must not be applied again to a
fresh schema. `db/unpatch_4.sql` removes those columns and would make the schema
incompatible with the current live-filtering code. `db/adserver_dump.sql` is a
schema-and-data snapshot containing content and historical tracking records, not
an isolated test fixture.

## Configuration and execution

`Schema::get_schema` requires these environment variables to be defined:

- `ADSERVER_DB_HOST`
- `ADSERVER_DB_NAME`
- `ADSERVER_DB_USER`
- `ADSERVER_DB_PASS`

`ADSERVER_DB_PORT` is optional. DBIx::Class connects using `dbi:mysql`, enables
`mysql_enable_utf8`, and quotes identifiers with backticks. It also assigns the
schema to DBIx::Class's `thaw_schema` global, but no application cache is implemented.
The shell utilities require nonempty values, whereas the Perl check accepts empty
defined values. `.env.sample` is a shell export template; there is no explicit
`.env` loader in the application. Its `ADSERVER_APP_*` and log-directory variables
are not consumed by the examined application code (`ADSERVER_APP_POST` is spelled
that way in the sample).

With dependencies installed and database variables exported, the intended Plack
entry point can be started from the repository root:

```sh
plackup AdServer/bin/app.psgi
```

The explicit static middleware serves `/images`, `/css`, and `/javascripts` from
`./AdServer/public`, making that path dependent on the working directory. CGI and
FastCGI dispatchers are also present and set the production environment; the
FastCGI wrapper requests five detached processes.

`AdServer/config.yml` selects UTF-8, Template Toolkit with `<% ... %>` delimiters,
and a default `main` layout. Ad responses explicitly bypass that layout. Development
logs to the console with stack traces; production logs to a file and hides stack
traces and server tokens. The default content type is `text/html`: the two JSON
routes encode their bodies manually without explicitly setting a JSON content type.

The dependency manifests are incomplete. Beyond their Dancer2 and testing entries,
the source needs modules including DBIx::Class, its DateTime inflation support,
DBD::mysql, Moose, MooseX::NonMoose, MooseX::MarkAsMethods, Moo, Types::Standard,
Template Toolkit, Data::Printer, and Digest::MD5. The loader uses Path::Tiny and
JSON; tests additionally use Plack::Test and Ref::Util. Installing only the declared
dependencies is therefore not a reliable clean-environment setup procedure.

## Content and database utilities

Run the Perl utilities with `AdServer/lib` on the include path, for example
`perl -IAdServer/lib bin/add_client 'Example Client' example`.

| Utility | Behavior |
| --- | --- |
| `bin/add_client <name> [<code>]` | Creates a client; derives a missing code by lowercasing the name and replacing runs of non-word characters with hyphens. |
| `bin/add_campaign <client_code> <name> [<code>]` | Creates a campaign; despite its usage text, it ignores the optional code argument and always derives the code from the name. |
| `bin/add_ad <client_code> <campaign_code> <code> <name> <url> <header> <text>` | Creates an ad beneath an existing campaign; the insert hook generates its hash. No image argument is supported. |
| `bin/ad_hash` | Rewrites all ad hashes using their current hierarchy codes. |
| `load_data` | Reads `data.json` from the working directory and creates clients with nested campaigns and ads through ORM relationships. Repeated loading can fail on uniqueness constraints; it is not an upsert. |
| `bin/db [SQL]` | Opens the MySQL client, or executes the supplied SQL arguments. |
| `bin/dump_db` | Overwrites `db/adserver_dump.sql` using `mysqldump --skip-extended-insert`. |
| `bin/load_db` | Loads that dump into the configured database. |

The dump/load helpers assume the repository root as working directory. Client
images are excluded by `.gitignore` and must be provisioned separately. The Dancer
welcome page, layout, bundled jQuery, and stock assets are mostly scaffold material;
the root route no longer renders `index.tt`.

## Observed limitations and verification

The template inserts ad content fields without explicit HTML escaping, so markup
in those fields can affect the generated HTML. Tracking URLs now carry an opaque impression token and HTML-escape the link
attribute. The
template also has a `</bpdy>` closing-tag typo. These are observations of the
current source, not fixes made during this examination.

There is no application authentication, click deduplication, bot filtering,
retention job, or reporting layer. The public client listing includes database
IDs and live flags because it serializes all client columns.

Validation performed on 14 September 2026:

```sh
prove -IAdServer/lib AdServer/t
```

The suite now also uses temporary MariaDB servers, loaded from `db/adserver.sql`,
to exercise actual ORM queries and HTTP requests through Plack. It covers selection
at all three scopes, impression metadata, both rendered click links, exact redirect
targets, click attribution, missing records, empty selections, and live flags.
Application database environment variables are ignored by the test connection
helper. See the README for prerequisites and isolation details.

Integration testing found that DBIx::Class `find` could discard the non-key
`is_live` condition during unique-key lookup. `find_live` now scopes the result set
by its qualified live flag before calling `find`. Disabled ads no longer serve or
redirect; disabled clients and campaigns block serving. Hash links to live ads
still redirect regardless of parent status, preserving that existing policy.

Administrative scripts, deployment, and browser-level behavior remain outside the
test coverage. Tests mutate only their disposable databases; no production database
or live deployment was exercised.

The working tree already contained untracked `AdServer/public/test.html`,
`AdServer/views/404.tt`, `data-munging.webp`, and `image.tar`. The HTML files were
inspected as local context (the former is an iframe experiment); the binary assets
were not unpacked or executed. None was changed or treated as a committed runtime
requirement.
