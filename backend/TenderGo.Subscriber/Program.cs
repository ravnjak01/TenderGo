
using EasyNetQ;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using TenderGo.Subscriber;

var host = Host.CreateDefaultBuilder(args)
    .ConfigureServices((context, services) =>
    {
        services.AddEasyNetQ("host=localhost");
        services.AddSingleton<TenderSubscriber>();
        services.AddHostedService<Worker>();

    })
    .Build();

await host.RunAsync();

