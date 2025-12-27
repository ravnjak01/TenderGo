using Microsoft.AspNetCore.Identity;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.Entities;
using TenderGo.Services.DTOs;

namespace TenderGo.Services.Interfaces
{
    public interface IAuthService
    {

        Task<IdentityResult> RegisterAsync(RegisterDTO dto);
    }
}
