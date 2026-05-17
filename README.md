# Aspire Perl Examples

This repository collects practical examples for using Perl resources inside Aspire application graphs. The goal is to show a few different integration shapes, keep the samples approachable, and document the rough edges we have hit while building them.

The current repo includes runnable examples today, plus planning docs for additional scenarios we want to add next.

## Windows Support

I will try and maintain parity between windows and linux over time, but the perl ecosystem is largely linux first now, so the priority is Linux first.

If one of these doesn't work and you're on Windows, you can use the provided dev container to run the samples in the repo.

## Current examples

### `perl-hello`

Minimal file-based AppHost example for wiring a Perl script into Aspire. This is the smallest sample in the repo and the easiest place to validate package installation behavior and basic script execution.

### `perl-with-database`

Full-stack file-based example with a Perl API and worker service, a database-backed workflow, and a Vite/React frontend. This sample is the main reference for Perl plus frontend plus data-service integration in a lightweight AppHost shape.

### `perl-with-blazor`

Multi-project Aspire solution that pairs Perl with a Blazor web application and supporting C# services. This is the current example for the more traditional AppHost project layout when the app graph includes richer .NET project structure.

## Planned example types

The broader sample roadmap lives in [docs/examples-plan.md](docs/examples-plan.md). Planned scenarios currently include:

- Mojolicious full-stack app
- Next.js frontend with Perl backend
- Angular frontend with Perl backend
- Perlbrew environment demo
- Dockerfile publishing example

## Known issues

- [Windows CPAN installer HTTPS failure](docs/issues/cpan-installer-windows-https-failure.md): on Windows, the default `cpan` installer path can fail under Aspire installer resources during HTTPS fetches even though the same Perl install works from a normal shell and from a trivial wrapper.
- [Duplicate installer resource name collision](docs/issues/duplicate-resource-installer-name-collision.md): two resources that use the same `.WithPackage()` dependency can generate colliding installer resource names and prevent the AppHost from starting.