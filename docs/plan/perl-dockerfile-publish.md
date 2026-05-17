# Example 8 — perl-dockerfile-publish

Demonstrates the Dockerfile publishing path for a Perl resource and the
certificate trust annotation, without leaving the local dev experience.

## Goal

Show that a Perl resource can emit a Dockerfile-based publish manifest (for
use by container runtimes or downstream deployment tooling) and can be
configured to trust a custom CA bundle — both without requiring an actual
cloud deployment.

## AppHost style

File-based single-file `apphost.cs`.

## Proposed layout

```
src/perl-dockerfile-publish/
├── apphost.cs
├── apphost.run.json
├── nuget.config
├── certs/
│   └── corp-root-ca.pem         ← example custom CA (self-signed for demo)
└── app/
    ├── apiService.pl
    └── cpanfile
```

## AppHost snippet

```csharp
#:package CommunityToolkit.Aspire.Hosting.Perl@<pinned-preview>
#:sdk Aspire.AppHost.Sdk@<pinned-preview>

using Aspire.Hosting;

var builder = DistributedApplication.CreateBuilder(args);

var api = builder.AddPerlApi("api", "app", "apiService.pl")
    .WithCpanMinus()
    .WithLocalLib("local")
    .WithProjectDependencies()
    .WithCertificateTrust("../certs/corp-root-ca.pem") // trust a custom CA
    .PublishAsDockerFile();                             // emit Dockerfile on publish

builder.Build().Run();
```

> The exact extension-method names (`WithCertificateTrust`,
> `PublishAsDockerFile`) should match what the integration exposes in
> [`PerlAppResourceBuilderExtensions.Dockerfile.cs`](../../../CommunityToolkit.Aspire.Hosting.Perl/src/CommunityToolkit.Aspire.Hosting.Perl/PerlAppResourceBuilderExtensions.Dockerfile.cs)
> and the `PerlCertificateTrustAnnotation`. Before landing the example, open
> those files and align the method names/signatures.

## app/cpanfile

```perl
requires 'Mojolicious', '>= 9.0';
requires 'IO::Socket::SSL';
requires 'LWP::UserAgent';
requires 'Mozilla::CA';
```

## Features demonstrated

- `PublishAsDockerFile` (Dockerfile publisher for Perl resources)
- Certificate trust annotation (`WithCertificateTrust` or equivalent)
- `WithLocalLib` with a rooted path variant *(documented alternative)*:
  ```csharp
  .WithLocalLib("/opt/perl-libs") // absolute — used verbatim
  ```
- `appDirectory` sibling layout (`"app"`)

## Blockers / problems

- **Extension-method name mismatch.** The public API names for certificate
  trust and Dockerfile publishing may differ from the placeholders above.
  Verify against the source before finalizing the example; update this plan
  if the public names differ.
- **Local-only scope.** Per the overall plan, no `azd`/Azure deployment is
  included. The example stops at emitting artifacts; do not add
  `azd init`/`azd up` steps.
- **Custom CA file is demo-only.** The `certs/corp-root-ca.pem` checked into
  the repo must be a clearly-labeled self-signed demo cert with a wide
  comment in the example README explaining that it is not a production CA.
- **Rooted `WithLocalLib` paths** are OS-specific. Show the Linux example
  in-repo and mention the Windows form (`C:\perl-libs`) in a comment only.

## Verification

1. `aspire run` works as a plain local API (no publish).
2. Running the Aspire publish command for the AppHost produces a Dockerfile
   and related artifacts for the `api` resource in the publish output
   directory.
3. The generated Dockerfile installs dependencies from `cpanfile` and copies
   the trusted CA into the image's trust store.
