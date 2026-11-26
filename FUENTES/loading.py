"""Transient pre-loader for Escoria 0.21. No changes to the resident game."""
from pathlib import Path
import struct, functools, zipfile
ROOT=Path(__file__).resolve().parent
STUB_ADDR=0x8000

def block(flag,p):
 b=bytes([flag])+p;return struct.pack('<H',len(b)+1)+b+bytes([functools.reduce(int.__xor__,b,0)])
def header(t,name,l,p1,p2):
 n=name.encode('ascii');assert len(n)<=10
 return block(0,bytes([t])+n.ljust(10,b' ')+struct.pack('<HHH',l,p1,p2))
def number(n):return str(n).encode()+bytes([14,0,0,n&255,n>>8,0])
def split(tap):
 i=0;out=[]
 while i<len(tap):
  assert i+2<=len(tap);n=struct.unpack_from('<H',tap,i)[0];assert n>=2 and i+2+n<=len(tap)
  b=tap[i+2:i+2+n];assert functools.reduce(int.__xor__,b)==0;out.append(b);i+=2+n
 assert i==len(tap);return out

def stub():
 b=bytearray();labels={};fix=[];asm=['org $8000']
 def label(n):labels[n]=STUB_ADDR+len(b);asm.append(n+':')
 def e(s,*v):asm.append('    '+s);b.extend(v)
 def j(s,op,n):e(s+' '+n,op);fix.append((len(b),n));b.extend(b'\0\0')
 label('start');e('ld b,120',0x06,120);e('xor a',0xaf)
 label('beep');e('xor 16',0xee,16);e('out ($fe),a',0xd3,0xfe);e('ld c,160',0x0e,160)
 label('tone_wait');e('dec c',0x0d);j('jp nz,',0xc2,'tone_wait');e('dec b',0x05);j('jp nz,',0xc2,'beep')
 e('xor a',0xaf);e('out ($fe),a',0xd3,0xfe)
 for name,op in [('release',0xc2),('press',0xca),('release_after',0xc2)]:
  label(name);e('halt',0x76);j('call',0xcd,'fire');j('jp nz,' if op==0xc2 else 'jp z,',op,name)
 e('ld bc,0',0x01,0,0);e('ret',0xc9)
 label('fire');e('ld bc,$7ffe',0x01,0xfe,0x7f);e('in a,(c)',0xed,0x78);e('bit 0,a',0xcb,0x47);j('jp z,',0xca,'pressed')
 e('ld bc,$001f',0x01,0x1f,0);e('in a,(c)',0xed,0x78);e('and 31',0xe6,31);e('ld d,a',0x57);e('and 3',0xe6,3);e('cp 3',0xfe,3);j('jp z,',0xca,'not_pressed');e('ld a,d',0x7a);e('and 12',0xe6,12);e('cp 12',0xfe,12);j('jp z,',0xca,'not_pressed');e('ld a,d',0x7a);e('bit 4,a',0xcb,0x67);e('ret',0xc9)
 label('pressed');e('ld a,1',0x3e,1);e('or a',0xb7);e('ret',0xc9)
 label('not_pressed');e('xor a',0xaf);e('ret',0xc9)
 for i,n in fix:struct.pack_into('<H',b,i,labels[n])
 return bytes(b),labels,'\n'.join(asm)+'\n'

def wrap(base,root=ROOT):
 old=split(base);assert len(old)==24 and old[0][1]==0
 O=struct.unpack_from('<H',old[2],14)[0];assert O==0x5f00
 code,labels,asm=stub();assert len(code)<256
 with zipfile.ZipFile(root/'PANTALLA_CARGA_ZX.zip') as z: scr=z.read('escoria_sideral_carga.scr')
 assert len(scr)==6912
 # LOAD transient CODE, then SCREEN$, wait in USR, then load unchanged core and first bank.
 load=bytes([0xef])+b'""'+bytes([0xaf]);screen=bytes([0xef])+b'""'+bytes([0xaa]);usr=lambda a:bytes([0xf9,0xc0])+number(a)
 line=b':'.join([bytes([0xe7])+number(0),bytes([0xfd])+number(O-1),load,screen,usr(STUB_ADDR),load,load,usr(O)])+b'\r'
 basic=struct.pack('>H',10)+struct.pack('<H',len(line))+line
 prefix=header(0,'ESCORIA',len(basic),10,len(basic))+block(255,basic)+header(3,'ESPERA',len(code),STUB_ADDR,0)+block(255,code)+header(3,'INTRO',len(scr),0x4000,0)+block(255,scr)
 offset=sum(2+len(x) for x in old[:2]);result=prefix+base[offset:]
 assert split(result)[6:]==old[2:]
 (root/'carga.scr').write_bytes(scr);(root/'espera.bin').write_bytes(code);(root/'espera.asm').write_text(asm)
 return result
if __name__=='__main__':
 (ROOT/'ESCORIA_SIDERAL_ALFA_21_2.tap').write_bytes(wrap((ROOT/'base_sin_carga.tap').read_bytes()))
