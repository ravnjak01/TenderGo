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
using System.Security.Cryptography;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;

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
        private readonly IConfiguration _configuration;
        private readonly string _cloudName;
        private readonly IWebHostEnvironment _env;
        public AuthService(UserManager<ApplicationUser> userManager, IConfiguration config, IHttpContextAccessor httpContextAccessor, TenderGoContext context, IMapper mapper, ILogger<AuthService> logger, EmailService emailService, IConfiguration configuration
           ,IWebHostEnvironment env )
        {
            _logger = logger;
            _userManager = userManager;
            _config = config;
            _httpContextAccessor = httpContextAccessor;
            _context = context;
            _mapper = mapper;
            _emailService = emailService;
            _configuration = configuration;
            _env=env;
            _cloudName = _configuration["AppSettings:FrontendUrl"];
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
            if (user.IsBanned)
            {
                throw new UserException("ACCOUNT_BANNED");  
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

            var existingTokens = await _context.RefreshTokens
          .Where(rt => rt.UserId == user.Id && !rt.IsRevoked)
          .ToListAsync();

            foreach (var existing in existingTokens)
            {
                existing.IsRevoked = true;
                existing.RevokedAt = DateTime.UtcNow;
                existing.UpdatedAt = DateTime.UtcNow;
                existing.UpdatedByUserId = user.Id;
            }

            var refreshTokenExpiryDays = int.Parse(_config["Jwt:RefreshTokenExpiryDays"] ?? "7");
            var refreshToken = new RefreshToken
            {
                Token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64)),
                UserId = user.Id,
                Expires = DateTime.UtcNow.AddDays(refreshTokenExpiryDays),
                IsRevoked = false,
                CreatedAt = DateTime.UtcNow,
                CreatedByUserId = user.Id
            };

            await _context.RefreshTokens.AddAsync(refreshToken);
            await _context.SaveChangesAsync();

            var isProduction = _env.IsProduction();


            _httpContextAccessor.HttpContext?.Response.Cookies.Append("refreshToken", refreshToken.Token, new CookieOptions
            {
                HttpOnly = true,
                Secure = isProduction,
                SameSite = isProduction
                ? SameSiteMode.Strict
                : SameSiteMode.Lax,
                Expires = refreshToken.Expires
            });


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

            var storedToken = await _context.RefreshTokens.FirstOrDefaultAsync(rt => rt.Token == refreshToken && rt.UserId == userId && !rt.IsRevoked);


            if (storedToken != null)
            {
                storedToken.IsRevoked = true;
                storedToken.RevokedAt = DateTime.UtcNow;
                storedToken.UpdatedAt = DateTime.UtcNow;
                storedToken.UpdatedByUserId = userId;
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
            return userId ?? throw new UnauthorizedException();
        }

        public async Task<UserDTO> GetMyProfile()
        {

            var userId = GetCurrentUserId();

             if (string.IsNullOrEmpty(userId))
                 throw new UnauthorizedException();

            var user = await _context.Users
                .Include(u => u.Address) 
                .FirstOrDefaultAsync(u => u.Id == userId);

            if (user == null) throw new Exception("User not found");
            if (user.IsBanned)
            {
                throw new UserException("ACCOUNT_BANNED"); 
            }

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

            var frontendUrl = Environment.GetEnvironmentVariable("AppSettings__FrontendUrl") ?? _configuration["AppSettings:FrontendUrl"];

            var token = await _userManager.GeneratePasswordResetTokenAsync(user);
                var resetLink = $"{frontendUrl}/#/reset-password?token={Uri.EscapeDataString(token)}&email={Uri.EscapeDataString(user.Email)}";

           await _emailService.SendResetPasswordEmail(user.Email, resetLink, cancellationToken);
        }

        public async Task<IdentityResult> ResetPasswordAsync(ResetPasswordRequest model)
        {
            var user = await _userManager.FindByEmailAsync(model.Email);
            if (user == null)
                return IdentityResult.Failed(new IdentityError { Description = "User not found." });
            var result = await _userManager.ResetPasswordAsync(user, model.Token, model.NewPassword);
            return result;

        }

        public bool IsInRole(string role)
        {
            return _httpContextAccessor.HttpContext?.User?.IsInRole(role) ?? false;
        }

        public async Task<LoginResponseDto?> RefreshTokenAsync()
        {
            var refreshTokenValue = _httpContextAccessor.HttpContext?.Request.Cookies["refreshToken"];
            if (string.IsNullOrEmpty(refreshTokenValue))
                throw new UserException("Refresh token not found.");

            var storedToken = await _context.RefreshTokens
                .Include(rt => rt.User)
                .FirstOrDefaultAsync(rt => rt.Token == refreshTokenValue);

            if (storedToken == null || !storedToken.IsActive)
                throw new UserException("Invalid or expired refresh token.");

            var user = storedToken.User;
            var roles = await _userManager.GetRolesAsync(user);

            var claims = new List<Claim>
    {
        new Claim(ClaimTypes.NameIdentifier, user.Id),
        new Claim(ClaimTypes.Email, user.Email),
        new Claim(ClaimTypes.Name, user.UserName),
        new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
    };

            foreach (var role in roles)
                claims.Add(new Claim(ClaimTypes.Role, role));

            var newJwtToken = GenerateJwtToken(user, claims);

            storedToken.IsRevoked = true;
            storedToken.RevokedAt = DateTime.UtcNow;
            storedToken.UpdatedAt = DateTime.UtcNow;
            storedToken.UpdatedByUserId = user.Id;

            var refreshTokenExpiryDays = int.Parse(_config["Jwt:RefreshTokenExpiryDays"] ?? "7");
            var newRefreshToken = new RefreshToken
            {
                Token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64)),
                UserId = user.Id,
                Expires = DateTime.UtcNow.AddDays(refreshTokenExpiryDays),
                IsRevoked = false,
                CreatedAt = DateTime.UtcNow,
                CreatedByUserId = user.Id
            };

            await _context.RefreshTokens.AddAsync(newRefreshToken);
            await _context.SaveChangesAsync();

            _httpContextAccessor.HttpContext?.Response.Cookies.Append("refreshToken", newRefreshToken.Token, new CookieOptions
            {
                HttpOnly = true,
                Secure = true,
                SameSite = SameSiteMode.Strict,
                Expires = newRefreshToken.Expires
            });

            return new LoginResponseDto
            {
                Token = newJwtToken,
                ExpiresAt = DateTime.UtcNow.AddMinutes(int.Parse(_config["Jwt:ExpiresInMinutes"]))
            };
        }

    }
}
