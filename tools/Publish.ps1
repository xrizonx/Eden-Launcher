[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$output = Join-Path $repositoryRoot 'artifacts/publish/win-x64'
$archive = Join-Path $repositoryRoot 'artifacts/Eden-Launcher-win-x64.zip'
$exe = Join-Path $output 'Eden.Desktop.exe'

Push-Location -LiteralPath $repositoryRoot
try {
    # A clean output directory prevents stale assemblies from entering the release ZIP.
    if (Test-Path -LiteralPath $output) {
        Remove-Item -LiteralPath $output -Recurse -Force
    }

    $publishArguments = @(
        'publish',
        'src/Eden.Launcher/Eden.Launcher.csproj',
        '-c', 'Release',
        '-r', 'win-x64',
        '--self-contained', 'true',
        '-p:PublishSingleFile=true',
        '-p:IncludeNativeLibrariesForSelfExtract=true',
        '-p:EnableCompressionInSingleFile=true',
        '-o', $output
    )
    & dotnet @publishArguments
    if ($LASTEXITCODE -ne 0) {
        throw 'Launcher publishing failed.'
    }
    if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
        throw 'The expected Eden.Desktop.exe was not produced.'
    }
    if ((Get-Item -LiteralPath $exe).Length -eq 0) {
        throw 'The published executable is empty.'
    }

    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'README.md') -Destination $output
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'docs') -Destination $output -Recurse -Force

    $files = Get-ChildItem -LiteralPath $output | Select-Object -ExpandProperty FullName
    Compress-Archive -LiteralPath $files -DestinationPath $archive -Force
    Write-Output $archive
    Write-Output $exe
}
finally {
    Pop-Location
}
