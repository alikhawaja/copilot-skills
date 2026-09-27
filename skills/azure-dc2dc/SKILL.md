---
name: azure-dc2dc
description: Plan and document an Azure data-center-to-data-center or cross-region migration for a complete Azure estate into a planned Azure region that is not yet live. Use when the user asks to inventory the estate, assess migration readiness, design migration waves, create migration deliverables, or publish the final migration package.
---

# Azure DC-to-DC migration

Use this skill to run the complete migration-planning journey from authenticated discovery through approved design decisions, deliverable generation, PDF conversion, and publication for any Azure estate.

## Operating rules

- Ask for the **account** and **tenant** before discovery. Do not assume the signed-in Azure account or tenant.
- if a directory is provided for an isolated azure session, try to discover the account and tenant from there.
- Verify the Azure CLI session with `az account show`, confirm the tenant, and list the subscriptions visible to the signed-in account.
- Ask the user to select the subscriptions in scope, with an explicit option to select all subscriptions visible in the confirmed tenant. Never treat all visible subscriptions as in scope unless the user selects that option.
- If a selected subscription is not visible, stop and report the authentication or access issue. Do not switch accounts silently.
- Run discovery in an isolated working directory. Do not overwrite Azure CLI session files, existing exports, or another migration engagement.
- Ask for the requested publication folder before creating deliverables.
- Treat discovery as read-only. Do not modify Azure resources.
- Do not create final documents until findings, recommendations, and design decisions have been reviewed and confirmed.
- Use explicit errors and stop on failed discovery, unresolved customer-owned inventory gaps, or unresolved design decisions.
- Treat the destination as a planned Azure region that is not yet live. Do not attempt to qualify current target-region service, SKU, quota, or capacity availability. Use the requested destination label, identify future availability validation as a mandatory pre-execution dependency, and do not describe the package as deployment-ready.
- Preserve literal Azure resource names, resource-group names, application names, and subscription identifiers exactly as discovered. Remove only accidental project branding from document prose when requested.
- Base the target architecture on discovered current state. Do not recommend a firewall vendor, hub technology, gateway, NAT pattern, or topology before inventorying what is deployed and determining whether it is operationally sound.

## Required interaction sequence

### 1. Establish context and access

Ask, one at a time:

1. Which Microsoft account should be used?
2. Which Azure tenant should be inventoried?
3. Which subscriptions should be inventoried? Present the visible subscriptions and allow either an explicit selection or **all visible subscriptions in the confirmed tenant**.
4. What is the destination Azure region/data-center label?
5. Where should the final package be published?

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
- Existing hub-and-spoke or Virtual WAN topology, including the actual security and egress path, route propagation, DNS flow, hybrid links, and managed-service networks.
- Public-network-access posture for data, application, registry, and secrets services.
- Backup coverage and health, not only the existence of vault resources.
- Resiliency signals such as storage replication, database zone redundancy, DDoS-plan association, and availability-zone use.
- Managed-service dependencies whose resource IDs reside in Microsoft-managed subscriptions, including Virtual WAN, API Management, AKS, Data Factory managed VNets, Fabric managed private endpoints, and similar platform infrastructure.

Preserve raw exports separately from cleaned analysis data. Validate counts, subscription coverage, resource-group coverage, and duplicate or ambiguous resources before analysis.

For references to subscription IDs outside the visible scope:

- Inspect the referenced resource IDs and resource-group patterns before calling them missing customer subscriptions.
- Classify Microsoft-managed backing subscriptions as platform dependencies rather than migration targets.
- Treat customer-owned inaccessible subscriptions as inventory gaps. Either obtain access or explicitly exclude their resources while retaining dependency actions and owner confirmation as a migration gate.

### 3. Present findings before planning

Present a concise findings review before creating any migration plan:

- Subscription and region inventory.
- Dev/Test/Prod/shared resource counts.
- Workload/application grouping.
- Cross-subscription dependencies.
- Orphaned, isolated, untagged, duplicate, or ambiguous resources.
- Azure Arc and other hybrid assets that are not native Azure resources.
- Destination-region service, SKU, quota, and capacity validation dependencies that must be resolved when the region becomes available for qualification.
- Resource types outside the selected Microsoft delivery program.
- Important SKU, security, identity, networking, backup, resiliency, and operational observations.
- Whether the existing landing-zone topology is sound and should be retained, or whether evidence supports a redesign.

