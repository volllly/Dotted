Function PackageAction($dotsData, $name, $action) {
  $packageaction = $dotsData[$name][$action]
  $depends = $dotsData[$name]["depends"]

  if(($packageaction["packageactiondone"]) -Or ($packageaction["error"])) {
    Return
  }

  if(($packageaction["depended"] -Gt 1) -Or ($dotsData[$name]["depended"] -Gt 1)) {
    Write-Host "detected circular dependency for $name" -ForegroundColor Red
    Return
  }
  if($packageaction["depends"]) {
    $packageaction["depends"] | ForEach-Object {
      if(!$dotsData[$_]) {
        Write-Error "Could not find dependency `"$_`" for `"$name`""
        exit
      }
      if(!$dotsData[$_][$action]) {
        Write-Error "Could not find `"$action`" for dependency `"$_`" for `"$name`""
        exit
      }
      $dotsData[$_][$action]["depended"] += 1
      PackageAction $dotsData $_ $action
    }
  }

  switch ($action) {
    "updates" {
      Write-Host "updating $name"
    }
    "installs" { 
      Write-Host "installing $name"
    }
  }

  Invoke-Expression $packageaction["cmd"]

  $dotsData[$name][$action]["packageactiondone"] = $true

  if($depends) {
    $depends | ForEach-Object {
      $dotsData[$_]["depended"] += 1
      PackageAction $dotsData $_ $action
    }
  }

  Write-Host ""
}
