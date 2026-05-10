---
status: accepted
---

# 0001 Official Catalog Bootstrap

The first public Harness Yard Package Registry is an official Git-backed catalog
in this separate repository. It registers only Orbit Packages and Harness
Packages, accepts generated Registry Entry Candidates through PR or manual
review, and stores YAML namespace-level indexes under `packages/<namespace>/`,
namespace ownership records under `namespaces/`, and curated bare-handle aliases
under `curated/`.

We chose this over hosting catalog data in the Harness Yard CLI source
repository, accepting arbitrary tool registration, default self-hosted registry
discovery, mutable branch-backed handles, and hosted account flows because the
early registry needs reproducibility, reviewability, and low infrastructure
cost. Ordinary public handles are namespaced by Git-platform user or
organization identities; unnamespaced handles are reserved for official or
curated packages and point at namespaced handles.

## Consequences

Version Entries are immutable and commit-pinned. Fixes require a new version plus
an explicit Dist Tag update, and `latest` is a Dist Tag rather than highest
SemVer or newest commit. Package status is package-level: deprecated packages
warn, yanked packages require explicit override, and blocked packages cannot be
installed. First-version entries carry install locator fields and minimal
validation evidence, not ratings, download counts, signatures, SBOMs, or broad
safety labels.
