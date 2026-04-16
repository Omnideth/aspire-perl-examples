var builder = DistributedApplication.CreateBuilder(args);

var api = builder.AddPerlApi("apiservice", "scripts", "weatherApi.pl")
    .WithCpanMinus()
    .WithLocalLib()
    .WithPackage("Mojolicious")
    .WithHttpHealthCheck("/health");

builder.AddProject<Projects.PerlBlazor_Web>("webfrontend")
    .WithExternalHttpEndpoints()
    .WithHttpHealthCheck("/health")
    .WithReference(api)
    .WaitFor(api);

builder.Build().Run();
