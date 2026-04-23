using EasyNetQ;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using DotNetEnv;
using TenderGo.Api.Database;
using TenderGo.Subscriber;
using TenderGo.Subscriber.Models;

var envPath = Path.Combine(AppContext.BaseDirectory, ".env");
if (File.Exists(envPath))
    Env.Load(envPath);

// Read what docker-compose actually sets
var connectionString = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection");
var rabbitHost = Environment.GetEnvironmentVariable("RabbitMQ__Host") ?? "localhost";
var rabbitUser = Environment.GetEnvironmentVariable("RabbitMQ__Username") ?? "guest";
var rabbitPass = Environment.GetEnvironmentVariable("RabbitMQ__Password") ?? "guest";

Console.WriteLine("DB = " + connectionString);
if (string.IsNullOrEmpty(connectionString))
    throw new Exception("DB_CONNECTION is missing!");

var host = Host.CreateDefaultBuilder(args)
    .ConfigureServices((context, services) =>
    {
        services.AddDbContext<TenderGoContext>(options =>
            options.UseSqlServer(connectionString, b =>
            {
                b.MigrationsAssembly("TenderGo.Services");
            }));

        services.AddDbContext<NotificationDbContext>(options =>
            options.UseSqlServer(connectionString));

        // Use credentials from env
        services.AddEasyNetQ($"host={rabbitHost};username={rabbitUser};password={rabbitPass}")
                .UseSystemTextJson();

        services.AddSingleton<TenderSubscriber>();
        services.AddHostedService<Worker>();
    })
    .Build();

await host.RunAsync();