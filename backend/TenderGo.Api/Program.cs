using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using TenderGo.Api.Database;
using TenderGo.Models.Entities;
using TenderGo.Services.Interfaces; 
using TenderGo.Services.Services;  

var builder = WebApplication.CreateBuilder(args);

// 1. Konfiguracija baze
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<TenderGoContext>(options => options.UseSqlServer(connectionString, b =>
{
    b.MigrationsAssembly("TenderGo.Services");
}));

// 2. Identity postavke
builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options =>
{
    options.Password.RequiredLength = 8;
    options.Password.RequireDigit = true;
    options.Password.RequireUppercase = true;
    options.Password.RequireNonAlphanumeric = false;
    options.User.RequireUniqueEmail = true;
    options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(5);
    options.Lockout.MaxFailedAccessAttempts = 5;
})
    .AddEntityFrameworkStores<TenderGoContext>()
    .AddDefaultTokenProviders();

// 3. Autentifikacija i JWT
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!))
    };
});

// 4. Registracija ostalih servisa (OBAVEZNO PRIJE builder.Build())
builder.Services.AddControllers(); // Ovo je neophodno za rad [ApiController] kontrolera
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

//  custom servisi
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddAutoMapper(AppDomain.CurrentDomain.GetAssemblies());

// --- OVDE SE ZAKLJUČAVAJU SERVISI ---
var app = builder.Build();

// 5. Middleware Pipeline (Redoslijed je bitan)
    app.UseSwagger();
app.UseSwaggerUI(c => {
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "TenderGo API V1");
    c.RoutePrefix = "swagger"; // Ovo osigurava da je na /swagger
});

app.UseHttpsRedirection();

//  da bi zaštita radila
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers(); // Bez ovoga ruta /api/auth/register neće raditi

app.Run();