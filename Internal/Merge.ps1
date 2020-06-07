function Merge($object, $assign) {
  $new = @{ }
  foreach ($key in $object.Keys) {
    if($object[$key].Clone) {
      $new[$key] = $object[$key].Clone()
    } else {
      $new[$key] = $object[$key]
    }
  }
  foreach ($key in $assign.Keys) {
    if($assign[$key].GetType().Name -eq "Hashtable") {
      if(!$new[$key]) {
        $new[$key] = $assign[$key]
      } else {
        $new[$key] = Merge $new[$key] $assign[$key]
      }
    } else {
      $new[$key] = $assign[$key]
    }
  }

  return $new
}
