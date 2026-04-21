FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .	

RUN dotnet restore "TenderGo.Api/TenderGo.Api.csproj"

FROM build AS publish
WORKDIR "/src/TenderGo.Api" 
RUN dotnet publish "TenderGo.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

ENTRYPOINT ["dotnet", "TenderGo.Api.dll"]