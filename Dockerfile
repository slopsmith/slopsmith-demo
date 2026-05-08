FROM python:3.12-slim

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg git curl unzip nginx supervisor \
    fluidsynth fluid-soundfont-gm libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

# GoatCounter (linux-amd64)
RUN curl -sL https://github.com/arp242/goatcounter/releases/download/v2.7.0/goatcounter-v2.7.0-linux-amd64.gz \
    | gunzip > /usr/local/bin/goatcounter && chmod +x /usr/local/bin/goatcounter

# vgmstream-cli
RUN curl -sL https://github.com/vgmstream/vgmstream/releases/download/r2083/vgmstream-linux-cli.zip \
    -o /tmp/vgm.zip && unzip -o /tmp/vgm.zip -d /usr/local/bin/ \
    && chmod +x /usr/local/bin/vgmstream-cli && rm /tmp/vgm.zip

WORKDIR /app

# This ref changes on every push to slopsmith-demo, busting the cache for all
# subsequent git clone layers — so every build pulls fresh from GitHub.
ADD https://api.github.com/repos/byrongamatos/slopsmith-demo/git/refs/heads/main /tmp/build_ref

# Clone slopsmith core
RUN git clone --depth 1 https://github.com/byrongamatos/slopsmith.git /app

# byrongamatos plugins (all — none are committed to the slopsmith core repo)
# Excluded: cf (ToS), ug (ToS), rs-2d-highway, find-more, rooms, slopsmith-update-manager
RUN for plugin in \
      drums editor fretboard lyrics-karaoke lyrics-sync \
      metronome midi multiplayer nam-tone notedetect piano player-guide practice \
      sectionmap setlist stepmode studio tabimport tabview tones; do \
    git clone --depth 1 https://github.com/byrongamatos/slopsmith-plugin-${plugin}.git \
      /app/plugins/${plugin//-/_} 2>/dev/null || echo "skip $plugin"; \
  done

# Community plugins
RUN git clone --depth 1 https://github.com/alleexx/slopsmith-plugin-transpose-chords.git /app/plugins/transpose_chords \
 && git clone --depth 1 https://github.com/masc0t/slopsmith-plugin-invert-highway.git /app/plugins/invert_highway \
 && git clone --depth 1 https://github.com/masc0t/slopsmith-plugin-the-daily.git /app/plugins/the_daily \
 && git clone --depth 1 https://github.com/masc0t/slopsmith-plugin-themes.git /app/plugins/themes \
 && git clone --depth 1 https://github.com/narvasus/slopsmith-plugin-stem-mixer.git /app/plugins/stem_mixer \
 && git clone --depth 1 https://github.com/renanboni/slopsmith-plugin-jumpingtab.git /app/plugins/jumpingtab \
 && git clone --depth 1 https://github.com/topkoa/slopsmith-plugin-guitar-theory.git /app/plugins/guitar_theory \
 && git clone --depth 1 https://github.com/topkoa/slopsmith-plugin-splitscreen.git /app/plugins/splitscreen \
 && git clone --depth 1 https://github.com/topkoa/slopsmith-plugin-stems.git /app/plugins/stems

# Install Python deps
RUN pip install --no-cache-dir -r /app/requirements.txt

# Install per-plugin requirements
RUN find /app/plugins -maxdepth 2 -name requirements.txt \
    -exec pip install --no-cache-dir -r {} \;

# Overlay: add demo.js + demo.css, then patch slopsmith's index.html in-place
# (no overlay index.html — we patch the live one so it always tracks slopsmith updates)
COPY overlay/static/ /app/static/
RUN python3 - << 'PYEOF'
import re
path = '/app/static/index.html'
html = open(path).read()

# 1. Demo CSS in <head>
html = html.replace('</head>', '    <link rel="stylesheet" href="/static/demo.css">\n</head>', 1)

# 2. Demo banner at top of <body>
html = re.sub(
    r'(<body\b[^>]*>)',
    r'\1\n    <div id="demo-banner">DEMO MODE — your edits are temporary and not saved</div>',
    html, count=1
)

# 3. demo.js + SLOPSMITH_DEMO flag injected before highway.js
html = html.replace(
    '<script src="/static/highway.js">',
    '<script>window.SLOPSMITH_DEMO = true;</script>\n    <script src="/static/demo.js"></script>\n    <script src="/static/highway.js">',
    1
)

open(path, 'w').write(html)
print('index.html patched OK')
PYEOF

# Demo content
COPY dlc/ /app/dlc/
COPY nam-profiles/ /app/nam-profiles/
COPY assets/ /app/demo-assets/

# Nginx + supervisord config
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisor/conf.d/slopsmith-demo.conf

ENV PYTHONPATH=/app/lib:/app
ENV SLOPSMITH_DEMO_MODE=1
ENV DLC_DIR=/app/dlc
ENV NAM_PROFILES_DIR=/app/nam-profiles
ENV CONFIG_DIR=/config

EXPOSE 7860

COPY start.sh /start.sh
RUN chmod +x /start.sh
CMD ["/start.sh"]
