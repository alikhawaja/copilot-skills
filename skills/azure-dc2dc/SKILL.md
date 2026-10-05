---
name: azure-dc2dc
description: Plan and document an Azure data-center-to-data-center or cross-region migration by discovered workload, starting with an estate overview and shared landing zone. Use for inventory, workload architecture and dependencies, source SKU and quantity workbooks, readiness, or publication.
---

# Azure DC-to-DC migration

Use this skill to run workload-led migration planning from authenticated discovery through approved design decisions and requested deliverables. Begin with the estate overview, then the shared landing zone (Workload 0), then one document and allocation workbook per business or hybrid workload, plus an estate-wide monthly actual-cost services workbook for every customer. Generate PDFs and presentations only when requested or agreed for publication.

## Operating rules

- Ask for the **account** and **tenant** before discovery. Do not assume the signed-in Azure account or tenant.
- If an isolated Azure session directory is provided, inspect the account and tenant there; do not overwrite its profile.
- Verify the Azure CLI session with `az account show`, confirm the tenant, and list the subscriptions visible to the signed-in account.
- Ask the user to select the subscriptions in scope, with an explicit option to select all subscriptions visible in the confirmed tenant. Never treat all visible subscriptions as in scope unless the user selects that option.
- If a selected subscription is not visible, stop and report the authentication or access issue. Do not switch accounts silently.
- Run discovery in an isolated working directory. Do not overwrite Azure CLI session files, existing exports, or another migration engagement.
- Ask for the requested publication folder before creating deliverables.
- Treat discovery as read-only. Do not modify Azure resources.
- Do not present unconfirmed material design decisions as final. A user-requested Markdown review draft may be created with open decisions clearly labelled; final publication follows approval.
- Use explicit errors and stop on failed discovery, unresolved customer-owned inventory gaps, or unresolved design decisions.
- Treat the destination as a planned Azure region that is not yet live. Do not attempt to qualify current target-region service, SKU, quota, or capacity availability. Use the requested destination label, identify future availability validation as a mandatory pre-execution dependency, and do not describe the package as deployment-ready.
- Preserve literal Azure resource names, resource-group names, application names, and subscription identifiers exactly as discovered. Remove only accidental project branding from document prose when requested.
- Base the target architecture on discovered current state. Always evaluate the existing landing zone against its actual connectivity, routing, inspection, DNS, resilience, security and operational requirements; recommend specific improvements when evidence shows a need. Retain a sound design and consider redesign only when justified and approved. Do not recommend a firewall vendor, hub technology, gateway, NAT pattern, or topology before inventorying what is deployed and determining whether it is operationally sound.
- Organize by workloads and their dependencies, not migration waves. Never prescribe durations, effort in days, calendar dates, or a project timeline. Scheduling follows confirmed workload readiness, capacity, change authority, and conditions on the ground. Discovery/evidence dates remain mandatory provenance, not schedule estimates.
- Lead all executive and customer-facing materials with discovered workloads, business services, external applications, and their dependencies. Keep resource counts, SKU quantities, and reconciliation in a separate technical inventory appendix and workbooks; do not put resource totals, subscription totals, or allocation quantities in the opening narrative or strategy presentation.
- Inventory third-party services, SaaS, marketplace purchases, partner-managed subscriptions, external cloud workloads, and external control planes explicitly. Verify marketplace purchases against billing/marketplace records before calling a discovered integration a purchase; record unknown commercial ownership as unverified.
- Write customer-facing deliverables in affirmative, plain language: describe the discovered estate, workload dependencies, proposed approach, and required approvals. Give every customer-facing Markdown document a short **Inventory basis** section near the end: state the actual inventory extraction date, that the document is presented for customer review and approval, and that owners will confirm current usage and dependencies and validate destination service availability, SKUs, quotas and capacity where applicable before implementation. Tailor the owner and scope to the document; do not list raw export filenames or prior-version paths there. Put a short planning-and-approval note at the top of a README only when one is produced; do not repeat it at the top of every document. Avoid internal version paths, generator jargon, defensive "what this is not" comparisons, and repeated negative disclaimers. State uncertainties neutrally and specifically.
- Map dependencies inside the consuming workload document: show named ingress paths, application-to-service relationships, cross-workload connections, and their owners. Distinguish configured private endpoint, observed traffic, verified application call, and proposed target path in diagrams and prose. Keep all discovered private endpoint names, consumer and target subscriptions/IDs, region, subresource, and connection states in technical evidence; a private endpoint establishes configured connectivity, not the application caller. Confirm actual caller, data flow, DNS, identity, and change owner. Production endpoints targeting services hosted in Non-Prod/Test subscriptions belong to their real consumers and target owners, not automatically to a "non-production workload."
- Identify critical cleanups in the affected workload: disconnected/rejected connections, divergent ingress/failover routes, unhealthy external origins, and data-residency or lifecycle concerns. Refresh exported states and confirm usage and impact with owners before remediation, controlled retirement, or exception. Define the affected workload's readiness gate. An exported state is an investigation lead, not proof of a live outage.
- Treat backup-health remediation as advisory in every workload: report coverage and health evidence, recommend owner-led investigation, restore testing and remediation or documented exceptions, but never make remediation a mandatory migration-readiness gate.
- Keep website-specific Imperva, Front Door, application telemetry and other integrations in the website workload when that is their confirmed consumer. Azure Arc/GCP belongs in the hybrid workload, and SaaS/Marketplace partners belong with confirmed consumers. Do not put them in the shared landing zone simply because they traverse shared networking.
- Keep the estate-wide historical-cost services workbook distinct from per-workload destination allocation workbooks. Cost attribution is an evidence-based reporting grouping, not proof of application calls, migration scope or target-region spend.

## Required interaction sequence

### 1. Establish context and access

