using EasyNetQ;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TenderGo.Api.Database;
using TenderGo.Contracts;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;

namespace TenderGo.Api.Controllers;

[ApiController]
[Route("api/test-notifications")]
public class TestNotificationController : ControllerBase
{
    private readonly TenderGoContext _context;
    private readonly IPubSub _pubSub;
    private readonly IWebHostEnvironment _environment;
    private readonly ILogger<TestNotificationController> _logger;

    public TestNotificationController(
        TenderGoContext context,
        IPubSub pubSub,
        IWebHostEnvironment environment,
        ILogger<TestNotificationController> logger)
    {
        _context = context;
        _pubSub = pubSub;
        _environment = environment;
        _logger = logger;
    }

    [HttpPost("bid-created")]
    public async Task<IActionResult> PublishBidCreated([FromBody] TestBidCreatedRequest request)
    {
        if (!_environment.IsDevelopment()) return NotFound();

        var tender = await _context.Tenders
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Id == request.TenderId);

        if (tender == null) return NotFound($"Tender {request.TenderId} was not found.");

        var message = new BidCreatedEvent
        {
            TenderId = tender.Id,
            OwnerUserId = tender.CreatedByUserId,
            OfferedPrice = request.OfferedPrice ?? tender.MaxBudget,
            TenderTitle = tender.Title
        };

        await _pubSub.PublishAsync(message, cfg => cfg.WithTopic("bid_created"));

        return Ok(new { Topic = "bid_created", Event = message });
    }

    [HttpPost("tender-expired")]
    public async Task<IActionResult> PublishTenderExpired([FromBody] TestTenderExpiredRequest request)
    {
        if (!_environment.IsDevelopment()) return NotFound();

        var tender = await _context.Tenders
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Id == request.TenderId);

        if (tender == null) return NotFound($"Tender {request.TenderId} was not found.");

        var message = new TenderExpiredEvent
        {
            TenderId = tender.Id,
            TenderTitle = tender.Title,
            OwnerUserId = tender.CreatedByUserId,
            ExpiredAt = DateTime.UtcNow
        };

        await _pubSub.PublishAsync(message, cfg => cfg.WithTopic("tender_expired"));

        return Ok(new { Topic = "tender_expired", Event = message });
    }

    [HttpPost("tender-awarded")]
    public async Task<IActionResult> PublishTenderAwarded([FromBody] TestTenderAwardedRequest request)
    {
        if (!_environment.IsDevelopment()) return NotFound();

        var tender = await _context.Tenders
            .Include(t => t.Bids)
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Id == request.TenderId);

        if (tender == null) return NotFound($"Tender {request.TenderId} was not found.");

        var winningBid = request.WinnerBidId.HasValue
            ? tender.Bids.FirstOrDefault(b => b.Id == request.WinnerBidId.Value)
            : tender.Bids.FirstOrDefault(b => b.Id == tender.WinningBidId)
                ?? tender.Bids.FirstOrDefault(b => b.Status == ApplicationStatus.Accepted);

        var winnerUserId = request.WinnerUserId ?? winningBid?.SubmittedByUserId;
        if (string.IsNullOrWhiteSpace(winnerUserId))
        {
            return BadRequest("Provide winnerUserId or winnerBidId, or use a tender with a winning/accepted bid.");
        }

        var otherUserIds = request.OtherUserIds?.Distinct().ToList()
            ?? tender.Bids
                .Where(b => b.SubmittedByUserId != winnerUserId && b.Status == ApplicationStatus.Pending)
                .Select(b => b.SubmittedByUserId)
                .Distinct()
                .ToList();

        var message = new TenderAwardedEvent
        {
            TenderId = tender.Id,
            TenderTitle = tender.Title,
            WinnerUserId = winnerUserId,
            OtherUserIds = otherUserIds
        };

        await _pubSub.PublishAsync(message, cfg => cfg.WithTopic("tender_awarded"));

        return Ok(new { Topic = "tender_awarded", Event = message });
    }

    [HttpPost("direct")]
    public async Task<IActionResult> CreateDirectNotification([FromBody] TestDirectNotificationRequest request)
    {
        if (!_environment.IsDevelopment()) return NotFound();

        var userExists = await _context.Users.AnyAsync(u => u.Id == request.UserId);
        if (!userExists) return NotFound($"User {request.UserId} was not found.");

        var notification = new Notification
        {
            UserId = request.UserId,
            Title = request.Title,
            Message = request.Message,
            CreatedAt = DateTime.UtcNow,
            IsRead = false
        };

        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();

        _logger.LogInformation(
            "Development test notification {NotificationId} created directly for user {UserId}",
            notification.Id,
            notification.UserId);

        return Ok(notification);
    }

    public class TestBidCreatedRequest
    {
        public int TenderId { get; set; }
        public decimal? OfferedPrice { get; set; }
    }

    public class TestTenderExpiredRequest
    {
        public int TenderId { get; set; }
    }

    public class TestTenderAwardedRequest
    {
        public int TenderId { get; set; }
        public int? WinnerBidId { get; set; }
        public string? WinnerUserId { get; set; }
        public List<string>? OtherUserIds { get; set; }
    }

    public class TestDirectNotificationRequest
    {
        public string UserId { get; set; } = string.Empty;
        public string Title { get; set; } = "Test notification";
        public string Message { get; set; } = "This is a development test notification.";
    }
}
