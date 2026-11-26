"""Check physical TAP layout and actual emitted loading gate. ROM BASIC/ULA not emulated."""
from pathlib import Path
import struct, zipfile
from loading import split,stub,STUB_ADDR,wrap
P=Path(__file__).resolve().parent
base=(P/'base_sin_carga.tap').read_bytes();tap=(P/'ESCORIA_SIDERAL_ALFA_21_2.tap').read_bytes();blocks=split(tap);old=split(base)
assert len(blocks)==28 and blocks[6:]==old[2:]
for i in range(0,len(blocks),2):
 h,d=blocks[i:i+2];assert len(h)==19 and h[0]==0 and d[0]==255 and h[1]==(0 if i==0 else 3)
 n,size,dest,extra=struct.unpack('<10sHHH',h[2:-1]);assert len(d)-2==size
 if i==0:assert dest==10 and extra==size
assert struct.unpack('<HHH',blocks[2][12:-1])==(len(blocks[3])-2,STUB_ADDR,0)
assert struct.unpack('<HHH',blocks[4][12:-1])==(6912,0x4000,0)
with zipfile.ZipFile(P/'PANTALLA_CARGA_ZX.zip') as z:assert blocks[5][1:-1]==z.read('escoria_sideral_carga.scr')
assert wrap(base)==tap
print('PASS: 28 physical TAP blocks, headers and checksums, original SCR, all 22 game blocks identical to rebuilt base')
src=(P/'test_cpu.py').read_text();ns={'__file__':str(P/'test_cpu.py')};exec(compile(src[:src.index('assert i==len(tap)')],str(P/'test_cpu.py'),'exec'),ns)
CPU,S,png=ns['CPU'],ns['S'],ns['png'];code,labels,_=stub();assert code==blocks[3][1:-1]
def reach(c,addr,limit=100000):
 for _ in range(limit):
  if c.pc==addr:return
  c.step()
 raise AssertionError((hex(addr),hex(c.pc)))
for name,key,joy in [('SPACE',16,255),('Kempston FIRE',0,16),('Kempston right + FIRE',0,17),('Kempston diagonal + FIRE',0,25),('Kempston upper bits set + FIRE',0,240)]:
 c=CPU();c.m[STUB_ADDR:STUB_ADDR+len(code)]=code;c.m[0x4000:0x5b00]=blocks[5][1:-1];screen=c.screen();c.ie=True;c.pc=STUB_ADDR;c.push(0x0100);saved_sp=c.sp+2;c.keys=key;c.joy=joy
 reach(c,labels['release']);assert len(c.audio_events)==121 and {v for _,v in c.audio_events}=={0,16} and c.audio_events[-1][1]==0
 assert 250000<c.audio_events[-1][0]<310000
 for _ in range(4):c.step();reach(c,labels['release'])
 c.keys=0;c.joy=255 if key else 0;reach(c,labels['press'])
 for _ in range(20):c.step();reach(c,labels['press'])
 assert c.screen()==screen and len(c.audio_events)==121
 c.keys=key;c.joy=joy;reach(c,labels['release_after']);c.step();reach(c,labels['release_after'])
 c.keys=0;c.joy=255 if key else 0;reach(c,0x0100);assert c.screen()==screen and c.sp==saved_sp and c.pair(0)==0 and c.ie
 print('PASS:',name,'one beep, held input rejected, wait for fresh press/release, SCR unchanged, USR returns')
png(screen,'captura_carga.png')
# Run actual game dispatcher using the physical new tape, rather than the legacy fixture.
ns['blocks']=blocks;c=CPU();c.tape_pos=10;ns['start_from_title'](c)
for phase in range(2,6):
 c.pc=S['next_phase'];c.run_to('loop');assert c.v('phase')==phase and c.tape_pos==10+4*(phase-1)
c.pc=S['win'];c.run_to('wait_final');assert c.tape_pos==28 and c.screen()==(P/'final.scr').read_bytes()
print('PASS: five-phase dispatch and exact final SCR with new physical tape offsets (ROM transfer simulated)')