Ask, one at a time:

1. Which Microsoft account should be used?
2. Which Azure tenant should be inventoried?
3. Which subscriptions should be inventoried? Present the visible subscriptions and allow either an explicit selection or **all visible subscriptions in the confirmed tenant**.
4. What is the destination Azure region/data-center label?
5. Where should the final package be published?

For the required monthly services workbook, also confirm the actual-cost reporting month (default to the last **completed** calendar month), source billing currencies and any reporting-currency conversion the customer wants. Do not assume Saudia's September 2026 period or 3.75 SAR/USD conversion for another customer.

Verify:

- The signed-in account and tenant.
- The selected subscriptions in scope, including explicit confirmation when all visible subscriptions are selected.
- That the working directory is isolated from Azure CLI session state and previous engagements.

Record the source tenant, selected subscriptions, whether all visible subscriptions were selected, destination label, discovery date, and publication path in the working engagement metadata.

### 2. Pull and validate inventory

Collect read-only inventory using Azure Resource Graph and service-specific queries as needed:

- Resources, resource groups, subscriptions, regions, resource types, SKUs, quantities, tags, and IDs.
- VNets, subnets, peerings, route tables, firewalls, gateways, Bastion, DNS, NAT, and private endpoints.
- Compute, storage, databases, App Services, Functions, API Management, Databricks, Synapse, Data Factory, Log Analytics, Automation, Backup, AVD/WVD, Fabric, and Azure Arc.
- Existing cross-subscription and cross-region dependencies.
- Exact source SKUs and service requirements to use as the baseline for future destination-region validation.
- Inspect live service-specific ARM properties where top-level Resource Graph `sku` is absent. For example, Virtual WAN type may be in `properties.type`, a Virtual WAN VPN gateway uses scale units, and a DDoS plan's VNet association identifies Network Protection. Distinguish a missing API SKU property from an unknown service tier; never invent a conventional SKU.
- For the monthly services workbook, collect read-only Cost Management **ActualCost** for the confirmed period across the selected subscriptions, preserving the source currency, resource ID, service name, retrieval time and subscription. Follow pagination and retry throttled requests; reconcile the retrieved total before assigning costs. Billing access is separate from resource Reader access: if actual costs cannot be retrieved, report the access gap rather than substituting retail prices, estimates or zeroes.
- Existing hub-and-spoke or Virtual WAN topology, including the actual security and egress path, route propagation, DNS flow, hybrid links, and managed-service networks.
- Public-network-access posture for data, application, registry, and secrets services.
- Backup coverage and health, not only the existence of vault resources.
- Resiliency signals such as storage replication, database zone redundancy, DDoS-plan association, and availability-zone use.
- Managed-service dependencies whose resource IDs reside in Microsoft-managed subscriptions, including Virtual WAN, API Management, AKS, Data Factory managed VNets, Fabric managed private endpoints, and similar platform infrastructure.
- Per-private-endpoint target resource ID, target subscription, subresource/group ID, endpoint subnet, connection state and region. Separate customer-managed workload endpoints from provider-managed control-plane endpoints; correlate target owner and subscription across environments.
- Current public ingress paths, their actual routing/origin policies, third-party WAF and change authority, plus representative traffic and failover evidence where accessible. Trace vendor and SaaS integrations to workload owners without inferring commercial purchases from technical configuration.

Preserve raw exports separately from cleaned analysis data. Validate counts, subscription coverage, resource-group coverage, and duplicate or ambiguous resources before analysis.

For references to subscription IDs outside the visible scope:

- Inspect the referenced resource IDs and resource-group patterns before calling them missing customer subscriptions.
- Classify Microsoft-managed backing subscriptions as platform dependencies rather than migration targets.
- Treat customer-owned inaccessible subscriptions as inventory gaps. Either obtain access or explicitly exclude their resources while retaining dependency actions and owner confirmation as a migration gate.

### 3. Present findings before planning

Present a concise findings review before creating any migration plan:

- Discovered workload and business-service grouping, including third-party applications.
- Directional workload, cross-subscription, cross-region, and external dependencies, with ownership and cutover impact.
- Subscription/region inventory and Dev/Test/Prod/shared counts in supporting analysis, not the executive opening.
- Orphaned, isolated, untagged, duplicate, or ambiguous resources.
- Azure Arc and other hybrid assets that are not native Azure resources.
- Destination-region service, SKU, quota, and capacity validation dependencies that must be resolved when the region becomes available for qualification.
- Resource types outside the selected Microsoft delivery program.
- Important SKU, security, identity, networking, backup, resiliency, and operational observations.
- Critical source cleanups: disconnected/rejected private links, misleading or ineffective failover routes, unhealthy SaaS origins, production use of shared services hosted in a Test/Non-Prod subscription, and unresolved vendor telemetry or commercial ownership. Distinguish confirmed impact from configuration evidence and nominate an owner for live verification.
- An evaluation of the existing landing-zone topology against observed routing, connectivity, inspection, DNS, resilience, security and operations; recommend targeted improvements where needed, retain a sound model, and explain any evidence supporting a redesign.

Then provide **design review recommendations**. Do not silently turn recommendations into decisions.

### 4. Confirm decisions and resolve ambiguity

For every material recommendation, ask for confirmation or clarification. Keep a decision log with:

- Decision.
- Rationale.
- Affected workloads, environments, and shared resources.
- Owner or approver.
- Open dependency.
- Whether the decision is confirmed, pending, or rejected.

Do not publish affected designs as approved while material decisions remain pending; review drafts should name the decisions and owners.

## Discovery-led decision pattern

Use these as configurable starting points. Apply only when supported by discovery and revalidate every material choice with the user:

### Architecture preservation and enhancement

