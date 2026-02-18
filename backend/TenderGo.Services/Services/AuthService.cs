using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Services.DTOs;
using TenderGo.Services.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using TenderGo.Models.DTOs;
using TenderGo.Api.Database;
using AutoMapper;
using TenderGo.Services.Services.Exceptions;
using Microsoft.Extensions.Logging;

namespace TenderGo.Services.Services
{
    public class AuthService : IAuthService
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IConfiguration _config;
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly TenderGoContext _context;
        private readonly IMapper _mapper;
        private readonly ILogger<AuthService> _logger;

        public AuthService(UserManager<ApplicationUser> userManager, IConfiguration config, IHttpContextAccessor httpContextAccessor,TenderGoContext context,IMapper mapper,ILogger<AuthService> logger
            )
        {
            _logger = logger;
            _userManager = userManager;
            _config = config;
            _httpContextAccessor = httpContextAccessor;
            _context = context;
            _mapper = mapper;
        }

        public async Task<IdentityResult> RegisterAsync(RegisterRequest dto)
        {
            _logger.LogInformation("Registering new user with email {Email}", dto.Email);

            var user = new ApplicationUser
            {
                UserName = dto.Email,
                Email = dto.Email,
                FirstName = dto.FirstName,
                LastName = dto.LastName,
                CreatedAt = DateTime.UtcNow
            };
            var result = await _userManager.CreateAsync(user, dto.Password);

            if(!result.Succeeded)
            {
                var errors = string.Join(", ", result.Errors.Select(e => e.Description));
                throw new UserException(errors);
            }

            await _userManager.AddToRoleAsync(user, AppRoles.User);

            return result;

            _logger.LogInformation("User with email {Email} registered successfully", dto.Email);
        }

        public async Task<LoginResponseDto?> LoginAsync(LoginRequest dto)
        {

            _logger.LogInformation("Attempting login for user with email {Email}", dto.Email);

            var user = await _userManager.FindByEmailAsync(dto.Email);
            if (user==null)
            {
                return null;

            }

            var passwordValid = await _userManager.CheckPasswordAsync(user, dto.Password);
            if (!passwordValid)
                return null;

            var roles= await _userManager.GetRolesAsync(user);

            var claims= new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier,user.Id),
                new Claim(ClaimTypes.Email,user.Email),
                new Claim(ClaimTypes.Name,user.UserName)

            };


            foreach (var role in roles)
            {
                claims.Add(new Claim(ClaimTypes.Role, role));
            }

            var token = GenerateJwtToken(user,claims);

            return new LoginResponseDto
            {
                Token = token,
                ExpiresAt = DateTime.UtcNow.AddMinutes(
            int.Parse(_config["Jwt:ExpiresInMinutes"])



        )
            };


            _logger.LogInformation("User with email {Email} logged in successfully", dto.Email);
        }

        public string GenerateJwtToken(ApplicationUser user,IEnumerable<Claim>claims)
        {

            var jwtKey = _config["Jwt:Key"]
    ?? throw new Exception("Jwt:Key nije postavljen");

            var expires = int.Parse(
       _config["Jwt:ExpiresInMinutes"]
       ?? throw new Exception("Jwt:ExpiresInMinutes nije postavljen")
   );
          
            var key=new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]));

            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var token = new JwtSecurityToken(
                issuer: _config["Jwt:Issuer"],
                audience: _config["Jwt:Audience"],
                claims: claims,
                 expires: DateTime.UtcNow.AddMinutes(expires),
                signingCredentials: creds
                );


            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        public string GetCurrentUserId()
        {

            var userId = _httpContextAccessor.HttpContext?.User?.FindFirstValue(ClaimTypes.NameIdentifier);
            return userId ?? throw new Exception("User not logged");
        }

        public async Task<MeResponseDTO> GetMyProfile()
        {

            var userId = GetCurrentUserId();

            var user = await _userManager.FindByIdAsync(userId);
            if (user == null) throw new Exception("User not found");

            var roles = await _userManager.GetRolesAsync(user);

            var response = _mapper.Map<MeResponseDTO>(user);
            response.Roles = roles.ToList();

            return response;
        }

    }
}