Then provide **design review recommendations**. Do not silently turn recommendations into decisions.

### 4. Confirm decisions and resolve ambiguity

For every material recommendation, ask for confirmation or clarification. Keep a decision log with:

- Decision.
- Rationale.
- Affected waves/resources.
- Owner or approver.
- Open dependency.
- Whether the decision is confirmed, pending, or rejected.

Do not generate final deliverables while material decisions remain pending.

## Discovery-led decision pattern

Use these as configurable starting points. Apply only when supported by discovery and revalidate every material choice with the user:

### Architecture preservation and enhancement

- Start from the current landing-zone architecture. If the estate has a sound hub-and-spoke or Virtual WAN design, recommend reproducing that operating model in the destination before proposing replacement technology.
- Preserve the existing firewall platform when it meets the target security, scale, support, and availability requirements. Do not introduce Palo Alto, Azure Firewall, another NVA, or an Azure Load Balancer merely because it appeared in a previous engagement.
- When the current estate uses Azure Virtual WAN with Azure Firewall Premium, VPN/P2S gateways, DNS Private Resolver, and spoke connections, prefer recreating that pattern through IaC. Migrate route intent, firewall policy, IP groups, diagnostics, threat-intelligence settings, hybrid links, and zone design.
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
- Build wave gates from cross-subscription dependencies. Do not delete a source resource until all downstream references are repointed and tested.
- Classify external subscription references into Microsoft-managed platform dependencies and customer-owned dependencies. Block only unresolved customer-owned dependencies unless the user chooses a stricter rule.

### Security, operations, and resilience

- Recommend private access by default for target PaaS services, with documented and security-reviewed exceptions for required public endpoints. Preserve HTTPS-only behavior, certificates, health probes, access restrictions, and partner integrations.
- Treat missing ownership and criticality tags as migration-governance gaps. Recommend owner validation for potential orphans and require ownership/criticality metadata before production migration when the user approves that control.
- Preserve workload-specific Log Analytics workspaces when they reflect real operational boundaries; centralize shared/security telemetry and rationalize only with owner approval.
- Compare protected backup items with the actual VM/stateful workload count. Preserve confirmed protections and clearly recommend remediation, private vault access, immutability review, and restore testing. Ask whether remediation is mandatory, advisory, or out of scope.
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
- Cutover sequence, validation criteria, rollback method, and expected downtime.
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
- Include a per-application dependency matrix in the workload inventory and a cutover runbook in the applicable wave document.
- Define certificate readiness, DNS TTL preparation, deployment-slot strategy, application warm-up, health validation, session handling, scheduled jobs, custom-domain cutover, expected downtime, and rollback to the source endpoint.
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

- Azure Arc server re-registration is a separate wave from Azure-native shared platform migration unless the user explicitly combines it.
- Treat Microsoft Fabric capacity/workspace relocation as a separate solutioning track. Resource Graph capacity objects are not a complete Fabric inventory.
- Use Azure Region Move Initiative or Azure Resource Mover for supported same-tenant regional moves. Use the customer's existing IaC standard plus service-native replication/export/import/re-registration for unsupported resources.
- Prefer the customer's existing IaC modules and pipelines. When gaps exist and no other standard is specified, recommend Bicep rather than replacing working IaC solely for migration.
- Use exact discovered source SKUs as the planning workbook baseline. Mark them unvalidated for the destination; never invent a target SKU or use `N/A` for a resource that has a SKU.

### Default wave shape

