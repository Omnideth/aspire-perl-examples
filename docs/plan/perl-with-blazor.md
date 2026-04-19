# Example 4 — perl-with-blazor (retrofit)

The existing [src/perl-with-blazor](../../src/perl-with-blazor/) solution is a
textbook Aspire starter (Blazor Web + Blazor ApiService + ServiceDefaults) but
currently contains **no Perl resource**. This guide retrofits Perl into it so
the classic multi-project AppHost style is demonstrated alongside Perl.

## Goal

Show a canonical multi-project Aspire solution — the kind produced by
`dotnet new aspire-starter` — with a Perl worker participating in the graph
and being referenced from the C# ApiService.

## AppHost style

Classic `PerlBlazor.AppHost.csproj` (already present).

## Shape of the retrofit

```
src/perl-with-blazor/
├── PerlBlazor.sln
├── PerlBlazor.AppHost/
│   ├── AppHost.cs                 ← updated (see below)
│   ├── PerlBlazor.AppHost.csproj  ← add PackageReference to CommunityToolkit.Aspire.Hosting.Perl
│   └── scripts/                   ← NEW
│       ├── reportWorker.pl
│       └── cpanfile
├── PerlBlazor.ApiService/         ← consumes the Perl worker's output
│   └── Program.cs                 ← reads services__perl-worker__http__0 if exposed,
│                                     or reads shared resource (e.g., a file/queue/db)
├── PerlBlazor.Web/                ← unchanged Blazor frontend
└── PerlBlazor.ServiceDefaults/    ← unchanged
```

## AppHost.cs (updated)

```csharp
var builder = DistributedApplication.CreateBuilder(args);

var perlWorker = builder.AddPerlScript("perl-worker", "scripts", "reportWorker.pl")
    .WithCpanMinus()
    .WithLocalLib("local")
    .WithProjectDependencies();

var apiService = builder.AddProject<Projects.PerlBlazor_ApiService>("apiservice")
    .WithHttpHealthCheck("/health")
    .WithReference(perlWorker) // expose perl-worker env/endpoint info to the C# ApiService
    .WaitFor(perlWorker);

builder.AddProject<Projects.PerlBlazor_Web>("webfrontend")
    .WithExternalHttpEndpoints()
    .WithHttpHealthCheck("/health")
    .WithReference(apiService)
    .WaitFor(apiService);

builder.Build().Run();
```

## scripts/cpanfile

```perl
requires 'OpenTelemetry::SDK';
requires 'JSON::PP';
```

## Features demonstrated

- Classic multi-project AppHost (`AddProject<T>`) alongside Perl
- `AddPerlScript` in a multi-project solution
- `WithCpanMinus` + `WithProjectDependencies`
- `WithLocalLib`
- `WithReference` from a C# project onto a Perl resource (and vice-versa if
  the Perl worker needs the ApiService URL — invert the `WithReference` in
  that case)
- OpenTelemetry from Perl into the Aspire dashboard

## Blockers / problems

- **Choosing the collaboration shape between C# and Perl.** Aspire's
  `WithReference` on a non-HTTP resource injects environment variables, not a
  network endpoint. For this example, pick one shape and stick with it:
  - *Option A (recommended):* Perl worker writes output to a shared resource
    (e.g., a file path or queue) that the C# ApiService reads. Keeps the
    example simple.
  - *Option B:* Promote the worker to `AddPerlApi` so it exposes HTTP, then
    `WithReference` gives the ApiService a real URL. Slightly more moving
    parts but a stronger "Perl as a peer service" story.
  The guide defaults to Option A; note Option B inline in the example README.
- **Package reference version drift.** The classic AppHost `.csproj` must
  pin the same Perl integration preview version used elsewhere in the repo.
  Ensure CI uses the repo-level `aspire.config.json` feed.
- **No duplicate `WithPackage` across Perl resources** — trivially satisfied
  here because there is only one Perl resource.

## Verification

1. `cd src/perl-with-blazor && aspire run`.
2. Dashboard shows `perl-worker`, `apiservice`, `webfrontend` all healthy.
3. The Blazor frontend renders data originating from the Perl worker through
   the ApiService.
4. Dashboard Traces view shows spans from both `apiservice` and `perl-worker`.
