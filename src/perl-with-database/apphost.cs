#:package Aspire.Hosting.JavaScript@13.4.0-preview.1.26264.14
#:package Aspire.Hosting.PostgreSQL@13.4.0-preview.1.26264.14
#:package CommunityToolkit.Aspire.Hosting.Perl@13.3.0
#:sdk Aspire.AppHost.Sdk@13.4.0-preview.1.26264.14

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
    .WithPackage("DBD::Pg", force: true, skipTest: true)
    .WithReference(database)
    .WaitFor(database);

var api = builder.AddPerlApi("api", "scripts", "apiService.pl")
    .WithHttpEndpoint(env: "PORT")
    .WithCarton()
    .WithProjectDependencies(cartonDeployment: false)
    .WithLocalLib()
    .WithReference(database)
    .WaitFor(database);

var frontend = builder.AddViteApp("frontend", "./frontend")
    .WithExternalHttpEndpoints()
    .WithReference(api)
    .WaitFor(api);

builder.Build().Run();
