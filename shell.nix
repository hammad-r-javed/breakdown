let
  pkgs_main = import (fetchTarball {
    url = "https://releases.nixos.org/nixpkgs/nixpkgs-25.05pre767417.573c650e8a14/nixexprs.tar.xz";
    sha256 = "1zzjrcpqyir2q2bzaxl2sk5vfq0sv4m8xx0q9bf21dsfafcv42qr";
  }) { };
in
pkgs_main.mkShell {
  buildInputs = [
    (pkgs_main.haskellPackages.ghcWithPackages (ps: [
      ps.cabal-install
      ps.scotty
    ]))
    pkgs_main.elmPackages.elm
  ];

  shellHook = ''
    export CABAL_DIR="$(pwd)/cabal-dir"
    export CABAL_CONFIG="$(pwd)/cabal-dir/config"

    test -d ./cabal-dir && echo "local cabal dir exists" || mkdir ./cabal-dir
    test -f ./cabal-dir/config && echo "local cabal config exists" || cabal user-config init
  '';
}
