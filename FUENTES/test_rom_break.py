"""Exercise real emitted transition code; ROM byte transfer remains a mock.
The ROM mock explicitly rejects SPACE (BREAK). No auto-release in these tests.
"""
from pathlib import Path
from loading import split
P=Path(__file__).resolve().parent
src=(P/'test_cpu.py').read_text();ns={'__file__':str(P/'test_cpu.py')};exec(compile(src[:src.index('assert i==len(tap)')],str(P/'test_cpu.py'),'exec'),ns)
CPU,S=ns['CPU'],ns['S'];ns['blocks']=split((P/'ESCORIA_SIDERAL_V1.0.1_DIRECTOR.tap').read_bytes())
def wait(c):
 c.run_to('rom_wait_space');pos=c.tape_pos;sp=c.sp
 for _ in range(6000):
  c.step();assert c.tape_pos==pos and c.sp==sp and S['rom_wait_space']<=c.pc<S['rom_wait_space']+7
 assert c.keys&16
 c.keys&=~16

def boot():
 c=CPU();c.tape_pos=10;return ns['start_from_title'](c)
# Actual win -> press_end -> phase load, hold SPACE across the transition.
c=boot()
for phase in range(2,6):
 c.set('lives',2);c.set('score0',7);c.set('bonus_left',77);c.pc=S['win'];c.keys=0;c.run_to('press_end');c.keys=16;wait(c);c.run_to('loop')
 assert c.v('phase')==phase and c.tape_pos==10+4*(phase-1) and c.v('lives')==2 and c.v('score0')==7 and c.v('bonus_left')==77 and c.sp==65534
 print('PASS: phase',phase,'held SPACE blocked, release loads bank + SCR, lives/score/stack intact',flush=True)
# Final is automatic: player might still be holding fire at the last boss's death.
c.pc=S['win'];c.keys=16;wait(c);c.run_to('wait_final');assert c.tape_pos==28 and c.screen()==(P/'final.scr').read_bytes();print('PASS: final SCR with SPACE held',flush=True)
# Test every individual entry to ROM, including payload guard.
c=boot();c.pc=S['next_phase'];c.run_to('rom_load_safe');saved=(c.r[:],c.f,c.sp,c.ix,c.pair(1));c.keys=16;wait(c)
while c.pc!=0x0556:c.step()
assert (c.r[:],c.f,c.sp,c.ix,c.pair(1))==saved
c.step();c.run_to('load_payload');c.keys=16;wait(c);c.run_to('loop');assert c.tape_pos==14 and c.v('phase')==2
print('PASS: header call register/flag/stack preservation and payload release guard',flush=True)
# Kempston FIRE alone must not block tape: ROM BREAK is keyboard SPACE.
c=CPU();c.tape_pos=10;ns['start_from_title'](c,True);c.pc=S['win'];c.run_to('press_end');c.joy=16;c.run_to('loop');assert c.v('phase')==2 and c.tape_pos==14
print('PASS: Kempston FIRE transition',flush=True)