- Wave 0 remains assessment and qualification. Define the execution waves as Waves 1 through N, where N is determined by discovered workload boundaries, dependencies, risk, and approved delivery constraints.
- Migration waves may be merged, split, omitted, or added. Confirm the final wave count and scope with the user, and record any departure from the example sequence in the decision log.
- Use this dependency-led sequence as a starting example when it fits; it does not require exactly seven execution waves:
  - Wave 0: assessment, ownership, dependency closure, move-method matrix, and program qualification.
  - Wave 1: destination landing zone, connectivity, firewall, routing, DNS, Bastion, and DDoS decisions.
  - Wave 2: shared management, security, identity, DevOps, observability, and approved backup scope.
  - Wave 3: Azure Arc re-registration.
  - Wave 4: Dev, Test, UAT, and PreProd workloads.
  - Wave 5: production application and integration platforms.
  - Wave 6: production data and analytics, with Fabric as a separate solutioning track where present.
  - Wave 7: production business-critical workloads and final cutover.
- The architecture document remains the authoritative landing-zone design and contains the design decisions.
- Every execution wave is self-contained: prerequisites, design, inline diagram, components, design review notes, program alignment, SKU information, and resource checklist reference.
- The diagram appears immediately under the Design section, before Components.
- Design review tables use `Observation | Recommendation | Why it matters`.
- Wave documentation uses terse, specific, customer-readable language. Avoid conversational labels such as “Why first”.
- Use `Sequence`, `Estimated effort`, and `Scope` near the top of each wave document.
- Estimated effort is expressed as days, not calendar dates or a timeline.
- Wave 0 is document-only and has no resource checklist workbook.
- Each execution wave, Waves 1 through N, has a matching resource checklist workbook.
- Each workbook is a concise target-allocation summary, not a raw one-row-per-resource export. Aggregate interchangeable target components by resource role/type, region, and exact SKU, and place the aggregate count in `Quantity`.
- Use customer-readable allocation labels such as `Virtual Machine`, `Azure Functions`, `Private Endpoint`, `Azure SQL Database`, or `Log Analytics Workspace`. Split rows when SKUs, regions, service roles, environments, or move methods differ materially.
- Do not list platform-generated or supporting artifacts as independent target allocations when the parent service creates them, such as private-endpoint NICs, Network Watchers, managed-service VM scale sets, or restore-point collections. Account for them in an internal reconciliation file instead.
- Add explicit sizing rows for service subcomponents not represented as standalone Resource Graph resources when they affect capacity, such as AKS node pools, resolver endpoints, or scale-set instance counts.
- Reconcile every discovered in-scope resource to either a target-allocation row or a documented supporting/generated/excluded disposition. Validate that workbook quantities represent the intended deployable units rather than merely counting Resource Graph records.
- Each workbook has one worksheet and exactly these columns:
  `Resource Name | Resource Type | Region | SKU | Quantity`
- Use one exact planning SKU value per row, based on the discovered source SKU until the destination can be qualified. Use `N/A` only when the Azure resource has no SKU.
- Do not add owner, status, task, cost, notes, or current-vs-target columns to the workbooks.
- Keep `05-diagrams.md` retired. Put each diagram in its wave document.
- Keep `04-migration-waves.md` as a short index and overall sequencing diagram.
- Keep `03-landing-zone.md` as the architecture and design-decisions document.
- For standalone PDFs, use generic references such as “the README file”, “the architecture document”, “this wave's Prerequisites section”, and “the accompanying resource checklist workbook”. Do not use exact Markdown or workbook filenames inside wave prose.
- The README's document index table links each deliverable by its published PDF filename, not its Markdown source filename, since only PDFs are published.
- Where a wave row has a matching resource checklist workbook, add the full workbook filename (including `.xlsx` extension) on a second line within the same table cell as the wave's PDF link, so the reader sees both the document and its workbook without a separate column.
- In inventory tables, abbreviate subscription IDs with a visible truncation marker, for example `d5572236-...`; retain full IDs only in the README scope record.

## Microsoft program alignment

Treat these as separate programs with separate engagement processes:

### Cloud Accelerate Factory

Use for broad Azure adoption acceleration, Azure Landing Zone adoption, re-architecture, re-platforming, modernization, AVD/AVS, application, data, analytics, security, or AI delivery using repeatable patterns.

Nomination uses its own field, partner, or Offer Navigator/MCI process. Do not present it as the Azure Region Move Initiative nomination path.

### Azure Region Move Initiative