- Always assess the current landing-zone architecture first. Test the actual hub-and-spoke or Virtual WAN operating model against requirements and document evidence-based recommendations for any gaps. If it is sound, recommend reproducing it in the destination; propose replacement technology or redesign only when the evaluation demonstrates a need and the customer approves.
- Preserve the existing firewall platform when it meets the target security, scale, support, and availability requirements. Do not introduce Palo Alto, Azure Firewall, another NVA, or an Azure Load Balancer merely because it appeared in a previous engagement.
- When the current estate uses Azure Virtual WAN with Azure Firewall Premium, VPN/P2S gateways, DNS Private Resolver, and spoke connections, evaluate the pattern before recommending its IaC-based recreation. If it meets the requirements, migrate route intent, firewall policy, IP groups, diagnostics, threat-intelligence settings, hybrid links, and zone design.
- When the current estate uses a supported Palo Alto or other NVA standard, preserve it unless discovery identifies a material security, availability, licensing, throughput, or support gap. Recommend the appropriate HA/load-balancing pattern only after validating the deployed model and vendor guidance.
- Preserve the current S2S termination model unless the user approves a change. Establish destination connectivity in parallel, validate BGP and effective routes, test asymmetric-routing controls, and retain rollback.
- Do not add NAT Gateway by default. If the current design routes egress through the firewall, recommend retaining centralized inspection and validating firewall/SNAT scale. Recommend NAT Gateway only for a demonstrated egress requirement or approved architecture change.
- Preserve centralized private DNS when the estate relies on DNS Private Resolver, private DNS zones, VNet links, and private endpoints. Treat DNS as an early shared-platform dependency and migrate private endpoints with their owning workloads.
- If Bastion is absent, present one centralized Bastion deployment as a security enhancement, not as an assumed current component. Confirm tier, subnet sizing, RBAC, logging, and session-control requirements.
- If a DDoS plan exists but eligible VNets do not show protection enabled, recommend validating the association and attaching protection to approved public-facing target VNets. Do not assume an existing plan is effective merely because the resource exists.
- Preserve non-overlapping address-space discipline. Validate destination ranges against every cloud, on-premises, partner, and managed-service network used during coexistence.

### Scope, subscriptions, and dependencies

- Preserve active workload-subscription and environment boundaries by default. Recommend consolidation only when ownership, policy, cost, and operational evidence justify it.
- Identify empty subscriptions and sandbox/experimental resources. Recommend exclusion or retirement, but require explicit confirmation and revalidation at execution time.
- Preserve shared-DNS and other dependency actions for excluded customer-owned subscriptions. Exclusion from resource migration does not remove cross-subscription cutover obligations.
- Build workload readiness gates from cross-subscription dependencies. Do not delete a source resource until all downstream references are repointed and tested.
- Classify external subscription references into Microsoft-managed platform dependencies and customer-owned dependencies. Block only unresolved customer-owned dependencies unless the user chooses a stricter rule.

### Security, operations, and resilience

- Recommend private access by default for target PaaS services, with documented and security-reviewed exceptions for required public endpoints. Preserve HTTPS-only behavior, certificates, health probes, access restrictions, and partner integrations.
- Treat missing ownership and criticality tags as migration-governance gaps. Recommend owner validation for potential orphans and require ownership/criticality metadata before production migration when the user approves that control.
- Preserve workload-specific Log Analytics workspaces when they reflect real operational boundaries; centralize shared/security telemetry and rationalize only with owner approval.
- Compare protected backup items with the actual VM/stateful workload count. Preserve confirmed protections and recommend owner-led investigation of unhealthy or missing protection, private vault access, immutability review, restore testing and appropriate remediation or documented exceptions. Backup-health remediation is always advisory; do not ask whether to make it mandatory or use it as a migration-readiness gate.
- Preserve current storage/database redundancy unless the user approves a change. Recommend zone redundancy or stronger storage replication for business-critical workloads according to confirmed RPO/RTO rather than applying blanket upgrades.
- Retain APIM Developer tier only for non-production when approved. Recommend an SLA-backed tier for production and validate networking behavior for the selected tier.
- For classic Azure Cache for Redis, recommend assessing Azure Managed Redis. Record compatibility, persistence, clustering, TLS, networking, and destination availability as future design and validation dependencies; use the discovered source SKU as the planning baseline until those dependencies can be resolved.
- Recreate managed identities, role assignments, federated credentials, Key Vault access, secrets, keys, and certificates through controlled runbooks. Never export secret values into the planning package.
- Recreate AKS, Container Apps, VM scale sets, and managed control-plane infrastructure through supported deployment methods rather than copying provider-managed resources.

### Service-specific discovery and migration guidance

Apply only the sections relevant to discovered services. For each service, document:

- Inventory and source configuration.
- Application, platform, network, identity, and data dependencies.
- Proposed recreation, replication, export/import, or re-registration method.
- Cutover sequence, validation criteria, service-interruption conditions, and rollback method. Determine operational windows with the workload owner from the actual change plan rather than prescribing durations in the package.
- Exact source SKU and scale as the unvalidated destination planning baseline.
- Destination service, SKU, quota, capacity, and feature checks that must occur when the planned region becomes available for qualification.

#### App Service and Web Apps

