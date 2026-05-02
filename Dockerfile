FROM python:3.12-slim

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

# Clone slopsmith core (feat/demo-mode until #148 merges)
RUN git clone --depth 1 --branch feat/demo-mode https://github.com/byrongamatos/slopsmith.git /app

# byrongamatos plugins
# (built-ins drums/editor/lyrics_karaoke/lyrics_sync/notedetect/piano/studio already in /app/plugins/)
# Excluded: cf (ToS), ug (ToS), rs-2d-highway, find-more, rooms, slopsmith-update-manager
RUN for plugin in \
      3dhighway discextract fretboard metronome midi multiplayer \
      nam-tone practice profileimport rs1extract sectionmap setlist \
      stepmode tabimport tabview tones; do \
    git clone --depth 1 https://github.com/byrongamatos/slopsmith-plugin-${plugin}.git \
      /app/plugins/${plugin} 2>/dev/null || echo "skip $plugin"; \
  done

# Community plugins
RUN git clone --depth 1 https://github.com/alleexx/slopsmith-plugin-transpose-chords.git /app/plugins/transpose_chords \
 && git clone --depth 1 https://github.com/masc0t/slopsmith-plugin-invert-highway.git /app/plugins/invert_highway \
 && git clone --depth 1 https://github.com/masc0t/slopsmith-plugin-midi-capo.git /app/plugins/midi_capo \
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

# Overlay: replace index.html, add demo.js + demo.css
COPY overlay/static/ /app/static/

# Demo content
COPY dlc/ /app/dlc/
COPY nam-profiles/ /app/nam-profiles/

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
