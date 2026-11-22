# Azure resource naming

Use three inputs when naming a Niobium service deployment. The **service slug**
appears in the resource group. The **compact prefix** is the approved Azure
short name for that service. The **environment** is the deployment suffix,
such as `test` or `prod`. Read the deployed service's workflow and Bicep
parameters when extending it. Repository names alone cannot establish these
values. For example, Notification uses the prefix `niobiumnotify`.

| Resource | Name pattern | Invoicing test | Driver production target |
| --- | --- | --- | --- |
| Resource group | `rg-niobium-<service-slug>-<env>` | `rg-niobium-invoicing-test` | `rg-niobium-agents-prod` |
| Function App | `<prefix>-func-<env>` | `niobiuminvoicing-func-test` | `niobiumagents-func-prod` |
| App Service plan | `<prefix>-plan-<env>` | `niobiuminvoicing-plan-test` | `niobiumagents-plan-prod` |
| User-assigned managed identity | `<prefix>-id-<env>` | `niobiuminvoicing-id-test` | `niobiumagents-id-prod` |
| Application Insights | `<prefix>-appi-<env>` | `niobiuminvoicing-appi-test` | `niobiumagents-appi-prod` |
| Log Analytics workspace | `<prefix>-log-<env>` | `niobiuminvoicing-log-test` | `niobiumagents-log-prod` |
| Key Vault | `<prefix>-kv-<env>` | `niobiuminvoicing-kv-test` | `niobiumagents-kv-prod` |
| Functions deployment package storage account | `<prefix>sts<env>` | `niobiuminvoicingststest` | `niobiumagentsstsprod` |
| Application data storage account | `<prefix>std<env>` | `niobiuminvoicingstdtest` | `niobiumagentsstdprod` |

In the service-owned Invoicing and Driver modules, Bicep composes the prefix,
resource abbreviation and environment. A Service Bus namespace, when the service uses one, follows
`<prefix>-sb-<env>`. Storage account names concatenate the lowercase prefix,
`st`, the purpose letter (`s` for deployment packages or `d` for application data), and the
environment. Check the complete name against Azure's length and uniqueness
constraints. [Invoicing host module](https://github.com/niobium-nz/Niobium.Invoicing/blob/0b4ffa7a7c6d255e7d3f0db7553cc87a807959a9/infra/function-app.bicep) · [Application resources](https://github.com/niobium-nz/Niobium.Invoicing/blob/0b4ffa7a7c6d255e7d3f0db7553cc87a807959a9/infra/main.bicep)

`functionAppConfig.deployment.storage` points to the package container in `sts`.
The service configures `AzureWebJobsStorage` separately. Invoicing, Identity,
Notification and Store use `std` for its Blob and Table endpoints. Driver uses
`sts` for its Blob, Queue and Table endpoints so its `std` account can start
empty. [Invoicing runtime endpoints](https://github.com/niobium-nz/Niobium.Invoicing/blob/0b4ffa7a7c6d255e7d3f0db7553cc87a807959a9/infra/main.bicep#L102-L110) · [Driver runtime endpoints](https://github.com/niobium-nz/Niobium.AI.Agent.Driver/blob/7f266bb1fe3ac1ee322ce437fd12d94de2a3496a/infra/function-app.bicep#L57-L61)

Record each new service's approved slug, prefix and environments in its
deployment guidance. Region, hostname and which resources to provision are
service decisions. Driver uses West US 2, Azure's default Functions hostname,
and a separate data account with zero application tables. For existing
installations, use their resource names when binding or updating resources.
Renaming a deployed resource is a separate migration. [Driver deployment configuration](https://github.com/niobium-nz/Niobium.AI.Agent.Driver/blob/7f266bb1fe3ac1ee322ce437fd12d94de2a3496a/README.md#azure-naming-and-resources)

## Existing Azure Pipelines Function App job

The `FunctionAppInfrastructure.yml` job takes a resource group and a single
`appName`. Its `FunctionApp.bicep` uses that name for the site, strips a
trailing `Func` when deriving the prefix, and appends `Plan`, `Insights`,
`Logs`, `Store` and `Vault` to derive other names. It lowercases the storage
account name. For example, `ordersFunc` yields `ordersstore`. Passing
`niobiuminvoicing-func-test` yields `niobiuminvoicing-func-teststore`,
which contains hyphens and exceeds Azure's 24-character storage account limit.

Keep the existing job's deployed `appName` when updating its callers. Use
the service-owned Bicep naming inputs for new deployments that follow the
table above. Adopting those inputs in the legacy job requires a separate
template and caller migration. [Pipeline job](../pipelines/jobs/FunctionAppInfrastructure.yml) · [Legacy Function App template](../bicep/FunctionApp.bicep)
