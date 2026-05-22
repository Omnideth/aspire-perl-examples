# Aspire Perl Examples

This repository showcases examples for using Perl in Aspire. The goal is to show a few different integration shapes and keep the samples simple but showing real use scenarios.

The current repo includes runnable examples today, plus planning docs for additional scenarios we want to add next.

I am not an expert in Perl, but I know most people haven't used it much at all.  I'm trying to put things together to help people visualize using it, so be nice.

## Windows Support

I try to maintain parity between windows and linux over time, but the perl ecosystem is largely linux first now, so the priority is Linux first.

If one of these doesn't work and you're on Windows, you can use the provided dev container to run the samples in the repo, or you can open an issue and I can see if it's resolvable.

## Current examples

### `perl-hello`

Minimal file-based AppHost example for wiring a Perl script into Aspire. This is the smallest sample in the repo and the easiest place to validate package installation behavior and basic apphost shape for adding something in Perl.

### `perl-with-database`

Full-stack file-based example with a Perl API and worker service, a database-backed workflow, and a Vite frontend. This sample is the main reference for Perl plus frontend plus data-service integration in a lightweight AppHost shape.

### `perl-with-blazor`

Multi-project Aspire solution that pairs Perl with a Blazor web application and supporting C# services. This is to highlight just that it can be a backend exclusively if you want, and just stole the /weatherforecast behavior from the blazor template as a shortcut to something familiar.

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