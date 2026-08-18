{ pkgs, ... }:

let
  site = pkgs.runCommand "nixos-web-app" {} ''
    mkdir -p $out
    cat << 'HTML' > $out/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>NixOS // Immutable Infrastructure</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <div class="glow-bg"></div>
  <main class="container">
    <header class="hero">
      <div class="badge">NixOS • ARM64</div>
      <h1>Declarative.<br><span class="gradient-text">Reproducible.</span></h1>
      <p class="subtitle">Purely functional system management powered by OpenTofu & Nix flakes.</p>
    </header>

    <section class="grid">
      <div class="card">
        <div class="card-icon">⚡</div>
        <h3>Atomic Upgrades</h3>
        <p>Upgrades never break system integrity. Instantly rollback to previous generations if needed.</p>
      </div>
      <div class="card">
        <div class="card-icon">❄️</div>
        <h3>Pure Declarative</h3>
        <p>Entire system configured from a single immutable evaluation graph.</p>
      </div>
      <div class="card">
        <div class="card-icon">🛡️</div>
        <h3>Sandboxed Builds</h3>
        <p>Guaranteed build reproducibility with isolated, hermetic environment dependencies.</p>
      </div>
    </section>

    <section class="code-box">
      <div class="code-header">
        <span class="dot red"></span>
        <span class="dot yellow"></span>
        <span class="dot green"></span>
        <span class="code-title">configuration.nix</span>
      </div>
      <pre><code><span class="k">services</span>.<span class="s">nginx</span> = {
  <span class="k">enable</span> = <span class="b">true</span>;
  <span class="k">virtualHosts</span>.<span class="s">"default"</span> = {
    <span class="k">root</span> = <span class="s">site</span>;
  };
};</code></pre>
    </section>
  </main>
</body>
</html>
HTML

    cat << 'CSS' > $out/style.css
:root {
  --bg: #090a0f;
  --card-bg: rgba(255, 255, 255, 0.03);
  --card-border: rgba(255, 255, 255, 0.08);
  --text: #f3f4f6;
  --muted: #9ca3af;
  --accent: #5277c3;
  --accent-glow: #7ebae4;
}

* { box-sizing: border-box; margin: 0; padding: 0; }

body {
  background-color: var(--bg);
  color: var(--text);
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  min-height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  position: relative;
  overflow-x: hidden;
}

.glow-bg {
  position: absolute;
  width: 600px;
  height: 600px;
  background: radial-gradient(circle, rgba(82, 119, 195, 0.15) 0%, rgba(0,0,0,0) 70%);
  top: 20%;
  left: 50%;
  transform: translate(-50%, -50%);
  z-index: 0;
  pointer-events: none;
}

.container {
  width: 100%;
  max-width: 900px;
  padding: 2rem;
  z-index: 1;
  display: flex;
  flex-direction: column;
  gap: 3rem;
}

.badge {
  display: inline-block;
  padding: 0.35rem 0.85rem;
  border-radius: 99px;
  background: rgba(82, 119, 195, 0.12);
  border: 1px solid rgba(82, 119, 195, 0.3);
  color: var(--accent-glow);
  font-size: 0.85rem;
  font-weight: 600;
  margin-bottom: 1rem;
  letter-spacing: 0.05em;
}

.hero h1 {
  font-size: 3.5rem;
  line-height: 1.1;
  font-weight: 800;
  letter-spacing: -0.03em;
}

.gradient-text {
  background: linear-gradient(135deg, #7ebae4 0%, #5277c3 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.subtitle {
  margin-top: 1rem;
  color: var(--muted);
  font-size: 1.15rem;
  max-width: 550px;
}

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
}

.card {
  background: var(--card-bg);
  border: 1px solid var(--card-border);
  padding: 1.75rem;
  border-radius: 16px;
  backdrop-filter: blur(12px);
  transition: all 0.3s ease;
}

.card:hover {
  border-color: rgba(126, 186, 228, 0.4);
  transform: translateY(-4px);
  box-shadow: 0 10px 30px -10px rgba(82, 119, 195, 0.2);
}

.card-icon {
  font-size: 1.5rem;
  margin-bottom: 0.75rem;
}

.card h3 {
  font-size: 1.15rem;
  margin-bottom: 0.5rem;
}

.card p {
  color: var(--muted);
  font-size: 0.92rem;
  line-height: 1.5;
}

.code-box {
  background: #0d0e15;
  border: 1px solid var(--card-border);
  border-radius: 12px;
  overflow: hidden;
  font-family: "JetBrains Mono", monospace, monospace;
}

.code-header {
  background: rgba(255, 255, 255, 0.02);
  padding: 0.6rem 1rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  border-bottom: 1px solid var(--card-border);
}

.dot { width: 10px; height: 10px; border-radius: 50%; }
.red { background: #ff5f56; }
.yellow { background: #ffbd2e; }
.green { background: #27c93f; }

.code-title {
  margin-left: 0.5rem;
  color: var(--muted);
  font-size: 0.8rem;
}

pre { padding: 1.25rem; overflow-x: auto; font-size: 0.9rem; }
.k { color: #7ebae4; }
.s { color: #a5d6ff; }
.b { color: #ff7b72; }
CSS
  '';

in {
  imports = [ <nixpkgs/nixos/modules/virtualisation/amazon-image.nix> ];

  # Enable Nginx & configure static web root directly in the Nix store
  services.nginx = {
    enable = true;
    virtualHosts.default = {
      default = true;
      root = site;
    };
  };

  # Open HTTP port in the OS firewall
  networking.firewall.allowedTCPPorts = [ 80 ];
}
