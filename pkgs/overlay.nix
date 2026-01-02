# Overlay for nvfetcher-managed sources.
final: prev:
let
  sources = import ./_sources/generated.nix { inherit (prev) lib; };
in
{
  # Expose sources for reuse in modules or packages.
  frostflakeSources = sources;

  # Track a bleeding-edge Ghostty build using nvfetcher.
  ghostty-latest = prev.ghostty.overrideAttrs (_: {
    version = sources.ghostty.version;
    src = sources.ghostty.src;
  });

  # Define packages using nvfetcher sources here, e.g.:
  # mytool = prev.stdenv.mkDerivation {
  #   pname = "mytool";
  #   version = sources.mytool.version;
  #   src = sources.mytool.src;
  #   nativeBuildInputs = [ prev.pkg-config ];
  #   buildInputs = [ ];
  #   installPhase = ''
  #     mkdir -p $out/bin
  #     cp mytool $out/bin/
  #   '';
  # };
}
