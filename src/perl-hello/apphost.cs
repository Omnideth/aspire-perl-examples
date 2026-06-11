#:package CommunityToolkit.Aspire.Hosting.Perl@13.3.0
#:sdk Aspire.AppHost.Sdk@13.4.0-preview.1.26264.14

using Aspire.Hosting;

var builder = DistributedApplication.CreateBuilder(args);

var script = builder.AddPerlScript("script", "scripts", "hello.pl")
    .WithCpanMinus()
    .WithLocalLib()
    .WithPackage("JSON::PP");

builder.Build().Run();