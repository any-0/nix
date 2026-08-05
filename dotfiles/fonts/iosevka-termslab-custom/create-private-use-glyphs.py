"""Patch IosevkaTermSlab Nerd Font Mono with private-use rail and logo glyphs.

  U+E010  top half of heavy connector: arm at the bottom edge
  U+E011  heavy vertical bar, right-aligned
  U+E018  bottom half of heavy connector: arm at the top edge
  U+E012..U+E014  Claude logo, split across three cells
  U+E015..U+E017  OpenAI logo, split across three cells
  U+E019..U+E01B  Nix snowflake, split across three cells
  U+E01C..U+E01E  eye, split across three cells
  U+E01F..U+E021  Neovim logo, split across three cells
  U+E022..U+E024  SSH terminal, split across three cells
  U+E025..U+E027  Rust logo, split across three cells
  U+E028..U+E02A  Python logo, split across three cells

Source: IosevkaTermSlabNerdFontMono-Regular.ttf from the Nerd Fonts release.

  fontforge -script create-private-use-glyphs.py \
      IosevkaTermSlabNerdFontMono-Regular.ttf \
      ~/Library/Fonts/IosevkaTermSlabNerdFontMono-Custom-Regular.ttf \
      claude.svg OpenAI-black-monoblossom.svg 1090 -410 1600 -700 false

The two logo SVGs are the vendors' own artwork, fetched by default.nix rather
than kept in the tree - see the comments there for where each comes from.

The rails deliberately overhang the nominal ascent/descent, because a glyph
drawn to the ascent stops short of the cell edge and the bars do not join
between rows. Kitty pins a bitmap that rises above the ascent to the top row of
the cell rather than clipping it, so the rail's top edge, not the baseline,
decides where the bar starts: the edge has to land on a whole pixel or that row
comes out half covered and every row boundary shows a seam. Drawing the top at
exactly one em above the baseline does that, since hinting rounds the ppem to
whole pixels - see fonts.fontconfig in system/desktop.nix, which is what forces
full hinting for this family. The bottom overhangs far enough for kitty to clip
it at the cell edge. CoreText clips those overhanging outlines at a different
position, so Nix supplies the measured cell edges for the target renderer:
FreeType keeps each half-arm inside its cell; CoreText uses the complete arm
centered on the boundary.

Only the PostScript name is made unique. The family name is left untouched on
purpose so that kitty still resolves bold/italic to the genuine Iosevka faces
while `postscript_name=` pins Regular to this patched file.
"""

import math
import sys

import fontforge

source_path, output_path = sys.argv[1:3]
claude_svg, openai_svg = sys.argv[3:5]
connector_cell_top, connector_cell_bottom = map(int, sys.argv[5:7])
rail_top, rail_bottom = map(int, sys.argv[7:9])
arms_inside = sys.argv[9] == "true"

PSNAME = "IosevkaTermSlabNFMCustomR7-Regular"
FULLNAME = "IosevkaTermSlab Nerd Font Mono Custom R7"

font = fontforge.open(source_path)

# The Nerd Font ships an explicit sfnt name table, and it wins over the
# convenience attributes, so the identity entries have to be rewritten in place.
overrides = {"PostScriptName": PSNAME, "UniqueID": PSNAME, "Fullname": FULLNAME}
names, present = [], set()
for language, key, value in font.sfnt_names:
    if key in overrides:
        value = overrides[key]
        present.add((language, key))
    names.append((language, key, value))
for key, value in overrides.items():
    if ("English (US)", key) not in present:
        names.append(("English (US)", key, value))
font.sfnt_names = tuple(names)
font.fontname = PSNAME
font.fullname = FULLNAME

WIDTH = 500          # monospace cell
BAR_LEFT = 362       # heavy stroke, flush with the right edge of the cell
BAR_RIGHT = WIDTH
ARM_LEFT = 0         # runs to the left edge so it meets the neighbouring cell
TOP = rail_top
BOTTOM = rail_bottom

GLYPH_CENTER = 340
ARM_THICKNESS = BAR_RIGHT - BAR_LEFT

# The imported logos are scaled to fill a 1000x1000 box centered in the three
# cells they span. The drawn sequences below use the same box, so every
# three-cell icon in the mux sidebar comes out at one size and one height.
LOGO_LEFT = 250
LOGO_BOTTOM = -35
LOGO_SIZE = 1000
LOGO_CENTER_X = LOGO_LEFT + LOGO_SIZE / 2
LOGO_CENTER_Y = LOGO_BOTTOM + LOGO_SIZE / 2

