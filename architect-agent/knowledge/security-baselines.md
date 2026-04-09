# Security Baselines

Security is not a feature to add at the end. Every architecture decision is also a security decision. This document covers the baseline security practices that should be in place before a system handles user data or faces the internet.

**This document is always loaded** — security considerations apply to every architecture conversation.

---

## Zero Trust Architecture

### The Principle

"Never trust, always verify." Traditional perimeter security assumes that everything inside the network is trusted. Zero trust assumes breach — every request, from any source, must be authenticated and authorized, regardless of where it originates.

Zero trust replaces implicit trust (inside = safe) with explicit verification: identity, device health, context, and minimal privilege on every request.

### Core Tenets

1. **Verify explicitly** — Authenticate and authorize every request using all available data points: identity, location, device, service, time, data classification.
2. **Use least privilege access** — Limit user and service access to the minimum required. Just-in-time (JIT) access for privileged operations.
3. **Assume breach** — Design as if attackers are already inside. Segment networks, encrypt all internal traffic, minimize blast radius.

### Implementation in Cloud Architectures

- **Service-to-service authentication:** mTLS between services (Istio, Linkerd, or application-level). No service should trust another service solely because it's on the same VPC.
- **Workload identity:** Use IAM roles for EC2/ECS/EKS workloads (instance profiles, IRSA for Kubernetes). Never use long-lived credentials in application code.
- **Micro-segmentation:** Security groups that allow only specific service-to-service ports, not broad "internal" rules.
- **Continuous validation:** Session tokens expire; re-validate on sensitive operations. Short-lived credentials (AWS STS, OIDC tokens) preferred over long-lived API keys.

---

## Least Privilege

### The Principle

Every user, service, and process should have access to only the resources it needs to perform its function — and no more. Unused permissions are attack surface.

### IAM Best Practices

**For human users:**
- Never use root credentials for day-to-day operations
- Require MFA for all AWS console access (enforce via SCP)
- Use IAM Identity Center (SSO) rather than individual IAM users
- Use temporary credentials via SSO — no long-lived access keys
- Separate production and non-production accounts

**For service accounts and workloads:**
- One IAM role per service/workload — not shared roles
- Scope policies to specific resources, not `Resource: "*"`
- Use condition keys to further restrict (e.g., `aws:RequestedRegion`, `aws:SourceVpc`)
- Regularly run IAM Access Analyzer and act on unused access findings
- Audit permissions quarterly; remove unused access

**Common over-permissioning patterns to avoid:**
- `s3:*` on all S3 buckets when the service only reads one bucket
- `ec2:*` for an automation role that only needs to start/stop instances
- Admin policies attached to Lambda execution roles
- Shared service accounts across teams

---

## Encryption

### At Rest

Encrypt all data at rest. This is table stakes and has minimal performance impact with modern hardware-accelerated AES.

- **AWS:** Enable default encryption on EBS, S3, RDS, DynamoDB. Use AWS KMS for key management.
- **Key rotation:** Enable automatic annual KMS key rotation. For highly sensitive data, rotate more frequently.
- **Application-layer encryption:** For particularly sensitive fields (SSNs, PII), encrypt at the application layer before writing to the database, in addition to volume-level encryption. Defense in depth.

### In Transit

All data in transit should be encrypted with TLS 1.2+ (prefer TLS 1.3).

- **External traffic:** HTTPS everywhere. Enforce with HSTS. Minimum TLS 1.2, prefer 1.3. Use ACM for certificate management.
- **Internal traffic:** mTLS between services. At minimum, TLS on all service-to-service communication. "Internal network" is not a security boundary.
- **Database connections:** Require SSL for all database connections. RDS supports this natively; enforce with parameter group settings.
- **Reject weak ciphers:** Disable TLS 1.0 and 1.1. Disable weak cipher suites.

### Key Management

