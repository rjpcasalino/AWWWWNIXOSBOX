{ pkgs ? import <nixpkgs> { system = "aarch64-linux"; } }:

let
  # Explicitly define the system to match our target
  system = "aarch64-linux";

  # 1. Fetch and build the BSS tool directly from its Flake
  # This returns the compiled package, not just the raw source code.
  bssPkg = (builtins.getFlake "github:rjpcasalino/bss/master").packages.${system}.default;

  # 2. Fetch the latest Blog source code
  blogSrc = builtins.fetchGit {
    url = "https://github.com/rjpcasalino/blog_bt.git";
    ref = "master"; # Change to "master" if that is your default branch
  };

  # 3. Build the blog static site
  site = pkgs.stdenv.mkDerivation {
    name = "blog-static-site";
    src = blogSrc;

    # Inject the compiled bss package (and core utilities) into the build environment.
    # Nix will automatically add the 'bss' binary to the $PATH.
    buildInputs = with pkgs; [ bash coreutils bssPkg ];

    buildPhase = ''
      # Execute the compiled bss tool
      bss build
    '';

    installPhase = ''
      mkdir -p $out
      cp -r _site/* $out/
    '';
  };

  # 4. Configure Nginx
  nginxConf = pkgs.writeText "nginx.conf" ''
    user nobody;
    daemon off;
    pid /tmp/nginx.pid;
    error_log /dev/stdout info;

    events {
      worker_connections 1024;
    }

    http {
      include ${pkgs.nginx}/conf/mime.types;
      default_type application/octet-stream;
      access_log /dev/stdout;

      client_body_temp_path /tmp/client_body;
      proxy_temp_path       /tmp/proxy_temp;
      fastcgi_temp_path     /tmp/fastcgi_temp;
      uwsgi_temp_path       /tmp/uwsgi_temp;
      scgi_temp_path        /tmp/scgi_temp;
    
    
      server {
        listen 80;
        listen [::]:80;
        location / {
          root ${site};
          index index.html;
        }
      }
    }
  '';

in pkgs.dockerTools.buildLayeredImage {
  name = "nixos-web-app-medium";
  tag = "latest";

  contents = [ pkgs.nginx pkgs.fakeNss ];

  extraCommands = ''
    mkdir -p tmp var/log/nginx
    chmod 1777 tmp
  '';

  config = {
    Cmd = [ "nginx" "-e" "/dev/stdout" "-c" "${nginxConf}" ];
    ExposedPorts = { "80/tcp" = {}; };
  };
}
