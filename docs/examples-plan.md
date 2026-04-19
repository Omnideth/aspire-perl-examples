# Perl Integration Examples — Plan

This plan enumerates the example apps that will demonstrate every feature of
`CommunityToolkit.Aspire.Hosting.Perl` and show how Perl fits into a broader
Aspire ecosystem alongside common front ends and other resources.

Each example below has a short description here and a detailed implementation
guide in [docs/plan/](./plan/). The detailed guides include exact AppHost
snippets, expected directory layout, cpanfiles, and any known blockers.

## Goals

1. Exercise every public surface of the Perl integration at least once across
   the sample set.
2. Show **both** AppHost authoring styles:
   - **File-based** single-file `apphost.cs` (`#:package` / `#:sdk` directives) for
     small, focused demos.
   - **Classic** multi-project `*.AppHost.csproj` for larger, multi-frontend
     demos where project references and `AddProject<T>` are natural.
3. Pair Perl with a variety of frontends (Blazor, Vite/React, Next.js, Angular,
   Mojolicious server-rendered) to make the point that Perl is just another
   first-class resource in an Aspire graph.
4. Keep everything runnable locally (`aspire run`). Deployment is out of scope
   for this round, but the Dockerfile publisher is still demonstrated as a
   feature of the integration.

## AppHost style rule

| Scope | Style |
|-------|-------|
| Single AppHost + 1–2 Perl resources + one non-project frontend (Vite, Mojolicious, Next.js dev server, Angular dev server) | File-based `apphost.cs` |
| Multi-project Aspire solution (Blazor Web + Blazor ApiService + Perl) | Classic `*.AppHost.csproj` |

## Examples at a glance

| # | Example | AppHost style | Frontend | Primary features |
|---|---------|---------------|----------|------------------|
| 1 | [perl-hello](./plan/perl-hello.md) | file-based | none (CLI) | `AddPerlScript`, default `cpan`, `WithPackage` |
| 2 | [perl-with-database](./plan/perl-with-database.md) *(exists — polish)* | file-based | Vite/React | `AddPerlApi`, `AddPerlScript`, `cpanm`, `WithLocalLib`, `WithReference(postgres)`, OpenTelemetry |
| 3 | [perl-mojolicious-fullstack](./plan/perl-mojolicious-fullstack.md) | file-based | Mojolicious server-rendered | `AddPerlApi`, `WithCarton` + `WithProjectDependencies` + `cartonDeployment`, `cpanfile.snapshot` |
| 4 | [perl-with-blazor](./plan/perl-with-blazor.md) *(retrofit)* | classic AppHost project | Blazor Web + Blazor ApiService (C#) | `AddPerlScript` worker called by ApiService, `cpanm` + `WithProjectDependencies`, `WithReference` |
| 5 | [perl-with-nextjs](./plan/perl-with-nextjs.md) | classic AppHost project | Next.js | `AddPerlApi`, `cpanm` + cpanfile, Postgres `WithReference`, OTel |
| 6 | [perl-with-angular](./plan/perl-with-angular.md) | classic AppHost project | Angular | `AddPerlApi`, Carton deployment mode |
| 7 | [perl-perlbrew-demo](./plan/perl-perlbrew-demo.md) | file-based | none (CLI / tiny API) | `WithPerlbrewEnvironment` (Linux), Berrybrew/Windows notice behavior |
| 8 | [perl-dockerfile-publish](./plan/perl-dockerfile-publish.md) | file-based | none | Dockerfile publisher, certificate trust |

## Feature coverage matrix

Every feature below is demonstrated by at least one example in this set.

| Feature | Example(s) |
|---------|-----------|
| `AddPerlScript` | 1, 2, 4 |
| `AddPerlApi` | 2, 3, 5, 6, 7 |
| Default `cpan` + `WithPackage` | 1 |
| `WithCpanMinus` + `WithPackage` | 2, 4 |
| `WithCpanMinus` + `WithProjectDependencies` (cpanfile) | 4, 5 |
| `WithCarton` + `WithProjectDependencies` | 3, 6 |
| Carton `cartonDeployment: true` (snapshot required) | 3, 6 |
| `WithLocalLib` (relative) | 2, 3, 4, 5, 6 |
| `WithLocalLib` (rooted) — documented variant | 8 |
| `WithPerlbrewEnvironment` (Linux) | 7 |
| Berrybrew / Windows notification documented | 7 |
| Dockerfile publishing | 8 |
| Certificate trust | 8 |
| `WithReference` to non-Perl resources (Postgres, C# API) | 2, 4, 5 |
| OpenTelemetry via `OpenTelemetry::SDK` | 2, 3, 4, 5, 6 |
| `appDirectory = "."` layout | 3, 8 |
| `appDirectory = "scripts"` / sibling layout | 1, 2, 4, 5, 6, 7 |

## Known blockers that affect the plan

These apply across multiple examples and are called out again in each relevant
detailed guide.

- **Duplicate installer resource name collision** —
  [docs/issues/duplicate-resource-installer-name-collision.md](./issues/duplicate-resource-installer-name-collision.md).
  Two resources using identical `.WithPackage("X")` entries can cause installer
  resource name collisions. Any example that adds both a worker and an API
  sharing modules (`OpenTelemetry::SDK`, `DBI`, etc.) must either:
  - prefer a shared `cpanfile` with `WithProjectDependencies()` (preferred), or
  - deliberately split modules so the two resources do not request the exact
    same package set.
- **Perlbrew is Linux-only.** Example 7 documents the Berrybrew/Windows
  notification path but cannot fully exercise a Windows install as part of an
  automated demo.
- **`WithCarton` + `WithPackage` throws.** Examples 3 and 6 must put everything
  in `cpanfile`; a note is included in each guide.

## Conventions used in every example

- AppHost references `CommunityToolkit.Aspire.Hosting.Perl` at the current
  preview version pinned in [aspire.config.json](../aspire.config.json) or the
  classic `.csproj`.
- Perl resources set `WithLocalLib("local")` so installs never touch system
  Perl, except where the example is specifically demonstrating a non-local
  install.
- Where OpenTelemetry is demonstrated, scripts load `OpenTelemetry::SDK` and
  emit at least one span so the Aspire dashboard traces view is non-empty.
- Each example README includes a **Run** section (`aspire run`) and a
  **Features demonstrated** section that links back to this plan.

## Implementation order

Suggested order so each step unblocks the next:

1. Example 1 (`perl-hello`) — smallest surface, validates defaults.
2. Example 2 (`perl-with-database`) — already exists; polish + document.
3. Example 3 (`perl-mojolicious-fullstack`) — establishes Carton pattern.
4. Example 4 (`perl-with-blazor`) — establishes classic AppHost pattern.
5. Examples 5 and 6 — reuse patterns from 3 and 4 with different frontends.
6. Example 7 (`perl-perlbrew-demo`) — Linux-only path, standalone.
7. Example 8 (`perl-dockerfile-publish`) — publisher + cert trust, standalone.
