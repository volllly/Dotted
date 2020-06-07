function Enlarge($dot) {
  function EnlargeSingle($dot) {
    if($dot["installs"]) {
      if($dot["installs"].GetType().Name -Eq "String") {
        $dot["installs"] = @{
          "cmd"     = $dot["installs"]
          "depends" = @()
        }
      }
      if($dot["installs"]["depends"]) {
        if($dot["installs"]["depends"].GetType().Name -Eq "String") {
          $dot["installs"]["depends"] = @($dot["installs"]["depends"])
        }
      }
    }
    if($dot["links"]) {
      if($dot["links"].GetType().Name -Eq "String") {
        $dot["links"] = @($dot["links"])
        $dot["links"].Keys | ForEach-Object {
          if($dot["links"][$_].GetType().Name -Eq "String") {
            $dot["links"][$_] = @($dot["links"][$_])
          }
        }
      }
    }
    if($dot["updates"]) {
      if($dot["updates"].GetType().Name -Eq "String") {
        $dot["updates"] = @{
          "cmd"     = $dot["updates"].Clone()
          "depends" = @()
        }
      }
      if($dot["updates"]["depends"]) {
        if($dot["updates"]["depends"].GetType().Name -Eq "String") {
          $dot["updates"]["depends"] = @($dot["updates"]["depends"])
        }
      }
    }
    return $dot
  }

  if($dot["windows"] -or $dot["linux"] -or $dot["darwin"] -or $dot["global"]) {
    if($dot["windows"]) {
      $dot["windows"] = EnlargeSingle($dot["windows"])
    }

    if($dot["linux"]) {
      $dot["linux"] = EnlargeSingle($dot["linux"])
    }

    if($dot["darwin"]) {
      $dot["darwin"] = EnlargeSingle($dot["darwin"])
    }

    if($dot["global"]) {
      $dot["global"] = EnlargeSingle($dot["global"])
    }
  } else {
    $dot = EnlargeSingle($dot)
  }

  return $dot
}
