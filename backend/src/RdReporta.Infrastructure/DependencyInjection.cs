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
        var connectionString = configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "ConnectionStrings:DefaultConnection debe configurarse fuera del repositorio.");
        }

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
}
