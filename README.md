# Harness Yard Package Registry

This repository is the official Git-backed catalog for public Harness Yard
Package Handles. It is the default catalog source for `hyard`, and the `hyard`
resolver must also support other Git remotes as registry sources.

It stores registry entries for installable Orbit Packages and Harness Packages.
It does not store Harness Yard CLI source code, resolver implementation, package
payloads, or arbitrary third-party tools.

Public registration is catalog-as-code: authors publish an Orbit Package or
Harness Package, generate a registry entry candidate with `hyard registry entry`,
and submit the candidate to this repository for review. This repository is not a
hosted registration service and does not provide accounts, OAuth, automatic
registration APIs, or automatic pull request creation.

## Layout

```text
namespaces/<namespace>.yaml
packages/<namespace>/index.yaml
curated/index.yaml
docs/adr/*.md
docs/source-contract.md
CONTEXT.md
```

- `namespaces/` records namespace ownership.
- `packages/` contains ordinary namespaced Package Handles such as `acme/docs`,
  grouped by namespace-level index files.
- `curated/` contains unnamespaced official or curated handles such as `docs`.
- `docs/adr/` records registry-specific catalog decisions.
- `docs/source-contract.md` records the operating contract for this repository.

The Harness Yard CLI source repository owns the registry schema, resolver code,
candidate-generation behavior, and package installation semantics. This
repository owns catalog entries, namespace ownership records, curated handles,
review policy, and registry CI validation.
