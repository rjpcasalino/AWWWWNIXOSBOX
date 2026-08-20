{ pkgs ? import <nixpkgs> { system = "aarch64-linux"; } }:

let
  site = pkgs.stdenv.mkDerivation {
    name = "micro-static-site";
    src = ./.; 

    buildPhase = ''
      mkdir -p $out
      cat << 'EOF' > $out/index.html
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>rjpc.net</title>
          <style>
              :root {
                  --bg: #1e2326;
                  --fg: #d3c6aa;
                  --accent: #a7c080;
                  --prompt: #7fbbb3;
                  --error: #e67e80;
              }
              body, html {
                  background-color: var(--bg);
                  color: var(--fg);
                  font-family: "JetBrains Mono", "Fira Code", monospace;
                  margin: 0; padding: 1rem; height: 100%;
                  box-sizing: border-box;
                  overflow: hidden;
              }
              body::after {
                  content: " "; display: block; position: absolute;
                  top: 0; left: 0; bottom: 0; right: 0;
                  background: linear-gradient(rgba(18, 16, 16, 0) 50%, rgba(0, 0, 0, 0.15) 50%);
                  background-size: 100% 2px, 3px 100%; z-index: 10; pointer-events: none;
              }
              #terminal {
                  max-width: 900px;
                  position: relative;
                  z-index: 2;
                  display: flex;
                  flex-direction: column;
                  height: 100%;
                  font-size: 1.1rem; /* Bumped up base size */
              }
              #output { flex-grow: 1; overflow-y: auto; padding-bottom: 1rem; white-space: pre-wrap; word-break: break-all; }
              .prompt-line { display: flex; align-items: center; flex-wrap: wrap; }
              .prompt-txt { color: var(--prompt); font-weight: bold; margin-right: 0.5rem; }
              .mode-indicator { color: var(--accent); margin-right: 0.5rem; font-size: 0.9em; }
              #cmd {
                  background: transparent; border: none; color: var(--fg);
                  font-family: inherit; font-size: 1.1rem; flex-grow: 1; outline: none;
                  caret-color: var(--accent);
                  min-width: 120px;
              }
              .cmd-echo { color: var(--accent); }
              .ascii {
                  color: var(--prompt);
                  text-shadow: 0 0 3px var(--prompt);
                  font-size: 0.75rem; /* Scaled down slightly so it doesn't wrap awkwardly on small screens */
                  margin-bottom: 1rem;
                  line-height: 1.1;
              }

              /* Mobile adjustments */
              @media (max-width: 768px) {
                  body { padding: 0.5rem; }
                  #terminal { font-size: 0.95rem; }
                  .ascii { font-size: 0.55rem; }
              }

              ::-webkit-scrollbar { width: 8px; }
              ::-webkit-scrollbar-thumb { background: var(--prompt); }
          </style>
      </head>
      <body>
          <div id="terminal">
              <div id="output">
<div class="ascii">
    ____      __                           __ 
   /  _/___  / /____  _________  ____     / /_
   / // __ \/ __/ _ \/ ___/ __ \/ __ \   / __/
 _/ // / / / /_/  __/ /  / / / / /_/ /  / /_  
/___/_/ /_/\__/\___/_/  /_/ /_/\____/   \__/  
                                              
</div>
Welcome to rjpc.net. Connection established.
Press 'i' to enter INSERT mode. Type 'help' to begin.
<br><br></div>
              <div class="prompt-line">
                  <span class="mode-indicator" id="mode">[NORMAL]</span>
                  <span class="prompt-txt">rjpc@nixos ~ ❯</span>
                  <input type="text" id="cmd" autocomplete="off" readonly>
              </div>
          </div>

          <script>
              const input = document.getElementById('cmd');
              const output = document.getElementById('output');
              const modeInd = document.getElementById('mode');
              let isInsertMode = false;

              const fileSystem = {
                  'help': 'Available commands:\n  whoami    - Print user information\n  stack     - Display core technologies\n  hardware  - List peripheral interests\n  clear     - Clear terminal buffer',
                  'whoami': 'Ryan Joseph Patrick Casalino.\nSenior Software Engineer, Systems Developer, & NLP Researcher.',
                  'stack': 'Languages: Go, C, C++, Python, Nix\nSystems:   NixOS, Wayland (Sway, tinywl with cwm bindings)\nResearch:  PyTorch, Hugging Face, QualityLens AI defect classification\nArch:      ARM64, gRPC microservices',
                  'hardware': 'neo_geo_mvs2_arcade/\nmetricom_ricochet_transceivers/\nallwinner_h616_soc/\nraspberry_pi_zero_2_w/'
              };

              document.addEventListener('keydown', (e) => {
                  if (e.key === 'Escape') {
                      isInsertMode = false;
                      modeInd.innerText = '[NORMAL]';
                      modeInd.style.color = 'var(--accent)';
                      input.setAttribute('readonly', true);
                      input.blur();
                  } else if (!isInsertMode && e.key === 'i') {
                      e.preventDefault();
                      isInsertMode = true;
                      modeInd.innerText = '[INSERT]';
                      modeInd.style.color = 'var(--error)';
                      input.removeAttribute('readonly');
                      input.focus();
                  } else if (isInsertMode && e.key === 'Enter') {
                      const val = input.value.trim().toLowerCase();
                      if (val) {
                          printLine(`<span class="prompt-txt">rjpc@nixos ~ ❯</span> <span class="cmd-echo">''${val}</span>`);
                          if (val === 'clear') {
                              output.innerHTML = "";
                          } else if (fileSystem[val]) {
                              printLine(fileSystem[val] + '\n');
                          } else {
                              printLine(`zsh: command not found: ''${val}\n`);
                          }
                      }
                      input.value = "";
                      output.scrollTop = output.scrollHeight;
                  }
              });

              function printLine(text) {
                  const div = document.createElement('div');
                  div.innerHTML = text;
                  output.appendChild(div);
              }
              
              // Keep focus if clicking anywhere
              document.addEventListener('click', () => { if(isInsertMode) input.focus(); });
          </script>
      </body>
      </html>
      EOF
    '';

    installPhase = "true"; 
  };

  nginxConf = pkgs.writeText "nginx.conf" ''
    user nobody;
    daemon off;
    pid /tmp/nginx.pid;
    error_log /dev/stdout info;
    events { worker_connections 1024; }
    http {
      include ${pkgs.nginx}/conf/mime.types;
      access_log /dev/stdout;
      server {
        listen 80;
        location / {
          root ${site};
          index index.html;
        }
      }
    }
  '';

in pkgs.dockerTools.buildLayeredImage {
  name = "nixos-web-app-micro";
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
