"""Regression of actual emitted input code; no hardware/ULA emulation."""
from pathlib import Path
P=Path(__file__).resolve().parent
src=(P/'test_cpu.py').read_text();ns={'__file__':str(P/'test_cpu.py')}
exec(compile(src[:src.index('assert i==len(tap)')],str(P/'test_cpu.py'),'exec'),ns)
CPU,S=ns['CPU'],ns['S']
# Every port byte in every selected mode, independent of keyboard input.
for mode in (0,1,2):
 for raw in range(256):
  for keys in (0,1,2,4,8,16,17,24):
   c=CPU();c.joy=raw;c.keys=keys;c.set('joy',mode);c.sub('input');c.finish()
   valid=mode!=2 and raw<32 and (raw&3)!=3 and (raw&12)!=12
   assert c.v('keys')==keys|(raw if valid else 0),(mode,raw,keys,c.v('keys'))
   assert c.v('joy')==mode
print('PASS: 6144 mode/port/keyboard combinations, invalid full bytes rejected, keyboard mode ignores port')
class NoisyCPU(CPU):
 def __init__(self,seq):super().__init__();self.samples=iter(seq);self.polls=0
 def step(self):
  if self.m[self.pc:self.pc+2]==bytes([0xed,0x78]) and self.pair(0)==0x001f:
   self.polls+=1;self.joy=next(self.samples)
  super().step()
for mode in (0,1):
 for seq in ((8,0,0),(16,16,0),(24,8,24),(16,240,16),(1,2,1),(255,0,0),(248,248,248)):
  c=NoisyCPU(seq);c.set('joy',mode);c.keys=1;c.sub('input');c.finish();assert c.v('keys')==1,(mode,seq,c.v('keys'))
for seq in ((8,8,8),(16,16,16),(25,25,25)):
 c=NoisyCPU(seq);c.set('joy',1);c.sub('input');c.finish();assert c.v('keys')==seq[0] and c.polls==3
c=NoisyCPU([]);c.set('joy',2);c.keys=16;c.sub('input');c.finish();assert c.polls==0 and c.v('keys')==16
print('PASS: inconsistent samples ignored, valid stable Kempston accepted, zero port reads in keyboard mode')
c=ns['boot']();assert c.v('joy')==2
for raw in (8,16,24,1,2,255,248,0)*5:
 c.joy=raw;c.set('spawn_delay',255);c.set('hdelay',255);c.step_frame();assert c.v('jump')==255 and c.v('keys')==0 and c.v('scroll')==0 and all(c.v(f'b{i}on')==0 for i in range(3))
c.joy=24;c.step_frame(8);assert c.v('jump')!=255
print('PASS: idle Ace stays still with synthetic ghost jump/fire; intentional Q works')
c=ns['start_from_title'](CPU(),True);assert c.v('joy')==1
c.joy=1;c.step_frame();assert c.v('scroll')==2
c.joy=2;c.step_frame();assert c.v('px')==78
c.joy=8;c.step_frame();assert c.v('jump')!=255
c.joy=255;c.step_frame(1);assert c.v('px')==80
print('PASS: FIRE selects Kempston; right/left/jump and keyboard fallback')
c=CPU();c.run_to('title_press');c.keys=16;c.joy=16;c.run_to('title_start_release');c.keys=c.joy=0;c.run_to('loop');assert c.v('joy')==2
print('PASS: physical SPACE has priority at title')
# Title and hidden selector helpers from the original regression, without running unrelated expensive checks.
exec(src[src.index('def title_tick'):src.index('for use_joy in (False,True):')],ns)
exec(src[src.index('def select_boot'):src.index('for j in (False,True):')],ns)
for joy in (False,True):
 for phase in range(1,6): ns['select_boot'](phase,joy)
print('PASS: ten direct title cheat/selector launches, keyboard and Kempston, all five phases')
# Loader gate when port is disconnected or opposing directions are present.
from loading import stub,STUB_ADDR
code,labels,_=stub()
for raw in range(256):
 for keys in (0,16):
  c=CPU();c.m[STUB_ADDR:STUB_ADDR+len(code)]=code;c.pc=labels['fire'];c.push(0x100);c.joy=raw;c.keys=keys;c.finish()
  j=raw&31;expected=bool(keys or (j&16 and j&3!=3 and j&12!=12))
  assert bool(not c.f&64)==expected,(raw,keys,c.f)
print('PASS: 512 loader FIRE reads; disconnected port cannot block SPACE')