- **AWS KMS:** Managed key storage, audit logging, fine-grained access control. Default choice for AWS-hosted workloads.
- **AWS CloudHSM:** Hardware security module for workloads requiring FIPS 140-2 Level 3. Higher cost; required for some compliance frameworks.
- **Never store keys in code or environment variables.** Use secrets management (see below).

---

## Identity Federation

### What It Is

Instead of managing user identities in each application, federate identity to a trusted external provider. Users authenticate once (SSO) and receive tokens that can be used across services.

### Protocols

**OIDC (OpenID Connect):** The modern standard. Built on OAuth 2.0. Returns JWT ID tokens with user identity claims. Widely supported. Use for:
- User-facing applications authenticating with Google, Okta, Auth0, Azure AD
- Service-to-service authentication (SPIFFE/SPIRE, AWS IAM OIDC provider for Kubernetes)

**SAML 2.0:** Older enterprise standard. XML-based. Use when your enterprise IdP requires it (many enterprise SSO systems are SAML-only). More complex to implement than OIDC.

**OAuth 2.0:** Authorization protocol (not authentication). Use for delegated access ("allow app X to access my Y on my behalf"). Not for authentication alone — use OIDC on top of OAuth 2.0 for authentication.

### Enterprise Integration

- **AWS IAM Identity Center (SSO):** Integrates with corporate IdP (Okta, Azure AD, Google Workspace). Provides SSO for AWS Console, CLI, and SDK. Single source of truth for who has access to what.
- **Kubernetes IRSA (IAM Roles for Service Accounts):** Allows pods to assume IAM roles without long-lived credentials. OIDC-based. Standard practice for EKS.

---

## Network Segmentation

### Principle

Defense in depth. Even if an attacker breaches one segment, they cannot easily move laterally to other segments.

### VPC Design

**Multi-account strategy:** Separate AWS accounts for production, staging, and development. Account boundaries are the strongest isolation available in AWS.

**Subnet tiers:**
- **Public subnets:** Only load balancers, NAT gateways, bastion hosts (or no bastion — use SSM Session Manager instead)
- **Private subnets:** Application tier (ECS, EC2, Lambda in VPC)
- **Isolated subnets:** Database tier — no outbound internet access, inbound only from application tier

**Security groups as micro-firewalls:**
- One security group per service tier
- Allow only specific source SGs/CIDRs on specific ports
- Avoid `0.0.0.0/0` inbound on any port except 80/443 on the public load balancer
- Regularly audit for overly permissive rules

**Network ACLs:** Stateless firewall at the subnet level. Use for broad CIDR-based blocking; prefer security groups for fine-grained service-to-service rules.

### Private Connectivity

- **VPC Endpoints:** Access AWS services (S3, DynamoDB, SQS, etc.) from private subnets without internet gateway or NAT gateway. Reduces attack surface and data transfer costs.
- **AWS PrivateLink:** Private connectivity to AWS services and partner services over the AWS backbone. No public internet exposure.
- **VPN / Direct Connect:** For on-premise to cloud connectivity. Direct Connect for high-bandwidth, low-latency requirements; VPN for lower traffic or backup.

---

## Secrets Management

### The Problem

Secrets (database passwords, API keys, OAuth client secrets) must be stored and accessed securely. Hardcoding secrets in code or environment variables is the most common cause of credential exposure.

### Solutions

**AWS Secrets Manager:**
- Centralized secret storage with automatic rotation support
- Fine-grained IAM access control per secret
- Automatic rotation for RDS, Redshift, DocumentDB (built-in Lambda rotators)
- Audit log of every secret access via CloudTrail
- ~$0.40/secret/month + $0.05 per 10K API calls

**AWS Parameter Store (SSM):**
- Free tier available for standard parameters
- SecureString parameters encrypted with KMS
- Use for configuration that's less sensitive (feature flags, endpoints) or when cost matters
- No automatic rotation — use Secrets Manager for credentials

