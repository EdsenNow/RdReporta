using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using RdReporta.Application.Common.Interfaces;
using RdReporta.Domain.Entities;
using RdReporta.Domain.Enums;

namespace RdReporta.Infrastructure.Persistence;

public static class DbInitializer
{
    public static async Task UpgradeSchemaAsync(ApplicationDbContext context)
    {
        if (!context.Database.IsNpgsql()) return;

        await context.Database.ExecuteSqlRawAsync("""
            CREATE TABLE IF NOT EXISTS "PostViews" (
                "PostId" uuid NOT NULL REFERENCES "Posts"("Id") ON DELETE CASCADE,
                "UserId" uuid NOT NULL REFERENCES "Users"("Id") ON DELETE CASCADE,
                "ViewedAt" timestamp with time zone NOT NULL,
                CONSTRAINT "PK_PostViews" PRIMARY KEY ("PostId", "UserId"));
            CREATE INDEX IF NOT EXISTS "IX_PostViews_UserId" ON "PostViews" ("UserId");
            """);

        await context.Database.ExecuteSqlRawAsync(
            "ALTER TABLE \"Users\" ADD COLUMN IF NOT EXISTS \"DisplayName\" character varying(80) NOT NULL DEFAULT ''; " +
            "ALTER TABLE \"Users\" ADD COLUMN IF NOT EXISTS \"UsernameChangedAt\" timestamp with time zone NULL; " +
            "ALTER TABLE \"Users\" ADD COLUMN IF NOT EXISTS \"PasswordResetCode\" character varying(10) NULL; " +
            "ALTER TABLE \"Users\" ADD COLUMN IF NOT EXISTS \"PasswordResetExpiresAt\" timestamp with time zone NULL; " +
            "ALTER TABLE \"Posts\" ADD COLUMN IF NOT EXISTS \"Neighborhood\" character varying(100) NULL; " +
            "ALTER TABLE \"Posts\" ADD COLUMN IF NOT EXISTS \"VideoUrl\" character varying(1000) NULL; " +
            "ALTER TABLE \"Posts\" ALTER COLUMN \"Latitude\" DROP NOT NULL; " +
            "ALTER TABLE \"Posts\" ALTER COLUMN \"Longitude\" DROP NOT NULL; " +
            "ALTER TABLE \"Posts\" ALTER COLUMN \"LocationCoordinates\" DROP NOT NULL; " +
            "UPDATE \"Users\" SET \"DisplayName\" = \"Username\" WHERE \"DisplayName\" = '';"
        );
        await context.Database.ExecuteSqlRawAsync("""
            DROP TABLE IF EXISTS "PostConfirmations";
            ALTER TABLE "Posts" DROP COLUMN IF EXISTS "ConfirmationsCount";
            UPDATE "Users"
            SET "RefreshToken" = NULL, "RefreshTokenExpiryTime" = NULL
            WHERE "RefreshToken" IS NOT NULL
                AND (length("RefreshToken") <> 64 OR "RefreshToken" ~ '[^0-9A-F]');
            UPDATE "Users" SET "RefreshTokenExpiryTime" = NULL
            WHERE "RefreshToken" IS NOT NULL AND "RefreshTokenExpiryTime" > CURRENT_TIMESTAMP;
            """);
        await context.Database.ExecuteSqlRawAsync("""
            WITH ranked AS (
              SELECT "Id", row_number() OVER (
                PARTITION BY "PostId", "UserId" ORDER BY "CreatedAt" DESC, "Id") AS position
              FROM "PostReactions")
            DELETE FROM "PostReactions" AS reactions
            USING ranked
            WHERE reactions."Id" = ranked."Id" AND ranked.position > 1;
            UPDATE "Posts" AS posts
            SET "ReactionsCount" = (
              SELECT count(*) FROM "PostReactions" AS reactions WHERE reactions."PostId" = posts."Id");
            DROP INDEX IF EXISTS "IX_PostReactions_PostId_UserId_ReactionType";
            CREATE UNIQUE INDEX IF NOT EXISTS "IX_PostReactions_PostId_UserId"
              ON "PostReactions" ("PostId", "UserId");
            """);
        await context.Database.ExecuteSqlRawAsync("""
            DROP INDEX IF EXISTS "IX_Users_Username";
            WITH ranked AS (
              SELECT "Id", lower("Username") AS canonical,
                     row_number() OVER (PARTITION BY lower("Username") ORDER BY "CreatedAt", "Id") AS position
              FROM "Users"
            )
            UPDATE "Users" AS users
            SET "Username" = CASE
              WHEN ranked.position = 1 THEN ranked.canonical
              ELSE left(ranked.canonical, 17) || '_' || replace(ranked."Id"::text, '-', '')
            END
            FROM ranked
            WHERE users."Id" = ranked."Id"
              AND users."Username" <> CASE
                WHEN ranked.position = 1 THEN ranked.canonical
                ELSE left(ranked.canonical, 17) || '_' || replace(ranked."Id"::text, '-', '')
              END;
            CREATE UNIQUE INDEX IF NOT EXISTS "IX_Users_Username_Lower"
              ON "Users" (lower("Username"));
            """);
        await context.Database.ExecuteSqlRawAsync("""
            CREATE TABLE IF NOT EXISTS "UserFollows" (
              "FollowerId" uuid NOT NULL REFERENCES "Users"("Id") ON DELETE CASCADE,
              "FollowedId" uuid NOT NULL REFERENCES "Users"("Id") ON DELETE CASCADE,
              "CreatedAt" timestamp with time zone NOT NULL,
              CONSTRAINT "PK_UserFollows" PRIMARY KEY ("FollowerId", "FollowedId"));
            CREATE INDEX IF NOT EXISTS "IX_UserFollows_FollowedId" ON "UserFollows" ("FollowedId");
            CREATE TABLE IF NOT EXISTS "UserNotifications" (
              "Id" uuid NOT NULL, "UserId" uuid NOT NULL REFERENCES "Users"("Id") ON DELETE CASCADE,
              "ActorUserId" uuid NOT NULL, "PostId" uuid NULL, "Type" character varying(30) NOT NULL,
              "Message" character varying(300) NOT NULL, "IsRead" boolean NOT NULL,
              "CreatedAt" timestamp with time zone NOT NULL, CONSTRAINT "PK_UserNotifications" PRIMARY KEY ("Id"));
            CREATE INDEX IF NOT EXISTS "IX_UserNotifications_UserId_IsRead_CreatedAt" ON "UserNotifications" ("UserId", "IsRead", "CreatedAt");
            CREATE TABLE IF NOT EXISTS "DeviceRegistrations" (
              "Id" uuid NOT NULL, "UserId" uuid NOT NULL REFERENCES "Users"("Id") ON DELETE CASCADE,
              "Token" character varying(500) NOT NULL, "Platform" character varying(20) NOT NULL,
              "UpdatedAt" timestamp with time zone NOT NULL, CONSTRAINT "PK_DeviceRegistrations" PRIMARY KEY ("Id"));
            CREATE UNIQUE INDEX IF NOT EXISTS "IX_DeviceRegistrations_Token" ON "DeviceRegistrations" ("Token");
            """);
        await context.Database.ExecuteSqlRawAsync("""
            CREATE TABLE IF NOT EXISTS "PushDeliveries" (
              "Id" uuid PRIMARY KEY,
              "NotificationId" uuid NOT NULL REFERENCES "UserNotifications"("Id") ON DELETE CASCADE,
              "DeviceRegistrationId" uuid NOT NULL REFERENCES "DeviceRegistrations"("Id") ON DELETE CASCADE,
              "Attempts" integer NOT NULL DEFAULT 0,
              "NextAttemptAt" timestamp with time zone NOT NULL,
              "CompletedAt" timestamp with time zone NULL);
            CREATE UNIQUE INDEX IF NOT EXISTS "IX_PushDeliveries_NotificationId_DeviceRegistrationId"
              ON "PushDeliveries" ("NotificationId", "DeviceRegistrationId");
            CREATE INDEX IF NOT EXISTS "IX_PushDeliveries_NextAttemptAt"
              ON "PushDeliveries" ("NextAttemptAt") WHERE "CompletedAt" IS NULL;
            """);
    }

    public static async Task SeedAsync(
        ApplicationDbContext context,
        IPasswordHasher passwordHasher,
        IConfiguration configuration)
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
        var adminEmail = configuration["SeedAdmin:Email"];
        var adminPassword = configuration["SeedAdmin:Password"];
        if (!string.IsNullOrWhiteSpace(adminEmail)
            && !string.IsNullOrWhiteSpace(adminPassword)
            && !await context.Users.AnyAsync(u => u.Email == adminEmail))
        {
            var adminRole = await context.Roles.FirstAsync(r => r.Name == "Administrador");
            var adminUser = new User
            {
                Id = Guid.NewGuid(),
                Username = "admin_rdreporta",
                DisplayName = "Administrador RDReporta",
                Email = adminEmail.Trim().ToLowerInvariant(),
                PasswordHash = passwordHasher.Hash(adminPassword),
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
