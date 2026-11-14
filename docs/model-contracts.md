# Model conventions in shared tooling

The owner's rule of 14 November 2026 applies to examples and generated code in
every Niobium repository. The [framework guide](https://github.com/niobium-nz/Niobium/blob/main/docs/model-contracts.md)
is the detailed source for business names, `EntityKeyAttribute`, model-owned data
formats and rich-domain responsibilities.

Niobium.DevOps currently contains a reusable .NET workflow rather than Table
models. It has no existing model to rename. Any future template, generator or
sample must use business property names with `EntityKeyKind.PartitionKey` and
`RowKey` annotations; physical storage names belong to the framework adapter.

Keep ID derivation, hashing, composite encodings, serialized shape and blob-path
definitions private to the owning data contract behind a small meaningful API.
Domains own business rules and transitions; flows coordinate; adapters perform
backend mapping and I/O. Do not generate domains that duplicate model formats.

Compatibility checks should verify existing rows/wire values and the installed
adapter, including private-setter materialization and the fact that public
computed properties become columns. Existing generic public contracts in the
services/framework are inventoried in the shared guide for a separate rollout.
This documentation does not change reusable workflow inputs or behavior.
