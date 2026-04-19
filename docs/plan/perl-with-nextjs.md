# Example 5 — perl-with-nextjs

Next.js frontend backed by a Perl (Mojolicious) API, with Postgres for
persistence. Multi-project classic AppHost so the Perl integration lives
alongside a real `.csproj`.

## Goal

Show a modern JS SSR framework (Next.js) composing cleanly with a Perl API in
the Aspire graph, using `cpanm` + `cpanfile` for dependency management.

## AppHost style

Classic `PerlNext.AppHost.csproj`.

## Proposed layout

```
src/perl-with-nextjs/
├── PerlNext.sln
├── PerlNext.AppHost/
│   ├── AppHost.cs
│   ├── PerlNext.AppHost.csproj   ← PackageReference to Aspire.Hosting.NodeJs
│   │                                and CommunityToolkit.Aspire.Hosting.Perl
│   └── scripts/
│       ├── apiService.pl         ← Mojolicious daemon
│       └── cpanfile
├── PerlNext.ServiceDefaults/
└── frontend/                     ← Next.js app (pages or app router)
    ├── package.json
    └── ...
```

## AppHost.cs

```csharp
var builder = DistributedApplication.CreateBuilder(args);

var db = builder.AddPostgres("pg").AddDatabase("appdb");

var api = builder.AddPerlApi("api", "scripts", "apiService.pl")
    .WithCpanMinus()
    .WithLocalLib("local")
    .WithProjectDependencies()
    .WithReference(db)
    .WaitFor(db);

builder.AddNpmApp("web", "../frontend", "dev")
    .WithHttpEndpoint(env: "PORT")
    .WithExternalHttpEndpoints()
    .WithReference(api)
    .WaitFor(api);

builder.Build().Run();
```

## scripts/cpanfile

```perl
requires 'Mojolicious', '>= 9.0';
requires 'OpenTelemetry::SDK';
requires 'DBI';
requires 'DBD::Pg';
```

## Features demonstrated

- Classic multi-project AppHost
- `AddPerlApi` + Mojolicious
- `WithCpanMinus` + `WithProjectDependencies`
- `WithLocalLib`
- `WithReference(postgres)`
- OpenTelemetry
- Next.js front end via `AddNpmApp`

## Blockers / problems

- **Next.js dev server and port env var.** `AddNpmApp(..., "dev")` requires
  the Next.js `dev` script to honor `PORT`. Either set
  `"dev": "next dev -p $PORT"` in `package.json` or use `cross-env` so it
  works on Windows. Call out in README.
- **API base URL in Next.js.** The frontend must read the API URL from
  `services__api__http__0` (injected env) rather than hardcoding. Use a
  small `lib/config.ts` to centralize that lookup.
- **Postgres driver compile time.** `DBD::Pg` compiles against libpq. On
  Linux, document `apt install libpq-dev` (or equivalent) as a prerequisite.

## Verification

1. `cd src/perl-with-nextjs && aspire run`.
2. Dashboard shows `pg`, `appdb`, `api`, `web` healthy.
3. Opening the Next.js URL renders a page driven by the Perl API.
