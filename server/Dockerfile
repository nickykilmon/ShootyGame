# Runs the pre-built headless server binary as a WebSocket dedicated server.
# You export server/build/game.x86_64 once from Godot (embed PCK = ON) and commit
# it; this image just copies and runs it.
#
# Render setting: Root Directory = server   (so the build context is this folder)

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
      libgl1 libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 libxext6 \
      libfreetype6 libasound2 ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY build/game.x86_64 /app/game.x86_64
RUN chmod +x /app/game.x86_64

EXPOSE 9999

# `--` passes --server through to the game (world.gd checks for it).
# The game binds to the PORT env var if the host sets one, else 9999.
CMD ["/app/game.x86_64", "--headless", "--", "--server"]
