using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using System.Net;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Api.Filters
{
    public class ErrorFilter: ExceptionFilterAttribute
    {
        public override void OnException(ExceptionContext context)
        {


            if(context.Exception is ValidationException validationException)
            {
                    context.HttpContext.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                foreach (var error in validationException.Errors)
                {
                    context.ModelState.AddModelError(error.Key, string.Join(", ", error.Value));
                }
            }   
            else if(context.Exception is NotFoundException exception)
            {
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.NotFound;
                context.ModelState.AddModelError("NotFound", exception.Message);
            }
            else if (context.Exception is UserException userException)
            {
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                context.ModelState.AddModelError("UserError", userException.Message);
            }

            else if(context.Exception is ForbiddenException forbidden)
            {
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.Forbidden;
                context.ModelState.AddModelError("Forbidden", forbidden.Message);
            }
            else
            {

                context.ModelState.AddModelError("ERROR", "Server side error");
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
            }



            var list= context.ModelState.Where(x=>x.Value.Errors.Count()>0)
                .ToDictionary(x=>x.Key,y => y.Value.Errors.Select(z => z.ErrorMessage));

            context.Result = new JsonResult(new {errors=list});
        }
    }
}
