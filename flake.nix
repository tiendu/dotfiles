{
  description = "Environment with necessary tools";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
    in {
      devShells.${system} = nixpkgs.lib.mkShell {
        packages = with nixpkgs.pkgs; [
          curl
          aria2
          git
          zip
          unzip
          gawk
          fish
          helix
          tmux
          nmap
          jq
          exa
          ripgrep
          bat
          fzf
          yazi
          fd
          zoxide
          entr
        ];
      };
    };
}