- Inventory App Service plans, Web Apps, API Apps, deployment slots, operating system, runtime stacks and versions, plan SKUs, worker counts, autoscale settings, zone redundancy, and App Service Environment dependencies.
- Preserve app-to-plan placement when it represents a real scaling, isolation, ownership, cost, or lifecycle boundary. Recommend regrouping only when discovery demonstrates a benefit and application owners approve it.
- Capture custom domains, certificate bindings, managed identities, authentication settings, access restrictions, health checks, deployment configuration, backup settings, and application-setting names. Never export application-setting values, connection strings, certificates, or secrets.
- Map inbound public access and private endpoints separately from outbound VNet integration, route-all behavior, DNS, NAT, firewall, service endpoints, and fixed-egress dependencies.
- Identify dependencies on Key Vault, databases, Storage, Service Bus, Event Hubs, API Management, Container Registry, Application Insights, partner endpoints, and on-premises services.
- Identify the authoritative application artifact and deployment pipeline. Prefer recreating plans, apps, slots, identity, networking, and configuration through the customer's existing IaC and CI/CD process rather than cloning an app without provenance.
- Treat a tightly coupled app, its plan and slots, and its required platform dependencies as one migration unit unless the dependency analysis supports separation.
- Include a per-application dependency matrix and cutover/rollback approach in the consuming workload document.
- Define certificate readiness, DNS TTL preparation, deployment-slot strategy, application warm-up, health validation, session handling, scheduled jobs, custom-domain cutover, possible service interruption, and rollback to the source endpoint.
- Use the source plan SKU, worker count, runtime, and scaling configuration as the destination planning baseline. Do not imply destination support until the planned region can be qualified.

#### Azure Functions

- Inventory hosting plans, runtime and extension versions, trigger and binding types, deployment slots, scale settings, storage accounts, managed identities, networking, host-key dependencies, and Durable Functions state.
- Group each function application with its trigger sources, required storage, secrets, and downstream services. Define producer pause, drain, checkpoint, replay, duplicate-processing, and rollback behavior for event-driven cutovers.

#### API Management

- Inventory tier, units, APIs, revisions, versions, products, subscriptions, policies, named-value names, certificates, identities, custom domains, gateways, developer portal, diagnostics, networking mode, and backend dependencies.
- Preserve policy behavior and certificate trust chains without exporting secret named values or subscription keys. Define DNS, gateway, backend, client, and subscription-key transition steps and validate the selected tier's required networking capabilities later.

#### AKS and Container Apps

- Inventory cluster or environment versions, node pools and workload profiles, identities, registries, ingress, egress, DNS, network policy, persistent storage, secrets integration, autoscaling, observability, policy, and deployment pipelines.
- Recreate supported control-plane resources and deploy workloads from authoritative manifests or pipelines. Define image replication, persistent-data movement, traffic switching, workload validation, and rollback independently.

#### Data and analytics services

- Assess Azure SQL, SQL Managed Instance, Cosmos DB, PostgreSQL, MySQL, Synapse, Databricks, Data Factory, and Fabric separately because their migration and validation methods differ.
- Capture engine and compatibility versions, data size and growth, throughput, replication, encryption, identities, private connectivity, integration runtimes, linked services, maintenance windows, RPO/RTO, synchronization method, data validation, cutover, and rollback.
- Treat Fabric workspace and item discovery as a service-specific exercise rather than inferring complete scope from Resource Graph capacity objects.

#### Storage

- Inventory account kind, performance tier, redundancy, access tier, capacity, transaction profile, endpoints, firewall rules, private endpoints, lifecycle rules, immutability, SFTP/NFS features, encryption, file-share configuration, and dependent applications.
- Define replication or copy tooling, change synchronization, integrity validation, final-delta handling, endpoint cutover, and rollback. Preserve stronger source resilience unless an approved design decision changes it.

#### Integration and messaging

- Assess Service Bus, Event Hubs, Event Grid, Logic Apps, and Data Factory with their producers and consumers rather than as isolated resources.
- Capture namespaces, entities, throughput or capacity, schemas, filters, sessions, checkpoints, identities, networking, retry and dead-letter behavior, ordering requirements, integration accounts, connectors, and self-hosted integration runtimes.
- Define producer and consumer cutover order, drain or replay handling, duplicate-processing controls, endpoint transition, validation, and rollback.

#### Identity, secrets, and registries

- Inventory managed identities, role assignments, federated credentials, Key Vault dependencies, keys, certificate metadata, private endpoints, Container Registry SKUs, replicas, images, tasks, webhooks, and content-trust requirements.
- Recreate access relationships using least privilege, replicate images through supported tooling, and plan credential or certificate rotation. Record only secret references and metadata, never secret material.

#### Monitoring, backup, and operations

- Inventory Application Insights, Log Analytics workspaces, diagnostic settings, data-collection rules, alerts, action groups, dashboards, retention, Automation, update management, backup policies, protected items, and operational ownership.
- Define telemetry continuity, alert suppression and re-enablement, dashboard updates, backup re-protection, restore testing, operational acceptance, and heightened post-cutover monitoring.

### Specialized workloads and delivery method

- Azure Arc server re-registration belongs to a separate hybrid workload dossier from the shared landing zone unless the owner confirms a different boundary.
- Treat Microsoft Fabric capacity/workspace relocation as a separate solutioning track. Resource Graph capacity objects are not a complete Fabric inventory.
- Use Azure Region Move Initiative or Azure Resource Mover for supported same-tenant regional moves. Use the customer's existing IaC standard plus service-native replication/export/import/re-registration for unsupported resources.
- Prefer the customer's existing IaC modules and pipelines. When gaps exist and no other standard is specified, recommend Bicep rather than replacing working IaC solely for migration.
- Use exact discovered source SKUs as the planning workbook baseline. Mark them unvalidated for the destination; never invent a target SKU or use `N/A` for a resource that has a SKU.

### Workload-first document sequence and boundaries

