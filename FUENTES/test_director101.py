"""V1.0.1 candidate: actual emitted Z80 director and hazard tests."""
from pathlib import Path
P=Path(__file__).resolve().parent
src=(P/'test_cpu.py').read_text();ns={'__file__':str(P/'test_cpu.py')};exec(compile(src[:src.index('assert i==len(tap)')],str(P/'test_cpu.py'),'exec'),ns)
CPU,S,boot=ns['CPU'],ns['S'],ns['boot']
def call(c,n):c.sub(n);c.finish()
def phase_boot(phase):
 c=boot()
 for _ in range(phase-1):c.pc=S['next_phase'];c.run_to('loop')
 return c
def clear(c):
 for i in range(4):c.set(f'e{i}on',0)
# Sample actual spawn decision and species, including blocked front.
for phase in range(1,6):
 c=phase_boot(phase);c.set('cheat',1);speeds=set();species=set();hp=set()
 for _ in range(256):
  clear(c);c.set('spawn_delay',0);c.set('hdelay',255);c.set('keys',0);call(c,'update')
  assert c.v('e0on')==1 and c.v('e0dir')==0 and 210<=c.v('e0x')<=216
  speeds.add(c.v('e0speed'));species.add(c.v('e0species'));hp.add(c.v('e0hp'))
 assert 2 in speeds and 4 in speeds and species==({0,1} if phase>=3 else {0})
 clear(c);c.set('e0on',1);c.set('e0x',216);c.set('e0wait',2);c.set('spawn_delay',0);call(c,'update');assert not any(c.v(f'e{i}on') for i in range(1,4))
 print('Phase',phase,': 256 front-only spawns; speed/species/HP',speeds,species,hp,'blocked entry PASS',flush=True)
# Discover each real tactical pattern, save random state and hazard state at launch.
for phase in range(1,6):
 c=phase_boot(phase);c.set('px',80);c.set('advance',0);clear(c);patterns={}
 for _ in range(160):
  c.set('hon',0);c.set('hdelay',0);call(c,'hazard');kind=c.v('htype');x=c.v('hx');name='ahead' if x>88 else 'center' if x==88 else 'trail';patterns.setdefault((kind,name),bytes(c.m))
 assert len(patterns)==(3 if phase<=2 else 6),patterns.keys()
 for (kind,name),memory in patterns.items():
  results={}
  for action,key in [('stop',0),('forward',1),('back',2)]:
   c.m[:]=memory;c.set('lives',3);c.set('inv',0);c.set('death',0);c.set('hdelay',255);c.set('spawn_delay',255)
   start=c.v('hx');seen=[]
   for _ in range(48):
    if not c.v('hon'):break
    c.set('keys',key);call(c,'update');seen.append(c.v('hx'))
   results[action]=c.v('lives')
   if action=='stop':assert set(seen)=={start},(phase,kind,name,seen)
   if action=='forward':assert all(a>=b for a,b in zip([start]+seen,seen))
  assert results['stop']==(3 if name=='ahead' else 2),(phase,kind,name,results)
  assert results['forward']==(2 if name=='ahead' else 3),(phase,kind,name,results)
  assert results['back']==3,(phase,kind,name,results)
  print('Phase',phase,'hazard',kind,name,results,'PASS',flush=True)
 # Crowd against left border: defer, no forced unavoidable hit.
 c.set('px',0);c.set('death',0);c.set('hon',0);c.set('hdelay',0);c.set('e0on',1);c.set('e0x',30);call(c,'hazard');assert c.v('hon')==0 and c.v('hdelay')==12
 print('Phase',phase,'corner safety PASS',flush=True)
print('PASS: front-only director and positional environmental hazards; no homing')

# Dynamic full-frame rendering of the hazards as the camera scrolls.
addr=ns['addr']
def zone(c,y0,y1):return b''.join(c.screen()[addr(y):addr(y)+32] for y in range(y0,y1))
for phase in range(1,6):
 for kind in ([0] if phase<3 else [0,2]):
  c=phase_boot(phase);c.set('cheat',1);c.set('spawn_delay',255);c.set('hdelay',255);top=zone(c,40,64)
  c.set('hon',1);c.set('htype',kind);c.set('hx',128 if kind==0 else 112);c.set('hy',40 if kind==0 else 64);c.set('hboom',14 if kind==2 else 0);c.set('hscroll',0)
  for i in range(48):
   c.step_frame(1);assert zone(c,40,144)==bytes(c.m[S['shadow']:S['shadow_end']]),(phase,kind,i)
  assert not c.v('hon') and zone(c,40,64)==top,(phase,kind)
 print('Phase',phase,'moving hazard publication and backdrop restoration PASS',flush=True)
