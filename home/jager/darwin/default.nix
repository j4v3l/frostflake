{
  pkgs,
  lib,
  ...
}: {
  imports = [../common/default.nix];

  home.packages = lib.mkAfter (with pkgs; [iterm2]);

  programs.zsh.initContent = lib.mkAfter ''
    # Ensure Homebrew binaries appear before the default macOS ones if Brew is present
    if [ -x /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  '';
}
