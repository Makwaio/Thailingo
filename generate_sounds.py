"""
Generates programmatic WAV sound effects for the Thai Lab app.
Uses only Python's built-in wave + struct modules — no external dependencies.
"""

import wave, struct, math, os

RATE = 44100

def _pack(samples):
    clamped = [max(-32767, min(32767, int(s))) for s in samples]
    return struct.pack(f'<{len(clamped)}h', *clamped)

def write_wav(path, samples):
    with wave.open(path, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(_pack(samples))
    print(f'  wrote {path}  ({len(samples)/RATE:.2f}s)')

def silence(dur):
    return [0] * int(RATE * dur)

def sine(freq, dur, amp=0.5):
    n = int(RATE * dur)
    return [amp * 32767 * math.sin(2 * math.pi * freq * i / RATE) for i in range(n)]

def sweep(f0, f1, dur, amp=0.55):
    """Frequency sweep with proper phase tracking."""
    n = int(RATE * dur)
    out, phase = [], 0.0
    for i in range(n):
        t = i / n
        freq = f0 + (f1 - f0) * t
        out.append(amp * 32767 * math.sin(phase))
        phase += 2 * math.pi * freq / RATE
    return out

def envelope(samples, attack=0.02, release=0.12):
    """Apply attack+release linear envelope."""
    n = len(samples)
    atk = int(RATE * attack)
    rel = int(RATE * release)
    result = []
    for i, s in enumerate(samples):
        if i < atk:
            env = i / atk
        elif i >= n - rel:
            env = max(0.0, (n - i) / rel)
        else:
            env = 1.0
        result.append(s * env)
    return result

def womp(f0, f1, dur, amp=0.60):
    """Single descending 'womp' tone."""
    raw = sweep(f0, f1, dur, amp)
    return envelope(raw, attack=0.02, release=dur * 0.4)

# ── sfx_wrong.wav — single descending womp ─────────────────────────────
def make_wrong():
    samples = womp(300, 90, 0.50, amp=0.65)
    write_wav('assets/audio/sfx_wrong.wav', samples)

# ── sfx_gameover.wav — three womps, third dramatic ─────────────────────
def make_gameover():
    w1 = womp(320, 100, 0.45, amp=0.55)
    w2 = womp(290, 80,  0.50, amp=0.62)
    w3 = womp(260, 45,  0.90, amp=0.72)  # longer, lower, louder
    samples = w1 + silence(0.30) + w2 + silence(0.30) + w3
    write_wav('assets/audio/sfx_gameover.wav', samples)

# ── sfx_complete.wav — ascending happy fanfare ─────────────────────────
def make_complete():
    def note(freq, dur, amp=0.38):
        raw = sine(freq, dur, amp)
        return envelope(raw, attack=0.01, release=dur * 0.35)

    # C5-E5-G5-C6 ascending arpeggio, then hold
    melody = (
        note(523, 0.12) + silence(0.03) +
        note(659, 0.12) + silence(0.03) +
        note(784, 0.14) + silence(0.03) +
        note(1047, 0.30)
    )
    write_wav('assets/audio/sfx_complete.wav', melody)

# ── sfx_combo.wav — quick rising ping ──────────────────────────────────
def make_combo():
    raw = sweep(440, 1000, 0.18, amp=0.42)
    samples = envelope(raw, attack=0.008, release=0.07)
    write_wav('assets/audio/sfx_combo.wav', samples)

# ── sfx_click.wav — very short soft tick ───────────────────────────────
def make_click():
    raw = sine(700, 0.055, amp=0.22)
    samples = envelope(raw, attack=0.004, release=0.025)
    write_wav('assets/audio/sfx_click.wav', samples)

# ── Run all ────────────────────────────────────────────────────────────
os.makedirs('assets/audio', exist_ok=True)
print('Generating sound effects...')
make_wrong()
make_gameover()
make_complete()
make_combo()
make_click()
print('Done.')
