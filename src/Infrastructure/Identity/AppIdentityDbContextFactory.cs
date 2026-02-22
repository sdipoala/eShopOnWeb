using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Infrastructure.Identity
{
    public class AppIdentityDbContextFactory : IDesignTimeDbContextFactory<AppIdentityDbContext>
    {
        public AppIdentityDbContext CreateDbContext(string[] args)
        {
            var optionsBuilder = new DbContextOptionsBuilder<AppIdentityDbContext>();
            optionsBuilder.UseNpgsql("Host=localhost;Database=eshop_identity;Username=postgres;Password=postgres");

            return new AppIdentityDbContext(optionsBuilder.Options);
        }
    }
}
