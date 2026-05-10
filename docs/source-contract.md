# Package Registry Source Contract

This document records the operating contract for the official Harness Yard
Package Registry repository.

## Source Model

- The default official catalog source is `zack-nova/hyard-registry`.
- `hyard` must support any Git remote as a registry source, not only GitHub.
- Public registration is catalog-as-code through reviewed pull requests.
- The first registration model does not include hosted accounts, OAuth,
  automatic registration APIs, or automatic pull request creation.

## Repository Boundary

This repository owns:

- catalog entries
- namespace ownership records
- curated bare handles
- catalog review policy
- registry CI validation for submitted entries

The Harness Yard product repository owns:

- Package Handle Coordinate parsing and normalization
- registry schema and resolver behavior
- registry-backed Package Installation semantics
- `hyard registry entry` candidate generation
- product documentation for installation and registration

## Catalog Layout

Registry catalog data is YAML and includes a schema version.

```text
namespaces/<namespace>.yaml
packages/<namespace>/index.yaml
curated/index.yaml
```

`namespaces/<namespace>.yaml` records namespace ownership. Owners are structured
Git-platform user or org identities.

`packages/<namespace>/index.yaml` records all packages under one namespace.
Each package entry records package-level status, dist-tags, version metadata,
source locator metadata, and validation evidence.

`curated/index.yaml` records curated bare handles such as `docs`. A curated
handle points at a namespaced Package Handle and does not copy full version
locator metadata.

## Coordinate Rules

Supported coordinate forms:

```text
namespace/name
namespace/name@<semver>
namespace/name@latest
name
name@<semver>
name@latest
```

Rules:

- Coordinates are case-insensitive and normalized before resolution.
- `namespace/name` is equivalent to `namespace/name@latest`.
- `name` is a curated bare handle and is equivalent to `name@latest`.
- `latest` is an explicit registry dist-tag.
- `latest` must not be inferred from a Git branch, newest registry merge, or
  highest SemVer version.
- Namespace and handle segments use lowercase letters, digits, hyphens, or
  underscores, and start and end with an alphanumeric character.
- npm-style `@namespace/name` syntax is not used because `@` is the version or
  dist-tag separator.

## Bare Handles

Bare handles are globally scarce names and are reserved for curated aliases.

- Ordinary authors register `namespace/name`.
- Curated handles are reviewed through the catalog curation process.
- Curated handles point at namespaced handles.
- Curated handles do not own independent version locator metadata.

## Status And Resolution

Registry status is package-level:

- `active`: install normally.
- `deprecated`: install with a warning.
- `yanked`: require explicit user override.
- `blocked`: never install.

Each resolved install uses a commit SHA. Branches and tags may appear as
provenance or discovery inputs, but installation uses the resolved commit.

Registry-backed installation must not guess GitHub locators or mutable branches.

## Cache Contract

Registry cache is a `hyard` runtime concern, not catalog data.

The product contract uses user-level global cache, npm/pip style:

```text
Linux:   ${XDG_CACHE_HOME:-~/.cache}/hyard
macOS:   ~/Library/Caches/hyard
Windows: %LocalAppData%/hyard/Cache
```

`HYARD_CACHE_DIR` overrides the cache root.

Cache semantics:

- Cache keys include the canonical registry remote.
- Exact-version resolutions may be cached.
- Bare and `latest` resolutions refresh from the registry when available.
- If the registry is unavailable and a previously verified cached resolution
  exists, installation may proceed with a warning.
- If there is no usable cached resolution, installation fails.
- A cached entry that is already known as `blocked` still cannot install.

## Registry Entry Candidates

`hyard registry entry orbit` and `hyard registry entry harness` output the same
YAML candidate schema. The package type and validation path vary by package
kind, but the entry shape does not.

Candidate behavior:

- Default output is stdout.
- `--out <path>` may write the candidate to a chosen file.
- `--registry <path>` may write the candidate into a local registry checkout at
  the intended target path.
- Local-only package results may produce preview output, but they cannot produce
  submittable registry entries.

A submittable candidate records:

- schema version
- intended target path
- package type
- package identity
- source Git remote
- source ref
- resolved commit SHA
- package status
- validation evidence

Validation evidence must cover:

- source remote reachability
- ref resolution
- commit reachability
- package identity match
- installability through the existing package install preview path

Registry CI must revalidate submitted candidates and must not trust local
validation evidence as authoritative.
