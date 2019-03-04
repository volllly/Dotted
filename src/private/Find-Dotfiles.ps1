Function Find-Dotfiles {
  If($Env:DotfileRoot) {
    Return $Env:DotfileRoot
  }
  return Resolve-Path "~/dotfiles"
}
