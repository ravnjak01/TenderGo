using Microsoft.Extensions.Hosting;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Subscriber
{
    public class Worker:BackgroundService
    {
        private readonly TenderSubscriber _subscriber;
        public Worker(TenderSubscriber subscriber)
        {
            _subscriber = subscriber;
        }
        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {

            Console.WriteLine("Provide subscription ID: ");
            var subscriptionId = Console.ReadLine();


            await _subscriber.SubscribeAsync(subscriptionId);

            Console.WriteLine($"Listening with ID: {subscriptionId}");

            await Task.Delay(Timeout.Infinite, stoppingToken);
        }
    }
}
