{ pkgs, ... }:

let
  site = pkgs.runCommand "nixos-web-app" {
    # Include cmark parser to process Markdown into HTML at build time
    nativeBuildInputs = [ pkgs.cmark ];
  } ''
    mkdir -p $out

    # Read open letter markdown file from current directory (${./letter.md})
    LETTER_HTML=$(cmark ${./letter.md})

    cat << HTML > $out/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>NixOS // Immutable Infrastructure</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <!-- Scrolling "HAPPY BIRTHDAY" Background -->
  <div class="birthday-bg">
    <div class="scroll-track track-left">
      <span>HAPPY BIRTHDAY ★ HAPPY BIRTHDAY ★ HAPPY BIRTHDAY ★ HAPPY BIRTHDAY ★ HAPPY BIRTHDAY ★ HAPPY BIRTHDAY ★</span>
    </div>
    <div class="scroll-track track-right">
      <span>HAPPY BIRTHDAY ✦ HAPPY BIRTHDAY ✦ HAPPY BIRTHDAY ✦ HAPPY BIRTHDAY ✦ HAPPY BIRTHDAY ✦ HAPPY BIRTHDAY ✦</span>
    </div>
    <div class="scroll-track track-left-fast">
      <span>HAPPY BIRTHDAY ⚡ HAPPY BIRTHDAY ⚡ HAPPY BIRTHDAY ⚡ HAPPY BIRTHDAY ⚡ HAPPY BIRTHDAY ⚡ HAPPY BIRTHDAY ⚡</span>
    </div>
    <div class="scroll-track track-diag">
      <span>HAPPY BIRTHDAY 🎉 HAPPY BIRTHDAY 🎉 HAPPY BIRTHDAY 🎉 HAPPY BIRTHDAY 🎉 HAPPY BIRTHDAY 🎉 HAPPY BIRTHDAY 🎉</span>
    </div>
    <div class="scroll-track track-right-slow">
      <span>HAPPY BIRTHDAY ★ HAPPY BIRTHDAY ★ HAPPY BIRTHDAY ★ HAPPY BIRTHDAY ★ HAPPY BIRTHDAY ★ HAPPY BIRTHDAY ★</span>
    </div>
  </div>

  <header class="top-nav">
    <nav class="nav-links">
      <a href="#system">[ SYSTEM ]</a>
      <a href="#flakes">[ FLAKES ]</a>
      <a href="#modules">[ MODULES ]</a>
      <a href="#dev" class="active">[ DEV ]</a>
    </nav>
    <div class="nav-title">NIXOS.TXT / DECLARATIVE SYSTEM</div>
  </header>

  <main class="container">
    <header class="hero card" id="system">
      <div class="section-tag">LABEL: HERO.SYS</div>
      <div class="badge">NixOS • ARM64</div>
      <h1>Declarative.<br><span class="gradient-text">Reproducible.</span></h1>
      <p class="subtitle">> Purely functional system management powered by OpenTofu & Nix flakes.</p>
    </header>

    <section class="grid" id="flakes">
      <div class="card">
        <div class="section-tag">FEATURE: 01</div>
        <div class="card-icon">[ ⚡ ]</div>
        <h3>Atomic Upgrades</h3>
        <p>Upgrades never break system integrity. Instantly rollback to previous generations if needed.</p>
      </div>

      <div class="card">
        <div class="section-tag">FEATURE: 02</div>
        <div class="card-icon">[ ❄️ ]</div>
        <h3>Pure Declarative</h3>
        <p>Entire system configured from a single immutable evaluation graph.</p>
      </div>

      <div class="card">
        <div class="section-tag">FEATURE: 03</div>
        <div class="card-icon">[ 🛡️ ]</div>
        <h3>Sandboxed Builds</h3>
        <p>Guaranteed build reproducibility with isolated, hermetic environment dependencies.</p>
      </div>
    </section>

    <section class="code-box card" id="modules">
      <div class="section-tag">SOURCE: CONFIG.NIX</div>
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

    <!-- Dev Section: Rendered Open Letter -->
    <section class="card dev-section" id="dev">
      <div class="section-tag">OPEN LETTER // DEV</div>
      <div class="markdown-body">
        $LETTER_HTML
      </div>
    </section>
  </main>
</body>
</html>
HTML

    cat << 'CSS' > $out/style.css
:root {
  --bg: #cbcdbf;
  --card-bg: #d5d7cb;
  --border: #1a1b18;
  --text: #1a1b18;
  --muted: #4a4c43;
  --accent: #5277c3;
  --accent-light: #2c4270;
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
  border-radius: 0 !important;
}

body {
  background-color: var(--bg);
  color: var(--text);
  font-family: "Courier New", Courier, Monaco, "Lucida Console", monospace;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding-bottom: 3rem;
  position: relative;
  overflow-x: hidden;
  -webkit-font-smoothing: none;
  font-smooth: never;
}

/* Multi-Directional Scrolling Background */
.birthday-bg {
  position: fixed;
  inset: 0;
  z-index: 0;
  pointer-events: none;
  overflow: hidden;
  opacity: 0.12;
  display: flex;
  flex-direction: column;
  justify-content: space-around;
  font-weight: 900;
  font-size: 1.8rem;
  user-select: none;
}

.scroll-track {
  white-space: nowrap;
  display: flex;
  width: 200%;
}

.scroll-track span {
  display: inline-block;
  width: 100%;
}

