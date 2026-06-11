using Aspire.Hosting;

var builder = DistributedApplication.CreateBuilder(args);

var api = builder.AddPerlApi("api", ".", "../scripts/apiService.pl")
    .WithHttpEndpoint(env: "PORT")
    .WithCarton()
    .WithProjectDependencies(cartonDeployment: true)
    .WithLocalLib("local");

if (OperatingSystem.IsWindows())
{
    // Keep the Windows host path runnable without requiring Alien::ProtoBuf or live OTLP export.
    api.WithEnvironment("OTEL_EXPORTER_OTLP_PROTOCOL", "http/json")
        .WithEnvironment("OTEL_PERL_EXPORTER_OTLP_PROTOCOL", "http/json")
        .WithEnvironment("OTEL_LOGS_EXPORTER", "none")
        .WithEnvironment("OTEL_METRICS_EXPORTER", "none")
        .WithEnvironment("OTEL_PERL_LOGS_EXPORTER", "none")
        .WithEnvironment("OTEL_PERL_METRICS_EXPORTER", "none")
        .WithEnvironment("OTEL_TRACES_EXPORTER", "none")
        .WithEnvironment("OTEL_PERL_TRACES_EXPORTER", "none");
}

api.WithHttpHealthCheck("/health");

builder.AddJavaScriptApp("web", "../frontend", "start")
    .WithHttpEndpoint(env: "PORT")
    .WithExternalHttpEndpoints()
    .WithReference(api)
    .WaitFor(api);

builder.Build().Run();