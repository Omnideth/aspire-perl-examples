var builder = DistributedApplication.CreateBuilder(args);

var apiService = builder.AddPerlApi("apiservice", "../scripts", "weatherApi.pl")
    .WithHttpEndpoint(env: "PORT")
    .WithCpanMinus()
    .WithProjectDependencies()
    .WithLocalLib("local")
    .WithHttpHealthCheck("/health");

builder.AddProject<Projects.PerlBlazor_Web>("webfrontend")
    .WithExternalHttpEndpoints()
    .WithHttpHealthCheck("/health")
    .WithReference(apiService)
    .WaitFor(apiService);

builder.Build().Run();
