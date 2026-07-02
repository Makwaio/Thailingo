"""
Generate skeet shooter sound effects.
Run: python scripts/generate_skeet_sounds.py
"""

import wave, struct, math, random, os

def generate_sling_sound():
    sample_rate = 44100
    duration = 0.25
    frames = []
    for i in range(int(sample_rate * duration)):
        t = i / sample_rate
        freq = 800 - (t / duration * 600)
        if t < 0.02:
            amp = t / 0.02
        else:
            amp = math.exp(-(t - 0.02) * 15)
        noise = (random.random() - 0.5) * 0.3
        sample = amp * (
            math.sin(2 * math.pi * freq * t) * 0.7 + noise
        ) * 0.5
        value = int(sample * 32767 * 0.5)
        frames.append(struct.pack('<h', max(-32767, min(32767, value))))
    os.makedirs('assets/audio', exist_ok=True)
    with wave.open('assets/audio/sfx_skeet_launch.wav', 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(sample_rate)
        f.writeframes(b''.join(frames))
    print('Generated sfx_skeet_launch.wav')

def generate_explosion_sound():
    sample_rate = 44100
    duration = 0.35
    frames = []
    for i in range(int(sample_rate * duration)):
        t = i / sample_rate
        noise = (random.random() - 0.5)
        low_freq = math.sin(2 * math.pi * 60 * t)
        mid_freq = math.sin(2 * math.pi * 150 * t)
        amp = math.exp(-t * 8)
        sample = amp * (
            noise * 0.6 + low_freq * 0.3 + mid_freq * 0.1
        ) * 0.5
        value = int(sample * 32767)
        frames.append(struct.pack('<h', max(-32767, min(32767, value))))
    with wave.open('assets/audio/sfx_skeet_explosion.wav', 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(sample_rate)
        f.writeframes(b''.join(frames))
    print('Generated sfx_skeet_explosion.wav')

generate_sling_sound()
generate_explosion_sound()
print('Done!')
