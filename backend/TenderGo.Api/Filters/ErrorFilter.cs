using System;
using System.Diagnostics;
using System.Net;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Api.Filters;

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
        if (context.Result is null)
        {
            await next();
            return;
        }

        if (context.Result is FileResult)
        {
            await next();
            return;
        }

        TryGetStatusCode(context.Result, out var existingStatusCode);

        if (existingStatusCode >= 400)
        {
            if (IsStandardEnvelope(context.Result))
            {
                await next();
                return;
            }

            var (message, errors) = MapErrorResult(context.Result, existingStatusCode);
            context.Result = ToObjectResult(context, existingStatusCode, message, errors);
        }
        else
        {
            if (context.Result is ObjectResult objResult &&
                (objResult.Value is ApiSuccessEnvelope || objResult.Value is ApiErrorEnvelope))
            {
                await next();
                return;
            }

            context.Result = ToSuccessObjectResult(context.Result, existingStatusCode);
        }

        await next();
    }

    private ObjectResult ToSuccessObjectResult(IActionResult currentResult, int statusCode)
    {
        object? rawData = null;
        string message = "Request processed successfully.";

        if (currentResult is ObjectResult obj && obj.Value is not null)
        {
            if (obj.Value is string text)
            {
                message = text;
            }
            else
            {
                rawData = obj.Value;
            }
        }

        var payload = new ApiSuccessEnvelope
        {
            success = true,
            statusCode = statusCode,
            message = message,
            data = rawData
        };

        return new ObjectResult(payload) { StatusCode = statusCode };
    }


    private (int statusCode, string message, IReadOnlyList<string>? errors) MapException(ExceptionContext context)
    {
        var ex = context.Exception;

        if (ex is BaseException baseEx)
        {
            if (ex is ValidationException valEx && valEx.Errors.Any())
            {
                var formattedErrors = valEx.Errors.SelectMany(kv => kv.Value.Select(msg => $"{kv.Key}: {msg}")).ToList();
                return (baseEx.StatusCode, baseEx.Message, formattedErrors);
            }

            return (baseEx.StatusCode, baseEx.Message, new[] { baseEx.Message });
        }

        if (TryExtractValidationErrors(ex, out var validationErrors))
            return ((int)HttpStatusCode.BadRequest, "Validation failed.", validationErrors);

        if (ex is UnauthorizedAccessException)
        {
            _logger.LogError(
                ex,
                "File system access error occurred. TraceId={TraceId}",
                GetTraceId(context.HttpContext));

            return (
                (int)HttpStatusCode.InternalServerError,
                "Došlo je do greške prilikom pristupa fajlu.",
                null);
        }

        if (ex is DbUpdateException dbEx)
        {
            _logger.LogError(dbEx, "Database update error occurred. TraceId={TraceId}", GetTraceId(context.HttpContext));

            var sqlException = dbEx.InnerException as SqlException;
            if (sqlException != null && sqlException.Number == 547)
            {
                return ((int)HttpStatusCode.BadRequest, "Stavka se ne može obrisati jer se koristi u drugim dijelovima sistema.", null);
            }

            return ((int)HttpStatusCode.InternalServerError, "Došlo je do greške prilikom rada sa bazom podataka.", null);
        }

        _logger.LogError(ex, "Unhandled exception occurred: {Message}. TraceId={TraceId}", ex.Message, GetTraceId(context.HttpContext));

        return ((int)HttpStatusCode.InternalServerError, "Došlo je do neočekivane greške na serveru.", null);
    }

    private (string message, IReadOnlyList<string>? errors) MapErrorResult(IActionResult result, int statusCode)
    {
        if (statusCode == (int)HttpStatusCode.Unauthorized) return ("Unauthorized.", null);
        if (statusCode == (int)HttpStatusCode.Forbidden) return ("Forbidden.", null);

        if (result is BadRequestObjectResult br)
        {
            if (TryExtractErrorsFromBadRequestValue(br.Value, out var errors)) return ("Validation failed.", errors);
            if (br.Value is string s && !string.IsNullOrWhiteSpace(s)) return (s, new[] { s });
        }

        if (result is ObjectResult obj && obj.Value is string msg && !string.IsNullOrWhiteSpace(msg))
        {
            return (msg, statusCode >= 500 ? null : new[] { msg });
        }

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

    private static string GetTraceId(HttpContext httpContext) => Activity.Current?.Id ?? httpContext.TraceIdentifier;

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

    private static string ToUserMessage(string? input, string fallback) => string.IsNullOrWhiteSpace(input) ? fallback : input;

    private static bool TryExtractValidationErrors(Exception ex, out IReadOnlyList<string> errors)
    {
        if (ex is ValidationException ve)
        {
            var list = new List<string>();
            foreach (var kv in ve.Errors)
            {
                foreach (var msg in kv.Value)
                {
                    if (!string.IsNullOrWhiteSpace(kv.Key)) list.Add($"{kv.Key}: {msg}");
                    else list.Add(msg);
                }
            }
            errors = list;
            return true;
        }

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

                    if (!string.IsNullOrWhiteSpace(propertyName) && !string.IsNullOrWhiteSpace(errorMessage)) list.Add($"{propertyName}: {errorMessage}");
                    else if (!string.IsNullOrWhiteSpace(errorMessage)) list.Add(errorMessage);
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
        if (value is Microsoft.AspNetCore.Identity.IdentityResult identityResult)
        {
            errors = identityResult.Errors.Select(e => e.Description).ToArray();
            return true;
        }
        if (value is IEnumerable<Microsoft.AspNetCore.Identity.IdentityError> identityErrors)
        {
            errors = identityErrors.Select(e => e.Description).ToArray();
            return true;
        }
        if (value is SerializableError se)
        {
            var list = new List<string>();
            foreach (var (key, val) in se)
            {
                if (val is string[] arr) foreach (var msg in arr) list.Add($"{key}: {msg}");
                else if (val is IEnumerable<string> enumerable) foreach (var msg in enumerable) list.Add($"{key}: {msg}");
                else if (val is string s) list.Add($"{key}: {s}");
            }
            errors = list;
            return true;
        }
        if (value is ValidationProblemDetails vpd)
        {
            errors = vpd.Errors.SelectMany(kv => kv.Value.Select(msg => $"{kv.Key}: {msg}")).ToArray();
            return true;
        }
        if (value is ModelStateDictionary msd)
        {
            errors = msd.Where(x => x.Value?.Errors.Count > 0).SelectMany(x => x.Value!.Errors.Select(e => $"{x.Key}: {e.ErrorMessage}")).ToArray();
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
    public sealed class ApiSuccessEnvelope
    {
        public bool success { get; init; } = true;
        public string message { get; init; } = "Request processed successfully.";
        public object? data { get; init; }
        public int statusCode { get; init; }
    }
}
