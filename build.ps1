param(
  [ValidateSet(
    "netframework",
    "win-x86", "win-x64", "win-arm64",
    "linux-x64", "linux-arm", "linux-arm64",
    "osx-x64"
  )]
  [string]$framework = 'netframework',
  ${-no-msbuild}
)

$ErrorActionPreference = 'Stop'

$configuration = 'Release'
# https://learn.microsoft.com/en-us/dotnet/standard/frameworks#latest-versions
$tfm = "net8.0"

function BuildNETFramework {
  Write-Host 'Building .NET Framework x86 and x64 binaries'
  if (${-no-msbuild}) {
    dotnet build -o "bin\$configuration\netframework\" -v:m -c $configuration -p:TargetFrameworks=net481
    if ($LASTEXITCODE) { 
      Write-Host
      Write-Host ==========================
      Write-Host "THE BUILD OPERATION ENCOUNTERED AN ERROR. EXIT CODE: $LASTEXITCODE" -ForegroundColor Red
      exit $LASTEXITCODE 
    }
  }
  else {
    msbuild -p:OutputPath="..\bin\$configuration\netframework\" -v:m -m -restore -t:Build -p:Configuration=$configuration -p:TargetFrameworks=net481
    if ($LASTEXITCODE) { 
      Write-Host
      Write-Host ==========================
      Write-Host "THE BUILD OPERATION ENCOUNTERED AN ERROR. EXIT CODE: $LASTEXITCODE" -ForegroundColor Red
      exit $LASTEXITCODE 
    }
  }
}

function BuildNETCore {
  param([string]$runtimeidentifier)

  Write-Host "Building .NET binaries, arch=$runtimeidentifier tfm=$tfm"

  if (${-no-msbuild}) {
    dotnet publish -o "bin\$configuration\$runtimeidentifier\" NETReactorSlayer.CLI\NETReactorSlayer.CLI.csproj -v:m -c $configuration -f $tfm -r $runtimeidentifier --self-contained -p:IncludeNativeLibrariesForSelfExtract=true -p:PublishSingleFile=true -p:TargetFrameworks=$tfm
    if ($LASTEXITCODE) { 
      Write-Host
      Write-Host ==========================
      Write-Host "THE BUILD OPERATION ENCOUNTERED AN ERROR. EXIT CODE: $LASTEXITCODE" -ForegroundColor Red
      exit $LASTEXITCODE 
    }
  }
  else {
    msbuild -p:OutputPath="..\bin\$configuration\$runtimeidentifier\" NETReactorSlayer.CLI\NETReactorSlayer.CLI.csproj -v:m -m -restore -t:Publish -p:Configuration=$configuration -p:TargetFramework=$tfm -p:RuntimeIdentifier=$runtimeidentifier -p:SelfContained=True -p:IncludeNativeLibrariesForSelfExtract=true -p:PublishSingleFile=true -p:TargetFrameworks=$tfm
    if ($LASTEXITCODE) { 
      Write-Host
      Write-Host ==========================
      Write-Host "THE BUILD OPERATION ENCOUNTERED AN ERROR. EXIT CODE: $LASTEXITCODE" -ForegroundColor Red
      exit $LASTEXITCODE
     }
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