1. **00 Overview:** A customer-readable estate introduction, as-is high-level regional topology, discovered workload table, named cross-workload connections, and a two-column external-service-to-owning-workload register. Show a proposed workload-based document model separately from current traffic. Include the short **Inventory basis** section near the end, followed by a reading-order table containing **only existing deliverables** and their matching workbook links; add rows as workload dossiers are created. No SKU quantities, resource-count headlines, waves, or timelines.
2. **01 Workload 0: Landing Zone:** Describe the shared foundation needed to operate: governance and identity boundaries, shared Virtual WAN/VNet routing, inspection/egress, existing-region shared connectivity, shared DNS, Bastion, DDoS protection, and platform monitoring. Open with a brief base-layer context, then a **discovered as-is architecture diagram before any proposed diagram**. Explicitly evaluate whether the existing foundation is sound, recommend evidence-based improvements where needed, and make any redesign a separate approval decision before showing the proposed diagram. Show source SKU/tier baselines in a concise `Shared role | Discovered source | Source SKU / planning baseline` table and a matching SKU workbook. List firewalls in firewall rows and their policies **only** in a separate policy row; do not duplicate policy names with each firewall. Omit a redundant role-description column and lengthy "how to read service tiers" explanation; add only brief SKU clarifications in the relevant cells. Decisions and cleanups address only the foundation. Do not place website ingress, workload spokes, application/private endpoints, application backup, Azure Arc, or unverified partner services here.
3. **02 onward: One dossier per confirmed boundary or clearly labelled review candidate:** Include all that grouping's environments (for example Dev, QA, PreProd and Prod), distinguishing which services are shared and which are environment-specific. Show as-is application architecture and flows first, then proposed design, named inbound/outbound and cross-subscription dependencies, data, identity, DNS, operations, third-party/Marketplace integrations, owner confirmations, critical cleanups, coexistence, validation and rollback. A website's Imperva/Front Door routes belong to the website dossier; hybrid Arc/GCP belongs to the hybrid dossier. Honor customer-approved combined planning groupings, such as Saudia's combined saudia.com and Digital services, while retaining distinct source roles and marking actual callers and ownership unverified where traffic evidence is unavailable.

- Use a unique zero-padded reading-order prefix for each dossier. For Saudia, name the source dossier `<NN>-<Workload>-Workload-Analysis.md`, the customer PDF `<NN>-<Workload>-Workload-Analysis.pdf`, and its workbook `<NN>-<Workload>-Resources.xlsx`; the three share the prefix and workload slug, not the complete basename. For example: `01-Landing-Zone-Workload-Analysis.md`, `01-Landing-Zone-Workload-Analysis.pdf` and `01-Landing-Zone-Resources.xlsx`. Do not renumber old published versions.
- Group by business service and actual ownership, not by environment-only waves or a subscription label. Each owner decides the consuming workload's dependencies and target quantities; the overview gives context, and the landing zone supplies only shared foundation requirements.
- Show separate, readable diagrams for current verified paths and proposed relationships. Put rendering images inline in the relevant Markdown; retain editable Mermaid sources alongside them. Label each arrow's meaning and use distinct styles for observed traffic, configured private endpoints and proposed dependencies. Do not draw connections merely because components share a region or subscription.
- Keep a full private-endpoint evidence inventory outside the narrative: endpoint name, consumer and target subscription, IDs, region, target, subresource and state. Document named cross-subscription targets within the consuming dossier; validate caller, DNS, authorization, lifecycle, and operational impact before changing them. A production consumer's service hosted in Test/Non-Prod is not automatically a non-production dependency.
- When external services are discovered, maintain a separate third-party applications and Marketplace evidence document listing named services (such as Imperva), confirmed or suspected consumers, environment, integration, ownership, billing/entitlement evidence, data flow and residency, and open verifications. The consuming workload dossier owns design, vendor and cutover decisions; the separate document is an estate-wide reference, not a competing decision log. Add it to the overview reading table only after it exists. Do not assume a discovered integration is a Marketplace purchase.
- Where decisions or cleanups apply, use the heading **Decisions and Critical Cleanups Required (if applicable)** and a two-column `Decision or cleanup | Evidence and Remediation` table. Use bullets within the second column for evidence and the owner-led remediation, with sub-bullets only when they clarify multiple actions. Omit a separate "Why it matters" column; retain exact affected services, live-state/impact verification, disposition (repair/retire/exception), and acceptance dependency where relevant. Readiness follows dependency closure, not an estimated schedule; backup-health remediation remains advisory and is not a readiness dependency.

### Per-workload SKU and quantity workbook

- For Saudia, create a **new workbook from** `repatriation\v3\source\FY27_09_28_workload_template.xlsx` (or its subsequently supplied location); do not overwrite it except when the customer explicitly requests a template change. Preserve the columns `WorkloadName | CustomerName | WorkloadType | ServiceName | Environment | ServiceACR | MilestoneID | MilestoneName | Capacity | [blank] | Owner | UAT`, then add `SKU` and `Quantity` to the right. `ServiceName` must contain only the generic Azure service/catalog name, such as `Azure Kubernetes Service`, `Virtual Machines`, or `Azure SQL Database`: no environment prefixes, application roles, pool names, subresources, or discovered resource names. Put `Dev`, `QA`, `PreProd`, `Prod`, or an accurate shared-foundation environment in `Environment`; retain resource names, roles, pool names, private endpoint subresources, and detailed traceability on an evidence sheet, not in `ServiceName`. Set `WorkloadName` to the dossier's workload name (for example, `Landing Zone`), and keep unconfirmed commercial or milestone fields empty rather than inventing values. For other engagements, use the customer's supplied template, or agree a schema if none exists.
- Name the main resources-and-SKUs worksheet **`workload_resources`** and make it the **first sheet** in the FY27 template and every delivered workload workbook. Keep `ServiceName`, `Environment`, `SKU` and `Quantity` on that sheet in their established template-derived columns; retain basis, endpoint, application and other evidence sheets after it. Validate sheet order, sheet name, headers and evidence preservation in Excel before publication.
- Create the Saudia workbook with the same numbered workload slug as its Markdown but the `-Resources.xlsx` suffix. Keep service rows concise and scoped to deployable workload roles; include a separate basis/evidence sheet if needed to trace proposed quantities to exact source resources, environment, ownership and inclusion decisions. A quantity is a **proposed destination allocation**, not automatically the number of current source resources across all regions; for review candidates or unresolved owners, leave the target quantity blank and retain the source SKU and evidence rather than inventing an approved allocation.
- Retrieve source SKUs from the environment with read-only service-specific ARM queries where Resource Graph lacks a top-level `sku`. Record actual service type or tier when expressed differently: e.g. Virtual WAN `properties.type=Standard`, Azure Firewall deployment/tier, VPN gateway scale units, DDoS **Network Protection** plan/VNet association, resolver components, and public IP tier. State explicitly when a resource has no conventional SKU property; `N/A` describes the API field, not necessarily an unknown service tier.
- Carry forward observed source tiers as the **planning baseline** unless Saudia approves a change; mark destination support, quota, capacity, cost and quantity as pending qualification when unverified. Split rows by environment, role, SKU, region or material sizing difference. Include needed separately billable supporting services, but do not bill platform-generated artifacts independently. Reconcile each row's quantity and reference to the source evidence.
- On OneDrive/IRM-protected folders, stage a new XLSX locally and copy the completed workbook into the requested folder; Office protection may change the on-disk file header. Validate via Excel if `openpyxl` cannot reopen the protected copy, and never overwrite the source template.

