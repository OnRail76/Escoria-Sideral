#!/usr/bin/env python3
# ESCORIA SIDERAL - experimental horizontal profile, Z80 standard.
# Build from the approved asset ZIP; no external assembler dependencies.
from pathlib import Path
import zipfile, struct, json, sys, math, collections
from screen_codec import pack
ROOT=Path(__file__).resolve().parent
ASSET=Path(sys.argv[1]) if len(sys.argv)>1 else ROOT/'recursos.zip'
z=zipfile.ZipFile(ASSET)
ace=zipfile.ZipFile(ROOT/'ACE_WISCONSIN_V3.zip')
bosses=zipfile.ZipFile(ROOT/'BOSSES_TRAMADOS_FINAL.zip')
floors=zipfile.ZipFile(ROOT/'SUELOS_TRAMADOS.zip')
alien_floor=zipfile.ZipFile(ROOT/'SUELO_ALIEN_V3.zip')
backgrounds=zipfile.ZipFile(ROOT/'FONDOS_COMPLETOS.zip')
new_effects=bosses.read('efectos_comunes/effects.bin')
assert len(new_effects)==224
with zipfile.ZipFile(ROOT/'LUNA_ZX.zip') as moon:
 moon_bitmap=moon.read('luna_bitmap.bin');moon_attrs=moon.read('luna_atributos.bin')
assert len(moon_bitmap)==288 and len(moon_attrs)==36
ace_manifest=json.loads(ace.read('frames.json'))
ace_meta=ace_manifest['frames']
assert (ace_manifest['width'],ace_manifest['height'])==(32,32)
assert ace_manifest['anchor']==[16,31] and ace_manifest['muzzle']==[25,15]
assert [f['name'] for f in ace_meta]==[n for g in ['idle','walk','walk_fire','fire','jump','crouch','death'] for n in ace_manifest['groups'][g]]
assert all(f['offset']==128*i for i,f in enumerate(ace_meta))
assert len(ace_meta)==29 and all(f['index']==i for i,f in enumerate(ace_meta))
assert len(ace.read('sprites.bin'))==len(ace.read('masks.bin'))==29*128
def get(p):return z.read(p)
O=0x5f00; code=bytearray(); labels={}; fixes=[]; listing=[]; serial=0
def lab(n):
 assert n not in labels,n; labels[n]=O+len(code); listing.append(n+':')
def emit(s,*v):
 listing.append('    '+s);code.extend(v)
def word(x):
 if isinstance(x,str):fixes.append((len(code),x));code.extend(b'\0\0')
 else:code.extend(struct.pack('<H',x))
def w(s,op,x):emit(s,op);word(x)
def dw(x):listing.append('    dw '+str(x));word(x)
def data(b):
 code.extend(b)
 for i in range(0,len(b),24):listing.append('    db '+','.join('$%02x'%a for a in b[i:i+24]))
def tag(p='L'):
 global serial;serial+=1;return f'{p}_{serial}'
R={'b':0,'c':1,'d':2,'e':3,'h':4,'l':5,'(hl)':6,'a':7}; RR={'bc':0,'de':1,'hl':2,'sp':3}; CC={'nz':0,'z':1,'nc':2,'c':3}
def ld(a,b):
 if a in R and b in R:emit(f'ld {a},{b}',0x40+8*R[a]+R[b]);return
 if a in R and isinstance(b,int):emit(f'ld {a},{b}',6+8*R[a],b&255);return
 if a in RR:w(f'ld {a},{b}',1+16*RR[a],b);return
 raise ValueError((a,b))
def la(n):w(f'ld a,({n})',0x3a,n)
def sa(n):w(f'ld ({n}),a',0x32,n)
def sh(n):w(f'ld ({n}),hl',0x22,n)
def lh(n):w(f'ld hl,({n})',0x2a,n)
def jp(n,c=None):w('jp '+(c+',' if c else '')+n,0xc3 if c is None else 0xc2+CC[c]*8,n)
def call(n):w('call '+n,0xcd,n)
def ret(c=None):emit('ret'+(' '+c if c else ''),0xc9 if c is None else 0xc0+8*CC[c])
def alu(op,v):
 base={'add':0x80,'sub':0x90,'and':0xa0,'xor':0xa8,'or':0xb0,'cp':0xb8}[op];imm={'add':0xc6,'sub':0xd6,'and':0xe6,'xor':0xee,'or':0xf6,'cp':0xfe}[op]
 emit(f'{op} '+('a,' if op=='add' else '')+str(v),*( [base+R[v]] if isinstance(v,str) else [imm,v&255]))
def inc(r):emit('inc '+r,0x04+8*R[r] if r in R else 3+16*RR[r])
def dec(r):emit('dec '+r,0x05+8*R[r] if r in R else 0xb+16*RR[r])
def bit(n,r='a'):emit(f'bit {n},{r}',0xcb,0x40+8*n+R[r])
def addhl(r):emit('add hl,'+r,9+16*RR[r])
def push(r):emit('push '+r,0xc5+16*({'bc':0,'de':1,'hl':2,'af':3}[r]))
def pop(r):emit('pop '+r,0xc1+16*({'bc':0,'de':1,'hl':2,'af':3}[r]))
def setv(n,v):ld('a',v);sa(n)
def zero(n):alu('xor','a');sa(n)
def port(p):ld('bc',p);emit('in a,(c)',0xed,0x78)
def key(p,b,n):port(p);bit(b);jp(n,'z')
def branch_var(n,v,target,cond='z'):la(n);alu('cp',v);jp(target,cond)
def tick(n,delta):la(n);alu('add',delta);sa(n)
def addr(y,x=0):return 0x4000+((y&192)<<5)+((y&7)<<8)+((y&56)<<2)+x
# ROM BASIC loader leaves a valid IM1/FRAMES environment.
lab('start');emit('di',0xf3);ld('sp',0xfffe);emit('ld iy,$5c3a',0xfd,0x21,0x3a,0x5c);emit('im 1',0xed,0x56);alu('xor','a');emit('out ($fe),a',0xd3,0xfe);emit('ei',0xfb)
# Resident title, using the exact supplied ZX SCREEN$ logo. Wait for a fresh FIRE.
lab('title');zero('joy');zero('cheat');zero('cheat_steps');zero('cheat_down');zero('select_hold');setv('selected_phase',1);ld('hl','title_screen');call('unpack_screen');ld('hl','song_title');call('song_start')
lab('title_release');call('song_wait');call('input');la('keys');bit(4);jp('title_release','nz')
lab('title_press');call('song_wait');call('input');la('keys');bit(4);jp('title_fire','nz');branch_var('cheat',1,'title_select');la('keys');bit(2);jp('title_down','nz')
zero('cheat_down');jp('title_press')
lab('title_down');branch_var('cheat_down',1,'title_press');setv('cheat_down',1);branch_var('cheat_steps',2,'title_press');tick('cheat_steps',1);jp('title_press')
lab('title_fire');branch_var('cheat',1,'title_start_release');branch_var('cheat_steps',2,'title_start_release','nz');setv('cheat',1);zero('cheat_steps');ld('de','msg_cheat');ld('hl',addr(112,10));ld('b',8);call('msg_row');ld('hl',0x5800+14*32+10);ld('b',12);lab('cheat_attr');ld('(hl)',0x44);inc('hl');dec('b');jp('cheat_attr','nz');call('cheat_beep');zero('song_active');call('selector_draw')
lab('title_cheat_release');call('song_wait');call('input');la('keys');bit(4);jp('title_cheat_release','nz');jp('title_press')
lab('title_select');la('keys');alu('and',3);jp('selector_idle','z');ld('b','a');branch_var('select_hold',1,'title_press');setv('select_hold',1);ld('a','b');bit(0);jp('selector_right','nz');branch_var('selected_phase',1,'selector_wrap_left');tick('selected_phase',-1);jp('selector_changed');lab('selector_wrap_left');setv('selected_phase',5);jp('selector_changed');lab('selector_right');branch_var('selected_phase',5,'selector_wrap_right');tick('selected_phase',1);jp('selector_changed');lab('selector_wrap_right');setv('selected_phase',1);lab('selector_changed');call('selector_draw');jp('title_press');lab('selector_idle');zero('select_hold');jp('title_press')
lab('selector_draw');ld('de','msg_select');ld('hl',addr(120,10));ld('b',8);call('msg_row');ld('hl',0x5800+15*32+10);ld('b',12);lab('selector_attr');ld('(hl)',0x46);inc('hl');dec('b');jp('selector_attr','nz');la('selected_phase');call('digit_ptr');ld('hl',addr(120,21));jp('draw_1_8')
lab('cheat_beep');ld('b',120);alu('xor','a');lab('cheat_tone');alu('xor',16);emit('out ($fe),a',0xd3,0xfe);ld('c',160);lab('cheat_tone_wait');dec('c');jp('cheat_tone_wait','nz');dec('b');jp('cheat_tone','nz');alu('xor','a');emit('out ($fe),a',0xd3,0xfe);ret()
lab('title_start_release');call('select_control_wait');call('input');la('keys');bit(4);jp('title_start_release','nz');jp('restart')
# Shared LZ screen decoder, writes exactly 6912 bytes; no scratch framebuffer.
lab('unpack_screen');ld('de',0x4000)
lab('unpack_next');ld('a','(hl)');inc('hl');alu('or','a');ret('z');bit(7);jp('unpack_match','nz');ld('c','a');ld('b',0);emit('ldir',0xed,0xb0);jp('unpack_next')
lab('unpack_match');alu('cp',255);jp('unpack_long','z');ld('c','a');alu('and',7);ld('b','a');ld('a','c');emit('rrca',0x0f);emit('rrca',0x0f);emit('rrca',0x0f);alu('and',15);alu('add',3);ld('c','(hl)');inc('hl');jp('unpack_copy')
lab('unpack_long');ld('a','(hl)');inc('hl');ld('c','(hl)');inc('hl');ld('b','(hl)');inc('hl')
lab('unpack_copy');push('hl');ld('h','d');ld('l','e');alu('or','a');emit('sbc hl,bc',0xed,0x42);ld('c','a');ld('b',0);emit('ldir',0xed,0xb0);pop('hl');jp('unpack_next')
lab('restart');branch_var('phase',1,'restart_screen');ld('de','msg_rewind');call('show_message');call('load_phase1');setv('phase',1)
lab('restart_screen');call('clear_vars');setv('lives',3);setv('bonus_left',100);branch_var('selected_phase',1,'restart_road');la('selected_phase');jp('load_selected');lab('restart_road');ld('hl','initial_screen');call('unpack_screen');call('moon_draw');jp('init_stage')
lab('clear_vars');la('joy');push('af')
# Reset resident mutable variables without modifying assets.
ld('hl','vars');ld('de','vars_plus1');ld('bc','vars_size');ld('(hl)',0);emit('ldir',0xed,0xb0);pop('af');sa('joy');ret()
lab('init_stage')
for n,v in [('px',80),('py',112),('pose',0),('boss_hp',16),('jump',255),('spawn_delay',8),('hdelay',100),('rng',173),('rng_hi',167)]:setv(n,v)
ld('hl','hp_by_phase');call('phase_value');sa('boss_hp');lab('init_hp_done')
call('ground_render');call('hud');call('shadow_init');call('render_begin');call('draw_all');call('publish');la(0x5c78);sa('last');sa('inv_last');alu('or',1);sa('rng')
lab('loop');call('sync');call('render_begin');call('erase_all');call('input');call('update');call('draw_all');call('publish');call('ground');call('hud_if_dirty');branch_var('death',0,'loop','nz');branch_var('lives',0,'gameover');ld('hl','death_by_phase');call('phase_value');ld('b','a');la('boss_end');alu('cp','b');jp('win','nc');jp('loop')
# FRAMES sync: >=2 interrupts since previous update; 25 Hz target.
lab('next_phase');la('phase');inc('a');lab('load_selected')
for phase in (2,3,4,5):
 alu('cp',phase);jp(f'next_phase{phase}','z')
