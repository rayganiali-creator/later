#!/usr/bin/env python3
"""Generates all launcher/store icon assets from the single 'rewind clock'
concept in concepts.py. Requires: pip install playwright (Chromium)."""
import glob, os, sys
from concepts import concept_a, svg
from playwright.sync_api import sync_playwright

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
RES = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
STORE = os.path.join(ROOT, 'store', 'assets')
os.makedirs(STORE, exist_ok=True)

VARIANTS = {
    'classic': ('#6C5CE7', '#4B3FC0'),
    'teal': ('#19B5AD', '#0B7A78'),
    'rose': ('#F0679B', '#C22F66'),
    'dark': ('#3A3658', '#191727'),
}
c = concept_a()

def vec_paths(fg='#FFFFFF'):
    out = []
    for kind, d, w in c['parts']:
        if kind == 'stroke':
            out.append(f'    <path\n        android:pathData="{d}"\n        android:strokeColor="{fg}"\n        android:strokeWidth="{w}"\n        android:strokeLineCap="round"\n        android:strokeLineJoin="round" />')
        else:
            out.append(f'    <path\n        android:pathData="{d}"\n        android:fillColor="{fg}"\n        android:strokeColor="{fg}"\n        android:strokeWidth="2"\n        android:strokeLineJoin="round" />')
    return '\n'.join(out)

def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'w', encoding='utf-8').write(text)

# --- adaptive icon pieces --------------------------------------------------
write(f'{RES}/drawable/ic_launcher_foreground.xml', f'''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
{vec_paths()}
</vector>
''')
for name, (c1, c2) in VARIANTS.items():
    suffix = '' if name == 'classic' else f'_{name}'
    write(f'{RES}/drawable/ic_launcher_background{suffix}.xml', f'''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:aapt="http://schemas.android.com/aapt"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:pathData="M0,0h108v108h-108z">
        <aapt:attr name="android:fillColor">
            <gradient
                android:startX="0"
                android:startY="0"
                android:endX="108"
                android:endY="108"
                android:type="linear">
                <item android:color="{c1}" android:offset="0.0" />
                <item android:color="{c2}" android:offset="1.0" />
            </gradient>
        </aapt:attr>
    </path>
</vector>
''')
    write(f'{RES}/mipmap-anydpi-v26/ic_launcher{suffix}.xml', f'''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background{suffix}" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
''')

# --- notification small icon (24dp, white only) ------------------------------
write(f'{RES}/drawable/ic_notification.xml', f'''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="108"
    android:viewportHeight="108"
    android:tint="#FFFFFF">
{vec_paths()}
</vector>
''')

# --- splash (Android 12+ animated icon slot + legacy) --------------------------
write(f'{RES}/drawable/ic_splash.xml', f'''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
{vec_paths()}
</vector>
''')

# --- legacy PNG launcher icons (API 24-25) + store icon -----------------------
DENS = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
with sync_playwright() as p:
    exe = glob.glob('/opt/pw-browsers/chromium-*/chrome-linux/chrome')[0]
    b = p.chromium.launch(executable_path=exe, args=['--no-sandbox'])
    def render(html, path, w, h, transparent=True):
        pg = b.new_page(viewport={'width': w, 'height': h})
        pg.set_content(f'<body style="margin:0;background:transparent">{html}</body>')
        pg.screenshot(path=path, omit_background=transparent)
        pg.close()
    for name, bg in VARIANTS.items():
        suffix = '' if name == 'classic' else f'_{name}'
        for d, px in DENS.items():
            out = f'{RES}/mipmap-{d}/ic_launcher{suffix}.png'
            os.makedirs(os.path.dirname(out), exist_ok=True)
            render(svg(c, bg=bg, size=px), out, px, px)
    # Store icon 512 (no transparency needed but keep rounded corners off: stores mask themselves)
    full = svg(c, bg=VARIANTS['classic'], size=512).replace('rx="24"', 'rx="0"')
    render(full, f'{STORE}/icon_512.png', 512, 512, transparent=False)
    # Preview sheet used in the docs
    b.close()
print('icons generated')