### Estate-wide monthly services and actual-cost workbook (every customer)

- Create a separate `<customer-slug>-services.xlsx` for each customer in the agreed publication folder, in addition to the per-workload `-Resources.xlsx` files. Use the customer's supplied three-column services template if available; otherwise reproduce the Saudia layout. The **first sheet** must be `Services` with exactly `ServiceName | Workload | ACR`, in that order, with no extra visible columns or sample rows. `ACR` contains numeric **monthly historical Azure ActualCost** in the stated reporting currency; it is the team's requested column label, not a claim that the number is Microsoft's formal Azure Consumed Revenue metric. Do not populate it with estimates, proposed capacity or retail prices.
- Use the confirmed billing month, preferably the last completed calendar month, and the confirmed subscription scope. Query Cost Management by **ResourceId and ServiceName** at each subscription, preserving full pagination and throttling behavior; source records may contain late adjustments. Record the reporting month, UTC retrieval timestamp, `ActualCost` measure, reporting currency, original currencies, exchange rate and its customer-approved basis, and any late-charge caveat on `Basis and reconciliation`. Never silently sum different currencies or reuse an exchange rate from another engagement.
- Attribute only defensible billing records to agreed planning workloads using the exact resource ID, subscription and validated ownership rules. A dedicated subscription can be a planning boundary when confirmed; a shared subscription, shared resource group or resource name alone cannot prove the consuming application. Keep ambiguous, mixed-use and subscription-level charges in `Unallocated costs` with explicit reasons. Keep reservation purchases and other upfront commitments separate from monthly workload usage; don't spread them across applications without an approved accounting method. When the customer combines workload reporting groups, update both the cost classification and the workload package without implying observed application traffic.
- In `Services.ServiceName`, append a verified **source** tier/SKU when available, e.g. `Virtual Machines: Dsv5-series`, `Redis Cache: Premium P1`, `Application Gateway: WAF_v2` or `Microsoft Fabric: F256`. Match the billed resource ID **and** the appropriate billed service/resource type to discovery or read-only service-specific ARM evidence; do not attach a VMSS's SKU to a `Virtual Network` charge merely because the resource ID names the VMSS. Keep a generic service label when no defensible source tier exists. These labels describe the observed resource tier at the evidence date, **not** the billing meter SKU, a whole-month configuration history or a destination SKU. Unlike the services workbook, the per-workload resource workbooks keep generic `ServiceName` and put SKU in their dedicated column.
- Preserve six worksheets in order: `Services`; `Basis and reconciliation` (`Metric | Value | Meaning`); `Attribution evidence` (`Workload | ServiceName | Source subscription | Subscription ID | Source currency | ActualCost USD equivalent | Attribution basis`, replacing `USD` with the actual agreed reporting currency as needed); `SKU evidence` (`Workload | ServiceName | Subscription ID | Source resource ID | Source resource type | Discovered source SKU | SKU provenance | Source currency | ActualCost USD equivalent`, likewise using the reporting currency); `Subscription reconciliation` (`Subscription | Subscription ID | Source currency | ActualCost USD equivalent | Attributed USD | Unallocated USD | Note`, with reporting-currency headers adapted together); `Unallocated costs` (`Subscription | Subscription ID | ServiceName | Source currency | ActualCost USD equivalent | Reason`, likewise adapted). Preserve the three-column customer-facing `Services` schema regardless of the evidence-sheet currency header changes.
- Reconcile each subscription's original-currency records to its converted reporting-currency total; verify `Services` equals `Attribution evidence`, `Services` plus `Unallocated costs` equals the retrieved ActualCost total, and the SKU-labelled portion of `Services` equals `SKU evidence`. Keep exact source-resource traceability in supporting sheets without exposing credentials or billing tokens. Stage and validate the workbook before publication; preserve a prior published version if replacing one. If billing access, source completeness, currency conversion approval or a locked publication file blocks the workbook, report the blocker and do not mark this required deliverable complete.

## Microsoft program alignment

Treat these as separate programs with separate engagement processes:

### Cloud Accelerate Factory

Use for broad Azure adoption acceleration, Azure Landing Zone adoption, re-architecture, re-platforming, modernization, AVD/AVS, application, data, analytics, security, or AI delivery using repeatable patterns.

Nomination uses its own field, partner, or Offer Navigator/MCI process. Do not present it as the Azure Region Move Initiative nomination path.

### Azure Region Move Initiative

