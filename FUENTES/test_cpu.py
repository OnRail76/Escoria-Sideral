"""Small instruction-level Z80 harness for the emitted subset. No ROM/ULA contention.
Simulates FRAMES interrupts, input ports, and exact nominal instruction timings.
Not a replacement for a Spectrum emulator or hardware.
"""
from pathlib import Path
import json,struct,functools
from PIL import Image
P=Path(__file__).resolve().parent
S=json.loads((P/'symbols.json').read_text()); BIN=(P/'escoria.bin').read_bytes()
class CPU:
 def __init__(self):
  self.m=bytearray(65536);self.m[S['start']:S['start']+len(BIN)]=BIN;self.r=[0]*8;self.f=0;self.sp=65534;self.pc=S['start'];self.t=0;self.irq=69888;self.ie=False;self.keys=0;self.joy=0;self.steps=0;self.ix=0;self.tape_pos=6;self.audio_events=[]
 def read(self):v=self.m[self.pc];self.pc=(self.pc+1)&65535;return v
 def word(self):return self.read()|self.read()<<8
 def rdw(self,a):return self.m[a]|self.m[(a+1)&65535]<<8
 def wrw(self,a,v):self.m[a]=v&255;self.m[(a+1)&65535]=v>>8
 def pair(self,i):return self.sp if i==3 else self.r[i*2]*256+self.r[i*2+1]
 def putpair(self,i,v):
  v&=65535
  if i==3:self.sp=v
  else:self.r[i*2]=v>>8;self.r[i*2+1]=v&255
 def get(self,i):return self.m[self.pair(2)] if i==6 else self.r[i]
 def put(self,i,v):
  v&=255
  if i==6:self.m[self.pair(2)]=v
  else:self.r[i]=v
 def push(self,v):self.sp=(self.sp-2)&65535;self.wrw(self.sp,v)
 def pop(self):v=self.rdw(self.sp);self.sp=(self.sp+2)&65535;return v
 def flags(self,v,c=0):self.f=(64 if not v&255 else 0)|(1 if c else 0)
 def cond(self,i):return [not self.f&64,bool(self.f&64),not self.f&1,bool(self.f&1)][i]
 def op(self,k,v):
  a=self.r[7]
  if k==0:n=a+v;self.flags(n,n>255)
  elif k==2:n=a-v;self.flags(n,n<0)
  elif k==4:n=a&v;self.flags(n)
  elif k==5:n=a^v;self.flags(n)
  elif k==6:n=a|v;self.flags(n)
  elif k==7:n=a-v;self.flags(n,n<0);return
  else:raise AssertionError(k)
  self.r[7]=n&255
 def step(self):
  pc=self.pc
  # Collapse only complete non-interrupting iterations of the 41T audio polling loop.
  # The iteration that sees the interrupt and the final delay iteration still execute normally.
  if pc==S['audio_poll'] and self.ie and self.m[0x5c78]==self.r[2]:
   k=min((self.r[1] or 256)-1,max(0,(self.irq-self.t-1)//41))
   if k>0:
    self.r[7]=self.r[2];self.r[1]=(self.r[1]-k)&255;self.flags(self.r[1]);self.t+=41*k;self.steps+=5*k;return
  # Mock only the ROM tape entry: validate flags, lengths and checksum; actual Z80 executes all dispatch/restore logic.
  if pc==0x0556:
   assert self.f&1 and self.tape_pos<len(blocks),(self.tape_pos,self.r[7]);b=blocks[self.tape_pos];self.tape_pos+=1
   valid=b[0]==self.r[7] and len(b)==self.pair(1)+2
   if valid:self.m[self.ix:self.ix+len(b)-2]=b[1:-1];self.ix+=len(b)-2;self.putpair(1,0)
   self.f=1 if valid else 0;self.pc=self.pop();return
  o=self.read();t=4;self.steps+=1
  if o==0x00:pass
  elif o==0x76:
   assert self.ie; t=max(4,self.irq-self.t)
  elif 0x40<=o<=0x7f:self.put((o>>3)&7,self.get(o&7));t=7 if 6 in [(o>>3)&7,o&7] else 4
  elif 0x80<=o<=0xbf:self.op((o>>3)&7,self.get(o&7));t=7 if o&7==6 else 4
  elif o in [0xc6,0xd6,0xe6,0xee,0xf6,0xfe]:self.op({0xc6:0,0xd6:2,0xe6:4,0xee:5,0xf6:6,0xfe:7}[o],self.read());t=7
  elif o&0xc7==6 and o<0x40:i=(o>>3)&7;self.put(i,self.read());t=10 if i==6 else 7
  elif o&0xcf==1 and o<0x40:self.putpair(o>>4,self.word());t=10
  elif o&0xcf in [3,11] and o<0x40:i=o>>4;self.putpair(i,self.pair(i)+(1 if o&15==3 else -1));t=6
  elif o&0xc7 in [4,5] and o<0x40:
   i=(o>>3)&7;v=(self.get(i)+(1 if o&7==4 else -1))&255;self.put(i,v);self.flags(v,self.f&1);t=11 if i==6 else 4
  elif o&0xcf==9 and o<0x40:
   n=self.pair(2)+self.pair(o>>4);self.putpair(2,n);self.f=(self.f&64)|(n>65535);t=11
  elif o in [0x3a,0x32,0x22,0x2a]:
   a=self.word();t=13 if o in [0x3a,0x32] else 16
   if o==0x3a:self.r[7]=self.m[a]
   elif o==0x32:self.m[a]=self.r[7]
   elif o==0x22:self.wrw(a,self.pair(2))
   else:self.putpair(2,self.rdw(a))
  elif o==0x1a:self.r[7]=self.m[self.pair(1)];t=7
  elif o==0x12:self.m[self.pair(1)]=self.r[7];t=7
  elif o in [0x07,0x0f]:
   a=self.r[7];self.r[7]=((a<<1)|(a>>7))&255 if o==7 else ((a>>1)|(a<<7))&255;self.f=(self.f&64)|((a>>7) if o==7 else a&1)
  elif o==0xeb:a=self.pair(1);self.putpair(1,self.pair(2));self.putpair(2,a)
  elif o==0xc3 or o in [0xc2,0xca,0xd2,0xda]:
   a=self.word();t=10
   if o==0xc3 or self.cond((o-0xc2)//8):self.pc=a
  elif o==0xcd:a=self.word();self.push(self.pc);self.pc=a;t=17
  elif o==0xc9:self.pc=self.pop();t=10
  elif o in [0xc0,0xc8,0xd0,0xd8]:
   t=5
   if self.cond((o-0xc0)//8):self.pc=self.pop();t=11
  elif o&0xcf in [0xc1,0xc5]:
   i=(o>>4)&3
   if o&15==5:self.push(self.r[7]*256+self.f if i==3 else self.pair(i));t=11
   else:
    v=self.pop();t=10
    if i==3:self.r[7]=v>>8;self.f=v&255
    else:self.putpair(i,v)
  elif o==0xcb:
   b=self.read();assert 0x40<=b<0x80;self.flags(self.get(b&7)&(1<<((b>>3)&7)),self.f&1);t=8
  elif o==0xed:
   b=self.read()
   if b==0x78:
    p=self.pair(0);v=255
    if p==0x001f:v=self.joy
    else:
     for pp,bb,k in [(0xdffe,0,1),(0xdffe,1,2),(0xfdfe,0,4),(0xfbfe,0,8),(0x7ffe,0,16)]:
      if pp==p and self.keys&k:v&=~(1<<bb)
    self.r[7]=v;t=12
   elif b in (0x42,0x52):
    n=self.pair(2)-self.pair(0 if b==0x42 else 1)-(self.f&1);self.putpair(2,n);self.f=(64 if not n&65535 else 0)|(1 if n<0 else 0);t=15
   elif b==0x44:a=self.r[7];self.r[7]=(-a)&255;self.flags(-a,a!=0);t=8
   elif b==0x56:t=8
   elif b==0x5b:self.putpair(1,self.rdw(self.word()));t=20
   elif b==0x73:self.wrw(self.word(),self.sp);t=20
   elif b==0x7b:self.sp=self.rdw(self.word());t=20
   elif b==0xa0:
    h=self.pair(2);d=self.pair(1);self.m[d]=self.m[h];self.putpair(2,h+1);self.putpair(1,d+1);self.putpair(0,self.pair(0)-1);t=16
   elif b==0xb0:
    n=self.pair(0) or 65536;h=self.pair(2);d=self.pair(1)
    for _ in range(n):self.m[d]=self.m[h];h=(h+1)&65535;d=(d+1)&65535
    self.putpair(0,0);self.putpair(1,d);self.putpair(2,h);t=21*n-5
   else:raise AssertionError((hex(pc),hex(o),hex(b)))
  elif o==0xdd:
   q=self.read();a=self.word();assert q in (0x21,0x2a);self.ix=a if q==0x21 else self.rdw(a);t=14 if q==0x21 else 20
  elif o==0x37:self.f|=1
  elif o==0xfd:assert self.read()==0x21;self.word();t=14
  elif o==0xf3:self.ie=False
  elif o==0xfb:self.ie=True
  elif o==0xd3:
   port=self.read();t=11
   if port==0xfe:self.audio_events.append((self.t,self.r[7]))
  else:raise AssertionError((hex(pc),hex(o)))
  self.t+=t
  while self.t>=self.irq:
   if self.ie:self.m[0x5c78]=(self.m[0x5c78]+1)&255
   self.irq+=69888
 def run_to(self,lab,limit=2500000):
  target=S[lab];n=0
  while self.pc!=target:
   self.step();n+=1
   assert n<limit,(lab,hex(self.pc))
 def step_frame(self,keys=0):
  assert self.pc==S['loop'];self.keys=keys;self.step();n=0
  while self.pc not in [S['loop'],S['gameover'],S['win']]:
   self.step();n+=1;assert n<300000
 def v(self,n):return self.m[S[n]]
 def set(self,n,v):self.m[S[n]]=v
 def sub(self,n):self.push(0x0100);self.pc=S[n]
 def finish(self):
  n=0
  while self.pc!=0x0100:self.step();n+=1;assert n<300000
 def screen(self):return bytes(self.m[0x4000:0x5b00])
def addr(y,x=0):return ((y&192)<<5)+((y&7)<<8)+((y&56)<<2)+x
def png(scr,name):
 im=Image.new('RGB',(256,192));px=im.load();pal=[(0,0,0),(0,0,205),(205,0,0),(205,0,205),(0,205,0),(0,205,205),(205,205,0),(205,205,205)]
 for y in range(192):
  for x in range(256):
   a=scr[6144+y//8*32+x//8];idx=(a&7) if scr[addr(y,x//8)]&(128>>(x%8)) else (a>>3)&7;c=pal[idx];px[x,y]=tuple(255 if q and a&64 else q for q in c)
 im.resize((768,576),Image.Resampling.NEAREST).save(P/name)
def start_from_title(c,joy=False):
 c.run_to('title_press');assert c.screen()==(P/'titulo.scr').read_bytes()
 if joy:c.joy=16
 else:c.keys=16
 c.run_to('title_start_release');c.keys=c.joy=0;c.run_to('loop');return c
def boot():return start_from_title(CPU())
# Test TAP blocks and payload.
tap=(P/'base_sin_carga.tap').read_bytes();i=0;blocks=[]
while i<len(tap):
 n=int.from_bytes(tap[i:i+2],'little');b=tap[i+2:i+2+n];assert functools.reduce(int.__xor__,b)==0;blocks.append(b);i+=2+n
assert i==len(tap) and len(blocks)==24 and blocks[3][1:-1]+blocks[5][1:-1]==BIN
# Validate the actual ROM tape container, not merely XOR and payload.
for h,d,typ in [(blocks[i],blocks[i+1],0 if i==0 else 3) for i in range(0,24,2)]:
 assert len(h)==19 and h[0]==0 and h[1]==typ and d[0]==255
 name,length,p1,p2=struct.unpack('<10sHHH',h[2:-1])
 assert len(name)==10 and length==len(d)-2
 if typ==0:
  assert p1==10 and p2==length
 else:
  assert p1 in (S['start'],S['phase_bank'],0x4000) and p2==0 and p1+length<=0xfd00
print('PASS: ROM TAP headers, exact 19 bytes, types, flags, lengths and CODE address')
c=CPU();c.run_to('title_press');png(c.screen(),'captura_titulo.png');assert c.screen()==(P/'titulo.scr').read_bytes();c.run_to('title_press')
# Wait without input, then fresh SPACE starts; Kempston FIRE starts and locks joystick.
for _ in range(200):c.step()
assert c.pc in range(S['title_press'],S['title_start_release']) or c.pc in range(S['input'],S['near']) or c.pc in range(S['song_wait'],S['sfx_pitches'])
c=boot();assert c.v('joy')==0
j=start_from_title(CPU(),True);assert j.v('joy')==1 and j.v('lives')==3
print('PASS: title SCR exact, SPACE and Kempston FIRE, release gate')
c=boot();assert c.v('lives')==3 and c.v('px')==80;assert c.sp==65534
initial=c.screen();png(initial,'captura_inicio.png')
# Stopping stops progress. Moving forward at camera anchor advances terrain.
for _ in range(8):c.step_frame(0)
assert c.v('px')==80 and c.v('scroll')==0 and c.v('progress')==0
poses=set()
for _ in range(20):c.step_frame(1);poses.add(c.v('pose'))
assert c.v('px')==80 and c.v('scroll')==40 and c.v('progress')==5 and poses==set(range(1,7)),poses
import zipfile
with zipfile.ZipFile(P/'SUELOS_TRAMADOS.zip') as f:
 terrain=[f.read(n) for n in ['01_carretera/carretera.bin','02_ciudad/ciudad.bin','03_laboratorio/laboratorio.bin','04_ultratecnologia/ultratecnologia.bin','05_alien/alien.bin']]
with zipfile.ZipFile(P/'SUELO_ALIEN_V3.zip') as f:terrain[4]=f.read('05_alien/alien.bin')
def floor_check(c,phase,scroll):
 for y in range(24):
  row=terrain[phase-1][24*y:24*y+24];v=int.from_bytes(row,'big');r=(((v<<scroll)|(v>>(192-scroll)))&((1<<192)-1)).to_bytes(24,'big');assert c.screen()[addr(y+144):addr(y+144)+32]==r+r[:8],(phase,scroll,y)
floor_check(c,1,40)
for _ in range(8):c.step_frame(2)
assert c.v('px')==64 and c.v('scroll')==40
c=boot();jposes=set()
c.step_frame(8);assert c.v('py')<112
jposes.add(c.v('pose'))
for _ in range(21):c.step_frame(0);jposes.add(c.v('pose'))
assert c.v('py')==112 and {16,17,18,19}<=jposes,jposes
for keys,expected in [(4,{20,21,22}),(16,{13,14,15})]:
 c=boot();poses=set()
 for _ in range(8):c.step_frame(keys);poses.add(c.v('pose'))
 assert poses==expected,(keys,poses)
assert c.v('b0on') and not c.v('b0diag')
c=boot();poses=set()
for _ in range(18):c.step_frame(17);poses.add(c.v('pose'))
assert poses==set(range(7,13)),poses
# Verify reverse order, not just the set of frames; keep FIRE phase synchronized.
assert BIN[S['walk_pose']-S['start']:S['walk_pose']-S['start']+18]==bytes([6-i//3 for i in range(18)])
for keys,offset in [(1,0),(17,6)]:
 c=boot();seq=[]
 for _ in range(18):
  c.step_frame(keys);seq.append(c.v('pose'))
  assert c.v('pose')==6-c.v('walkclock')//3+offset
 assert seq==[6-((i+1)%18)//3+offset for i in range(18)],seq
c=boot()
for i in range(18):
 c.step_frame(17 if i%2 else 1)
 assert c.v('pose')==6-c.v('walkclock')//3+(6 if i%2 else 0)
print('PASS: reverse six-frame gait and synchronized walk/fire transitions')
c=boot();c.step_frame(24);assert c.v('jump')!=255 and not c.v('b0on')
c=boot();c.step_frame(20);assert not c.v('b0on')
# Controlled zombies: actual direction and speed assigned per entity.
def enemy(c,i,x,d=0,period=2,speed=2):
 for n,v in [('on',1),('x',x),('y',112),('dir',d),('period',period),('speed',speed),('wait',1),('hp',1)]:c.set(f'e{i}'+n,v)
c=boot();enemy(c,0,214,1);c.step_frame();assert c.v('e0x')==216
c.step_frame();c.step_frame();assert c.v('e0on')==0
# Rear walker passed by jumping backwards; no contact.
c=boot();enemy(c,0,44,1)
for j in range(15):c.step_frame(10 if j==0 else 2)
assert c.v('px')<c.v('e0x') and c.v('lives')==3, (c.v('px'),c.v('e0x'),c.v('lives'))
c=boot();enemy(c,1,84);c.step_frame();assert c.v('lives')==2
# Rifle-only overlap is safe; actual body overlap still kills, from both sides.
for x,d,want in [(98,0,3),(90,0,2),(94,1,3),(66,1,2),(62,1,3)]:
 c=boot();enemy(c,0,x,d);c.set('e0wait',2);c.step_frame();assert c.v('lives')==want,(x,d,want,c.v('lives'))
# A landing immediately behind a crossing zombie is safe even with rifle overlap.
c=boot();enemy(c,0,94,1);c.set('jump',21);c.set('e0wait',2);c.step_frame();assert c.v('jump')==255 and c.v('lives')==3
print('PASS: rifle-only overlap and landing safe; body contact lethal')
c=boot();enemy(c,1,136);c.set('b0on',1);c.set('b0x',140);c.set('b0y',126);c.step_frame();assert c.v('e1on')==2 and c.v('score0')==1
assert c.v('e1death')==24
for _ in range(24):c.step_frame()
assert c.v('e1on')==0
# Four ground zombies, two bullets, meteor; measure full body.
c=boot()
for i,x,d,period,speed in [(0,16,1,2,2),(1,200,0,3,2),(2,176,0,1,4),(3,40,0,3,2)]:enemy(c,i,x,d,period,speed)
for n,v in [('b0on',1),('b0x',120),('b0y',110),('b1on',1),('b1x',152),('b1y',48),('b2on',1),('b2x',104),('b2y',90),('hon',1),('hx',224),('hy',52)]:c.set(n,v)
c.set('spawn_delay',0);c.pc=S['erase_all'];c.push(0x0100);t=c.t;c.finish();erase=c.t-t
c.pc=S['loop'];c.keys=1;c.step();c.run_to('erase_all');t=c.t;c.run_to('loop');body=c.t-t;png(c.screen(),'captura_carga_maxima.png');assert c.sp==65534
# Every even offset of the 192-pixel native floor, including wrap.
c=boot();floor_check(c,1,0)
for phase in range(2,193,2):
 c.set('advance',1);c.sub('ground');c.finish();assert c.v('scroll')==phase%192;floor_check(c,1,phase%192)
# Spawn director: sample actual spawns, health, speed, direction and group timing.
c=boot();kinds=[];dirs=[];delays=[];hp=[];sizes=[]
for _ in range(255):
 c.set('spawn_delay',0);c.set('progress',0);c.set('frame',0);c.set('hdelay',100)
 for i in range(4):c.set(f'e{i}on',0)
 c.sub('update');c.finish();assert c.v('e0on') and c.v('e0y')==112
 kinds.append(c.v('e0speed'));dirs.append(c.v('e0dir'));delays.append(c.v('spawn_delay'));hp.append(c.v('e0hp'));sizes.append(c.v('wave_left'))
assert all(speed==2 for speed,d in zip(kinds,dirs) if d==1)
assert any(speed==4 and d==0 for speed,d in zip(kinds,dirs))
assert set(hp)==set(range(1,4)),hp
assert min(hp.count(i) for i in range(1,4))>=50
assert 4 in kinds and kinds.count(2)>kinds.count(4)*3 and 0 in dirs and 1 in dirs and dirs.count(0)>dirs.count(1) and len(set(delays))>15,(kinds.count(4),dirs.count(1),len(set(delays)))
print('Spawn sample: slow',kinds.count(2),'runners',kinds.count(4),'rear',dirs.count(1),'HP distribution',[hp.count(i) for i in range(1,4)],'unique intervals',len(set(delays)))
# Every HP count takes exactly N impacts; each projectile consumed, score only on final hit.
for hits in range(1,4):
 c=boot();enemy(c,1,136);c.set('e1hp',hits);c.set('spawn_delay',255)
 for n in range(hits):
  c.set('b0on',1);c.set('b0x',140);c.set('b0y',127);c.step_frame()
  assert c.v('b0on')==0 and c.v('e1hp')==hits-n-1
  assert c.v('e1on')==(2 if n==hits-1 else 1) and c.v('score0')==(1 if n==hits-1 else 0)
# Real continuous spawn sequence: maximum occupancy and both directions under walking.
c=boot();c.set('inv',255);counts=[];rear=False;front=False;rear_counts=[]
for i in range(160):
 c.set('inv',255);c.step_frame(1)
 rear_counts.append(sum(c.v(f'e{j}on')!=0 and c.v(f'e{j}dir')==1 for j in range(4)));active=[j for j in range(4) if c.v(f'e{j}on')==1];counts.append(len(active));rear|=any(c.v(f'e{j}dir') for j in active);front|=any(not c.v(f'e{j}dir') for j in active)
assert max(rear_counts)==1,rear_counts
assert max(counts)==4 and rear and front,(max(counts),rear,front)
print('Continuous movement occupancy: max',max(counts),'mean',round(sum(counts)/len(counts),2))
print('PASS: all rear-origin spawns walk; front runners retained')
print('Maximum rear-origin slots (including deaths):',max(rear_counts))
# Force attempts while an existing rear-origin zombie is alive or dying, even after crossing Ace.
for state in (1,2):
 for x in (48,120,160):
  c=boot();enemy(c,0,x,1);c.set('e0on',state);c.set('e0death',24);c.set('inv',255)
  for _ in range(12):
   c.set('spawn_delay',0);c.sub('update');c.finish()
   assert sum(c.v(f'e{j}on')!=0 and c.v(f'e{j}dir')==1 for j in range(4))<=1
print('PASS: rear lock holds through crossing and dying')
# Meteor uses only falling fire and never overwrites the road.
c=boot();c.set('hdelay',0);c.sub('hazard');c.finish();assert c.v('hon') and c.v('htype')==0 and c.v('hy')==40
for _ in range(50):
 if not c.v('hon'):break
 c.sub('hazard');c.finish();assert c.v('hy')<=128
assert not c.v('hon')
# Meteor target locked at spawn, horizontal range close to Ace, no homing.
for px in (0,2,40,80,126,176):
 c=boot();c.set('px',px);xs=set()
 for _ in range(80):
  c.set('hon',0);c.set('hdelay',0);c.sub('hazard');c.finish();hx=c.v('hx');xs.add(hx)
  assert hx%8==0 and 0<=hx<=240 and abs(hx+4-((px&252)+13))<=35,(px,hx)
  c.set('px',176 if px<80 else 0);c.sub('hazard');c.finish();assert c.v('hx')==hx;c.set('px',px)
 assert len(xs)>=4,(px,xs)
print('PASS: 480 targeted meteor spawns, bounded and varied, no homing')
# Moon retains original pixels and attributes before and after a meteor crosses it.
with zipfile.ZipFile(P/'LUNA_ZX.zip') as z:moon=z.read('luna_bitmap.bin');attrs=z.read('luna_atributos.bin')
def moon_check(c):
 sc=c.screen()
 assert b''.join(sc[addr(y,23):addr(y,23)+6] for y in range(16,64))==moon
 assert b''.join(sc[6144+y*32+23:6144+y*32+29] for y in range(2,8))==attrs
c=boot();moon_check(c)
for x in range(184,232,8):
 for y in range(40,64):
  c.set('hon',1);c.set('hx',x);c.set('hy',y);c.sub('draw_all');c.finish();c.sub('erase_all');c.finish();moon_check(c)
c.set('px',176);c.set('inv',255);c.set('spawn_delay',255);c.pc=S['loop']
for _ in range(35):c.step_frame()
moon_check(c)
print('PASS: original moon bitmap/attributes; meteor crossing restores background')
# Projectile collisions also ignore the extended rifle.
for hx,want in [(104,3),(88,2)]:
 c=boot();c.set('hon',1);c.set('hx',hx);c.set('hy',117);c.sub('hazard');c.finish();assert c.v('lives')==want,(hx,c.v('lives'))
for bx,want in [(108,3),(96,2)]:
 c=boot();c.set('boss',1);c.set('bon',1);c.set('bx',bx);c.set('by',112);c.sub('boss_attack');c.finish();assert c.v('lives')==want,(bx,c.v('lives'))
print('PASS: meteor and boss projectile body bounds')
# HUD attribute bands and cyan gameplay.
sc=boot().screen();assert all(sc[6144+y*32+x]==0x45 for y in range(21) for x in range(32) if not (2<=y<8 and 23<=x<29));assert set(sc[6144+21*32:])=={0x46,0x44,0x47}
# Boss transition and eye hits.
c=boot();c.set('progress',249);c.set('distance_sub',3);c.step_frame();assert c.v('boss')==0
c.step_frame(1);assert c.v('boss')==1
# Actual alternating boss spawn lanes; sample projectile at the approach.
c.set('boss_delay',0);c.step_frame();assert c.v('bon') and c.v('lane')==1 and c.v('by')==112
for _ in range(8):c.step_frame(4)
png(c.screen(),'captura_jefe.png')
c.set('bon',0);c.set('boss_delay',0);c.step_frame();assert c.v('bon') and c.v('lane')==0 and c.v('by')==136
# High projectile hits standing, misses crouch. Low hits crouch, misses jumping.
for lane,y,keys,jump,want in [(1,112,0,255,2),(1,112,4,255,3),(0,136,4,255,2),(0,136,0,10,3)]:
 c=boot();c.set('boss',1);c.set('bon',1);c.set('lane',lane);c.set('bx',96);c.set('by',y);c.set('jump',jump);c.step_frame(keys);assert c.v('lives')==want,(lane,keys,jump,c.v('lives'))
# First projectile must be launched before damage. A burst can inflict only one hit.
c=boot();c.set('boss',1);c.set('boss_delay',100);c.set('cheat',1)
def inject_eye(c,count=1):
 c.set('frame',8)
 for i in range(count):
  p=f'b{i}';c.set(p+'on',1);c.set(p+'x',216);c.set(p+'y',127);c.set(p+'diag',0)
 c.step_frame()
inject_eye(c,3);assert c.v('boss_hp')==16 and not c.v('boss_ready')
c.set('boss_delay',0);c.step_frame();assert c.v('boss_ready') and c.v('bon')
inject_eye(c,3);assert c.v('boss_hp')==15
for _ in range(11):
 inject_eye(c);assert c.v('boss_hp')==15
inject_eye(c);assert c.v('boss_hp')==14
for hp in range(13,-1,-1):
 for _ in range(11):c.step_frame()
 inject_eye(c);assert c.v('boss_hp')==hp,(hp,c.v('boss_hp'))
assert c.pc==S['loop']
for _ in range(75):c.step_frame()
assert c.pc==S['win'];png(c.screen(),'captura_jefe_derrotado.png')
print('PASS: Senor 16 hits, first attack gate, 12-update damage cooldown, no stacked hits')
# Ace death lasts 24 updates, including all six frames.
c=boot();enemy(c,0,82);c.step_frame();assert c.v('lives')==2 and c.v('death')==24
poses={c.v('pose')}
for _ in range(23):c.step_frame();poses.add(c.v('pose'))
assert poses==set(range(23,29)),poses
c.step_frame();assert c.v('death')==0
# Death animation cannot drain another life; protection starts only at respawn.
c=boot();enemy(c,0,82);c.step_frame();assert c.v('lives')==2 and c.v('death')==24
for _ in range(23):
 c.sub('hurt');c.finish();c.pc=S['loop'];assert c.v('lives')==2
 c.step_frame();assert c.v('death')>0
c.step_frame();assert c.v('death')==0 and c.v('inv')==100 and c.v('lives')==2
# Test exactly 100 elapsed ROM interrupts, including wrap, and rendered blink.
for i in range(4):c.set(f'e{i}on',0)
c.set('spawn_delay',255);c.set('hdelay',255);c.set('hon',0)
start=c.v('inv_last');seen=set()
for _ in range(60):
 c.step_frame();elapsed=(c.v('inv_last')-start)&255
 assert c.v('inv')==max(0,100-elapsed),(elapsed,c.v('inv'))
 if c.v('inv'):
  c.sub('hurt');c.finish();c.pc=S['loop'];assert c.v('lives')==2
  # Ace area is empty on hidden updates, nonzero on visible ones.
  visible=any(c.screen()[addr(y,10):addr(y,10)+4]!=bytes(4) for y in range(112,144))
  assert visible==(not bool(c.v('inv')&8)),(elapsed,visible)
  seen.add(visible)
 else:break
assert elapsed>=100 and seen=={False,True}
c.sub('hurt');c.finish();assert c.v('lives')==1 and c.v('death')==24
# Test FRAMES low-byte wrap and a delayed update (skipped game ticks).
c=boot();c.set('inv',100);c.set('inv_last',250);c.m[0x5c78]=4
c.sub('update');c.finish();assert c.v('inv')==90
c.m[0x5c78]=94;c.sub('update');c.finish();assert c.v('inv')==0
print('PASS: death guard, 100 ROM interrupts after respawn, blink visible/hidden, wrap, damage resumes')
# Extra lives exactly at 1000, 2500, 4000; no repeated grant on idle HUD.
c=boot()
for event in range(1,401):
 c.sub('score_inc');c.finish()
 score=10*sum(c.v(f'score{i}')*10**i for i in range(5))
 assert score==event*10
 expected=3+sum(event>=threshold for threshold in (100,250,400))
 assert c.v('lives')==expected,(event,c.v('lives'))
 for _ in range(2) if event in (100,250,400) else ():
  c.sub('hud');c.finish();assert c.v('lives')==expected
# HUD renders two-digit lives; restart reinitializes bonus threshold and score.
c.set('lives',9);c.set('bonus_left',1);c.sub('score_inc');c.finish();assert c.v('lives')==10
c.sub('hud');c.finish()
for x,d in [(15,1),(16,0)]:
 assert bytes(c.screen()[addr(181+y,x)] for y in range(8))==bytes(c.m[S['digits']+d*8:S['digits']+d*8+8])
c.set('lives',99);c.set('bonus_left',1);c.sub('score_inc');c.finish();assert c.v('lives')==99 and c.v('bonus_left')==150
c.pc=S['restart'];c.run_to('loop');assert c.v('lives')==3 and c.v('bonus_left')==100 and c.v('inv')==0 and all(c.v(f'score{i}')==0 for i in range(5))
print('PASS: bonus lives 1000/2500/4000, no duplicate award, two HUD digits, cap 99, restart reset')
# Kempston auto lock.
c=boot();c.joy=17;c.step_frame();assert c.v('joy')==1 and c.v('scroll')==2
# First and third-second lockout: run end-screen until release branch.
c=boot();c.set('lives',0);c.step_frame();assert c.pc==S['gameover'];start=c.t;c.run_to('release_end',2500000);assert c.t-start>=149*69888
c.run_to('press_end');c.keys=16;c.run_to('title_release');assert c.screen()==(P/'titulo.scr').read_bytes();c.keys=0;start_from_title(c);assert c.v('lives')==3
print('PASS: game over returns to title; new game starts with fresh FIRE')
print('TAP: 24 checksummed blocks; code bytes',len(BIN));print('PASS: boot, 96 even scroll phases, movement-linked scroll, all Ace pose groups, zombie death, random spawns, meteor, HUD, boss high/low evasion, boss death, Kempston, end hold');print('Nominal full load body T-states:',body,'erase alone:',erase,'of 139776 nominal for 2 frames (no ULA/ROM overhead).')
(P/'test_results.txt').write_text(f'All checks PASS. Full-load sampled update body: {body} T-states nominal; erase {erase}. 2 frames: 139776 T-states. ROM/ULA not modeled.\n')

# Complete stage transition via the real Z80 dispatch and mocked ROM tape entry.
c=boot();c.set('lives',2);c.set('bonus_left',77);c.set('score0',3);c.set('score1',2);c.set('score2',1);c.set('boss',1);c.set('boss_hp',0);c.set('boss_end',74);c.step_frame();assert c.pc==S['win'];c.run_to('press_end');c.keys=16;c.run_to('loop');c.keys=0
assert c.v('phase')==2 and c.v('lives')==2 and c.v('bonus_left')==77 and [c.v(f'score{i}') for i in range(3)]==[3,2,1] and c.v('boss_hp')==22 and c.v('progress')==0 and c.tape_pos==10
assert c.m[S['phase_bank']:S['phase_bank']+S['phase_size']]==(P/'fase2.bin').read_bytes()
with zipfile.ZipFile(P/'BARCELONA_ZX_V2.zip') as z:city=z.read('bitmap.bin')
def city_check(c):
 sc=c.screen();assert b''.join(sc[addr(y):addr(y)+32] for y in range(16,64))==city
 assert set(sc[6144+21*32:])=={0x46,0x44,0x47}
city_check(c);png(c.screen(),'captura_barcelona.png')
for x in range(0,241,8):
 for y in (40,43,49,55,61,63):
  c.set('hon',1);c.set('hx',x);c.set('hy',y);c.sub('draw_all');c.finish();c.sub('erase_all');c.finish();city_check(c)
c.set('hon',0);c.pc=S['loop'];c.set('inv',255);c.set('spawn_delay',255);c.set('hdelay',255)
floor_check(c,2,0)
for i in range(96):
 c.step_frame(1);city_check(c);floor_check(c,2,c.v('scroll'))
print('PASS: city overlay, carry lives/score/bonus, exact backdrop, 186 meteor crossings, fine scroll')
c.set('progress',249);c.set('distance_sub',3);c.step_frame(1);assert c.v('boss')==1;c.set('inv',0);c.set('boss_delay',0);c.step_frame();assert c.v('bon');png(c.screen(),'captura_bruja.png')
# Check boss 2 burst pause and alternating shots; all one projectile at a time.
c.set('inv',255);c.set('boss_burst',2);c.set('bx',0);c.sub('boss_attack');c.finish();assert c.v('boss_delay')==4 and c.v('boss_burst')==1 and not c.v('bon')
c.set('bon',1);c.set('bx',0);c.sub('boss_attack');c.finish();assert c.v('boss_delay')==30 and c.v('boss_burst') in (2,3)
# Game over after stage 2 returns to title. Rewind tape to ROADBANK, reload first stage.
c.pc=S['loop'];c.set('lives',0);c.set('death',0);c.step_frame();assert c.pc==S['gameover'];c.run_to('press_end');c.keys=16;c.run_to('title_release');c.keys=0;c.tape_pos=0;start_from_title(c);assert c.v('phase')==1 and c.v('lives')==3 and c.tape_pos==6;moon_check(c)
print('PASS: witch fire rhythm and restart from rewound tape; ROM transfer simulated, not full emulator')

# Phase 2: 22 valid hits, including first-attack gate.
c=boot();c.pc=S['next_phase'];c.run_to('loop');c.set('boss',1);c.set('boss_delay',100);c.set('cheat',1)
inject_eye(c,3);assert c.v('boss_hp')==22
c.set('boss_delay',0);c.step_frame();assert c.v('boss_ready')
for hp in range(21,-1,-1):
 inject_eye(c,3);assert c.v('boss_hp')==hp
 if hp:
  for _ in range(11):c.step_frame()
assert c.v('boss_hp')==0
for _ in range(75):c.step_frame()
assert c.pc==S['win'];print('PASS: witch 22 valid eye hits and complete defeat animation')
# Held fire from a normal encounter with invulnerability: count actual launches and elapsed updates.
for phase,hp in [(1,16),(2,22)]:
 c=boot()
 if phase==2:c.pc=S['next_phase'];c.run_to('loop')
 c.set('cheat',1);c.set('progress',249);c.set('distance_sub',3)
 c.step_frame(17);assert c.v('boss') and c.v('boss_hp')==hp
 launches=0;lanes=set();first_damage=None;prev=0
 for ticks in range(1,1801):
  old_hp=c.v('boss_hp');c.step_frame(16)
  active=c.v('bon')
  if active and not prev:launches+=1;lanes.add(c.v('lane'))
  prev=active
  if c.v('boss_hp')<old_hp and first_damage is None:first_damage=ticks;assert launches>=1
  if not c.v('boss_hp'):break
 assert c.v('boss_hp')==0 and launches>=3 and lanes=={0,1},(phase,ticks,launches,lanes,c.v('boss_hp'))
 print(f'PASS: phase {phase} held FIRE, first damage {first_damage}, defeat {ticks} updates, {launches} attacks launched, both lanes')

# Cheat title: two distinct down presses; held down counts once; activation FIRE
# does not start gameplay. Second fresh FIRE starts, and protection survives tape.
def title_tick(c,keys=0,joy=0):
 assert c.pc==S['title_press'];c.keys=keys;c.joy=joy;c.step();c.run_to('title_press')
for use_joy in (False,True):
 c=CPU();c.run_to('title_press')
 def down():title_tick(c,0 if use_joy else 4,4 if use_joy else 0)
 down();down();down();assert c.v('cheat_steps')==1 and not c.v('cheat')
 title_tick(c);down();title_tick(c);assert c.v('cheat_steps')==2
 c.keys=0 if use_joy else 16;c.joy=16 if use_joy else 0;c.run_to('title_cheat_release');assert c.v('cheat')==1
 assert bytes(c.screen()[6144+14*32+10:6144+14*32+22])==bytes([0x44])*12
 assert b''.join(c.screen()[addr(y,10):addr(y,10)+12] for y in range(112,120))==BIN[S['msg_cheat']-S['start']:S['msg_cheat']-S['start']+96]
 if not use_joy:png(c.screen(),'captura_truco.png')
 c.keys=c.joy=0;c.run_to('title_press');c.keys=0 if use_joy else 16;c.joy=16 if use_joy else 0;c.run_to('title_start_release');c.keys=c.joy=0;c.run_to('loop');assert c.v('cheat')==1 and c.v('lives')==3
 for _ in range(5):c.sub('hurt');c.finish();assert c.v('lives')==3 and not c.v('death')
 # Actual zombie collision while cheat on.
 c.pc=S['loop'];enemy(c,0,82);c.step_frame();assert c.v('lives')==3 and not c.v('death')
 c.pc=S['next_phase'];c.run_to('loop');assert c.v('phase')==2 and c.v('cheat')==1 and c.v('lives')==3
 c.sub('hurt');c.finish();assert c.v('lives')==3
 c.pc=S['title'];c.run_to('title_press');assert not c.v('cheat') and c.screen()==(P/'titulo.scr').read_bytes()
# One held down followed by FIRE must start normal game, never cheat.
c=CPU();c.run_to('title_press');title_tick(c,4);title_tick(c,4);title_tick(c);c.keys=16;c.run_to('title_start_release');c.keys=0;c.run_to('loop');assert not c.v('cheat');c.sub('hurt');c.finish();assert c.v('lives')==2
print('PASS: cheat QAOP and Kempston, separate presses, visible confirmation, fresh FIRE, collision immunity, phase persistence and reset on title')
# Verify boss frame bytes, independently against supplied PNGs and all five raw banks.
with zipfile.ZipFile(P/'BOSSES_TRAMADOS_FINAL.zip') as z:
 import io
 for phase,name in enumerate(('senor','bruja','mago','cocinero','enfermera'),1):
  raw=z.read(name+'/boss.bin');assert len(raw)==512
  meta=json.loads(z.read(name+'/metadata.json'));assert meta['placement']['eye_center_y_relative_to_floor']==-17
  for sym,pngname in [('boss_open','normal'),('boss_closed','parpadeo'),('boss_hit_img','impacto'),('boss_mouth','ataque')]:
   im=Image.open(io.BytesIO(z.read(name+'/'+pngname+'.png'))).convert('1');assert im.size==(48,64)
   expected=im.tobytes()
   if phase<=5:
    bank=(P/f'fase{phase}.bin').read_bytes();off=S[sym]-S['phase_bank'];baseoff=S['boss_open']-S['phase_bank'];actual=bytearray(bank[baseoff:baseoff+384])
    if sym!='boss_open':
     x,y,h=bank[off:off+3];x=(x-208)//8;y-=80
     for j in range(h):actual[(y+j)*6+x:(y+j)*6+x+2]=bank[off+3+j*2:off+5+j*2]
    assert bytes(actual)==expected,(name,sym)
print('PASS: new boss normal/blink/hit/attack frame bytes match approved PNGs for all five phases')

# The fifth-stage victory path is dormant until stages 3-5 exist.
# Exercise actual Z80 dispatcher with simulated ROM tape transfer, not a played fifth phase.
final=(P/'final.scr').read_bytes()
with zipfile.ZipFile(P/'FINAL_ZX_V2.zip') as z: assert final==z.read('final.scr')
assert blocks[22][2:12]==b'FINAL     ' and blocks[23][1:-1]==final
c=boot();c.pc=S['next_phase'];c.run_to('loop');c.pc=S['win'];c.run_to('press_end');assert c.tape_pos==10 and c.screen()!=final
c.keys=16;c.run_to('loop');assert c.tape_pos==14 and c.v('phase')==3
c.pc=S['win'];c.keys=0;c.run_to('press_end');c.keys=16;c.run_to('loop');assert c.tape_pos==18 and c.v('phase')==4
c=boot();c.set('phase',5);c.set('boss_hp',0);c.set('boss_end',100);c.tape_pos=22;c.pc=S['win'];c.keys=16;c.run_to('wait_final');assert c.tape_pos==24 and c.screen()==final
start=c.t;c.run_to('release_end');assert c.t-start>=149*69888 and c.screen()==final
c.keys=0;c.run_to('press_end');c.keys=16;c.run_to('title_release');assert c.screen()==(P/'titulo.scr').read_bytes()
png(final,'captura_final.png')
print('PASS: exact final SCR, only phase 5 victory branch, 3-second hold, fresh FIRE, return to title; phase 3 does not consume final block')

# Exact sparse renderer regression: all original frames, masks, directions and stored alignments.
# Start from a nonblack synthetic bitmap to detect accidental overwrites of transparent pixels.
from collections import Counter
with zipfile.ZipFile(P/'ACE_WISCONSIN_V3.zip') as a,zipfile.ZipFile(P/'recursos.zip') as z:
 banks=[('ace',a.read('sprites.bin'),a.read('masks.bin'),[(f'ace{i}',i,i>=23) for i in range(29)])]
 for species,group,dirs in [('zombie','03_ZOMBIE',[('left',0),('right',12)]),('alien','02_ALIEN',[('left',12),('right',0)])]:
  banks.append((species,z.read('RECURSOS/'+group+'/sprites.bin'),z.read('RECURSOS/'+group+'/masks.bin'),[(f'{species}_{direction}_{j}',idx+j,j>=6) for direction,idx in dirs for j in range(12)]))
 checked=0
 for species,bm,mk,frames in banks:
  for name,i,death in frames:
   for shift in ([0] if death else [0,4]):
    c=CPU();c.m[0x4000:0x5800]=bytes([0x5a])*6144;expected=bytearray(c.m[0x4000:0x5800]);x=48+shift;y=81;w=4 if shift==0 else 5
    for r in range(32):
     k=i*128+r*4;bits=int.from_bytes(bm[k:k+4],'big');opaque=(~int.from_bytes(mk[k:k+4],'big'))&0xffffffff
     vs=(bits<<shift).to_bytes(w,'big');ms=((~(opaque<<shift))&((1<<(w*8))-1)).to_bytes(w,'big');dst=addr(y+r,x//8)
     for j,(mask,b) in enumerate(zip(ms,vs)):expected[dst+j]=(expected[dst+j]&mask)|b
    c.r[7]=x;c.r[1]=y;c.putpair(1,S[name]);c.sub('actor_draw');c.finish();assert c.m[0x4000:0x5800]==expected,(name,shift);checked+=1
print(f'PASS: all {checked} sparse sprite frame/alignment combinations bit-exact against original bitmap AND mask')

def lab_boot():
 c=boot();c.pc=S['next_phase'];c.run_to('loop');c.set('lives',2);c.set('score0',7);c.set('bonus_left',93);c.set('cheat',1);c.set('boss',1);c.set('boss_hp',0);c.set('boss_end',74);c.step_frame();assert c.pc==S['win'];c.run_to('press_end');c.keys=16;c.run_to('loop');c.keys=0
 assert c.v('phase')==3 and c.tape_pos==14 and c.v('lives')==2 and c.v('score0')==7 and c.v('bonus_left')==93 and c.v('cheat')==1 and c.v('boss_hp')==28
 assert c.m[S['phase_bank']:S['phase_bank']+S['phase_size']]==(P/'fase3.bin').read_bytes()
 return c
with zipfile.ZipFile(P/'FONDOS_COMPLETOS.zip') as zz:lab_bg=zz.read('03_laboratorio/bitmap.bin')
def lab_bg_check(c):
 sc=c.screen();assert b''.join(sc[addr(y):addr(y)+32] for y in range(16,64))==lab_bg
 assert set(sc[6144+21*32:])=={0x46,0x44,0x47}
c=lab_boot();lab_bg_check(c);png(c.screen(),'captura_laboratorio.png');c.set('spawn_delay',255);c.set('hdelay',255)
for i in range(96):
 c.step_frame(1);lab_bg_check(c);floor_check(c,3,c.v('scroll'))
for x in range(0,241,8):
 for y in (40,43,49,55,61,63):
  c.set('hon',1);c.set('htype',0);c.set('hx',x);c.set('hy',y);c.sub('draw_all');c.finish();c.sub('erase_all');c.finish();lab_bg_check(c)
print('PASS: phase 2 -> 3 real dispatcher, resident state/cheat, green backdrop, 96 scroll offsets and 186 meteor crossings')
# Sample director parameters, test invariants for both species.
c=lab_boot();species=Counter();hp_by={0:set(),1:set()};runners=Counter();rear=Counter();periods={0:set(),1:set()}
for _ in range(512):
 c.set('spawn_delay',0);c.set('progress',0);c.set('frame',0);c.set('hdelay',100)
 for i in range(4):c.set(f'e{i}on',0)
 c.sub('update');c.finish();assert c.v('e0on') and c.v('e0y')==112
 k=c.v('e0species');d=c.v('e0dir');v=c.v('e0speed');period=c.v('e0period');hp=c.v('e0hp');species[k]+=1;hp_by[k].add(hp);periods[k].add(period)
 if d:rear[k]+=1;assert period>=2 and v==2
 if period==1:runners[k]+=1;assert d==0 and v==(5 if k else 4)
 if k and period!=1:assert period==2 and v==2
assert .23<species[1]/512<.40 and hp_by=={0:{1,2,3},1:{2,3,4}} and all(runners[k]>0 and rear[k]>0 for k in (0,1))
print('PASS: mixed director sample',dict(species),'HP',hp_by,'runners',dict(runners),'rear',dict(rear),'periods',periods)
c=lab_boot();mix=False;peak=0
for i in range(180):
 c.step_frame(1);active=[j for j in range(4) if c.v(f'e{j}on')];peak=max(peak,len(active));mix|=len(set(c.v(f'e{j}species') for j in active))==2;assert sum(c.v(f'e{j}dir') for j in active)<=1
assert peak==4 and mix
# Sample high load: two aliens, two zombies, 3 shots, moving terrain and full lightning column.
c=lab_boot();c.set('spawn_delay',255);c.set('hdelay',255)
for i,x,d,period,speed in [(0,16,1,2,2),(1,200,0,2,2),(2,176,0,1,5),(3,40,0,3,2)]:enemy(c,i,x,d,period,speed);c.set(f'e{i}species',int(i in (1,2)))
for n,v in [('b0on',1),('b0x',120),('b0y',110),('b1on',1),('b1x',152),('b1y',80),('b2on',1),('b2x',104),('b2y',90),('hon',1),('hx',112),('hy',64),('htype',3),('hboom',4)]:c.set(n,v)
c.sub('draw_all');c.finish();c.pc=S['loop'];c.keys=1;c.step();c.run_to('erase_all');t=c.t;c.run_to('loop');lab_body=c.t-t;assert c.sp==65534;lab_bg_check(c);png(c.screen(),'captura_laboratorio_combate.png');print('Lab full-load nominal T-states:',lab_body,'of 139776, no contention')
# Lightning warning/strike: precise timing, fixed x, collision and safe dodge.
for dodge in (False,True):
 c=lab_boot();c.set('cheat',0);c.set('lives',3);c.set('hx',88);c.sub('lightning_start');c.finish();assert c.v('htype')==2 and c.v('hboom')==14
 for i in range(13):
  c.sub('hazard');c.finish();assert c.v('htype')==2 and c.v('lives')==3 and c.v('hx')==88
 c.sub('draw_lightning');c.finish();png(c.screen(),'captura_aviso_rayo.png');c.sub('erase_lightning');c.finish();lab_bg_check(c)
 if dodge:c.set('px',120)
 c.sub('hazard');c.finish();assert c.v('htype')==3 and c.v('lives')==(3 if dodge else 2)
 c.sub('draw_lightning');c.finish();png(c.screen(),'captura_rayo.png');c.sub('erase_lightning');c.finish();lab_bg_check(c)
 for _ in range(4):c.sub('hazard');c.finish()
 assert not c.v('hon') and c.v('hx')==88
print('PASS: lightning warns for 14 updates, fixed target, 4 strike updates, damage only on strike, dodge and backdrop safe')
# Normal boss entry and continuous fire: horizontal lanes and lightning; no simultaneous hazards.
c=lab_boot();c.set('progress',249);c.set('distance_sub',3);c.step_frame(17);assert c.v('boss') and c.v('boss_hp')==28
launches=0;bolts=0;lanes=set();prev=prev_h=0
for ticks in range(1,2001):
 c.step_frame(16);active=c.v('bon');h=c.v('hon');assert not (active and h)
 if active and not prev:launches+=1;lanes.add(c.v('lane'))
 if h and not prev_h:bolts+=1;assert c.v('htype')==2
 if h and c.v('htype')==3:png(c.screen(),'captura_mago_rayo.png')
 if launches==1 and active:png(c.screen(),'captura_mago.png')
 prev=active;prev_h=h
 if not c.v('boss_hp'):break
assert c.v('boss_hp')==0 and bolts>0 and launches>=3 and lanes=={0,1},(ticks,launches,bolts,lanes,c.v('boss_hp'))
print(f'PASS: Mago 28 valid hits, defeat in {ticks} updates, {launches} horizontal attacks, {bolts} lightning attacks, both lanes, never simultaneous')
for _ in range(75):c.step_frame()
assert c.pc==S['win'];c.run_to('press_end');c.keys=16;c.run_to('loop');assert c.tape_pos==18 and c.v('phase')==4
(P/'test_results.txt').write_text(f'All checks PASS. Phase 1 sampled update body: {body} T-states. Phase 3 mixed sampled update body: {lab_body} T-states. Budget 139776 nominal; ULA/ROM not modeled.\n')
# Restart from the third-stage tape after rewinding, all original phase-1 data restored.
c=lab_boot();c.set('lives',0);c.set('death',0);c.step_frame();assert c.pc==S['gameover'];c.run_to('press_end');c.keys=16;c.run_to('title_release');c.keys=0;c.tape_pos=0;start_from_title(c);assert c.v('phase')==1 and c.v('lives')==3 and c.tape_pos==6 and not c.v('cheat');moon_check(c)
print('PASS: Game Over in phase 3 -> title -> rewind -> correct phase 1 bank and cleared cheat')

# Selector is hidden until the two distinct DOWN presses and FIRE; keyboard/joystick use the same edge logic.
def select_boot(target,joy=False):
 c=CPU();c.run_to('title_press')
 def tick(k):title_tick(c,0 if joy else k,k if joy else 0)
 tick(1);tick(0);assert c.v('selected_phase')==1 and not c.v('cheat')
 tick(4);tick(0);tick(4);tick(0)
 c.keys=0 if joy else 16;c.joy=16 if joy else 0;c.run_to('title_cheat_release')
 c.keys=c.joy=0;c.run_to('title_press');assert c.v('cheat') and c.v('selected_phase')==1
 tick(2);assert c.v('selected_phase')==5;tick(2);assert c.v('selected_phase')==5;tick(0);tick(1);assert c.v('selected_phase')==1;tick(0)
 for i in range(target-1):tick(1);tick(1);tick(0);assert c.v('selected_phase')==i+2
 assert b''.join(c.screen()[addr(y,21):addr(y,21)+1] for y in range(120,128))==BIN[S['digits']-S['start']+target*8:S['digits']-S['start']+(target+1)*8]
 if target==5 and not joy:png(c.screen(),'captura_selector.png')
 c.keys=0 if joy else 16;c.joy=16 if joy else 0;c.run_to('title_start_release');c.keys=c.joy=0;c.run_to('loop')
 assert c.v('phase')==target and c.v('cheat') and c.v('lives')==3 and c.v('bonus_left')==100 and c.tape_pos==6+4*(target-1)
 assert c.m[S['phase_bank']:S['phase_bank']+S['phase_size']]==(P/f'fase{target}.bin').read_bytes()
 return c
for j in (False,True):
 for n in range(1,6):select_boot(n,j)
print('PASS: hidden phase selector O/P and Kempston, edge debounce, wrap, visible selected digit, all ten direct starts and correct sequential tape position')

for phase,bgname,hp,ratio in [(4,'04_ultratecnologia',34,10/16),(5,'05_entorno_alien',50,13/16)]:
 with zipfile.ZipFile(P/'FONDOS_COMPLETOS.zip') as z:bg=z.read(bgname+'/bitmap.bin')
 c=select_boot(phase);assert c.v('boss_hp')==hp
 def bg_check(c):
  sc=c.screen();assert b''.join(sc[addr(y):addr(y)+32] for y in range(16,64))==bg
  assert set(sc[6144+21*32:])=={0x46,0x44,0x47}
 bg_check(c);png(c.screen(),f'captura_fase{phase}.png');c.set('spawn_delay',255);c.set('hdelay',255)
 for i in range(96):c.step_frame(1);bg_check(c);floor_check(c,phase,c.v('scroll'))
 for x in range(0,241,8):
  for y in (40,43,49,55,61,63):
   c.set('hon',1);c.set('htype',0);c.set('hx',x);c.set('hy',y);c.sub('draw_all');c.finish();c.sub('erase_all');c.finish();bg_check(c)
 print(f'PASS: phase {phase}, exact original backdrop, 96 terrain offsets, 186 meteor crossings')
 c=select_boot(phase);species=Counter();hp_by={0:set(),1:set()};runners=Counter();rear=Counter()
 for _ in range(512):
  c.set('spawn_delay',0);c.set('progress',0);c.set('frame',0);c.set('hdelay',100)
  for i in range(4):c.set(f'e{i}on',0)
  c.sub('update');c.finish();assert c.v('e0on') and c.v('e0y')==112
  k=c.v('e0species');d=c.v('e0dir');v=c.v('e0speed');period=c.v('e0period');species[k]+=1;hp_by[k].add(c.v('e0hp'))
  if d:rear[k]+=1;assert period>=2 and v==2
  if period==1:runners[k]+=1;assert d==0 and v==(5 if k else 4)
 assert abs(species[1]/512-ratio)<.09 and hp_by=={0:{1,2,3},1:{2,3,4}}
 print(f'PASS: phase {phase} director sample {dict(species)}, HP {hp_by}, runners {dict(runners)}, rear {dict(rear)}')
 c=select_boot(phase);c.set('progress',249);c.set('distance_sub',3);c.step_frame(17);assert c.v('boss') and c.v('boss_hp')==hp
 launches=0;bolts=0;meteors=0;lanes=set();prev=prev_h=0
 for ticks in range(1,3001):
  c.step_frame(16);active=c.v('bon');h=c.v('hon');assert not (active and h)
  if active and not prev:launches+=1;lanes.add(c.v('lane'))
  if h and not prev_h:
   if c.v('htype')==2:bolts+=1
   else:assert c.v('htype')==0;meteors+=1
  if launches==1 and active and not prev:png(c.screen(),f'captura_jefe{phase}.png')
  prev=active;prev_h=h
  if not c.v('boss_hp'):break
 assert not c.v('boss_hp') and launches>=3 and lanes=={0,1} and meteors>0 and (bolts>0 if phase==5 else bolts==0),(phase,ticks,launches,bolts,meteors,c.v('boss_hp'))
 print(f'PASS: phase {phase} boss defeat in {ticks} updates, {launches} horizontal, {meteors} falling fire, {bolts} lightning, no simultaneous attacks')
 for _ in range(100 if phase==5 else 75):c.step_frame()
 assert c.pc==S['win'];c.keys=0
 if phase==4:
  c.set('lives',2);c.set('bonus_left',73);c.set('score0',7);c.run_to('press_end');c.keys=16;c.run_to('loop');assert c.v('phase')==5 and c.tape_pos==22 and c.v('lives')==2 and c.v('bonus_left')==73 and c.v('score0')==7 and c.v('cheat')
 else:
  c.run_to('wait_final');assert c.tape_pos==24 and c.screen()==final
  c.run_to('press_end');c.keys=16;c.run_to('title_release');assert c.screen()==(P/'titulo.scr').read_bytes() and not c.v('cheat')
print('PASS: actual phase 4 boss -> phase 5 state persistence; actual phase 5 boss -> exact final -> title')
