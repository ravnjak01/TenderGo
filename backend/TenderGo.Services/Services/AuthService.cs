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
        private readonly IEmailService _emailService;
        private readonly IWebHostEnvironment _env;
        private readonly string _jwtKey;
        private readonly string _jwtIssuer;
        private readonly string _jwtAudience;
        private readonly int _jwtExpiresInMinutes;
        private readonly int _refreshTokenExpiryDays;
        public AuthService(UserManager<ApplicationUser> userManager, IConfiguration config, IHttpContextAccessor httpContextAccessor,
            TenderGoContext context, IMapper mapper, ILogger<AuthService> logger, IEmailService emailService
           ,IWebHostEnvironment env )
        {
            _logger = logger;
            _userManager = userManager;
            _config = config;
            _httpContextAccessor = httpContextAccessor;
            _context = context;
            _mapper = mapper;
            _emailService = emailService;
            _env=env;
            _jwtKey = _config["Jwt:Key"]
                ?? throw new InvalidOperationException("JWT Key is missing.");

            _jwtIssuer = _config["Jwt:Issuer"]
                ?? throw new InvalidOperationException("JWT Issuer is missing.");

            _jwtAudience = _config["Jwt:Audience"]
                ?? throw new InvalidOperationException("JWT Audience is missing.");

            _jwtExpiresInMinutes =
                int.Parse(_config["Jwt:ExpiresInMinutes"] ?? "60");

            _refreshTokenExpiryDays =
                int.Parse(_config["Jwt:RefreshTokenExpiryDays"] ?? "7");
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
                var errors = result.Errors
                 .GroupBy(e => e.Code)
                 .ToDictionary(
                     g => g.Key,
                     g => g.Select(e => e.Description).ToArray());
                throw new ValidationException(errors);
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
                _logger.LogWarning("Login blocked: User {Email} is banned.", dto.Email);
                throw new ForbiddenException("Your account is banned");
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

            var refreshToken = new RefreshToken
            {
                Token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64)),
                UserId = user.Id,
                Expires = DateTime.UtcNow.AddDays(_refreshTokenExpiryDays),
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
                RefreshToken = refreshToken.Token,
                ExpiresAt = DateTime.UtcNow.AddMinutes(_jwtExpiresInMinutes)
            };



        }

        public async Task LogoutAsync()
        {
            var refreshToken = _httpContextAccessor.HttpContext?.Request.Cookies["refreshToken"];

            if (string.IsNullOrEmpty(refreshToken))
                throw new UnauthorizedException("Refresh token is missing.");

            var userId = _httpContextAccessor.HttpContext?.User?.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
                throw new UnauthorizedException("User is not authenticated.");

            var storedToken = await _context.RefreshTokens
                .FirstOrDefaultAsync(rt => rt.Token == refreshToken
                                        && rt.UserId == userId
                                        && !rt.IsRevoked);

            if (storedToken != null)
            {
                storedToken.IsRevoked = true;
                storedToken.RevokedAt = DateTime.UtcNow;
                storedToken.UpdatedAt = DateTime.UtcNow;
                storedToken.UpdatedByUserId = userId;
            }

            var jti = _httpContextAccessor.HttpContext?.User
                ?.FindFirstValue(JwtRegisteredClaimNames.Jti);
            var expClaim = _httpContextAccessor.HttpContext?.User
                ?.FindFirstValue(JwtRegisteredClaimNames.Exp);

            if (!string.IsNullOrWhiteSpace(jti) && !string.IsNullOrWhiteSpace(expClaim))
            {
                if (long.TryParse(expClaim, out var expUnix))
                {
                    var expiresAt = DateTimeOffset.FromUnixTimeSeconds(expUnix).UtcDateTime;

                    var alreadyRevoked = await _context.RevokedTokens.AnyAsync(x => x.Jti == jti);
                    if (!alreadyRevoked)
                    {
                        _context.RevokedTokens.Add(new RevokedToken
                        {
                            Jti = jti,
                            UserId = userId,
                            RevokedAt = DateTime.UtcNow,
                            ExpiresAt = expiresAt
                        });
                    }
                }

               
            }

            await _context.SaveChangesAsync();

            _httpContextAccessor.HttpContext?.Response.Cookies.Delete("refreshToken", new CookieOptions
            {
                HttpOnly = true,
                Secure = true,
                SameSite = SameSiteMode.Strict,
            });
        }

        public string GenerateJwtToken(
                     ApplicationUser user,
                     IEnumerable<Claim> claims)
        {
            if (_jwtKey.Length < 32)
            {
                _logger.LogCritical(
                    "JWT Key is too short. Minimum 32 characters required.");

                throw new InvalidOperationException(
                    "Server configuration error: Security key is invalid.");
            }

            var key = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(_jwtKey));

            var creds = new SigningCredentials(
                key,
                SecurityAlgorithms.HmacSha256);

            var token = new JwtSecurityToken(
                issuer: _jwtIssuer,
                audience: _jwtAudience,
                claims: claims,
                notBefore: DateTime.UtcNow,
                expires: DateTime.UtcNow.AddMinutes(_jwtExpiresInMinutes),
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

            var user = await _context.Users
                .Include(u => u.Address) 
                .FirstOrDefaultAsync(u => u.Id == userId);

            if (user == null) throw new Exception("User not found");
            if (user.IsBanned)
            {
                throw new UserException("Your account is banned"); 
            }

            var roles = await _userManager.GetRolesAsync(user);

            var response = _mapper.Map<UserDTO>(user);
            response.Roles = roles.ToList();

            return response;
        }

 
