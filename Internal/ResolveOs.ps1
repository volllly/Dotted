function ResolveOs($dot, $os) {
  $dotOs = $false
  $keys = @{
    "windows" = $dot.Keys | Where-Object { $_ -match '[a-z|]*windows[a-z|]*' };
    "linux"   = $dot.Keys | Where-Object { $_ -match '[a-z|]*linux[a-z|]*' };
    "darwin"  = $dot.Keys | Where-Object { $_ -match '[a-z|]*darwin[a-z|]*' };
  }

  if($keys["windows"] -or $keys["linux"] -or $keys["darwin"] -or $dot.ContainsKey("global")) {
    if($keys[$os] -or $dot.ContainsKey("global")) {
      
      if($dot.ContainsKey("global")) {
        $dotOs = $dot["global"]
      } else {
        $dotOs = @{ }
      }
      
      foreach($key in $keys[$os]) {
        $dotOs = Merge $dotOs $dot[$key]
      }
    }
  } else {
    $dotOs = $dot
  }

  return $dotOs
}
