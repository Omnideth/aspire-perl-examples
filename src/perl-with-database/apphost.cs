#:package Aspire.Hosting.JavaScript@13.4.0-preview.1.26259.2
#:package Aspire.Hosting.PostgreSQL@13.4.0-preview.1.26259.2
#:package CommunityToolkit.Aspire.Hosting.Perl@13.1.2-dev.260315-1626
#:sdk Aspire.AppHost.Sdk@13.4.0-preview.1.26259.2

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

var api = builder.AddPerlApi("api", "scripts", "apiService.pl")
    .WithHttpEndpoint(env: "PORT")
    .WithCpanMinus()
    .WithLocalLib()
    .WithPackage("OpenTelemetry::SDK", force: true, skipTest: true)
    .WithPackage("Mojolicious")
    .WithPackage("DBI")
    .WithPackage("DBD::Pg")
    .WithReference(database)
    .WaitFor(database);

var frontend = builder.AddViteApp("frontend", "./frontend")
    .WithExternalHttpEndpoints()
    .WithReference(api)
    .WaitFor(api);

builder.Build().Run();
