# AWWWWNIXOSBOX

This simple example of NixOS on EC2 via [OpenTofu](https://opentofu.org/docs/cli/code).

**AI Collaboration Overview**

### AI Model

* **Model Used:** Gemini (Google)

---

### Key Technical Milestones

* **Deployment Strategy Selection:** Evaluated AWS VM Import (`nix-build` → S3 → AMI) vs. direct remote provisioning (`nixos-rebuild` over SSH onto a stock NixOS ARM64 AMI). Selected the SSH push pattern for faster iteration.
* **IPv6-Only Infrastructure:** Configured OpenTofu (`main.tf`) to allocate IPv6 addresses (`ipv6_address_count = 1`), disabled public IPv4 assignment, and bound deployment scripts exclusively to IPv6 endpoints.
* **Boot Race Condition & Auth Fixes:** Resolved EC2 metadata SSH key availability race conditions by replacing raw `nc` port checks with an `ssh -o BatchMode=yes` polling loop.
* **IPv6 String & SCP Parsing Workarounds:** Fixed OpenSSH and `scp` IPv6 syntax errors (colon delimiter ambiguity) by streaming `configuration.nix` directly over standard SSH `stdin`.
* **Cross-Architecture Build Fixes:** Solved host `x86_64` vs. target `aarch64` evaluation mismatches and remote flake auto-detection conflicts by invoking `nixos-rebuild switch -I nixos-config=...` natively on the target instance.
* **Memory Optimization on `t4g.micro`:** Resolved system build Out-Of-Memory (OOM) crashes on 1 GB RAM instances by allocating a temporary 2 GB swap file and setting Nix build execution constraints (`--option max-jobs 1 --option cores 1`).
* **Cluster Architecture Planning:** Designed a production-ready, high-availability architecture featuring a dedicated IPv6-first VPC, dual-stack Application Load Balancer (ALB), Auto Scaling Group (ASG), and pre-compiled closure deployment via S3.

---

### Truncated Prompt History

1. `"ah fuck. we should have looked at docs... import via vmimport - not sure how we can have tofu do all this"`
2. `"show me the full main.tf for option 2 and we use t4g.micro moving forward"`
3. `"also we only use IPv6 on the NixOS box so we need to use the IPv6 addr given the box"`
4. `"this works but we get promptyed for a password: aws_instance.nixos_box (local-exec)..."`
5. `"this works on my host but keeps looping in local-exec: ssh -6 -o BatchMode=yes..."`
6. `"aws_instance.nixos_box (local-exec): error: flake 'git+file:///etc/nixos' does not provide attribute..."`
7. `"aws_instance.nixos_box (local-exec): ssh: Could not resolve hostname 2600... scp: Connection closed"`
8. `"works! t4g.micro CANNOT build the system but could probably run it fine we need to figure that out..."`
9. `"now provide a rough plan on how you'd spin up this EC2 instance as a cluster in EC2..."` 
