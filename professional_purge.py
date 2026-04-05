import os
import re

d = 'c:/flutter_projects/secure_attendance/lib'
changed_count = 0
files = [os.path.join(r, f) for r, dirs, f_ in os.walk(d) for f in f_ if f.endswith('.dart')]

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    old_c = content
    
    # ── 1. PURGE GAMING EFFECTS ───────────────────────────────────────────────
    # Remove gradients and replace them with solid charcoal or light gray
    content = re.sub(r'BoxDecoration\s*\(\s*gradient\s*:\s*LinearGradient\(.*?\)\s*,', 'BoxDecoration(color: Color(0xFF2C2C2C),', content, flags=re.DOTALL)
    # Remove BackdropFilter (Glassmorphism)
    content = re.sub(r'BackdropFilter\s*\(.*?filter\s*:\s*ImageFilter\.blur\(.*?\).*?child\s*:\s*(.*?)\s*,?\s*\)', r'\1', content, flags=re.DOTALL)
    
    # ── 2. NEW COLOR SYSTEM ───────────────────────────────────────────────────
    # Primary/Charcoal
    content = content.replace('0xFF4F46E5', '0xFF2C2C2C') # Indigo
    content = content.replace('0xFF2347D4', '0xFF2C2C2C') # Blue
    content = content.replace('0xFF1E293B', '0xFF2C2C2C') # Slate
    
    # Background/Soft Gray
    # Any screen with specific background light blue/purple, force to #F5F5F5
    content = content.replace('0xFFF8FAFF', '0xFFF5F5F5')
    content = content.replace('0xFFF1F5F9', '0xFFFFFFFF') # Cards/Inputs to White
    
    # Text Colors
    content = content.replace('0xFF111827', '0xFF111827') # No-op (Primary Text)
    content = content.replace('0xFF334155', '0xFF111827') # Text slate → Dark Gray
    content = content.replace('0xFF475569', '0xFF6B7280') # Text slate med → Muted Gray

    # Accent (Muted Green)
    content = content.replace('0xFF10B981', '0xFF059669') # Emerald
    content = content.replace('0xFF22C55E', '0xFF059669') # Bright Green
    
    # ── 3. SPECIFIC UI COMPONENTS ─────────────────────────────────────────────
    # Buttons: Ensure Charcoal bg and White text
    # This is partially handled by the 4F46E5/2C2C2C swap above

    if content != old_c:
        with open(file, 'w', encoding='utf-8') as f:
            f.write(content)
        changed_count += 1

print(f'Purged and Professionalized {changed_count} files.')
