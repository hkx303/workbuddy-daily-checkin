#!/usr/bin/env python3
"""Verify that WorkBuddy's claim button is in its light completed state."""

from __future__ import annotations

import struct
import sys
from pathlib import Path


def average_button_brightness(bmp_path: Path, center_x: int, center_y: int) -> float:
    data = bmp_path.read_bytes()
    if data[:2] != b"BM":
        raise ValueError("expected a BMP image")

    pixel_offset = struct.unpack_from("<I", data, 10)[0]
    dib_size = struct.unpack_from("<I", data, 14)[0]
    if dib_size < 40:
        raise ValueError("unsupported BMP header")

    width, height = struct.unpack_from("<ii", data, 18)
    bits_per_pixel = struct.unpack_from("<H", data, 28)[0]
    compression = struct.unpack_from("<I", data, 30)[0]
    # sips writes 32-bit BMP using BI_BITFIELDS (compression value 3).
    # RGB bytes remain at the start of each pixel, so it is safe to sample.
    if width <= 0 or height == 0 or bits_per_pixel not in (24, 32) or compression not in (0, 3):
        raise ValueError("unsupported BMP pixel format")

    absolute_height = abs(height)
    bytes_per_pixel = bits_per_pixel // 8
    row_stride = ((width * bytes_per_pixel + 3) // 4) * 4
    samples: list[float] = []

    # Sample a compact area at the button center, avoiding its rounded edges.
    for y in range(center_y - 5, center_y + 6):
        for x in range(center_x - 10, center_x + 11):
            if not (0 <= x < width and 0 <= y < absolute_height):
                raise ValueError("button sample is outside the screenshot")
            source_y = absolute_height - 1 - y if height > 0 else y
            offset = pixel_offset + source_y * row_stride + x * bytes_per_pixel
            blue, green, red = data[offset : offset + 3]
            samples.append((red + green + blue) / 3)

    return sum(samples) / len(samples)


def main() -> int:
    if len(sys.argv) != 4:
        print("Usage: verify-claim.py <bitmap> <button-center-x> <button-center-y>", file=sys.stderr)
        return 64

    try:
        brightness = average_button_brightness(Path(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3]))
    except (OSError, ValueError, struct.error) as error:
        print(f"ERROR: unable to verify completed state: {error}", file=sys.stderr)
        return 65

    # WorkBuddy renders "立即领取" as a near-black button and "今日已领" as a
    # light-gray disabled button. The measured center is well separated.
    print(f"Claim button brightness: {brightness:.1f}")
    if brightness >= 150:
        print("VERIFIED: WorkBuddy claim button is in the completed (今日已领) state.")
        return 0

    print("ERROR: WorkBuddy claim button is still in the unclaimed state.", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
