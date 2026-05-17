# Example 6 — perl-with-angular

Angular SPA served by its dev server, backed by a Perl API whose dependencies
are pinned with Carton + `cpanfile.snapshot`.

## Goal

Show Angular + Aspire + Perl and exercise Carton's deployment mode in a
classic multi-project AppHost.

## AppHost style

Classic `PerlAngular.AppHost.csproj`.

## Proposed layout

```
src/perl-with-angular/
├── PerlAngular.sln
├── PerlAngular.AppHost/
│   ├── AppHost.cs
│   ├── PerlAngular.AppHost.csproj
│   ├── cpanfile                 ← appDirectory = "." → lives next to csproj
│   ├── cpanfile.snapshot        ← committed
│   └── local/                   ← gitignored
├── PerlAngular.ServiceDefaults/
├── scripts/
│   └── apiService.pl            ← referenced as "../scripts/apiService.pl"
└── frontend/                    ← Angular CLI app
    ├── package.json
    └── angular.json
```

## AppHost.cs

```csharp
var builder = DistributedApplication.CreateBuilder(args);

var api = builder.AddPerlApi("api", ".", "../scripts/apiService.pl")
    .WithCarton()
    .WithProjectDependencies(cartonDeployment: true)
    .WithLocalLib("local");

builder.AddNpmApp("web", "../frontend", "start")
    .WithHttpEndpoint(env: "PORT")
    .WithExternalHttpEndpoints()
    .WithReference(api)
    .WaitFor(api);

builder.Build().Run();
```

## cpanfile (next to the AppHost csproj)

```perl
requires 'Mojolicious', '>= 9.0';
requires 'OpenTelemetry::SDK';
```

## Features demonstrated

- Classic multi-project AppHost + SPA frontend
- `AddPerlApi` with `appDirectory = "."` and a script path that steps up to a
  sibling `scripts/` folder
- `WithCarton` + `WithProjectDependencies(cartonDeployment: true)`
- Committed `cpanfile.snapshot`
- `WithLocalLib` resolved at the AppHost root
- Angular CLI via `AddNpmApp`

## Blockers / problems

- **Snapshot bootstrap** (same as Example 3): generate with a one-time
  `cartonDeployment: false` run or a manual `carton install`, then commit.
- **Angular CLI and the `PORT` env.** `ng serve` does not honor `$PORT` by
  default. Either expose a `start` script that invokes
  `ng serve --host 0.0.0.0 --port $PORT` (via `cross-env`) or set
  `--port` from a small wrapper script. Document in the example README.
- **Carton + `WithPackage` is forbidden.** Any additional module goes in
  `cpanfile`.
- **`appDirectory = "."`** places `local/` and snapshot files next to the
  AppHost csproj; update `.gitignore` accordingly.

## Verification

1. Ensure `cpanfile.snapshot` exists (one-time bootstrap if needed).
2. `cd src/perl-with-angular && aspire run`.
3. Dashboard shows `api` and `web` healthy; Angular app loads and makes calls
   against `api`.
