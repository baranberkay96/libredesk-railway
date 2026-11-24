# syntax=docker/dockerfile:1
#
# LibreDesk 2.9.2 for Railway.
#
# Base: the official image (Alpine 3.18 + the libredesk binary), tag v2.9.2
# pinned by digest (pushed 2026-10-31). To upgrade, change the tag and digest
# together (Docker Hub, libredesk/libredesk) and redeploy; the start script
# runs "libredesk --upgrade" before the server starts.
#
# Added: postgresql-client (pg_isready to wait for the database, psql to set
# the root URL once) and the start script.
FROM libredesk/libredesk:v2.9.2@sha256:1c5a234b113b6fa7b4170219a4e1063d8a9e4a396d4811b2ea03fdfcd02c63de

RUN apk add --no-cache postgresql15-client

COPY --chmod=0755 railway-start.sh /usr/local/bin/railway-start

ENV PORT=9000
EXPOSE 9000
WORKDIR /libredesk
ENTRYPOINT ["/usr/local/bin/railway-start"]
