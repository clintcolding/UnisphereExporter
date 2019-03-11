# Unisphere Exporter

Prometheus exporter for VMAX Unisphere metrics built with PowerShell!

### Dependencies

[Polaris](https://github.com/PowerShell/Polaris) - A cross-platform, minimalist web framework for PowerShell.  
[NSSM](https://nssm.cc/download) - A service helper which doesn't suck.

### Configuration

- Update the `config.json` with the correct Unisphere API settings for your environment.
- The metrics which will be collected are defined in `metrics.json`

### Running as a Service

1. Clone this repo to `C:\Program Files\WindowsPowerShell\Modules`

```
Set-Location "C:\Program Files\WindowsPowerShell\Modules"
git clone "https://gitlab.servevirtual.net/Platform/UnisphereExporter.git"
```

2. Copy the `StartListener.ps1` function to an unprotected folder such as `D:\Resources\UnisphereExporter`

```
Copy-Item -Path .\UnisphereExporter\StartListener.ps1 -Destination D:\Resources\UnisphereExporter\StartListener.ps1
```

3. Verify the paths in `CreateService.ps1` are correct based on where you've copied the source files

4. Setup as a service by running `CreateService.ps1`

5. Validate by locally browsing to [http://localhost:9183/metrics](http://localhost:9183/metrics)

### Contributions

[Clint Colding](https://gitlab.servevirtual.net/Colding) - Author