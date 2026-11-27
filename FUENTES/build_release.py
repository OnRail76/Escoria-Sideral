"""Rebuild the V1.0.1 approved director release and verify exact TAP."""
from pathlib import Path
import subprocess,sys,hashlib
root=Path(__file__).resolve().parent
subprocess.run([sys.executable,str(root/'build.py')],cwd=root,check=True)
raw=(root/'ESCORIA_SIDERAL_V1.0.1_DIRECTOR.tap').read_bytes()
assert hashlib.sha256(raw).hexdigest()=='df2d7b596060ee42a675de0b748e14e2aa2ce9d8be9a2308e7f538df1240766e'
(root.parent/'JUEGO').mkdir(exist_ok=True)
(root.parent/'JUEGO'/'ESCORIA_SIDERAL_V1.0.1.tap').write_bytes(raw)
print('Release TAP verified:',len(raw),'bytes')
