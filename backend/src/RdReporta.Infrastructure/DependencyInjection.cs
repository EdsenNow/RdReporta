using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using RdReporta.Application.Common.Interfaces;
using RdReporta.Application.Services;
using RdReporta.Infrastructure.Persistence;
using RdReporta.Infrastructure.Security;
using RdReporta.Infrastructure.Services;

namespace RdReporta.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructureServices(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? configuration["DATABASE_URL"];
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "ConnectionStrings:DefaultConnection o DATABASE_URL debe configurarse fuera del repositorio.");
        }

        connectionString = NormalizeConnectionString(connectionString);

        services.AddDbContext<ApplicationDbContext>(options =>
        {
            options.UseNpgsql(connectionString, npgsqlOptions =>
            {
                npgsqlOptions.UseNetTopologySuite();
                npgsqlOptions.MigrationsAssembly(typeof(ApplicationDbContext).Assembly.FullName);
            });
        });

        services.AddScoped<IApplicationDbContext>(provider => provider.GetRequiredService<ApplicationDbContext>());

        // Security & Services
        services.AddSingleton<IPasswordHasher, PasswordHasher>();
        services.AddSingleton<IJwtTokenService, JwtTokenService>();
        services.AddHttpClient<IAppleAuthService, AppleAuthService>();

        services.Configure<S3StorageOptions>(configuration.GetSection(S3StorageOptions.SectionName));
        var storageProvider = configuration["Storage:Provider"];
        if (string.Equals(storageProvider, "S3", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(storageProvider, "R2", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(storageProvider, "Cloud", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(storageProvider, "Cloudflare", StringComparison.OrdinalIgnoreCase))
        {
            services.AddSingleton<IStorageService, S3StorageService>();
        }
        else
        {
            services.AddScoped<IStorageService, LocalStorageService>();
        }

        services.AddHostedService<PushNotificationWorker>();

        // Application Services
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IPostService, PostService>();
        services.AddScoped<ICategoryService, CategoryService>();
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<IModerationService, ModerationService>();

        return services;
    }

    private static string NormalizeConnectionString(string raw)
    {
        if (raw.StartsWith("postgres://", StringComparison.OrdinalIgnoreCase) ||
            raw.StartsWith("postgresql://", StringComparison.OrdinalIgnoreCase))
        {
            var uri = new Uri(raw);
            var userInfo = uri.UserInfo.Split(':', 2);
            var username = userInfo.Length > 0 ? Uri.UnescapeDataString(userInfo[0]) : "postgres";
            var password = userInfo.Length > 1 ? Uri.UnescapeDataString(userInfo[1]) : "";
            var database = uri.AbsolutePath.TrimStart('/');
            var port = uri.Port > 0 ? uri.Port : 5432;
            return $"Host={uri.Host};Port={port};Database={database};Username={username};Password={password};SSL Mode=Prefer;Trust Server Certificate=true";
        }
        return raw;
    }
}
