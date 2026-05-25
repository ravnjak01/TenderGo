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
using TenderGo.Models.Entities;
using TenderGo.Recommender;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Mapping;
using TenderGo.Services.Services;
using TenderGo.Services.StateMachines.BidStates;
using TenderGo.Services.StateMachines.TenderStates;

var builder = WebApplication.CreateBuilder(args);
// 🌟 DODAJ OVU LINIJU U Program.cs:
QuestPDF.Settings.License = LicenseType.Community;

// Učitavanje .env datoteke za Docker okruženje
Env.Load();

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
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!))
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

builder.Services.AddHttpContextAccessor();
builder.Services.AddMemoryCache();

// 5. Registracija Custom Servisa i Infrastrukture
builder.Services.AddAutoMapper(typeof(MappingProfile));
builder.Services.AddScoped(typeof(IBaseService<,,,>), typeof(BaseService<,,,>));
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<ITenderService, TenderService>();
builder.Services.AddScoped<IBidService, BidService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IAdminService, AdminService>();
builder.Services.AddScoped<IImageService, ImageService>();
builder.Services.AddTransient<ICategoryService, CategoryService>();
builder.Services.AddTransient<ILocationService, LocationService>();
builder.Services.AddScoped<INotificationService, NotificationService>();

// Email i Background poslovi
builder.Services.Configure<EmailSettings>(builder.Configuration.GetSection("EmailSettings"));
builder.Services.AddScoped<EmailService>();
builder.Services.AddHostedService<TenderExpiryJob>();

// Recommender i Pametni moduli
builder.Services.AddSingleton<RecommenderService>();
builder.Services.AddSingleton<TenderVectorBuilder>();

// State Machine registracije
builder.Services.AddTransient<BaseState>();
builder.Services.AddTransient<OpenTenderState>();
builder.Services.AddTransient<ClosedTenderState>();
builder.Services.AddTransient<AwardedTenderState>();
builder.Services.AddTransient<CancelledTenderState>();
builder.Services.AddScoped<PendingBidState>();
builder.Services.AddScoped<FinalBidState>();

// 6. RabbitMQ i CORS konfiguracija
// Čita "ConnectionStrings:RabbitMQ" iz appsettings/okruženja
var rabbitConnectionString = builder.Configuration.GetConnectionString("RabbitMQ") 
                             ?? "host=localhost;username=guest;password=guest;timeout=30";

builder.Services.AddEasyNetQ(rabbitConnectionString).UseSystemTextJson();

var allowedOrigins = builder.Configuration.GetSection("CorsSettings:AllowedOrigins").Get<string[]>();
builder.Services.AddCors(options =>
{
    options.AddPolicy("TenderGoPolicy", policy =>
    {
        policy.WithOrigins(allowedOrigins!)
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });
});

// --- HTTP PIPELINE SLUŽBENO POČINJE OVDJE ---
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

// 7. Migracije i Seeding baze podataka prilikom podizanja (Retry mehanizam)
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

            await IdentitySeeder.SeedRolesAndAdminAsync(services);

            logger.LogInformation("Database migrated and seeded successfully.");
            break;
        }
        catch (Exception ex)
        {
            logger.LogWarning($"Try {i + 1}: SQL Server still not ready... Waiting.");
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