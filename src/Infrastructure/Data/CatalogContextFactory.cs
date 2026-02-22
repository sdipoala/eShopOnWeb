using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Infrastructure.Data
{
    public class CatalogContextFactory : IDesignTimeDbContextFactory<CatalogContext>
    {
        public CatalogContext CreateDbContext(string[] args)
        {
            var optionsBuilder = new DbContextOptionsBuilder<CatalogContext>();
            optionsBuilder.UseNpgsql("Host=localhost;Database=eshop_catalog;Username=postgres;Password=postgres");

            return new CatalogContext(optionsBuilder.Options);
        }
    }
}
