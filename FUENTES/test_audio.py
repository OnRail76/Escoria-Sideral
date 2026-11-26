"""Audio on emitted Z80 with nominal interrupt timing; no listening or ULA claim."""
from pathlib import Path
P=Path(__file__).resolve().parent
source=(P/'test_cpu.py').read_text();ns={'__file__':str(P/'test_cpu.py')};exec(compile(source[:source.index('assert i==len(tap)')],str(P/'test_cpu.py'),'exec'),ns)
CPU,S,boot=ns['CPU'],ns['S'],ns['boot']
def call(c,n):c.sub(n);c.finish()
# Distinct event timbres; every audible wait must stop at next IRQ and leave speaker off.
for name,duration in [('beep',2),('sfx_hit',2),('sfx_kill',4),('sfx_bossfire',3),('sfx_meteor',5),('sfx_lightning',6),('sfx_bonus',8),('sfx_death',12),('sfx_bossdead',15)]:
 c=boot();call(c,name);rank=c.v('sound')>>4;assert c.v('sound')&15==duration
 if rank>1:call(c,'beep');assert c.v('sound')>>4==rank
 count=0
 for i in range(duration):
  c.audio_events.clear();deadline=c.irq;call(c,'audio_wait');assert deadline<=c.t<=deadline+350,(name,c.t-deadline)
  assert len(c.audio_events)>3 and c.audio_events[-1][1]==0 and {v for _,v in c.audio_events}=={0,16}
  count+=len(c.audio_events)
 assert not c.v('sound');print(name,duration,'IRQ ticks;',count,'FE writes; deadline and priority PASS')
# Title is one-shot, end jingles fit the existing hold, fire is not locked by song.
c=CPU();c.run_to('title_press');heard=0
for i in range(200):
 c.audio_events.clear();c.step();c.run_to('title_press');heard+=len(c.audio_events)
 if i>=180:assert not c.audio_events
assert heard>100 and not c.v('song_active');print('title one-shot and silence after end PASS')
for event in ('gameover','win'):
 c=boot();c.pc=S[event];c.keys=0;c.audio_events.clear();t=c.t;c.run_to('press_end');assert c.t-t>=149*69888 and not c.v('song_active') and len(c.audio_events)>100 and c.audio_events[-1][1]==0;print(event,'one-shot jingle, existing 3-second hold PASS')
# Actual input/events, not just direct effect calls.
c=boot();c.set('keys',16);call(c,'update');assert c.v('sound')>>4==1
c=boot();c.set('lives',3);call(c,'hurt');assert c.v('sound')>>4==8
c=boot();c.set('bonus_left',1);call(c,'score_inc');assert c.v('sound')>>4==7
c=boot();c.set('boss',1);c.set('boss_delay',0);call(c,'boss_attack');assert c.v('sound')>>4==4
c=boot();c.set('htype',0);c.set('hon',1);c.set('hy',128);call(c,'hazard');assert c.v('sound')>>4==5
c=boot();c.set('htype',2);c.set('hon',1);c.set('hboom',1);c.set('hx',8);call(c,'hazard');assert c.v('sound')>>4==6
print('Actual shot, loss, extra life, boss fire, meteor and lightning event routing PASS')
