"""Reconstruye la cinta Gold Master V1.0 con el generador original aprobado."""
from pathlib import Path
import subprocess, sys, hashlib
root = Path(__file__).resolve().parent
subprocess.run([sys.executable, str(root / 'build.py')], cwd=root, check=True)
raw = (root / 'ESCORIA_SIDERAL_ALFA_21_2.tap').read_bytes()
expected = '250c3210909e3479801fbec8212b2745d588a9035ae2c6b7c4d87c847a8990f2'
actual = hashlib.sha256(raw).hexdigest()
if actual != expected:
    raise SystemExit(f'ERROR: SHA-256 no coincide: {actual}')
out = root.parent / 'JUEGO' / 'ESCORIA_SIDERAL_V1.0.tap'
out.parent.mkdir(exist_ok=True)
out.write_bytes(raw)
print(f'Gold Master verificado: {out} | {len(raw)} bytes | SHA-256 {actual}')