jp('title')
for phase,screen in [(2,'city'),(3,'lab'),(4,'ultra'),(5,'alien')]:
 lab(f'next_phase{phase}');ld('de','msg_load2');call('show_message');ld('a',phase);call('digit_ptr');ld('hl',addr(56,21));call('draw_1_8');call(f'load_phase{phase}');call(f'load_{screen}_screen');setv('phase',phase);jp('phase_loaded')
lab('phase_loaded')
for n in ['lives','bonus_left']+[f'score{i}' for i in range(5)]:la(n);push('af')
call('clear_vars')
for n in reversed(['lives','bonus_left']+[f'score{i}' for i in range(5)]):pop('af');sa(n)
jp('init_stage')
# Standard ROM LD_BYTES with named CODE headers and validated destination/size.
# On rewind, skip unrelated headers; no write until the expected header is seen.
for name,first,dest,size in [('load_phase1',ord('R'),'phase_bank','phase_size'),('load_phase2',ord('B'),'phase_bank','phase_size'),('load_city_screen',ord('P'),0x4000,6912),('load_phase3',ord('L'),'phase_bank','phase_size'),('load_lab_screen',ord('T'),0x4000,6912),('load_phase4',ord('U'),'phase_bank','phase_size'),('load_ultra_screen',ord('C'),0x4000,6912),('load_phase5',ord('A'),'phase_bank','phase_size'),('load_alien_screen',ord('Q'),0x4000,6912),('load_final_screen',ord('F'),0x4000,6912)]:
 lab(name);setv('load_id',first);ld('hl',dest);sh('load_dest');ld('hl',size);sh('load_len');jp('load_named')
lab('load_named');emit('ld ix,header_buf',0xdd,0x21);word('header_buf');ld('de',17);alu('xor','a');emit('scf',0x37);call('rom_load_safe');jp('load_named','nc')
la('header_buf');alu('cp',3);jp('load_named','nz');la('load_id');ld('b','a');la('header_name');alu('cp','b');jp('load_named','nz')
# Compare declared size and destination to expected. SBC clears carry first.
for h,v in [('header_len','load_len'),('header_dest','load_dest')]:
 lh(v);emit('ex de,hl',0xeb);lh(h);alu('or','a');emit('sbc hl,de',0xed,0x52);jp('load_named','nz')
lab('load_payload');emit('ld ix,(load_dest)',0xdd,0x2a);word('load_dest');emit('ld de,(load_len)',0xed,0x5b);word('load_len');ld('a',255);emit('scf',0x37);call('rom_load_safe');jp('load_named','nc');emit('ld iy,$5c3a',0xfd,0x21,0x3a,0x5c);emit('im 1',0xed,0x56);emit('ei',0xfb);alu('xor','a');emit('out ($fe),a',0xd3,0xfe);ret()
lab('phase_value');la('phase');dec('a');ld('e','a');ld('d',0);addhl('de');ld('a','(hl)');ret()
lab('sync');la('sound');alu('or','a');jp('sync_wait','z');call('audio_game');la('last');ld('b','a');la(0x5c78);alu('sub','b');alu('cp',2);jp('sync_done','nc');ld('a','e');call('audio_play');lab('sync_wait');la('last');ld('b','a');la(0x5c78);alu('sub','b');alu('cp',2);jp('sync_done','nc');call('audio_wait');jp('sync_wait');lab('sync_done');la(0x5c78);sa('last');ret()
# Input bits 0 R,1 L,2 down,3 up,4 fire. Keyboard always read.
# joy: 0 = title/unselected; 1 = Kempston selected; 2 = keyboard only.
lab('input');zero('keys');zero('joy_source');call('keyboard');jp('input_joy')
assert O+len(code)<=0x63f6
data(bytes(0x63f6-(O+len(code))))
lab('keyboard')
for p,b,m in [(0xdffe,0,1),(0xdffe,1,2),(0xfdfe,0,4),(0xfbfe,0,8),(0x7ffe,0,16)]:
 n=tag();port(p);bit(b);jp(n,'nz');la('keys');alu('or',m);sa('keys');lab(n)
ret()
# Collision: A vs B, C threshold; absolute unsigned difference < C.
lab('near');alu('sub','b');jp('near_pos','nc');emit('neg',0xed,0x44);lab('near_pos');alu('cp','c');ret()
def near(a,b,t,fail):la(b);ld('b','a');la(a);ld('c',t);call('near');jp(fail,'nc')
def near_const(a,b,t,fail):ld('b',b);la(a);ld('c',t);call('near');jp(fail,'nc')
lab('update');tick('frame',1)
# Invulnerability in real ROM interrupt ticks (50 Hz), not game updates.
# Unsigned subtraction handles FRAMES low-byte wrap. Timer starts on respawn.
la('inv_last');ld('b','a');la(0x5c78);sa('inv_last');alu('sub','b');ld('b','a');la('inv');alu('sub','b');jp('inv_tick_ok','nc');alu('xor','a');lab('inv_tick_ok');sa('inv')
# Fire cooldown remains in simulation ticks.
skip=tag();la('cool');alu('or','a');jp(skip,'z');dec('a');sa('cool');lab(skip)
# Horizontal movement, right-facing only. Down disables movement on ground.
zero('advance');zero('moving');la('death');alu('or','a');jp('death_update','nz')
la('keys');bit(2);jp('movement_done','nz');bit(0);jp('move_left','z');la('boss');alu('or','a');jp('boss_walk','nz');la('px');alu('cp',80);jp('camera_walk','nc');lab('boss_walk');la('px');alu('cp',176);jp('movement_done','nc');tick('px',2);setv('moving',1);jp('movement_done');lab('camera_walk');setv('advance',1);setv('moving',1);jp('movement_done');lab('move_left');la('keys');bit(1);jp('movement_done','z');la('px');alu('cp',2);jp('movement_done','c');tick('px',-2);setv('moving',1);lab('movement_done')
la('moving');alu('or','a');jp('walkclock_done','z');tick('walkclock',1);branch_var('walkclock',18,'walkclock_reset');jp('walkclock_done');lab('walkclock_reset');zero('walkclock');lab('walkclock_done')
# Q jumps; no repeated jump until release. V3 does not shoot in mid-air.
la('keys');alu('and',8);jp('q_on','nz');zero('qheld');jp('jump_step');lab('q_on');la('qheld');alu('or','a');jp('jump_step','nz');setv('qheld',1);branch_var('jump',255,'jump_step','nz');zero('jump')
lab('jump_step');la('jump');alu('cp',255);jp('on_ground','z');ld('e','a');ld('d',0);ld('hl','jump_y');addhl('de');ld('a','(hl)');sa('py');tick('jump',1);branch_var('jump',22,'jump_finished');jp('select_pose');lab('jump_finished');setv('jump',255);lab('on_ground');setv('py',112)
# V3 pose state machine: reverse the six-frame gait in both synchronized banks.
lab('select_pose');setv('pose',0);branch_var('jump',255,'ground_pose');zero('crouch_clock');la('jump');ld('e','a');ld('d',0);ld('hl','jump_pose');addhl('de');ld('a','(hl)');sa('pose');jp('shots_update')
lab('ground_pose');la('keys');bit(2);jp('stand_up','z');la('crouch_clock');alu('cp',6);jp('crouch_pose','nc');inc('a');sa('crouch_clock');jp('crouch_pose')
lab('stand_up');la('crouch_clock');alu('or','a');jp('standing','z');dec('a');sa('crouch_clock');lab('crouch_pose');ld('e','a');ld('d',0);ld('hl','crouch_anim');addhl('de');ld('a','(hl)');sa('pose');jp('shots_update')
lab('standing');branch_var('moving',0,'stationary_pose');la('walkclock');ld('e','a');ld('d',0);ld('hl','walk_pose');addhl('de');ld('b','(hl)');la('keys');bit(4);ld('a','b');jp('walk_pose_ready','z');alu('add',6);lab('walk_pose_ready');sa('pose');jp('shoot')
lab('stationary_pose');la('keys');bit(4);jp('shots_update','z');la('frame');alu('and',7);ld('e','a');ld('d',0);ld('hl','action_anim');addhl('de');ld('a','(hl)');alu('add',13);sa('pose');jp('shoot')
lab('death_update');la('death');dec('a');sa('death');jp('death_respawn','z');ld('e','a');ld('d',0);ld('hl','death_pose');addhl('de');ld('a','(hl)');sa('pose');jp('shots_update');lab('death_respawn');setv('py',112);setv('jump',255);setv('pose',0);zero('crouch_clock');branch_var('lives',0,'shots_update');setv('inv',100);la(0x5c78);sa('inv_last');jp('shots_update')
# Three player shots, each independent, travel right only.
lab('shoot');la('keys');bit(4);jp('shots_update','z');branch_var('cool',0,'shots_update','nz')
for i in range(3):branch_var(f'b{i}on',0,f'fire{i}')
jp('shots_update')
for i in range(3):
 p=f'b{i}';lab(f'fire{i}');setv(p+'on',1);la('px');alu('add',25);alu('and',252);sa(p+'x');la('py');alu('add',15);sa(p+'y');zero(p+'diag');setv('cool',5);call('beep');jp('shots_update')
lab('shots_update')
for i in range(3):
 p=f'b{i}';off=tag();done=tag();branch_var(p+'on',0,done);la(p+'x');alu('cp',244);jp(off,'nc');alu('add',8);sa(p+'x');branch_var(p+'diag',0,done);la(p+'y');alu('cp',44);jp(off,'c');alu('sub',4);sa(p+'y');jp(done);lab(off);zero(p+'on');lab(done)
# 40 s nominal road section. One global spawn scheduler, four slots.
la('boss');alu('or','a');jp('boss_logic','nz');branch_var('advance',0,'no_progress');tick('distance_sub',1);branch_var('distance_sub',4,'distance_tick');jp('no_progress');lab('distance_tick');zero('distance_sub');tick('progress',1);branch_var('progress',250,'begin_boss');lab('no_progress')
# Wave director: group size 2-4, internal delay 7-14 ticks, rest 18-33.
# Active and dying slots bounded at four; never spawn atop an existing zombie.
call('random');la('spawn_delay');alu('or','a');jp('spawn_try','z');dec('a');sa('spawn_delay');jp('enemy_move')
lab('spawn_try');la('wave_left');alu('or','a');jp('wave_active','nz');lab('wave_size_roll');call('random');alu('and',3);alu('cp',3);jp('wave_size_roll','z');alu('add',2);sa('wave_left');lab('wave_active')
# Front-only director; never use the left edge, even if the front is blocked.
for i in range(4):
 p=f'e{i}';skip=tag();branch_var(p+'on',0,skip);la(p+'x');alu('cp',184);jp('enemy_move','nc');lab(skip)
