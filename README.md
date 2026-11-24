# Deploy and Host LibreDesk with Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/libredesk-29-helpdesk-live-chat-postgres?referralCode=20H68q)

LibreDesk is an open-source, self-hosted customer support desk: a shared inbox for email and live chat, with teams, automation rules, SLAs, canned responses, CSAT surveys, a help center and reports. This template runs LibreDesk on Railway with Postgres, Redis and persistent attachment storage, and sets the admin password before the app goes online.

## About Hosting LibreDesk

LibreDesk is a single Go binary with a Vue front end. It needs Postgres for conversations and settings, Redis for sessions, cache and queues, and storage for attachments. Installation creates a built-in "System" administrator; upstream's container either asks for its password interactively or gives it a random one that you then have to reset from a shell. This community template pins the official v2.9.2 image, installs the schema and the System admin with a generated, policy-compliant password before the port opens, runs schema upgrades on every start, replaces the default `localhost` root URL with your Railway domain, and keeps attachments on a Railway volume.

## Common Use Cases

- A shared support inbox for a team, fed by email (IMAP) and website live chat
- Routing conversations to teams with automation rules and auto-assignment
- SLA tracking, CSAT surveys and reports for support quality
- A public help center and canned responses (macros) for faster replies
- A self-hosted alternative to Zendesk, Freshdesk or Intercom inboxes

## Dependencies for LibreDesk Hosting

- LibreDesk service (official image) with a volume for attachments
- Postgres
- Redis

### Deployment Dependencies

- [LibreDesk website and docs](https://libredesk.io/)
- [LibreDesk on GitHub](https://github.com/abhinavxd/libredesk)
- [Releases](https://github.com/abhinavxd/libredesk/releases)

### Implementation Details

| Service | What runs inside | Volume | Port |
|---|---|---|---|
| LibreDesk | LibreDesk v2.9.2 (install/upgrade at start) | `/libredesk/uploads` (attachments) | 9000, public domain |
| Postgres | PostgreSQL 18 | `/var/lib/postgresql/data` | private |
| Redis | Redis 8.2 | `/data` | private |

**First login**

1. Open `https://{your-domain}`.
2. Sign in with the email `System` and the password from `LIBREDESK_SYSTEM_USER_PASSWORD` (Variables tab of the LibreDesk service).
3. Create agent accounts for yourself and your team under Admin, Agents, and use those for daily work; keep System for administration.
4. Add inboxes (email, live chat) under Admin, Inboxes. The root URL is already set to your Railway domain (Admin, General); change it there if you add a custom domain.

**System password.** When `LIBREDESK_SYSTEM_USER_PASSWORD` changes, the next start applies it and signs the System user out everywhere. It must follow LibreDesk's rule (10–72 characters with upper and lower case, a digit and a special character). A value that does not is ignored with a warning in the deploy log: an existing password stays, and a brand-new install gets a random System password until you set a valid one.

**Encryption key.** `LIBREDESK_APP__ENCRYPTION_KEY` (exactly 32 characters, generated) encrypts stored inbox and integration credentials. Never change it after the first start.

**Email.** Email inboxes fetch over IMAP and send over SMTP using the mail server you configure per inbox. Railway allows outbound SMTP only on the Pro plan; on other plans use live chat, or a mail provider that offers SMTP on a port your plan allows. Agent notifications use the notification SMTP settings under Admin.

**Live chat.** Create a live chat inbox and paste its widget snippet into your website; the widget talks to `https://{your-domain}`.

**Scaling and upgrades.** Keep one LibreDesk replica (attachments live on the volume). The stack idled at about 0.2 GB RAM in our tests and fits the Trial plan per service. All configuration keys can be set as `LIBREDESK_SECTION__KEY` variables (see `config.sample.toml` upstream). To upgrade, eject the repo, change the image tag and digest in `services/libredesk/Dockerfile`, and redeploy; `libredesk --upgrade` runs before the server starts. Back up Postgres first.

### Why Deploy LibreDesk on Railway?

Railway runs LibreDesk with managed Postgres and Redis, HTTPS and a persistent volume in one project, so a support desk is online in minutes. This template adds pinned versions, a database-backed healthcheck, an admin password set before the first request and the correct public URL out of the box.
