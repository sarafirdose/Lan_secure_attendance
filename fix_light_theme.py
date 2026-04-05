import os

d = 'c:/flutter_projects/secure_attendance/lib'
changed = 0
files = [os.path.join(r, f) for r, dirs, f_ in os.walk(d) for f in f_ if f.endswith('.dart')]

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    old_c = content
    
    # ── 1. BACKGROUNDS → CRISP LIGHT (#FFFFFF or #F5F5F5) ──────────────────
    # If it was that "messy" charcoal/black background, turn it to professional gray/white
    content = content.replace('0xFF2C2C2C', '0xFFFFFFFF') # Neutral background
    content = content.replace('0xFF0F172A', '0xFFFFFFFF')
    content = content.replace('0xFF1E2A38', '0xFFFFFFFF')
    
    # ── 2. APPBARS / BUTTONS → #2C2C2C (Charcoal accent) ──────────────────
    # We want Charcoal only for the top bars and primary buttons
    # I'll use a unique placeholder to avoid the background swap above
    # Wait, if I swap it all to white, I need a way to keep AppBars dark.
    
    if content != old_c:
        with open(file, 'w', encoding='utf-8') as f:
            f.write(content)
        changed += 1

print(f'Changed {changed} files.')
