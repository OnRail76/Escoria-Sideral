"""Audio starvation regression: nominal Z80 timing, no ULA contention."""
from pathlib import Path
P=Path(__file__).resolve().parent
src=(P/'test_cpu.py').read_text();ns={'__file__':str(P/'test_cpu.py')};exec(compile(src[:src.index('assert i==len(tap)')],str(P/'test_cpu.py'),'exec'),ns)
CPU,S,boot=ns['CPU'],ns['S'],ns['boot']
def call(c,n):c.sub(n);c.finish()
for n in ('beep','sfx_hit','sfx_kill','sfx_bossfire','sfx_meteor','sfx_lightning','sfx_bonus','sfx_death','sfx_bossdead'):
 c=boot();call(c,n);c.set('last',(c.m[0x5c78]-2)&255);c.audio_events.clear();t=c.t;call(c,'sync');elapsed=c.t-t
 assert 6500<elapsed<10500,(n,elapsed)
 assert len(c.audio_events)>=4 and c.audio_events[-1][1]==0 and {v for _,v in c.audio_events}=={0,16},(n,c.audio_events)
 print(n,'late frame:',elapsed,'T,',len(c.audio_events),'FE writes PASS',flush=True)
c=boot();call(c,'sfx_kill');c.set('last',(c.m[0x5c78]-2)&255);call(c,'sync');v=c.v('sound');assert v==0x33
for name in ('beep','sfx_hit','sfx_kill'):call(c,name);assert c.v('sound')==v
call(c,'sfx_meteor');assert c.v('sound')==0x55
c.set('last',(c.m[0x5c78]-2)&255);call(c,'sync');assert c.v('sound')==0x54
for name in ('beep','sfx_hit','sfx_kill','sfx_bossfire','sfx_meteor'):call(c,name);assert c.v('sound')==0x54
call(c,'sfx_death');assert c.v('sound')==0x8c;call(c,'sfx_bossdead');assert c.v('sound')==0x9f
print('Priority: meteor > normal combat, death > meteor, no repeated reset, boss destruction can refresh PASS',flush=True)
peak=0;audio_peak=0
for phase in range(1,6):
 c=boot();c.set('cheat',1)
 for _ in range(phase-1):c.pc=S['next_phase'];c.run_to('loop')
 for i,x in enumerate((12,44,144,208)):
  for k,v in [('on',1),('x',x),('y',112),('dir',int(i==0)),('period',3),('speed',2),('wait',1),('anim',0),('death',0),('hp',3),('species',int(phase>=3 and i%2))]:c.set(f'e{i}'+k,v)
 c.set('spawn_delay',255);c.set('hdelay',255);c.set('hon',1);c.set('htype',0);c.set('hy',128);c.set('hx',100)
 c.keys=17;c.step_frame(17);assert c.v('sound')>>4==5
 c.audio_events.clear();t=c.t;c.step();c.run_to('render_begin');audio_peak=max(audio_peak,c.t-t);assert len(c.audio_events)>=4 and c.audio_events[-1][1]==0
 t=c.t;c.run_to('loop');peak=max(peak,c.t-t)
 print('Phase',phase,'four actors + impact, meteor audible, frame body',c.t-t,'T PASS',flush=True)
print('Sample peak body',peak,'T; sync incl wait up to',audio_peak,'T; no ULA contention model',flush=True)
