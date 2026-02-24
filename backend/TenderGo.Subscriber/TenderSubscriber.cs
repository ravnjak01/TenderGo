using EasyNetQ;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using EasyNetQ.Topology;
namespace TenderGo.Subscriber
{
    public class TenderSubscriber
    {
        private readonly IPubSub _pubSub;

        public TenderSubscriber(IPubSub pubSub)
        {
            _pubSub = pubSub;
        }

        public async Task SubscribeAsync(string subscriptionId)
        {
            await _pubSub.SubscribeAsync<Tender>(
                subscriptionId,
                HandleTextMessage,
                          cfg => cfg.WithTopic("tender_updates")
            );
        }

        private Task HandleTextMessage(Tender entity,CancellationToken cancellationToken)
        {
            Console.WriteLine($"Received: {entity.Id}, {entity.Title}");
            return Task.CompletedTask;
        }

    }
    }

