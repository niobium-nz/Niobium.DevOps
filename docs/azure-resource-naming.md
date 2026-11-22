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
| Functions host/package storage account | `<prefix>sts<env>` | `niobiuminvoicingststest` | `niobiumagentsstsprod` |
| Application data storage account | `<prefix>std<env>` | `niobiuminvoicingstdtest` | `niobiumagentsstdprod` |

For named service resources, Bicep composes the prefix, resource abbreviation
and environment. A Service Bus namespace, when the service uses one, follows
`<prefix>-sb-<env>`. Storage account names concatenate the lowercase prefix,
`st`, the purpose letter (`s` for host/package or `d` for data), and the
environment. Check the complete name against Azure's length and uniqueness
constraints. [Invoicing host module](https://github.com/niobium-nz/Niobium.Invoicing/blob/0b4ffa7a7c6d255e7d3f0db7553cc87a807959a9/infra/function-app.bicep) · [Application resources](https://github.com/niobium-nz/Niobium.Invoicing/blob/0b4ffa7a7c6d255e7d3f0db7553cc87a807959a9/infra/main.bicep)

Record each new service's approved slug, prefix and environments in its
deployment guidance. Region, hostname and which resources to provision are
service decisions. Driver uses West US 2, Azure's default Functions hostname,
and a separate data account with zero application tables. For existing
installations, use their resource names when binding or updating resources.
Renaming a deployed resource is a separate migration. [Driver deployment configuration](https://github.com/niobium-nz/Niobium.AI.Agent.Driver/blob/7f266bb1fe3ac1ee322ce437fd12d94de2a3496a/README.md#azure-naming-and-resources)
