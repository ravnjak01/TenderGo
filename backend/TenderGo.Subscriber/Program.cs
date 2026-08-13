using EasyNetQ;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using DotNetEnv;
using TenderGo.Api.Database;
using TenderGo.Subscriber;

LoadEnvFile();

if (Environment.GetEnvironmentVariable("DOTNET_RUNNING_IN_CONTAINER") != "true")
{
    Environment.SetEnvironmentVariable("DOTNET_ENVIRONMENT", "Development");
}

var hostBuilder = Host.CreateDefaultBuilder(args);

var host = hostBuilder
    .ConfigureServices((context, services) =>
    {
        var connectionString = context.Configuration.GetConnectionString("DefaultConnection")
                               ?? Environment.GetEnvironmentVariable("DB_CONNECTION");

        if (string.IsNullOrEmpty(connectionString))
        {
            throw new InvalidOperationException("Database connection string 'DefaultConnection' is missing from configuration.");
        }

        var rabbitConnectionString = BuildRabbitMqConnectionString(context.Configuration);

        if (string.IsNullOrEmpty(rabbitConnectionString))
        {
            throw new InvalidOperationException("RabbitMQ connection string is missing from configuration.");
        }

        // Registracija servisa
        services.AddDbContext<TenderGoContext>(options =>
            options.UseSqlServer(connectionString, b =>
            {
                b.MigrationsAssembly("TenderGo.Services");
            }));

        services.AddEasyNetQ(rabbitConnectionString);

        services.AddSingleton<TenderSubscriber>();
        services.AddHostedService<Worker>();
    })
    .Build();

await host.RunAsync();

#region Helper Methods

static void LoadEnvFile()
{
    if (Environment.GetEnvironmentVariable("DOTNET_RUNNING_IN_CONTAINER") == "true")
        return;

    var candidates = new[]
    {
        Path.Combine(AppContext.BaseDirectory, ".env"),
        Path.Combine(Directory.GetCurrentDirectory(), ".env"),
        Path.Combine(Directory.GetCurrentDirectory(), "..", ".env"),
        Path.Combine(Directory.GetCurrentDirectory(), "..", "..", ".env"),
    };

    foreach (var path in candidates)
    {
        var fullPath = Path.GetFullPath(path);
        if (File.Exists(fullPath))
        {
            Env.Load(fullPath);
            return;
        }
    }
}

static string BuildRabbitMqConnectionString(IConfiguration config)
{
    var host = Environment.GetEnvironmentVariable("RabbitMQ__Host")
                   ?? config["RabbitMQ:Host"]
                   ?? "localhost";

    var username = Environment.GetEnvironmentVariable("RabbitMQ__Username")
                   ?? config["RabbitMQ:Username"]
                   ?? "guest";

    var password = Environment.GetEnvironmentVariable("RabbitMQ__Password")
                   ?? config["RabbitMQ:Password"]
                   ?? "guest";

    return $"host={host};username={username};password={password};timeout=30";
}

#endregion