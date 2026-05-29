using EasyNetQ;
using Microsoft.Extensions.Configuration;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using DotNetEnv;
using TenderGo.Api.Database;
using TenderGo.Subscriber;
using TenderGo.Subscriber.Models;

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

LoadEnvFile();

var hostBuilder = Host.CreateDefaultBuilder(args);

var host = hostBuilder
    .ConfigureServices((context, services) =>
    {
       var connectionString = context.Configuration.GetConnectionString("DefaultConnection") 
                       ?? Environment.GetEnvironmentVariable("DB_CONNECTION");

        var rabbitConnectionString = context.Configuration.GetConnectionString("RabbitMQ")
                                     ?? "host=localhost;username=guest;password=guest;timeout=30";

        if (string.IsNullOrEmpty(connectionString))
            throw new Exception("DefaultConnection is missing from configuration!");

        services.AddDbContext<TenderGoContext>(options =>
            options.UseSqlServer(connectionString, b =>
            {
                b.MigrationsAssembly("TenderGo.Services");
            }));

        services.AddDbContext<TenderGoContext>(options =>
            options.UseSqlServer(connectionString));

            services.AddEasyNetQ(rabbitConnectionString);

        services.AddSingleton<TenderSubscriber>();
        services.AddHostedService<Worker>();
    })
    .Build();

await host.RunAsync();
