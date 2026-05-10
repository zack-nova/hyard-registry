# Harness Yard Package Registry

This context records the operating language and decisions for the official
Harness Yard Package Registry catalog.

## Language

**Package Registry**:
The official catalog that maps Package Handle Coordinates to installable Orbit Package or Harness Package locators.
_Avoid_: package manager, source repository, package payload store

**Registry Entry**:
One catalog record for a Package Handle, including dist-tags, versions, package-level status, locator data, and validation evidence.
_Avoid_: package manifest, install record, source manifest

**Package Namespace**:
A registry ownership prefix recorded as a Git-platform user or organization identity.
_Avoid_: package type, Git remote URL, folder name

**Package Handle**:
A registry-facing name that users pass to Harness Yard package lifecycle commands.
_Avoid_: Package Identity, branch name, display title

**Package Handle Coordinate**:
A registry-facing install selector made from a Package Handle and optional version or dist-tag, such as `acme/docs@0.1.0`.
_Avoid_: Package Identity, Git locator, npm scoped package

**Curated Handle**:
A bare Package Handle reviewed by the official catalog and mapped to a namespaced Package Handle.
_Avoid_: ordinary public handle, global name claim, duplicated locator metadata

**Version Entry**:
An immutable Registry Entry section for one package version and its commit-pinned locator.
_Avoid_: mutable release pointer, branch head

**Dist Tag**:
A mutable named pointer from a Package Handle to a Version Entry, such as `latest`.
_Avoid_: highest SemVer, default branch, newest commit

**Package Status**:
A package-level registry gate such as active, deprecated, yanked, or blocked.
_Avoid_: per-version status, deletion, branch protection

**Registry Entry Candidate**:
A generated Registry Entry proposal created from package publication evidence before review.
_Avoid_: handwritten package metadata, automatic registration

## Relationships

- The official **Package Registry** registers **Orbit Packages** and **Harness Packages** only.
- The official **Package Registry** does not register arbitrary tools, services, agent frameworks, plugins, or non-Harness Yard package shapes.
- Ordinary public **Package Handles** use a **Package Namespace**, for example `acme/docs`.
- **Curated Handles** are unnamespaced, reserved for official or curated packages, and point at namespaced **Package Handles**.
- The catalog stores namespace-level package indexes, not one file per **Package Handle**.
- **Version Entries** are immutable after publication; fixes require a new version and an explicit **Dist Tag** update.
- A bare **Package Handle** resolves through a **Curated Handle**, then through the explicit `latest` **Dist Tag** before selecting a **Version Entry**.
- Registry history is retained for auditability; **Package Status** controls future installation instead of ordinary deletion.
- Submittable **Registry Entry Candidates** require remote repository, ref, commit reachability, package identity, and installability validation.
- Local-only publication results may produce preview output, but not a submittable **Registry Entry Candidate**.

## Boundaries

- This repository owns catalog data, review policy, and registry-specific decisions.
- The Harness Yard CLI source repository owns registry schema, resolver implementation, package installation behavior, and product documentation.
- Package source repositories own package payloads and authored package truth.
- Registry cache is a `hyard` runtime concern, not catalog data; the product contract uses a user-level global cache with `HYARD_CACHE_DIR` override.

## Example Dialogue

> **Dev:** "Can I register `docs` for my package?"
> **Registry maintainer:** "Use a namespaced **Package Handle** such as `acme/docs`; unnamespaced **Curated Handles** are reserved."

> **Dev:** "Can I fix `acme/docs@0.1.0` by changing its commit?"
> **Registry maintainer:** "No. Publish `0.1.1`, then update the `latest` **Dist Tag**."

## Flagged Ambiguities

- "tool" could mean arbitrary CLIs, plugins, services, or agent frameworks. Resolution: registry entries are only **Orbit Package** or **Harness Package** entries.
- "latest" could mean highest SemVer, newest merged registry version, or source default branch. Resolution: `latest` is an explicit **Dist Tag** pointer.
- Removing broken packages could make old installs unreproducible. Resolution: retained entries use package-level deprecated, yanked, or blocked status.
- A single registry index file could make ordinary registration PRs conflict frequently, while per-package files would scatter namespace review. Resolution: use one package index per namespace, with curated unnamespaced handles stored in a curated index.
- Namespace claims could require Harness Yard accounts or a separate ownership database. Resolution: first-version ownership records use Git-platform user or organization identities plus PR/manual review evidence.

## Open Questions

- None recorded.