zero('spawn_dir');lab('slot_search')
for i in range(4):branch_var(f'e{i}on',0,f'spawn{i}')
jp('enemy_move')
for i in range(4):
 p=f'e{i}';lab(f'spawn{i}');zero(p+'dir');setv(p+'x',216)
 call('random');alu('and',7);jp(f'spawn{i}_runner','z');lab(f'spawn{i}_slow');alu('and',1);alu('add',2);sa(p+'period');setv(p+'speed',2);jp(f'spawn{i}_ready');lab(f'spawn{i}_runner');setv(p+'period',1);setv(p+'speed',4);lab(f'spawn{i}_ready');setv(p+'wait',1);setv(p+'y',112);setv(p+'on',1);zero(p+'anim');zero(p+'death');zero(p+'species');la('phase');alu('cp',3);jp(f'spawn{i}_hp','c');lab(f'spawn{i}_species');call('random');alu('and',15);ld('b','a');ld('hl','species_by_phase');call('phase_value');alu('cp','b');jp(f'spawn{i}_hp','c');jp(f'spawn{i}_hp','z');setv(p+'species',1);branch_var(p+'period',1,f'spawn{i}_alien_runner');setv(p+'period',2);jp(f'spawn{i}_hp');lab(f'spawn{i}_alien_runner');setv(p+'speed',5)
 # Uniform rejection sampling 1..3; HP remains assigned until killed.
 lab(f'spawn{i}_hp');call('random');alu('and',3);alu('cp',3);jp(f'spawn{i}_hp','nc');inc('a');ld('b','a');la(p+'species');alu('add','b');sa(p+'hp');jp('wave_schedule')
lab('wave_schedule');la('wave_left');dec('a');sa('wave_left');jp('wave_rest','z');call('random');alu('and',7);alu('add',7);sa('spawn_delay');jp('enemy_move');lab('wave_rest');call('random');alu('and',15);alu('add',18);sa('spawn_delay');jp('enemy_move')
# Reuse original spawn area for environmental director; preserve every external routine address.
lab('haz_spawn');branch_var('death',0,'haz_defer','nz');zero('front_block')
# Avoid boxing Ace in against the left edge. Nearby enemies bias toward a forward trap.
for i in range(4):
 p=f'e{i}';skip=tag();branch_var(p+'on',1,skip,'nz');la('px');ld('b','a');la(p+'x');ld('c',48);call('near');jp(skip,'nc');setv('front_block',1);lab(skip)
branch_var('front_block',0,'haz_choose');la('px');alu('cp',24);jp('haz_defer','c')
lab('haz_choose');zero('htype');la('phase');alu('cp',3);jp('haz_pattern','c');call('random');alu('and',1);jp('haz_pattern','z');setv('htype',2)
lab('haz_pattern');branch_var('front_block',1,'haz_ahead');call('random');alu('and',3);alu('cp',2);jp('haz_ahead','nc');alu('or','a');jp('haz_center','z')
# Trailing-edge threat still intersects the current body; advance is the short escape.
la('px');alu('and',252);alu('add',12);alu('and',248);alu('sub',8);jp('haz_place','nc');alu('xor','a');jp('haz_place')
lab('haz_center');la('px');alu('and',252);alu('add',12);alu('and',248);jp('haz_place')
lab('haz_ahead');la('px');alu('and',252);alu('add',12);alu('and',248);ld('b','a');la('htype');alu('or','a');ld('a',40);jp('haz_ahead_add','z');ld('a',24);lab('haz_ahead_add');alu('add','b')
lab('haz_place');sa('hx');setv('hon',1);zero('hscroll');branch_var('htype',2,'lightning_start');setv('hy',40);ret()
lab('haz_defer');setv('hdelay',12);ret()
assert O+len(code)<=27574
data(bytes(27574-(O+len(code))))
lab('enemy_move')
for i in range(4):
 p=f'e{i}';end=tag();off=tag();contact=tag();left=tag();branch_var(p+'on',0,end);branch_var('advance',0,p+'_camera_done');branch_var(p+'dir',1,p+'_camera_done');la(p+'x');alu('sub',2);jp(off,'c');sa(p+'x');lab(p+'_camera_done');branch_var(p+'on',2,p+'_dying');la(p+'wait');dec('a');sa(p+'wait');jp(contact,'nz');la(p+'period');sa(p+'wait');la(p+'speed');ld('b','a');la(p+'dir');alu('or','a');jp(left,'z');la(p+'x');alu('cp',216);jp(off,'nc');alu('add','b');alu('cp',217);jp(off,'nc');sa(p+'x');jp(contact);lab(left);la(p+'x');alu('sub','b');jp(off,'c');sa(p+'x');lab(contact);branch_var(p+'period',1,p+'_animfast');tick(p+'anim',1);jp(p+'_animcheck');lab(p+'_animfast');tick(p+'anim',2);lab(p+'_animcheck');branch_var(p+'anim',24,p+'_animreset');jp(p+'_animdone');lab(p+'_animreset');zero(p+'anim');lab(p+'_animdone')
 # Body-only contact: align to drawn 4-pixel positions; Ace center +13, zombie +16.
 # Combined horizontal half-width 14; the projecting rifle is not lethal.
 la('px');alu('and',252);alu('add',13);ld('b','a');la(p+'x');alu('and',252);alu('add',16);ld('c',14);call('near');jp(end,'nc');near(p+'y','py',17,end);call('hurt');jp(end);lab(p+'_dying');la(p+'death');dec('a');sa(p+'death');jp(off,'z');jp(end);lab(off);zero(p+'on');lab(end)
# Projectiles vs active enemies.
for i in range(3):
 p=f'b{i}';end=tag();branch_var(p+'on',0,end)
 for j in range(4):
  e=f'e{j}';skip=tag();branch_var(e+'on',1,skip,'nz');la(e+'x');alu('add',16);ld('b','a');la(p+'x');ld('c',17);call('near');jp(skip,'nc');la(e+'y');alu('add',16);ld('b','a');la(p+'y');ld('c',15);call('near');jp(skip,'nc');zero(p+'on');la(e+'hp');alu('or','a');jp(skip+'_kill','z');dec('a');sa(e+'hp');jp(skip+'_kill','z');call('sfx_hit');jp(end);lab(skip+'_kill');setv(e+'on',2);setv(e+'death',24);call('sfx_kill');call('score_inc');jp(end);lab(skip)
 lab(end)
jp('hazard')
lab('begin_boss');setv('boss',1)
for i in range(4):zero(f'e{i}on')
zero('hon');setv('hdelay',25);setv('boss_delay',12);zero('boss_ready')
for i in range(3):zero(f'b{i}on')
lab('boss_logic');branch_var('boss_hp',0,'boss_dying');
# Keep player outside boss. Eye center (228,127), vulnerable except when closed.
la('px');alu('cp',176);jp('boss_pos_ok','c');setv('px',176);lab('boss_pos_ok')
for i in range(3):
 p=f'b{i}';skip=tag();branch_var(p+'on',0,skip);ld('hl','eye_by_phase');call('phase_value');ld('b','a');la(p+'x');alu('cp','b');jp(skip,'c');zero(p+'on');near_const(p+'y',127,5,skip);la('frame');alu('and',31);alu('cp',6);jp(skip,'c');branch_var('boss_ready',0,skip);branch_var('boss_hit',0,skip,'nz');branch_var('boss_hp',0,skip);tick('boss_hp',-1);setv('boss_hit',12);branch_var('boss_hp',0,skip+'_boss_dead');call('sfx_hit');jp(skip+'_boss_score');lab(skip+'_boss_dead');call('sfx_bossdead');lab(skip+'_boss_score');call('score_inc');lab(skip)
la('phase');alu('cp',3);jp('mago_hazard','nc');call('boss_attack');ret();lab('mago_hazard');branch_var('hon',0,'mago_shoot');branch_var('boss_hit',0,'mago_hazard_tick');tick('boss_hit',-1);lab('mago_hazard_tick');call('hazard');ret();lab('mago_shoot');call('boss_attack');ret();lab('boss_dying');zero('bon');zero('hon');tick('boss_end',1);alu('and',3);ret('nz');jp('sfx_bossdead')
# Environmental director. One hazard at a time. Road attacks are anchored to the
# world, moving left one byte per four camera advances; never retarget Ace.
lab('hazard');branch_var('hon',0,'haz_active','nz');la('hdelay');alu('or','a');jp('haz_spawn','z');dec('a');sa('hdelay');ret()
lab('haz_active');branch_var('boss',1,'haz_motion_done');branch_var('advance',0,'haz_motion_done');tick('hscroll',1);alu('cp',4);jp('haz_motion_done','c');zero('hscroll');la('hx');alu('sub',8);jp('haz_off','c');sa('hx');lab('haz_motion_done');la('htype');alu('cp',2);jp('lightning_warning','z');alu('cp',3);jp('lightning_strike','z');branch_var('htype',0,'haz_fall');la('hboom');dec('a');sa('hboom');jp('haz_off','z');ret();lab('haz_fall');la('hy');alu('cp',128);jp('haz_impact','nc');alu('add',3);alu('cp',129);jp('haz_impact','nc');sa('hy');la('px');alu('and',252);alu('add',13);ld('b','a');la('hx');alu('add',4);ld('c',10);call('near');jp('haz_done','nc');la('py');alu('add',16);ld('b','a');la('hy');alu('add',8);ld('c',19);call('near');jp('haz_done','nc');call('hurt');lab('haz_done');ret();lab('haz_impact');setv('htype',1);setv('hboom',12);setv('hy',128);jp('sfx_meteor')
# ROM LD_BYTES tests SPACE as BREAK. Preserve the entire call contract,
# wait for keyboard release before EVERY header and payload transfer.
lab('rom_load_safe');push('af');push('bc');ld('bc',0x7ffe)
lab('rom_wait_space');emit('in a,(c)',0xed,0x78);bit(0);jp('rom_wait_space','z');pop('bc');pop('af');w('jp $0556',0xc3,0x0556)
assert O+len(code)<=0x7588
data(bytes(0x7588-(O+len(code))))
lab('haz_off');zero('hon');call('random');alu('and',31);ld('b','a');la('boss');alu('or','a');ld('a',72);jp('haz_delay','z');ld('a',18);lab('haz_delay');alu('add','b');sa('hdelay');ret()
# Lightning: warning for 14 updates, strike 4 updates. One hazard slot.
assert O+len(code)<=30114
data(bytes(30114-(O+len(code))))
lab('lightning_start');setv('hon',1);setv('htype',2);setv('hy',64);setv('hboom',14);la('hx');alu('cp',200);ret('c');setv('hx',192);ret()
lab('lightning_warning');tick('hboom',-1);ret('nz');setv('htype',3);setv('hboom',4);call('sfx_lightning');jp('lightning_contact')
lab('lightning_strike');tick('hboom',-1);jp('lightning_off','z');lab('lightning_contact');la('px');alu('and',252);alu('add',13);ld('b','a');la('hx');alu('add',4);ld('c',10);call('near');ret('nc');call('hurt');ret()
lab('lightning_off');call('haz_off');branch_var('boss',0,'lightning_done');setv('boss_delay',24);branch_var('phase',5,'lightning_done','nz');setv('boss_delay',14);lab('lightning_done');ret()
# Horizontal boss fire. High lane passes over crouched Ace; low lane must be jumped.
lab('boss_attack');la('boss_hit');alu('or','a');jp('boss_nohit','z');dec('a');sa('boss_hit');lab('boss_nohit');branch_var('bon',0,'boss_fire_active','nz');la('boss_delay');alu('or','a');jp('boss_fire_spawn','z');dec('a');sa('boss_delay');ret();lab('boss_fire_spawn');la('phase');alu('cp',3);jp('mago_choose','nc');jp('boss_horizontal');lab('mago_choose');branch_var('boss_ready',0,'boss_horizontal');call('random');alu('and',3);jp('boss_horizontal','nz');la('px');alu('and',252);alu('add',12);alu('and',248);alu('cp',200);jp('boss_target_ok','c');ld('a',192);lab('boss_target_ok');sa('hx');branch_var('phase',4,'boss_meteor');branch_var('phase',3,'lightning_start');call('random');alu('and',1);jp('lightning_start','z');lab('boss_meteor');setv('hon',1);zero('htype');setv('hy',40);setv('boss_delay',18);ret();lab('boss_horizontal');setv('boss_ready',1);setv('bon',1);setv('bx',192);la('lane');alu('xor',1);sa('lane');alu('or','a');ld('a',136);jp('boss_fire_y','z');ld('a',112);lab('boss_fire_y');sa('by');jp('sfx_bossfire')
lab('boss_fire_active');ld('hl','speed_by_phase');call('phase_value');ld('b','a');la('bx');alu('sub','b');jp('boss_fire_off','c');sa('bx');la('px');alu('and',252);alu('add',13);ld('b','a');la('bx');alu('add',8);ld('c',16);call('near');ret('nc');# Collision uses vertical body bounds, not only the head or legs.
la('py');alu('add',31);ld('b','a');la('by');alu('cp','b');jp('boss_fire_safe','nc');la('py');alu('add',7);ld('b','a');la('keys');bit(2);jp('boss_body_top','z');branch_var('jump',255,'boss_body_top','nz');la('py');alu('add',16);ld('b','a');lab('boss_body_top');la('by');alu('add',7);alu('cp','b');jp('boss_fire_safe','c');call('hurt');jp('boss_fire_off');lab('boss_fire_safe');ret();lab('boss_fire_off');zero('bon');setv('boss_delay',18);branch_var('phase',1,'boss_delay_done');la('boss_burst');alu('or','a');jp('boss_new_burst','z');dec('a');sa('boss_burst');jp('boss_new_burst','z');setv('boss_delay',4);branch_var('phase',5,'boss_delay_done','nz');setv('boss_delay',3);ret();lab('boss_new_burst');call('random');alu('and',1);alu('add',2);ld('b','a');branch_var('phase',5,'boss_burst_store','nz');inc('b');lab('boss_burst_store');ld('a','b');sa('boss_burst');setv('boss_delay',30);branch_var('phase',5,'boss_delay_done','nz');setv('boss_delay',20);lab('boss_delay_done');ret()
# 16-bit maximal-period Galois LFSR (0xB400), mixed byte for the director.
lab('random');
for _ in range(7):call('rng_step')
lab('rng_step');la('rng_hi');ld('b','a');emit('rrca',0x0f);alu('and',127);ld('c','a');la('rng');emit('rrca',0x0f);jp('rng_even','nc');ld('d',1);jp('rng_low');lab('rng_even');ld('d',0);lab('rng_low');alu('and',127);ld('e','a');ld('a','b');alu('and',1);jp('rng_no_carry','z');ld('a','e');alu('or',128);ld('e','a');lab('rng_no_carry');ld('a','e');sa('rng');ld('a','d');alu('or','a');ld('a','c');jp('rng_high','z');alu('xor',0xb4);lab('rng_high');sa('rng_hi');alu('xor','e');ret()
lab('hurt');branch_var('cheat',1,'hurt_done');branch_var('death',0,'hurt_done','nz');branch_var('inv',0,'hurt_done','nz');la('lives');alu('or','a');jp('hurt_done','z');dec('a');sa('lives');setv('death',24);setv('pose',23);setv('py',112);setv('jump',255);call('sfx_death');lab('hurt_done');ret()
# Priority beeper events; audio runs only during the old HALT wait, not drawing.
# Upper nibble priority, lower nibble IRQs remaining. Separate audio noise state.
for n,value in [('beep',0x12),('sfx_hit',0x22),('sfx_kill',0x34),('sfx_bossfire',0x43),('sfx_meteor',0x55),('sfx_lightning',0x66),('sfx_bonus',0x78),('sfx_death',0x8c),('sfx_bossdead',0x9f)]:
 lab(n);ld('a',value);
 if n=='sfx_bossdead':sa('sound');ret()
 else:jp('audio_request')
