# Stage 1: restore & build
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy project files first for layer-cached restore
COPY ["src/Web/Web.csproj", "src/Web/"]
COPY ["src/ApplicationCore/ApplicationCore.csproj", "src/ApplicationCore/"]
COPY ["src/Infrastructure/Infrastructure.csproj", "src/Infrastructure/"]
RUN dotnet restore "src/Web/Web.csproj"

# Copy remaining source and build
COPY . .
WORKDIR /src/src/Web
RUN dotnet build "Web.csproj" -c Release -o /app/build --no-restore

# Stage 2: publish
FROM build AS publish
RUN dotnet publish "Web.csproj" -c Release -o /app/publish --no-restore

# Stage 3: runtime image
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
EXPOSE 5106
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Web.dll"]
