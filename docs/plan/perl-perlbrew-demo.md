# Example 7 — perl-perlbrew-demo

Demonstrates `WithPerlbrewEnvironment` on Linux and documents the Windows /
Berrybrew notification behavior.

## Goal

Show that Perl resources can target a specific perlbrew-managed Perl (e.g.,
`perl-5.42.0`) independent of the system Perl, and document what happens on
Windows where Berrybrew is not yet automated.

## AppHost style

File-based single-file `apphost.cs`.

## Proposed layout

```
src/perl-perlbrew-demo/
├── apphost.cs
├── apphost.run.json
├── nuget.config
└── scripts/
    └── versionReport.pl
```

## Prerequisites

- Linux with perlbrew installed and at least one named Perl available:
  ```bash
  curl -L https://install.perlbrew.pl | bash
  perlbrew install perl-5.42.0
  perlbrew install-cpanm
  ```

## AppHost snippet

```csharp
#:package CommunityToolkit.Aspire.Hosting.Perl@<pinned-preview>
#:sdk Aspire.AppHost.Sdk@<pinned-preview>

using Aspire.Hosting;

var builder = DistributedApplication.CreateBuilder(args);

builder.AddPerlScript("version-report", "scripts", "versionReport.pl")
    .WithPerlbrewEnvironment("perl-5.42.0")
    .WithCpanMinus()
    .WithLocalLib("local")
    .WithPackage("JSON::PP");

builder.Build().Run();
```

## scripts/versionReport.pl

```perl
use strict;
use warnings;
use Config;
use JSON::PP;
print encode_json({
    perl_version => $^V,
    archname     => $Config{archname},
    perlbrew     => $ENV{PERLBREW_PERL},
    perl5lib     => $ENV{PERL5LIB},
}), "\n";
sleep 3600;
```

## Features demonstrated

- `WithPerlbrewEnvironment` (Linux)
- Combining perlbrew with `WithLocalLib` for per-project isolation
- `PERLBREW_ROOT`, `PERLBREW_PERL`, `PERLBREW_HOME`, `PATH` configuration
- Berrybrew / Windows notification path (documented, not code-driven)

## Blockers / problems

- **Linux-only.** On Windows the integration emits a notification recommending
  Berrybrew; there is no automated Windows path yet. The example README must
  state this up front and link to
  [../perl-integration-docs.md](../perl-integration-docs.md) *→
  WithPerlbrewEnvironment*.
- **Named Perl must already exist.** `WithPerlbrewEnvironment("perl-5.42.0")`
  does not install the Perl; users must `perlbrew install perl-5.42.0` first.
- **cpanm via perlbrew.** If `perlbrew install-cpanm` was skipped, `cpanm`
  will not be on `PATH` under that Perl. README lists this as a prereq.

## Verification

1. `perlbrew list` shows `perl-5.42.0`.
2. `aspire run` from `src/perl-perlbrew-demo/`.
3. Dashboard shows `version-report` healthy and its log contains a JSON line
   where `perl_version` matches `perl-5.42.0` and `PERLBREW_PERL` is set.