lab('audio_request');push('bc');ld('b','a');alu('and',240);ld('c','a');la('sound');alu('and',240);alu('cp','c');jp('audio_keep','nc');ld('a','b');sa('sound');lab('audio_keep');pop('bc');ret()
lab('audio_wait');la('sound');alu('or','a');jp('audio_halt','z');call('audio_take');jp('audio_play');lab('audio_take');ld('b','a');alu('and',15);dec('a');jp('audio_last','z');ld('a','b');dec('a');sa('sound');jp('audio_pitch');lab('audio_last');zero('sound')
lab('audio_pitch');ld('a','b');alu('and',240)
for _ in range(4):emit('rrca',0x0f)
ld('e','a');ld('d',0);ld('hl','sfx_pitches');addhl('de');ld('a','b');alu('and',15);ld('b','a');ld('a',15);alu('sub','b');alu('add','(hl)');ld('c','a');la('boss_end');alu('or','a');ld('a','c');ret('z');bit(7,'a');ret('z');la('boss_end');alu('and',12);alu('add','a');alu('add',0x98);ret()
# Original short arcade melodies, one pass on each screen. Each pair = ticks,pitch.
lab('song_start');sh('song_ptr');zero('song_left');setv('song_active',1);ret()
lab('song_wait');push('bc');la('song_active');alu('or','a');jp('song_silent','z');la('song_left');alu('or','a');jp('song_note','nz');lh('song_ptr');ld('a','(hl)');inc('hl');alu('or','a');jp('song_stop','z');sa('song_left');ld('a','(hl)');inc('hl');sa('song_pitch');sh('song_ptr');lab('song_note');tick('song_left',-1);la('song_pitch');alu('or','a');jp('song_silent','z');call('audio_play');pop('bc');ret()
lab('song_stop');zero('song_active');lab('song_silent');emit('halt',0x76);pop('bc');ret()
# A = pitch (bit 7 noise); poll FRAMES each inner delay iteration; no IRQ/vector changes.
# Exits at next IRQ, leaves speaker off and black border. Normal stack only.
lab('audio_play');ld('e','a');la(0x5c78);ld('d','a');ld('h',0);la('audio_seed');ld('l','a')
lab('audio_edge');ld('a','e');alu('and',127);ld('c','a');bit(7,'e');jp('audio_toggle','z');ld('a','l');emit('rrca',0x0f);jp('audio_noise_even','nc');alu('xor',0xb8);lab('audio_noise_even');ld('l','a');alu('and',15);alu('add','c');ld('c','a');lab('audio_toggle');ld('a','h');alu('xor',16);ld('h','a');emit('out ($fe),a',0xd3,0xfe)
lab('audio_poll');la(0x5c78);alu('cp','d');jp('audio_done','nz');dec('c');jp('audio_poll','nz');jp('audio_edge')
lab('audio_done');ld('a','l');sa('audio_seed');alu('xor','a');emit('out ($fe),a',0xd3,0xfe);ret();lab('audio_halt');emit('halt',0x76);ret()
# Bounded gameplay slice, independent of the number of IRQs already spent drawing.
# 176 delay iterations at ~40 T + edge overhead; no IRQ disabling, no writes to VRAM.
lab('audio_game');call('audio_take');ld('e','a');ld('h',0);la('audio_seed');ld('l','a');ld('b',176)
lab('audio_game_edge');ld('a','e');alu('and',127);ld('c','a');bit(7,'e');jp('audio_game_toggle','z');ld('a','l');emit('rrca',0x0f);jp('audio_game_even','nc');alu('xor',0xb8);lab('audio_game_even');ld('l','a');alu('and',15);alu('add','c');ld('c','a')
lab('audio_game_toggle');ld('a','h');alu('xor',16);ld('h','a');emit('out ($fe),a',0xd3,0xfe)
lab('audio_game_poll');dec('b');jp('audio_done','z');emit('nop',0);emit('nop',0);emit('nop',0);dec('c');jp('audio_game_poll','nz');jp('audio_game_edge')
lab('sfx_pitches');data(bytes([0,0x88,7,0x9b,0x90,0xa8,0x83,24,0xab,0xb0]))
lab('audio_seed');data(b'\xa7');lab('song_ptr');data(b'\0\0');lab('song_left');data(b'\0');lab('song_pitch');data(b'\0');lab('song_active');data(b'\0')
# Small original minor-key title motif; pitch approx by 41T polling loop.
def song(n,notes):
 lab(n);data(bytes(v for ticks,midi in notes for v in (ticks,0 if midi is None else max(1,min(127,round((3500000/(440*2**((midi-69)/12))/2-90)/41)))) )+b'\0')
