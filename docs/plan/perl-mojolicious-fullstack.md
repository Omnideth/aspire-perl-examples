# Example 3 — perl-mojolicious-fullstack

Perl-only web stack: Mojolicious API **and** Mojolicious-rendered HTML
frontend, dependencies managed with Carton for reproducible installs.

## Goal

Demonstrate that Perl can own the full request path (server-rendered UI) while
still being a citizen of the Aspire graph, and that Carton + `cpanfile.snapshot`
provides deterministic installs.

## AppHost style

File-based single-file `apphost.cs`.

## Proposed layout

```
src/perl-mojolicious-fullstack/
├── apphost.cs
├── apphost.run.json
├── nuget.config
├── cpanfile                ← at AppHost root because appDirectory = "."
├── cpanfile.snapshot       ← committed; required for cartonDeployment: true
├── local/                  ← populated on first run (gitignored)
└── app/
    ├── web.pl              ← Mojolicious::Lite app with routes + templates
    └── templates/
        └── index.html.ep
```

> `appDirectory = "."` is chosen so Carton's `cpanfile`/`local/` live next to
> the AppHost, matching Carton's usual workflow.

## AppHost snippet

```csharp
#:package CommunityToolkit.Aspire.Hosting.Perl@<pinned-preview>
#:sdk Aspire.AppHost.Sdk@<pinned-preview>

using Aspire.Hosting;

var builder = DistributedApplication.CreateBuilder(args);

builder.AddPerlApi("web", ".", "app/web.pl")
    .WithCarton()
    .WithProjectDependencies(cartonDeployment: true)
    .WithLocalLib("local");

builder.Build().Run();
```

## cpanfile

```perl
requires 'Mojolicious', '>= 9.0';
requires 'OpenTelemetry::SDK';
```

## Features demonstrated

- `AddPerlApi`
- `WithCarton` + `WithProjectDependencies(cartonDeployment: true)`
- `cpanfile.snapshot` committed for reproducible installs
- `WithLocalLib` with `appDirectory = "."` layout
- Perl serving HTML directly (no JS framework required)
- OpenTelemetry

## Blockers / problems

- **Snapshot must be generated and committed** before `cartonDeployment: true`
  works. First-time authoring needs one of:
  - `carton install` locally (produces `cpanfile.snapshot`), then commit, or
  - switch to `cartonDeployment: false` for the initial run, generate the
    snapshot, then switch back.
  Call this out in the README.
- **`WithCarton` + `WithPackage` throws.** Any additional module must be added
  to `cpanfile`; cannot be chained as `.WithPackage(...)`.
- **`appDirectory = "."`** means the AppHost root contains `cpanfile`,
  `cpanfile.snapshot`, and a generated `local/` folder. Ensure `.gitignore`
  excludes `local/`.

## Verification

1. One-time bootstrap if `cpanfile.snapshot` is absent: temporarily set
   `cartonDeployment: false`, run, then commit `cpanfile.snapshot`.
2. `aspire run` from `src/perl-mojolicious-fullstack/`.
3. `web` resource healthy; opening its URL returns server-rendered HTML.
4. Dashboard Traces view shows at least one span from `web`.
