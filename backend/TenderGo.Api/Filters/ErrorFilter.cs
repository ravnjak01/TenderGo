using System.Diagnostics;
using System.Net;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.Extensions.Logging;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Api.Filters;

/// <summary>
/// Global filter that standardizes *all* error responses into a single JSON envelope
/// that is easy to parse on the Flutter side.
///
/// Register globally via:
/// services.AddControllers(o => o.Filters.Add<ErrorFilter>());
/// </summary>
public sealed class ErrorFilter : Attribute, IAsyncExceptionFilter, IAsyncResultFilter
{
    private readonly ILogger<ErrorFilter> _logger;

    public ErrorFilter(ILogger<ErrorFilter> logger)
    {
        _logger = logger;
    }

    public Task OnExceptionAsync(ExceptionContext context)
    {
        var (statusCode, message, errors) = MapException(context);
        context.Result = ToObjectResult(context, statusCode, message, errors);
        context.ExceptionHandled = true;
        return Task.CompletedTask;
    }

    public async Task OnResultExecutionAsync(ResultExecutingContext context, ResultExecutionDelegate next)
    {
        // If an exception filter produced a result already, or pipeline has no result, continue.
        if (context.Result is null)
        {
            await next();
            return;
        }

        // If this is already our standardized envelope, don't wrap again.
        if (TryGetStatusCode(context.Result, out var existingStatusCode) && existingStatusCode >= 400)
        {
            if (IsStandardEnvelope(context.Result))
            {
                await next();
                return;
            }

            var (message, errors) = MapErrorResult(context.Result, existingStatusCode);
            context.Result = ToObjectResult(context, existingStatusCode, message, errors);
        }

        await next();
    }

    private (int statusCode, string message, IReadOnlyList<string>? errors) MapException(ExceptionContext context)
    {
        var ex = context.Exception;

        // Domain / business logic exceptions (your custom ones)
        if (ex is ForbiddenException forbidden)
        {
            return ((int)HttpStatusCode.Forbidden, ToUserMessage(forbidden.Message, fallback: "Forbidden."), new[] { forbidden.Message });
        }

        if (ex is NotFoundException notFound)
        {
            return ((int)HttpStatusCode.NotFound, ToUserMessage(notFound.Message, fallback: "Resource not found."), new[] { notFound.Message });
        }

        if (ex is UserException userException)
        {
            return ((int)HttpStatusCode.BadRequest, ToUserMessage(userException.Message, fallback: "Bad request."), new[] { userException.Message });
        }

        // Validation exceptions (your custom ValidationException OR FluentValidation.ValidationException)
        if (TryExtractValidationErrors(ex, out var validationErrors))
        {
            return ((int)HttpStatusCode.BadRequest, "Validation failed.", validationErrors);
        }

        // Auth-related exceptions
        if (ex is UnauthorizedAccessException)
        {
            return ((int)HttpStatusCode.Unauthorized, "Unauthorized.", null);
        }

        // Unknown/unhandled -> generic 500 (log real exception)
        _logger.LogError(ex, "Unhandled exception occurred. TraceId={TraceId}", GetTraceId(context.HttpContext));
        return ((int)HttpStatusCode.InternalServerError, "Internal Server Error.", null);
    }

    private (string message, IReadOnlyList<string>? errors) MapErrorResult(IActionResult result, int statusCode)
    {
        // 401 / 403 results often have no body.
        if (statusCode == (int)HttpStatusCode.Unauthorized) return ("Unauthorized.", null);
        if (statusCode == (int)HttpStatusCode.Forbidden) return ("Forbidden.", null);

        // Handle typical validation payloads.
        if (result is BadRequestObjectResult br)
        {
            if (TryExtractErrorsFromBadRequestValue(br.Value, out var errors))
            {
                return ("Validation failed.", errors);
            }

            if (br.Value is string s && !string.IsNullOrWhiteSpace(s))
            {
                return (s, new[] { s });
            }
        }

        // Any other ObjectResult with a string body.
        if (result is ObjectResult obj && obj.Value is string msg && !string.IsNullOrWhiteSpace(msg))
        {
            return (msg, statusCode >= 500 ? null : new[] { msg });
        }

        // Fallback message by status code.
        return statusCode switch
        {
            400 => ("Bad request.", null),
            404 => ("Resource not found.", null),
            409 => ("Conflict.", null),
            422 => ("Validation failed.", null),
            500 => ("Internal Server Error.", null),
            _ => ("Request failed.", null)
        };
    }

