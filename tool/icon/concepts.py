import math, json, sys

def pt(cx, cy, r, deg):
    a = math.radians(deg)
    return cx + r*math.cos(a), cy + r*math.sin(a)

def arrow_ring(cx=54, cy=54, r=23, w=6.5, gap_center=200, gap=50):
    # ring open around gap_center (deg, screen coords, clockwise from +x). arrowhead at the start (counter-clockwise end)
    s = gap_center + gap/2      # start of drawn arc (clockwise direction)
    e = gap_center - gap/2 + 360
    x1, y1 = pt(cx, cy, r, s); x2, y2 = pt(cx, cy, r, e)
    large = 1 if (e - s) > 180 else 0
    arc = f'M{x1:.2f},{y1:.2f} A{r},{r} 0 {large} 1 {x2:.2f},{y2:.2f}'
    # arrow head at end point (x2,y2), tangent direction clockwise -> arrow points along clockwise tangent
    # Put the head at the END of the arc pointing clockwise (the classic "redo" ring)
    t = math.radians(e + 90)  # tangent direction (clockwise)
    tip = (x2 + 7.5*math.cos(t), y2 + 7.5*math.sin(t))
    n = math.radians(e)
    b1 = (x2 + 9*math.cos(n), y2 + 9*math.sin(n))
    b2 = (x2 - 9*math.cos(n), y2 - 9*math.sin(n))
    head = f'M{b1[0]:.2f},{b1[1]:.2f} L{tip[0]:.2f},{tip[1]:.2f} L{b2[0]:.2f},{b2[1]:.2f} Z'
    return arc, head

def concept_a():
    # Rewind ring (history style) + clock hands
    arc, head = arrow_ring(gap_center=245, gap=46)
    hands = 'M54,42 L54,55 L62,60'
    return dict(
        name='A_rewind_clock',
        parts=[
            ('stroke', arc, 6.5),
            ('fill', head, 0),
            ('stroke', hands, 5.5),
        ])

def concept_b():
    # Bookmark ribbon with a clock inside
    ribbon = 'M38,30 Q38,26 42,26 L66,26 Q70,26 70,30 L70,80 L54,68 L38,80 Z'
    return dict(name='B_bookmark_clock', parts=[('fill', ribbon, 0)], cut=[('clock', 54, 47, 9.5)])

def concept_c():
    # Hourglass
    top = 'M40,28 L68,28 L68,33 Q68,44 54,54 Q40,44 40,33 Z'
    bot = 'M40,80 L68,80 L68,75 Q68,64 54,54 Q40,64 40,75 Z'
    return dict(name='C_hourglass', parts=[('fill', top, 0), ('fill', bot, 0), ('stroke', 'M36,28 L72,28', 5), ('stroke', 'M36,80 L72,80', 5)])

def svg(concept, bg=('#6C5CE7', '#4B3FC0'), fg='#FFFFFF', shape='square', size=216):
    parts = []
    for kind, d, w in concept['parts']:
        if kind == 'stroke':
            parts.append(f'<path d="{d}" fill="none" stroke="{fg}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>')
        else:
            parts.append(f'<path d="{d}" fill="{fg}" stroke="{fg}" stroke-width="2" stroke-linejoin="round"/>')
    for c in concept.get('cut', []):
        _, cx, cy, r = c
        parts.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{bg[1]}" stroke-width="4"/>')
        parts.append(f'<path d="M{cx},{cy-5} L{cx},{cy+0.5} L{cx+4},{cy+3}" fill="none" stroke="{bg[1]}" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"/>')
    clip = '<clipPath id="m"><circle cx="54" cy="54" r="54"/></clipPath>' if shape == 'circle' else '<clipPath id="m"><rect width="108" height="108" rx="24"/></clipPath>'
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108" width="{size}" height="{size}">
<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{bg[0]}"/><stop offset="1" stop-color="{bg[1]}"/></linearGradient>{clip}</defs>
<g clip-path="url(#m)"><rect width="108" height="108" fill="url(#g)"/>{''.join(parts)}</g></svg>'''

if __name__ == '__main__':
    cs = [concept_a(), concept_b(), concept_c()]
    html = '<body style="margin:0;background:#eee;display:flex;gap:16px;padding:16px;font-family:sans-serif">'
    for c in cs:
        html += '<div>' + f'<div>{c["name"]}</div>' + svg(c, size=216) + svg(c, shape='circle', size=216) + svg(c, size=48) + svg(c, shape='circle', size=32) + '</div>'
    html += '</body>'
    open('concepts.html', 'w').write(html)
