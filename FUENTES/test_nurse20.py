from pathlib import Path
P=Path(__file__).resolve().parent
s=(P/'test_cpu.py').read_text();ns={'__file__':str(P/'test_cpu.py')};exec(compile(s[:s.index('assert i==len(tap)')],str(P/'test_cpu.py'),'exec'),ns)
S,boot,png=ns['S'],ns['boot'],ns['png']
c=boot();c.set('cheat',1)
for _ in range(4):c.pc=S['next_phase'];c.run_to('loop')
assert c.v('phase')==5 and c.v('boss_hp')==50
c.set('progress',249);c.set('distance_sub',3);c.step_frame(17);assert c.v('boss')
prev=prev_h=0;lanes=set();launches=meteors=bolts=0
for tick in range(1,3001):
 c.step_frame(16);b=c.v('bon');h=c.v('hon');assert not(b and h)
 if b and not prev:
  launches+=1;lanes.add(c.v('lane'))
  if launches==1:png(c.screen(),'captura_jefe5.png')
 if h and not prev_h:
  if c.v('htype')==2:bolts+=1
  else:meteors+=1;assert c.v('htype')==0
 prev=b;prev_h=h
 if not c.v('boss_hp'):break
assert not c.v('boss_hp') and launches>=3 and lanes=={0,1} and bolts>0 and meteors>0
print(f'PASS: nurse held FIRE, {tick} updates, {launches} horizontal attacks, {bolts} lightning, {meteors} meteors; both lanes, no overlapping hazards')
for _ in range(100):c.step_frame()
assert c.pc==S['win'];c.run_to('wait_final');assert c.screen()==(P/'final.scr').read_bytes() and c.tape_pos==24
print('PASS: complete boss destruction and final SCR via actual dispatcher')