song('song_title',[(7,72),(7,75),(7,72),(7,78),(10,77),(5,None),(7,72),(7,75),(7,79),(7,78),(18,72),(5,None),(7,67),(7,70),(7,72),(7,75),(7,74),(20,72)])
song('song_over',[(12,72),(12,70),(12,67),(28,63)])
song('song_win',[(7,72),(7,75),(7,79),(7,84),(7,82),(24,84)])
# Five decimal digits plus fixed trailing zero: +10 points per score event.
# One bonus after 100 score events (1000 points), then every 150 (1500).
# Countdown is reset only on a new game; can survive future phase loads.
lab('score_inc');ld('hl','score');ld('b',5);lab('score_loop');inc('(hl)');ld('a','(hl)');alu('cp',10);jp('score_bonus','c');ld('(hl)',0);inc('hl');dec('b');jp('score_loop','nz')
lab('score_bonus');la('bonus_left');dec('a');sa('bonus_left');ret('nz');setv('bonus_left',150);la('lives');alu('cp',99);ret('nc');inc('a');sa('lives');jp('sfx_bonus')
# Screen address from x in A (pixel), y in C; HL return.
lab('screen_addr');emit('rrca',0x0f);emit('rrca',0x0f);emit('rrca',0x0f);alu('and',31);ld('b','a');la('shadow_mode');alu('or','a');jp('screen_addr_real','z');ld('a','c');alu('sub',40);ld('l','a');ld('h',0)
for _ in range(5):addhl('hl')
ld('a','l');alu('or','b');ld('l','a');push('de');ld('de','shadow');addhl('de');pop('de');ret()
lab('screen_addr_real');ld('a','c');alu('and',0x38);emit('rlca',0x07);emit('rlca',0x07);alu('or','b');ld('l','a');ld('a','c');alu('and',0xc0);emit('rrca',0x0f);emit('rrca',0x0f);emit('rrca',0x0f);alu('or',0x40);ld('h','a');ld('a','c');alu('and',7);alu('or','h');ld('h','a');ret()
# Shadow rows are linear, 32 bytes per scanline, one 256-byte page per character band.
lab('nextrow');bit(7,'h');jp('shadow_nextrow','nz');inc('h');ld('a','h');alu('and',7);ret('nz');ld('a','l');alu('add',32);ld('l','a');ret('c');ld('a','h');alu('sub',8);ld('h','a');ret()
lab('shadow_nextrow');ld('a','l');alu('add',32);ld('l','a');ret('nc');inc('h');ret()
# Each rectangle marks only touched byte columns per 8-row band; publish a coherent image,
# never the erase pass. HL points at shadow pixel byte, A=width, B=height.
lab('mark_dirty');bit(7,'h');ret('z');push('af');push('bc');push('de');push('hl');ld('c','a');ld('a','l');alu('and',31);ld('e','a');alu('add','c');ld('d','a');ld('a','l');alu('and',224)
for _ in range(5):emit('rrca',0x0f)
alu('add','b');dec('a')
for _ in range(3):emit('rrca',0x0f)
alu('and',31);inc('a');push('af');ld('a','h');emit('db $d6 ; SUB n',0xd6);lab('mark_shadow_hi');data(b'\0');alu('add','a');ld('c','a');ld('b',0);ld('hl','dirty');addhl('bc');pop('af');ld('b','a')
lab('mark_band');ld('a','e');alu('cp','(hl)');jp('mark_min_done','nc');ld('(hl)','a');lab('mark_min_done');inc('hl');ld('a','d');alu('cp','(hl)');jp('mark_max_done','c');ld('(hl)','a');lab('mark_max_done');inc('hl');dec('b');jp('mark_band','nz');pop('hl');pop('de');pop('bc');pop('af');ret()
lab('render_begin');ld('hl','used_cols');ld('(hl)',0);ld('de','used_cols_plus1');ld('bc',31);emit('ldir',0xed,0xb0);setv('shadow_mode',1);ld('hl','shadow_nextrow');sh('sparse_nextrow_ptr');ld('hl','dirty');ld('de','old_dirty');ld('bc',26);emit('ldir',0xed,0xb0);call('reset_dirty');ret()
lab('reset_dirty');ld('hl','dirty');ld('(hl)',32);inc('hl');ld('(hl)',0);ld('hl','dirty');ld('de','dirty_plus2');ld('bc',24);emit('ldir',0xed,0xb0);ret()
lab('shadow_init');zero('shadow_mode');call('reset_dirty');ld('hl','shadow');ld('(hl)',0);ld('de','shadow_plus1');ld('bc',3327);emit('ldir',0xed,0xb0);ld('hl',addr(40));ld('de','shadow');ld('a',24)
lab('shadow_init_row');push('af');push('hl');call('copy32');pop('hl');call('nextrow');pop('af');dec('a');jp('shadow_init_row','nz');ret()
lab('clear_shadow');ld('hl','old_dirty_ground');ld('b',10);emit('db $0e ; LD C,n',0x0e);lab('clear_shadow_hi');data(b'\0')
lab('clear_shadow_loop');push('bc');ld('a','(hl)');inc('hl');ld('e','a');ld('a','(hl)');inc('hl');alu('sub','e');jp('clear_shadow_skip','c');jp('clear_shadow_skip','z');push('hl');ld('l','e');ld('h','c');call('clear_band');pop('hl');lab('clear_shadow_skip');pop('bc');inc('c');dec('b');jp('clear_shadow_loop','nz');ret()
# clear width A at HL, eight rows, faster than rectangle erase with row addressing.
lab('clear_band');push('hl');ld('b','a');ld('a',32);alu('sub','b');alu('add','a');ld('e','a');ld('d',0);ld('hl','clear32');addhl('de');sh('clear_call_ptr');pop('hl');ld('b',8);alu('xor','a')
lab('clear_band_row');push('hl');emit('db $cd ; CALL nn',0xcd);lab('clear_call_ptr');dw(0);pop('hl');ld('a','l');alu('add',32);ld('l','a');alu('xor','a');dec('b');jp('clear_band_row','nz');ret()
lab('clear32')
for _ in range(32):ld('(hl)','a');inc('l')
ret()
# Publish union of previous and current rectangles; keep current map for next frame.
lab('publish');zero('shadow_mode');ld('hl','nextrow');sh('sparse_nextrow_ptr');ld('hl','dirty');ld('de','old_dirty');ld('b',13);ld('c',40)
lab('publish_loop');push('bc');emit('ld a,(de)',0x1a);alu('cp','(hl)');jp('pub_min_ok','c');ld('a','(hl)');lab('pub_min_ok');ld('b','a');inc('hl');inc('de');emit('ld a,(de)',0x1a);alu('cp','(hl)');jp('pub_max_ok','nc');ld('a','(hl)');lab('pub_max_ok');inc('hl');inc('de');alu('sub','b');jp('publish_skip','c');jp('publish_skip','z');push('hl');push('de');push('af');ld('a','b')
for _ in range(3):emit('rlca',0x07)
call('screen_addr');emit('ex de,hl',0xeb);ld('a','c');alu('sub',40)
for _ in range(3):emit('rrca',0x0f)
emit('db $c6 ; ADD A,n',0xc6);lab('pub_shadow_hi');data(b'\0');ld('h','a');ld('a','e');alu('and',31);ld('l','a');pop('af');call('publish_band');pop('de');pop('hl')
lab('publish_skip');pop('bc');ld('a','c');alu('add',8);ld('c','a');dec('b');jp('publish_loop','nz');ret()
lab('publish_band');sa('pub_width');push('hl');push('de');ld('b','a');ld('a',32);alu('sub','b');alu('add','a');ld('e','a');ld('d',0);ld('hl','copy32');addhl('de');sh('pub_copy_ptr');pop('de');pop('hl');ld('a',8)
lab('pub_row');push('af');ld('bc',32);emit('db $cd ; CALL nn',0xcd);lab('pub_copy_ptr');dw(0);addhl('bc');ld('a','e');emit('db $d6 ; SUB n',0xd6);lab('pub_width');data(b'\0');ld('e','a');jp('pub_row_skip_inc','c');inc('d');lab('pub_row_skip_inc');pop('af');dec('a');jp('pub_row','nz');ret()
lab('copy32')
for _ in range(32):emit('ldi',0xed,0xa0)
ret()
# Unrolled row transfers. For the playfield, the background is black below y=40.
# Masked composition, all previous rectangles restored before any actor drawn.
for width,height in [(5,32),(1,4),(1,16),(2,8),(2,16),(6,64),(6,48),(1,8)]:
 for mode in ['erase','draw']:
  if ((width,height) in [(1,8),(6,48)] and mode=='erase') or ((width,height)==(5,32) and mode=='draw'):continue
  name=f'{mode}_{width}_{height}';lab(name);ld('b',height);ld('a',width);call('mark_dirty');lab(name+'_row')
  for k in range(width):
   if mode=='erase':ld('(hl)',0)
   elif (width,height) in [(4,32),(5,32)]:emit('ld a,(de)',0x1a);alu('and','(hl)');ld('c','a');inc('de');emit('ld a,(de)',0x1a);alu('or','c');ld('(hl)','a');inc('de')
   elif (width,height) in [(1,8),(6,64),(6,48)]:emit('ld a,(de)',0x1a);ld('(hl)','a');inc('de')
   else:emit('ld a,(de)',0x1a);alu('or','(hl)');ld('(hl)','a');inc('de')
   if k<width-1:inc('l')
  if width>1:ld('a','l');alu('sub',width-1);ld('l','a')
  call('nextrow');dec('b');jp(name+'_row','nz');ret()
# Fixed moon at the original demo position; restore only when a meteor crosses it.
lab('moon_draw');ld('hl',addr(16,23));ld('de','moon_bitmap');jp('draw_6_48')
# Restore only the intersected byte-column of the moon, at most 16 rows.
lab('moon_restore');la('hy');ld('c','a');la('hx');call('screen_addr');push('hl')
la('hy');alu('sub',16);ld('l','a');ld('h',0);addhl('hl');ld('d','h');ld('e','l');addhl('hl');addhl('de')
la('hx');emit('rrca',0x0f);emit('rrca',0x0f);emit('rrca',0x0f);alu('and',31);alu('sub',23);ld('e','a');ld('d',0);addhl('de');ld('de','moon_bitmap');addhl('de');emit('ex de,hl',0xeb);pop('hl')
la('hy');ld('b','a');ld('a',64);alu('sub','b');alu('cp',16);jp('moon_count','c');ld('a',16);lab('moon_count');ld('b','a');lab('moon_restore_row');emit('ld a,(de)',0x1a);ld('(hl)','a')
for _ in range(6):inc('de')
call('nextrow');dec('b');jp('moon_restore_row','nz');ret()
# Barcelona: restore only the byte column crossed by the meteor, y=40..63.
lab('city_restore');la('hy');ld('c','a');la('hx');call('screen_addr');push('hl');la('hy');alu('sub',40);ld('l','a');ld('h',0)
for _ in range(5):addhl('hl')
la('hx');emit('rrca',0x0f);emit('rrca',0x0f);emit('rrca',0x0f);alu('and',31);ld('e','a');ld('d',0);addhl('de');ld('de','moon_bitmap');addhl('de');emit('ex de,hl',0xeb);pop('hl');la('hy');ld('b','a');ld('a',64);alu('sub','b');alu('cp',16);jp('city_count','c');ld('a',16);lab('city_count');ld('b','a');lab('city_restore_row');emit('ld a,(de)',0x1a);ld('(hl)','a');push('hl');ld('hl',32);addhl('de');emit('ex de,hl',0xeb);pop('hl');call('nextrow');dec('b');jp('city_restore_row','nz');ret()
# Draw actor: A pixel x, C y, DE pointer to aligned frame pair (shift 0,4).
lab('actor_draw');push('af');call('screen_addr');ld('b',32);ld('a',5);call('mark_dirty');call('fast_select');pop('af');bit(2);jp('actor_ptr','z');inc('de');inc('de');lab('actor_ptr');push('hl');emit('ex de,hl',0xeb);ld('e','(hl)');inc('hl');ld('d','(hl)');pop('hl');ld('b',32)
lab('sparse_row');emit('ld a,(de)',0x1a);inc('de');alu('cp',48);jp('sparse_dict','nc');lab('sparse_code');emit('db $c6 ; ADD A,n',0xc6);lab('span_offset');data(b'\0');sa('sparse_patch');lab('sparse_dispatch');jp('sparse_table');labels['sparse_patch']=labels['sparse_dispatch']+1;listing.append('sparse_patch equ sparse_dispatch+1')
lab('sparse_next');bit(7,'b');jp('sparse_advance','z');pop('de');ld('a','b');alu('and',127);ld('b','a');lab('sparse_advance');emit('db $cd ; CALL nn',0xcd);lab('sparse_nextrow_ptr');dw('nextrow');dec('b');jp('sparse_row','nz');ret()
lab('sparse_dict');push('de');push('hl');ld('l','a');ld('h',0);addhl('hl');ld('de','row_dict_base');addhl('de');ld('e','(hl)');inc('hl');ld('d','(hl)');pop('hl');ld('a','b');alu('or',128);ld('b','a');emit('ld a,(de)',0x1a);inc('de');jp('sparse_code')
# Shadow is black under all actors. If none of the previous actors intersects
# these columns, opaque/masked composition is exactly equivalent to bitmap write.
# Never use this fast path on real VRAM or in the boss room.
lab('fast_select');zero('span_offset');bit(7,'h');ret('z');branch_var('boss',0,'fast_check');ret()
lab('fast_check');push('hl');push('de');ld('a','l');alu('and',31);ld('e','a');ld('d',0);ld('hl','used_cols');addhl('de');alu('xor','a')
for i in range(5):
 alu('or','(hl)');ld('(hl)',1)
 if i<4:inc('l') # used_cols aligned to 32, so never cross page
jp('fast_done','nz');setv('span_offset',48);lab('fast_done');pop('de');pop('hl');ret()
# Dispatch table must remain in one page; only low operand of JP is patched.
spans=[None]+[(x0,x1) for x0 in range(5) for x1 in range(x0,5)]
# Use only the original sparse-dispatch alignment padding, never shift game code.
lab('input_joy');branch_var('joy',2,'input_done');port(0x001f);alu('cp',32);ret('nc');ld('d','a')
# Three agreeing full-byte samples; never mask undefined upper bits.
for _ in range(2):emit('in a,(c)',0xed,0x78);alu('cp','d');ret('nz')
ld('a','d');alu('and',3);alu('cp',3);ret('z');ld('a','d');alu('and',12);alu('cp',12);ret('z')
# SPACE wins the title selection if both sources press fire. The keyboard
# remains active even in joystick mode; all gameplay inputs are combined.
la('keys');bit(4);jp('input_merge','nz');bit(4,'d');jp('input_merge','z');setv('joy_source',1)
lab('input_merge');la('keys');alu('or','d');sa('keys');lab('input_done');ret()
lab('select_control_wait');la('joy');alu('or','a');jp('song_wait','nz');la('joy_source');alu('or','a');ld('a',2);jp('control_selected','z');ld('a',1);lab('control_selected');sa('joy');jp('song_wait')
lab('joy_source');data(b'\0')
assert O+len(code)<=0x7f00
data(bytes(0x7f00-(O+len(code))));lab('sparse_table')
for i,span in enumerate(spans):jp('sparse_next' if span is None else f'sparse_span{i}')
for i,span in enumerate(spans):jp('sparse_next' if span is None else f'fast_span{i}')
for i,span in enumerate(spans):
 if span is None:continue
 x0,x1=span;lab(f'sparse_span{i}')
 for _ in range(x0):inc('l')
 for k in range(x0,x1+1):
  emit('ld a,(de)',0x1a);alu('and','(hl)');ld('c','a');inc('de');emit('ld a,(de)',0x1a);alu('or','c');ld('(hl)','a');inc('de')
  if k<x1:inc('l')
 for _ in range(x1):dec('l')
 jp('sparse_next')
