using ApplicationCore.Interfaces;
using ApplicationCore.Services;
using Infrastructure.Data;
using Infrastructure.Identity;
using Infrastructure.Logging;
using Infrastructure.Services;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.eShopWeb.Interfaces;
using Microsoft.eShopWeb.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Text;

namespace Microsoft.eShopWeb
{
    public class Startup
    {
        private IServiceCollection _services;
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        public void ConfigureDevelopmentServices(IServiceCollection services)
        {
            // use in-memory database
            ConfigureInMemoryDatabases(services);

            // use real database
            // ConfigureProductionServices(services);

            ConfigureServices(services);
        }

        private void ConfigureInMemoryDatabases(IServiceCollection services)
        {
            // use in-memory database
            services.AddDbContext<CatalogContext>(c =>
                c.UseInMemoryDatabase("Catalog"));

            // Add Identity DbContext
            services.AddDbContext<AppIdentityDbContext>(options =>
                options.UseInMemoryDatabase("Identity"));
        }

        public void ConfigureProductionServices(IServiceCollection services)
        {
            services.Configure<ForwardedHeadersOptions>(options =>
            {
                options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
                options.KnownNetworks.Clear();
                options.KnownProxies.Clear();
            });

            // Persist Data Protection keys to AWS Systems Manager Parameter Store
            services.AddDataProtection()
                .PersistKeysToAWSSystemsManager("/eShopWeb/DataProtection");

            // use real database
            services.AddDbContext<CatalogContext>(c =>
                c.UseNpgsql(Configuration.GetConnectionString("CatalogConnection"))
                 .ConfigureWarnings(w => w.Ignore(RelationalEventId.PendingModelChangesWarning)));

            // Add Identity DbContext
            services.AddDbContext<AppIdentityDbContext>(options =>
                options.UseNpgsql(Configuration.GetConnectionString("IdentityConnection"))
                       .ConfigureWarnings(w => w.Ignore(RelationalEventId.PendingModelChangesWarning)));

            ConfigureServices(services);
        }

        public void ConfigureServices(IServiceCollection services)
        {
            services.AddHealthChecks();
            
            services.AddIdentity<ApplicationUser, IdentityRole>()
                .AddEntityFrameworkStores<AppIdentityDbContext>()
                .AddDefaultTokenProviders();

            services.ConfigureApplicationCookie(options =>
            {
                options.Cookie.HttpOnly = true;
                options.ExpireTimeSpan = TimeSpan.FromHours(1);
                options.LoginPath = "/Account/Signin";
                options.LogoutPath = "/Account/Signout";
                options.Cookie = new CookieBuilder
                {
                    IsEssential = true // required for auth to work without explicit user consent; adjust to suit your privacy policy
                };
            });

            services.AddMvc(options => options.EnableEndpointRouting = false);

            services.AddScoped(typeof(IRepository<>), typeof(EfRepository<>));
            services.AddScoped(typeof(IAsyncRepository<>), typeof(EfRepository<>));

            services.AddScoped<ICatalogService, CachedCatalogService>();
            services.AddScoped<IBasketService, BasketService>();
            services.AddScoped<IBasketViewModelService, BasketViewModelService>();
            services.AddScoped<IOrderService, OrderService>();
            services.AddScoped<IOrderRepository, OrderRepository>();
            services.AddScoped<CatalogService>();
            services.Configure<CatalogSettings>(Configuration);
            services.AddSingleton<IUriComposer>(new UriComposer(Configuration.Get<CatalogSettings>()));

            services.AddScoped(typeof(IAppLogger<>), typeof(LoggerAdapter<>));
            services.AddTransient<IEmailSender, EmailSender>();

            // Add memory cache services
            services.AddMemoryCache();

            _services = services;
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app,
            IHostingEnvironment env)
        {
            app.UseForwardedHeaders();

            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
                ListAllRegisteredServices(app);
                app.UseHttpsRedirection();
            }
            else
            {
                app.UseExceptionHandler("/Catalog/Error");
                app.UseHsts();
            }

            app.UseStaticFiles();
            app.UseAuthentication();
            
            app.UseHealthChecks("/health");

            app.UseMvc();
        }

        private void ListAllRegisteredServices(IApplicationBuilder app)
        {
            app.Map("/allservices", builder => builder.Run(async context =>
            {
                var sb = new StringBuilder();
                sb.Append("<h1>All Services</h1>");
                sb.Append("<table><thead>");
                sb.Append("<tr><th>Type</th><th>Lifetime</th><th>Instance</th></tr>");
                sb.Append("</thead><tbody>");
                foreach (var svc in _services)
                {
                    sb.Append("<tr>");
                    sb.Append($"<td>{svc.ServiceType.FullName}</td>");
                    sb.Append($"<td>{svc.Lifetime}</td>");
                    sb.Append($"<td>{svc.ImplementationType?.FullName}</td>");
                    sb.Append("</tr>");
                }
                sb.Append("</tbody></table>");
                await context.Response.WriteAsync(sb.ToString());
            }));
        }
    }
}
