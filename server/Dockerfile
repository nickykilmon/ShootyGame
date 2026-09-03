# Self-building dedicated-server image.
# Downloads Godot, exports a headless Linux build of THIS project, and runs it as
# a WebSocket server. Docker hosts (Render, Koyeb, Railway, Fly...) build straight
# from this - you don't export anything locally.
#
# If your Godot version differs, change GODOT_VERSION (must match project.godot).

ARG GODOT_VERSION=4.7.2-stable

# ---------- build stage ----------
FROM debian:bookworm-slim AS build
ARG GODOT_VERSION
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl unzip ca-certificates && rm -rf /var/lib/apt/lists/*

RUN curl -fSL "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip" -o /tmp/godot.zip \
 && unzip /tmp/godot.zip -d /tmp \
 && mv "/tmp/Godot_v${GODOT_VERSION}_linux.x86_64" /usr/local/bin/godot \
 && chmod +x /usr/local/bin/godot

RUN VER_DIR="${GODOT_VERSION/-stable/.stable}" \
 && mkdir -p "/root/.local/share/godot/export_templates/${VER_DIR}" \
 && curl -fSL "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_export_templates.tpz" -o /tmp/tpl.tpz \
 && unzip /tmp/tpl.tpz -d /tmp/tpl \
 && mv /tmp/tpl/templates/* "/root/.local/share/godot/export_templates/${VER_DIR}/"

WORKDIR /src
COPY . /src
# The project's own export_presets.cfg is gitignored, so drop in a server one.
RUN cp /src/server/linux_export_presets.cfg /src/export_presets.cfg \
 && godot --headless --path /src --import || true \
 && mkdir -p /out \
 && godot --headless --path /src --export-release "LinuxServer" /out/game.x86_64 \
 && test -f /out/game.x86_64

# ---------- runtime stage ----------
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
      libgl1 libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 libxext6 \
      libfreetype6 libasound2 ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /out/game.x86_64 /app/game.x86_64
RUN chmod +x /app/game.x86_64
EXPOSE 9999
CMD ["/app/game.x86_64", "--headless", "--", "--server"]
