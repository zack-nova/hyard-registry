# Registry Submission And Review Policy

This document explains how package authors submit registry entry candidates and
how catalog maintainers review them.

## Author Flow

To register a public Package Handle:

1. First publish the package as an Orbit Package or Harness Package.
2. Ensure the package is reachable from a Git remote, ref, and commit.
3. Run `hyard registry entry orbit ...` or `hyard registry entry harness ...`
   from the Harness Yard product CLI to generate a YAML registry entry
   candidate.
4. Submit the generated candidate to this repository in the target namespace
   index or curated index.

Local-only package results are preview-only. They are useful for inspecting what
would be submitted, but they cannot be accepted as registry entries because the
catalog must be able to revalidate the source remote, ref, commit, package
identity, and installability.

## Namespace Ownership Evidence

Ordinary package authors register namespaced handles such as `acme/docs`.

Namespace ownership is recorded in `namespaces/<namespace>.yaml`. Owners are
structured Git-platform user or organization identities, such as GitHub users,
GitHub organizations, GitLab users, or GitLab groups.

Maintainers should verify that a submitted package belongs to a namespace owner
or that the namespace owner explicitly approves the submission.

## Curated Handles

A Curated Handle is a bare handle such as `docs`. Bare handles are globally
scarce and have a higher review bar than ordinary namespaced handles.

Curated handles:

- must point at an existing namespaced Package Handle
- must not copy version locator metadata from the namespaced package
- should be reserved for official, broadly useful, or intentionally curated
  package entry points
- should not be granted only because an author wants a shorter name

## Package Status

Registry status is package-level:

- `active`: install normally.
- `deprecated`: install with a warning.
- `yanked`: require explicit user override.
- `blocked`: never install.

Maintainers should prefer status changes over deletion so registry history stays
auditable and existing version metadata remains inspectable.

## Review Rules

Registry CI revalidates submitted candidates and does not trust local validation evidence as authoritative.

Before merge, maintainers should confirm:

- the YAML structure passes catalog validation
- namespace ownership evidence is sufficient
- curated handle requests meet the higher review bar
- source remote, ref, and commit are suitable for reproducible installation
- package identity in the source package matches the registry entry
- validation failures are fixed in the submission rather than bypassed