Use for same-tenant, cross-region movement of existing Azure resources, including repatriation and data-residency moves. It is primarily lift-and-shift and requires a resource inventory for nomination.

Call out its separate nomination, sponsorship, Azure PG qualification, joint-delivery, capacity, and scope constraints. Do not claim approval or availability before qualification.

For every wave, include an **Applicable Microsoft program** section:

- Highlight the applicable program in green in the PDF.
- Highlight the non-applicable program in red in the PDF.
- Explain why the applicable program fits the wave.
- Explain why the other program does not fit.
- If neither applies, state that directly and identify the required standalone or separate solutioning path.

Example default mapping:

Recalculate program applicability after waves are merged, split, omitted, or added. Assign eligibility from each wave's actual scope rather than its wave number.

| Wave | Default alignment |
|---|---|
| Wave 0 | Neither program executes work; output feeds Azure Region Move Initiative nomination |
| Wave 1 | Azure Region Move Initiative for supported existing hub resources; vendor-specific or redesigned network appliances require separate handling |
| Wave 2 | Azure Region Move Initiative for existing Key Vault, Storage, Backup, Log Analytics, and VM resources; redesign/consolidation may require Cloud Accelerate Factory |
| Wave 3 | Neither; Arc re-registration is a standalone hybrid operation |
| Wave 4 | Azure Region Move Initiative for supported Dev/Test resources |
| Wave 5 | Azure Region Move Initiative for supported App Service, Functions, and APIM; Fabric/unsupported items require separate solutioning |
| Wave 6 | Azure Region Move Initiative for supported Synapse, SQL, Storage, and Registry resources; WVD/AVD requires separate solutioning |
| Wave 7 | Azure Region Move Initiative for supported business-critical production resources |

## Deliverables

Create only after decisions are confirmed:

- README with scope, migration decisions, both Microsoft programs, nomination constraints, and document index.
- Environment inventory.
- Workload inventory.
- Architecture and landing-zone design.
- Short migration-wave index.
- One self-contained Markdown document for Wave 0 and every approved execution wave, Waves 1 through N.
- One resource/SKU workbook per approved execution wave, Waves 1 through N.
- PDF for every Markdown deliverable.
- Migration strategy presentation in both PPTX and PDF unless the user explicitly declines it.

For the migration strategy presentation:

- Produce both PPTX and PDF.
- Use a clear 16:9 visual design with consistent colors, typography, spacing, and page numbering.
- Make the deck self-contained and cover the executive summary, estate scale, current-state topology, target architecture, confirmed decisions, migration strategy, material risks, all migration waves, cross-cutting controls, Microsoft program alignment, and pre-execution gates.
- Give every migration wave a dedicated slide containing scope, estimated effort, prerequisites, design approach, core components, exit criteria, program alignment, and target-allocation quantity.
- Prefer native PowerPoint shapes, connectors, timelines, process flows, KPI cards, and simple charts over dense prose or screenshots.
- Export the deck to PDF and verify that the PPTX slide count matches the PDF page count and that the PDF has a descriptive `/Title`.
- Build the deck with `python-pptx`; never hand-craft slides in PowerPoint directly. Follow the visual design rules below so the first draft is lively, not a bland bullet-point deck.

## Presentation visual design rules

A first-pass deck of plain title+bullets slides is not acceptable output. Apply every rule below when generating the migration strategy presentation.

**Design system (define once, reuse everywhere):**

- Fix a small color palette as RGB constants: a dark navy/brand color for headers and body text, a gray for secondary text, an accent color for the current wave/CTA, plus a light and dark neutral for backgrounds. Define these once at the top of the build script and reference them everywhere — never inline ad hoc colors per slide.
- Give every wave its own color from a risk-graded palette, cool-to-warm across the wave sequence (for example: slate for Wave 0, blue/teal for early foundation waves, purple/green for mid waves, amber/red for the final production waves). Use that same wave color consistently for its badge, timeline chevron, and any chart segment referencing that wave, and state the color legend ("cool = lower risk/foundational, warm = higher risk/production") in a caption once.
- Use one heading treatment across all slides: a colored header band containing a small uppercase eyebrow/kicker line (section label) above the bold slide title, with a thin accent rule beneath it. Keep a footer with the source document reference and slide number.