    private ObjectResult ToObjectResult(FilterContext context, int statusCode, string message, IReadOnlyList<string>? errors)
    {
        var payload = new ApiErrorEnvelope
        {
            success = false,
            message = message,
            errors = errors,
            statusCode = statusCode,
            traceId = GetTraceId(context.HttpContext)
        };

        return new ObjectResult(payload) { StatusCode = statusCode };
    }

    private static string GetTraceId(HttpContext httpContext)
    {
        // Uses W3C traceparent / Activity when available; otherwise falls back to ASP.NET trace id.
        return Activity.Current?.Id ?? httpContext.TraceIdentifier;
    }

    private static bool TryGetStatusCode(IActionResult result, out int statusCode)
    {
        switch (result)
        {
            case StatusCodeResult scr:
                statusCode = scr.StatusCode;
                return true;
            case ObjectResult or:
                statusCode = or.StatusCode ?? 200;
                return true;
            default:
                statusCode = 200;
                return false;
        }
    }

    private static bool IsStandardEnvelope(IActionResult result)
    {
        if (result is not ObjectResult obj) return false;
        return obj.Value is ApiErrorEnvelope;
    }

    private static string ToUserMessage(string? input, string fallback)
        => string.IsNullOrWhiteSpace(input) ? fallback : input;

    private static bool TryExtractValidationErrors(Exception ex, out IReadOnlyList<string> errors)
    {
        // Your custom ValidationException appears to contain a Dictionary<string, string[]/List<string>> in .Errors
        if (ex is ValidationException ve)
        {
            var list = new List<string>();
            foreach (var kv in ve.Errors)
            {
                foreach (var msg in kv.Value)
                {
                    if (!string.IsNullOrWhiteSpace(kv.Key))
                        list.Add($"{kv.Key}: {msg}");
                    else
                        list.Add(msg);
                }
            }

            errors = list;
            return true;
        }

        // FluentValidation.ValidationException (avoid hard dependency by checking by name)
        var type = ex.GetType();
        if (type.FullName == "FluentValidation.ValidationException")
        {
            var prop = type.GetProperty("Errors");
            if (prop?.GetValue(ex) is System.Collections.IEnumerable enumerable)
            {
                var list = new List<string>();
                foreach (var item in enumerable)
                {
                    var propertyName = item?.GetType().GetProperty("PropertyName")?.GetValue(item)?.ToString();
                    var errorMessage = item?.GetType().GetProperty("ErrorMessage")?.GetValue(item)?.ToString();

                    if (!string.IsNullOrWhiteSpace(propertyName) && !string.IsNullOrWhiteSpace(errorMessage))
                        list.Add($"{propertyName}: {errorMessage}");
                    else if (!string.IsNullOrWhiteSpace(errorMessage))
                        list.Add(errorMessage);
                }

                errors = list;
                return true;
            }
        }

        errors = Array.Empty<string>();
        return false;
    }

    private static bool TryExtractErrorsFromBadRequestValue(object? value, out IReadOnlyList<string> errors)
    {
        // BadRequest(ModelState) typically becomes SerializableError
        if (value is SerializableError se)
        {
            var list = new List<string>();
            foreach (var (key, val) in se)
            {
                if (val is string[] arr)
                {
                    foreach (var msg in arr) list.Add($"{key}: {msg}");
                }
                else if (val is IEnumerable<string> enumerable)
                {
                    foreach (var msg in enumerable) list.Add($"{key}: {msg}");
                }
                else if (val is string s)
                {
                    list.Add($"{key}: {s}");
                }
            }

            errors = list;
            return true;
        }

        if (value is ValidationProblemDetails vpd)
        {
            errors = vpd.Errors
                .SelectMany(kv => kv.Value.Select(msg => $"{kv.Key}: {msg}"))
                .ToArray();
            return true;
        }

        if (value is ModelStateDictionary msd)
        {
            errors = msd
                .Where(x => x.Value?.Errors.Count > 0)
                .SelectMany(x => x.Value!.Errors.Select(e => $"{x.Key}: {e.ErrorMessage}"))
                .ToArray();
            return true;
        }

        errors = Array.Empty<string>();
        return false;
    }

    public sealed class ApiErrorEnvelope
    {
        public bool success { get; init; }
        public string message { get; init; } = "";
        public IReadOnlyList<string>? errors { get; init; }
        public int statusCode { get; init; }
        public string traceId { get; init; } = "";
    }
}