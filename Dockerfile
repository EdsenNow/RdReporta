# syntax=docker/dockerfile:1
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copiar csproj y restaurar dependencias de capas
COPY ["backend/src/RdReporta.Domain/RdReporta.Domain.csproj", "backend/src/RdReporta.Domain/"]
COPY ["backend/src/RdReporta.Application/RdReporta.Application.csproj", "backend/src/RdReporta.Application/"]
COPY ["backend/src/RdReporta.Infrastructure/RdReporta.Infrastructure.csproj", "backend/src/RdReporta.Infrastructure/"]
COPY ["backend/src/RdReporta.Api/RdReporta.Api.csproj", "backend/src/RdReporta.Api/"]

RUN dotnet restore "backend/src/RdReporta.Api/RdReporta.Api.csproj"

# Copiar el código fuente completo del backend
COPY backend/src/ backend/src/

# Compilar y publicar binarios optimizados en modo Release
WORKDIR "/src/backend/src/RdReporta.Api"
RUN dotnet publish "RdReporta.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Etapa final de producción (ASP.NET Core Runtime ligero)
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
EXPOSE 8080

ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "RdReporta.Api.dll"]
