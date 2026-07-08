#!/usr/bin/env python3
"""LAST SIGNAL — original audio generator.
Synthesizes all music loops and sound effects with numpy (no samples, no external assets).
Outputs 44.1kHz 16-bit mono WAV into ../audio/music and ../audio/sfx.
Run:  python3 tools/generate_audio.py   (from the project root)
"""
import numpy as np, wave, os, struct

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MUSIC = os.path.join(ROOT, "audio", "music")
SFX = os.path.join(ROOT, "audio", "sfx")
os.makedirs(MUSIC, exist_ok=True)
os.makedirs(SFX, exist_ok=True)

def write_wav(path, sig):
    sig = np.clip(sig, -1.0, 1.0)
    data = (sig * 32767).astype(np.int16)
    with wave.open(path, "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(data.tobytes())

def mtof(m): return 440.0 * (2.0 ** ((m - 69) / 12.0))

def osc(freq, dur, kind="sine", detune=0.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    ph = 2 * np.pi * (freq + detune) * t
    if kind == "sine": return np.sin(ph)
    if kind == "square": return np.sign(np.sin(ph))
    if kind == "saw": return 2.0 * ((freq * t) % 1.0) - 1.0
    if kind == "tri": return 2.0 * np.abs(2.0 * ((freq * t) % 1.0) - 1.0) - 1.0
    return np.sin(ph)

def env_ad(n, a, d, sustain=0.0, rel=0.0, total=None):
    total = total or n
    e = np.zeros(total)
    ai = min(total, max(1, int(a * SR)))
    e[:ai] = np.linspace(0, 1, ai)
    di = max(1, int(d * SR))
    end = min(total, ai + di)
    if end > ai:
        e[ai:end] = np.linspace(1, sustain, end - ai)
    if sustain > 0 and end < total:
        e[end:] = sustain
    ri = int(rel * SR) if rel else 0
    if ri and ri < total:
        e[-ri:] *= np.linspace(1, 0, ri)
    return e[:total]

def note(freq, dur, kind="saw", vol=0.3, a=0.005, d=0.15, sustain=0.0, rel=0.05):
    n = int(dur * SR)
    sig = osc(freq, dur, kind)
    e = env_ad(n, a, d, sustain, rel, n)
    return sig * e * vol

def noise(dur, vol=0.3, a=0.001, d=0.1):
    n = int(dur * SR)
    sig = np.random.uniform(-1, 1, n)
    return sig * env_ad(n, a, d, 0, 0, n) * vol

def lowpass(sig, alpha=0.2):
    out = np.zeros_like(sig); acc = 0.0
    for i in range(len(sig)):
        acc += alpha * (sig[i] - acc); out[i] = acc
    return out

def place(buf, sig, at):
    i = int(at * SR); j = min(len(buf), i + len(sig))
    if i < len(buf): buf[i:j] += sig[:j - i]

def mix(*sigs):
    n = max(len(s) for s in sigs)
    out = np.zeros(n)
    for s in sigs:
        out[:len(s)] += s
    return out

# ----------------------------------------------------------------- MUSIC
MINOR = [0, 2, 3, 5, 7, 8, 10]
PHRYG = [0, 1, 3, 5, 7, 8, 10]

def make_music(root, scale, bpm, bars, lead=False, dark=1.0, arp_kind="square"):
    spb = 60.0 / bpm
    step = spb / 4.0            # 16th
    total = bars * 4 * spb
    buf = np.zeros(int(total * SR) + SR)
    n_steps = bars * 16
    for i in range(n_steps):
        t = i * step
        bar_pos = i % 16
        # bass on beats
        if bar_pos % 4 == 0:
            deg = [0, 3, 4, 3][(bar_pos // 4) % 4]
            f = mtof(root - 12 + scale[deg % len(scale)])
            place(buf, note(f, spb * 0.9, "tri", 0.34 * dark, 0.005, spb * 0.6, 0.15, 0.1), t)
        # arp every 2 steps
        if bar_pos % 2 == 0:
            idx = (i // 2) % len(scale)
            octave = 12 * (1 + ((i // (len(scale) * 2)) % 2))
            f = mtof(root + octave + scale[idx])
            place(buf, note(f, step * 1.6, arp_kind, 0.10, 0.004, 0.12, 0, 0.03), t)
        # pad chord each bar
        if bar_pos == 0:
            for d3 in [0, 2, 4]:
                f = mtof(root + scale[d3 % len(scale)])
                place(buf, note(f, spb * 3.6, "saw", 0.05, 0.4, 0.5, 0.5, 0.6), t)
        # sparse lead
        if lead and bar_pos in (6, 14):
            idx = (i // 5) % len(scale)
            f = mtof(root + 24 + scale[idx])
            place(buf, note(f, step * 3, "saw", 0.08, 0.01, 0.2, 0, 0.1), t)
        # hat
        if bar_pos % 4 == 2:
            place(buf, noise(0.03, 0.05), t)
        # kick
        if bar_pos % 4 == 0:
            k = osc(90, 0.12, "sine") * env_ad(int(0.12 * SR), 0.001, 0.11, 0, 0, int(0.12 * SR)) * 0.5
            place(buf, k, t)
    buf = buf[:int(total * SR)]
    buf = 0.9 * buf / (np.max(np.abs(buf)) + 1e-6)
    return buf

write_wav(os.path.join(MUSIC, "menu.wav"), make_music(45, MINOR, 84, 8, lead=False, dark=0.9, arp_kind="tri"))
write_wav(os.path.join(MUSIC, "stage1.wav"), make_music(45, MINOR, 104, 8, lead=False, arp_kind="square"))
write_wav(os.path.join(MUSIC, "stage2.wav"), make_music(43, MINOR, 116, 8, lead=True, arp_kind="square"))
write_wav(os.path.join(MUSIC, "stage3.wav"), make_music(41, PHRYG, 126, 8, lead=True, arp_kind="saw"))
write_wav(os.path.join(MUSIC, "boss.wav"), make_music(40, PHRYG, 146, 8, lead=True, dark=1.1, arp_kind="saw"))
write_wav(os.path.join(MUSIC, "victory.wav"), make_music(48, MINOR, 110, 8, lead=True, arp_kind="tri"))

# ----------------------------------------------------------------- SFX
def slide(f0, f1, dur, kind="square", vol=0.3):
    n = int(dur * SR); t = np.arange(n) / SR
    f = np.linspace(f0, f1, n)
    ph = 2 * np.pi * np.cumsum(f) / SR
    sig = np.sign(np.sin(ph)) if kind == "square" else (np.sin(ph) if kind == "sine" else 2 * ((f * t) % 1) - 1)
    return sig * env_ad(n, 0.003, dur, 0, 0, n) * vol

def save_sfx(name, sig):
    write_wav(os.path.join(SFX, name + ".wav"), np.clip(sig, -1, 1))

save_sfx("shoot", slide(620, 300, 0.09, "square", 0.35))
save_sfx("hit", lowpass(noise(0.05, 0.5), 0.5))
save_sfx("enemy_die", mix(slide(300, 90, 0.14, "square", 0.4), noise(0.09, 0.25)))
save_sfx("player_hurt", slide(220, 70, 0.28, "saw", 0.5))
save_sfx("pickup", slide(880, 1320, 0.07, "sine", 0.3))
save_sfx("scrap", slide(1046, 1568, 0.08, "square", 0.28))
save_sfx("ui_click", slide(660, 660, 0.05, "square", 0.3))
save_sfx("nova", mix(slide(400, 80, 0.35, "sine", 0.5), lowpass(noise(0.3, 0.3), 0.3)))
save_sfx("boss_hit", lowpass(noise(0.06, 0.5), 0.4))
lvl = np.zeros(int(0.5 * SR))
for k, f in enumerate([523, 659, 784, 1046]):
    place(lvl, note(f, 0.16, "square", 0.3), k * 0.07)
save_sfx("level_up", lvl)
cache = np.zeros(int(0.6 * SR))
for k, f in enumerate([659, 831, 988, 1319]):
    place(cache, note(f, 0.2, "tri", 0.3), k * 0.08)
save_sfx("cache", cache)
bd = np.zeros(int(1.0 * SR))
place(bd, lowpass(noise(0.7, 0.5), 0.2), 0.0)
for k, f in enumerate([392, 330, 262, 196]):
    place(bd, note(f, 0.4, "saw", 0.3), k * 0.13)
save_sfx("boss_die", bd)
go = np.zeros(int(1.2 * SR))
for k, f in enumerate([330, 294, 247, 196, 165]):
    place(go, note(f, 0.5, "saw", 0.28), k * 0.2)
save_sfx("game_over", go)
vic = np.zeros(int(1.0 * SR))
for k, f in enumerate([523, 659, 784, 1046, 1319]):
    place(vic, note(f, 0.3, "square", 0.3), k * 0.13)
save_sfx("victory", vic)

print("Audio generated:")
print("  music:", sorted(os.listdir(MUSIC)))
print("  sfx:", sorted(os.listdir(SFX)))
