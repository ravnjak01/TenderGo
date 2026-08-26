using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System.Net;
using System.Net.Mail;
using TenderGo.Models.Entities;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services;

public class EmailService: IEmailService
{
    private readonly EmailSettings _emailSettings;
    private readonly ILogger<EmailService> _logger;



    public EmailService(IOptions<EmailSettings> emailSettings, ILogger<EmailService> logger
        )
    {
        _emailSettings = emailSettings.Value;
        _logger = logger;

        if (string.IsNullOrEmpty(_emailSettings.From))
        {
            _logger.LogCritical("Email settings are missing or improperly configured!");
            throw new InvalidOperationException("Email service configuration error: 'From' address is missing.");
        }
    }


    public async Task SendResetPasswordEmail(string toEmail, string resetCode, CancellationToken cancellationToken)
    {
        try
        {
            cancellationToken.ThrowIfCancellationRequested();

            using var mail = new MailMessage
            {
                From = new MailAddress(_emailSettings.From),
                Subject = "Password reset ",
                IsBodyHtml = true,
                Body = $@"
                <h3>Password Reset Request</h3>
                <p>You requested a password reset. Please use the following code to reset your password:</p>
                <h2 style='color: #2B6CB0; letter-spacing: 2px;'>{resetCode}</h2>
                <p>If you didn't request this, you can safely ignore this email.</p>"
            };
            mail.To.Add(toEmail);

            using var smtp = new SmtpClient(_emailSettings.SmtpServer, _emailSettings.Port)
            {
                UseDefaultCredentials = false,
                Credentials = new NetworkCredential(_emailSettings.Username, _emailSettings.Password),
                EnableSsl = _emailSettings.EnableSsl,
                Timeout = 10000
            };

            cancellationToken.ThrowIfCancellationRequested();

            await smtp.SendMailAsync(mail);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Failed to send email to {toEmail}");
            throw new InvalidOperationException($"Sending of  email to {toEmail} didnt succeed.", ex);
        }
    }

}
