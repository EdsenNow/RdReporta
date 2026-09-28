using Microsoft.EntityFrameworkCore;
using RdReporta.Application.Common.Interfaces;
using RdReporta.Domain.Entities;
using RdReporta.Domain.Enums;

namespace RdReporta.Infrastructure.Persistence;

public static class DbInitializer
{
    public static async Task SeedAsync(ApplicationDbContext context, IPasswordHasher passwordHasher)
    {
        // 1. Seed Roles
        if (!await context.Roles.AnyAsync())
        {
            var roles = new List<Role>
            {
                new() { Name = "Ciudadano" },
                new() { Name = "Moderador" },
                new() { Name = "Administrador" },
                new() { Name = "Institucion" }
            };
            context.Roles.AddRange(roles);
            await context.SaveChangesAsync();
        }

        // 2. Seed Default Categories for Dominican Republic
        if (!await context.Categories.AnyAsync())
        {
            var categories = new List<Category>
            {
                new()
                {
                    Name = "Accidentes",
                    Slug = "accidentes",
                    Description = "Choques, colisiones o atropellamientos en vías públicas",
                    IconName = "car-crash",
                    ColorHex = "#E53935",
                    DisplayOrder = 1
                },
                new()
                {
                    Name = "Tránsito",
                    Slug = "transito",
                    Description = "Semáforos dañados, congestionamientos críticos o desvíos",
                    IconName = "traffic-light",
                    ColorHex = "#FB8C00",
                    DisplayOrder = 2
                },
                new()
                {
                    Name = "Calles y Vías",
                    Slug = "calles-vias",
                    Description = "Hoyos, derrumbes, asfaltado deteriorado o alcantarillas sin tapa",
                    IconName = "road",
                    ColorHex = "#FDD835",
                    DisplayOrder = 3
                },
                new()
                {
                    Name = "Inundaciones",
                    Slug = "inundaciones",
                    Description = "Acumulación de agua por lluvias, cañadas o ríos desbordados",
                    IconName = "water",
                    ColorHex = "#1E88E5",
                    DisplayOrder = 4
                },
                new()
                {
                    Name = "Basura y Desechos",
                    Slug = "basura",
                    Description = "Vertederos improvisados, falta de recogida o contaminación",
                    IconName = "trash-can",
                    ColorHex = "#8E24AA",
                    DisplayOrder = 5
                },
                new()
                {
                    Name = "Servicios Públicos",
                    Slug = "servicios-publicos",
                    Description = "Averías de tendido eléctrico, cortes prolongados o fugas de agua",
                    IconName = "power-plug",
                    ColorHex = "#00897B",
                    DisplayOrder = 6
                },
                new()
                {
                    Name = "Emergencias",
                    Slug = "emergencias",
                    Description = "Incendios, emergencias médicas o situaciones de riesgo inminente",
                    IconName = "ambulance",
                    ColorHex = "#D81B60",
                    DisplayOrder = 7
                },
                new()
                {
                    Name = "Comunidad",
                    Slug = "comunidad",
                    Description = "Iniciativas vecinales, quejas de ruido o necesidades comunales",
                    IconName = "account-group",
                    ColorHex = "#43A047",
                    DisplayOrder = 8
                },
                new()
                {
                    Name = "Acontecimientos",
                    Slug = "acontecimientos",
                    Description = "Eventos locales relevantes y noticias comunitarias al momento",
                    IconName = "newspaper",
                    ColorHex = "#3949AB",
                    DisplayOrder = 9
                }
            };

            context.Categories.AddRange(categories);
            await context.SaveChangesAsync();
        }

        // 3. Seed Default Admin User
        if (!await context.Users.AnyAsync(u => u.Email == "admin@rdreporta.do"))
        {
            var adminRole = await context.Roles.FirstAsync(r => r.Name == "Administrador");
            var adminUser = new User
            {
                Id = Guid.NewGuid(),
                Username = "admin_rdreporta",
                Email = "admin@rdreporta.do",
                PasswordHash = passwordHasher.Hash("Admin123!*"),
                Province = "Distrito Nacional",
                Municipality = "Santo Domingo",
                ReputationScore = 1000,
                ReputationLevel = ReputationLevel.ColaboradorConfiable,
                IsActive = true,
                IsVerified = true,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            adminUser.UserRoles.Add(new UserRole { User = adminUser, Role = adminRole });
            context.Users.Add(adminUser);
            await context.SaveChangesAsync();
        }
    }
}
