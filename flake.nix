{
  description = "Environment with necessary tools";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  outputs = { self, nixpkgs }: {
    devShells.default = nixpkgs.lib.mkShell {
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
