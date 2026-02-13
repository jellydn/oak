# Ambient Sound Assets

Oak looks up bundled ambient tracks from this folder first, then falls back to generated audio when files are missing.

## Required filenames

Add one file per track using the exact base names below:

- `ambient_rain`
- `ambient_forest`
- `ambient_cafe`
- `ambient_brown_noise`
- `ambient_lofi`

Supported extensions:

- `.m4a` (preferred)
- `.wav`
- `.mp3`

Example:

- `ambient_rain.m4a`
- `ambient_forest.m4a`
- `ambient_cafe.m4a`
- `ambient_brown_noise.m4a`
- `ambient_lofi.m4a`

## Recommended sources

- Mixkit: free tracks/effects with license terms at https://mixkit.co/license/
- Pixabay Music/SFX: license terms at https://pixabay.com/service/license-summary/
- Freesound: use CC0 filters or verify attribution requirements: https://freesound.org/help/faq/

## Production quality checklist

- Export as AAC (`.m4a`) at 44.1 kHz or 48 kHz.
- Trim to seamless loop boundaries (no clicks at loop point).
- Normalize to consistent loudness across all tracks.
- Keep each track long enough (for example 2-3 minutes) to avoid obvious repetition.
- Prefer ~3 minute source files to keep raw `.wav` assets under GitHub's 50 MB recommended limit.

## Useful commands

Generate 3-minute placeholder sources for all required tracks:

```bash
ffmpeg -f lavfi -i "anoisesrc=color=white:amplitude=0.12" -af "highpass=f=400,lowpass=f=7000" -t 180 ambient_rain.wav
ffmpeg -f lavfi -i "anoisesrc=color=pink:amplitude=0.10" -af "highpass=f=200,lowpass=f=5000" -t 180 ambient_forest.wav
ffmpeg -f lavfi -i "anoisesrc=color=pink:amplitude=0.08" -af "highpass=f=120,lowpass=f=3200" -t 180 ambient_cafe.wav
ffmpeg -f lavfi -i "anoisesrc=color=brown:amplitude=0.18" -t 180 ambient_brown_noise.wav
ffmpeg -f lavfi -i "anoisesrc=color=violet:amplitude=0.05" -af "lowpass=f=2800" -t 180 ambient_lofi.wav
```

Convert generated WAV files to ready-to-bundle `.m4a` assets:

```bash
ffmpeg -i ambient_rain.wav -ar 48000 -ac 2 -c:a aac -b:a 192k ambient_rain.m4a
ffmpeg -i ambient_forest.wav -ar 48000 -ac 2 -c:a aac -b:a 192k ambient_forest.m4a
ffmpeg -i ambient_cafe.wav -ar 48000 -ac 2 -c:a aac -b:a 192k ambient_cafe.m4a
ffmpeg -i ambient_brown_noise.wav -ar 48000 -ac 2 -c:a aac -b:a 192k ambient_brown_noise.m4a
ffmpeg -i ambient_lofi.wav -ar 48000 -ac 2 -c:a aac -b:a 192k ambient_lofi.m4a
```
