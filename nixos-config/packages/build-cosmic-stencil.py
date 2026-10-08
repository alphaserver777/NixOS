"""Цифры с диагональными прорезями на основе Orbitron, лицензия SIL OFL 1.1."""

from pathlib import Path
from copy import deepcopy
import sys

from fontTools import subset
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont
import pathops


def polygon(points):
    path = pathops.Path()
    pen = path.getPen()
    pen.moveTo(points[0])
    for point in points[1:]:
        pen.lineTo(point)
    pen.closePath()
    return path


def main():
    font = TTFont(sys.argv[1], recalcTimestamp=False)
    # Чистый овал нуля: исходная перечёркнутая форма мешает новой прорези.
    source_cmap = font.getBestCmap()
    font['glyf'][source_cmap[ord('0')]] = deepcopy(font['glyf'][source_cmap[ord('O')]])
    options = subset.Options()
    options.hinting = False
    subsetter = subset.Subsetter(options=options)
    subsetter.populate(text="0123456789: ")
    subsetter.subset(font)
    cmap = font.getBestCmap()
    glyphs = font.getGlyphSet()
    width = max(font['hmtx'][cmap[ord(char)]][0] for char in '0123456789')
    height = font['OS/2'].sCapHeight
    slope = height * .65 / width
    left, right = -100, width + 100
    low = height / 2 + slope * (left - width / 2)
    high = height / 2 + slope * (right - width / 2)
    gap = height * .028
    cut = polygon([(left, low - gap), (right, high - gap),
                   (right, high + gap), (left, low + gap)])
    paths = {}
    for char in '0123456789':
        name = cmap[ord(char)]
        advance, bearing = font['hmtx'][name]
        shift = round((width - advance) / 2)
        outline = pathops.Path()
        glyphs[name].draw(TransformPen(outline.getPen(), (1, 0, 0, 1, shift, 0)))
        paths[name] = pathops.op(outline, cut, pathops.PathOp.DIFFERENCE)
        font['hmtx'][name] = (width, bearing + shift)

    # Два ромба вместо обычного двоеточия.
    colon = cmap[ord(':')]
    center = font['hmtx'][colon][0] / 2
    radius = height * .065
    diamonds = [polygon([(center, y + radius), (center + radius, y),
                         (center, y - radius), (center - radius, y)])
                for y in (height * .29, height * .71)]
    paths[colon] = pathops.op(*diamonds, pathops.PathOp.UNION)
    font['hmtx'][colon] = (font['hmtx'][colon][0], round(center - radius))
    for name, path in paths.items():
        pen = TTGlyphPen(None)
        path.draw(Cu2QuPen(pen, max_err=1))
        font['glyf'][name] = pen.glyph()

    # Отдельное имя для производного шрифта; сведения об авторе и OFL сохранены.
    names = {1: 'Cosmic Stencil', 2: 'Bold', 3: '1.0;CS;CosmicStencil-Bold',
             4: 'Cosmic Stencil Bold', 5: 'Version 1.000', 6: 'CosmicStencil-Bold',
             16: 'Cosmic Stencil', 17: 'Bold'}
    font['name'].names = [record for record in font['name'].names
                         if record.nameID not in set(names) | {18, 21, 22}]
    for name_id, value in names.items():
        font['name'].setName(value, name_id, 3, 1, 0x409)
    font['head'].fontRevision = 1.0
    output = Path(sys.argv[2])
    output.parent.mkdir(parents=True, exist_ok=True)
    font.save(output)


if __name__ == '__main__':
    main()
