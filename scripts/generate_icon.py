"""SHADOW RUN 앱 아이콘 생성 스크립트 (1024x1024)"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

SIZE = 1024
BG = (10, 10, 10)        # #0A0A0A
RED = (255, 82, 98)      # #FF5262
DARK_RED = (146, 2, 35)  # #920223

img = Image.new('RGBA', (SIZE, SIZE), (*BG, 255))
draw = ImageDraw.Draw(img)

# Subtle radial glow behind text
glow = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
glow_draw = ImageDraw.Draw(glow)
for r in range(300, 0, -2):
    alpha = int(40 * (1 - r / 300))
    glow_draw.ellipse(
        [SIZE // 2 - r, SIZE // 2 - r, SIZE // 2 + r, SIZE // 2 + r],
        fill=(*RED, alpha),
    )
img = Image.alpha_composite(img, glow)
draw = ImageDraw.Draw(img)

# Try to use a bold system font, fallback to default
font_big = None
font_small = None
font_paths = [
    "C:/Windows/Fonts/arialbd.ttf",
    "C:/Windows/Fonts/arial.ttf",
    "C:/Windows/Fonts/segoeui.ttf",
]
for fp in font_paths:
    if os.path.exists(fp):
        font_big = ImageFont.truetype(fp, 320)
        font_small = ImageFont.truetype(fp, 80)
        break

if font_big is None:
    font_big = ImageFont.load_default()
    font_small = ImageFont.load_default()

# Draw "SR" text with shadow
shadow_offset = 6
# Shadow layer
draw.text(
    (SIZE // 2 + shadow_offset, SIZE // 2 - 80 + shadow_offset),
    "SR",
    fill=(*DARK_RED, 180),
    font=font_big,
    anchor="mm",
)
# Main text
draw.text(
    (SIZE // 2, SIZE // 2 - 80),
    "SR",
    fill=RED,
    font=font_big,
    anchor="mm",
)

# Subtitle "SHADOW RUN"
draw.text(
    (SIZE // 2, SIZE // 2 + 160),
    "SHADOW RUN",
    fill=(*RED, 180),
    font=font_small,
    anchor="mm",
)

# Bottom accent line
line_y = SIZE // 2 + 220
draw.line(
    [(SIZE // 2 - 200, line_y), (SIZE // 2 + 200, line_y)],
    fill=(*RED, 100),
    width=3,
)

# Rounded corners mask
mask = Image.new('L', (SIZE, SIZE), 0)
mask_draw = ImageDraw.Draw(mask)
radius = 180
mask_draw.rounded_rectangle([0, 0, SIZE, SIZE], radius=radius, fill=255)

# Apply mask for rounded corners
output = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
output.paste(img, mask=mask)

# Save as PNG
out_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "icon", "app_icon.png")
output.save(out_path, "PNG")
print(f"App icon saved to: {out_path}")