for i,span in enumerate(spans):
 if span is None:continue
 x0,x1=span;lab(f'fast_span{i}')
 for _ in range(x0):inc('l')
 for k in range(x0,x1+1):
  inc('de');emit('ld a,(de)',0x1a);ld('(hl)','a');inc('de')
  if k<x1:inc('l')
 for _ in range(x1):dec('l')
 jp('sparse_next')
# Erase and draw lightning without touching the fixed upper backdrop or ground.
lab('erase_lightning');la('hx');ld('c',64);call('screen_addr');ld('b',80);ld('a',1);call('mark_dirty');lab('erase_lightning_row');ld('(hl)',0);call('nextrow');dec('b');jp('erase_lightning_row','nz');ret()
lab('draw_lightning');la('hx');ld('c',64);call('screen_addr');ld('de','lightning_warn');branch_var('htype',2,'lightning_image');ld('de','lightning0');la('frame');bit(0);jp('lightning_image','z');ld('de','lightning1');lab('lightning_image')
for _ in range(5):push('de');call('draw_1_16');pop('de')
ret()
# Dynamic draw/erase routines; old state still present during erase phase.
def location(x,y):la(y);ld('c','a');la(x);call('screen_addr')
def actor_loc(x,y):la(y);ld('c','a');la(x)
def ptr_table(n):# A index -> DE pointer, preserves neither HL nor C
 alu('add','a');ld('e','a');ld('d',0);ld('hl',n);addhl('de');ld('e','(hl)');inc('hl');ld('d','(hl)')
lab('erase_all');la('shadow_mode');alu('or','a');jp('erase_direct','z');call('clear_shadow');branch_var('hon',0,'erase_shadow_done');branch_var('htype',0,'erase_shadow_done','nz');la('hy');alu('cp',64);jp('erase_shadow_done','nc');location('hx','hy');jp('erase_meteor');lab('erase_shadow_done');ret();lab('erase_direct');location('px','py');call('erase_5_32')
for i in range(4):
 p=f'e{i}';skip=tag();branch_var(p+'on',0,skip);location(p+'x',p+'y');call('erase_5_32');lab(skip)
for i in range(3):
 p=f'b{i}';skip=tag();branch_var(p+'on',0,skip);location(p+'x',p+'y');call('erase_1_4');lab(skip)
skip=tag();branch_var('hon',0,skip);la('htype');alu('cp',2);jp('erase_lightning_call','nc');location('hx','hy');branch_var('htype',0,'erase_meteor');call('erase_2_16');jp('erase_haz_done');lab('erase_meteor');call('erase_1_16');la('hy');alu('cp',64);jp('erase_haz_done','nc');branch_var('phase',1,'erase_moon','nz');jp('erase_moon_actual');lab('erase_moon');jp('erase_city');lab('erase_moon_actual');la('hx');alu('cp',184);jp('erase_haz_done','c');alu('cp',232);jp('erase_haz_done','nc');call('moon_restore');jp('erase_haz_done');lab('erase_city');call('city_restore');jp('erase_haz_done');lab('erase_lightning_call');call('erase_lightning');lab('erase_haz_done');lab(skip);skip=tag();branch_var('bon',0,skip);location('bx','by');call('erase_2_8');lab(skip);ret()
lab('draw_all');branch_var('boss',0,'draw_enemies');ld('a',208);ld('c',80);call('screen_addr');branch_var('boss_hp',0,'boss_death_draw');ld('de','boss_closed');la('frame');alu('and',31);alu('cp',6);jp('boss_img','c');ld('de','boss_hit_img');la('boss_hit');alu('cp',7);jp('boss_img','nc');lab('boss_not_hit');ld('de','boss_mouth');la('boss_delay');alu('cp',8);jp('boss_img','c');ld('de','boss_open');jp('boss_normal');lab('boss_death_draw');la('boss_end');alu('cp',48);jp('boss_death_clear','nc');bit(2);jp('boss_death_clear','nz');ld('de','boss_open');call('draw_6_64');jp('boss_death_fx');lab('boss_death_clear');call('erase_6_64');lab('boss_death_fx')
# Four independently staggered bursts move across the original 48x64 boss.
ld('hl','death_by_phase');call('phase_value');alu('sub',4);ld('b','a');la('boss_end');alu('cp','b');jp('death_sparks','nc')
for off in (0,8,16,24):ld('a',off);call('death_burst')
# The last boss gets an extra pair of explosions spreading beyond the silhouette.
branch_var('phase',5,'death_final_normal','nz')
for off in (4,20):ld('a',off);call('death_burst')
la('boss_end');alu('cp',84);jp('death_sparks','c');jp('death_final_flash')
lab('death_final_normal');la('boss_end');alu('cp',63);jp('death_sparks','c')
# Final crescendo: four additional blasts erupt in the gaps of the silhouette.
lab('death_final_flash');ld('de','death_blast2')
for x,y in ((224,96),(224,128),(208,112),(240,112)):
 push('de');ld('a',x);ld('c',y);call('screen_addr');call('draw_2_16');pop('de')
lab('death_sparks')
# Flickering fragments on the left of the boss, within the shadow buffer.
for off in (0,4,8):ld('a',off);call('death_spark')
jp('draw_player')
lab('death_burst');ld('b','a');la('boss_end');alu('add','b');ld('b','a');alu('and',7);ld('e','a');ld('d',0);ld('hl','effect_anim');addhl('de');ld('a','(hl)');push('bc');ptr_table('death_blast_table');pop('bc');push('de');ld('a','b');alu('and',28);emit('rrca',0x0f);ld('e','a');ld('d',0);ld('hl','death_positions');addhl('de');ld('a','(hl)');inc('hl');ld('c','(hl)');call('screen_addr');pop('de');jp('draw_2_16')
lab('death_spark');ld('b','a');la('boss_end');alu('add','b');bit(1);ret('z');ld('b','a');alu('and',12);alu('add',184);push('af');ld('a','b');alu('and',24);emit('rlca',0x07);alu('add',80);ld('c','a');pop('af');call('screen_addr');ld('de','spark_bitmap');jp('draw_1_8')
lab('boss_normal');call('draw_6_64');jp('draw_player');lab('boss_img');push('de');ld('de','boss_open');call('draw_6_64');pop('hl');ld('a','(hl)');inc('hl');ld('c','(hl)');inc('hl');ld('b','(hl)');inc('hl');push('bc');emit('ex de,hl',0xeb);call('screen_addr');pop('bc');call('boss_patch');jp('draw_player')
lab('boss_patch');emit('ld a,(de)',0x1a);ld('(hl)','a');inc('de');inc('l');emit('ld a,(de)',0x1a);ld('(hl)','a');inc('de');dec('l');call('nextrow');dec('b');jp('boss_patch','nz');ret()
lab('draw_enemies')
for i in range(4):
 p=f'e{i}';skip=tag();fast=tag();choose=tag();right=tag();ready=tag();dying=tag();branch_var(p+'on',0,skip);branch_var(p+'on',2,dying);la(p+'anim');emit('rrca',0x0f);emit('rrca',0x0f);alu('and',7);jp(choose);lab(dying);la(p+'death');ld('e','a');ld('d',0);ld('hl','zdeath_pose');addhl('de');ld('a','(hl)');lab(choose);ld('b','a');branch_var(p+'species',1,p+'_alien_draw');la(p+'dir');alu('or','a');ld('a','b');jp(right,'nz');ptr_table('etable_left');jp(ready);lab(right);ptr_table('etable_right');jp(ready);lab(p+'_alien_draw');la(p+'dir');alu('or','a');ld('a','b');jp(p+'_alien_right','nz');ptr_table('atable_left');jp(ready);lab(p+'_alien_right');ptr_table('atable_right');lab(ready);branch_var(p+'on',2,p+'_drawdead');actor_loc(p+'x',p+'y');call('actor_draw');jp(skip);lab(p+'_drawdead');actor_loc(p+'x',p+'y');alu('and',248);call('actor_draw');lab(skip)
lab('draw_player');la('death');alu('or','a');jp('draw_ace','nz');la('inv');alu('and',8);jp('draw_shots','nz');lab('draw_ace');la('pose');ptr_table('ptable');branch_var('death',0,'draw_alive');actor_loc('px','py');alu('and',248);call('actor_draw');jp('draw_shots');lab('draw_alive');actor_loc('px','py');call('actor_draw');lab('draw_shots')
for i in range(3):
 p=f'b{i}';skip=tag();branch_var(p+'on',0,skip);location(p+'x',p+'y');ld('de','bullet');la(p+'x');bit(2);jp(f'bullet{i}_ready','z');ld('de','bullet_shift');lab(f'bullet{i}_ready');call('draw_1_4');lab(skip)
skip=tag();branch_var('hon',0,skip);la('htype');alu('cp',2);jp('draw_lightning_call','nc');location('hx','hy');branch_var('htype',0,'draw_meteor');push('hl');la('hboom');ld('e','a');ld('d',0);ld('hl','hboom_pose');addhl('de');ld('a','(hl)');ptr_table('explosion_table');pop('hl');call('draw_2_16');jp('draw_haz_done');lab('draw_meteor');push('hl');la('frame');alu('and',7);ld('e','a');ld('d',0);ld('hl','effect_anim');addhl('de');ld('a','(hl)');ptr_table('meteor_table');pop('hl');call('draw_1_16');jp('draw_haz_done');lab('draw_lightning_call');call('draw_lightning');lab('draw_haz_done');lab(skip);skip=tag();branch_var('bon',0,skip);location('bx','by');push('hl');la('frame');alu('and',7);ld('e','a');ld('d',0);ld('hl','effect_anim');addhl('de');ld('a','(hl)');ptr_table('bossfire_table');pop('hl');call('draw_2_8');lab(skip);ret()
# Native 192px terrain, 4 pre-shifted bit phases; rotate 24-byte row then repeat 8 bytes.
# Unrolled LDI writes only the 24 ground lines. Never scroll the background or HUD.
lab('ground');branch_var('boss',0,'ground_scroll');ret();lab('ground_scroll');branch_var('advance',0,'ground_idle');la('scroll');alu('add',2);alu('cp',192);jp('ground_store','c');alu('xor','a');lab('ground_store');sa('scroll')
lab('ground_render');la('scroll');alu('and',6);ld('e','a');ld('d',0);ld('hl','floor_ptr');addhl('de');ld('e','(hl)');inc('hl');ld('d','(hl)');push('de');la('scroll');emit('rrca',0x0f);emit('rrca',0x0f);emit('rrca',0x0f);alu('and',31);sa('ground_offset');alu('add','a');ld('e','a');ld('d',0);ld('hl','ground_copy24');addhl('de');sh('ground_first');ld('hl','ground_copy_end');alu('or','a');emit('sbc hl,de',0xed,0x52);sh('ground_second');pop('hl')
for y in range(144,168):
 ld('de',addr(y));call('ground_row')
