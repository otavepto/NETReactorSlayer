param(
  [ValidateSet(
    "netframework",
    "win-x86", "win-x64", "win-arm64",
    "linux-x64", "linux-arm", "linux-arm64",
    "osx-x64"
  )]
  [string]$framework = 'netframework'
)

$ErrorActionPreference = 'Stop'

$configuration = 'Release'
# https://learn.microsoft.com/en-us/dotnet/standard/frameworks#latest-versions
$tfm = "net8.0"
$build_folder_prefix = "NETReactorSlayer"

function BuildNETFramework {
  Write-Host 'Building .NET Framework x86 and x64 binaries'
  dotnet build -o "bin\$configuration\$build_folder_prefix-netframework\" -v:m -c $configuration -p:TargetFrameworks=net481
  if ($LASTEXITCODE) { 
    Write-Host
    Write-Host ==========================
    Write-Host "THE BUILD OPERATION ENCOUNTERED AN ERROR. EXIT CODE: $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE 
  }
}

function BuildNETCore {
  param([string]$runtimeidentifier)

  Write-Host "Building .NET binaries, arch=$runtimeidentifier tfm=$tfm"
  dotnet publish -o "bin\$configuration\$build_folder_prefix-$runtimeidentifier\" NETReactorSlayer.CLI\NETReactorSlayer.CLI.csproj -v:m -c $configuration -f $tfm -r $runtimeidentifier --self-contained -p:IncludeNativeLibrariesForSelfExtract=true -p:PublishSingleFile=true -p:TargetFrameworks=$tfm
  if ($LASTEXITCODE) { 
    Write-Host
    Write-Host ==========================
    Write-Host "THE BUILD OPERATION ENCOUNTERED AN ERROR. EXIT CODE: $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE 
  }
}


if(($framework -eq 'netframework') -or ($framework -eq 'all')){
  BuildNETFramework
} else {
  BuildNETCore $framework
}

Write-Host
Write-Host ==========================
Write-Host "Done"
