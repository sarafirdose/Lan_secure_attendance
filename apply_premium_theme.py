import os

d = 'c:/flutter_projects/secure_attendance/lib'
changed = 0
files = [os.path.join(r, f) for r, dirs, f_ in os.walk(d) for f in f_ if f.endswith('.dart')]

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    old_c = content
    
    # ── 1. PRIMARY / APPBAR / BUTTONS → #2C2C2C (Charcoal) ──────────────────
    # Replacing common slate and the leftover "Dashboard Blue"
    content = content.replace('0xFF0F172A', '0xFF2C2C2C')
    content = content.replace('0xFF1E2A38', '0xFF2C2C2C')
    content = content.replace('0xFF1E293B', '0xFF2C2C2C')
    content = content.replace('0xFF111827', '0xFF2C2C2C')
    content = content.replace('0xFF2347D4', '0xFF2C2C2C')
    content = content.replace('0xFF1E293B', '0xFF2C2C2C')
    
    # ── 2. BACKGROUND → #F5F5F5 (Soft light gray) ───────────────────────────
    content = content.replace('0xFFF8FAFF', '0xFFF5F5F5')
    content = content.replace('0xFFF5F7FA', '0xFFF5F5F5')
    content = content.replace('0xFFF9FAFB', '0xFFF5F5F5')
    
    # ── 3. TEXT SECONDARY → #6B7280 ─────────────────────────────────────────
    content = content.replace('0xFF475569', '0xFF6B7280')
    content = content.replace('0xFF64748B', '0xFF6B7280')

    if content != old_c:
        with open(file, 'w', encoding='utf-8') as f:
            f.write(content)
        changed += 1

print(f'Changed {changed} files.')
