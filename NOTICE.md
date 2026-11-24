# NOTICE: LibreDesk template

This is a community template. It is not made, endorsed or supported by the LibreDesk project or Railway.

## Components

| Component | Source | License | How it is used |
|---|---|---|---|
| LibreDesk v2.9.2 (`libredesk/libredesk:v2.9.2@sha256:1c5a234b113b6fa7b4170219a4e1063d8a9e4a396d4811b2ea03fdfcd02c63de`) | https://github.com/abhinavxd/libredesk | AGPL-3.0 | Official image, unmodified, used as the base image. Source: https://github.com/abhinavxd/libredesk/tree/v2.9.2 |
| postgresql15-client (Alpine 3.18 package) | https://www.postgresql.org/ | PostgreSQL License | `pg_isready` and `psql` in the start script |
| PostgreSQL 18 (`ghcr.io/railwayapp-templates/postgres-ssl`) | https://github.com/railwayapp-templates/postgres-ssl | PostgreSQL License | Database |
| Redis 8.2 | https://hub.docker.com/_/redis | RSALv2/SSPLv1/AGPLv3 | Sessions, cache, queues |
| LibreDesk launcher logo (`static/public/launcher-logo-black.png`, via jsDelivr) | LibreDesk repository | Project asset | Listing and service icon, to identify the app |

## Files written for this template

`services/libredesk/Dockerfile`, `services/libredesk/railway-start.sh` and the documentation were written for this template and are offered under the MIT License.

## Upstream files checked (tag v2.9.2)

- `Dockerfile`, `docker-compose.yml` (install/upgrade commands, `/libredesk/uploads` volume), `config.sample.toml` (keys, `LIBREDESK_` env mapping)
- `cmd/install.go` (`--install --idempotent-install`, `LIBREDESK_SYSTEM_USER_PASSWORD`, `--set-system-user-password` reading stdin), `cmd/init.go` (config loading, 32-character encryption key check, Redis URL), `cmd/main.go` (DB settings loaded after env), `cmd/handlers.go` (`/health` pings the database)
- `internal/user/user.go` (password policy, System user), `schema.sql` (default `app.root_url`)

## Market templates

The Railway marketplace templates `libredesk`, `libredesk-complete-setup` and `libredesk-helpdesk` were reviewed for features only. No files or text were copied.