Use for same-tenant, cross-region movement of existing Azure resources, including repatriation and data-residency moves. It is primarily lift-and-shift and requires a resource inventory for nomination.

Call out its separate nomination, sponsorship, Azure PG qualification, joint-delivery, capacity, and scope constraints. Do not claim approval or availability before qualification.

Assess program applicability **per workload and move method**, not by document number. Identify supported same-tenant regional resources as potential Region Move Initiative scope subject to nomination and qualification; redesigned platforms may need Cloud Accelerate Factory, and Arc re-registration or Fabric may need separate solutioning. State fit, constraints, and next owner action in the relevant workload. Use colored program highlighting only when a customer presentation or styled PDF requests it.

## Deliverables

Create deliverables incrementally after their scope and decisions have been reviewed:

- `00-Overview.md` introducing as-is estate topology, discovered workloads and third-party applications, dependency summary, provenance, qualifications, and **only existing** documents in its reading table.
- `01-Landing-Zone-Workload-Analysis.md` and `.xlsx` for the shared foundation.
- One self-contained Markdown dossier and corresponding template-derived `-Resources.xlsx` workbook for each subsequently confirmed Saudia workload; add a reading-table row only after the files exist.
- One `<customer-slug>-services.xlsx` estate-wide actual-cost workbook for every customer, using the exact three-column `Services` layout and the evidence/reconciliation sheets above. It is separate from the destination-allocation workbooks; report a billing-access blocker rather than omitting it silently.
- Keep raw discovery, detailed private-connection evidence, reconciliations and technical inventory separate from customer-facing overview and allocation workbook. Preserve earlier published versions without modifying them in place.
- Maintain the separate third-party/Marketplace evidence document for discovered external services; reflect all consumer-specific decisions in the owning dossiers. Record commercial verification status from actual billing or marketplace evidence.
- Generate PDF, PPTX or a published package **only when requested**. A Markdown-first dossier review does not require PDF conversion, a README, a slide deck, or a wave index.

If a presentation is requested, produce both PPTX and PDF with the agreed scope. Lead with discovered workloads, third-party services and key topology. Show the shared foundation, named workload dependencies, customer decisions and readiness gates; omit resource-count slides, allocation quantities, waves, calendar dates and effort estimates. Use readable, evidence-labelled diagrams and native shapes; export the PDF and check matching slide/page counts and descriptive title metadata. Use `python-pptx` with reusable design helpers if generating programmatically.

## Presentation visual design rules

A first-pass deck of plain title+bullets slides is not acceptable output. Apply every rule below when generating the migration strategy presentation.

**Design system (define once, reuse everywhere):**

- Fix a small color palette as RGB constants: a dark navy/brand color for headers and body text, a gray for secondary text, workload accents, plus light and dark neutrals for backgrounds. Define these once at the top of the build script and reference them everywhere.
- Use consistent colors for each named workload or delivery track across its badge and dependency-flow node; colors distinguish tracks, not a presumed risk ranking or sequence.
- Use one heading treatment across all slides: a colored header band containing a small uppercase eyebrow/kicker line (section label) above the bold slide title, with a thin accent rule beneath it. Keep a footer with the source document reference and slide number.

**Required visual components (do not ship a deck without these):**

- **Capability cards** on the executive-summary slide: rounded rectangles with a colored top accent bar, a named workload or delivery track, and a short dependency or outcome underneath. Do not use numerical estate KPIs.
- **Icon/marker bullets, not plain text bullets**: render top-level bullets with a small colored square or rounded-square marker and sub-bullets with a smaller neutral dash/oval marker, built as actual shapes next to a text box — not the built-in bullet character. Keep bullet body text at normal (non-bold) weight; reserve bold for numbers, headings, and single-line callouts only, or the slide reads as shouting.
- **Workload badges** paired with workload titles and one-line dependency statements, on workload-detail slides where useful.
- **A native connector dependency flow** showing the shared foundation and named consuming workloads, including parallel paths when evidence supports them. Label readiness prerequisites, never elapsed time.
- **Severity/impact-shaded table rows** on any findings or design-review table: light red/amber/neutral row fills that darken with severity or consolidation impact, plus a one-line caption explaining the shading key.
- **Checkmark-circle bullets** on a confirmed-decisions/decision-log slide, to visually distinguish "settled" statements from open bullets elsewhere in the deck.
- **A decorative title/closing slide** with a simple source-region to planned-destination chip flow, without implying validated destination capacity.
- Prefer native relationship diagrams over charts of resource or subscription counts.

**Implementation pattern:**

- Structure the build script as small reusable helper functions for cards, markers, tables, dependency connectors, and title/closing bands.
- After generating, render representative slides (title, a workload detail, dependency relationships, findings, decisions, closing) to PNG and inspect for overflow, contrast and overlaps.
- If any text box looks cramped or bold overload makes a slide hard to scan, fix the root cause (font size, box height, bold flag) in the shared helper function, not with a one-off patch on a single slide.

## Naming and workload document template

Use `00-Overview.md`, `01-Landing-Zone-Workload-Analysis.md` and `01-Landing-Zone-Resources.xlsx`, then `<NN>-<Workload>-Workload-Analysis.md` and `<NN>-<Workload>-Resources.xlsx` for confirmed Saudia workloads. Preserve existing numbers and workload slugs. PDFs share their Markdown basenames; a presentation or appendix has its own agreed name and must not displace a workload number. A README, if requested, links to the files actually published. The overview reading-order table stays up to date with actual existing dossiers and workbooks, not aspirational entries.

Each workload dossier should contain, in this order when applicable:

