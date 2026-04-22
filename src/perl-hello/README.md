# perl-hello

The smallest viable Perl + Aspire graph: a single `AddPerlScript` resource
using the default `cpan` package manager, one `WithPackage` call, and no
frontend.

This example corresponds to Example 1 in
[../../docs/examples-plan.md](../../docs/examples-plan.md) — see
[../../docs/plan/perl-hello.md](../../docs/plan/perl-hello.md) for the
detailed plan and rationale.

## Features demonstrated

- `AddPerlScript`
- Default `cpan` package manager (no `WithCpanMinus`)
- `WithPackage` (single module — `JSON::PP`)
- `appDirectory = "scripts"` sibling-folder layout

## Prerequisites

- .NET 10 SDK
- [Aspire CLI](https://learn.microsoft.com/dotnet/aspire/) (`aspire`)
- A working Perl install on `PATH` (any recent Perl 5.x)
- `cpan` available on `PATH` (ships with most Perl distributions)

> **Heads up:** This example intentionally omits `WithLocalLib`, so the
> default `cpan` install path writes into your system / user Perl tree.
> On some Linux distributions that may require elevated permissions. See
> [../../docs/perl-integration-docs.md](../../docs/perl-integration-docs.md)
> → *Common Pitfalls → Choosing to skip WithLocalLib*.

## Run

```bash
cd src/perl-hello
aspire run
```

## What to look for

1. Dashboard opens and shows the `hello` resource.
2. An installer child resource runs `cpan JSON::PP` (first run only).
3. After install completes, `hello` transitions to Running.
4. The `hello` resource console log contains a JSON line similar to:

   ```json
   {"message":"hello from perl","pid":12345,"perl":"5.38.2"}
   ```

5. The resource stays alive (the script sleeps) so it remains visible in the
   dashboard — stop it with `Ctrl+C` on the `aspire run` terminal.
