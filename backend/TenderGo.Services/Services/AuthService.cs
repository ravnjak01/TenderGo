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
using Microsoft.AspNetCore.Mvc;

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
        private readonly EmailService _emailService;
        public AuthService(UserManager<ApplicationUser> userManager, IConfiguration config, IHttpContextAccessor httpContextAccessor, TenderGoContext context, IMapper mapper, ILogger<AuthService> logger, EmailService emailService
            )
        {
            _logger = logger;
            _userManager = userManager;
            _config = config;
            _httpContextAccessor = httpContextAccessor;
            _context = context;
            _mapper = mapper;
            _emailService = emailService;
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

            if (!result.Succeeded)
            {
                var errors = string.Join(", ", result.Errors.Select(e => e.Description));
                throw new UserException(errors);
            }

            await _userManager.AddToRoleAsync(user, AppRoles.User);

            _logger.LogInformation("User with email {Email} registered successfully", dto.Email);
            return result;

        }

        public async Task<LoginResponseDto?> LoginAsync(LoginRequest dto)
        {

            _logger.LogInformation("Attempting login for user with email {Email}", dto.Email);

            var user = await _userManager.FindByEmailAsync(dto.Email);
            if (user == null)
            {
                _logger.LogWarning("Login failed: User with email {Email} not found.", dto.Email);
                throw new UserException("Wrong email or password.");

            }

            var passwordValid = await _userManager.CheckPasswordAsync(user, dto.Password);
            if (!passwordValid)
            {
                _logger.LogWarning("Login failed: Invalid password for user {Email}.", dto.Email);
                throw new UserException("Wrong email or password.");

            }


            var roles = await _userManager.GetRolesAsync(user);

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier,user.Id),
                new Claim(ClaimTypes.Email,user.Email),
                new Claim(ClaimTypes.Name,user.UserName),
                new Claim(JwtRegisteredClaimNames.Jti,Guid.NewGuid().ToString())

            };



            foreach (var role in roles)
            {
                claims.Add(new Claim(ClaimTypes.Role, role));
            }

            var token = GenerateJwtToken(user, claims);

            _logger.LogInformation("User with email {Email} logged in successfully", dto.Email);
            return new LoginResponseDto
            {
                Token = token,
                ExpiresAt = DateTime.UtcNow.AddMinutes(
            int.Parse(_config["Jwt:ExpiresInMinutes"])



        )
            };


        }

        public async Task LogoutAsync()
        {
            var refreshToken = _httpContextAccessor.HttpContext?.Request.Cookies["refreshToken"];

            if (string.IsNullOrEmpty(refreshToken))
            {
                throw new UserException("Not found refresh token.");
            }


            var userId = _httpContextAccessor.HttpContext?.User?.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
            {
                throw new UserException("User is not defined.");
            }

            var storedToken = await _context.RefreshTokens.FirstOrDefaultAsync(rt => rt.Token == refreshToken && rt.UserId == userId);


            if (storedToken != null)
            {
                _context.RefreshTokens.Remove(storedToken);
                await _context.SaveChangesAsync();
            }



            _httpContextAccessor.HttpContext?.Response.Cookies.Delete("refreshToken", new CookieOptions
            {
                HttpOnly = true,
                Secure = true,
                SameSite = SameSiteMode.Strict,
            });
        }

        public string GenerateJwtToken(ApplicationUser user, IEnumerable<Claim> claims)
        {

            var jwtKey = _config["Jwt:Key"];
            if (string.IsNullOrEmpty(jwtKey))
            {
                _logger.LogCritical("JWT Key is missing in configuration!");
                throw new Exception("Server configuration error: Security key is missing.");
            }


            if (jwtKey.Length < 32)
            {
                _logger.LogCritical("JWT Key is too short. Minimum 32 characters required.");
                throw new Exception("Server configuration error: Security key is invalid.");
            }


            if (!int.TryParse(_config["Jwt:ExpiresInMinutes"], out var expires))
            {
                _logger.LogError("Jwt:ExpiresInMinutes is not a valid number in appsettings.json");
                throw new Exception("Server configuration error: Invalid token expiration settings.");
            }


            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var token = new JwtSecurityToken(
                issuer: _config["Jwt:Issuer"],
                audience: _config["Jwt:Audience"],
                claims: claims,
                notBefore: DateTime.UtcNow,
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

        public async Task<UserDTO> GetMyProfile()
        {

            var userId = GetCurrentUserId();

            var user = await _userManager.FindByIdAsync(userId);
            if (user == null) throw new Exception("User not found");

            var roles = await _userManager.GetRolesAsync(user);

            var response = _mapper.Map<UserDTO>(user);
            response.Roles = roles.ToList();

            return response;
        }

        public async Task ForgotPasswordAsync(ForgotPasswordRequest model, string baseUrl,CancellationToken cancellationToken)
        {
            var user = await _userManager.FindByEmailAsync(model.Email);
            if (user == null)
            {
                _logger.LogWarning($"Trying to reset for nonexisting email : {model.Email}");
                return;
            }
            try
            {
                var token = await _userManager.GeneratePasswordResetTokenAsync(user);
                var resetLink = $"{baseUrl}/reset-password?token={Uri.EscapeDataString(token)}&email={Uri.EscapeDataString(user.Email)}";

                await _emailService.SendResetPasswordEmail(user.Email, resetLink, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error during sending an email for {model.Email}");

                throw new Exception("Sending an email was not successfull.");
            }
        }

        public async Task<IdentityResult> ResetPasswordAsync(ResetPasswordRequest model)
        {
            var user = await _userManager.FindByEmailAsync(model.Email);
            if (user == null)
                return IdentityResult.Failed(new IdentityError { Description = "User not found." });
            var result = await _userManager.ResetPasswordAsync(user, model.Token, model.NewPassword);
            return result;

        }
    }
}
