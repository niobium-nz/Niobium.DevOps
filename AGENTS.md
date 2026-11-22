# Working in Niobium.DevOps

Read [model names and contract ownership](docs/model-contracts.md) before adding or
changing a Table model, key, fingerprint, serialized shape or file reference.
Use business property names with EntityKey attributes. Models privately own their
representation; domains own business rules and transitions, flows coordinate,
and framework adapters map/persist. Keep existing key/wire values compatible and
follow the documented separate rollout for legacy public contract renames.

Use feature branches and the owner-authorized delivery process. Inspect existing
workflow triggers before submission, verify available checks, native review and
a separate genuine approval, and monitor any resulting publication/deployment.
Do not push main, fabricate status, self-approve, or mutate production data.

## Azure resource naming

Use `rg-niobium-<service-slug>-<env>` for resource groups and
`<prefix>-<abbr>-<env>` for named service resources such as Functions and
vaults. Functions deployment packages use `<prefix>sts<env>` and application
data uses `<prefix>std<env>`. Read the service's Bicep to see which account
supplies the `AzureWebJobsStorage` runtime endpoints. Use the service's approved slug and
compact prefix in new service-owned Bicep modules and deployment examples.
The existing Azure Pipelines Function App job takes a single `appName` and
derives suffix-based names. Passing a hyphenated site name to that job yields
an invalid storage account name. [Azure resource naming and legacy job behavior](docs/azure-resource-naming.md)
