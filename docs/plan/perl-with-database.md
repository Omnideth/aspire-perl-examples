# Example 2 — perl-with-database (polish existing)

The existing [src/perl-with-database](../../src/perl-with-database/) sample
already demonstrates a Vite/React frontend calling a Mojolicious Perl API, with
a Perl worker consuming Postgres. This guide describes the polish needed to
make it a canonical example.

## Goal

Showcase Perl as both an HTTP API (`AddPerlApi`) and a background worker
(`AddPerlScript`) participating with a Postgres database and a JS frontend.

## AppHost style

File-based single-file `apphost.cs` (already in use).

## Current AppHost (reference)

See [src/perl-with-database/apphost.cs](../../src/perl-with-database/apphost.cs).

## Changes to make

1. **Resolve duplicate `WithPackage` between `worker` and `api`.**
   Both resources currently call `.WithPackage("OpenTelemetry::SDK")`, which
   can trip
   [duplicate-resource-installer-name-collision](../issues/duplicate-resource-installer-name-collision.md).
   Replace the per-package listing with a shared `cpanfile` under `scripts/`
   plus `.WithProjectDependencies()`:

   ```csharp
   var worker = builder.AddPerlScript("worker", "scripts", "workerService.pl")
       .WithCpanMinus()
       .WithLocalLib()
       .WithProjectDependencies()
       .WithReference(database)
       .WaitFor(database);

   var api = builder.AddPerlApi("api", "scripts", "apiService.pl")
       .WithCpanMinus()
       .WithLocalLib()
       .WithProjectDependencies()
       .WithReference(database)
       .WaitFor(database);
   ```

   `scripts/cpanfile`:

   ```perl
   requires 'OpenTelemetry::SDK';
   requires 'Mojolicious';
   requires 'DBI';
   requires 'DBD::Pg';
   ```

2. **Ensure both Perl scripts emit at least one OTel span** on startup so the
   dashboard Traces view has content.
3. **Add a README.md** under `src/perl-with-database/` with: what is
   demonstrated, required tools (Perl ≥ 5.38, cpanm, node), run steps.
4. **Link back to [../examples-plan.md](../examples-plan.md).**

## Features demonstrated

- `AddPerlApi` (Mojolicious daemon)
- `AddPerlScript` (background worker)
- `WithCpanMinus` + `WithProjectDependencies` (shared cpanfile)
- `WithLocalLib`
- `WithReference(postgres)` + `WaitFor`
- OpenTelemetry via `OpenTelemetry::SDK`
- Vite/React frontend via `AddViteApp`
- `appDirectory = "scripts"` sibling layout

## Blockers / problems

- **Installer name collision** when both resources list the same
  `.WithPackage(...)` — mitigated by switching to `WithProjectDependencies()`.
- **First-run install time.** `cpanm` on a fresh machine compiling `DBD::Pg`
  and Mojolicious pulls native deps; call this out in the README so users
  don't think the AppHost is stuck.
- **Vite dev server port.** `AddViteApp` picks a port; verify the React app
  reads the API endpoint from the injected `services__api__http__0` env var
  rather than hardcoding.

## Verification

1. `cd src/perl-with-database && aspire run`.
2. Dashboard shows `server`, `postgres`, `worker`, `api`, `frontend` all healthy.
3. Opening the frontend URL shows data fetched from the Perl API.
4. Traces view shows spans from both the Perl API and worker.
