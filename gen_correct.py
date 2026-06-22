import wave, struct, math

RATE = 44100

def tone(freq, dur, amp=0.55, fade_in=0.015, fade_out=0.04):
    n = int(RATE * dur)
    fi = int(RATE * fade_in)
    fo = int(RATE * fade_out)
    samples = []
    for i in range(n):
        t = i / RATE
        v = math.sin(2 * math.pi * freq * t)
        # fade in
        if i < fi:
            v *= i / fi
        # fade out
        elif i >= n - fo:
            v *= (n - i) / fo
        samples.append(v * amp)
    return samples

def silence(dur):
    return [0.0] * int(RATE * dur)

def write_wav(path, samples):
    peak = max(abs(s) for s in samples)
    if peak > 0:
        samples = [s / peak * 0.92 for s in samples]
    with wave.open(path, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        for s in samples:
            f.writeframes(struct.pack('<h', int(s * 32767)))

# C5 → E5 → G5 ascending "ding ding DING!"
data = (
    tone(523, 0.15, amp=0.50)   # C5 — short
    + silence(0.05)
    + tone(659, 0.15, amp=0.55)  # E5 — short
    + silence(0.05)
    + tone(784, 0.30, amp=0.62, fade_out=0.12)  # G5 — longer, slow fade
)

write_wav('assets/audio/sfx_correct.wav', data)
print(f"Written sfx_correct.wav  ({len(data)/RATE:.2f}s)")
