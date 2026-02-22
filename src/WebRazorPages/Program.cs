using System;
using Microsoft.AspNetCore;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Logging;
using Infrastructure.Data;
using Infrastructure.Identity;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Npgsql;

namespace Microsoft.eShopWeb.RazorPages
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var host = CreateWebHostBuilder(args)
                        .Build();

            using (var scope = host.Services.CreateScope())
            {
                var services = scope.ServiceProvider;
                var loggerFactory = services.GetRequiredService<ILoggerFactory>();
                var logger = loggerFactory.CreateLogger<Program>();
                try
                {
                    var configuration = services.GetRequiredService<IConfiguration>();
                    
                    // Ensure databases exist before EF tries to connect
                    logger.LogInformation("Ensuring catalog database exists...");
                    var catalogConnectionString = configuration.GetConnectionString("CatalogConnection");
                    EnsureDatabase(catalogConnectionString);
                    logger.LogInformation("Catalog database ready.");
                    
                    logger.LogInformation("Ensuring identity database exists...");
                    var identityConnectionString = configuration.GetConnectionString("IdentityConnection");
                    EnsureDatabase(identityConnectionString);
                    logger.LogInformation("Identity database ready.");
                    
                    // Now run migrations
                    logger.LogInformation("Running catalog migrations...");
                    var catalogContext = services.GetRequiredService<CatalogContext>();
                    catalogContext.Database.Migrate();
                    logger.LogInformation("Catalog migrations complete.");
                    
                    logger.LogInformation("Running identity migrations...");
                    var identityContext = services.GetRequiredService<AppIdentityDbContext>();
                    identityContext.Database.Migrate();
                    logger.LogInformation("Identity migrations complete.");
                    
                    logger.LogInformation("Seeding catalog data...");
                    CatalogContextSeed.SeedAsync(catalogContext, loggerFactory)
            .Wait();
                    logger.LogInformation("Catalog data seeded.");

                    logger.LogInformation("Seeding identity data...");
                    var userManager = services.GetRequiredService<UserManager<ApplicationUser>>();
                    AppIdentityDbContextSeed.SeedAsync(userManager).Wait();
                    logger.LogInformation("Identity data seeded.");
                }
                catch (Exception ex)
                {
                    logger.LogError(ex, "An error occurred seeding the DB.");
                }
            }

            host.Run();
        }

        public static IWebHostBuilder CreateWebHostBuilder(string[] args) =>
            WebHost.CreateDefaultBuilder(args)
                .UseUrls("http://0.0.0.0:5107")
                .UseStartup<Startup>();

        private static void EnsureDatabase(string connectionString)
        {
            var builder = new NpgsqlConnectionStringBuilder(connectionString);
            var targetDatabase = builder.Database;
            builder.Database = "postgres";

            using var conn = new NpgsqlConnection(builder.ConnectionString);
            conn.Open();
            using var cmd = conn.CreateCommand();
            cmd.CommandText = $"SELECT 1 FROM pg_database WHERE datname = '{targetDatabase}'";
            var exists = cmd.ExecuteScalar() != null;
            if (!exists)
            {
                cmd.CommandText = $"CREATE DATABASE \"{targetDatabase}\"";
                cmd.ExecuteNonQuery();
            }
        }
    }
}
