#:package Aspire.Hosting.PostgreSQL@13.3.0-preview.1.26163.4
#:sdk Aspire.AppHost.Sdk@13.2.0-preview.1.26163.12
#:project ../../../CommunityToolkit.Aspire.Hosting.Perl/src/CommunityToolkit.Aspire.Hosting.Perl

var builder = DistributedApplication.CreateBuilder(args);

builder.Build().Run();