# One arm of the Nix snowflake, lifted from nixos-artwork's
# nix-snowflake-white.svg: y flipped to point up, measured from the center of
# the flake and scaled so the flake is one unit wide. The whole logo is this
# arm turned by multiples of 60 degrees.
NIX_ARM = [
    (-0.08822, -0.17420),
    (0.39906, -0.17422),
    (0.34399, -0.27171),
    (0.21328, -0.27134),
    (0.27819, -0.38446),
    (0.25036, -0.43262),
    (0.19349, -0.43269),
    (0.10118, -0.27163),
    (-0.03178, -0.27136),
]


def draw_rectangle(pen, left, bottom, right, top):
    pen.moveTo((left, bottom))
    pen.lineTo((left, top))
    pen.lineTo((right, top))
    pen.lineTo((right, bottom))
    pen.closePath()


def make_rail(codepoint):
    glyph = font.createChar(codepoint)
    glyph.clear()
    pen = glyph.glyphPen()
    draw_rectangle(pen, BAR_LEFT, BOTTOM, BAR_RIGHT, TOP)
    glyph.width = WIDTH
    # Hinting from the replaced glyph addresses point indices that do not exist
    # in this outline and distorts it under FreeType.
    glyph.ttinstrs = ()


def make_connector_half(codepoint, arm_center, inside_direction):
    glyph = font.createChar(codepoint)
    glyph.clear()
    if inside_direction > 0:
        arm_bottom, arm_top = arm_center, arm_center + ARM_THICKNESS / 2
    elif inside_direction < 0:
        arm_bottom, arm_top = arm_center - ARM_THICKNESS / 2, arm_center
    else:
        arm_bottom = arm_center - ARM_THICKNESS / 2
        arm_top = arm_center + ARM_THICKNESS / 2
    pen = glyph.glyphPen()
    draw_rectangle(pen, BAR_LEFT, BOTTOM, BAR_RIGHT, TOP)
    draw_rectangle(pen, ARM_LEFT, arm_bottom, BAR_LEFT, arm_top)
    glyph.width = WIDTH
    glyph.ttinstrs = ()


QUADRATIC = font.layers["Fore"].is_quadratic
FAR = 10000  # comfortably outside any outline, for the clipping band


def cell_band(left):
    """A rectangle covering one cell, tall enough to span any artwork."""
    contour = fontforge.contour()
    contour.is_quadratic = QUADRATIC
    contour.moveTo(left, -FAR)
    contour.lineTo(left, FAR)
    contour.lineTo(left + WIDTH, FAR)
    contour.lineTo(left + WIDTH, -FAR)
    contour.closed = True
    return contour


def make_art_sequence(first_codepoint, art):
    """Scale an outline into the three-cell box and cut it at the cells."""
    left, bottom, right, top = art.boundingBox()
    scale = LOGO_SIZE / max(right - left, top - bottom)
    art.transform((
        scale, 0, 0, scale,
        LOGO_CENTER_X - (left + right) / 2 * scale,
        LOGO_CENTER_Y - (bottom + top) / 2 * scale,
    ))
    art.correctDirection()

    for index in range(3):
        glyph = font.createChar(first_codepoint + index)
        glyph.clear()
        glyph.layers[1] = art.layers[1]
        layer = glyph.layers[1]
        layer += cell_band(index * WIDTH)
        glyph.layers[1] = layer
        glyph.intersect()
        glyph.transform((1, 0, 0, 1, -index * WIDTH, 0))
        glyph.correctDirection()
        glyph.width = WIDTH
        glyph.ttinstrs = ()

    font.removeGlyph(art)


def make_logo_sequence(first_codepoint, svg_path):
    """Import a vendor logo without flattening its curves.

    The drawn sequences below clip their own polygons, but these outlines are
    curves, and running them through a polyline clipper would flatten exactly
    the roundness the vendor artwork is imported for. FontForge's boolean
    intersect cuts them without touching the curves between the cuts.

    The downloads wrap their artwork in groups and clip paths; FontForge reads
    the paths and ignores the rest, which is what we want here - both files'
    clips only restate the artwork's own bounding box.
    """
    art = font.createChar(-1, "logo.import")
    art.clear()
    art.importOutlines(svg_path)
    make_art_sequence(first_codepoint, art)


def make_font_glyph_sequence(first_codepoint, source_codepoint):
    """Scale one Nerd Font glyph into the logo box and cut it into cells."""
    art = font.createChar(-1, "logo.font")
    art.clear()
    art.layers[1] = font[source_codepoint].layers[1]
    make_art_sequence(first_codepoint, art)