1. Name, business context, confirmed ownership and environment boundary.
2. **As-is** architecture with inline rendered diagram, discovered services, source tiers and integration evidence.
3. Named consuming and provider dependencies; external services with confirmed owner or owner-verification action.
4. **Proposed** architecture and foundation prerequisites; explain what is required for this workload without moving its decisions into Workload 0.
5. Decisions, source cleanups, readiness/acceptance criteria, validation, coexistence, cutover and rollback. Mark unresolved approvals.
6. Applicable program or separate solutioning path and future destination qualification.
7. Matching SKU/quantity workbook link and any detailed evidence references.
8. A short **Inventory basis** section stating the actual extraction date, customer review/approval context, owner confirmations and applicable destination-validation conditions. It may follow the workbook link, as in the landing-zone dossier.

Use direct customer-readable wording and the two-column decisions/cleanups format above when applicable. Exact endpoint lists and reconciliation belong in technical evidence.

## PDF generation rules

- Convert Markdown to HTML then to PDF with headless Chrome. Extract Mermaid blocks and render them to PNG with the Mermaid CLI first; do not rely on client-side Mermaid rendering in headless Chrome.
- Render every diagram block separately and replace it with an image link before PDF conversion. Check that diagrams are embedded images in the PDF, legible at page size, and consistent with the written dependency register; fail explicitly if rendering fails.
- Every generated HTML document must set an explicit `<title>` before conversion, for example `<title>Saudia Repatriation - Landing Zone Workload Analysis</title>`. Never let the PDF title default to a source filename.
- After conversion, verify the PDF's `/Title` metadata (for example with `pypdf`) matches the intended document title, not a filename, `.md`/`.html` extension, or `None`. Fix any mismatch by rewriting the metadata or regenerating with an explicit title before publishing.
- Use a descriptive title pattern: `<Engagement/Project Name> - <Document Name>`.
- Use 0.5-inch PDF margins on all sides unless the user requests otherwise.

## Publication rules

- Publish the requested Markdown, workbooks, PDFs and/or presentation to the agreed folder. Do not generate additional formats merely because older packages contained them.
- In the current Saudia `repatriation\v3` package, keep **only deliverable `.xlsx` and `.pdf` files** at the top level. Put all editable Markdown, the FY27 template, Mermaid sources, diagram images and build scripts under `repatriation\v3\source`; links from Markdown to a published workbook use its parent folder. Do not leave build environments or loose assets at the package root. This customer-requested layout supersedes older V3 example paths; customer workbooks use `-Resources.xlsx`.
- When the publication folder is OneDrive-backed or applies Office protection, stage generated Office files and HTML/headless-browser builds in a local temporary directory, then copy completed artifacts into the requested folder. Keep source outputs and presentation PDF in sync.
- Remove retired artifacts only after confirming the replacement files exist.
- Verify the final publication folder contains exactly the agreed current artifacts and no stale conflict copies; preserve older versions outside the new package.
- Do not overwrite unrelated files in the requested destination.
- If Office/IRM protection changes workbook file headers or prevents programmatic reopening, do not treat that as corruption. Preserve the protected workbook and report the limitation.

## Completion gate

Before reporting completion, verify:

- For new discovery, account, tenant, subscriptions and inventory scope were confirmed; inaccessible customer-owned dependencies were inventoried or identified with owner-confirmation actions. For a skill-only or documentation-only update, do not repeat Azure discovery.
- Destination service, SKU, quota, feature, and capacity qualification appears in the relevant readiness/design sections as a mandatory pre-execution dependency, without repeating a warning at the top of each customer document.
- Findings and recommendations were presented.
- The current landing zone was evaluated and evidence-based improvements recommended where needed; any redesign remains a separately approved decision.
- Backup-health remediation is advisory throughout the package and is not made a mandatory readiness condition.
- Material design decisions were confirmed for approved publication; draft material marks pending decisions and owners clearly.
- The overview lists the actual discovered workloads, high-level topology, external-service consumers and only existing dossier/workbook files. Each dossier owns its workload decisions; the landing zone contains only foundation requirements.
- Each created Saudia workload has a corresponding `-Resources.xlsx` workbook derived from the supplied template with preserved columns plus `SKU` and `Quantity`, and traceable source-based tier and proposed quantity evidence. Generated artifacts are not counted as independent allocations.
- Every customer package contains a separate monthly `<customer-slug>-services.xlsx` with first-sheet `ServiceName | Workload | ACR`, verified source SKU labels where available, recorded cost period/currency/conversion, complete attribution and SKU evidence, unallocated charges, and reconciled subscription and overall ActualCost totals; if access or approval prevents it, report the deliverable as blocked.
- If a presentation was produced, it uses the presentation visual design rules (workload cards, dependency flows and readable diagrams rather than plain title-and-bullet slides), and representative slides were rendered and spot-checked.
- Confirm no timeline, effort estimate, or resource/quantity headline appears in the generated customer documents or presentation; counts belong only in the separate technical inventory and resource workbooks. Verify third-party commercial classifications against marketplace evidence or label them unverified.
- Every customer-facing Markdown document has a concise **Inventory basis** section with the actual extraction date, review/approval context and document-specific owner and destination qualifications; detailed raw evidence stays in technical files. A README, if produced, may also contain a short opening planning/approval note.
- Dependency diagrams clearly distinguish observed serving routes, configured private connections and proposed target architecture; every cross-subscription target in the narrative traces to evidence, and detailed endpoint records are included in a separate technical inventory. Production-to-Test/Non-Prod hosting links are explained by named service, with actual runtime callers awaiting owner validation.
- Critical cleanups identify exact impacted services, owner, live-state/impact validation, action and consuming-workload readiness gate.
- If PDFs were requested, rendered diagrams appear as legible images, each requested Markdown document has its PDF, and every PDF has a descriptive `/Title`.
- Program applicability is stated for each approved workload, based on actual scope rather than document number.
- Published filenames and both the overview reading table and optional README index exactly match the artifacts that exist. Existing versions and user files were preserved.
