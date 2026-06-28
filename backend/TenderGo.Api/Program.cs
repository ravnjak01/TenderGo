using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using AutoMapper;
using DotNetEnv;
using EasyNetQ;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using QuestPDF.Infrastructure;
using TenderGo.Api.Database;
using TenderGo.Api.Filters;
using TenderGo.Data;
using TenderGo.Data.Seeders;
using TenderGo.Models.Entities;
using TenderGo.Recommender;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Mapping;
using TenderGo.Services.Services;
using TenderGo.Services.Services.Seed;
using TenderGo.Services.StateMachines.BidStates;
using TenderGo.Services.StateMachines.TenderStates;

var builder = WebApplication.CreateBuilder(args);
QuestPDF.Settings.License = LicenseType.Community;

Env.Load();

static string BuildRabbitMqConnectionString(IConfiguration config)
{
    var configuredConnectionString = config.GetConnectionString("RabbitMQ");
    if (!string.IsNullOrWhiteSpace(configuredConnectionString))
    {
        return configuredConnectionString;
    }

    var host = Environment.GetEnvironmentVariable("RabbitMQ__Host")
               ?? config["RabbitMQ:Host"]
               ?? "localhost";
    var username = Environment.GetEnvironmentVariable("RabbitMQ__Username")
                   ?? config["RabbitMQ:Username"]
                   ?? "guest";
    var password = Environment.GetEnvironmentVariable("RabbitMQ__Password")
                   ?? config["RabbitMQ:Password"]
                   ?? "guest";

    return $"host={host};username={username};password={password};timeout=30";
}

// 1. Konfiguracija baze podataka
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

// 3. Autentifikacija i JWT konfiguracija
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
        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!))
    };

    options.Events = new JwtBearerEvents
    {
        OnTokenValidated = async context =>
        {
            var db = context.HttpContext.RequestServices
                .GetRequiredService<TenderGoContext>();

            var jti = context.Principal?
                .FindFirstValue(JwtRegisteredClaimNames.Jti);

            if (string.IsNullOrWhiteSpace(jti))
            {
                context.Fail("Token does not contain JTI.");
                return;
            }

            var isRevoked = await db.RevokedTokens
                .AnyAsync(x => x.Jti == jti);

            if (isRevoked)
            {
                context.Fail("Token has been revoked.");
            }
        }
    };
});

// 4. Registracija API servisa i Swagger-a
builder.Services.AddControllers(x => x.Filters.Add<ErrorFilter>());
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(opt =>
{
    opt.SwaggerDoc("v1", new OpenApiInfo { Title = "TenderGo API", Version = "v1" });
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
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            Array.Empty<string>()
        }
    });
});


builder.Services.Configure<IdentityOptions>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequireLowercase = true;
    options.Password.RequireUppercase = true;
    options.Password.RequireNonAlphanumeric = true;
    options.Password.RequiredLength = 8;
});


builder.Services.AddHttpContextAccessor();
builder.Services.AddMemoryCache();

// 5. Registracija Custom Servisa i Infrastrukture
builder.Services.AddAutoMapper(typeof(MappingProfile));
builder.Services.AddScoped(typeof(IBaseService<,,,>), typeof(BaseService<,,,>));
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<ITenderService, TenderService>();
builder.Services.AddScoped<ITenderAdminService, TenderAdminService>();
builder.Services.AddScoped<IBidService, BidService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IUserAdminService, UserAdminService>();
builder.Services.AddScoped<IAdminDashboardService, AdminDashboardService>();
builder.Services.AddScoped<IImageService, ImageService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<ILocationService, LocationService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IAdminReportService,AdminReportService>();


// Email i Background poslovi
builder.Services.Configure<EmailSettings>(builder.Configuration.GetSection("EmailSettings"));
builder.Services.AddScoped<IEmailService,EmailService>();
builder.Services.AddHostedService<TenderExpiryJob>();

// Recommender i Pametni moduli
builder.Services.AddTransient<RecommenderService>();
builder.Services.AddTransient<TenderVectorBuilder>();
builder.Services.AddScoped<IRecommendationService, RecommendationService>();

// State Machine registracije
builder.Services.AddScoped<BaseState>();
builder.Services.AddScoped<OpenTenderState>();
builder.Services.AddScoped<ClosedTenderState>();
builder.Services.AddScoped<AwardedTenderState>();
builder.Services.AddScoped<CancelledTenderState>();
builder.Services.AddScoped<PendingBidState>();
builder.Services.AddScoped<FinalBidState>();

// 6. RabbitMQ i CORS konfiguracija
var rabbitConnectionString = BuildRabbitMqConnectionString(builder.Configuration);

builder.Services.AddEasyNetQ(rabbitConnectionString).UseSystemTextJson();

var allowedOriginsRaw = builder.Configuration["ALLOWED_ORIGINS"]
                        ?? Environment.GetEnvironmentVariable("ALLOWED_ORIGINS");

var allowedOrigins = allowedOriginsRaw?
    .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
    ?? new[] { "http://localhost:3000" }; 

builder.Services.AddCors(options =>
{
    options.AddPolicy("TenderGoPolicy", policy =>
        policy.WithOrigins(allowedOrigins)
              .AllowAnyHeader()
              .AllowAnyMethod());
});

var app = builder.Build();

app.UseStaticFiles();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "TenderGo API V1");
        c.RoutePrefix = "swagger";
    });
}
else
{
    app.UseHttpsRedirection();
    app.UseHsts();
}

app.UseCors("TenderGoPolicy");
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    var logger = services.GetRequiredService<ILogger<Program>>();

    for (int i = 0; i < 10; i++)
    {
        try
        {
            var context = services.GetRequiredService<TenderGoContext>();
            context.Database.Migrate();

            var seeders = new IDataSeeder[]
            {
                new IdentitySeeder(),
                new UserSeeder(),
                new LocationSeeder(),
                new CategorySeeder(),
                new TenderOpenSeeder(),
                new TenderImagesSeeder(),
                new TenderClosedSeeder(),
                new TenderAwardedSeeder(),
                new BidSeeder(),
                new RatingsSeeder(),
                new NotificationSeeder()
            };

            foreach (var seeder in seeders.OrderBy(s => s.Order))
            {
                await seeder.SeedAsync(context, services);
            }


            logger.LogInformation("Database migrated and seeded successfully.");
            break;
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Try {Attempt}: Database initialization failed. Waiting before retry.", i + 1);
            if (i == 9)
            {
                logger.LogError(ex, "Database migration failed after 10 attempts.");
                throw;
            }
            Thread.Sleep(5000);
        }
    }
}

app.Run();
