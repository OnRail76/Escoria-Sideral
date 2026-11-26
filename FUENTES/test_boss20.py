"""ALFA 0.20: native soil, progressive projectile speeds, boss finale and IRQ audio."""
from pathlib import Path
import zipfile, functools, struct
P=Path(__file__).resolve().parent
source=(P/'test_cpu.py').read_text();ns={'__file__':str(P/'test_cpu.py')};exec(compile(source[:source.index('assert i==len(tap)')],str(P/'test_cpu.py'),'exec'),ns)
CPU,S,boot,addr,png,blocks,BIN=[ns[n] for n in ('CPU','S','boot','addr','png','blocks','BIN')]
def call(c,n):c.sub(n);c.finish()
def zone(c):return b''.join(c.screen()[addr(y):addr(y)+32] for y in range(40,144))
def shadow(c):return bytes(c.m[S['shadow']:S['shadow_end']])
assert len(blocks)==24 and blocks[3][1:-1]+blocks[5][1:-1]==BIN
for i in range(0,24,2):
 h,d=blocks[i:i+2];assert len(h)==19 and h[0]==0 and d[0]==255 and struct.unpack('<H',h[12:14])[0]==len(d)-2
assert S['shadow_end']<=0xfd00
print('TAP structure, resident+bank, 48K memory PASS',flush=True)
with zipfile.ZipFile(P/'SUELO_ALIEN_V3.zip') as z:raw=z.read('05_alien/alien.bin')
assert len(raw)==576
c=boot()
for phase,(speed,hp,end) in enumerate(zip((5,6,7,8,9),(16,22,28,34,50),(75,75,75,75,100)),1):
 if phase>1:c.pc=S['next_phase'];c.run_to('loop')
 assert c.v('phase')==phase and c.v('boss_hp')==hp
 # Measure emitted logic across 12 successive projectile updates, no contact.
 c.set('px',8);c.set('boss',1);c.set('bon',1);c.set('bx',192);c.set('by',112);c.set('cheat',1)
 for j in range(12):call(c,'boss_attack');assert c.v('bx')==192-speed*(j+1),(phase,j,c.v('bx'))
 c.set('boss',0);c.set('bon',0);c.set('px',80)
 if phase==5:
  for scroll in range(0,192,2):
   c.set('scroll',scroll);call(c,'ground_render');scr=c.screen()
   for y in range(24):
    v=int.from_bytes(raw[y*24:y*24+24],'big');row=(((v<<scroll)|(v>>(192-scroll)))&((1<<192)-1)).to_bytes(24,'big');assert scr[addr(y+144):addr(y+144)+32]==row+row[:8],(scroll,y)
  png(c.screen(),'captura_suelo_v3.png');print('New soil: all 96 scroll offsets bit-exact PASS',flush=True)
  # Nurse has both types of evasive attack, increased burst and shorter gaps.
  c.set('boss',1);c.set('bon',1);c.set('bx',0);c.set('boss_burst',2);call(c,'boss_attack');assert c.v('boss_burst')==1 and c.v('boss_delay')==3
  c.set('bon',1);c.set('bx',0);call(c,'boss_attack');assert c.v('boss_burst') in (3,4) and c.v('boss_delay')==20
  for lane,by,keys,jump,want in [(1,112,0,255,2),(1,112,4,255,3),(0,136,4,255,2),(0,136,0,10,3)]:
   c.set('cheat',0);c.set('lives',3);c.set('death',0);c.set('inv',0);c.set('px',80);c.set('py',112);c.set('bon',1);c.set('lane',lane);c.set('bx',96);c.set('by',by);c.set('jump',jump);c.set('hon',0);c.pc=S['loop'];c.step_frame(keys);assert c.v('lives')==want,(lane,keys,c.v('lives'))
  print('Nurse faster fire, shorter rests, 3–4 shot bursts, high/low evasion PASS',flush=True)
 # Verify entire destruction choreography, preserving visible VRAM until publication.
 c.set('cheat',1);c.set('lives',3);c.set('death',0);c.set('jump',255);c.set('py',112);c.set('px',80);c.set('boss',1);c.set('boss_hp',0);c.set('boss_end',0);c.set('bon',0);c.set('hon',0);call(c,'sfx_bossdead');c.pc=S['loop']
 patterns=set();peak=0;edges=0;silent=0;audio_frames=0
 for tick in range(1,end+1):
  c.keys=0;c.audio_events.clear();c.step();c.run_to('render_begin');old=zone(c);t=c.t;c.run_to('publish');assert zone(c)==old,(phase,tick,'early write');c.run_to('ground');assert zone(c)==shadow(c),(phase,tick,'stale publication')
  c.run_to('win' if tick==end else 'loop');peak=max(peak,c.t-t)
  assert c.v('boss_end')==tick
  if c.audio_events:audio_frames+=1;edges+=len(c.audio_events);assert c.audio_events[-1][1]==0
  patterns.add(b''.join(c.screen()[addr(y,23):addr(y,23)+9] for y in range(80,144)))
  if phase==5 and tick in (6,25,58,88,98):png(c.screen(),f'captura_enfermera_muerte_{tick:02}.png')
 assert len(patterns)>=12 and edges>100 and audio_frames>=end//2,(phase,len(patterns),edges,audio_frames)
 print(f'Phase {phase}: speed {speed}, HP {hp}, destruction {end} ticks, {len(patterns)} distinct images, {audio_frames} audible updates, {edges} FE writes, peak body {peak} T PASS',flush=True)
 # next_phase will read the subsequent tape blocks, final remains pending until win.
 if phase==5:
  c.run_to('wait_final');assert c.screen()==(P/'final.scr').read_bytes() and c.tape_pos==24
  print('Final exact SCR after Nurse destruction PASS',flush=True)
