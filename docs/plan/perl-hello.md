# Example 1 — perl-hello

Minimal file-based AppHost that runs a single Perl script using default `cpan`
package management. Establishes that "zero-frontend" Perl works.

## Goal

Show the smallest viable Perl + Aspire graph: one `AddPerlScript`, default
`cpan` package manager, one `WithPackage` call, no local::lib, no frontend.

## AppHost style

File-based single-file `apphost.cs`.

## Proposed layout

```
src/perl-hello/
├── apphost.cs
├── apphost.run.json
├── nuget.config
└── scripts/
    └── hello.pl
```

## AppHost snippet

```csharp
#:package CommunityToolkit.Aspire.Hosting.Perl@<pinned-preview>
#:sdk Aspire.AppHost.Sdk@<pinned-preview>

using Aspire.Hosting;

var builder = DistributedApplication.CreateBuilder(args);

builder.AddPerlScript("hello", "scripts", "hello.pl")
    .WithPackage("JSON::PP"); // default cpan path — no WithCpanMinus / no WithLocalLib

builder.Build().Run();
```

## scripts/hello.pl

```perl
use strict;
use warnings;
use JSON::PP;
print encode_json({ message => "hello from perl", pid => $$ }), "\n";
sleep 3600; # keep the resource alive so it appears in the dashboard
```

## Features demonstrated

- `AddPerlScript`
- Default `cpan` package manager (no `WithCpanMinus`)
- `WithPackage` (single module)
- `appDirectory = "scripts"` sibling layout

## Blockers / problems

- **System Perl writes.** Because this example intentionally omits
  `WithLocalLib`, the default `cpan` install path may write to the system/user
  Perl install and on some Linux distros may require elevation. This is
  called out in the example README as the cost of a "bare defaults" demo and
  is documented in [../perl-integration-docs.md](../perl-integration-docs.md)
  under *Common Pitfalls → Choosing to skip WithLocalLib*.
- `cpan` does not support `--installdeps`, so this example cannot add a
  cpanfile without auto-switching to cpanm. Keep it to `WithPackage` only.

## Verification

1. `cd src/perl-hello && aspire run`.
2. Dashboard shows resource `hello` in running state after installer completes.
3. Console output includes the JSON line from `hello.pl`.
