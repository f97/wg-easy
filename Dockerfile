FROM docker.io/library/node:lts-alpine AS build
WORKDIR /app

# update corepack
RUN npm install --global corepack@latest
# Install pnpm
RUN corepack enable pnpm

# Copy Web UI
COPY src /app
WORKDIR /app
RUN npm ci --omit=dev &&\
    npm cache clean --force &&\
    mv node_modules /node_modules

# Copy build result to a new image.
# This saves a lot of disk space.
FROM alpine:3.18
COPY --from=build_node_modules /app /app

HEALTHCHECK --interval=1m --timeout=5s --retries=3 CMD /usr/bin/timeout 5s /bin/sh -c "/usr/bin/wg show | /bin/grep -q interface || exit 1"

# Copy the needed wg-password scripts
# COPY --from=build_node_modules /app/wgpw.sh /bin/wgpw
# RUN chmod +x /bin/wgpw

# Install Linux packages
RUN apk add --no-cache \
    nodejs \
    # dpkg \
    # dumb-init \
    # iptables \
    # iptables-legacy \
    wireguard-tools

# Use iptables-legacy
# RUN update-alternatives --install /usr/sbin/iptables iptables /usr/sbin/iptables-legacy 10 --slave /usr/sbin/iptables-restore iptables-restore /usr/sbin/iptables-legacy-restore --slave /usr/sbin/iptables-save iptables-save /usr/sbin/iptables-legacy-save

# Set Environment
# ENV DEBUG=Server,WireGuard

# Run Web UI
WORKDIR /app
CMD ["node", "server.js"]
