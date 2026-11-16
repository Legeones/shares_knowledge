"""Ajoute un diamant au style du lingot dans la police d'icônes.

Le diamant est dessiné comme le lingot : des traits de 30 unités (sur 1 024)
aux bouts arrondis, avec une petite coupure sur l'arête du haut. Il est
rangé au code 0xE901 (le lingot est en 0xE900).

Usage (depuis la racine du projet) :
    pip install fonttools shapely
    python tool/add_diamond_glyph.py
"""
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont
from shapely.geometry import LineString, MultiPolygon
from shapely.geometry.polygon import orient
from shapely.ops import unary_union

FONT = 'assets/fonts/SharesKnowledgeIcons.ttf'
NAME, CODE = 'diamond', 0xE901
HALF_STROKE = 15  # trait de 30 unités, comme le lingot

# Repères (unités de police, y vers le haut), centrés comme le lingot.
cx = 505
top, girdle, tip = 640, 470, 70  # table, ceinture, pointe
table, width = 170, 380  # demi-largeurs de la table et de la ceinture
facet = 125  # écart des facettes depuis le centre, sur la ceinture

lines = [
    # Arête du haut, avec une petite coupure à gauche (comme le lingot).
    [(cx - table, top), (cx - table + 45, top)],
    [(cx - table + 90, top), (cx + table, top)],
    # Contour : épaules, puis pointe.
    [(cx + table, top), (cx + width, girdle), (cx, tip),
     (cx - width, girdle), (cx - table, top)],
    # Ceinture.
    [(cx - width, girdle), (cx + width, girdle)],
    # Facettes de la couronne puis du pavillon.
    [(cx - table, top), (cx - facet, girdle), (cx, tip)],
    [(cx + table, top), (cx + facet, girdle), (cx, tip)],
]

shape = unary_union([
    LineString(points).buffer(HALF_STROKE, cap_style='round',
                              join_style='round', quad_segs=6)
    for points in lines
])
polygons = shape.geoms if isinstance(shape, MultiPolygon) else [shape]

# TrueType : contour extérieur dans le sens horaire, trous dans l'autre sens.
pen = TTGlyphPen(None)
for polygon in polygons:
    polygon = orient(polygon, sign=-1.0)
    for ring in [polygon.exterior, *polygon.interiors]:
        points = [(round(x), round(y)) for x, y in ring.coords[:-1]]
        pen.moveTo(points[0])
        for p in points[1:]:
            pen.lineTo(p)
        pen.closePath()
glyph = pen.glyph()

font = TTFont(FONT)
order = font.getGlyphOrder()
if NAME not in order:
    font.setGlyphOrder(order + [NAME])
font['glyf'][NAME] = glyph
glyph.recalcBounds(font['glyf'])
font['hmtx'][NAME] = (1024, glyph.xMin)
for table in font['cmap'].tables:
    if table.isUnicode():
        table.cmap[CODE] = NAME
font.save(FONT)
print('Ajouté :', NAME, hex(CODE), 'bbox', glyph.xMin, glyph.yMin,
      glyph.xMax, glyph.yMax)