**HashiCorp Vault:**
- Open-source, cloud-agnostic secret management
- Dynamic secrets (generate short-lived credentials on demand for DB, cloud providers)
- Comprehensive audit logging, fine-grained policies
- Operational overhead: you run and maintain the Vault cluster
- Use when multi-cloud or hybrid cloud secrets management is required

**Never accept:**
- Secrets in source code or configuration files
- Secrets in environment variables baked into container images
- Secrets in CI/CD logs
- Shared credentials across services or environments

---

## Common Attack Vectors by Architecture Pattern

### Web Applications

- **Injection (SQL, command, LDAP):** Parameterized queries, input validation, WAF rules
- **XSS:** Content Security Policy headers, output encoding, modern frameworks that escape by default
- **CSRF:** SameSite cookies, CSRF tokens for state-changing operations
- **Insecure direct object references:** Authorize every resource access — don't trust user-supplied IDs without verification
- **Broken authentication:** Strong password policies, MFA, secure session management, short token expiry

### APIs

- **Excessive data exposure:** Return only what clients need — apply response filtering
- **Rate limiting / abuse:** API gateway rate limiting, bot protection
- **Broken object-level authorization:** Verify every user can access every resource they request
- **JWT vulnerabilities:** Validate signature, expiry, issuer, audience. Never trust unsigned JWTs. Use strong signing algorithms (RS256, ES256 — not HS256 for distributed systems).

### Microservices / Containers

- **Container escape:** Run containers as non-root, use read-only file systems, apply seccomp/AppArmor profiles
- **Supply chain attacks:** Use trusted base images, scan images in CI (Trivy, Snyk, ECR Enhanced Scanning), sign images
- **Lateral movement:** mTLS, network policies (Kubernetes NetworkPolicy), security groups between services
- **Misconfigured K8s:** Disable anonymous API access, use RBAC, audit kube-apiserver access logs

---

## Compliance Frameworks

### SOC 2 Type II

**What it covers:** Controls for security, availability, processing integrity, confidentiality, and privacy of service organization data.

**Key requirements for architects:**
- Access controls with MFA and principle of least privilege
- Encryption at rest and in transit
- Audit logging and log retention (typically 12 months)
- Vulnerability management and patching cadence
- Incident response procedures
- Change management controls

**Cloud relevance:** AWS, Azure, GCP are SOC 2 compliant for their platform services. Your responsibility is the application and configuration layer.

### HIPAA

**What it covers:** Protected Health Information (PHI) handling in US healthcare.

**Key requirements:**
- Encryption of PHI at rest and in transit (required)
- Audit logs of PHI access (required)
- Business Associate Agreements (BAAs) with cloud providers (AWS, Azure, GCP offer BAAs)
- Minimum necessary access — don't store more PHI than required
- Data retention and destruction policies

**Architecture implications:** PHI must be isolated. Separate encryption keys, separate audit trails, restricted access. Not all AWS services are HIPAA-eligible — check the AWS HIPAA eligible services list before architecture.

### PCI-DSS

**What it covers:** Payment card data (cardholder data environment — CDE).

**Key requirements:**
- Cardholder data scope minimization — reduce what you store, process, and transmit
- Network segmentation: CDE must be isolated from non-CDE systems
- Strong encryption for cardholder data at rest and in transit
- Vulnerability scanning (quarterly external scans, annual penetration test)
- Intrusion detection in the CDE
- WAF required

**Architecture implications:** Strongly prefer tokenization (Stripe, Braintree, Adyen handle raw card data; you receive a token). This removes most of your PCI scope.

### GDPR

**What it covers:** Personal data of EU residents (applies regardless of where your company is based).

**Key requirements:**
- Data minimization — collect only what you need
- Right to erasure — ability to delete all data for a user on request
- Data portability — export user data on request
- Privacy by design — build privacy controls in, not on
- Data Processing Agreements (DPAs) with vendors who process personal data
- Breach notification — 72-hour notification to supervisory authority

**Architecture implications:** Know where PII lives. Tag it in your data catalog. Design for delete (soft delete with hard delete capability). Log data access. Review data retention policies.
