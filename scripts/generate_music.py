#!/usr/bin/env python3
"""
Generate a synthetic ambient background music file for Thailingo app.
Uses only Python standard library (wave + struct) — no dependencies needed.
Run: python scripts/generate_music.py

Output: assets/audio/ambient_bg.wav
"""

import wave
import struct
import math
import os
from pathlib import Path

AUDIO_DIR = Path(__file__).parent.parent / "assets" / "audio"
AUDIO_DIR.mkdir(parents=True, exist_ok=True)
OUT_FILE = AUDIO_DIR / "ambient_bg.wav"

SAMPLE_RATE = 44100
CHANNELS = 1
BITS = 16
DURATION_SECS = 60   # 1 minute loop
AMPLITUDE = 8000

def note_freq(note: str) -> float:
    """Return frequency for note name like C4, D4, E4 etc."""
    semitone_map = {
        'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3,
        'E': 4, 'F': 5, 'F#': 6, 'Gb': 6, 'G': 7, 'G#': 8,
        'Ab': 8, 'A': 9, 'A#': 10, 'Bb': 10, 'B': 11,
    }
    if len(note) >= 2 and note[-1].isdigit():
        octave = int(note[-1])
        name = note[:-1]
    else:
        octave = 4
        name = note
    semitone = semitone_map.get(name, 0)
    return 440.0 * (2 ** ((semitone + (octave - 4) * 12 - 9) / 12.0))

def sine(t: float, freq: float, amp: float = 1.0) -> float:
    return amp * math.sin(2 * math.pi * freq * t)

def envelope(t: float, total: float, attack: float = 0.05, release: float = 0.1) -> float:
    if t < attack:
        return t / attack
    if t > total - release:
        return (total - t) / release
    return 1.0

# Pentatonic scale (C major pentatonic — peaceful, suits ambient music)
PENTATONIC = ['C4', 'D4', 'E4', 'G4', 'A4', 'C5']

# Simple chord progression: C - G - Am - F (loops every 16 beats at 80 BPM)
BPM = 72
BEAT = 60.0 / BPM
MELODY_NOTES = [
    # (note, start_beat, duration_beats)
    ('C4', 0, 2), ('E4', 2, 2), ('G4', 4, 2), ('E4', 6, 2),
    ('D4', 8, 2), ('F4', 10, 2), ('A4', 12, 2), ('G4', 14, 2),
    ('C4', 16, 2), ('E4', 18, 2), ('G4', 20, 2), ('A4', 22, 2),
    ('F4', 24, 2), ('G4', 26, 2), ('E4', 28, 2), ('C4', 30, 4),
]
PATTERN_BEATS = 34
PATTERN_SECS = PATTERN_BEATS * BEAT

BASS_NOTES = [
    ('C3', 0, 4), ('G2', 4, 4), ('A2', 8, 4), ('F2', 12, 4),
    ('C3', 16, 4), ('G2', 20, 4), ('A2', 24, 4), ('F2', 28, 4),
]

def generate_samples():
    total = DURATION_SECS * SAMPLE_RATE
    samples = [0.0] * total

    def add_note(freq: float, start_s: float, dur_s: float, amp: float = 1.0):
        start = int(start_s * SAMPLE_RATE)
        end = min(int((start_s + dur_s) * SAMPLE_RATE), total)
        for i in range(start, end):
            t = (i - start) / SAMPLE_RATE
            env = envelope(t, dur_s, attack=0.02 * dur_s, release=0.15 * dur_s)
            samples[i] += sine(t, freq, amp * env)

    # Repeat pattern to fill duration
    pattern_secs = PATTERN_SECS
    t_offset = 0.0
    while t_offset < DURATION_SECS:
        for (note, beat, dur) in MELODY_NOTES:
            start = t_offset + beat * BEAT
            if start >= DURATION_SECS:
                break
            add_note(note_freq(note), start, dur * BEAT * 0.85, amp=0.45)
        for (note, beat, dur) in BASS_NOTES:
            start = t_offset + beat * BEAT
            if start >= DURATION_SECS:
                break
            add_note(note_freq(note), start, dur * BEAT * 0.9, amp=0.25)
        # Pad chord (sustained)
        for chord_note, beat in [('C4', 0), ('E4', 0), ('G4', 0)]:
            add_note(note_freq(chord_note), t_offset, 8 * BEAT, amp=0.1)
        for chord_note, beat in [('A3', 8), ('C4', 8), ('E4', 8)]:
            add_note(note_freq(chord_note), t_offset + 8 * BEAT, 8 * BEAT, amp=0.1)
        t_offset += pattern_secs

    # Normalize to prevent clipping
    max_val = max(abs(s) for s in samples) or 1.0
    scale = min(1.0, 0.9 / max_val)
    return [int(s * AMPLITUDE * scale) for s in samples]

def write_wav(samples: list, path: Path):
    with wave.open(str(path), 'w') as wf:
        wf.setnchannels(CHANNELS)
        wf.setsampwidth(BITS // 8)
        wf.setframerate(SAMPLE_RATE)
        data = struct.pack(f'<{len(samples)}h', *samples)
        wf.writeframes(data)

def main():
    print("Generating ambient background music...")
    print(f"Duration: {DURATION_SECS}s  BPM: {BPM}  Sample rate: {SAMPLE_RATE}Hz")

    samples = generate_samples()
    write_wav(samples, OUT_FILE)

    size_kb = OUT_FILE.stat().st_size / 1024
    print(f"✓ Written: {OUT_FILE}")
    print(f"  File size: {size_kb:.1f} KB")
    print("\nTo use in Flutter, add 'assets/audio/ambient_bg.wav' to pubspec.yaml assets.")
    print("(Consider converting to .mp3 with ffmpeg for smaller size)")

if __name__ == "__main__":
    main()
