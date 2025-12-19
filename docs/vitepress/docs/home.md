
# Home Environment

Frostflake uses Home Manager to configure user environments for both Linux and macOS.

## Highlights


## Example: Zsh Aliases

```nix
shellAliases = lib.mkMerge [
  {
    ll = "eza -lh --icons=always";
    la = "eza -lha --icons=always";
    lt = treeAlias;
    tree = "${treeAlias} -L 3";
    gs = "git status -sb";
    ga = "git add";
    gp = "git push";
    gl = "git pull";
    nclean = "sudo nix-collect-garbage -d && nix store optimise";
    nfu = "nix flake update";
    nfmt = "alejandra .";
    ncheck = "statix check . && deadnix";
  }
  # ...other aliases...
];
```
