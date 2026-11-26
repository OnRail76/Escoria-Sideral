"""Regression of actual emitted input code; no hardware/ULA emulation."""
from pathlib import Path
P=Path(__file__).resolve().parent
src=(P/'test_cpu.py').read_text();ns={'__file__':str(P/'test_cpu.py')}
exec(compile(src[:src.index('assert i==len(tap)')],str(P/'test_cpu.py'),'exec'),ns)
CPU,S=ns['CPU'],ns['S']
# Test all port values, including high bits, disconnected $ff and impossible directions.
for raw in range(256):
 for keys in (0,1,2,4,8,16,17,24):
  c=CPU();c.joy=raw;c.keys=keys;c.set('joy',1);c.sub('input');c.finish()
  j=raw&31;valid=(j&3)!=3 and (j&12)!=12
  assert c.v('keys')==keys|(j if valid else 0),(raw,keys,c.v('keys'))
print('PASS: 2048 input combinations, upper bits ignored, impossible directions rejected, keyboard always enabled')
c=ns['boot']();assert c.v('joy')==0
c.joy=1;c.step_frame();assert c.v('joy')==1 and c.v('scroll')==2
c.joy=2;c.step_frame();assert c.v('px')==78
c.joy=8;c.step_frame();assert c.v('jump')!=255
c.joy=255;c.step_frame(1);assert c.v('px')==80
print('PASS: keyboard start -> joystick right/left/jump without FIRE -> keyboard after disconnected joystick')
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
