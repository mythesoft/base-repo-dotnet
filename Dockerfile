FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build-env
WORKDIR /source

# Copy everything
COPY . ./
# Restore as distinct layers
RUN dotnet restore
# Build and publish a release
RUN dotnet publish -c Release -o published

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:7.0 as runtime
WORKDIR /app
COPY --from=build-env /source/published .

# Criar e configurar o script de entrada (entrypoint)
RUN echo "dotnet DotNet.Docker.dll" >> entrypoint.sh \
    && chmod a+x entrypoint.sh

ENTRYPOINT ["sh", "entrypoint.sh"]