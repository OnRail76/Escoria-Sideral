"""ALFA 0.18.1: check intermediate VRAM, dirty publishing and coherent composition.
Instruction-level model; no real ULA contention, not a substitute for Fuse.
"""
from pathlib import Path
import random, zipfile, io
from PIL import Image
P=Path(__file__).resolve().parent
# Reuse the exact instruction harness without executing its whole suite.
source=(P/'test_cpu.py').read_text();ns={'__file__':str(P/'test_cpu.py')}
exec(compile(source[:source.index('assert i==len(tap)')],str(P/'test_cpu.py'),'exec'),ns)
CPU,S,boot,addr=ns['CPU'],ns['S'],ns['boot'],ns['addr']
def zone(c):return b''.join(c.m[0x4000+addr(y):0x4000+addr(y)+32] for y in range(40,144))
def shadow(c):return bytes(c.m[S['shadow']:S['shadow_end']])
def stage(phase):
 c=boot();c.set('cheat',1)
 for _ in range(phase-1):c.pc=S['next_phase'];c.run_to('loop')
 assert c.v('phase')==phase and zone(c)==shadow(c)
 return c
def full_enemy(c,i,x,d):
 for k,v in [('on',1),('x',x),('y',112),('dir',d),('period',3),('speed',2),('wait',1),('anim',0),('death',0),('hp',3),('species',int(c.v('phase')>=3 and i%2))]:c.set(f'e{i}'+k,v)
def render(c):
 c.sub('render_begin');c.finish();c.sub('erase_all');c.finish();c.sub('draw_all');c.finish();c.sub('publish');c.finish();assert zone(c)==shadow(c)
peak=0;count=0
for phase in range(1,6):
 c=stage(phase)
 # A visible four-actor scene, without intentional invulnerability blink.
 for i,x in enumerate([8,44,144,208]):full_enemy(c,i,x,int(i==0))
 c.set('spawn_delay',255);c.set('hdelay',255);c.set('cheat',1);render(c)
 for i in range(60):
  c.pc=S['loop'];c.keys=[1,1,0,1,8,0,2,16][i%8];c.step();c.run_to('render_begin');t=c.t;old=zone(c);c.run_to('publish')
  assert zone(c)==old,(phase,i,'VRAM written before publish')
  c.run_to('ground');assert zone(c)==shadow(c),(phase,i,'dirty region stale')
  c.run_to('loop');peak=max(peak,c.t-t);count+=1
 # Explicitly test exact clean-image composition (including all overlapping masks).
 for xs in [(0,40,112,216),(64,68,72,76),(4,12,16,20)]:
  c=stage(phase)
  for i,x in enumerate(xs):full_enemy(c,i,x,int(i==0))
  c.set('pose',6);c.set('px',80);c.set('py',112)
  render(c);staged=zone(c)
  reference=stage(phase)
  for i,x in enumerate(xs):full_enemy(reference,i,x,int(i==0))
  reference.set('pose',6);reference.set('px',80);reference.set('py',112)
  # clear the initial player image before the reference draws all actors
  for y in range(64,144):reference.m[0x4000+addr(y):0x4000+addr(y)+32]=bytes(32)
  reference.sub('draw_all');reference.finish();assert zone(reference)==staged,(phase,xs,'composition mismatch')
 # verify complete boss patch renderer against independent approved PNGs
 name=['senor','bruja','mago','cocinero','enfermera'][phase-1]
 with zipfile.ZipFile(P/'BOSSES_TRAMADOS_FINAL.zip') as z:
  for state,frame,hit,delay in [('normal',10,0,20),('parpadeo',0,0,20),('impacto',10,12,20),('ataque',10,0,0)]:
   c=stage(phase);c.set('boss',1);c.set('frame',frame);c.set('boss_hit',hit);c.set('boss_delay',delay);c.set('px',16);render(c)
   actual=b''.join(c.m[0x4000+addr(y,26):0x4000+addr(y,26)+6] for y in range(80,144))
   expected=Image.open(io.BytesIO(z.read(name+'/'+state+'.png'))).convert('1').tobytes();assert actual==expected,(name,state)
 print('PASS stage',phase,'unchanged VRAM during composition, exact publication, overlapping sprites and four boss poses')
print('PASS:',count,'staged updates. Peak sampled body:',peak,'nominal T-states; no ULA contention model.')
