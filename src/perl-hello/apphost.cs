#:package CommunityToolkit.Aspire.Hosting.Perl@13.1.2-dev.260315-1626
#:sdk Aspire.AppHost.Sdk@13.2.0-preview.1.26163.12

using Aspire.Hosting;

var builder = DistributedApplication.CreateBuilder(args);

// Smallest viable Perl + Aspire graph:
// - AddPerlScript with appDirectory = "scripts" (sibling folder)
// - Default `cpan` package manager (no WithCpanMinus)
// - A single WithPackage call
// - Intentionally no WithLocalLib — this demo runs against the system/user Perl
//   install. That is the cost of "bare defaults"; see ../../docs/perl-integration-docs.md
//   (Common Pitfalls → Choosing to skip WithLocalLib).
builder.AddPerlScript("hello", "scripts", "hello.pl")
    .WithPackage("JSON::PP");

builder.Build().Run();
