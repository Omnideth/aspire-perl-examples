#:package Aspire.Hosting.PostgreSQL@13.3.0-preview.1.26163.4
#:package CommunityToolkit.Aspire.Hosting.Perl@13.1.2-dev
#:sdk Aspire.AppHost.Sdk@13.2.0-preview.1.26163.12

using Aspire.Hosting;

var builder = DistributedApplication.CreateBuilder(args);

var server = builder.AddPostgres("server")
    .WithInitFiles("./migrations");

var database = server.AddDatabase("postgres");

var worker = builder.AddPerlScript("worker", "scripts", "workerService.pl")
    .WithCpanMinus()
    .WithLocalLib()
    .WithPackage("OpenTelemetry::SDK")
    .WithPackage("DBI")
    .WithPackage("DBD::Pg")
    .WithReference(database)
    .WaitFor(database);

builder.Build().Run();