public async Task ForgotPasswordAsync(ForgotPasswordRequest model, CancellationToken cancellationToken)
{
    var user = await _userManager.FindByEmailAsync(model.Email);

    if (user == null)
    {
        _logger.LogWarning($"Reset attempt for non-existing email: {model.Email}");
        return;
    }

    var activeOldCodes = await _context.PasswordResetCodes
        .Where(x => x.UserId == user.Id && !x.IsUsed && !x.IsInvalidated)
        .ToListAsync(cancellationToken);

    foreach (var oldCode in activeOldCodes)
    {
        oldCode.IsInvalidated = true;
    }

    var plainCode = RandomNumberGenerator.GetInt32(100000, 999999).ToString();

    var saltBytes = RandomNumberGenerator.GetBytes(16);

    var hashedBytes = HashCodePbkdf2(plainCode, saltBytes);

    var resetCode = new PasswordResetCode
    {
        UserId = user.Id,
        Code = Convert.ToBase64String(hashedBytes), 
        Salt = Convert.ToBase64String(saltBytes),
        CreatedAt = DateTime.UtcNow,
        ExpiryTime = DateTime.UtcNow.AddMinutes(10),
        IsUsed = false,
        IsInvalidated = false,
        Attempts = 0 
    };

    await _context.PasswordResetCodes.AddAsync(resetCode, cancellationToken);
    await _context.SaveChangesAsync(cancellationToken);

    var message = $"Your password reset code is: {plainCode}. It is valid for 10 minutes.";
    await _emailService.SendResetPasswordEmail(user.Email, message, cancellationToken);
}

private byte[] HashCodePbkdf2(string input, byte[] salt)
{
    const int iterations = 100_000; 
    const int hashLength = 32;      

    return Rfc2898DeriveBytes.Pbkdf2(
        input, 
        salt, 
        iterations, 
        HashAlgorithmName.SHA256, 
        hashLength
    );
}

public async Task<IdentityResult> ResetPasswordAsync(ResetPasswordRequest model)
{
    var user = await _userManager.FindByEmailAsync(model.Email);

    if (user == null)
        return IdentityResult.Failed(new IdentityError { Description = "User not found." });

    var resetRecord = await _context.PasswordResetCodes
        .Where(x => x.UserId == user.Id && !x.IsUsed && !x.IsInvalidated)
        .OrderByDescending(x => x.CreatedAt) 
        .FirstOrDefaultAsync();

    if (resetRecord == null)
        return IdentityResult.Failed(new IdentityError { Description = "Invalid code." });

    if (resetRecord.Attempts >= 3)
    {
        resetRecord.IsInvalidated = true; 
        await _context.SaveChangesAsync();
        return IdentityResult.Failed(new IdentityError { Description = "Code locked due to too many failed attempts." });
    }

    if (resetRecord.ExpiryTime < DateTime.UtcNow)
        return IdentityResult.Failed(new IdentityError { Description = "Code expired." });

    var saltBytes = Convert.FromBase64String(resetRecord.Salt);
    var verificationHash = HashCodePbkdf2(model.Code, saltBytes); 

    var isCorrect = CryptographicOperations.FixedTimeEquals(
        verificationHash, 
        Convert.FromBase64String(resetRecord.Code)
    );

    if (!isCorrect)
    {
        resetRecord.Attempts++;
        await _context.SaveChangesAsync();
        return IdentityResult.Failed(new IdentityError { Description = "Invalid code." });
    }

    var token = await _userManager.GeneratePasswordResetTokenAsync(user);
    var result = await _userManager.ResetPasswordAsync(user, token, model.NewPassword);

    if (result.Succeeded)
    {
        resetRecord.UsedAt = DateTime.UtcNow;
        resetRecord.IsUsed = true;
        await _context.SaveChangesAsync();
    }

    return result;
}

        public bool IsInRole(string role)
        {
            return _httpContextAccessor.HttpContext?.User?.IsInRole(role) ?? false;
        }

        public async Task<LoginResponseDto?> RefreshTokenAsync(string? refreshToken = null)
        {
            var refreshTokenValue = !string.IsNullOrWhiteSpace(refreshToken)
                ? refreshToken
                : _httpContextAccessor.HttpContext?.Request.Cookies["refreshToken"];
            if (string.IsNullOrEmpty(refreshTokenValue))
                throw new UserException("Refresh token not found.");

            var storedToken = await _context.RefreshTokens
                .Include(rt => rt.User)
                .FirstOrDefaultAsync(rt => rt.Token == refreshTokenValue);

            if (storedToken == null || !storedToken.IsActive)
                throw new UserException("Invalid or expired refresh token.");

            var user = storedToken.User;
            if(user == null || user.IsBanned || await _userManager.IsLockedOutAsync(user))
            {
                throw new UnauthorizedAccessException("Korisnički nalog je banovan ili onemogućen.");
            }
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

            var newRefreshToken = new RefreshToken
            {
                Token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64)),
                UserId = user.Id,
                Expires = DateTime.UtcNow.AddDays(_refreshTokenExpiryDays),
                IsRevoked = false,
                CreatedAt = DateTime.UtcNow,
                CreatedByUserId = user.Id
            };

            await _context.RefreshTokens.AddAsync(newRefreshToken);
            await _context.SaveChangesAsync();

            var isProduction = _env.IsProduction();

            _httpContextAccessor.HttpContext?.Response.Cookies.Append("refreshToken", newRefreshToken.Token, new CookieOptions
            {
                HttpOnly = true,
                Secure = isProduction,
                SameSite = isProduction ? SameSiteMode.Strict : SameSiteMode.Lax,
                Expires = newRefreshToken.Expires
            });

            return new LoginResponseDto
            {
                Token = newJwtToken,
                RefreshToken = newRefreshToken.Token,
                ExpiresAt = DateTime.UtcNow.AddMinutes(_jwtExpiresInMinutes)
            };
        }

    }
}
