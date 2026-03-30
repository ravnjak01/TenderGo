using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System.Net;
using System.Net.Mail;
using TenderGo.Models.Entities;
using TenderGo.Services.Services;

public class EmailService 
{
    private readonly EmailSettings _emailSettings;
    private readonly ILogger<EmailService> _logger;


    public EmailService(IOptions<EmailSettings> emailSettings,ILogger<EmailService> logger
        )
    {
        _emailSettings = emailSettings.Value;
        _logger = logger;

        if (string.IsNullOrEmpty(_emailSettings.From))
            throw new Exception("KONFIGURACIJA NIJE UCITANA! Proveri Program.cs i JSON.");
    }


    public async Task SendResetPasswordEmail(string toEmail, string resetLink, CancellationToken cancellationToken)
    {
        try
        {
            cancellationToken.ThrowIfCancellationRequested();

            using var mail = new MailMessage
            {
                From = new MailAddress(_emailSettings.From),
                Subject = "Password reset ",
                Body = $"Click on link to reset a password: {resetLink}",
                IsBodyHtml = true 
            };
            mail.To.Add(toEmail);

            using var smtp = new SmtpClient(_emailSettings.SmtpServer, _emailSettings.Port)
            {
                UseDefaultCredentials = false,
                Credentials = new NetworkCredential(_emailSettings.Username, _emailSettings.Password),
                EnableSsl = true,
                Timeout = 10000
            };

            cancellationToken.ThrowIfCancellationRequested();

            await smtp.SendMailAsync(mail);
        }
        catch (OperationCanceledException)
        {
            // Logika ako je Task otkazan prije slanja
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Failed to send email to {toEmail}");
            throw new InvalidOperationException($"Sending of  email to {toEmail} didnt succeed.", ex);
        }
    }

}