lab('ground_idle');ret()
lab('ground_row');push('de');push('hl');emit('db $01 ; LD BC,nn',0x01);lab('ground_offset');dw(0);addhl('bc');emit('db $cd ; CALL nn',0xcd);lab('ground_first');dw(0);sh('ground_next');pop('hl');emit('db $cd ; CALL nn',0xcd);lab('ground_second');dw(0);pop('hl');call('ground_copy8');lh('ground_next');ret();lab('ground_next');dw(0)
# LDI staircase: call the appropriate entry for 0..24 copies; BC is not used for termination.
lab('ground_copy24')
for i in range(24):
 if i==16:lab('ground_copy8')
 emit('ldi',0xed,0xa0)
lab('ground_copy_end');ret()
# HUD digits at exact approved pixel rows (181). Draw only when changed in later revisions.
lab('hud_if_dirty');la('lives');ld('b','a');la('hud_lives');alu('cp','b');jp('hud','nz');ld('hl','score');ld('de','hud_score');ld('b',5);lab('hud_check');emit('ld a,(de)',0x1a);alu('cp','(hl)');jp('hud','nz');inc('hl');inc('de');dec('b');jp('hud_check','nz');ret()
lab('hud');la('lives');sa('hud_lives');ld('hl','score');ld('de','hud_score');ld('bc',5);emit('ldir',0xed,0xb0)
for i in range(5):
 la(f'score{i}');call('digit_ptr');ld('hl',addr(181,2+4-i));call('draw_1_8')