**Required visual components (do not ship a deck without these):**

- **KPI stat cards** on the executive-summary slide: rounded rectangles with a colored top accent bar, a large bold number/value, and a short label underneath, for headline metrics such as VM count, subscription count, wave count, or estimated duration.
- **Icon/marker bullets, not plain text bullets**: render top-level bullets with a small colored square or rounded-square marker and sub-bullets with a smaller neutral dash/oval marker, built as actual shapes next to a text box — not the built-in bullet character. Keep bullet body text at normal (non-bold) weight; reserve bold for numbers, headings, and single-line callouts only, or the slide reads as shouting.
- **Colored numbered badges** (solid circle + number) on every wave-detail slide, filled with that wave's palette color, paired with the wave title and a one-line subtitle.
- **A native chevron/pentagon process-flow timeline** for wave sequencing — build actual `MSO_SHAPE.CHEVRON`/`MSO_SHAPE.PENTAGON` shapes color-coded per wave and laid out in dependency order (including parallel branches on a second row where applicable). Do not use a static exported diagram image for this slide; it must be editable native shapes.
- **Severity/impact-shaded table rows** on any findings or design-review table: light red/amber/neutral row fills that darken with severity or consolidation impact, plus a one-line caption explaining the shading key.
- **Checkmark-circle bullets** on a confirmed-decisions/decision-log slide, to visually distinguish "settled" statements from open bullets elsewhere in the deck.
- **A decorative title/closing slide**: diagonal accent bands (parallelogram shapes) plus a simple region/state "chip" flow (for example `Source Region A` chip → `Source Region B` chip → chevron → destination chip in the accent color) that visually previews the migration at a glance before the reader reaches any detail slide.
- Prefer simple native charts (bar/column) over tables when comparing counts across waves or subscriptions.

**Implementation pattern:**

- Structure the build script as small reusable helper functions (one per component: KPI card, icon bullets, wave badge, wave-intro header, table slide with row-color support, timeline slide, title/closing band) rather than repeating shape-creation code per slide. This keeps the deck consistent and makes future edits (recoloring, rewording) a one-line change.
- After generating, render a handful of representative slides (title, a wave-detail slide, the timeline, the design-review table, the decision log, the closing slide) to PNG (for example with `pymupdf`/`fitz` against the exported PDF) and visually inspect them before publishing, checking for text overflow, illegible contrast, and overlapping shapes.
- If any text box looks cramped or bold overload makes a slide hard to scan, fix the root cause (font size, box height, bold flag) in the shared helper function, not with a one-off patch on a single slide.

## Published file naming and sequence

Prefix every published artifact with a zero-padded sequence number so normal filename sorting presents the package in reading order. Use the fixed sequence for common documents, then assign wave sequence numbers dynamically:

| Sequence | Deliverable | Published filename pattern |
|---|---|---|
| `00` | README | `00-README.pdf` |
| `01` | Migration strategy presentation | `01-Migration-Strategy-Presentation.pdf` and `01-Migration-Strategy-Presentation.pptx` |
| `02` | Environment inventory | `02-Environment-Inventory.pdf` |
| `03` | Workload inventory | `03-Workload-Inventory.pdf` |
| `04` | Architecture and landing-zone design | `04-Architecture-and-Landing-Zone.pdf` |
| `05` | Migration-wave index | `05-Migration-Waves.pdf` |
| `06` | Wave 0 | `06-Wave-0-Assessment-and-Qualification.pdf` |
| `07` onward | Wave N, beginning with Wave 1 | `<NN>-Wave-<N>-Plan-<Short-Title>.pdf` and `<NN>-Wave-<N>-Resource-Checklist.xlsx` |

- For execution Wave N, calculate the publication sequence as `NN = 06 + N` and format it with at least two digits. For example, Wave 1 uses `07`, Wave 7 uses `13`, and Wave 8 uses `14`.
- Use the same numeric prefix for a wave PDF and its matching workbook so they remain adjacent. Include `Plan` in the PDF filename so it sorts before `Resource-Checklist`.
- Keep filenames concise and customer-readable. Use hyphens between words and avoid internal source prefixes such as `04-1-`.
- If optional deliverables are added, assign the next unused sequence number after the final approved wave without renumbering already published artifacts unless the user approves a full-package republish.
- The README document index must use the exact filenames generated for the approved wave set.

