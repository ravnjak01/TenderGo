using EasyNetQ;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Reflection.Emit;
using System.Security.Claims;
using System.Text;
using TenderGo.Api.Database;
using TenderGo.Api.Filters;
using TenderGo.Api.Middleware;
using TenderGo.Data;
using TenderGo.Models.Entities;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services;
using TenderGo.Services.StateMachines.BidStates;
using TenderGo.Services.StateMachines.TenderStates;
using DotNetEnv;
using static System.Runtime.InteropServices.JavaScript.JSType;

var builder = WebApplication.CreateBuilder(args);

DotNetEnv.Env.Load();

// 1. Konfiguracija baze
var connectionString =
   builder.Configuration.GetConnectionString("DefaultConnection");

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
        RoleClaimType = ClaimTypes.Role,
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
builder.Services.AddControllers(x =>
{
    x.Filters.Add<ErrorFilter>();
}); 
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(opt =>
{
    opt.SwaggerDoc("v1", new OpenApiInfo { Title = "TenderGo API", Version = "v1" });

    // Dodajemo definiciju za Bearer Token
    opt.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        In = ParameterLocation.Header,
        Description = "Enter token in format: Bearer {your_token}",
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        BearerFormat = "JWT",
        Scheme = "bearer"
    });

    opt.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new string[]{}
        }
    });
});
builder.Services.AddHttpContextAccessor();
//  custom servisi
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddAutoMapper(AppDomain.CurrentDomain.GetAssemblies());
builder.Services.AddScoped<ITenderService, TenderService>();
builder.Services.AddScoped<IBidService, BidService>();
builder.Services.AddScoped(typeof(IBaseService<,,,>), typeof(BaseService<,,,>));
builder.Services.AddTransient<BaseState>();
builder.Services.AddTransient < InitialTenderState>() ;
builder.Services.AddTransient<OpenTenderState>();
builder.Services.AddTransient<ClosedTenderState>();
builder.Services.AddTransient<AwardedTenderState>();
builder.Services.AddTransient<CancelledTenderState>();
builder.Services.AddTransient<ArchivedTenderState>();


builder.Services.AddScoped<OpenBidState>();
builder.Services.AddScoped<FinalBidState>();

builder.Services.AddEasyNetQ("host=localhost");


//builder.Entity<Rating>()
//  .HasCheckConstraint("CK_Rating_Score", "Score BETWEEN 1 AND 5");



// --- OVDE SE ZAKLJUČAVAJU SERVISI ---
var app = builder.Build();
app.UseMiddleware<GlobalExceptionMiddleware>();



if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
app.UseSwaggerUI(c => {
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "TenderGo API V1");
    c.RoutePrefix = "swagger"; 
});

}

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers(); // Bez ovoga ruta /api/auth/register neće raditi

// Izmeni onaj blok u Program.cs
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    var logger = services.GetRequiredService<ILogger<Program>>();

    // Pokušaj 10 puta sa pauzom od 5 sekundi
    for (int i = 0; i < 10; i++)
    {
        try
        {
            var context = services.GetRequiredService<TenderGoContext>();
            context.Database.Migrate();
            await IdentitySeeder.SeedRolesAsync(services);
            logger.LogInformation("Database migrated and seeded successfully.");
            break; // Ako uspe, izađi iz petlje
        }
        catch (Exception ex)
        {
            logger.LogWarning($"Pokušaj {i + 1}: SQL Server još nije spreman... Čekam.");
            if (i == 9) // Ako je zadnji pokušaj, baci grešku
            {
                logger.LogError(ex, "Greška nakon 10 pokušaja.");
                throw;
            }
            Thread.Sleep(5000); // Sačekaj 5 sekundi pre novog pokušaja
        }
    }
}
   
app.Run();


   