.track-left {
  animation: moveLeft 16s linear infinite;
}

.track-right {
  animation: moveRight 20s linear infinite;
}

.track-left-fast {
  animation: moveLeft 10s linear infinite;
}

.track-right-slow {
  animation: moveRight 28s linear infinite;
}

.track-diag {
  transform: rotate(-12deg) scale(1.2);
  animation: moveLeft 14s linear infinite;
}

@keyframes moveLeft {
  0% { transform: translateX(0); }
  100% { transform: translateX(-50%); }
}

@keyframes moveRight {
  0% { transform: translateX(-50%); }
  100% { transform: translateX(0); }
}

.top-nav {
  width: 100%;
  background: var(--card-bg);
  border-bottom: 2px solid var(--border);
  padding: 0.6rem 1.5rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.85rem;
  font-weight: bold;
  letter-spacing: 0.05em;
  margin-bottom: 2rem;
  z-index: 10;
}

.nav-links {
  display: flex;
  gap: 1rem;
}

.nav-links a {
  color: var(--text);
  text-decoration: none;
  padding: 0.2rem 0.4rem;
}

.nav-links a.active,
.nav-links a:hover {
  background: var(--text);
  color: var(--bg);
}

.nav-title {
  font-size: 0.75rem;
  color: var(--muted);
  text-transform: uppercase;
}

.container {
  width: 100%;
  max-width: 920px;
  padding: 0 1.5rem;
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  z-index: 1;
}

.card {
  background: var(--card-bg);
  border: 1px solid var(--border);
  padding: 1.5rem;
  position: relative;
  box-shadow: 3px 3px 0px var(--border);
  transition: transform 0.1s, box-shadow 0.1s;
}

.card:hover {
  transform: translate(-2px, -2px);
  box-shadow: 5px 5px 0px var(--border);
}

.section-tag {
  font-size: 0.7rem;
  font-weight: bold;
  color: var(--muted);
  letter-spacing: 0.08em;
  text-transform: uppercase;
  margin-bottom: 0.75rem;
  border-bottom: 1px dashed var(--border);
  padding-bottom: 0.3rem;
  display: inline-block;
  width: 100%;
}

.hero h1 {
  font-size: 2.75rem;
  line-height: 1.05;
  font-weight: 900;
  letter-spacing: -0.02em;
  text-transform: uppercase;
  margin: 0.75rem 0;
}

.gradient-text {
  background: var(--border);
  color: var(--bg);
  padding: 0 0.3rem;
  -webkit-text-fill-color: initial;
}

.badge {
  display: inline-block;
  padding: 0.2rem 0.6rem;
  background: var(--border);
  color: var(--bg);
  font-size: 0.75rem;
  font-weight: bold;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  margin-bottom: 0.5rem;
}

.subtitle {
  margin-top: 0.75rem;
  color: var(--muted);
  font-size: 0.95rem;
  line-height: 1.4;
}

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.25rem;
}

.card-icon {
  font-size: 1.2rem;
  margin-bottom: 0.5rem;
  font-weight: bold;
}

.card h3 {
  font-size: 1.1rem;
  margin-bottom: 0.5rem;
  text-transform: uppercase;
  letter-spacing: 0.02em;
}

.card p {
  color: var(--muted);
  font-size: 0.85rem;
  line-height: 1.4;
}

.code-box {
  padding: 0;
}

.code-box .section-tag {
  margin: 1.25rem 1.25rem 0 1.25rem;
  width: calc(100% - 2.5rem);
}

.code-header {
  background: rgba(0, 0, 0, 0.05);
  padding: 0.5rem 1.25rem;
  display: flex;
  align-items: center;
  gap: 0.4rem;
  border-bottom: 1px solid var(--border);
  border-top: 1px solid var(--border);
}

.dot {
  width: 8px;
  height: 8px;
  border: 1px solid var(--border);
}

.red { background: #1a1b18; }
.yellow { background: #777; }
.green { background: #fff; }

.code-title {
  margin-left: 0.5rem;
  color: var(--text);
  font-size: 0.8rem;
  font-weight: bold;
}

pre {
  background: #151713;
  color: #e2e4d8;
  padding: 1.25rem;
  overflow-x: auto;
  font-size: 0.85rem;
  line-height: 1.5;
  border-top: 0;
}

.k { color: #81a1c1; font-weight: bold; }
.s { color: #a3be8c; }
.b { color: #d08770; }

/* Markdown Content Styling inside DEV section */
.markdown-body {
  font-size: 0.9rem;
  line-height: 1.6;
}

.markdown-body h1,
.markdown-body h2,
.markdown-body h3 {
  margin-top: 1.2rem;
  margin-bottom: 0.6rem;
  text-transform: uppercase;
  border-bottom: 1px dashed var(--border);
  padding-bottom: 0.25rem;
}

.markdown-body p {
  margin-bottom: 0.85rem;
}

.markdown-body ul,
.markdown-body ol {
  margin-left: 1.5rem;
  margin-bottom: 0.85rem;
}

.markdown-body blockquote {
  border-left: 3px solid var(--border);
  padding-left: 0.8rem;
  margin: 1rem 0;
  color: var(--muted);
  font-style: italic;
}

.markdown-body code {
  background: rgba(0, 0, 0, 0.08);
  padding: 0.1rem 0.3rem;
  font-weight: bold;
}
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
