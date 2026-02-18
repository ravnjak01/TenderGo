using System.Net;
using TenderGo.Models.DTOs;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Api.Middleware
{
    public class GlobalExceptionMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<GlobalExceptionMiddleware> _logger;

        public GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext httpContext)
        {
            try
            {
                await _next(httpContext);
            }
            catch (Exception ex)
            {
                _logger.LogError($"Something went wrong: {ex}");
                await HandleExceptionAsync(httpContext, ex);
            }
        }

        private static Task HandleExceptionAsync(HttpContext context, Exception exception)
        {
            context.Response.ContentType = "application/json";

            var statusCode = (int)HttpStatusCode.InternalServerError;
            var message = "Internal Server Error from the custom middleware.";

            // Provjeravamo o kojem se specifičnom Exceptionu radi
            switch (exception)
            {
                case BaseException customEx: // Tvoja bazna klasa koju smo ranije kreirali
                    statusCode = customEx.StatusCode;
                    message = customEx.Message;
                    break;

                case UnauthorizedAccessException:
                    statusCode = (int)HttpStatusCode.Unauthorized;
                    message = "Unauthorized access.";
                    break;

             
                // Ovdje možeš dodati još specifičnih sistemskih exceptiona
                default:
                    message = exception.Message; // U produkciji ovdje stavi općenitu poruku
                    break;
            }

            context.Response.StatusCode = statusCode;

            return context.Response.WriteAsync(new ErrorDetails()
            {
                StatusCode = context.Response.StatusCode,
                Message = message,
                Type = exception.GetType().Name
            }.ToString());
        }
    }
}
