using Aspire.Hosting;

var builder = DistributedApplication.CreateBuilder(args);

var postgres = builder.AddPostgres("pg");
var database = postgres.AddDatabase("appdb");

var api = builder.AddPerlApi("api", "scripts", "apiService.pl")
    .WithHttpEndpoint(env: "PORT")
    .WithCpanMinus()
    .WithLocalLib("local")
    .WithProjectDependencies()
    .WithReference(database)
    .WaitFor(database);

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

builder.AddJavaScriptApp("web", "../frontend", "dev")
    .WithHttpEndpoint(env: "PORT")
    .WithExternalHttpEndpoints()
    .WithReference(api)
    .WaitFor(api);

builder.Build().Run();