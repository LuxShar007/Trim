# Security Policy

## 1. Zero-Client-Secret Architecture

TRIM enforces a strict zero-client-secret architecture to safeguard AI provider credentials and protect users:
- **Server-Side AI Proxy**: The Flutter client (Web and Android) never directly communicates with `api.groq.com`. Instead, all requests route through a secure Vercel Serverless Function (`/api/trim`).
- **No Embedded Keys**: `GROQ_API_KEY` is never compiled into release APKs, web bundles, or Dart code.
- **No `--dart-define` Production Keys**: Production deployments do not rely on `--dart-define` for secrets, eliminating the risk of client decompilation extraction.
- **Local Data Privacy**: Session history and locked MVPs are persisted locally on-device using Hive. No product ideas are logged or sold to third-party databases.

---

## 2. Prohibited Practices for Contributors

Contributors must strictly adhere to the following rules:
- **Never commit `.env` or local configuration files**: Repository `.gitignore` rules prevent staging `.env*` files.
- **Never hardcode credentials or tokens**: Any pull request containing API keys, authorization tokens, or internal credentials will be rejected immediately.
- **Do not introduce direct client AI calls**: All LLM inference must pass through verified server-side routing with rate limiting, timeouts, and request validation.

---

## 3. Reporting Security Issues

If you discover a potential vulnerability, credential leak, or security issue, please do not open a public GitHub issue.

Instead, report it responsibly to:
- **Email**: `security@sharvin.dev` (or via GitHub Private Vulnerability Reporting)

Please include:
- A description of the issue.
- Steps to reproduce or proof-of-concept.
- Any relevant logs (ensure no private credentials are included in the report).

We commit to acknowledging reports within 48 hours and deploying remediation patches promptly.
