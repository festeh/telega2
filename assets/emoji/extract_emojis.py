#!/usr/bin/env python3
"""
Extract individual emoji PNGs from Telegram Desktop sprite sheets.
Uses hybrid approach: auto-mapping for early positions, manual fixes for offset regions.
"""

import re
from pathlib import Path
from PIL import Image

EMOJI_SIZE = 72
EMOJIS_PER_ROW = 32
EMOJIS_PER_SHEET = 512

TDESKTOP_PATH = Path.home() / "github" / "tdesktop"
EMOJI_TXT = TDESKTOP_PATH / "Telegram" / "lib_ui" / "emoji.txt"
SPRITE_DIR = TDESKTOP_PATH / "Telegram" / "Resources" / "emoji"
OUTPUT_DIR = Path(__file__).parent


def emoji_to_codepoint(emoji: str) -> str:
    """Convert emoji to codepoint string."""
    codepoints = []
    for char in emoji:
        cp = ord(char)
        codepoints.append(f"{cp:X}")
    return "-".join(codepoints) if codepoints else ""


def parse_emoji_txt(filepath: Path) -> list[str]:
    """Parse emoji.txt section 0."""
    content = filepath.read_text(encoding='utf-8')
    sections = re.split(r'[-=]{8,}', content)
    emojis = [m.group(1) for m in re.finditer(r'"([^"]+)"', sections[0])]
    return emojis


def extract_sprite(sprites: list, pos: int) -> Image.Image | None:
    """Extract single emoji from sprite sheets."""
    sheet = pos // EMOJIS_PER_SHEET
    if sheet >= len(sprites):
        return None
    pos_in_sheet = pos % EMOJIS_PER_SHEET
    row = pos_in_sheet // EMOJIS_PER_ROW
    col = pos_in_sheet % EMOJIS_PER_ROW

    # Check bounds
    sheet_rows = sprites[sheet].size[1] // EMOJI_SIZE
    if row >= sheet_rows:
        return None

    x, y = col * EMOJI_SIZE, row * EMOJI_SIZE
    return sprites[sheet].crop((x, y, x + EMOJI_SIZE, y + EMOJI_SIZE))


# Manual overrides for emojis with known offset issues
# Format: codepoint -> sprite_position
MANUAL_SPRITE_POSITIONS = {
    # Hearts (offset region)
    '2764-FE0F': 3142,  # ❤️ red heart
    '2764': 3142,       # ❤ red heart (without FE0F)
    '1FA77': 3141,      # 🩷 pink heart
    '1F9E1': 3143,      # 🧡 orange heart
    '1F49B': 3144,      # 💛 yellow heart
    '1F49A': 3145,      # 💚 green heart
    '1FA75': 3146,      # 🩵 light blue heart
    '1F499': 3147,      # 💙 blue heart
    '1F49C': 3148,      # 💜 purple heart
    '1F90E': 3149,      # 🤎 brown heart
    '1F5A4': 3150,      # 🖤 black heart
    '1FA76': 3151,      # 🩶 grey heart
    '1F90D': 3152,      # 🤍 white heart
}


def main():
    if not EMOJI_TXT.exists():
        print(f"Error: emoji.txt not found at {EMOJI_TXT}")
        return 1

    emojis = parse_emoji_txt(EMOJI_TXT)
    print(f"Parsed {len(emojis)} emojis from emoji.txt")

    # Load sprites
    sprites = []
    for i in range(1, 9):
        sprite_path = SPRITE_DIR / f"emoji_{i}.webp"
        if sprite_path.exists():
            sprites.append(Image.open(sprite_path))
            print(f"Loaded {sprite_path}")

    if not sprites:
        print("Error: No sprite sheets found")
        return 1

    # Calculate total sprites
    total_sprites = sum(
        EMOJIS_PER_ROW * (s.size[1] // EMOJI_SIZE) for s in sprites
    )
    print(f"Total sprites available: {total_sprites}")

    # Clear old PNGs
    for old_png in OUTPUT_DIR.glob("*.png"):
        old_png.unlink()

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    extracted = 0
    seen_codepoints = set()

    # First pass: extract using emoji.txt order for positions 0-2723 (no offset)
    for idx, emoji in enumerate(emojis):
        if idx >= 2724:  # Stop before offset region
            break
        if idx >= total_sprites:
            break

        codepoint = emoji_to_codepoint(emoji)
        if not codepoint or codepoint in seen_codepoints:
            continue
        seen_codepoints.add(codepoint)

        img = extract_sprite(sprites, idx)
        if img:
            img.save(OUTPUT_DIR / f"{codepoint}.png")
            extracted += 1

    print(f"Extracted {extracted} emojis from auto-mapping (positions 0-2723)")

    # Second pass: manual overrides for offset region
    manual_extracted = 0
    for codepoint, sprite_pos in MANUAL_SPRITE_POSITIONS.items():
        if codepoint in seen_codepoints:
            continue
        seen_codepoints.add(codepoint)

        img = extract_sprite(sprites, sprite_pos)
        if img:
            img.save(OUTPUT_DIR / f"{codepoint}.png")
            manual_extracted += 1

    print(f"Extracted {manual_extracted} emojis from manual mapping")

    # Third pass: extract remaining emojis with offset 2 (positions 2724+)
    # Offset: emoji.txt position - 2 = sprite position
    offset_extracted = 0
    for idx in range(2724, min(len(emojis), total_sprites + 2)):
        emoji = emojis[idx]
        codepoint = emoji_to_codepoint(emoji)
        if not codepoint or codepoint in seen_codepoints:
            continue

        sprite_pos = idx - 2  # Apply offset
        if sprite_pos < 0 or sprite_pos >= total_sprites:
            continue

        seen_codepoints.add(codepoint)
        img = extract_sprite(sprites, sprite_pos)
        if img:
            img.save(OUTPUT_DIR / f"{codepoint}.png")
            offset_extracted += 1

    print(f"Extracted {offset_extracted} emojis with offset correction")
    print(f"\nTotal: {extracted + manual_extracted + offset_extracted} emojis")

    return 0


if __name__ == "__main__":
    exit(main())