# HUD has two existing life digits. Convert 0..99 without touching score.
la('lives');ld('b',0);lab('life_digits');alu('cp',10);jp('life_digits_done','c');alu('sub',10);inc('b');jp('life_digits');lab('life_digits_done');push('af');ld('a','b');call('digit_ptr');ld('hl',addr(181,15));call('draw_1_8');pop('af');call('digit_ptr');ld('hl',addr(181,16));call('draw_1_8');ret()
lab('digit_ptr');alu('add','a');alu('add','a');alu('add','a');ld('e','a');ld('d',0);ld('hl','digits');addhl('de');emit('ex de,hl',0xeb);ret()
# End screen: 150 interrupts (3 s) then fresh fire; replay alpha, not title.
lab('gameover');ld('hl','song_over');call('song_start');ld('de','msg_over');jp('end_screen');lab('win');ld('hl','song_win');call('song_start');branch_var('phase',5,'final_victory');ld('de','msg_win');call('show_message');la('phase');call('digit_ptr');ld('hl',addr(56,15));call('draw_1_8');jp('end_hold');lab('end_screen');call('show_message');lab('end_hold');ld('b',150);lab('wait_end');call('song_wait');dec('b');jp('wait_end','nz');lab('release_end');call('input');la('keys');bit(4);jp('release_end','nz');lab('press_end');emit('halt',0x76);call('input');la('keys');bit(4);jp('press_end','z');branch_var('lives',0,'title');branch_var('phase',5,'title');jp('next_phase')
# Reserved for the fifth phase; no early ending in this two-phase alpha.
lab('final_victory');call('load_final_screen');lab('wait_final');ld('b',150);jp('wait_end')
lab('show_message');ld('hl',addr(56,10));ld('b',8);lab('msg_row');push('bc')
ld('c',12);lab('msg_col');emit('ld a,(de)',0x1a);ld('(hl)','a');inc('de');inc('l');dec('c');jp('msg_col','nz')
ld('a','l');alu('sub',12);ld('l','a');call('nextrow');pop('bc');dec('b');jp('msg_row','nz');ret()
# Data banks (only right-facing Ace; two preshift offsets per selected animation).
lab('vars');lab('px');data(b'\0');lab('vars_plus1')
for n in ['py','lives','boss_hp','jump','qheld','pose','keys','joy','inv','inv_last','bonus_left','cool','frame','last','scroll','boss','progress','hon','hx','hy','htype','hdelay','rng','rng_hi','spawn_delay','advance','moving','walkclock','distance_sub','death','bon','bx','by','lane','boss_delay','boss_hit','boss_ready','boss_end','hboom','crouch_clock','wave_left','front_block','hscroll','spawn_dir','boss_burst','sound']+[f'e{i}{s}' for i in range(4) for s in ['x','y','on','dir','period','speed','wait','anim','death','hp','species']]+[f'b{i}{s}' for i in range(3) for s in ['x','y','on','diag']]:lab(n);data(b'\0')
lab('score')
for i in range(5):lab(f'score{i}');data(b'\0')
lab('saved_sp');data(b'\0\0');labels['vars_size']=O+len(code)-labels['vars']-1
data(bytes((-(O+len(code)))%32));lab('used_cols');data(b'\0');lab('used_cols_plus1');data(bytes(31));lab('hud_lives');data(b'\0');lab('hud_score');data(bytes(5));lab('shadow_mode');data(b'\0');lab('dirty');data(bytes(2));lab('dirty_plus2');data(bytes(24));lab('old_dirty');data(bytes(6));lab('old_dirty_ground');data(bytes(20));lab('phase');data(b'\1');lab('cheat');data(b'\0');lab('cheat_steps');data(b'\0');lab('cheat_down');data(b'\0');lab('select_hold');data(b'\0');lab('selected_phase');data(b'\1');lab('load_id');data(b'\0');lab('load_dest');data(b'\0\0');lab('load_len');data(b'\0\0');lab('header_buf');data(b'\0');lab('header_name');data(bytes(10));lab('header_len');data(bytes(2));lab('header_dest');data(bytes(2));data(bytes(2))
lab('jump_y');data(bytes(round(112-48*math.sin(math.pi*(i+1)/23)) for i in range(22)))
lab('jump_pose');data(bytes([16]*5+[17]*6+[18]*6+[19]*6));lab('crouch_anim');data(bytes([20,20,20,21,21,22,22]));lab('walk_pose');data(bytes([6-i//3 for i in range(18)]));lab('action_anim');lab('effect_anim');data(bytes([0,0,1,1,2,2,1,1]));lab('death_pose');data(bytes([28]+[28-i//4 for i in range(24)]));lab('zdeath_pose');data(bytes([11]+[11-i//4 for i in range(24)]));lab('bullet');data(bytes([0,0xf0,0xf0,0]));lab('bullet_shift');data(bytes([0,15,15,0]))
effects=new_effects
lab('lightning_warn');data(bytes([0x18,0,0,0]*4));lab('lightning0');data(effects[96:112]);lab('lightning1');data(effects[112:128])
for n,off,length in [('firefall',48,16),('firefall1',64,16),('firefall2',80,16)]:lab(n);data(effects[off:off+length])
font=get('RECURSOS/05_HUD_Y_FUENTES/font.bin');lab('digits');data(font[16*8:26*8])
def textrows(s):return bytes(font[(ord(c)-32)*8+y] for y in range(8) for c in s.ljust(12)[:12])
lab('msg_cheat');data(textrows('TRUCO ACTIVO'));lab('msg_over');data(textrows(' GAME OVER'));lab('msg_win');data(textrows('FASE 1 OK'));lab('msg_load2');data(textrows('CARGA FASE 2'));lab('msg_rewind');data(textrows('REBOBINA TAP'));lab('msg_select');data(textrows('O/P FASE   1'));lab('hp_by_phase');data(bytes([16,22,28,34,50]));lab('speed_by_phase');data(bytes([5,6,7,8,9]));lab('death_by_phase');data(bytes([75,75,75,75,100]));lab('species_by_phase');data(bytes([0,0,5,10,13]));lab('eye_by_phase');data(bytes([220,220,212,212,212]))
# Approved actual asset banks. Interleave mask and bitmap; pre-shift into five bytes.
def frame_rows(group,idx,shift):
 p='RECURSOS/'+group+'/';bm=(ace.read('sprites.bin') if group=='01_SOLDADO' else get(p+'sprites.bin'))[idx*128:(idx+1)*128];mk=(ace.read('masks.bin') if group=='01_SOLDADO' else get(p+'masks.bin'))[idx*128:(idx+1)*128]
 for y in range(32):
  bits=int.from_bytes(bm[y*4:y*4+4],'big');mask=int.from_bytes(mk[y*4:y*4+4],'big');opaque=(~mask)&0xffffffff
  width=4 if shift==0 else 5;b=(bits<<shift).to_bytes(width,'big');m=((~(opaque<<shift))&((1<<(width*8))-1)).to_bytes(width,'big')
  pairs=list(zip(m,b));xs=[x for x,pair in enumerate(pairs) if pair!=(255,0)]
  if not xs:yield b'\0';continue
  x0,x1=min(xs),max(xs);yield bytes([spans.index((x0,x1))*3])+bytes(v for pair in pairs[x0:x1+1] for v in pair)
frames=[('01_SOLDADO',i,f'ace{i}') for i in range(29)]
for species,group,dirs in [('zombie','03_ZOMBIE',[('left',0),('right',12)]),('alien','02_ALIEN',[('left',12),('right',0)])]:
 for direction,baseidx in dirs:
  for j in range(12):frames.append((group,baseidx+j,f'{species}_{direction}_{j}'))
def shifts(group,idx):return [0] if (idx>=23 if group=='01_SOLDADO' else idx%12>=6) else [0,4]
counts=collections.Counter(row for g,i,n in frames for shift in shifts(g,i) for row in frame_rows(g,i,shift))
rank=sorted((((len(row)-1)*count-len(row)-2)/count,(len(row)-1)*count-len(row)-2,row) for row,count in counts.items())[::-1]
dict_rows=[row for ratio,saving,row in rank[:208] if saving>0];dictionary={row:48+i for i,row in enumerate(dict_rows)}
lab('row_dict');labels['row_dict_base']=labels['row_dict']-96
for i,row in enumerate(dict_rows):dw(f'row_dict_{i}')
for i,row in enumerate(dict_rows):lab(f'row_dict_{i}');data(row)
for group,idx,n in frames:
 ss=shifts(group,idx);lab(n);dw(n+'_s0');dw(n+('_s0' if len(ss)==1 else '_s4'))
 for shift in ss:
  lab(n+f'_s{shift}');data(b''.join(bytes([dictionary[row]]) if row in dictionary else row for row in frame_rows(group,idx,shift)))
lab('ptable')
for i in range(29):dw(f'ace{i}')
for species,prefix in [('zombie','etable'),('alien','atable')]:
 for direction in ['left','right']:
  lab(f'{prefix}_{direction}')
  for i in range(12):dw(f'{species}_{direction}_{i}')
lab('hboom_pose');data(bytes([2]*5+[1]*4+[0]*4));
for i in range(3):lab(f'boom{i}');data(effects[128+32*i:160+32*i])
# New boss-only 16x16 bursts: hot irregular core, expanding starburst and scattered debris.
# Keep the original meteor explosion assets unchanged.
for stage in range(3):
 lab(f'death_blast{stage}');rows=[]
 for y in range(16):
  v=0
  for x in range(16):
   dx=x-7.5;dy=y-7.5;r=math.hypot(dx,dy);a=math.atan2(dy,dx);j=(x*17+y*31+stage*13)%11
   rays=abs(math.cos(4*a))>.91
   if stage==0:on=r<3.0 or (r<6 and rays) or (4<r<6 and j==1)
   elif stage==1:on=r<3.2 or (3.2<=r<5.9+1.3*math.sin(7*a) and j>2) or (r<8 and rays) or (6<r<9 and j==1)
   else:on=(2.2<r<6.8 and j>3 and (r<4 or rays or j>7)) or (6<r<9 and (rays and j>3 or j==1))
   if on:v|=1<<(15-x)
  rows.append(v.to_bytes(2,'big'))
 data(b''.join(rows))
lab('death_blast_table')
for stage in range(3):dw(f'death_blast{stage}')
lab('death_positions');data(bytes([208,80,240,96,224,112,208,128,240,80,208,96,240,128,224,80]));lab('spark_bitmap');data(bytes([0x10,0,0x44,0x10,0xaa,0x10,0x44,0]));lab('explosion_table')
for i in range(3):dw(f'boom{i}')
lab('meteor_table')
for n in ['firefall','firefall1','firefall2']:dw(n)
# Build the title directly from the supplied 6912-byte SCR, preserving all logo pixels/attributes.
with zipfile.ZipFile(ROOT/'LOGO_ZX.zip') as logo:
 title=bytearray(logo.read('logo_color.scr'))
assert len(title)==6912
for y,t,col in [(128,'PULSA FUEGO',0x46),(144,'Q A O P / SPACE',0x47),(160,'KEMPSTON AUTO',0x45),(184,'TONY C. WARE 2026',0x47)]:
 x=(32-len(t))//2
 for j,ch in enumerate(t):
  for r in range(8):title[addr(y+r,x+j)-0x4000]=font[(ord(ch)-32)*8+r]
  title[6144+y//8*32+x+j]=col
(ROOT/'titulo.scr').write_bytes(title)
lab('title_screen');data(pack(bytes(title)))
lab('phase_bank')
with zipfile.ZipFile(ROOT/'BARCELONA_ZX_V2.zip') as city:
 city_bitmap=city.read('bitmap.bin')
assert len(city_bitmap)==1536
def stage_assets(phase):
 # Compose exact opaque patches from the approved per-boss metadata.
 name=('senor','bruja','mago','cocinero','enfermera')[phase-1];boss=bosses.read(name+'/boss.bin');meta=json.loads(bosses.read(name+'/metadata.json'));base=bytes(boss[:384]);assert len(boss)==512
 img=bytearray(base)
 for key,where in [('ojo_normal','eye_patch'),('boca_cerrada','mouth_patch')]:
  info=meta[key];x,y=meta['placement'][where];patch=boss[info['offset']:info['offset']+info['bytes']]
  for j in range(info['height']):img[(y+j)*6+x//8:(y+j)*6+x//8+2]=patch[j*2:j*2+2]
 lab('boss_open');data(img)
 for n,key,where in [('boss_closed','ojo_cerrado','eye_patch'),('boss_hit_img','ojo_impacto','eye_patch'),('boss_mouth','boca_abierta','mouth_patch')]:
  info=meta[key];x,y=meta['placement'][where];patch=boss[info['offset']:info['offset']+info['bytes']]
  lab(n);data(bytes([208+x,80+y,info['height']])+patch)
 for i in range(3):lab(f'bossfire{i}');data(new_effects[16*i:16*(i+1)])
 lab('bossfire_table')
 for i in range(3):dw(f'bossfire{i}')
 # Original 192x24 native bitmap, four even sub-byte shifts.
 path=('01_carretera/carretera.bin','02_ciudad/ciudad.bin','03_laboratorio/laboratorio.bin','04_ultratecnologia/ultratecnologia.bin','05_alien/alien.bin')[phase-1]
 raw=(alien_floor if phase==5 else floors).read(path);assert len(raw)==576
 road=[raw[y*24:y*24+24] for y in range(24)]
 lab('floor_ptr')
 for shift in range(0,8,2):dw(f'floor{shift}')
 for shift in range(0,8,2):
  lab(f'floor{shift}')
  for row in road:
   v=int.from_bytes(row,'big');data((((v<<shift)|(v>>(192-shift)))&((1<<192)-1)).to_bytes(24,'big'))
 backdrop=city_bitmap if phase==2 else backgrounds.read({3:'03_laboratorio',4:'04_ultratecnologia',5:'05_entorno_alien'}[phase]+'/bitmap.bin') if phase>=3 else None
 lab('moon_bitmap');data(moon_bitmap if phase==1 else backdrop[24*32:])
 # initial screen: stars and moon attributes; moon bitmap drawn separately at restart.
 scr=bytearray(6912);colour=(0x45,0x46,0x44,0x43,0x42)[phase-1];scr[6144:]=bytes([colour])*768
 if phase==1:
  for x,y in [(9,7),(37,18),(68,5),(95,29),(127,13),(151,34),(180,8),(202,22),(236,12),(250,36),(16,32),(112,38)]:
   if not (184<=x<232 and 16<=y<64):scr[addr(y,x//8)-0x4000]|=128>>(x%8)
  for r in range(6):scr[6144+(2+r)*32+23:6144+(2+r)*32+29]=moon_attrs[r*6:r*6+6]
 else:
  for y in range(48):
   a=addr(y+16)-0x4000;scr[a:a+32]=backdrop[y*32:y*32+32]
  for y in range(2,8):scr[6144+y*32:6144+(y+1)*32]=bytes([colour&7])*32
 for y,row in enumerate(road,144):
  if phase!=1:a=addr(y)-0x4000;scr[a:a+32]=row+row[:8]
 at=get('RECURSOS/04_SUELOS_V2/carretera_attr.bin');
 for y in range(3):scr[6144+(18+y)*32:6144+(19+y)*32]=bytes([colour])*32
 hud=get('RECURSOS/05_HUD_Y_FUENTES/hud_base.bin')
 for y in range(24):a=addr(y+168)-0x4000;scr[a:a+32]=hud[y*32:y*32+32]
 # Fixed HUD colour zones independent of the phase.
 for y in range(21,24):
  for x in range(32):scr[6144+y*32+x]=0x46 if x<13 else 0x44 if x<23 else 0x47
 # Static zeros in digit fields; changing digits overwritten by HUD routine.
 for x in [2,3,4,5,6,7,15,16,25,26]:
  ch=phase if x==26 else 0
  for y in range(8):scr[addr(181+y,x)-0x4000]=font[(16+ch)*8+y]
 # Initial screen is emitted compactly as separate data after code? 6912 bytes fit only with smaller bank.
 if phase==1:lab('initial_screen');data(pack(bytes(scr)))
 else:(ROOT/{2:'barcelona_fase2.scr',3:'laboratorio_fase3.scr',4:'ultratecnologia_fase4.scr',5:'alien_fase5.scr'}[phase]).write_bytes(scr)
bank_start=len(code);base_labels=set(labels);fix_start=len(fixes);listing_start=len(listing)
stage_assets(1)
phase1_size=len(code)-bank_start;labels['phase_size']=phase1_size
# Build second bank at identical addresses in a separate output image. Restore phase1 labels/listing afterward.
phase1_code=bytes(code);phase1_labels=labels.copy();phase1_fixes=fixes[:];phase1_listing=listing[:]
stage_data={}
for phase in (2,3,4,5):
 del code[bank_start:];labels={k:v for k,v in phase1_labels.items() if k in base_labels};del fixes[fix_start:];del listing[listing_start:]
 stage_assets(phase)
 assert len(code)-bank_start<=phase1_size,(len(code)-bank_start,phase1_size)
 for k,v in labels.items():
  if k not in base_labels:assert phase1_labels[k]==v,(k,v,phase1_labels[k])
 for pos,n in fixes[fix_start:]:code[pos:pos+2]=struct.pack('<H',labels[n])
 stage_data[phase]=bytes(code[bank_start:]).ljust(phase1_size,b'\0')
 (ROOT/f'fase{phase}.bin').write_bytes(stage_data[phase]);(ROOT/f'fase{phase}.asm').write_text(f'org ${O+bank_start:04x}\n'+'\n'.join(listing[listing_start:])+'\n')
phase2_data=stage_data[2];phase3_data=stage_data[3]
code=bytearray(phase1_code);labels=phase1_labels;fixes=phase1_fixes;listing=phase1_listing
labels['shadow']=(O+len(code)+255)&~255;labels['shadow_plus1']=labels['shadow']+1;labels['shadow_end']=labels['shadow']+3328;code[labels['mark_shadow_hi']-O]=labels['shadow']>>8;code[labels['pub_shadow_hi']-O]=labels['shadow']>>8;code[labels['clear_shadow_hi']-O]=(labels['shadow']>>8)+3
for k in ('mark_shadow_hi','pub_shadow_hi','clear_shadow_hi'):
 listing[listing.index(k+':')+1]=f'    db ${code[labels[k]-O]:02x}'
for k in ('shadow','shadow_plus1','shadow_end','row_dict_base','phase_size'):
 listing.append(f'{k} equ ${labels[k]:04x}')
assert labels['shadow_end']<=0xfd00, (hex(labels['shadow']),hex(labels['shadow_end']),hex(O+len(code)))
for pos,n in fixes:
 assert n in labels,n;code[pos:pos+2]=struct.pack('<H',labels[n])
assert O+len(code)<=0xfd00,(hex(O+len(code)),len(code))
(ROOT/'escoria.bin').write_bytes(code);(ROOT/'escoria.asm').write_text(f'org ${O:04x}\n'+'\n'.join(listing)+f'\nvars_size equ {labels["vars_size"]}\n')
(ROOT/'symbols.json').write_text(json.dumps(labels,indent=2))
# Standard Spectrum TAP: BASIC program + CODE; numeric markers for Sinclair BASIC.
def number(n):return str(n).encode()+bytes([14,0,0,n&255,n>>8,0])
def block(flag,p):
 b=bytes([flag])+p;cs=0
 for x in b:cs^=x
 return struct.pack('<H',len(b)+1)+b+bytes([cs])
def header(t,name,l,p1,p2):
 name=name.encode('ascii')
 assert len(name)<=10, 'Spectrum TAP filename exceeds 10 bytes'
 result=block(0,bytes([t])+name.ljust(10,b' ')+struct.pack('<HHH',l,p1,p2))
 assert len(result)==21 # 2-byte block length + 19-byte ROM header
 return result
# CLEAR before CODE: LOAD "" CODE: RANDOMIZE USR entry
line=bytes([0xfd])+number(O-1)+b':'+bytes([0xef])+b'""'+bytes([0xaf])+b':'+bytes([0xef])+b'""'+bytes([0xaf])+b':'+bytes([0xf9,0xc0])+number(O)+b'\r'
basic=struct.pack('>H',10)+struct.pack('<H',len(line))+line
resident=bytes(code[:bank_start]);phase1_data=bytes(code[bank_start:]);(ROOT/'fase1.bin').write_bytes(phase1_data)
out=header(0,'ESCORIA',len(basic),10,len(basic))+block(255,basic)+header(3,'ESCORIA020',len(resident),O,0)+block(255,resident)+header(3,'ROADBANK',len(phase1_data),O+bank_start,0)+block(255,phase1_data)+header(3,'BCNBANK',len(phase2_data),O+bank_start,0)+block(255,phase2_data)+header(3,'PANTALLA2',6912,0x4000,0)+block(255,(ROOT/'barcelona_fase2.scr').read_bytes())
with zipfile.ZipFile(ROOT/'FINAL_ZX_V2.zip') as ending:
 final=ending.read('final.scr')
assert len(final)==6912 and all(not a&128 for a in final[6144:])
(ROOT/'final.scr').write_bytes(final)
out+=header(3,'LABBANK',len(phase3_data),O+bank_start,0)+block(255,phase3_data)+header(3,'TERCERA',6912,0x4000,0)+block(255,(ROOT/'laboratorio_fase3.scr').read_bytes())
for phase,bank,screen,scr in [(4,'ULTRABANK','CUARTA','ultratecnologia_fase4.scr'),(5,'ALIENBANK','QUINTA','alien_fase5.scr')]:
 out+=header(3,bank,len(stage_data[phase]),O+bank_start,0)+block(255,stage_data[phase])+header(3,screen,6912,0x4000,0)+block(255,(ROOT/scr).read_bytes())
out+=header(3,'FINAL',6912,0x4000,0)+block(255,final)
(ROOT/'base_sin_carga.tap').write_bytes(out);print('CODE',len(code),'end',hex(O+len(code)), 'TAP',len(out),'resident',len(resident),'overlay',len(phase1_data))

from loading import wrap
(ROOT/'ESCORIA_SIDERAL_V1.0.1_DIRECTOR.tap').write_bytes(wrap(out))