## Wave document template

Each wave document should contain, in this order:

1. Title.
2. Sequence.
3. Estimated effort in days, with a specific scope qualifier.
4. Scope.
5. Prerequisites.
6. Design.
7. Inline diagram.
8. Diagram notes.
9. Components.
10. Design review notes with Observation, Recommendation, and Why it matters.
11. Applicable Microsoft program, with green/red PDF highlighting.
12. Wave-specific SKU or scale-up requirements. Include only the before/after change required for that wave; do not repeat unrelated future-wave sizing.
13. Resource checklist reference.

## PDF generation rules

- Convert Markdown to HTML then to PDF with headless Chrome. Extract Mermaid blocks and render them to PNG with the Mermaid CLI first; do not rely on client-side Mermaid rendering in headless Chrome.
- Every generated HTML document must set an explicit `<title>` before conversion, for example `<title>Customer Azure Migration Plan - Wave 3: Arc Re-registration</title>`. Never let the PDF title default to a source filename such as `04-3-wave3-arc-reregistration.html` or `01.html`.
- After conversion, verify the PDF's `/Title` metadata (for example with `pypdf`) matches the intended document title, not a filename, `.md`/`.html` extension, or `None`. Fix any mismatch by rewriting the metadata or regenerating with an explicit title before publishing.
- Use a descriptive title pattern: `<Engagement/Project Name> - <Document Name>` (for example `Customer Azure Migration Plan - README`, `... - Wave 6: Production Data`).
- Use 0.5-inch PDF margins on all sides unless the user requests otherwise.

## Publication rules

- Keep Markdown source files in the working directory unless the user explicitly requests them in the publication folder.
- Publish PDFs and requested workbooks to the requested folder.
- Publish the migration strategy PPTX and presentation PDF unless the user explicitly declined the presentation.
- Remove retired artifacts only after confirming the replacement files exist.
- Verify the final publication folder contains one current artifact per deliverable, no stale conflict copies, no retired `05-diagrams` artifacts, and no obsolete `sku_sheets` folder.
- Do not overwrite unrelated files in the requested destination.
- If Office/IRM protection changes workbook file headers or prevents programmatic reopening, do not treat that as corruption. Preserve the protected workbook and report the limitation.

## Completion gate

Before reporting completion, verify:

- Account and tenant were confirmed.
- Inventory is complete; inaccessible customer-owned dependencies were either inventoried or explicitly excluded with owner-confirmation actions.
- Every deliverable identifies destination-region service, SKU, quota, and capacity availability as unvalidated and includes a mandatory pre-execution validation gate.
- Findings and recommendations were presented.
- Material design decisions were confirmed.
- The final Wave 1 through N count, scope, and sequence were confirmed and any departure from the example wave shape was recorded in the decision log.
- Wave dependencies and parallel paths are internally consistent.
- Every workbook uses the five-column planning SKU schema and clearly identifies its SKU values as unvalidated for the destination.
- Workbook rows are aggregated target allocations, quantities reconcile to the internal source-to-allocation mapping, and platform-generated artifacts are not presented as separately purchased/deployed resources.
- If a presentation was produced, it uses the presentation visual design rules (KPI cards, icon bullets, wave-color badges, native chevron timeline, shaded tables, checkmark decision log, decorative title/closing bands) rather than plain title+bullet slides, and representative slides were rendered and visually spot-checked before publishing.
- Every Markdown deliverable has a corresponding PDF.
- Every PDF has explicit, descriptive `/Title` metadata — not a filename, `.md`/`.html` extension, or blank title.
- Program applicability is stated for every wave.
- Published filenames use the approved zero-padded sequence, and each wave PDF is adjacent to its same-numbered workbook.
- The README document index exactly matches the published filenames.
- Publication was verified and stale/retired artifacts were handled safely.
