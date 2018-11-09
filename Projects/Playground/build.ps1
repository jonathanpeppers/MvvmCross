$sln = '..\..\MvvmCross.sln'
$csproj = '.\Playground.Droid\Playground.Droid.csproj'
$xaml = '.\Playground.Droid\Resources\layout\SplashScreen.axml'
$adb = 'C:\Program Files (x86)\Android\android-sdk\platform-tools\adb.exe'
$packageName = 'com.mvvmcross.playground'
$verbosity = 'quiet'
$java = '/p:JavaSdkDirectory=C:\Program Files (x86)\Java\jdk1.8.0_161'
$suffix = '-aapt'

function Touch {
    param ([string] $path)
    $date = (Get-Date)
    $date = $date.ToUniversalTime()
    $file = Get-Item $path
    $file.LastAccessTimeUtc = $date
    $file.LastWriteTimeUtc = $date
}

function MSBuild {
    param ([string] $msbuild, [string] $target, [string] $binlog)

    & $msbuild $csproj /t:$target /v:$verbosity /bl:$binlog $java /p:AndroidUseAapt2=False
    if (!$?) {
        exit
    }

    # So git clean call doesn't delete
    & git add $binlog
}

function Profile {
    param ([string] $msbuild, [string] $version)
    
    # Reset working copy & device
    #& $adb uninstall $packageName
    & git clean -dxf ..\..
    & $msbuild $sln /t:Restore
    if (!$?) {
        exit
    }

    # First
    #MSBuild -msbuild $msbuild -target 'Build' -binlog "./first-build-$version$suffix.binlog"
    MSBuild -msbuild $msbuild -target 'SignAndroidPackage' -binlog "./first-$version$suffix.binlog"
    #MSBuild -msbuild $msbuild -target 'Install' -binlog "./first-install-$version$suffix.binlog"

    # Second
    #MSBuild -msbuild $msbuild -target 'Build' -binlog "./second-build-$version$suffix.binlog" 
    MSBuild -msbuild $msbuild -target 'SignAndroidPackage' -binlog "./second-$version$suffix.binlog"
    #MSBuild -msbuild $msbuild -target 'Install' -binlog "./second-install-$version$suffix.binlog"

    # Third (Touch XAML)
    Touch $xaml
    #MSBuild -msbuild $msbuild -target 'Build' -binlog "./third-build-$version$suffix.binlog"
    MSBuild -msbuild $msbuild -target 'SignAndroidPackage' -binlog "./third-$version$suffix.binlog"
    #MSBuild -msbuild $msbuild -target 'Install' -binlog "./third-install-$version$suffix.binlog"
}

# 15.8.2
#$msbuild = 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\MSBuild.exe'
#Profile -msbuild $msbuild -version '15.8'

# 16.0 P2
$msbuild = 'C:\Program Files (x86)\Microsoft Visual Studio\Preview\Enterprise\MSBuild\15.0\Bin\MSBuild.exe'
Profile -msbuild $msbuild -version '16.0'

# Print summary of results
$logs = Get-ChildItem .\*.binlog
foreach ($log in $logs) {
    $time = & $msbuild $log | Select-Object -Last 1
    Write-Host "$log $time"
}