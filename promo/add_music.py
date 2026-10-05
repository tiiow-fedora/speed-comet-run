"""Adds royalty-free phonk under the hype edit (video untouched, audio remixed).
Music: Pixabay Content License, both tracks NOT Content ID registered (checked 2026-10-04):
  "Gym Phonk" by Sub_Clair   https://pixabay.com/music/phonk-gym-phonk-571899/
  "Sport Phonk" by Sub_Clair https://pixabay.com/music/phonk-sport-phonk-571905/
Each track starts at its drop so the beat lands on the opening BOOM. The SFX ducks the music (sidechain)."""
import subprocess, pathlib
ROOT = pathlib.Path(__file__).resolve().parent
TRACKS = {"gym": ("music/gym_phonk_sub_clair.mp3", 46.05), "sport": ("music/sport_phonk_sub_clair.mp3", 14.76)}
TOTAL, END_START = 19.5, 16.29  # from make_hype.py (end card starts at MAIN_LEN)

for fmt in ("vertical", "16x9"):
    video = ROOT / "out" / f"comet_run_hype_{fmt}.mp4"
    for name, (mp3, drop) in TRACKS.items():
        out = ROOT / "out" / f"comet_run_hype_{fmt}_{name}.mp4"
        fade_start = END_START + 1.4
        filt = (f"[1:a]atrim={drop}:{drop + TOTAL},asetpts=PTS-STARTPTS,aresample=44100,volume=0.62,"
                f"afade=t=out:st={fade_start}:d={TOTAL - fade_start}[mus];"
                f"[0:a]aresample=44100,asplit=2[sfx][key];"
                f"[mus][key]sidechaincompress=threshold=0.08:ratio=6:attack=5:release=250[duck];"
                f"[duck][sfx]amix=inputs=2:weights='1 0.9':normalize=0,alimiter=limit=0.95[a]")
        subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(video), "-i", str(ROOT / mp3),
                        "-filter_complex", filt, "-map", "0:v", "-map", "[a]", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
                        "-t", str(TOTAL), "-movflags", "+faststart", str(out)], check=True)
        print(out)
