# TEMPLATE: LibreDesk 2.9 (Helpdesk, Live Chat, Postgres, Redis)

Composer spec. `template.json` is the machine-readable copy.

## Services

| Service | Source | Public | Healthcheck | Volume | Restart |
|---|---|---|---|---|---|
| LibreDesk | repo `baranberkay96/libredesk-railway`, root `/services/libredesk` (`FROM libredesk/libredesk:v2.9.2@sha256:1c5a234b…`, 2026-10-31, + postgresql15-client) | 9000 | `/health` (DB ping), 600 s | `/libredesk/uploads` | ALWAYS |
| Postgres | `postgres-ssl:18.6@sha256:4fc833b4…` | no | — | `/var/lib/postgresql/data` | ON_FAILURE |
| Redis | `redis:8.2.11@sha256:b0b01167…` | no | — | `/data` | ON_FAILURE |

No required inputs. Generated: `LIBREDESK_SYSTEM_USER_PASSWORD` (24 alnum + `-Ld7` so LibreDesk's policy is always met), `LIBREDESK_APP__ENCRYPTION_KEY` (32), DB/Redis passwords.

## Design

- `railway-start` (sh): PORT check → `[::]:$PORT`; encryption key ≠ 32 chars → stable sha256-derived key + warning (upstream would `log.Fatalf`); password policy check (upstream would `log.Fatalf` on a weak password at install) → lock mode; `pg_isready` wait (10 min); `--install --idempotent-install --yes` only when `settings` table is missing (System admin created with the variable, or random in lock mode); `--upgrade --yes`; changed password (sha256 fingerprint with the encryption key in `/libredesk/uploads/.railway/`, 0700) → `--set-system-user-password` via stdin (ends System sessions); root URL/favicon URL replaced only while they are upstream's `localhost` defaults; `exec ./libredesk`.
- STANDARD 8.37: everything above runs before the port opens; there is no first-run web installer.
- Attachments on the volume (`fs` provider); S3 provider possible via `LIBREDESK_UPLOAD__PROVIDER=s3` + `LIBREDESK_UPLOAD__S3__*`.

## Improvements over market templates

- `libredesk` (147 deploys): `latest` image, `postgres:17-alpine` without Railway's SSL image conventions, `debug` logging, empty System password (random, needs a shell to reset), localhost root URL, `|| true` around install/upgrade so failures go unnoticed. `libredesk-complete-setup`: `latest`, `PASSWORD=Aa1!…`. `libredesk-helpdesk`: third-party repo with a gateway and Mailpit. This one: pinned image, generated policy-compliant admin password that can be rotated from the variable, install/upgrade failures stop the start, root URL set, DB-backed healthcheck.

## Resources

| Service | Idle RAM | Typical | CPU |
|---|---|---|---|
| LibreDesk | see report | 0.1–0.3 GB | low |
| Postgres | ≈0.1 GB | 0.1–0.3 GB | low |
| Redis | ≈0.03 GB | — | low |

Estimated cost ≈ $3–5/month + volumes. Minimum plan: Hobby (3 services); each fits Trial.

## Verification checklist

- `/health` 200; login as `System` with the variable's password; a wrong password is refused.
- Create an agent, a team and a live chat inbox; send a widget message and see the conversation in the inbox.
- Root URL in Admin > General is `https://{domain}`.
- Upload an attachment; it survives a redeploy.
- `LIBREDESK_SYSTEM_USER_PASSWORD=abc` → SUCCESS, warning, old password works; a new valid value → new password works.

## Open questions

- Email inbound/outbound with a real mail provider not tested (SMTP is Pro-only on Railway).
