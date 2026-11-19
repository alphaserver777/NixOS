"""Типографский элемент Plymouth; строится один раз, вне загрузки системы."""

import sys
from PIL import Image, ImageDraw, ImageFont

font_path, output = sys.argv[1:]
# Двойное разрешение и явные интервалы сохраняют прорези Anurati.
font = ImageFont.truetype(font_path, 64)
text = "VADIM MOISEENKO"
spacing = 8
widths = [font.getlength(char) for char in text]
top = min(font.getbbox(char)[1] for char in text if char != " ")
bottom = max(font.getbbox(char)[3] for char in text if char != " ")
image = Image.new("RGBA", (round(sum(widths) + spacing * (len(text) - 1)) + 16,
                            bottom - top + 16))
draw = ImageDraw.Draw(image)
x = 8.0
for char, width in zip(text, widths):
    draw.text((round(x), 8 - top), char, font=font, fill=(205, 214, 244, 255))
    x += width + spacing
image.save(output)
