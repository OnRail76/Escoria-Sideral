"""Compare all TAP blocks and the startup against the released V1.0 tape.
Usage: python3 test_boot_compat101.py path/to/ESCORIA_SIDERAL_V1.0.tap
ROM BASIC and IRQ timing remain simulated, not Fuse.
"""
from pathlib import Path
import sys, hashlib
from loading import split
P=Path(__file__).resolve().parent
old=Path(sys.argv[1]).read_bytes();new=(P/'ESCORIA_SIDERAL_V1.0.1_DIRECTOR.tap').read_bytes()
assert hashlib.sha256(old).hexdigest()=='250c3210909e3479801fbec8212b2745d588a9035ae2c6b7c4d87c847a8990f2'
a,b=split(old),split(new)
assert len(a)==len(b)==28 and [i for i in range(28) if a[i]!=b[i]]==[7]
assert len(a[7])==len(b[7]);ranges=[(0x67b0,0x6bb6),(0x74c1,0x75a2),(0x6341,0x6343),(0x637f,0x6381)]
changed=[0x5f00+i for i,(x,y) in enumerate(zip(a[7][1:-1],b[7][1:-1])) if x!=y]
assert all(any(lo<=addr<hi for lo,hi in ranges) for addr in changed)
print('PASS: all BASIC, loading gate, screen, CODE headers, overlays and final blocks identical to V1.0; only',len(changed),'resident director / ROM guard bytes changed')
src=(P/'test_cpu.py').read_text();ns={'__file__':str(P/'test_cpu.py')};exec(compile(src[:src.index('assert i==len(tap)')],str(P/'test_cpu.py'),'exec'),ns)
CPU,S=ns['CPU'],ns['S'];c,d=CPU(),CPU()
for cpu,blocks in [(c,a),(d,b)]:
 cpu.m[:]=bytes(65536);cpu.m[0x5f00:0xe184]=blocks[7][1:-1];cpu.m[0xe184:0xefa5]=blocks[9][1:-1];cpu.m[0x4000:0x5b00]=blocks[5][1:-1];cpu.joy=255
# Compare the actual emitted instruction stream, registers and timing through the title and first game frame.
steps=0
def reach(label):
 global steps
 target=S[label]
 while c.pc!=target or d.pc!=target:
  assert (c.pc,c.sp,c.r,c.f,c.t,c.ie)==(d.pc,d.sp,d.r,d.f,d.t,d.ie),(hex(c.pc),hex(d.pc))
  assert c.m[c.pc:c.pc+4]==d.m[d.pc:d.pc+4]
  c.step();d.step();steps+=1;assert steps<2000000
 assert c.screen()==d.screen()
reach('title_press');c.keys=d.keys=16;reach('title_start_release');c.keys=d.keys=0;reach('loop')
assert c.v('phase')==d.v('phase')==1 and c.v('lives')==d.v('lives')==3
assert c.audio_events==d.audio_events
print('PASS: identical instruction trace, registers, timing, title, first-phase screen and audio through',steps,'steps (ROM/IRQ simulated)')
