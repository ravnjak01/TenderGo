using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Logging;
using System.Net;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Api.Filters
{
    public class ErrorFilter : ExceptionFilterAttribute
    {
        private readonly ILogger<ErrorFilter> _logger;

        public ErrorFilter(ILogger<ErrorFilter> logger)
        {
            _logger = logger;
        }

        public override void OnException(ExceptionContext context)
        {
            var ex = context.Exception;

            // 🔥 LOG SVE
            _logger.LogError(ex, "Unhandled exception occurred");

            if (ex is ValidationException validationException)
            {
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.BadRequest;

                foreach (var error in validationException.Errors)
                {
                    context.ModelState.AddModelError(error.Key, string.Join(", ", error.Value));
                }
            }
            else if (ex is NotFoundException notFound)
            {
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.NotFound;
                context.ModelState.AddModelError("NotFound", notFound.Message);
            }
            else if (ex is UserException userException)
            {
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                context.ModelState.AddModelError("UserError", userException.Message);
            }
            else if (ex is ForbiddenException forbidden)
            {
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.Forbidden;
                context.ModelState.AddModelError("Forbidden", forbidden.Message);
            }
            else
            {
                // 🔥 OVDE SAD LOGUJEMO PRAVI ERROR
                _logger.LogError(ex, "Server side error (unhandled)");

                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.InternalServerError;

                context.ModelState.AddModelError("ERROR", ex.Message);
            }

            var list = context.ModelState
                .Where(x => x.Value.Errors.Count > 0)
                .ToDictionary(
                    x => x.Key,
                    y => y.Value.Errors.Select(z => z.ErrorMessage)
                );

            context.Result = new JsonResult(new { errors = list });
        }
    }
}