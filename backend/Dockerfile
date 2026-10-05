# syntax=docker/dockerfile:1
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY ["src/RdReporta.Domain/RdReporta.Domain.csproj", "src/RdReporta.Domain/"]
COPY ["src/RdReporta.Application/RdReporta.Application.csproj", "src/RdReporta.Application/"]
COPY ["src/RdReporta.Infrastructure/RdReporta.Infrastructure.csproj", "src/RdReporta.Infrastructure/"]
COPY ["src/RdReporta.Api/RdReporta.Api.csproj", "src/RdReporta.Api/"]

RUN dotnet restore "src/RdReporta.Api/RdReporta.Api.csproj"

COPY src/ src/

WORKDIR "/src/src/RdReporta.Api"
RUN dotnet publish "RdReporta.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
EXPOSE 8080

ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "RdReporta.Api.dll"]