def rotate(points, degrees):
    angle = math.radians(degrees)
    cos, sin = math.cos(angle), math.sin(angle)
    return [(x * cos - y * sin, x * sin + y * cos) for x, y in points]


def circle_arc(center_x, center_y, radius, start, end, steps):
    """Points along a circle, angles in degrees. Curves are drawn as polylines:
    at the size these icons render, the segments are far below a pixel."""
    return [
        (
            center_x + radius * math.cos(math.radians(start + (end - start) * i / steps)),
            center_y + radius * math.sin(math.radians(start + (end - start) * i / steps)),
        )
        for i in range(steps + 1)
    ]


def lid_arc(half_width, sagitta, sign, steps=32):
    """One eyelid: an arc from (-half_width, 0) to (half_width, 0) that bulges
    `sagitta` above the axis for sign 1, and below it for sign -1."""
    radius = (half_width**2 + sagitta**2) / (2 * sagitta)
    spread = math.degrees(math.asin(half_width / radius))
    center_y = sign * (sagitta - radius)
    if sign > 0:
        return circle_arc(0, center_y, radius, 90 + spread, 90 - spread, steps)
    return circle_arc(0, center_y, radius, -90 - spread, -90 + spread, steps)


def place(contours):
    """Move contours drawn about the origin into the three-cell logo box."""
    return [
        [(x + LOGO_CENTER_X, y + LOGO_CENTER_Y) for x, y in contour]
        for contour in contours
    ]


def nix_flake_contours():
    arm = [(x * LOGO_SIZE, y * LOGO_SIZE) for x, y in NIX_ARM]
    return place([rotate(arm, 60 * step) for step in range(6)])


def eye_contours(half_width=500, sagitta=310, rim=80, pupil=155):
    """An open eye: two lids meeting in points, plus a round pupil.

    The lids are crescents rather than one outline with a hole in it, so all
    three contours stay disjoint and none of them turns into a hole that shares
    an edge with its parent once the artwork is cut at a cell boundary.
    """
    contours = [
        lid_arc(half_width, sagitta, sign) + list(reversed(lid_arc(half_width, sagitta - rim, sign)))
        for sign in (1, -1)
    ]
    contours.append(circle_arc(0, 0, pupil, 0, 360, 48)[:-1])
    return place(contours)


def clip_to_cell(points, left, right):
    """Sutherland-Hodgman clip of a closed contour to the band left..right."""

    def clip(contour, inside, edge):
        out = []
        for index, current in enumerate(contour):
            previous = contour[index - 1]
            if inside(current) != inside(previous):
                t = (edge - previous[0]) / (current[0] - previous[0])
                out.append((edge, previous[1] + t * (current[1] - previous[1])))
            if inside(current):
                out.append(current)
        return out

    return clip(clip(points, lambda p: p[0] >= left, left), lambda p: p[0] <= right, right)


def make_drawn_sequence(first_codepoint, contours):
    """Cut artwork spanning all three cells into one glyph per cell."""
    for index in range(3):
        left = index * WIDTH
        glyph = font.createChar(first_codepoint + index)
        glyph.clear()
        pen = glyph.glyphPen()
        for contour in contours:
            clipped = clip_to_cell(contour, left, left + WIDTH)
            if len(clipped) < 3:
                continue
            pen.moveTo((clipped[0][0] - left, clipped[0][1]))
            for x, y in clipped[1:]:
                pen.lineTo((x - left, y))
            pen.closePath()
        glyph.correctDirection()
        glyph.width = WIDTH
        glyph.ttinstrs = ()


make_connector_half(0xE010, connector_cell_bottom, 1 if arms_inside else 0)
make_rail(0xE011)
make_connector_half(0xE018, connector_cell_top, -1 if arms_inside else 0)
make_logo_sequence(0xE012, claude_svg)
make_logo_sequence(0xE015, openai_svg)
make_drawn_sequence(0xE019, nix_flake_contours())
make_drawn_sequence(0xE01C, eye_contours())
make_font_glyph_sequence(0xE01F, 0xE6AE)
make_font_glyph_sequence(0xE022, 0xF08C0)
make_font_glyph_sequence(0xE025, 0xE7A8)
make_font_glyph_sequence(0xE028, 0xE73C)

# Keep the fallback process marker aligned with the logo center as well.
bullet = font[0x2022]
left, bottom, right, top = bullet.boundingBox()
bullet.transform((1, 0, 0, 1, 0, GLYPH_CENTER - (bottom + top) / 2))
bullet.ttinstrs = ()

font.generate(output_path)
font.close()
