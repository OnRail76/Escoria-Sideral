org $5f00
start:
    di
    ld sp,65534
    ld iy,$5c3a
    im 1
    xor a
    out ($fe),a
    ei
title:
    xor a
    ld (joy),a
    xor a
    ld (cheat),a
    xor a
    ld (cheat_steps),a
    xor a
    ld (cheat_down),a
    xor a
    ld (select_hold),a
    ld a,1
    ld (selected_phase),a
    ld hl,title_screen
    call unpack_screen
    ld hl,song_title
    call song_start
title_release:
    call song_wait
    call input
    ld a,(keys)
    bit 4,a
    jp nz,title_release
title_press:
    call song_wait
    call input
    ld a,(keys)
    bit 4,a
    jp nz,title_fire
    ld a,(cheat)
    cp 1
    jp z,title_select
    ld a,(keys)
    bit 2,a
    jp nz,title_down
    xor a
    ld (cheat_down),a
    jp title_press
title_down:
    ld a,(cheat_down)
    cp 1
    jp z,title_press
    ld a,1
    ld (cheat_down),a
    ld a,(cheat_steps)
    cp 2
    jp z,title_press
    ld a,(cheat_steps)
    add a,1
    ld (cheat_steps),a
    jp title_press
title_fire:
    ld a,(cheat)
    cp 1
    jp z,title_start_release
    ld a,(cheat_steps)
    cp 2
    jp nz,title_start_release
    ld a,1
    ld (cheat),a
    xor a
    ld (cheat_steps),a
    ld de,msg_cheat
    ld hl,18634
    ld b,8
    call msg_row
    ld hl,22986
    ld b,12
cheat_attr:
    ld (hl),68
    inc hl
    dec b
    jp nz,cheat_attr
    call cheat_beep
    xor a
    ld (song_active),a
    call selector_draw
title_cheat_release:
    call song_wait
    call input
    ld a,(keys)
    bit 4,a
    jp nz,title_cheat_release
    jp title_press
title_select:
    ld a,(keys)
    and 3
    jp z,selector_idle
    ld b,a
    ld a,(select_hold)
    cp 1
    jp z,title_press
    ld a,1
    ld (select_hold),a
    ld a,b
    bit 0,a
    jp nz,selector_right
    ld a,(selected_phase)
    cp 1
    jp z,selector_wrap_left
    ld a,(selected_phase)
    add a,-1
    ld (selected_phase),a
    jp selector_changed
selector_wrap_left:
    ld a,5
    ld (selected_phase),a
    jp selector_changed
selector_right:
    ld a,(selected_phase)
    cp 5
    jp z,selector_wrap_right
    ld a,(selected_phase)
    add a,1
    ld (selected_phase),a
    jp selector_changed
selector_wrap_right:
    ld a,1
    ld (selected_phase),a
selector_changed:
    call selector_draw
    jp title_press
selector_idle:
    xor a
    ld (select_hold),a
    jp title_press
selector_draw:
    ld de,msg_select
    ld hl,18666
    ld b,8
    call msg_row
    ld hl,23018
    ld b,12
selector_attr:
    ld (hl),70
    inc hl
    dec b
    jp nz,selector_attr
    ld a,(selected_phase)
    call digit_ptr
    ld hl,18677
    jp draw_1_8
cheat_beep:
    ld b,120
    xor a
cheat_tone:
    xor 16
    out ($fe),a
    ld c,160
cheat_tone_wait:
    dec c
    jp nz,cheat_tone_wait
    dec b
    jp nz,cheat_tone
    xor a
    out ($fe),a
    ret
title_start_release:
    call select_control_wait
    call input
    ld a,(keys)
    bit 4,a
    jp nz,title_start_release
    jp restart
unpack_screen:
    ld de,16384
unpack_next:
    ld a,(hl)
    inc hl
    or a
    ret z
    bit 7,a
    jp nz,unpack_match
    ld c,a
    ld b,0
    ldir
    jp unpack_next
unpack_match:
    cp 255
    jp z,unpack_long
    ld c,a
    and 7
    ld b,a
    ld a,c
    rrca
    rrca
    rrca
    and 15
    add a,3
    ld c,(hl)
    inc hl
    jp unpack_copy
unpack_long:
    ld a,(hl)
    inc hl
    ld c,(hl)
    inc hl
    ld b,(hl)
    inc hl
unpack_copy:
    push hl
    ld h,d
    ld l,e
    or a
    sbc hl,bc
    ld c,a
    ld b,0
    ldir
    pop hl
    jp unpack_next
restart:
    ld a,(phase)
    cp 1
    jp z,restart_screen
    ld de,msg_rewind
    call show_message
    call load_phase1
    ld a,1
    ld (phase),a
restart_screen:
    call clear_vars
    ld a,3
    ld (lives),a
    ld a,100
    ld (bonus_left),a
    ld a,(selected_phase)
    cp 1
    jp z,restart_road
    ld a,(selected_phase)
    jp load_selected
restart_road:
    ld hl,initial_screen
    call unpack_screen
    call moon_draw
    jp init_stage
clear_vars:
    ld a,(joy)
    push af
    ld hl,vars
    ld de,vars_plus1
    ld bc,vars_size
    ld (hl),0
    ldir
    pop af
    ld (joy),a
    ret
init_stage:
    ld a,80
    ld (px),a
    ld a,112
    ld (py),a
    ld a,0
    ld (pose),a
    ld a,16
    ld (boss_hp),a
    ld a,255
    ld (jump),a
    ld a,8
    ld (spawn_delay),a
    ld a,100
    ld (hdelay),a
    ld a,173
    ld (rng),a
    ld a,167
    ld (rng_hi),a
    ld hl,hp_by_phase
    call phase_value
    ld (boss_hp),a
init_hp_done:
    call ground_render
    call hud
    call shadow_init
    call render_begin
    call draw_all
    call publish
    ld a,(23672)
    ld (last),a
    ld (inv_last),a
    or 1
    ld (rng),a
loop:
    call sync
    call render_begin
    call erase_all
    call input
    call update
    call draw_all
    call publish
    call ground
    call hud_if_dirty
    ld a,(death)
    cp 0
    jp nz,loop
    ld a,(lives)
    cp 0
    jp z,gameover
    ld hl,death_by_phase
    call phase_value
    ld b,a
    ld a,(boss_end)
    cp b
    jp nc,win
    jp loop
next_phase:
    ld a,(phase)
    inc a
load_selected:
    cp 2
    jp z,next_phase2
    cp 3
    jp z,next_phase3
    cp 4
    jp z,next_phase4
    cp 5
    jp z,next_phase5
    jp title
next_phase2:
    ld de,msg_load2
    call show_message
    ld a,2
    call digit_ptr
    ld hl,16629
    call draw_1_8
    call load_phase2
    call load_city_screen
    ld a,2
    ld (phase),a
    jp phase_loaded
next_phase3:
    ld de,msg_load2
    call show_message
    ld a,3
    call digit_ptr
    ld hl,16629
    call draw_1_8
    call load_phase3
    call load_lab_screen
    ld a,3
    ld (phase),a
    jp phase_loaded
next_phase4:
    ld de,msg_load2
    call show_message
    ld a,4
    call digit_ptr
    ld hl,16629
    call draw_1_8
    call load_phase4
    call load_ultra_screen
    ld a,4
    ld (phase),a
    jp phase_loaded
next_phase5:
    ld de,msg_load2
    call show_message
    ld a,5
    call digit_ptr
    ld hl,16629
    call draw_1_8
    call load_phase5
    call load_alien_screen
    ld a,5
    ld (phase),a
    jp phase_loaded
phase_loaded:
    ld a,(lives)
    push af
    ld a,(bonus_left)
    push af
    ld a,(score0)
    push af
    ld a,(score1)
    push af
    ld a,(score2)
    push af
    ld a,(score3)
    push af
    ld a,(score4)
    push af
    call clear_vars
    pop af
    ld (score4),a
    pop af
    ld (score3),a
    pop af
    ld (score2),a
    pop af
    ld (score1),a
    pop af
    ld (score0),a
    pop af
    ld (bonus_left),a
    pop af
    ld (lives),a
    jp init_stage
load_phase1:
    ld a,82
    ld (load_id),a
    ld hl,phase_bank
    ld (load_dest),hl
    ld hl,phase_size
    ld (load_len),hl
    jp load_named
load_phase2:
    ld a,66
    ld (load_id),a
    ld hl,phase_bank
    ld (load_dest),hl
    ld hl,phase_size
    ld (load_len),hl
    jp load_named
load_city_screen:
    ld a,80
    ld (load_id),a
    ld hl,16384
    ld (load_dest),hl
    ld hl,6912
    ld (load_len),hl
    jp load_named
load_phase3:
    ld a,76
    ld (load_id),a
    ld hl,phase_bank
    ld (load_dest),hl
    ld hl,phase_size
    ld (load_len),hl
    jp load_named
load_lab_screen:
    ld a,84
    ld (load_id),a
    ld hl,16384
    ld (load_dest),hl
    ld hl,6912
    ld (load_len),hl
    jp load_named
load_phase4:
    ld a,85
    ld (load_id),a
    ld hl,phase_bank
    ld (load_dest),hl
    ld hl,phase_size
    ld (load_len),hl
    jp load_named
load_ultra_screen:
    ld a,67
    ld (load_id),a
    ld hl,16384
    ld (load_dest),hl
    ld hl,6912
    ld (load_len),hl
    jp load_named
load_phase5:
    ld a,65
    ld (load_id),a
    ld hl,phase_bank
    ld (load_dest),hl
    ld hl,phase_size
    ld (load_len),hl
    jp load_named
load_alien_screen:
    ld a,81
    ld (load_id),a
    ld hl,16384
    ld (load_dest),hl
    ld hl,6912
    ld (load_len),hl
    jp load_named
load_final_screen:
    ld a,70
    ld (load_id),a
    ld hl,16384
    ld (load_dest),hl
    ld hl,6912
    ld (load_len),hl
    jp load_named
load_named:
    ld ix,header_buf
    ld de,17
    xor a
    scf
    call rom_load_safe
    jp nc,load_named
    ld a,(header_buf)
    cp 3
    jp nz,load_named
    ld a,(load_id)
    ld b,a
    ld a,(header_name)
    cp b
    jp nz,load_named
    ld hl,(load_len)
    ex de,hl
    ld hl,(header_len)
    or a
    sbc hl,de
    jp nz,load_named
    ld hl,(load_dest)
    ex de,hl
    ld hl,(header_dest)
    or a
    sbc hl,de
    jp nz,load_named
load_payload:
    ld ix,(load_dest)
    ld de,(load_len)
    ld a,255
    scf
    call rom_load_safe
    jp nc,load_named
    ld iy,$5c3a
    im 1
    ei
    xor a
    out ($fe),a
    ret
phase_value:
    ld a,(phase)
    dec a
    ld e,a
    ld d,0
    add hl,de
    ld a,(hl)
    ret
sync:
    ld a,(sound)
    or a
    jp z,sync_wait
    call audio_game
    ld a,(last)
    ld b,a
    ld a,(23672)
    sub b
    cp 2
    jp nc,sync_done
    ld a,e
    call audio_play
sync_wait:
    ld a,(last)
    ld b,a
    ld a,(23672)
    sub b
    cp 2
    jp nc,sync_done
    call audio_wait
    jp sync_wait
sync_done:
    ld a,(23672)
    ld (last),a
    ret
input:
    xor a
    ld (keys),a
    xor a
    ld (joy_source),a
    call keyboard
    jp input_joy
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00
keyboard:
    ld bc,57342
    in a,(c)
    bit 0,a
    jp nz,L_1
    ld a,(keys)
    or 1
    ld (keys),a
L_1:
    ld bc,57342
    in a,(c)
    bit 1,a
    jp nz,L_2
    ld a,(keys)
    or 2
    ld (keys),a
L_2:
    ld bc,65022
    in a,(c)
    bit 0,a
    jp nz,L_3
    ld a,(keys)
    or 4
    ld (keys),a
L_3:
    ld bc,64510
    in a,(c)
    bit 0,a
    jp nz,L_4
    ld a,(keys)
    or 8
    ld (keys),a
L_4:
    ld bc,32766
    in a,(c)
    bit 0,a
    jp nz,L_5
    ld a,(keys)
    or 16
    ld (keys),a
L_5:
    ret
near:
    sub b
    jp nc,near_pos
    neg
near_pos:
    cp c
    ret
update:
    ld a,(frame)
    add a,1
    ld (frame),a
    ld a,(inv_last)
    ld b,a
    ld a,(23672)
    ld (inv_last),a
    sub b
    ld b,a
    ld a,(inv)
    sub b
    jp nc,inv_tick_ok
    xor a
inv_tick_ok:
    ld (inv),a
    ld a,(cool)
    or a
    jp z,L_6
    dec a
    ld (cool),a
L_6:
    xor a
    ld (advance),a
    xor a
    ld (moving),a
    ld a,(death)
    or a
    jp nz,death_update
    ld a,(keys)
    bit 2,a
    jp nz,movement_done
    bit 0,a
    jp z,move_left
    ld a,(boss)
    or a
    jp nz,boss_walk
    ld a,(px)
    cp 80
    jp nc,camera_walk
boss_walk:
    ld a,(px)
    cp 176
    jp nc,movement_done
    ld a,(px)
    add a,2
    ld (px),a
    ld a,1
    ld (moving),a
    jp movement_done
camera_walk:
    ld a,1
    ld (advance),a
    ld a,1
    ld (moving),a
    jp movement_done
move_left:
    ld a,(keys)
    bit 1,a
    jp z,movement_done
    ld a,(px)
    cp 2
    jp c,movement_done
    ld a,(px)
    add a,-2
    ld (px),a
    ld a,1
    ld (moving),a
movement_done:
    ld a,(moving)
    or a
    jp z,walkclock_done
    ld a,(walkclock)
    add a,1
    ld (walkclock),a
    ld a,(walkclock)
    cp 18
    jp z,walkclock_reset
    jp walkclock_done
walkclock_reset:
    xor a
    ld (walkclock),a
walkclock_done:
    ld a,(keys)
    and 8
    jp nz,q_on
    xor a
    ld (qheld),a
    jp jump_step
q_on:
    ld a,(qheld)
    or a
    jp nz,jump_step
    ld a,1
    ld (qheld),a
    ld a,(jump)
    cp 255
    jp nz,jump_step
    xor a
    ld (jump),a
jump_step:
    ld a,(jump)
    cp 255
    jp z,on_ground
    ld e,a
    ld d,0
    ld hl,jump_y
    add hl,de
    ld a,(hl)
    ld (py),a
    ld a,(jump)
    add a,1
    ld (jump),a
    ld a,(jump)
    cp 22
    jp z,jump_finished
    jp select_pose
jump_finished:
    ld a,255
    ld (jump),a
on_ground:
    ld a,112
    ld (py),a
select_pose:
    ld a,0
    ld (pose),a
    ld a,(jump)
    cp 255
    jp z,ground_pose
    xor a
    ld (crouch_clock),a
    ld a,(jump)
    ld e,a
    ld d,0
    ld hl,jump_pose
    add hl,de
    ld a,(hl)
    ld (pose),a
    jp shots_update
ground_pose:
    ld a,(keys)
    bit 2,a
    jp z,stand_up
    ld a,(crouch_clock)
    cp 6
    jp nc,crouch_pose
    inc a
    ld (crouch_clock),a
    jp crouch_pose
stand_up:
    ld a,(crouch_clock)
    or a
    jp z,standing
    dec a
    ld (crouch_clock),a
crouch_pose:
    ld e,a
    ld d,0
    ld hl,crouch_anim
    add hl,de
    ld a,(hl)
    ld (pose),a
    jp shots_update
standing:
    ld a,(moving)
    cp 0
    jp z,stationary_pose
    ld a,(walkclock)
    ld e,a
    ld d,0
    ld hl,walk_pose
    add hl,de
    ld b,(hl)
    ld a,(keys)
    bit 4,a
    ld a,b
    jp z,walk_pose_ready
    add a,6
walk_pose_ready:
    ld (pose),a
    jp shoot
stationary_pose:
    ld a,(keys)
    bit 4,a
    jp z,shots_update
    ld a,(frame)
    and 7
    ld e,a
    ld d,0
    ld hl,action_anim
    add hl,de
    ld a,(hl)
    add a,13
    ld (pose),a
    jp shoot
death_update:
    ld a,(death)
    dec a
    ld (death),a
    jp z,death_respawn
    ld e,a
    ld d,0
    ld hl,death_pose
    add hl,de
    ld a,(hl)
    ld (pose),a
    jp shots_update
death_respawn:
    ld a,112
    ld (py),a
    ld a,255
    ld (jump),a
    ld a,0
    ld (pose),a
    xor a
    ld (crouch_clock),a
    ld a,(lives)
    cp 0
    jp z,shots_update
    ld a,100
    ld (inv),a
    ld a,(23672)
    ld (inv_last),a
    jp shots_update
shoot:
    ld a,(keys)
    bit 4,a
    jp z,shots_update
    ld a,(cool)
    cp 0
    jp nz,shots_update
    ld a,(b0on)
    cp 0
    jp z,fire0
    ld a,(b1on)
    cp 0
    jp z,fire1
    ld a,(b2on)
    cp 0
    jp z,fire2
    jp shots_update
fire0:
    ld a,1
    ld (b0on),a
    ld a,(px)
    add a,25
    and 252
    ld (b0x),a
    ld a,(py)
    add a,15
    ld (b0y),a
    xor a
    ld (b0diag),a
    ld a,5
    ld (cool),a
    call beep
    jp shots_update
fire1:
    ld a,1
    ld (b1on),a
    ld a,(px)
    add a,25
    and 252
    ld (b1x),a
    ld a,(py)
    add a,15
    ld (b1y),a
    xor a
    ld (b1diag),a
    ld a,5
    ld (cool),a
    call beep
    jp shots_update
fire2:
    ld a,1
    ld (b2on),a
    ld a,(px)
    add a,25
    and 252
    ld (b2x),a
    ld a,(py)
    add a,15
    ld (b2y),a
    xor a
    ld (b2diag),a
    ld a,5
    ld (cool),a
    call beep
    jp shots_update
shots_update:
    ld a,(b0on)
    cp 0
    jp z,L_8
    ld a,(b0x)
    cp 244
    jp nc,L_7
    add a,8
    ld (b0x),a
    ld a,(b0diag)
    cp 0
    jp z,L_8
    ld a,(b0y)
    cp 44
    jp c,L_7
    sub 4
    ld (b0y),a
    jp L_8
L_7:
    xor a
    ld (b0on),a
L_8:
    ld a,(b1on)
    cp 0
    jp z,L_10
    ld a,(b1x)
    cp 244
    jp nc,L_9
    add a,8
    ld (b1x),a
    ld a,(b1diag)
    cp 0
    jp z,L_10
    ld a,(b1y)
    cp 44
    jp c,L_9
    sub 4
    ld (b1y),a
    jp L_10
L_9:
    xor a
    ld (b1on),a
L_10:
    ld a,(b2on)
    cp 0
    jp z,L_12
    ld a,(b2x)
    cp 244
    jp nc,L_11
    add a,8
    ld (b2x),a
    ld a,(b2diag)
    cp 0
    jp z,L_12
    ld a,(b2y)
    cp 44
    jp c,L_11
    sub 4
    ld (b2y),a
    jp L_12
L_11:
    xor a
    ld (b2on),a
L_12:
    ld a,(boss)
    or a
    jp nz,boss_logic
    ld a,(advance)
    cp 0
    jp z,no_progress
    ld a,(distance_sub)
    add a,1
    ld (distance_sub),a
    ld a,(distance_sub)
    cp 4
    jp z,distance_tick
    jp no_progress
distance_tick:
    xor a
    ld (distance_sub),a
    ld a,(progress)
    add a,1
    ld (progress),a
    ld a,(progress)
    cp 250
    jp z,begin_boss
no_progress:
    call random
    ld a,(spawn_delay)
    or a
    jp z,spawn_try
    dec a
    ld (spawn_delay),a
    jp enemy_move
spawn_try:
    ld a,(wave_left)
    or a
    jp nz,wave_active
wave_size_roll:
    call random
    and 3
    cp 3
    jp z,wave_size_roll
    add a,2
    ld (wave_left),a
wave_active:
    ld a,(e0on)
    cp 0
    jp z,L_13
    ld a,(e0x)
    cp 184
    jp nc,enemy_move
L_13:
    ld a,(e1on)
    cp 0
    jp z,L_14
    ld a,(e1x)
    cp 184
    jp nc,enemy_move
L_14:
    ld a,(e2on)
    cp 0
    jp z,L_15
    ld a,(e2x)
    cp 184
    jp nc,enemy_move
L_15:
    ld a,(e3on)
    cp 0
    jp z,L_16
    ld a,(e3x)
    cp 184
    jp nc,enemy_move
L_16:
    xor a
    ld (spawn_dir),a
slot_search:
    ld a,(e0on)
    cp 0
    jp z,spawn0
    ld a,(e1on)
    cp 0
    jp z,spawn1
    ld a,(e2on)
    cp 0
    jp z,spawn2
    ld a,(e3on)
    cp 0
    jp z,spawn3
    jp enemy_move
spawn0:
    xor a
    ld (e0dir),a
    ld a,216
    ld (e0x),a
    call random
    and 7
    jp z,spawn0_runner
spawn0_slow:
    and 1
    add a,2
    ld (e0period),a
    ld a,2
    ld (e0speed),a
    jp spawn0_ready
spawn0_runner:
    ld a,1
    ld (e0period),a
    ld a,4
    ld (e0speed),a
spawn0_ready:
    ld a,1
    ld (e0wait),a
    ld a,112
    ld (e0y),a
    ld a,1
    ld (e0on),a
    xor a
    ld (e0anim),a
    xor a
    ld (e0death),a
    xor a
    ld (e0species),a
    ld a,(phase)
    cp 3
    jp c,spawn0_hp
spawn0_species:
    call random
    and 15
    ld b,a
    ld hl,species_by_phase
    call phase_value
    cp b
    jp c,spawn0_hp
    jp z,spawn0_hp
    ld a,1
    ld (e0species),a
    ld a,(e0period)
    cp 1
    jp z,spawn0_alien_runner
    ld a,2
    ld (e0period),a
    jp spawn0_hp
spawn0_alien_runner:
    ld a,5
    ld (e0speed),a
spawn0_hp:
    call random
    and 3
    cp 3
    jp nc,spawn0_hp
    inc a
    ld b,a
    ld a,(e0species)
    add a,b
    ld (e0hp),a
    jp wave_schedule
spawn1:
    xor a
    ld (e1dir),a
    ld a,216
    ld (e1x),a
    call random
    and 7
    jp z,spawn1_runner
spawn1_slow:
    and 1
    add a,2
    ld (e1period),a
    ld a,2
    ld (e1speed),a
    jp spawn1_ready
spawn1_runner:
    ld a,1
    ld (e1period),a
    ld a,4
    ld (e1speed),a
spawn1_ready:
    ld a,1
    ld (e1wait),a
    ld a,112
    ld (e1y),a
    ld a,1
    ld (e1on),a
    xor a
    ld (e1anim),a
    xor a
    ld (e1death),a
    xor a
    ld (e1species),a
    ld a,(phase)
    cp 3
    jp c,spawn1_hp
spawn1_species:
    call random
    and 15
    ld b,a
    ld hl,species_by_phase
    call phase_value
    cp b
    jp c,spawn1_hp
    jp z,spawn1_hp
    ld a,1
    ld (e1species),a
    ld a,(e1period)
    cp 1
    jp z,spawn1_alien_runner
    ld a,2
    ld (e1period),a
    jp spawn1_hp
spawn1_alien_runner:
    ld a,5
    ld (e1speed),a
spawn1_hp:
    call random
    and 3
    cp 3
    jp nc,spawn1_hp
    inc a
    ld b,a
    ld a,(e1species)
    add a,b
    ld (e1hp),a
    jp wave_schedule
spawn2:
    xor a
    ld (e2dir),a
    ld a,216
    ld (e2x),a
    call random
    and 7
    jp z,spawn2_runner
spawn2_slow:
    and 1
    add a,2
    ld (e2period),a
    ld a,2
    ld (e2speed),a
    jp spawn2_ready
spawn2_runner:
    ld a,1
    ld (e2period),a
    ld a,4
    ld (e2speed),a
spawn2_ready:
    ld a,1
    ld (e2wait),a
    ld a,112
    ld (e2y),a
    ld a,1
    ld (e2on),a
    xor a
    ld (e2anim),a
    xor a
    ld (e2death),a
    xor a
    ld (e2species),a
    ld a,(phase)
    cp 3
    jp c,spawn2_hp
spawn2_species:
    call random
    and 15
    ld b,a
    ld hl,species_by_phase
    call phase_value
    cp b
    jp c,spawn2_hp
    jp z,spawn2_hp
    ld a,1
    ld (e2species),a
    ld a,(e2period)
    cp 1
    jp z,spawn2_alien_runner
    ld a,2
    ld (e2period),a
    jp spawn2_hp
spawn2_alien_runner:
    ld a,5
    ld (e2speed),a
spawn2_hp:
    call random
    and 3
    cp 3
    jp nc,spawn2_hp
    inc a
    ld b,a
    ld a,(e2species)
    add a,b
    ld (e2hp),a
    jp wave_schedule
spawn3:
    xor a
    ld (e3dir),a
    ld a,216
    ld (e3x),a
    call random
    and 7
    jp z,spawn3_runner
spawn3_slow:
    and 1
    add a,2
    ld (e3period),a
    ld a,2
    ld (e3speed),a
    jp spawn3_ready
spawn3_runner:
    ld a,1
    ld (e3period),a
    ld a,4
    ld (e3speed),a
spawn3_ready:
    ld a,1
    ld (e3wait),a
    ld a,112
    ld (e3y),a
    ld a,1
    ld (e3on),a
    xor a
    ld (e3anim),a
    xor a
    ld (e3death),a
    xor a
    ld (e3species),a
    ld a,(phase)
    cp 3
    jp c,spawn3_hp
spawn3_species:
    call random
    and 15
    ld b,a
    ld hl,species_by_phase
    call phase_value
    cp b
    jp c,spawn3_hp
    jp z,spawn3_hp
    ld a,1
    ld (e3species),a
    ld a,(e3period)
    cp 1
    jp z,spawn3_alien_runner
    ld a,2
    ld (e3period),a
    jp spawn3_hp
spawn3_alien_runner:
    ld a,5
    ld (e3speed),a
spawn3_hp:
    call random
    and 3
    cp 3
    jp nc,spawn3_hp
    inc a
    ld b,a
    ld a,(e3species)
    add a,b
    ld (e3hp),a
    jp wave_schedule
wave_schedule:
    ld a,(wave_left)
    dec a
    ld (wave_left),a
    jp z,wave_rest
    call random
    and 7
    add a,7
    ld (spawn_delay),a
    jp enemy_move
wave_rest:
    call random
    and 15
    add a,18
    ld (spawn_delay),a
    jp enemy_move
haz_spawn:
    ld a,(death)
    cp 0
    jp nz,haz_defer
    xor a
    ld (front_block),a
    ld a,(e0on)
    cp 1
    jp nz,L_17
    ld a,(px)
    ld b,a
    ld a,(e0x)
    ld c,48
    call near
    jp nc,L_17
    ld a,1
    ld (front_block),a
L_17:
    ld a,(e1on)
    cp 1
    jp nz,L_18
    ld a,(px)
    ld b,a
    ld a,(e1x)
    ld c,48
    call near
    jp nc,L_18
    ld a,1
    ld (front_block),a
L_18:
    ld a,(e2on)
    cp 1
    jp nz,L_19
    ld a,(px)
    ld b,a
    ld a,(e2x)
    ld c,48
    call near
    jp nc,L_19
    ld a,1
    ld (front_block),a
L_19:
    ld a,(e3on)
    cp 1
    jp nz,L_20
    ld a,(px)
    ld b,a
    ld a,(e3x)
    ld c,48
    call near
    jp nc,L_20
    ld a,1
    ld (front_block),a
L_20:
    ld a,(front_block)
    cp 0
    jp z,haz_choose
    ld a,(px)
    cp 24
    jp c,haz_defer
haz_choose:
    xor a
    ld (htype),a
    ld a,(phase)
    cp 3
    jp c,haz_pattern
    call random
    and 1
    jp z,haz_pattern
    ld a,2
    ld (htype),a
haz_pattern:
    ld a,(front_block)
    cp 1
    jp z,haz_ahead
    call random
    and 3
    cp 2
    jp nc,haz_ahead
    or a
    jp z,haz_center
    ld a,(px)
    and 252
    add a,12
    and 248
    sub 8
    jp nc,haz_place
    xor a
    jp haz_place
haz_center:
    ld a,(px)
    and 252
    add a,12
    and 248
    jp haz_place
haz_ahead:
    ld a,(px)
    and 252
    add a,12
    and 248
    ld b,a
    ld a,(htype)
    or a
    ld a,40
    jp z,haz_ahead_add
    ld a,24
haz_ahead_add:
    add a,b
haz_place:
    ld (hx),a
    ld a,1
    ld (hon),a
    xor a
    ld (hscroll),a
    ld a,(htype)
    cp 2
    jp z,lightning_start
    ld a,40
    ld (hy),a
    ret
haz_defer:
    ld a,12
    ld (hdelay),a
    ret
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
enemy_move:
    ld a,(e0on)
    cp 0
    jp z,L_21
    ld a,(advance)
    cp 0
    jp z,e0_camera_done
    ld a,(e0dir)
    cp 1
    jp z,e0_camera_done
    ld a,(e0x)
    sub 2
    jp c,L_22
    ld (e0x),a
e0_camera_done:
    ld a,(e0on)
    cp 2
    jp z,e0_dying
    ld a,(e0wait)
    dec a
    ld (e0wait),a
    jp nz,L_23
    ld a,(e0period)
    ld (e0wait),a
    ld a,(e0speed)
    ld b,a
    ld a,(e0dir)
    or a
    jp z,L_24
    ld a,(e0x)
    cp 216
    jp nc,L_22
    add a,b
    cp 217
    jp nc,L_22
    ld (e0x),a
    jp L_23
L_24:
    ld a,(e0x)
    sub b
    jp c,L_22
    ld (e0x),a
L_23:
    ld a,(e0period)
    cp 1
    jp z,e0_animfast
    ld a,(e0anim)
    add a,1
    ld (e0anim),a
    jp e0_animcheck
e0_animfast:
    ld a,(e0anim)
    add a,2
    ld (e0anim),a
e0_animcheck:
    ld a,(e0anim)
    cp 24
    jp z,e0_animreset
    jp e0_animdone
e0_animreset:
    xor a
    ld (e0anim),a
e0_animdone:
    ld a,(px)
    and 252
    add a,13
    ld b,a
    ld a,(e0x)
    and 252
    add a,16
    ld c,14
    call near
    jp nc,L_21
    ld a,(py)
    ld b,a
    ld a,(e0y)
    ld c,17
    call near
    jp nc,L_21
    call hurt
    jp L_21
e0_dying:
    ld a,(e0death)
    dec a
    ld (e0death),a
    jp z,L_22
    jp L_21
L_22:
    xor a
    ld (e0on),a
L_21:
    ld a,(e1on)
    cp 0
    jp z,L_25
    ld a,(advance)
    cp 0
    jp z,e1_camera_done
    ld a,(e1dir)
    cp 1
    jp z,e1_camera_done
    ld a,(e1x)
    sub 2
    jp c,L_26
    ld (e1x),a
e1_camera_done:
    ld a,(e1on)
    cp 2
    jp z,e1_dying
    ld a,(e1wait)
    dec a
    ld (e1wait),a
    jp nz,L_27
    ld a,(e1period)
    ld (e1wait),a
    ld a,(e1speed)
    ld b,a
    ld a,(e1dir)
    or a
    jp z,L_28
    ld a,(e1x)
    cp 216
    jp nc,L_26
    add a,b
    cp 217
    jp nc,L_26
    ld (e1x),a
    jp L_27
L_28:
    ld a,(e1x)
    sub b
    jp c,L_26
    ld (e1x),a
L_27:
    ld a,(e1period)
    cp 1
    jp z,e1_animfast
    ld a,(e1anim)
    add a,1
    ld (e1anim),a
    jp e1_animcheck
e1_animfast:
    ld a,(e1anim)
    add a,2
    ld (e1anim),a
e1_animcheck:
    ld a,(e1anim)
    cp 24
    jp z,e1_animreset
    jp e1_animdone
e1_animreset:
    xor a
    ld (e1anim),a
e1_animdone:
    ld a,(px)
    and 252
    add a,13
    ld b,a
    ld a,(e1x)
    and 252
    add a,16
    ld c,14
    call near
    jp nc,L_25
    ld a,(py)
    ld b,a
    ld a,(e1y)
    ld c,17
    call near
    jp nc,L_25
    call hurt
    jp L_25
e1_dying:
    ld a,(e1death)
    dec a
    ld (e1death),a
    jp z,L_26
    jp L_25
L_26:
    xor a
    ld (e1on),a
L_25:
    ld a,(e2on)
    cp 0
    jp z,L_29
    ld a,(advance)
    cp 0
    jp z,e2_camera_done
    ld a,(e2dir)
    cp 1
    jp z,e2_camera_done
    ld a,(e2x)
    sub 2
    jp c,L_30
    ld (e2x),a
e2_camera_done:
    ld a,(e2on)
    cp 2
    jp z,e2_dying
    ld a,(e2wait)
    dec a
    ld (e2wait),a
    jp nz,L_31
    ld a,(e2period)
    ld (e2wait),a
    ld a,(e2speed)
    ld b,a
    ld a,(e2dir)
    or a
    jp z,L_32
    ld a,(e2x)
    cp 216
    jp nc,L_30
    add a,b
    cp 217
    jp nc,L_30
    ld (e2x),a
    jp L_31
L_32:
    ld a,(e2x)
    sub b
    jp c,L_30
    ld (e2x),a
L_31:
    ld a,(e2period)
    cp 1
    jp z,e2_animfast
    ld a,(e2anim)
    add a,1
    ld (e2anim),a
    jp e2_animcheck
e2_animfast:
    ld a,(e2anim)
    add a,2
    ld (e2anim),a
e2_animcheck:
    ld a,(e2anim)
    cp 24
    jp z,e2_animreset
    jp e2_animdone
e2_animreset:
    xor a
    ld (e2anim),a
e2_animdone:
    ld a,(px)
    and 252
    add a,13
    ld b,a
    ld a,(e2x)
    and 252
    add a,16
    ld c,14
    call near
    jp nc,L_29
    ld a,(py)
    ld b,a
    ld a,(e2y)
    ld c,17
    call near
    jp nc,L_29
    call hurt
    jp L_29
e2_dying:
    ld a,(e2death)
    dec a
    ld (e2death),a
    jp z,L_30
    jp L_29
L_30:
    xor a
    ld (e2on),a
L_29:
    ld a,(e3on)
    cp 0
    jp z,L_33
    ld a,(advance)
    cp 0
    jp z,e3_camera_done
    ld a,(e3dir)
    cp 1
    jp z,e3_camera_done
    ld a,(e3x)
    sub 2
    jp c,L_34
    ld (e3x),a
e3_camera_done:
    ld a,(e3on)
    cp 2
    jp z,e3_dying
    ld a,(e3wait)
    dec a
    ld (e3wait),a
    jp nz,L_35
    ld a,(e3period)
    ld (e3wait),a
    ld a,(e3speed)
    ld b,a
    ld a,(e3dir)
    or a
    jp z,L_36
    ld a,(e3x)
    cp 216
    jp nc,L_34
    add a,b
    cp 217
    jp nc,L_34
    ld (e3x),a
    jp L_35
L_36:
    ld a,(e3x)
    sub b
    jp c,L_34
    ld (e3x),a
L_35:
    ld a,(e3period)
    cp 1
    jp z,e3_animfast
    ld a,(e3anim)
    add a,1
    ld (e3anim),a
    jp e3_animcheck
e3_animfast:
    ld a,(e3anim)
    add a,2
    ld (e3anim),a
e3_animcheck:
    ld a,(e3anim)
    cp 24
    jp z,e3_animreset
    jp e3_animdone
e3_animreset:
    xor a
    ld (e3anim),a
e3_animdone:
    ld a,(px)
    and 252
    add a,13
    ld b,a
    ld a,(e3x)
    and 252
    add a,16
    ld c,14
    call near
    jp nc,L_33
    ld a,(py)
    ld b,a
    ld a,(e3y)
    ld c,17
    call near
    jp nc,L_33
    call hurt
    jp L_33
e3_dying:
    ld a,(e3death)
    dec a
    ld (e3death),a
    jp z,L_34
    jp L_33
L_34:
    xor a
    ld (e3on),a
L_33:
    ld a,(b0on)
    cp 0
    jp z,L_37
    ld a,(e0on)
    cp 1
    jp nz,L_38
    ld a,(e0x)
    add a,16
    ld b,a
    ld a,(b0x)
    ld c,17
    call near
    jp nc,L_38
    ld a,(e0y)
    add a,16
    ld b,a
    ld a,(b0y)
    ld c,15
    call near
    jp nc,L_38
    xor a
    ld (b0on),a
    ld a,(e0hp)
    or a
    jp z,L_38_kill
    dec a
    ld (e0hp),a
    jp z,L_38_kill
    call sfx_hit
    jp L_37
L_38_kill:
    ld a,2
    ld (e0on),a
    ld a,24
    ld (e0death),a
    call sfx_kill
    call score_inc
    jp L_37
L_38:
    ld a,(e1on)
    cp 1
    jp nz,L_39
    ld a,(e1x)
    add a,16
    ld b,a
    ld a,(b0x)
    ld c,17
    call near
    jp nc,L_39
    ld a,(e1y)
    add a,16
    ld b,a
    ld a,(b0y)
    ld c,15
    call near
    jp nc,L_39
    xor a
    ld (b0on),a
    ld a,(e1hp)
    or a
    jp z,L_39_kill
    dec a
    ld (e1hp),a
    jp z,L_39_kill
    call sfx_hit
    jp L_37
L_39_kill:
    ld a,2
    ld (e1on),a
    ld a,24
    ld (e1death),a
    call sfx_kill
    call score_inc
    jp L_37
L_39:
    ld a,(e2on)
    cp 1
    jp nz,L_40
    ld a,(e2x)
    add a,16
    ld b,a
    ld a,(b0x)
    ld c,17
    call near
    jp nc,L_40
    ld a,(e2y)
    add a,16
    ld b,a
    ld a,(b0y)
    ld c,15
    call near
    jp nc,L_40
    xor a
    ld (b0on),a
    ld a,(e2hp)
    or a
    jp z,L_40_kill
    dec a
    ld (e2hp),a
    jp z,L_40_kill
    call sfx_hit
    jp L_37
L_40_kill:
    ld a,2
    ld (e2on),a
    ld a,24
    ld (e2death),a
    call sfx_kill
    call score_inc
    jp L_37
L_40:
    ld a,(e3on)
    cp 1
    jp nz,L_41
    ld a,(e3x)
    add a,16
    ld b,a
    ld a,(b0x)
    ld c,17
    call near
    jp nc,L_41
    ld a,(e3y)
    add a,16
    ld b,a
    ld a,(b0y)
    ld c,15
    call near
    jp nc,L_41
    xor a
    ld (b0on),a
    ld a,(e3hp)
    or a
    jp z,L_41_kill
    dec a
    ld (e3hp),a
    jp z,L_41_kill
    call sfx_hit
    jp L_37
L_41_kill:
    ld a,2
    ld (e3on),a
    ld a,24
    ld (e3death),a
    call sfx_kill
    call score_inc
    jp L_37
L_41:
L_37:
    ld a,(b1on)
    cp 0
    jp z,L_42
    ld a,(e0on)
    cp 1
    jp nz,L_43
    ld a,(e0x)
    add a,16
    ld b,a
    ld a,(b1x)
    ld c,17
    call near
    jp nc,L_43
    ld a,(e0y)
    add a,16
    ld b,a
    ld a,(b1y)
    ld c,15
    call near
    jp nc,L_43
    xor a
    ld (b1on),a
    ld a,(e0hp)
    or a
    jp z,L_43_kill
    dec a
    ld (e0hp),a
    jp z,L_43_kill
    call sfx_hit
    jp L_42
L_43_kill:
    ld a,2
    ld (e0on),a
    ld a,24
    ld (e0death),a
    call sfx_kill
    call score_inc
    jp L_42
L_43:
    ld a,(e1on)
    cp 1
    jp nz,L_44
    ld a,(e1x)
    add a,16
    ld b,a
    ld a,(b1x)
    ld c,17
    call near
    jp nc,L_44
    ld a,(e1y)
    add a,16
    ld b,a
    ld a,(b1y)
    ld c,15
    call near
    jp nc,L_44
    xor a
    ld (b1on),a
    ld a,(e1hp)
    or a
    jp z,L_44_kill
    dec a
    ld (e1hp),a
    jp z,L_44_kill
    call sfx_hit
    jp L_42
L_44_kill:
    ld a,2
    ld (e1on),a
    ld a,24
    ld (e1death),a
    call sfx_kill
    call score_inc
    jp L_42
L_44:
    ld a,(e2on)
    cp 1
    jp nz,L_45
    ld a,(e2x)
    add a,16
    ld b,a
    ld a,(b1x)
    ld c,17
    call near
    jp nc,L_45
    ld a,(e2y)
    add a,16
    ld b,a
    ld a,(b1y)
    ld c,15
    call near
    jp nc,L_45
    xor a
    ld (b1on),a
    ld a,(e2hp)
    or a
    jp z,L_45_kill
    dec a
    ld (e2hp),a
    jp z,L_45_kill
    call sfx_hit
    jp L_42
L_45_kill:
    ld a,2
    ld (e2on),a
    ld a,24
    ld (e2death),a
    call sfx_kill
    call score_inc
    jp L_42
L_45:
    ld a,(e3on)
    cp 1
    jp nz,L_46
    ld a,(e3x)
    add a,16
    ld b,a
    ld a,(b1x)
    ld c,17
    call near
    jp nc,L_46
    ld a,(e3y)
    add a,16
    ld b,a
    ld a,(b1y)
    ld c,15
    call near
    jp nc,L_46
    xor a
    ld (b1on),a
    ld a,(e3hp)
    or a
    jp z,L_46_kill
    dec a
    ld (e3hp),a
    jp z,L_46_kill
    call sfx_hit
    jp L_42
L_46_kill:
    ld a,2
    ld (e3on),a
    ld a,24
    ld (e3death),a
    call sfx_kill
    call score_inc
    jp L_42
L_46:
L_42:
    ld a,(b2on)
    cp 0
    jp z,L_47
    ld a,(e0on)
    cp 1
    jp nz,L_48
    ld a,(e0x)
    add a,16
    ld b,a
    ld a,(b2x)
    ld c,17
    call near
    jp nc,L_48
    ld a,(e0y)
    add a,16
    ld b,a
    ld a,(b2y)
    ld c,15
    call near
    jp nc,L_48
    xor a
    ld (b2on),a
    ld a,(e0hp)
    or a
    jp z,L_48_kill
    dec a
    ld (e0hp),a
    jp z,L_48_kill
    call sfx_hit
    jp L_47
L_48_kill:
    ld a,2
    ld (e0on),a
    ld a,24
    ld (e0death),a
    call sfx_kill
    call score_inc
    jp L_47
L_48:
    ld a,(e1on)
    cp 1
    jp nz,L_49
    ld a,(e1x)
    add a,16
    ld b,a
    ld a,(b2x)
    ld c,17
    call near
    jp nc,L_49
    ld a,(e1y)
    add a,16
    ld b,a
    ld a,(b2y)
    ld c,15
    call near
    jp nc,L_49
    xor a
    ld (b2on),a
    ld a,(e1hp)
    or a
    jp z,L_49_kill
    dec a
    ld (e1hp),a
    jp z,L_49_kill
    call sfx_hit
    jp L_47
L_49_kill:
    ld a,2
    ld (e1on),a
    ld a,24
    ld (e1death),a
    call sfx_kill
    call score_inc
    jp L_47
L_49:
    ld a,(e2on)
    cp 1
    jp nz,L_50
    ld a,(e2x)
    add a,16
    ld b,a
    ld a,(b2x)
    ld c,17
    call near
    jp nc,L_50
    ld a,(e2y)
    add a,16
    ld b,a
    ld a,(b2y)
    ld c,15
    call near
    jp nc,L_50
    xor a
    ld (b2on),a
    ld a,(e2hp)
    or a
    jp z,L_50_kill
    dec a
    ld (e2hp),a
    jp z,L_50_kill
    call sfx_hit
    jp L_47
L_50_kill:
    ld a,2
    ld (e2on),a
    ld a,24
    ld (e2death),a
    call sfx_kill
    call score_inc
    jp L_47
L_50:
    ld a,(e3on)
    cp 1
    jp nz,L_51
    ld a,(e3x)
    add a,16
    ld b,a
    ld a,(b2x)
    ld c,17
    call near
    jp nc,L_51
    ld a,(e3y)
    add a,16
    ld b,a
    ld a,(b2y)
    ld c,15
    call near
    jp nc,L_51
    xor a
    ld (b2on),a
    ld a,(e3hp)
    or a
    jp z,L_51_kill
    dec a
    ld (e3hp),a
    jp z,L_51_kill
    call sfx_hit
    jp L_47
L_51_kill:
    ld a,2
    ld (e3on),a
    ld a,24
    ld (e3death),a
    call sfx_kill
    call score_inc
    jp L_47
L_51:
L_47:
    jp hazard
begin_boss:
    ld a,1
    ld (boss),a
    xor a
    ld (e0on),a
    xor a
    ld (e1on),a
    xor a
    ld (e2on),a
    xor a
    ld (e3on),a
    xor a
    ld (hon),a
    ld a,25
    ld (hdelay),a
    ld a,12
    ld (boss_delay),a
    xor a
    ld (boss_ready),a
    xor a
    ld (b0on),a
    xor a
    ld (b1on),a
    xor a
    ld (b2on),a
boss_logic:
    ld a,(boss_hp)
    cp 0
    jp z,boss_dying
    ld a,(px)
    cp 176
    jp c,boss_pos_ok
    ld a,176
    ld (px),a
boss_pos_ok:
    ld a,(b0on)
    cp 0
    jp z,L_52
    ld hl,eye_by_phase
    call phase_value
    ld b,a
    ld a,(b0x)
    cp b
    jp c,L_52
    xor a
    ld (b0on),a
    ld b,127
    ld a,(b0y)
    ld c,5
    call near
    jp nc,L_52
    ld a,(frame)
    and 31
    cp 6
    jp c,L_52
    ld a,(boss_ready)
    cp 0
    jp z,L_52
    ld a,(boss_hit)
    cp 0
    jp nz,L_52
    ld a,(boss_hp)
    cp 0
    jp z,L_52
    ld a,(boss_hp)
    add a,-1
    ld (boss_hp),a
    ld a,12
    ld (boss_hit),a
    ld a,(boss_hp)
    cp 0
    jp z,L_52_boss_dead
    call sfx_hit
    jp L_52_boss_score
L_52_boss_dead:
    call sfx_bossdead
L_52_boss_score:
    call score_inc
L_52:
    ld a,(b1on)
    cp 0
    jp z,L_53
    ld hl,eye_by_phase
    call phase_value
    ld b,a
    ld a,(b1x)
    cp b
    jp c,L_53
    xor a
    ld (b1on),a
    ld b,127
    ld a,(b1y)
    ld c,5
    call near
    jp nc,L_53
    ld a,(frame)
    and 31
    cp 6
    jp c,L_53
    ld a,(boss_ready)
    cp 0
    jp z,L_53
    ld a,(boss_hit)
    cp 0
    jp nz,L_53
    ld a,(boss_hp)
    cp 0
    jp z,L_53
    ld a,(boss_hp)
    add a,-1
    ld (boss_hp),a
    ld a,12
    ld (boss_hit),a
    ld a,(boss_hp)
    cp 0
    jp z,L_53_boss_dead
    call sfx_hit
    jp L_53_boss_score
L_53_boss_dead:
    call sfx_bossdead
L_53_boss_score:
    call score_inc
L_53:
    ld a,(b2on)
    cp 0
    jp z,L_54
    ld hl,eye_by_phase
    call phase_value
    ld b,a
    ld a,(b2x)
    cp b
    jp c,L_54
    xor a
    ld (b2on),a
    ld b,127
    ld a,(b2y)
    ld c,5
    call near
    jp nc,L_54
    ld a,(frame)
    and 31
    cp 6
    jp c,L_54
    ld a,(boss_ready)
    cp 0
    jp z,L_54
    ld a,(boss_hit)
    cp 0
    jp nz,L_54
    ld a,(boss_hp)
    cp 0
    jp z,L_54
    ld a,(boss_hp)
    add a,-1
    ld (boss_hp),a
    ld a,12
    ld (boss_hit),a
    ld a,(boss_hp)
    cp 0
    jp z,L_54_boss_dead
    call sfx_hit
    jp L_54_boss_score
L_54_boss_dead:
    call sfx_bossdead
L_54_boss_score:
    call score_inc
L_54:
    ld a,(phase)
    cp 3
    jp nc,mago_hazard
    call boss_attack
    ret
mago_hazard:
    ld a,(hon)
    cp 0
    jp z,mago_shoot
    ld a,(boss_hit)
    cp 0
    jp z,mago_hazard_tick
    ld a,(boss_hit)
    add a,-1
    ld (boss_hit),a
mago_hazard_tick:
    call hazard
    ret
mago_shoot:
    call boss_attack
    ret
boss_dying:
    xor a
    ld (bon),a
    xor a
    ld (hon),a
    ld a,(boss_end)
    add a,1
    ld (boss_end),a
    and 3
    ret nz
    jp sfx_bossdead
hazard:
    ld a,(hon)
    cp 0
    jp nz,haz_active
    ld a,(hdelay)
    or a
    jp z,haz_spawn
    dec a
    ld (hdelay),a
    ret
haz_active:
    ld a,(boss)
    cp 1
    jp z,haz_motion_done
    ld a,(advance)
    cp 0
    jp z,haz_motion_done
    ld a,(hscroll)
    add a,1
    ld (hscroll),a
    cp 4
    jp c,haz_motion_done
    xor a
    ld (hscroll),a
    ld a,(hx)
    sub 8
    jp c,haz_off
    ld (hx),a
haz_motion_done:
    ld a,(htype)
    cp 2
    jp z,lightning_warning
    cp 3
    jp z,lightning_strike
    ld a,(htype)
    cp 0
    jp z,haz_fall
    ld a,(hboom)
    dec a
    ld (hboom),a
    jp z,haz_off
    ret
haz_fall:
    ld a,(hy)
    cp 128
    jp nc,haz_impact
    add a,3
    cp 129
    jp nc,haz_impact
    ld (hy),a
    ld a,(px)
    and 252
    add a,13
    ld b,a
    ld a,(hx)
    add a,4
    ld c,10
    call near
    jp nc,haz_done
    ld a,(py)
    add a,16
    ld b,a
    ld a,(hy)
    add a,8
    ld c,19
    call near
    jp nc,haz_done
    call hurt
haz_done:
    ret
haz_impact:
    ld a,1
    ld (htype),a
    ld a,12
    ld (hboom),a
    ld a,128
    ld (hy),a
    jp sfx_meteor
rom_load_safe:
    push af
    push bc
    ld bc,32766
rom_wait_space:
    in a,(c)
    bit 0,a
    jp z,rom_wait_space
    pop bc
    pop af
    jp $0556
    db $00,$00,$00,$00,$00,$00
haz_off:
    xor a
    ld (hon),a
    call random
    and 31
    ld b,a
    ld a,(boss)
    or a
    ld a,72
    jp z,haz_delay
    ld a,18
haz_delay:
    add a,b
    ld (hdelay),a
    ret
lightning_start:
    ld a,1
    ld (hon),a
    ld a,2
    ld (htype),a
    ld a,64
    ld (hy),a
    ld a,14
    ld (hboom),a
    ld a,(hx)
    cp 200
    ret c
    ld a,192
    ld (hx),a
    ret
lightning_warning:
    ld a,(hboom)
    add a,-1
    ld (hboom),a
    ret nz
    ld a,3
    ld (htype),a
    ld a,4
    ld (hboom),a
    call sfx_lightning
    jp lightning_contact
lightning_strike:
    ld a,(hboom)
    add a,-1
    ld (hboom),a
    jp z,lightning_off
lightning_contact:
    ld a,(px)
    and 252
    add a,13
    ld b,a
    ld a,(hx)
    add a,4
    ld c,10
    call near
    ret nc
    call hurt
    ret
lightning_off:
    call haz_off
    ld a,(boss)
    cp 0
    jp z,lightning_done
    ld a,24
    ld (boss_delay),a
    ld a,(phase)
    cp 5
    jp nz,lightning_done
    ld a,14
    ld (boss_delay),a
lightning_done:
    ret
boss_attack:
    ld a,(boss_hit)
    or a
    jp z,boss_nohit
    dec a
    ld (boss_hit),a
boss_nohit:
    ld a,(bon)
    cp 0
    jp nz,boss_fire_active
    ld a,(boss_delay)
    or a
    jp z,boss_fire_spawn
    dec a
    ld (boss_delay),a
    ret
boss_fire_spawn:
    ld a,(phase)
    cp 3
    jp nc,mago_choose
    jp boss_horizontal
mago_choose:
    ld a,(boss_ready)
    cp 0
    jp z,boss_horizontal
    call random
    and 3
    jp nz,boss_horizontal
    ld a,(px)
    and 252
    add a,12
    and 248
    cp 200
    jp c,boss_target_ok
    ld a,192
boss_target_ok:
    ld (hx),a
    ld a,(phase)
    cp 4
    jp z,boss_meteor
    ld a,(phase)
    cp 3
    jp z,lightning_start
    call random
    and 1
    jp z,lightning_start
boss_meteor:
    ld a,1
    ld (hon),a
    xor a
    ld (htype),a
    ld a,40
    ld (hy),a
    ld a,18
    ld (boss_delay),a
    ret
boss_horizontal:
    ld a,1
    ld (boss_ready),a
    ld a,1
    ld (bon),a
    ld a,192
    ld (bx),a
    ld a,(lane)
    xor 1
    ld (lane),a
    or a
    ld a,136
    jp z,boss_fire_y
    ld a,112
boss_fire_y:
    ld (by),a
    jp sfx_bossfire
boss_fire_active:
    ld hl,speed_by_phase
    call phase_value
    ld b,a
    ld a,(bx)
    sub b
    jp c,boss_fire_off
    ld (bx),a
    ld a,(px)
    and 252
    add a,13
    ld b,a
    ld a,(bx)
    add a,8
    ld c,16
    call near
    ret nc
    ld a,(py)
    add a,31
    ld b,a
    ld a,(by)
    cp b
    jp nc,boss_fire_safe
    ld a,(py)
    add a,7
    ld b,a
    ld a,(keys)
    bit 2,a
    jp z,boss_body_top
    ld a,(jump)
    cp 255
    jp nz,boss_body_top
    ld a,(py)
    add a,16
    ld b,a
boss_body_top:
    ld a,(by)
    add a,7
    cp b
    jp c,boss_fire_safe
    call hurt
    jp boss_fire_off
boss_fire_safe:
    ret
boss_fire_off:
    xor a
    ld (bon),a
    ld a,18
    ld (boss_delay),a
    ld a,(phase)
    cp 1
    jp z,boss_delay_done
    ld a,(boss_burst)
    or a
    jp z,boss_new_burst
    dec a
    ld (boss_burst),a
    jp z,boss_new_burst
    ld a,4
    ld (boss_delay),a
    ld a,(phase)
    cp 5
    jp nz,boss_delay_done
    ld a,3
    ld (boss_delay),a
    ret
boss_new_burst:
    call random
    and 1
    add a,2
    ld b,a
    ld a,(phase)
    cp 5
    jp nz,boss_burst_store
    inc b
boss_burst_store:
    ld a,b
    ld (boss_burst),a
    ld a,30
    ld (boss_delay),a
    ld a,(phase)
    cp 5
    jp nz,boss_delay_done
    ld a,20
    ld (boss_delay),a
boss_delay_done:
    ret
random:
    call rng_step
    call rng_step
    call rng_step
    call rng_step
    call rng_step
    call rng_step
    call rng_step
rng_step:
    ld a,(rng_hi)
    ld b,a
    rrca
    and 127
    ld c,a
    ld a,(rng)
    rrca
    jp nc,rng_even
    ld d,1
    jp rng_low
rng_even:
    ld d,0
rng_low:
    and 127
    ld e,a
    ld a,b
    and 1
    jp z,rng_no_carry
    ld a,e
    or 128
    ld e,a
rng_no_carry:
    ld a,e
    ld (rng),a
    ld a,d
    or a
    ld a,c
    jp z,rng_high
    xor 180
rng_high:
    ld (rng_hi),a
    xor e
    ret
hurt:
    ld a,(cheat)
    cp 1
    jp z,hurt_done
    ld a,(death)
    cp 0
    jp nz,hurt_done
    ld a,(inv)
    cp 0
    jp nz,hurt_done
    ld a,(lives)
    or a
    jp z,hurt_done
    dec a
    ld (lives),a
    ld a,24
    ld (death),a
    ld a,23
    ld (pose),a
    ld a,112
    ld (py),a
    ld a,255
    ld (jump),a
    call sfx_death
hurt_done:
    ret
beep:
    ld a,18
    jp audio_request
sfx_hit:
    ld a,34
    jp audio_request
sfx_kill:
    ld a,52
    jp audio_request
sfx_bossfire:
    ld a,67
    jp audio_request
sfx_meteor:
    ld a,85
    jp audio_request
sfx_lightning:
    ld a,102
    jp audio_request
sfx_bonus:
    ld a,120
    jp audio_request
sfx_death:
    ld a,140
    jp audio_request
sfx_bossdead:
    ld a,159
    ld (sound),a
    ret
audio_request:
    push bc
    ld b,a
    and 240
    ld c,a
    ld a,(sound)
    and 240
    cp c
    jp nc,audio_keep
    ld a,b
    ld (sound),a
audio_keep:
    pop bc
    ret
audio_wait:
    ld a,(sound)
    or a
    jp z,audio_halt
    call audio_take
    jp audio_play
audio_take:
    ld b,a
    and 15
    dec a
    jp z,audio_last
    ld a,b
    dec a
    ld (sound),a
    jp audio_pitch
audio_last:
    xor a
    ld (sound),a
audio_pitch:
    ld a,b
    and 240
    rrca
    rrca
    rrca
    rrca
    ld e,a
    ld d,0
    ld hl,sfx_pitches
    add hl,de
    ld a,b
    and 15
    ld b,a
    ld a,15
    sub b
    add a,(hl)
    ld c,a
    ld a,(boss_end)
    or a
    ld a,c
    ret z
    bit 7,a
    ret z
    ld a,(boss_end)
    and 12
    add a,a
    add a,152
    ret
song_start:
    ld (song_ptr),hl
    xor a
    ld (song_left),a
    ld a,1
    ld (song_active),a
    ret
song_wait:
    push bc
    ld a,(song_active)
    or a
    jp z,song_silent
    ld a,(song_left)
    or a
    jp nz,song_note
    ld hl,(song_ptr)
    ld a,(hl)
    inc hl
    or a
    jp z,song_stop
    ld (song_left),a
    ld a,(hl)
    inc hl
    ld (song_pitch),a
    ld (song_ptr),hl
song_note:
    ld a,(song_left)
    add a,-1
    ld (song_left),a
    ld a,(song_pitch)
    or a
    jp z,song_silent
    call audio_play
    pop bc
    ret
song_stop:
    xor a
    ld (song_active),a
song_silent:
    halt
    pop bc
    ret
audio_play:
    ld e,a
    ld a,(23672)
    ld d,a
    ld h,0
    ld a,(audio_seed)
    ld l,a
audio_edge:
    ld a,e
    and 127
    ld c,a
    bit 7,e
    jp z,audio_toggle
    ld a,l
    rrca
    jp nc,audio_noise_even
    xor 184
audio_noise_even:
    ld l,a
    and 15
    add a,c
    ld c,a
audio_toggle:
    ld a,h
    xor 16
    ld h,a
    out ($fe),a
audio_poll:
    ld a,(23672)
    cp d
    jp nz,audio_done
    dec c
    jp nz,audio_poll
    jp audio_edge
audio_done:
    ld a,l
    ld (audio_seed),a
    xor a
    out ($fe),a
    ret
audio_halt:
    halt
    ret
audio_game:
    call audio_take
    ld e,a
    ld h,0
    ld a,(audio_seed)
    ld l,a
    ld b,176
audio_game_edge:
    ld a,e
    and 127
    ld c,a
    bit 7,e
    jp z,audio_game_toggle
    ld a,l
    rrca
    jp nc,audio_game_even
    xor 184
audio_game_even:
    ld l,a
    and 15
    add a,c
    ld c,a
audio_game_toggle:
    ld a,h
    xor 16
    ld h,a
    out ($fe),a
audio_game_poll:
    dec b
    jp z,audio_done
    nop
    nop
    nop
    dec c
    jp nz,audio_game_poll
    jp audio_game_edge
sfx_pitches:
    db $00,$88,$07,$9b,$90,$a8,$83,$18,$ab,$b0
audio_seed:
    db $a7
song_ptr:
    db $00,$00
song_left:
    db $00
song_pitch:
    db $00
song_active:
    db $00
song_title:
    db $07,$4f,$07,$42,$07,$4f,$07,$37,$0a,$3b,$05,$00,$07,$4f,$07,$42,$07,$34,$07,$37,$12,$4f,$05,$00
    db $07,$6b,$07,$59,$07,$4f,$07,$42,$07,$46,$14,$4f,$00
song_over:
    db $0c,$4f,$0c,$59,$0c,$6b,$1c,$7f,$00
song_win:
    db $07,$4f,$07,$42,$07,$34,$07,$27,$07,$2c,$18,$27,$00
score_inc:
    ld hl,score
    ld b,5
score_loop:
    inc (hl)
    ld a,(hl)
    cp 10
    jp c,score_bonus
    ld (hl),0
    inc hl
    dec b
    jp nz,score_loop
score_bonus:
    ld a,(bonus_left)
    dec a
    ld (bonus_left),a
    ret nz
    ld a,150
    ld (bonus_left),a
    ld a,(lives)
    cp 99
    ret nc
    inc a
    ld (lives),a
    jp sfx_bonus
screen_addr:
    rrca
    rrca
    rrca
    and 31
    ld b,a
    ld a,(shadow_mode)
    or a
    jp z,screen_addr_real
    ld a,c
    sub 40
    ld l,a
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld a,l
    or b
    ld l,a
    push de
    ld de,shadow
    add hl,de
    pop de
    ret
screen_addr_real:
    ld a,c
    and 56
    rlca
    rlca
    or b
    ld l,a
    ld a,c
    and 192
    rrca
    rrca
    rrca
    or 64
    ld h,a
    ld a,c
    and 7
    or h
    ld h,a
    ret
nextrow:
    bit 7,h
    jp nz,shadow_nextrow
    inc h
    ld a,h
    and 7
    ret nz
    ld a,l
    add a,32
    ld l,a
    ret c
    ld a,h
    sub 8
    ld h,a
    ret
shadow_nextrow:
    ld a,l
    add a,32
    ld l,a
    ret nc
    inc h
    ret
mark_dirty:
    bit 7,h
    ret z
    push af
    push bc
    push de
    push hl
    ld c,a
    ld a,l
    and 31
    ld e,a
    add a,c
    ld d,a
    ld a,l
    and 224
    rrca
    rrca
    rrca
    rrca
    rrca
    add a,b
    dec a
    rrca
    rrca
    rrca
    and 31
    inc a
    push af
    ld a,h
    db $d6 ; SUB n
mark_shadow_hi:
    db $f0
    add a,a
    ld c,a
    ld b,0
    ld hl,dirty
    add hl,bc
    pop af
    ld b,a
mark_band:
    ld a,e
    cp (hl)
    jp nc,mark_min_done
    ld (hl),a
mark_min_done:
    inc hl
    ld a,d
    cp (hl)
    jp c,mark_max_done
    ld (hl),a
mark_max_done:
    inc hl
    dec b
    jp nz,mark_band
    pop hl
    pop de
    pop bc
    pop af
    ret
render_begin:
    ld hl,used_cols
    ld (hl),0
    ld de,used_cols_plus1
    ld bc,31
    ldir
    ld a,1
    ld (shadow_mode),a
    ld hl,shadow_nextrow
    ld (sparse_nextrow_ptr),hl
    ld hl,dirty
    ld de,old_dirty
    ld bc,26
    ldir
    call reset_dirty
    ret
reset_dirty:
    ld hl,dirty
    ld (hl),32
    inc hl
    ld (hl),0
    ld hl,dirty
    ld de,dirty_plus2
    ld bc,24
    ldir
    ret
shadow_init:
    xor a
    ld (shadow_mode),a
    call reset_dirty
    ld hl,shadow
    ld (hl),0
    ld de,shadow_plus1
    ld bc,3327
    ldir
    ld hl,16544
    ld de,shadow
    ld a,24
shadow_init_row:
    push af
    push hl
    call copy32
    pop hl
    call nextrow
    pop af
    dec a
    jp nz,shadow_init_row
    ret
clear_shadow:
    ld hl,old_dirty_ground
    ld b,10
    db $0e ; LD C,n
clear_shadow_hi:
    db $f3
clear_shadow_loop:
    push bc
    ld a,(hl)
    inc hl
    ld e,a
    ld a,(hl)
    inc hl
    sub e
    jp c,clear_shadow_skip
    jp z,clear_shadow_skip
    push hl
    ld l,e
    ld h,c
    call clear_band
    pop hl
clear_shadow_skip:
    pop bc
    inc c
    dec b
    jp nz,clear_shadow_loop
    ret
clear_band:
    push hl
    ld b,a
    ld a,32
    sub b
    add a,a
    ld e,a
    ld d,0
    ld hl,clear32
    add hl,de
    ld (clear_call_ptr),hl
    pop hl
    ld b,8
    xor a
clear_band_row:
    push hl
    db $cd ; CALL nn
clear_call_ptr:
    dw 0
    pop hl
    ld a,l
    add a,32
    ld l,a
    xor a
    dec b
    jp nz,clear_band_row
    ret
clear32:
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ld (hl),a
    inc l
    ret
publish:
    xor a
    ld (shadow_mode),a
    ld hl,nextrow
    ld (sparse_nextrow_ptr),hl
    ld hl,dirty
    ld de,old_dirty
    ld b,13
    ld c,40
publish_loop:
    push bc
    ld a,(de)
    cp (hl)
    jp c,pub_min_ok
    ld a,(hl)
pub_min_ok:
    ld b,a
    inc hl
    inc de
    ld a,(de)
    cp (hl)
    jp nc,pub_max_ok
    ld a,(hl)
pub_max_ok:
    inc hl
    inc de
    sub b
    jp c,publish_skip
    jp z,publish_skip
    push hl
    push de
    push af
    ld a,b
    rlca
    rlca
    rlca
    call screen_addr
    ex de,hl
    ld a,c
    sub 40
    rrca
    rrca
    rrca
    db $c6 ; ADD A,n
pub_shadow_hi:
    db $f0
    ld h,a
    ld a,e
    and 31
    ld l,a
    pop af
    call publish_band
    pop de
    pop hl
publish_skip:
    pop bc
    ld a,c
    add a,8
    ld c,a
    dec b
    jp nz,publish_loop
    ret
publish_band:
    ld (pub_width),a
    push hl
    push de
    ld b,a
    ld a,32
    sub b
    add a,a
    ld e,a
    ld d,0
    ld hl,copy32
    add hl,de
    ld (pub_copy_ptr),hl
    pop de
    pop hl
    ld a,8
pub_row:
    push af
    ld bc,32
    db $cd ; CALL nn
pub_copy_ptr:
    dw 0
    add hl,bc
    ld a,e
    db $d6 ; SUB n
pub_width:
    db $00
    ld e,a
    jp c,pub_row_skip_inc
    inc d
pub_row_skip_inc:
    pop af
    dec a
    jp nz,pub_row
    ret
copy32:
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ret
erase_5_32:
    ld b,32
    ld a,5
    call mark_dirty
erase_5_32_row:
    ld (hl),0
    inc l
    ld (hl),0
    inc l
    ld (hl),0
    inc l
    ld (hl),0
    inc l
    ld (hl),0
    ld a,l
    sub 4
    ld l,a
    call nextrow
    dec b
    jp nz,erase_5_32_row
    ret
erase_1_4:
    ld b,4
    ld a,1
    call mark_dirty
erase_1_4_row:
    ld (hl),0
    call nextrow
    dec b
    jp nz,erase_1_4_row
    ret
draw_1_4:
    ld b,4
    ld a,1
    call mark_dirty
draw_1_4_row:
    ld a,(de)
    or (hl)
    ld (hl),a
    inc de
    call nextrow
    dec b
    jp nz,draw_1_4_row
    ret
erase_1_16:
    ld b,16
    ld a,1
    call mark_dirty
erase_1_16_row:
    ld (hl),0
    call nextrow
    dec b
    jp nz,erase_1_16_row
    ret
draw_1_16:
    ld b,16
    ld a,1
    call mark_dirty
draw_1_16_row:
    ld a,(de)
    or (hl)
    ld (hl),a
    inc de
    call nextrow
    dec b
    jp nz,draw_1_16_row
    ret
erase_2_8:
    ld b,8
    ld a,2
    call mark_dirty
erase_2_8_row:
    ld (hl),0
    inc l
    ld (hl),0
    ld a,l
    sub 1
    ld l,a
    call nextrow
    dec b
    jp nz,erase_2_8_row
    ret
draw_2_8:
    ld b,8
    ld a,2
    call mark_dirty
draw_2_8_row:
    ld a,(de)
    or (hl)
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    or (hl)
    ld (hl),a
    inc de
    ld a,l
    sub 1
    ld l,a
    call nextrow
    dec b
    jp nz,draw_2_8_row
    ret
erase_2_16:
    ld b,16
    ld a,2
    call mark_dirty
erase_2_16_row:
    ld (hl),0
    inc l
    ld (hl),0
    ld a,l
    sub 1
    ld l,a
    call nextrow
    dec b
    jp nz,erase_2_16_row
    ret
draw_2_16:
    ld b,16
    ld a,2
    call mark_dirty
draw_2_16_row:
    ld a,(de)
    or (hl)
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    or (hl)
    ld (hl),a
    inc de
    ld a,l
    sub 1
    ld l,a
    call nextrow
    dec b
    jp nz,draw_2_16_row
    ret
erase_6_64:
    ld b,64
    ld a,6
    call mark_dirty
erase_6_64_row:
    ld (hl),0
    inc l
    ld (hl),0
    inc l
    ld (hl),0
    inc l
    ld (hl),0
    inc l
    ld (hl),0
    inc l
    ld (hl),0
    ld a,l
    sub 5
    ld l,a
    call nextrow
    dec b
    jp nz,erase_6_64_row
    ret
draw_6_64:
    ld b,64
    ld a,6
    call mark_dirty
draw_6_64_row:
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    ld (hl),a
    inc de
    ld a,l
    sub 5
    ld l,a
    call nextrow
    dec b
    jp nz,draw_6_64_row
    ret
draw_6_48:
    ld b,48
    ld a,6
    call mark_dirty
draw_6_48_row:
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    ld (hl),a
    inc de
    ld a,l
    sub 5
    ld l,a
    call nextrow
    dec b
    jp nz,draw_6_48_row
    ret
draw_1_8:
    ld b,8
    ld a,1
    call mark_dirty
draw_1_8_row:
    ld a,(de)
    ld (hl),a
    inc de
    call nextrow
    dec b
    jp nz,draw_1_8_row
    ret
moon_draw:
    ld hl,16471
    ld de,moon_bitmap
    jp draw_6_48
moon_restore:
    ld a,(hy)
    ld c,a
    ld a,(hx)
    call screen_addr
    push hl
    ld a,(hy)
    sub 16
    ld l,a
    ld h,0
    add hl,hl
    ld d,h
    ld e,l
    add hl,hl
    add hl,de
    ld a,(hx)
    rrca
    rrca
    rrca
    and 31
    sub 23
    ld e,a
    ld d,0
    add hl,de
    ld de,moon_bitmap
    add hl,de
    ex de,hl
    pop hl
    ld a,(hy)
    ld b,a
    ld a,64
    sub b
    cp 16
    jp c,moon_count
    ld a,16
moon_count:
    ld b,a
moon_restore_row:
    ld a,(de)
    ld (hl),a
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    call nextrow
    dec b
    jp nz,moon_restore_row
    ret
city_restore:
    ld a,(hy)
    ld c,a
    ld a,(hx)
    call screen_addr
    push hl
    ld a,(hy)
    sub 40
    ld l,a
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld a,(hx)
    rrca
    rrca
    rrca
    and 31
    ld e,a
    ld d,0
    add hl,de
    ld de,moon_bitmap
    add hl,de
    ex de,hl
    pop hl
    ld a,(hy)
    ld b,a
    ld a,64
    sub b
    cp 16
    jp c,city_count
    ld a,16
city_count:
    ld b,a
city_restore_row:
    ld a,(de)
    ld (hl),a
    push hl
    ld hl,32
    add hl,de
    ex de,hl
    pop hl
    call nextrow
    dec b
    jp nz,city_restore_row
    ret
actor_draw:
    push af
    call screen_addr
    ld b,32
    ld a,5
    call mark_dirty
    call fast_select
    pop af
    bit 2,a
    jp z,actor_ptr
    inc de
    inc de
actor_ptr:
    push hl
    ex de,hl
    ld e,(hl)
    inc hl
    ld d,(hl)
    pop hl
    ld b,32
sparse_row:
    ld a,(de)
    inc de
    cp 48
    jp nc,sparse_dict
sparse_code:
    db $c6 ; ADD A,n
span_offset:
    db $00
    ld (sparse_patch),a
sparse_dispatch:
    jp sparse_table
sparse_patch equ sparse_dispatch+1
sparse_next:
    bit 7,b
    jp z,sparse_advance
    pop de
    ld a,b
    and 127
    ld b,a
sparse_advance:
    db $cd ; CALL nn
sparse_nextrow_ptr:
    dw nextrow
    dec b
    jp nz,sparse_row
    ret
sparse_dict:
    push de
    push hl
    ld l,a
    ld h,0
    add hl,hl
    ld de,row_dict_base
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    pop hl
    ld a,b
    or 128
    ld b,a
    ld a,(de)
    inc de
    jp sparse_code
fast_select:
    xor a
    ld (span_offset),a
    bit 7,h
    ret z
    ld a,(boss)
    cp 0
    jp z,fast_check
    ret
fast_check:
    push hl
    push de
    ld a,l
    and 31
    ld e,a
    ld d,0
    ld hl,used_cols
    add hl,de
    xor a
    or (hl)
    ld (hl),1
    inc l
    or (hl)
    ld (hl),1
    inc l
    or (hl)
    ld (hl),1
    inc l
    or (hl)
    ld (hl),1
    inc l
    or (hl)
    ld (hl),1
    jp nz,fast_done
    ld a,48
    ld (span_offset),a
fast_done:
    pop de
    pop hl
    ret
input_joy:
    ld a,(joy)
    cp 2
    jp z,input_done
    ld bc,31
    in a,(c)
    cp 32
    ret nc
    ld d,a
    in a,(c)
    cp d
    ret nz
    in a,(c)
    cp d
    ret nz
    ld a,d
    and 3
    cp 3
    ret z
    ld a,d
    and 12
    cp 12
    ret z
    ld a,(keys)
    bit 4,a
    jp nz,input_merge
    bit 4,d
    jp z,input_merge
    ld a,1
    ld (joy_source),a
input_merge:
    ld a,(keys)
    or d
    ld (keys),a
input_done:
    ret
select_control_wait:
    ld a,(joy)
    or a
    jp nz,song_wait
    ld a,(joy_source)
    or a
    ld a,2
    jp z,control_selected
    ld a,1
control_selected:
    ld (joy),a
    jp song_wait
joy_source:
    db $00
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
sparse_table:
    jp sparse_next
    jp sparse_span1
    jp sparse_span2
    jp sparse_span3
    jp sparse_span4
    jp sparse_span5
    jp sparse_span6
    jp sparse_span7
    jp sparse_span8
    jp sparse_span9
    jp sparse_span10
    jp sparse_span11
    jp sparse_span12
    jp sparse_span13
    jp sparse_span14
    jp sparse_span15
    jp sparse_next
    jp fast_span1
    jp fast_span2
    jp fast_span3
    jp fast_span4
    jp fast_span5
    jp fast_span6
    jp fast_span7
    jp fast_span8
    jp fast_span9
    jp fast_span10
    jp fast_span11
    jp fast_span12
    jp fast_span13
    jp fast_span14
    jp fast_span15
sparse_span1:
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    jp sparse_next
sparse_span2:
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    dec l
    jp sparse_next
sparse_span3:
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    dec l
    dec l
    jp sparse_next
sparse_span4:
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    dec l
    dec l
    dec l
    jp sparse_next
sparse_span5:
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    dec l
    dec l
    dec l
    dec l
    jp sparse_next
sparse_span6:
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    dec l
    jp sparse_next
sparse_span7:
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    dec l
    dec l
    jp sparse_next
sparse_span8:
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    dec l
    dec l
    dec l
    jp sparse_next
sparse_span9:
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    dec l
    dec l
    dec l
    dec l
    jp sparse_next
sparse_span10:
    inc l
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    dec l
    dec l
    jp sparse_next
sparse_span11:
    inc l
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    dec l
    dec l
    dec l
    jp sparse_next
sparse_span12:
    inc l
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    dec l
    dec l
    dec l
    dec l
    jp sparse_next
sparse_span13:
    inc l
    inc l
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    dec l
    dec l
    dec l
    jp sparse_next
sparse_span14:
    inc l
    inc l
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    dec l
    dec l
    dec l
    dec l
    jp sparse_next
sparse_span15:
    inc l
    inc l
    inc l
    inc l
    ld a,(de)
    and (hl)
    ld c,a
    inc de
    ld a,(de)
    or c
    ld (hl),a
    inc de
    dec l
    dec l
    dec l
    dec l
    jp sparse_next
fast_span1:
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    jp sparse_next
fast_span2:
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    dec l
    jp sparse_next
fast_span3:
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    dec l
    dec l
    jp sparse_next
fast_span4:
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    dec l
    dec l
    dec l
    jp sparse_next
fast_span5:
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    dec l
    dec l
    dec l
    dec l
    jp sparse_next
fast_span6:
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    dec l
    jp sparse_next
fast_span7:
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    dec l
    dec l
    jp sparse_next
fast_span8:
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    dec l
    dec l
    dec l
    jp sparse_next
fast_span9:
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    dec l
    dec l
    dec l
    dec l
    jp sparse_next
fast_span10:
    inc l
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    dec l
    dec l
    jp sparse_next
fast_span11:
    inc l
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    dec l
    dec l
    dec l
    jp sparse_next
fast_span12:
    inc l
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    dec l
    dec l
    dec l
    dec l
    jp sparse_next
fast_span13:
    inc l
    inc l
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    dec l
    dec l
    dec l
    jp sparse_next
fast_span14:
    inc l
    inc l
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    dec l
    dec l
    dec l
    dec l
    jp sparse_next
fast_span15:
    inc l
    inc l
    inc l
    inc l
    inc de
    ld a,(de)
    ld (hl),a
    inc de
    dec l
    dec l
    dec l
    dec l
    jp sparse_next
erase_lightning:
    ld a,(hx)
    ld c,64
    call screen_addr
    ld b,80
    ld a,1
    call mark_dirty
erase_lightning_row:
    ld (hl),0
    call nextrow
    dec b
    jp nz,erase_lightning_row
    ret
draw_lightning:
    ld a,(hx)
    ld c,64
    call screen_addr
    ld de,lightning_warn
    ld a,(htype)
    cp 2
    jp z,lightning_image
    ld de,lightning0
    ld a,(frame)
    bit 0,a
    jp z,lightning_image
    ld de,lightning1
lightning_image:
    push de
    call draw_1_16
    pop de
    push de
    call draw_1_16
    pop de
    push de
    call draw_1_16
    pop de
    push de
    call draw_1_16
    pop de
    push de
    call draw_1_16
    pop de
    ret
erase_all:
    ld a,(shadow_mode)
    or a
    jp z,erase_direct
    call clear_shadow
    ld a,(hon)
    cp 0
    jp z,erase_shadow_done
    ld a,(htype)
    cp 0
    jp nz,erase_shadow_done
    ld a,(hy)
    cp 64
    jp nc,erase_shadow_done
    ld a,(hy)
    ld c,a
    ld a,(hx)
    call screen_addr
    jp erase_meteor
erase_shadow_done:
    ret
erase_direct:
    ld a,(py)
    ld c,a
    ld a,(px)
    call screen_addr
    call erase_5_32
    ld a,(e0on)
    cp 0
    jp z,L_55
    ld a,(e0y)
    ld c,a
    ld a,(e0x)
    call screen_addr
    call erase_5_32
L_55:
    ld a,(e1on)
    cp 0
    jp z,L_56
    ld a,(e1y)
    ld c,a
    ld a,(e1x)
    call screen_addr
    call erase_5_32
L_56:
    ld a,(e2on)
    cp 0
    jp z,L_57
    ld a,(e2y)
    ld c,a
    ld a,(e2x)
    call screen_addr
    call erase_5_32
L_57:
    ld a,(e3on)
    cp 0
    jp z,L_58
    ld a,(e3y)
    ld c,a
    ld a,(e3x)
    call screen_addr
    call erase_5_32
L_58:
    ld a,(b0on)
    cp 0
    jp z,L_59
    ld a,(b0y)
    ld c,a
    ld a,(b0x)
    call screen_addr
    call erase_1_4
L_59:
    ld a,(b1on)
    cp 0
    jp z,L_60
    ld a,(b1y)
    ld c,a
    ld a,(b1x)
    call screen_addr
    call erase_1_4
L_60:
    ld a,(b2on)
    cp 0
    jp z,L_61
    ld a,(b2y)
    ld c,a
    ld a,(b2x)
    call screen_addr
    call erase_1_4
L_61:
    ld a,(hon)
    cp 0
    jp z,L_62
    ld a,(htype)
    cp 2
    jp nc,erase_lightning_call
    ld a,(hy)
    ld c,a
    ld a,(hx)
    call screen_addr
    ld a,(htype)
    cp 0
    jp z,erase_meteor
    call erase_2_16
    jp erase_haz_done
erase_meteor:
    call erase_1_16
    ld a,(hy)
    cp 64
    jp nc,erase_haz_done
    ld a,(phase)
    cp 1
    jp nz,erase_moon
    jp erase_moon_actual
erase_moon:
    jp erase_city
erase_moon_actual:
    ld a,(hx)
    cp 184
    jp c,erase_haz_done
    cp 232
    jp nc,erase_haz_done
    call moon_restore
    jp erase_haz_done
erase_city:
    call city_restore
    jp erase_haz_done
erase_lightning_call:
    call erase_lightning
erase_haz_done:
L_62:
    ld a,(bon)
    cp 0
    jp z,L_63
    ld a,(by)
    ld c,a
    ld a,(bx)
    call screen_addr
    call erase_2_8
L_63:
    ret
draw_all:
    ld a,(boss)
    cp 0
    jp z,draw_enemies
    ld a,208
    ld c,80
    call screen_addr
    ld a,(boss_hp)
    cp 0
    jp z,boss_death_draw
    ld de,boss_closed
    ld a,(frame)
    and 31
    cp 6
    jp c,boss_img
    ld de,boss_hit_img
    ld a,(boss_hit)
    cp 7
    jp nc,boss_img
boss_not_hit:
    ld de,boss_mouth
    ld a,(boss_delay)
    cp 8
    jp c,boss_img
    ld de,boss_open
    jp boss_normal
boss_death_draw:
    ld a,(boss_end)
    cp 48
    jp nc,boss_death_clear
    bit 2,a
    jp nz,boss_death_clear
    ld de,boss_open
    call draw_6_64
    jp boss_death_fx
boss_death_clear:
    call erase_6_64
boss_death_fx:
    ld hl,death_by_phase
    call phase_value
    sub 4
    ld b,a
    ld a,(boss_end)
    cp b
    jp nc,death_sparks
    ld a,0
    call death_burst
    ld a,8
    call death_burst
    ld a,16
    call death_burst
    ld a,24
    call death_burst
    ld a,(phase)
    cp 5
    jp nz,death_final_normal
    ld a,4
    call death_burst
    ld a,20
    call death_burst
    ld a,(boss_end)
    cp 84
    jp c,death_sparks
    jp death_final_flash
death_final_normal:
    ld a,(boss_end)
    cp 63
    jp c,death_sparks
death_final_flash:
    ld de,death_blast2
    push de
    ld a,224
    ld c,96
    call screen_addr
    call draw_2_16
    pop de
    push de
    ld a,224
    ld c,128
    call screen_addr
    call draw_2_16
    pop de
    push de
    ld a,208
    ld c,112
    call screen_addr
    call draw_2_16
    pop de
    push de
    ld a,240
    ld c,112
    call screen_addr
    call draw_2_16
    pop de
death_sparks:
    ld a,0
    call death_spark
    ld a,4
    call death_spark
    ld a,8
    call death_spark
    jp draw_player
death_burst:
    ld b,a
    ld a,(boss_end)
    add a,b
    ld b,a
    and 7
    ld e,a
    ld d,0
    ld hl,effect_anim
    add hl,de
    ld a,(hl)
    push bc
    add a,a
    ld e,a
    ld d,0
    ld hl,death_blast_table
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    pop bc
    push de
    ld a,b
    and 28
    rrca
    ld e,a
    ld d,0
    ld hl,death_positions
    add hl,de
    ld a,(hl)
    inc hl
    ld c,(hl)
    call screen_addr
    pop de
    jp draw_2_16
death_spark:
    ld b,a
    ld a,(boss_end)
    add a,b
    bit 1,a
    ret z
    ld b,a
    and 12
    add a,184
    push af
    ld a,b
    and 24
    rlca
    add a,80
    ld c,a
    pop af
    call screen_addr
    ld de,spark_bitmap
    jp draw_1_8
boss_normal:
    call draw_6_64
    jp draw_player
boss_img:
    push de
    ld de,boss_open
    call draw_6_64
    pop hl
    ld a,(hl)
    inc hl
    ld c,(hl)
    inc hl
    ld b,(hl)
    inc hl
    push bc
    ex de,hl
    call screen_addr
    pop bc
    call boss_patch
    jp draw_player
boss_patch:
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    ld a,(de)
    ld (hl),a
    inc de
    dec l
    call nextrow
    dec b
    jp nz,boss_patch
    ret
draw_enemies:
    ld a,(e0on)
    cp 0
    jp z,L_64
    ld a,(e0on)
    cp 2
    jp z,L_69
    ld a,(e0anim)
    rrca
    rrca
    and 7
    jp L_66
L_69:
    ld a,(e0death)
    ld e,a
    ld d,0
    ld hl,zdeath_pose
    add hl,de
    ld a,(hl)
L_66:
    ld b,a
    ld a,(e0species)
    cp 1
    jp z,e0_alien_draw
    ld a,(e0dir)
    or a
    ld a,b
    jp nz,L_67
    add a,a
    ld e,a
    ld d,0
    ld hl,etable_left
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    jp L_68
L_67:
    add a,a
    ld e,a
    ld d,0
    ld hl,etable_right
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    jp L_68
e0_alien_draw:
    ld a,(e0dir)
    or a
    ld a,b
    jp nz,e0_alien_right
    add a,a
    ld e,a
    ld d,0
    ld hl,atable_left
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    jp L_68
e0_alien_right:
    add a,a
    ld e,a
    ld d,0
    ld hl,atable_right
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
L_68:
    ld a,(e0on)
    cp 2
    jp z,e0_drawdead
    ld a,(e0y)
    ld c,a
    ld a,(e0x)
    call actor_draw
    jp L_64
e0_drawdead:
    ld a,(e0y)
    ld c,a
    ld a,(e0x)
    and 248
    call actor_draw
L_64:
    ld a,(e1on)
    cp 0
    jp z,L_70
    ld a,(e1on)
    cp 2
    jp z,L_75
    ld a,(e1anim)
    rrca
    rrca
    and 7
    jp L_72
L_75:
    ld a,(e1death)
    ld e,a
    ld d,0
    ld hl,zdeath_pose
    add hl,de
    ld a,(hl)
L_72:
    ld b,a
    ld a,(e1species)
    cp 1
    jp z,e1_alien_draw
    ld a,(e1dir)
    or a
    ld a,b
    jp nz,L_73
    add a,a
    ld e,a
    ld d,0
    ld hl,etable_left
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    jp L_74
L_73:
    add a,a
    ld e,a
    ld d,0
    ld hl,etable_right
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    jp L_74
e1_alien_draw:
    ld a,(e1dir)
    or a
    ld a,b
    jp nz,e1_alien_right
    add a,a
    ld e,a
    ld d,0
    ld hl,atable_left
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    jp L_74
e1_alien_right:
    add a,a
    ld e,a
    ld d,0
    ld hl,atable_right
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
L_74:
    ld a,(e1on)
    cp 2
    jp z,e1_drawdead
    ld a,(e1y)
    ld c,a
    ld a,(e1x)
    call actor_draw
    jp L_70
e1_drawdead:
    ld a,(e1y)
    ld c,a
    ld a,(e1x)
    and 248
    call actor_draw
L_70:
    ld a,(e2on)
    cp 0
    jp z,L_76
    ld a,(e2on)
    cp 2
    jp z,L_81
    ld a,(e2anim)
    rrca
    rrca
    and 7
    jp L_78
L_81:
    ld a,(e2death)
    ld e,a
    ld d,0
    ld hl,zdeath_pose
    add hl,de
    ld a,(hl)
L_78:
    ld b,a
    ld a,(e2species)
    cp 1
    jp z,e2_alien_draw
    ld a,(e2dir)
    or a
    ld a,b
    jp nz,L_79
    add a,a
    ld e,a
    ld d,0
    ld hl,etable_left
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    jp L_80
L_79:
    add a,a
    ld e,a
    ld d,0
    ld hl,etable_right
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    jp L_80
e2_alien_draw:
    ld a,(e2dir)
    or a
    ld a,b
    jp nz,e2_alien_right
    add a,a
    ld e,a
    ld d,0
    ld hl,atable_left
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    jp L_80
e2_alien_right:
    add a,a
    ld e,a
    ld d,0
    ld hl,atable_right
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
L_80:
    ld a,(e2on)
    cp 2
    jp z,e2_drawdead
    ld a,(e2y)
    ld c,a
    ld a,(e2x)
    call actor_draw
    jp L_76
e2_drawdead:
    ld a,(e2y)
    ld c,a
    ld a,(e2x)
    and 248
    call actor_draw
L_76:
    ld a,(e3on)
    cp 0
    jp z,L_82
    ld a,(e3on)
    cp 2
    jp z,L_87
    ld a,(e3anim)
    rrca
    rrca
    and 7
    jp L_84
L_87:
    ld a,(e3death)
    ld e,a
    ld d,0
    ld hl,zdeath_pose
    add hl,de
    ld a,(hl)
L_84:
    ld b,a
    ld a,(e3species)
    cp 1
    jp z,e3_alien_draw
    ld a,(e3dir)
    or a
    ld a,b
    jp nz,L_85
    add a,a
    ld e,a
    ld d,0
    ld hl,etable_left
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    jp L_86
L_85:
    add a,a
    ld e,a
    ld d,0
    ld hl,etable_right
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    jp L_86
e3_alien_draw:
    ld a,(e3dir)
    or a
    ld a,b
    jp nz,e3_alien_right
    add a,a
    ld e,a
    ld d,0
    ld hl,atable_left
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    jp L_86
e3_alien_right:
    add a,a
    ld e,a
    ld d,0
    ld hl,atable_right
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
L_86:
    ld a,(e3on)
    cp 2
    jp z,e3_drawdead
    ld a,(e3y)
    ld c,a
    ld a,(e3x)
    call actor_draw
    jp L_82
e3_drawdead:
    ld a,(e3y)
    ld c,a
    ld a,(e3x)
    and 248
    call actor_draw
L_82:
draw_player:
    ld a,(death)
    or a
    jp nz,draw_ace
    ld a,(inv)
    and 8
    jp nz,draw_shots
draw_ace:
    ld a,(pose)
    add a,a
    ld e,a
    ld d,0
    ld hl,ptable
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    ld a,(death)
    cp 0
    jp z,draw_alive
    ld a,(py)
    ld c,a
    ld a,(px)
    and 248
    call actor_draw
    jp draw_shots
draw_alive:
    ld a,(py)
    ld c,a
    ld a,(px)
    call actor_draw
draw_shots:
    ld a,(b0on)
    cp 0
    jp z,L_88
    ld a,(b0y)
    ld c,a
    ld a,(b0x)
    call screen_addr
    ld de,bullet
    ld a,(b0x)
    bit 2,a
    jp z,bullet0_ready
    ld de,bullet_shift
bullet0_ready:
    call draw_1_4
L_88:
    ld a,(b1on)
    cp 0
    jp z,L_89
    ld a,(b1y)
    ld c,a
    ld a,(b1x)
    call screen_addr
    ld de,bullet
    ld a,(b1x)
    bit 2,a
    jp z,bullet1_ready
    ld de,bullet_shift
bullet1_ready:
    call draw_1_4
L_89:
    ld a,(b2on)
    cp 0
    jp z,L_90
    ld a,(b2y)
    ld c,a
    ld a,(b2x)
    call screen_addr
    ld de,bullet
    ld a,(b2x)
    bit 2,a
    jp z,bullet2_ready
    ld de,bullet_shift
bullet2_ready:
    call draw_1_4
L_90:
    ld a,(hon)
    cp 0
    jp z,L_91
    ld a,(htype)
    cp 2
    jp nc,draw_lightning_call
    ld a,(hy)
    ld c,a
    ld a,(hx)
    call screen_addr
    ld a,(htype)
    cp 0
    jp z,draw_meteor
    push hl
    ld a,(hboom)
    ld e,a
    ld d,0
    ld hl,hboom_pose
    add hl,de
    ld a,(hl)
    add a,a
    ld e,a
    ld d,0
    ld hl,explosion_table
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    pop hl
    call draw_2_16
    jp draw_haz_done
draw_meteor:
    push hl
    ld a,(frame)
    and 7
    ld e,a
    ld d,0
    ld hl,effect_anim
    add hl,de
    ld a,(hl)
    add a,a
    ld e,a
    ld d,0
    ld hl,meteor_table
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    pop hl
    call draw_1_16
    jp draw_haz_done
draw_lightning_call:
    call draw_lightning
draw_haz_done:
L_91:
    ld a,(bon)
    cp 0
    jp z,L_92
    ld a,(by)
    ld c,a
    ld a,(bx)
    call screen_addr
    push hl
    ld a,(frame)
    and 7
    ld e,a
    ld d,0
    ld hl,effect_anim
    add hl,de
    ld a,(hl)
    add a,a
    ld e,a
    ld d,0
    ld hl,bossfire_table
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    pop hl
    call draw_2_8
L_92:
    ret
ground:
    ld a,(boss)
    cp 0
    jp z,ground_scroll
    ret
ground_scroll:
    ld a,(advance)
    cp 0
    jp z,ground_idle
    ld a,(scroll)
    add a,2
    cp 192
    jp c,ground_store
    xor a
ground_store:
    ld (scroll),a
ground_render:
    ld a,(scroll)
    and 6
    ld e,a
    ld d,0
    ld hl,floor_ptr
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    push de
    ld a,(scroll)
    rrca
    rrca
    rrca
    and 31
    ld (ground_offset),a
    add a,a
    ld e,a
    ld d,0
    ld hl,ground_copy24
    add hl,de
    ld (ground_first),hl
    ld hl,ground_copy_end
    or a
    sbc hl,de
    ld (ground_second),hl
    pop hl
    ld de,20544
    call ground_row
    ld de,20800
    call ground_row
    ld de,21056
    call ground_row
    ld de,21312
    call ground_row
    ld de,21568
    call ground_row
    ld de,21824
    call ground_row
    ld de,22080
    call ground_row
    ld de,22336
    call ground_row
    ld de,20576
    call ground_row
    ld de,20832
    call ground_row
    ld de,21088
    call ground_row
    ld de,21344
    call ground_row
    ld de,21600
    call ground_row
    ld de,21856
    call ground_row
    ld de,22112
    call ground_row
    ld de,22368
    call ground_row
    ld de,20608
    call ground_row
    ld de,20864
    call ground_row
    ld de,21120
    call ground_row
    ld de,21376
    call ground_row
    ld de,21632
    call ground_row
    ld de,21888
    call ground_row
    ld de,22144
    call ground_row
    ld de,22400
    call ground_row
ground_idle:
    ret
ground_row:
    push de
    push hl
    db $01 ; LD BC,nn
ground_offset:
    dw 0
    add hl,bc
    db $cd ; CALL nn
ground_first:
    dw 0
    ld (ground_next),hl
    pop hl
    db $cd ; CALL nn
ground_second:
    dw 0
    pop hl
    call ground_copy8
    ld hl,(ground_next)
    ret
ground_next:
    dw 0
ground_copy24:
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
ground_copy8:
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
ground_copy_end:
    ret
hud_if_dirty:
    ld a,(lives)
    ld b,a
    ld a,(hud_lives)
    cp b
    jp nz,hud
    ld hl,score
    ld de,hud_score
    ld b,5
hud_check:
    ld a,(de)
    cp (hl)
    jp nz,hud
    inc hl
    inc de
    dec b
    jp nz,hud_check
    ret
hud:
    ld a,(lives)
    ld (hud_lives),a
    ld hl,score
    ld de,hud_score
    ld bc,5
    ldir
    ld a,(score0)
    call digit_ptr
    ld hl,21958
    call draw_1_8
    ld a,(score1)
    call digit_ptr
    ld hl,21957
    call draw_1_8
    ld a,(score2)
    call digit_ptr
    ld hl,21956
    call draw_1_8
    ld a,(score3)
    call digit_ptr
    ld hl,21955
    call draw_1_8
    ld a,(score4)
    call digit_ptr
    ld hl,21954
    call draw_1_8
    ld a,(lives)
    ld b,0
life_digits:
    cp 10
    jp c,life_digits_done
    sub 10
    inc b
    jp life_digits
life_digits_done:
    push af
    ld a,b
    call digit_ptr
    ld hl,21967
    call draw_1_8
    pop af
    call digit_ptr
    ld hl,21968
    call draw_1_8
    ret
digit_ptr:
    add a,a
    add a,a
    add a,a
    ld e,a
    ld d,0
    ld hl,digits
    add hl,de
    ex de,hl
    ret
gameover:
    ld hl,song_over
    call song_start
    ld de,msg_over
    jp end_screen
win:
    ld hl,song_win
    call song_start
    ld a,(phase)
    cp 5
    jp z,final_victory
    ld de,msg_win
    call show_message
    ld a,(phase)
    call digit_ptr
    ld hl,16623
    call draw_1_8
    jp end_hold
end_screen:
    call show_message
end_hold:
    ld b,150
wait_end:
    call song_wait
    dec b
    jp nz,wait_end
release_end:
    call input
    ld a,(keys)
    bit 4,a
    jp nz,release_end
press_end:
    halt
    call input
    ld a,(keys)
    bit 4,a
    jp z,press_end
    ld a,(lives)
    cp 0
    jp z,title
    ld a,(phase)
    cp 5
    jp z,title
    jp next_phase
final_victory:
    call load_final_screen
wait_final:
    ld b,150
    jp wait_end
show_message:
    ld hl,16618
    ld b,8
msg_row:
    push bc
    ld c,12
msg_col:
    ld a,(de)
    ld (hl),a
    inc de
    inc l
    dec c
    jp nz,msg_col
    ld a,l
    sub 12
    ld l,a
    call nextrow
    pop bc
    dec b
    jp nz,msg_row
    ret
vars:
px:
    db $00
vars_plus1:
py:
    db $00
lives:
    db $00
boss_hp:
    db $00
jump:
    db $00
qheld:
    db $00
pose:
    db $00
keys:
    db $00
joy:
    db $00
inv:
    db $00
inv_last:
    db $00
bonus_left:
    db $00
cool:
    db $00
frame:
    db $00
last:
    db $00
scroll:
    db $00
boss:
    db $00
progress:
    db $00
hon:
    db $00
hx:
    db $00
hy:
    db $00
htype:
    db $00
hdelay:
    db $00
rng:
    db $00
rng_hi:
    db $00
spawn_delay:
    db $00
advance:
    db $00
moving:
    db $00
walkclock:
    db $00
distance_sub:
    db $00
death:
    db $00
bon:
    db $00
bx:
    db $00
by:
    db $00
lane:
    db $00
boss_delay:
    db $00
boss_hit:
    db $00
boss_ready:
    db $00
boss_end:
    db $00
hboom:
    db $00
crouch_clock:
    db $00
wave_left:
    db $00
front_block:
    db $00
hscroll:
    db $00
spawn_dir:
    db $00
boss_burst:
    db $00
sound:
    db $00
e0x:
    db $00
e0y:
    db $00
e0on:
    db $00
e0dir:
    db $00
e0period:
    db $00
e0speed:
    db $00
e0wait:
    db $00
e0anim:
    db $00
e0death:
    db $00
e0hp:
    db $00
e0species:
    db $00
e1x:
    db $00
e1y:
    db $00
e1on:
    db $00
e1dir:
    db $00
e1period:
    db $00
e1speed:
    db $00
e1wait:
    db $00
e1anim:
    db $00
e1death:
    db $00
e1hp:
    db $00
e1species:
    db $00
e2x:
    db $00
e2y:
    db $00
e2on:
    db $00
e2dir:
    db $00
e2period:
    db $00
e2speed:
    db $00
e2wait:
    db $00
e2anim:
    db $00
e2death:
    db $00
e2hp:
    db $00
e2species:
    db $00
e3x:
    db $00
e3y:
    db $00
e3on:
    db $00
e3dir:
    db $00
e3period:
    db $00
e3speed:
    db $00
e3wait:
    db $00
e3anim:
    db $00
e3death:
    db $00
e3hp:
    db $00
e3species:
    db $00
b0x:
    db $00
b0y:
    db $00
b0on:
    db $00
b0diag:
    db $00
b1x:
    db $00
b1y:
    db $00
b1on:
    db $00
b1diag:
    db $00
b2x:
    db $00
b2y:
    db $00
b2on:
    db $00
b2diag:
    db $00
score:
score0:
    db $00
score1:
    db $00
score2:
    db $00
score3:
    db $00
score4:
    db $00
saved_sp:
    db $00,$00
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
used_cols:
    db $00
used_cols_plus1:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00
hud_lives:
    db $00
hud_score:
    db $00,$00,$00,$00,$00
shadow_mode:
    db $00
dirty:
    db $00,$00
dirty_plus2:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
old_dirty:
    db $00,$00,$00,$00,$00,$00
old_dirty_ground:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
phase:
    db $01
cheat:
    db $00
cheat_steps:
    db $00
cheat_down:
    db $00
select_hold:
    db $00
selected_phase:
    db $01
load_id:
    db $00
load_dest:
    db $00,$00
load_len:
    db $00,$00
header_buf:
    db $00
header_name:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
header_len:
    db $00,$00
header_dest:
    db $00,$00
    db $00,$00
jump_y:
    db $69,$63,$5d,$57,$52,$4d,$49,$45,$43,$41,$40,$40,$41,$43,$45,$49,$4d,$52,$57,$5d,$63,$69
jump_pose:
    db $10,$10,$10,$10,$10,$11,$11,$11,$11,$11,$11,$12,$12,$12,$12,$12,$12,$13,$13,$13,$13,$13,$13
crouch_anim:
    db $14,$14,$14,$15,$15,$16,$16
walk_pose:
    db $06,$06,$06,$05,$05,$05,$04,$04,$04,$03,$03,$03,$02,$02,$02,$01,$01,$01
action_anim:
effect_anim:
    db $00,$00,$01,$01,$02,$02,$01,$01
death_pose:
    db $1c,$1c,$1c,$1c,$1c,$1b,$1b,$1b,$1b,$1a,$1a,$1a,$1a,$19,$19,$19,$19,$18,$18,$18,$18,$17,$17,$17
    db $17
zdeath_pose:
    db $0b,$0b,$0b,$0b,$0b,$0a,$0a,$0a,$0a,$09,$09,$09,$09,$08,$08,$08,$08,$07,$07,$07,$07,$06,$06,$06
    db $06
bullet:
    db $00,$f0,$f0,$00
bullet_shift:
    db $00,$0f,$0f,$00
lightning_warn:
    db $18,$00,$00,$00,$18,$00,$00,$00,$18,$00,$00,$00,$18,$00,$00,$00
lightning0:
    db $18,$18,$0c,$0c,$3e,$3e,$38,$18,$1c,$3c,$3e,$34,$30,$18,$18,$18
lightning1:
    db $06,$04,$0c,$08,$18,$14,$3e,$3c,$1c,$38,$30,$78,$7c,$78,$38,$10
firefall:
    db $00,$08,$08,$08,$28,$2c,$2c,$2c,$3c,$3c,$7e,$7e,$7e,$7e,$3c,$18
firefall1:
    db $00,$08,$28,$28,$2c,$2c,$2c,$2c,$3c,$3c,$7e,$7e,$7e,$7e,$3c,$18
firefall2:
    db $20,$28,$28,$2c,$2c,$2c,$2c,$2c,$3c,$3c,$7e,$7e,$7e,$7e,$3c,$18
digits:
    db $38,$c4,$cc,$d4,$e4,$c4,$38,$00,$10,$30,$10,$10,$10,$10,$38,$00,$38,$c4,$04,$08,$10,$20,$fc,$00
    db $f8,$04,$04,$38,$04,$04,$f8,$00,$08,$18,$28,$c8,$fc,$08,$08,$00,$fc,$c0,$c0,$f8,$04,$04,$f8,$00
    db $38,$c0,$c0,$f8,$c4,$c4,$38,$00,$fc,$04,$08,$10,$20,$20,$20,$00,$38,$c4,$c4,$38,$c4,$c4,$38,$00
    db $38,$c4,$c4,$3c,$04,$04,$38,$00
msg_cheat:
    db $fc,$f8,$c4,$3c,$38,$00,$38,$3c,$fc,$fc,$c4,$38,$10,$c4,$c4,$c0,$c4,$00,$c4,$c0,$10,$10,$c4,$c4
    db $10,$c4,$c4,$c0,$c4,$00,$c4,$c0,$10,$10,$c4,$c4,$10,$f8,$c4,$c0,$c4,$00,$fc,$c0,$10,$10,$c4,$c4
    db $10,$d0,$c4,$c0,$c4,$00,$c4,$c0,$10,$10,$c4,$c4,$10,$c8,$c4,$c0,$c4,$00,$c4,$c0,$10,$10,$28,$c4
    db $10,$c4,$38,$3c,$38,$00,$c4,$3c,$10,$fc,$10,$38,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
msg_over:
    db $00,$3c,$38,$c4,$fc,$00,$38,$c4,$fc,$f8,$00,$00,$00,$c0,$c4,$ec,$c0,$00,$c4,$c4,$c0,$c4,$00,$00
    db $00,$c0,$c4,$d4,$c0,$00,$c4,$c4,$c0,$c4,$00,$00,$00,$dc,$fc,$d4,$f8,$00,$c4,$c4,$f8,$f8,$00,$00
    db $00,$c4,$c4,$c4,$c0,$00,$c4,$c4,$c0,$d0,$00,$00,$00,$c4,$c4,$c4,$c0,$00,$c4,$28,$c0,$c8,$00,$00
    db $00,$3c,$c4,$c4,$fc,$00,$38,$10,$fc,$c4,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
msg_win:
    db $fc,$38,$3c,$fc,$00,$10,$00,$38,$c4,$00,$00,$00,$c0,$c4,$c0,$c0,$00,$30,$00,$c4,$c8,$00,$00,$00
    db $c0,$c4,$c0,$c0,$00,$10,$00,$c4,$d0,$00,$00,$00,$f8,$fc,$38,$f8,$00,$10,$00,$c4,$e0,$00,$00,$00
    db $c0,$c4,$04,$c0,$00,$10,$00,$c4,$d0,$00,$00,$00,$c0,$c4,$04,$c0,$00,$10,$00,$c4,$c8,$00,$00,$00
    db $c0,$c4,$f8,$fc,$00,$38,$00,$38,$c4,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
msg_load2:
    db $3c,$38,$f8,$3c,$38,$00,$fc,$38,$3c,$fc,$00,$38,$c0,$c4,$c4,$c0,$c4,$00,$c0,$c4,$c0,$c0,$00,$c4
    db $c0,$c4,$c4,$c0,$c4,$00,$c0,$c4,$c0,$c0,$00,$04,$c0,$fc,$f8,$dc,$fc,$00,$f8,$fc,$38,$f8,$00,$08
    db $c0,$c4,$d0,$c4,$c4,$00,$c0,$c4,$04,$c0,$00,$10,$c0,$c4,$c8,$c4,$c4,$00,$c0,$c4,$04,$c0,$00,$20
    db $3c,$c4,$c4,$3c,$c4,$00,$c0,$c4,$f8,$fc,$00,$fc,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
msg_rewind:
    db $f8,$fc,$f8,$38,$f8,$fc,$c4,$38,$00,$fc,$38,$f8,$c4,$c0,$c4,$c4,$c4,$10,$e4,$c4,$00,$10,$c4,$c4
    db $c4,$c0,$c4,$c4,$c4,$10,$e4,$c4,$00,$10,$c4,$c4,$f8,$f8,$f8,$c4,$f8,$10,$d4,$fc,$00,$10,$fc,$f8
    db $d0,$c0,$c4,$c4,$c4,$10,$cc,$c4,$00,$10,$c4,$c0,$c8,$c0,$c4,$c4,$c4,$10,$cc,$c4,$00,$10,$c4,$c0
    db $c4,$fc,$f8,$38,$f8,$fc,$c4,$c4,$00,$10,$c4,$c0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
msg_select:
    db $38,$04,$f8,$00,$fc,$38,$3c,$fc,$00,$00,$00,$10,$c4,$04,$c4,$00,$c0,$c4,$c0,$c0,$00,$00,$00,$30
    db $c4,$08,$c4,$00,$c0,$c4,$c0,$c0,$00,$00,$00,$10,$c4,$10,$f8,$00,$f8,$fc,$38,$f8,$00,$00,$00,$10
    db $c4,$20,$c0,$00,$c0,$c4,$04,$c0,$00,$00,$00,$10,$c4,$c0,$c0,$00,$c0,$c4,$04,$c0,$00,$00,$00,$10
    db $38,$c0,$c0,$00,$c0,$c4,$f8,$fc,$00,$00,$00,$38,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
hp_by_phase:
    db $10,$16,$1c,$22,$32
speed_by_phase:
    db $05,$06,$07,$08,$09
death_by_phase:
    db $4b,$4b,$4b,$4b,$64
species_by_phase:
    db $00,$00,$05,$0a,$0d
eye_by_phase:
    db $dc,$dc,$d4,$d4,$d4
row_dict:
    dw row_dict_0
    dw row_dict_1
    dw row_dict_2
    dw row_dict_3
    dw row_dict_4
    dw row_dict_5
    dw row_dict_6
    dw row_dict_7
    dw row_dict_8
    dw row_dict_9
    dw row_dict_10
    dw row_dict_11
    dw row_dict_12
    dw row_dict_13
    dw row_dict_14
    dw row_dict_15
    dw row_dict_16
    dw row_dict_17
    dw row_dict_18
    dw row_dict_19
    dw row_dict_20
    dw row_dict_21
    dw row_dict_22
    dw row_dict_23
    dw row_dict_24
    dw row_dict_25
    dw row_dict_26
    dw row_dict_27
    dw row_dict_28
    dw row_dict_29
    dw row_dict_30
    dw row_dict_31
    dw row_dict_32
    dw row_dict_33
    dw row_dict_34
    dw row_dict_35
    dw row_dict_36
    dw row_dict_37
    dw row_dict_38
    dw row_dict_39
    dw row_dict_40
    dw row_dict_41
    dw row_dict_42
    dw row_dict_43
    dw row_dict_44
    dw row_dict_45
    dw row_dict_46
    dw row_dict_47
    dw row_dict_48
    dw row_dict_49
    dw row_dict_50
    dw row_dict_51
    dw row_dict_52
    dw row_dict_53
    dw row_dict_54
    dw row_dict_55
    dw row_dict_56
    dw row_dict_57
    dw row_dict_58
    dw row_dict_59
    dw row_dict_60
    dw row_dict_61
    dw row_dict_62
    dw row_dict_63
    dw row_dict_64
    dw row_dict_65
    dw row_dict_66
    dw row_dict_67
    dw row_dict_68
    dw row_dict_69
    dw row_dict_70
    dw row_dict_71
    dw row_dict_72
    dw row_dict_73
    dw row_dict_74
    dw row_dict_75
    dw row_dict_76
    dw row_dict_77
    dw row_dict_78
    dw row_dict_79
    dw row_dict_80
    dw row_dict_81
    dw row_dict_82
    dw row_dict_83
    dw row_dict_84
    dw row_dict_85
    dw row_dict_86
    dw row_dict_87
    dw row_dict_88
    dw row_dict_89
    dw row_dict_90
    dw row_dict_91
    dw row_dict_92
    dw row_dict_93
    dw row_dict_94
    dw row_dict_95
    dw row_dict_96
    dw row_dict_97
    dw row_dict_98
    dw row_dict_99
    dw row_dict_100
    dw row_dict_101
    dw row_dict_102
    dw row_dict_103
    dw row_dict_104
    dw row_dict_105
    dw row_dict_106
    dw row_dict_107
    dw row_dict_108
    dw row_dict_109
    dw row_dict_110
    dw row_dict_111
    dw row_dict_112
    dw row_dict_113
    dw row_dict_114
    dw row_dict_115
    dw row_dict_116
    dw row_dict_117
    dw row_dict_118
    dw row_dict_119
    dw row_dict_120
    dw row_dict_121
    dw row_dict_122
    dw row_dict_123
    dw row_dict_124
    dw row_dict_125
    dw row_dict_126
    dw row_dict_127
    dw row_dict_128
    dw row_dict_129
    dw row_dict_130
    dw row_dict_131
    dw row_dict_132
    dw row_dict_133
    dw row_dict_134
    dw row_dict_135
    dw row_dict_136
    dw row_dict_137
    dw row_dict_138
    dw row_dict_139
    dw row_dict_140
    dw row_dict_141
    dw row_dict_142
    dw row_dict_143
    dw row_dict_144
    dw row_dict_145
    dw row_dict_146
    dw row_dict_147
    dw row_dict_148
    dw row_dict_149
    dw row_dict_150
    dw row_dict_151
    dw row_dict_152
    dw row_dict_153
    dw row_dict_154
    dw row_dict_155
    dw row_dict_156
    dw row_dict_157
    dw row_dict_158
    dw row_dict_159
    dw row_dict_160
    dw row_dict_161
    dw row_dict_162
    dw row_dict_163
    dw row_dict_164
    dw row_dict_165
    dw row_dict_166
    dw row_dict_167
    dw row_dict_168
    dw row_dict_169
    dw row_dict_170
    dw row_dict_171
    dw row_dict_172
    dw row_dict_173
    dw row_dict_174
    dw row_dict_175
    dw row_dict_176
    dw row_dict_177
    dw row_dict_178
    dw row_dict_179
    dw row_dict_180
    dw row_dict_181
    dw row_dict_182
    dw row_dict_183
    dw row_dict_184
    dw row_dict_185
    dw row_dict_186
    dw row_dict_187
    dw row_dict_188
    dw row_dict_189
    dw row_dict_190
    dw row_dict_191
    dw row_dict_192
    dw row_dict_193
    dw row_dict_194
    dw row_dict_195
    dw row_dict_196
    dw row_dict_197
    dw row_dict_198
    dw row_dict_199
    dw row_dict_200
    dw row_dict_201
    dw row_dict_202
    dw row_dict_203
    dw row_dict_204
    dw row_dict_205
    dw row_dict_206
    dw row_dict_207
row_dict_0:
    db $0c,$fe,$00,$00,$f7,$1e,$40,$3f,$00
row_dict_1:
    db $0c,$fe,$00,$00,$ef,$00,$40,$3f,$80
row_dict_2:
    db $0c,$fe,$00,$00,$e0,$00,$d6,$3f,$00
row_dict_3:
    db $0c,$fe,$00,$00,$c2,$00,$7f,$3f,$80
row_dict_4:
    db $0c,$fe,$00,$00,$ff,$00,$18,$7f,$00
row_dict_5:
    db $1b,$fc,$00,$00,$37,$10,$c3,$7f,$00
row_dict_6:
    db $0c,$fe,$00,$08,$c3,$00,$ec,$3f,$00
row_dict_7:
    db $0c,$fe,$00,$03,$f8,$c0,$1f,$7f,$00
row_dict_8:
    db $0c,$fe,$00,$03,$e0,$c0,$1c,$7f,$00
row_dict_9:
    db $0c,$fe,$00,$03,$00,$c0,$00,$7f,$00
row_dict_10:
    db $09,$fc,$01,$00,$8d,$3f,$80
row_dict_11:
    db $09,$fc,$00,$20,$0e,$1f,$80
row_dict_12:
    db $09,$fc,$00,$00,$63,$3f,$80
row_dict_13:
    db $18,$e0,$0f,$01,$74,$e3,$00
row_dict_14:
    db $18,$e0,$0f,$00,$e3,$0f,$80
row_dict_15:
    db $18,$e0,$0e,$00,$f4,$03,$08
row_dict_16:
    db $18,$e0,$0e,$00,$0d,$03,$60
row_dict_17:
    db $18,$e0,$0c,$00,$27,$03,$f8
row_dict_18:
    db $09,$fe,$00,$00,$fe,$00,$38
row_dict_19:
    db $09,$fe,$00,$00,$85,$3f,$00
row_dict_20:
    db $09,$fe,$00,$00,$7c,$1f,$00
row_dict_21:
    db $09,$fe,$00,$00,$1c,$7f,$00
row_dict_22:
    db $09,$fc,$01,$00,$88,$3f,$00
row_dict_23:
    db $09,$fc,$00,$20,$0d,$3f,$80
row_dict_24:
    db $09,$fc,$00,$00,$e3,$3f,$80
row_dict_25:
    db $18,$e0,$0f,$00,$f1,$07,$80
row_dict_26:
    db $18,$e0,$00,$08,$c0,$3f,$00
row_dict_27:
    db $18,$e0,$00,$04,$60,$3f,$00
row_dict_28:
    db $09,$fe,$00,$00,$77,$1f,$c0
row_dict_29:
    db $09,$fe,$00,$00,$0c,$83,$00
row_dict_30:
    db $09,$fe,$00,$00,$06,$43,$00
row_dict_31:
    db $1b,$fc,$01,$00,$ce,$18,$c0,$7f,$00
row_dict_32:
    db $1b,$fc,$00,$00,$6e,$18,$00,$7f,$00
row_dict_33:
    db $1b,$e0,$0f,$00,$f1,$06,$80,$3f,$00
row_dict_34:
    db $1b,$e0,$0f,$00,$78,$00,$00,$7f,$00
row_dict_35:
    db $1b,$e0,$0f,$00,$78,$00,$00,$1f,$80
row_dict_36:
    db $1b,$e0,$0e,$00,$3e,$00,$30,$7f,$00
row_dict_37:
    db $1b,$e0,$0e,$00,$3e,$00,$30,$1f,$80
row_dict_38:
    db $1b,$e0,$0e,$00,$03,$00,$fd,$7f,$00
row_dict_39:
    db $1b,$e0,$0e,$00,$03,$00,$fd,$1f,$c0
row_dict_40:
    db $1b,$e0,$07,$01,$7c,$fe,$00,$3f,$00
row_dict_41:
    db $0c,$fe,$00,$18,$03,$00,$73,$3f,$80
row_dict_42:
    db $0c,$fe,$00,$18,$00,$00,$76,$3f,$00
row_dict_43:
    db $0c,$fe,$00,$00,$ff,$00,$18,$63,$00
row_dict_44:
    db $0c,$fe,$00,$00,$f7,$00,$80,$1f,$00
row_dict_45:
    db $0c,$fe,$00,$00,$f7,$00,$80,$07,$00
row_dict_46:
    db $0c,$fe,$00,$00,$f7,$00,$80,$01,$08
row_dict_47:
    db $0c,$fe,$00,$00,$e3,$00,$e3,$1f,$00
row_dict_48:
    db $0c,$fe,$00,$00,$e3,$00,$e3,$07,$00
row_dict_49:
    db $0c,$fe,$00,$00,$e3,$00,$e3,$01,$08
row_dict_50:
    db $0c,$fe,$00,$00,$e0,$00,$3f,$1f,$c0
row_dict_51:
    db $0c,$fe,$00,$00,$e0,$00,$3f,$07,$d0
row_dict_52:
    db $0c,$fe,$00,$00,$e0,$00,$3f,$01,$dc
row_dict_53:
    db $0c,$fe,$00,$00,$77,$1f,$c0,$e3,$00
row_dict_54:
    db $18,$83,$18,$f0,$06,$7f,$00
row_dict_55:
    db $09,$f8,$01,$3f,$80,$07,$60
row_dict_56:
    db $18,$fc,$01,$00,$ff,$0f,$80
row_dict_57:
    db $18,$fc,$01,$00,$c0,$1f,$00
row_dict_58:
    db $18,$f8,$03,$00,$fe,$7f,$00
row_dict_59:
    db $18,$f0,$07,$00,$8e,$7f,$00
row_dict_60:
    db $18,$e0,$0f,$3c,$81,$07,$f0
row_dict_61:
    db $18,$e0,$0e,$3c,$01,$07,$c0
row_dict_62:
    db $18,$e0,$00,$3c,$00,$07,$00
row_dict_63:
    db $18,$c0,$03,$01,$7c,$07,$30
row_dict_64:
    db $09,$f0,$01,$00,$ff,$3f,$80
row_dict_65:
    db $09,$e0,$0c,$80,$3e,$03,$c0
row_dict_66:
    db $15,$f8,$02,$00,$20
row_dict_67:
    db $15,$e0,$0f,$1f,$c0
row_dict_68:
    db $15,$80,$22,$0f,$00
row_dict_69:
    db $15,$fe,$00,$03,$00
row_dict_70:
    db $15,$fe,$00,$01,$fc
row_dict_71:
    db $15,$fc,$00,$07,$00
row_dict_72:
    db $15,$e0,$00,$3f,$00
row_dict_73:
    db $15,$e0,$00,$1f,$00
row_dict_74:
    db $15,$f0,$07,$01,$e0
row_dict_75:
    db $15,$00,$7e,$1f,$00
row_dict_76:
    db $15,$00,$0e,$3f,$00
row_dict_77:
    db $15,$fe,$00,$01,$00
row_dict_78:
    db $15,$f8,$00,$0f,$00
row_dict_79:
    db $15,$f0,$04,$03,$58
row_dict_80:
    db $15,$f0,$00,$03,$e0
row_dict_81:
    db $15,$c2,$00,$01,$e8
row_dict_82:
    db $15,$c0,$18,$03,$d8
row_dict_83:
    db $15,$c0,$06,$03,$38
row_dict_84:
    db $15,$00,$45,$3f,$80
row_dict_85:
    db $15,$fe,$00,$07,$00
row_dict_86:
    db $15,$fe,$00,$03,$f8
row_dict_87:
    db $15,$f8,$01,$00,$fe
row_dict_88:
    db $15,$e0,$0f,$3f,$80
row_dict_89:
    db $15,$c0,$00,$7f,$00
row_dict_90:
    db $15,$80,$1f,$0f,$e0
row_dict_91:
    db $15,$fc,$01,$07,$f0
row_dict_92:
    db $15,$e0,$08,$03,$50
row_dict_93:
    db $15,$e0,$07,$01,$c0
row_dict_94:
    db $15,$e0,$01,$07,$c0
row_dict_95:
    db $15,$c2,$00,$03,$d8
row_dict_96:
    db $15,$c0,$18,$03,$80
row_dict_97:
    db $15,$c0,$0e,$03,$38
row_dict_98:
    db $24,$c0,$00,$00,$7e,$7f,$00
row_dict_99:
    db $18,$fc,$01,$00,$fe,$7f,$00
row_dict_100:
    db $18,$fc,$00,$00,$07,$07,$e0
row_dict_101:
    db $18,$e0,$0f,$30,$07,$7f,$00
row_dict_102:
    db $18,$e0,$0f,$00,$78,$01,$00
row_dict_103:
    db $18,$e0,$0e,$70,$06,$7f,$00
row_dict_104:
    db $18,$e0,$0e,$00,$3e,$01,$30
row_dict_105:
    db $18,$e0,$0e,$00,$03,$01,$fc
row_dict_106:
    db $18,$e0,$07,$20,$87,$7f,$00
row_dict_107:
    db $18,$e0,$00,$00,$60,$3f,$00
row_dict_108:
    db $18,$c0,$1c,$01,$ec,$87,$00
row_dict_109:
    db $18,$c0,$06,$01,$e0,$87,$00
row_dict_110:
    db $18,$81,$3c,$f0,$07,$1f,$c0
row_dict_111:
    db $18,$81,$38,$f0,$07,$1f,$00
row_dict_112:
    db $18,$81,$00,$f0,$00,$1f,$00
row_dict_113:
    db $09,$fe,$00,$07,$e0,$07,$60
row_dict_114:
    db $09,$fe,$00,$03,$f0,$07,$70
row_dict_115:
    db $09,$fe,$00,$02,$78,$07,$70
row_dict_116:
    db $09,$fe,$00,$00,$7e,$03,$00
row_dict_117:
    db $09,$fe,$00,$00,$06,$03,$00
row_dict_118:
    db $09,$fc,$00,$0f,$80,$0f,$20
row_dict_119:
    db $09,$f8,$03,$1f,$c0,$01,$7c
row_dict_120:
    db $09,$f8,$03,$1f,$80,$01,$70
row_dict_121:
    db $09,$f8,$00,$1f,$00,$01,$00
row_dict_122:
    db $09,$e1,$00,$80,$37,$03,$38
row_dict_123:
    db $09,$e1,$00,$80,$07,$03,$60
row_dict_124:
    db $09,$e0,$07,$00,$e0,$3f,$00
row_dict_125:
    db $15,$e0,$07,$01,$7c
row_dict_126:
    db $15,$c0,$1f,$7f,$00
row_dict_127:
    db $15,$80,$3b,$1f,$80
row_dict_128:
    db $21,$80,$3f,$7f,$00
row_dict_129:
    db $15,$fe,$00,$00,$fe
row_dict_130:
    db $15,$f8,$03,$0f,$e0
row_dict_131:
    db $15,$f8,$03,$07,$f0
row_dict_132:
    db $15,$f8,$03,$01,$b8
row_dict_133:
    db $15,$e0,$0f,$0f,$e0
row_dict_134:
    db $15,$e0,$00,$7f,$00
row_dict_135:
    db $1b,$fc,$00,$00,$e3,$00,$c4,$7f,$00
row_dict_136:
    db $1b,$fc,$00,$00,$38,$00,$3b,$3f,$80
row_dict_137:
    db $0c,$fe,$00,$00,$23,$00,$c7,$3f,$00
row_dict_138:
    db $0c,$fc,$01,$00,$dc,$00,$1c,$3f,$00
row_dict_139:
    db $0c,$fc,$01,$00,$c7,$00,$ff,$7f,$00
row_dict_140:
    db $21,$c0,$1f,$00,$f8
row_dict_141:
    db $21,$80,$38,$7f,$00
row_dict_142:
    db $21,$00,$7e,$3f,$00
row_dict_143:
    db $15,$fc,$00,$00,$fc
row_dict_144:
    db $15,$fc,$00,$00,$7e
row_dict_145:
    db $15,$f8,$03,$07,$80
row_dict_146:
    db $15,$f8,$03,$00,$fe
row_dict_147:
    db $15,$f0,$07,$03,$e0
row_dict_148:
    db $15,$f0,$03,$00,$9e
row_dict_149:
    db $15,$c0,$1c,$01,$00
row_dict_150:
    db $15,$c0,$0f,$0f,$c0
row_dict_151:
    db $15,$c0,$07,$0f,$e0
row_dict_152:
    db $15,$80,$3f,$0f,$e0
row_dict_153:
    db $15,$80,$3f,$07,$e0
row_dict_154:
    db $15,$00,$78,$07,$e0
row_dict_155:
    db $15,$00,$39,$0f,$e0
row_dict_156:
    db $15,$00,$1f,$03,$f8
row_dict_157:
    db $21,$fc,$00,$1f,$00
row_dict_158:
    db $21,$e0,$00,$7f,$00
row_dict_159:
    db $21,$c0,$00,$7f,$00
row_dict_160:
    db $21,$00,$3e,$7f,$00
row_dict_161:
    db $15,$fe,$00,$00,$fc
row_dict_162:
    db $15,$f8,$03,$1f,$c0
row_dict_163:
    db $15,$f8,$03,$07,$c0
row_dict_164:
    db $15,$f8,$01,$00,$dc
row_dict_165:
    db $15,$f8,$00,$03,$08
row_dict_166:
    db $15,$f8,$00,$01,$f0
row_dict_167:
    db $15,$f0,$07,$0f,$c0
row_dict_168:
    db $15,$f0,$03,$0f,$e0
row_dict_169:
    db $15,$f0,$03,$0f,$c0
row_dict_170:
    db $15,$e0,$07,$01,$a0
row_dict_171:
    db $15,$c0,$0f,$1f,$80
row_dict_172:
    db $15,$c0,$08,$f0,$02
row_dict_173:
    db $15,$80,$1d,$0f,$c0
row_dict_174:
    db $15,$80,$00,$3f,$80
row_dict_175:
    db $24,$00,$1c,$00,$c3,$3f,$00
row_dict_176:
    db $24,$00,$03,$00,$1f,$3f,$00
row_dict_177:
    db $18,$fe,$00,$00,$ff,$7f,$00
row_dict_178:
    db $18,$fe,$00,$00,$fe,$7f,$00
row_dict_179:
    db $18,$fe,$00,$00,$7e,$7f,$00
row_dict_180:
    db $18,$fe,$00,$00,$7a,$1f,$00
row_dict_181:
    db $18,$fc,$01,$10,$c7,$1f,$c0
row_dict_182:
    db $18,$fc,$01,$10,$c7,$1f,$00
row_dict_183:
    db $18,$fc,$01,$00,$e7,$1f,$00
row_dict_184:
    db $18,$fc,$01,$00,$c7,$1f,$c0
row_dict_185:
    db $18,$fc,$00,$00,$ff,$7f,$00
row_dict_186:
    db $18,$fc,$00,$00,$f0,$3f,$00
row_dict_187:
    db $18,$fc,$00,$00,$e7,$7f,$00
row_dict_188:
    db $18,$fc,$00,$00,$e3,$3f,$00
row_dict_189:
    db $18,$f8,$03,$00,$ff,$7f,$00
row_dict_190:
    db $18,$f8,$03,$00,$ef,$3f,$80
row_dict_191:
    db $18,$f8,$03,$00,$ef,$3f,$00
row_dict_192:
    db $18,$f8,$03,$00,$e7,$3f,$00
row_dict_193:
    db $18,$f8,$03,$00,$9f,$1f,$c0
row_dict_194:
    db $18,$f8,$01,$00,$c7,$7f,$00
row_dict_195:
    db $18,$f8,$00,$00,$5e,$7f,$00
row_dict_196:
    db $18,$f0,$07,$00,$de,$7f,$00
row_dict_197:
    db $18,$f0,$07,$00,$87,$3f,$00
row_dict_198:
    db $18,$f0,$03,$00,$df,$7f,$00
row_dict_199:
    db $18,$f0,$01,$00,$cc,$03,$30
row_dict_200:
    db $18,$f0,$00,$00,$31,$03,$f0
row_dict_201:
    db $18,$e0,$0f,$70,$03,$1f,$80
row_dict_202:
    db $18,$e0,$0f,$20,$8f,$3f,$80
row_dict_203:
    db $18,$e0,$0f,$20,$07,$3f,$80
row_dict_204:
    db $18,$e0,$0f,$00,$8f,$3f,$00
row_dict_205:
    db $18,$e0,$0e,$f8,$01,$1f,$c0
row_dict_206:
    db $18,$e0,$0e,$78,$03,$1f,$c0
row_dict_207:
    db $18,$e0,$0e,$78,$01,$1f,$c0
ace0:
    dw ace0_s0
    dw ace0_s4
ace0_s0:
    db $00,$00,$00,$00,$00,$78,$88,$47,$46,$48,$43,$45,$44,$30,$31,$33,$32,$42,$09,$fe,$00,$00,$0c,$03
    db $00,$15,$80,$01,$3f,$00,$af,$15,$80,$3b,$0f,$c0,$cb,$09,$fe,$00,$00,$78,$0f,$e0,$09,$fc,$00,$02
    db $f0,$0f,$60,$09,$fc,$01,$06,$c0,$0f,$e0,$09,$fc,$00,$0e,$e0,$0f,$c0,$09,$fc,$00,$0e,$80,$0f,$60
    db $67,$09,$f8,$03,$1e,$80,$03,$70,$09,$f8,$03,$1e,$c0,$03,$f8,$09,$f8,$00,$1e,$00,$03,$00
ace0_s4:
    db $00,$00,$00,$00,$00,$75,$86,$8f,$90,$91,$8c,$8e,$8d,$3d,$3f,$41,$40,$3e,$18,$e0,$00,$00,$c0,$3f
    db $00,$15,$f8,$00,$03,$10,$b4,$15,$f8,$03,$00,$bc,$c4,$15,$e0,$07,$00,$8e,$15,$c0,$0f,$20,$06,$15
    db $c0,$1c,$60,$0e,$15,$c0,$0e,$e0,$0c,$15,$c0,$08,$e0,$06,$66,$18,$81,$38,$e0,$07,$3f,$00,$18,$81
    db $3c,$e0,$0f,$3f,$80,$18,$81,$00,$e0,$00,$3f,$00
ace1:
    dw ace1_s0
    dw ace1_s4
ace1_s0:
    db $00,$00,$00,$00,$00,$78,$88,$47,$46,$48,$43,$45,$44,$30,$31,$33,$32,$42,$4d,$74,$15,$00,$3f,$0f
    db $e0,$15,$00,$7d,$07,$e0,$09,$fe,$00,$00,$7d,$07,$f0,$09,$fe,$00,$00,$f8,$03,$f0,$09,$fe,$00,$02
    db $f8,$03,$f8,$09,$fe,$00,$02,$f0,$03,$78,$09,$fe,$00,$07,$f0,$01,$38,$09,$fe,$00,$07,$e0,$81,$3c
    db $09,$fe,$00,$0f,$e0,$81,$1c,$38,$37,$39
ace1_s4:
    db $00,$00,$00,$00,$00,$75,$86,$8f,$90,$91,$8c,$8e,$8d,$3d,$3f,$41,$40,$3e,$4a,$72,$15,$f0,$03,$00
    db $fe,$f4,$18,$e0,$07,$00,$df,$7f,$00,$fc,$fa,$fb,$f9,$fe,$fd,$6d,$6c,$6e
ace2:
    dw ace2_s0
    dw ace2_s4
ace2_s0:
    db $00,$00,$00,$00,$00,$78,$88,$47,$46,$48,$43,$45,$44,$30,$31,$33,$32,$42,$4d,$74,$c8,$c9,$15,$80
    db $3f,$07,$f0,$15,$80,$3e,$03,$f0,$15,$80,$3e,$03,$f8,$15,$80,$3e,$03,$70,$15,$80,$1c,$07,$70,$15
    db $c1,$1c,$01,$70,$15,$c1,$1c,$01,$7c,$c5,$ae,$89
ace2_s4:
    db $00,$00,$00,$00,$00,$75,$86,$8f,$90,$91,$8c,$8e,$8d,$3d,$3f,$41,$40,$3e,$4a,$72,$c2,$6a,$ed,$ef
    db $ee,$f0,$f2,$e6,$e5,$69,$8b,$77
ace3:
    dw ace3_s0
    dw ace3_s4
ace3_s0:
    db $00,$00,$00,$00,$00,$78,$88,$47,$46,$48,$43,$45,$44,$30,$31,$33,$32,$42,$4d,$74,$c8,$8a,$15,$c0
    db $1f,$07,$e0,$15,$c0,$0f,$07,$f0,$15,$e0,$0f,$07,$f0,$15,$e0,$07,$07,$e0,$d7,$15,$f0,$03,$07,$c0
    db $b3,$c1,$b2,$7e
ace3_s4:
    db $00,$00,$00,$00,$00,$75,$86,$8f,$90,$91,$8c,$8e,$8d,$3d,$3f,$41,$40,$3e,$4a,$72,$c2,$87,$93,$e9
    db $e1,$e3,$1e,$00,$7c,$21,$00,$3c,$7f,$00,$b0,$bd,$1e,$80,$3e,$1e,$80,$00
ace4:
    dw ace4_s0
    dw ace4_s4
ace4_s0:
    db $00,$00,$00,$00,$00,$78,$88,$47,$46,$48,$43,$45,$44,$30,$31,$33,$32,$42,$4d,$74,$8a,$c6,$db,$15
    db $80,$1f,$0f,$c0,$c9,$15,$00,$3d,$07,$f0,$15,$00,$78,$03,$70,$09,$fe,$00,$03,$70,$01,$38,$09,$fe
    db $00,$07,$e0,$81,$1c,$38,$37,$39
ace4_s4:
    db $00,$00,$00,$00,$00,$75,$86,$8f,$90,$91,$8c,$8e,$8d,$3d,$3f,$41,$40,$3e,$4a,$72,$87,$bf,$15,$fc
    db $00,$01,$f8,$15,$f8,$01,$00,$fc,$6a,$f6,$f5,$18,$e0,$07,$30,$03,$1f,$80,$ff,$6d,$6c,$6e
ace5:
    dw ace5_s0
    dw ace5_s4
ace5_s0:
    db $00,$00,$00,$00,$00,$78,$88,$47,$46,$48,$43,$45,$44,$30,$31,$33,$32,$42,$4d,$74,$8a,$c6,$73,$15
    db $e0,$0f,$0f,$c0,$b5,$15,$e0,$0f,$07,$e0,$15,$c0,$0e,$07,$70,$15,$c0,$1e,$01,$70,$15,$c0,$1c,$01
    db $7c,$c5,$ae,$89
ace5_s4:
    db $00,$00,$00,$00,$00,$75,$86,$8f,$90,$91,$8c,$8e,$8d,$3d,$3f,$41,$40,$3e,$4a,$72,$87,$bf,$76,$d1
    db $b1,$e2,$eb,$e7,$e8,$69,$8b,$77
ace6:
    dw ace6_s0
    dw ace6_s4
ace6_s0:
    db $00,$00,$00,$00,$00,$78,$88,$47,$46,$48,$43,$45,$44,$30,$31,$33,$32,$42,$4d,$74,$8a,$15,$c0,$1f
    db $0f,$e0,$15,$c0,$0f,$0f,$e0,$b5,$15,$e0,$07,$0f,$e0,$d9,$d2,$d3,$b3,$c1,$b2,$7e
ace6_s4:
    db $00,$00,$00,$00,$00,$75,$86,$8f,$90,$91,$8c,$8e,$8d,$3d,$3f,$41,$40,$3e,$4a,$72,$87,$15,$fc,$01
    db $00,$fe,$15,$fc,$00,$00,$fe,$b1,$15,$fe,$00,$00,$7e,$1e,$00,$3c,$1e,$81,$3c,$21,$80,$3c,$7f,$00
    db $b0,$bd,$1e,$80,$3e,$1e,$80,$00
ace7:
    dw ace7_s0
    dw ace7_s4
ace7_s0:
    db $00,$00,$00,$00,$00,$79,$73,$3b,$3a,$3c,$84,$7c,$7b,$4c,$5c,$62,$5f,$34,$4e,$74,$15,$00,$3f,$0f
    db $e0,$15,$00,$7d,$07,$e0,$09,$fe,$00,$00,$7d,$07,$f0,$09,$fe,$00,$00,$f8,$03,$f0,$09,$fe,$00,$02
    db $f8,$03,$f8,$09,$fe,$00,$02,$f0,$03,$78,$09,$fe,$00,$07,$f0,$01,$38,$09,$fe,$00,$07,$e0,$81,$3c
    db $09,$fe,$00,$0f,$e0,$81,$1c,$38,$37,$39
ace7_s4:
    db $00,$00,$00,$00,$00,$7d,$76,$81,$82,$83,$7f,$80,$7a,$ad,$96,$99,$98,$49,$4b,$72,$15,$f0,$03,$00
    db $fe,$f4,$18,$e0,$07,$00,$df,$7f,$00,$fc,$fa,$fb,$f9,$fe,$fd,$6d,$6c,$6e
ace8:
    dw ace8_s0
    dw ace8_s4
ace8_s0:
    db $00,$00,$00,$00,$00,$79,$73,$3b,$3a,$3c,$84,$7c,$7b,$4c,$5d,$63,$60,$34,$4e,$74,$c8,$c9,$15,$80
    db $3f,$07,$f0,$15,$80,$3e,$03,$f0,$15,$80,$3e,$03,$f8,$15,$80,$3e,$03,$70,$15,$80,$1c,$07,$70,$15
    db $c1,$1c,$01,$70,$15,$c1,$1c,$01,$7c,$c5,$ae,$89
ace8_s4:
    db $00,$00,$00,$00,$00,$7d,$76,$81,$82,$83,$7f,$80,$7a,$ad,$52,$56,$54,$49,$4b,$72,$c2,$6a,$ed,$ef
    db $ee,$f0,$f2,$e6,$e5,$69,$8b,$77
ace9:
    dw ace9_s0
    dw ace9_s4
ace9_s0:
    db $00,$00,$00,$00,$00,$79,$73,$3b,$3a,$3c,$84,$7c,$7b,$65,$5e,$64,$61,$5b,$4e,$74,$c8,$8a,$15,$c0
    db $1f,$07,$e0,$15,$c0,$0f,$07,$f0,$15,$e0,$0f,$07,$f0,$15,$e0,$07,$07,$e0,$d7,$15,$f0,$03,$07,$c0
    db $b3,$c1,$b2,$7e
ace9_s4:
    db $00,$00,$00,$00,$00,$7d,$76,$81,$82,$83,$7f,$80,$7a,$58,$53,$57,$55,$51,$4b,$72,$c2,$87,$93,$e9
    db $e1,$e3,$1e,$00,$7c,$21,$00,$3c,$7f,$00,$b0,$bd,$1e,$80,$3e,$1e,$80,$00
ace10:
    dw ace10_s0
    dw ace10_s4
ace10_s0:
    db $00,$00,$00,$00,$00,$79,$73,$3b,$3a,$3c,$84,$7c,$7b,$4c,$5c,$62,$5f,$34,$4e,$74,$8a,$c6,$db,$15
    db $80,$1f,$0f,$c0,$c9,$15,$00,$3d,$07,$f0,$15,$00,$78,$03,$70,$09,$fe,$00,$03,$70,$01,$38,$09,$fe
    db $00,$07,$e0,$81,$1c,$38,$37,$39
ace10_s4:
    db $00,$00,$00,$00,$00,$7d,$76,$81,$82,$83,$7f,$80,$7a,$ad,$96,$99,$98,$49,$4b,$72,$87,$bf,$15,$fc
    db $00,$01,$f8,$15,$f8,$01,$00,$fc,$6a,$f6,$f5,$18,$e0,$07,$30,$03,$1f,$80,$ff,$6d,$6c,$6e
ace11:
    dw ace11_s0
    dw ace11_s4
ace11_s0:
    db $00,$00,$00,$00,$00,$79,$73,$3b,$3a,$3c,$84,$7c,$7b,$4c,$5d,$63,$60,$34,$4e,$74,$8a,$c6,$73,$15
    db $e0,$0f,$0f,$c0,$b5,$15,$e0,$0f,$07,$e0,$15,$c0,$0e,$07,$70,$15,$c0,$1e,$01,$70,$15,$c0,$1c,$01
    db $7c,$c5,$ae,$89
ace11_s4:
    db $00,$00,$00,$00,$00,$7d,$76,$81,$82,$83,$7f,$80,$7a,$ad,$52,$56,$54,$49,$4b,$72,$87,$bf,$76,$d1
    db $b1,$e2,$eb,$e7,$e8,$69,$8b,$77
ace12:
    dw ace12_s0
    dw ace12_s4
ace12_s0:
    db $00,$00,$00,$00,$00,$79,$73,$3b,$3a,$3c,$84,$7c,$7b,$65,$5e,$64,$61,$5b,$4e,$74,$8a,$15,$c0,$1f
    db $0f,$e0,$15,$c0,$0f,$0f,$e0,$b5,$15,$e0,$07,$0f,$e0,$d9,$d2,$d3,$b3,$c1,$b2,$7e
ace12_s4:
    db $00,$00,$00,$00,$00,$7d,$76,$81,$82,$83,$7f,$80,$7a,$58,$53,$57,$55,$51,$4b,$72,$87,$15,$fc,$01
    db $00,$fe,$15,$fc,$00,$00,$fe,$b1,$15,$fe,$00,$00,$7e,$1e,$00,$3c,$1e,$81,$3c,$21,$80,$3c,$7f,$00
    db $b0,$bd,$1e,$80,$3e,$1e,$80,$00
ace13:
    dw ace13_s0
    dw ace13_s4
ace13_s0:
    db $00,$00,$00,$00,$00,$79,$73,$3b,$3a,$3c,$84,$7c,$7b,$4c,$5c,$62,$5f,$34,$a5,$de,$af,$dd,$cb,$ca
    db $a3,$a2,$a1,$a6,$67,$a8,$a7,$a9
ace13_s4:
    db $00,$00,$00,$00,$00,$7d,$76,$81,$82,$83,$7f,$80,$7a,$ad,$96,$99,$98,$49,$9b,$d5,$b4,$d4,$c4,$6b
    db $9a,$95,$97,$dc,$66,$9f,$9e,$a0
ace14:
    dw ace14_s0
    dw ace14_s4
ace14_s0:
    db $00,$00,$00,$00,$00,$79,$73,$3b,$3a,$3c,$84,$7c,$7b,$4c,$5d,$63,$60,$34,$a5,$de,$af,$dd,$cb,$ca
    db $a3,$a2,$a1,$a6,$67,$a8,$a7,$a9
ace14_s4:
    db $00,$00,$00,$00,$00,$7d,$76,$81,$82,$83,$7f,$80,$7a,$ad,$52,$56,$54,$49,$9b,$d5,$b4,$d4,$c4,$6b
    db $9a,$95,$97,$dc,$66,$9f,$9e,$a0
ace15:
    dw ace15_s0
    dw ace15_s4
ace15_s0:
    db $00,$00,$00,$00,$00,$79,$73,$3b,$3a,$3c,$84,$7c,$7b,$65,$5e,$64,$61,$5b,$a5,$de,$af,$dd,$cb,$ca
    db $a3,$a2,$a1,$a6,$67,$a8,$a7,$a9
ace15_s4:
    db $00,$00,$00,$00,$00,$7d,$76,$81,$82,$83,$7f,$80,$7a,$58,$53,$57,$55,$51,$9b,$d5,$b4,$d4,$c4,$6b
    db $9a,$95,$97,$dc,$66,$9f,$9e,$a0
ace16:
    dw ace16_s0
    dw ace16_s4
ace16_s0:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$7e,$d8,$15,$f0,$07,$0f,$e0,$15,$f0,$07,$0f,$80
    db $15,$80,$01,$1f,$c0,$15,$00,$3a,$1f,$c0,$09,$fe,$00,$00,$7a,$1f,$00,$0c,$fe,$00,$00,$f2,$00,$00
    db $7f,$00,$0c,$fe,$00,$00,$c3,$00,$7d,$7f,$00,$0c,$fe,$00,$00,$f3,$00,$fc,$7f,$00,$09,$fe,$00,$00
    db $7f,$01,$20,$15,$00,$06,$07,$00,$15,$80,$38,$03,$f0,$15,$80,$1c,$03,$78,$15,$c0,$0e,$03,$30,$09
    db $fe,$00,$00,$17,$07,$30,$09,$fc,$00,$00,$fe,$03,$30,$09,$fc,$01,$00,$c0,$01,$78,$09,$fc,$01,$0f
    db $e0,$01,$7c,$09,$fc,$00,$0f,$00,$01,$00
ace16_s4:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$1e,$80,$00,$1e,$00,$3e,$1e,$00,$7e,$1e,$00,$78
    db $15,$f8,$00,$01,$1c,$15,$f0,$03,$01,$ac,$da,$18,$e0,$0f,$00,$20,$07,$00,$18,$e0,$0c,$00,$37,$07
    db $d0,$18,$e0,$0f,$00,$3f,$07,$c0,$18,$e0,$07,$00,$f2,$1f,$00,$18,$f0,$00,$00,$60,$7f,$00,$18,$f8
    db $03,$00,$8f,$3f,$00,$18,$f8,$01,$00,$c7,$3f,$80,$ec,$18,$e0,$01,$00,$73,$7f,$00,$18,$c0,$0f,$00
    db $e3,$3f,$00,$18,$c0,$1c,$00,$07,$1f,$80,$18,$c0,$1e,$f0,$07,$1f,$c0,$18,$c0,$00,$f0,$00,$1f,$00
ace17:
    dw ace17_s0
    dw ace17_s4
ace17_s0:
    db $00,$00,$00,$00,$00,$00,$00,$00,$77,$8b,$8b,$15,$c0,$01,$07,$a0,$15,$c0,$1c,$07,$70,$15,$c0,$06
    db $07,$b0,$15,$c0,$0e,$07,$80,$15,$80,$1e,$01,$80,$15,$80,$39,$01,$fc,$15,$80,$39,$01,$fc,$15,$80
    db $3d,$01,$c0,$15,$80,$0f,$1f,$80,$15,$e0,$01,$01,$00,$15,$f0,$07,$01,$3c,$15,$f0,$07,$01,$1c,$15
    db $f0,$07,$01,$8c,$15,$f0,$01,$21,$8c,$15,$e0,$07,$01,$88,$15,$80,$0f,$03,$18,$15,$80,$3c,$03,$30
    db $15,$81,$38,$83,$18,$15,$83,$18,$c3,$00,$12,$c3,$18,$12,$c3,$00
ace17_s4:
    db $00,$00,$00,$00,$00,$00,$00,$00,$cf,$21,$c0,$1f,$7f,$00,$21,$c0,$1f,$7f,$00,$18,$fc,$00,$00,$1a
    db $7f,$00,$18,$fc,$01,$00,$c7,$7f,$00,$18,$fc,$00,$00,$6b,$7f,$00,$18,$fc,$00,$00,$e8,$7f,$00,$18
    db $f8,$01,$00,$e8,$1f,$00,$f1,$f1,$18,$f8,$03,$00,$dc,$1f,$00,$15,$f8,$00,$01,$f8,$18,$fe,$00,$00
    db $10,$1f,$00,$21,$00,$73,$1f,$c0,$21,$00,$71,$1f,$c0,$21,$00,$78,$1f,$c0,$21,$02,$18,$1f,$c0,$18
    db $fe,$00,$00,$78,$1f,$80,$18,$f8,$00,$00,$f1,$3f,$80,$18,$f8,$03,$00,$c3,$3f,$00,$18,$f8,$03,$18
    db $81,$3f,$80,$18,$f8,$01,$3c,$80,$3f,$00,$15,$fc,$01,$3f,$80,$15,$fc,$00,$3f,$00
ace18:
    dw ace18_s0
    dw ace18_s4
ace18_s0:
    db $00,$00,$00,$00,$00,$00,$00,$00,$7e,$d8,$15,$80,$07,$0f,$e0,$15,$00,$27,$0f,$00,$15,$00,$60,$0f
    db $e0,$15,$00,$13,$0f,$40,$09,$fe,$00,$00,$7e,$1f,$00,$0c,$fc,$00,$00,$fe,$00,$00,$7f,$00,$bb,$0c
    db $fc,$01,$00,$cf,$00,$b8,$7f,$00,$09,$fc,$00,$00,$fd,$03,$00,$09,$fe,$00,$00,$1a,$7f,$00,$15,$00
    db $20,$0f,$00,$ca,$15,$00,$3c,$07,$70,$15,$80,$1e,$07,$70,$15,$c0,$06,$07,$60,$15,$80,$0e,$0f,$c0
    db $15,$00,$3c,$1f,$c0,$15,$00,$70,$1f,$c0,$15,$06,$70,$1f,$00,$12,$07,$60,$12,$07,$30,$12,$87,$00
ace18_s4:
    db $00,$00,$00,$00,$00,$00,$00,$00,$1e,$80,$00,$1e,$00,$3e,$15,$f8,$00,$00,$7e,$15,$f0,$02,$00,$70
    db $15,$f0,$06,$00,$0e,$15,$f0,$01,$00,$34,$15,$e0,$07,$01,$e0,$18,$c0,$0f,$00,$e0,$07,$00,$18,$c0
    db $1c,$00,$7f,$07,$f0,$18,$c0,$1c,$00,$fb,$07,$80,$18,$c0,$0f,$00,$d0,$3f,$00,$15,$e0,$01,$07,$a0
    db $15,$f0,$02,$00,$00,$6b,$18,$f0,$03,$00,$c7,$7f,$00,$18,$f8,$01,$00,$e7,$7f,$00,$18,$fc,$00,$00
    db $66,$7f,$00,$15,$f8,$00,$00,$ec,$15,$f0,$03,$01,$cc,$15,$f0,$07,$01,$0c,$15,$f0,$07,$61,$00,$15
    db $f0,$06,$7f,$00,$15,$f0,$03,$7f,$00,$15,$f8,$00,$7f,$00
ace19:
    dw ace19_s0
    dw ace19_s4
ace19_s0:
    db $00,$00,$00,$00,$00,$00,$00,$7e,$d8,$15,$f0,$07,$0f,$60,$15,$f0,$06,$0f,$80,$15,$80,$01,$1f,$c0
    db $09,$fe,$00,$00,$3a,$1f,$c0,$09,$fc,$00,$00,$fe,$0f,$00,$0c,$fc,$01,$00,$f6,$00,$e0,$7f,$00,$bb
    db $0c,$fc,$01,$00,$eb,$00,$38,$7f,$00,$09,$fc,$00,$00,$7d,$03,$00,$15,$00,$0c,$7f,$00,$15,$80,$0f
    db $1f,$00,$15,$80,$2d,$0f,$c0,$15,$80,$3e,$07,$e0,$15,$80,$0f,$07,$70,$15,$e0,$07,$07,$70,$15,$f0
    db $03,$07,$e0,$d7,$15,$e0,$06,$1f,$00,$15,$e0,$0f,$7f,$00,$15,$e0,$0b,$3f,$00,$15,$e0,$03,$1f,$80
    db $d2,$15,$f8,$00,$1f,$00
ace19_s4:
    db $00,$00,$00,$00,$00,$00,$00,$1e,$80,$00,$1e,$00,$3e,$1e,$00,$76,$1e,$00,$68,$15,$f8,$00,$01,$1c
    db $15,$e0,$03,$01,$ac,$15,$c0,$0f,$00,$e0,$18,$c0,$1f,$00,$6e,$07,$00,$18,$c0,$1c,$00,$7f,$07,$f0
    db $18,$c0,$1e,$00,$b3,$07,$80,$18,$c0,$07,$00,$d0,$3f,$00,$15,$f0,$00,$07,$c0,$d6,$15,$f8,$02,$00
    db $dc,$18,$f8,$03,$00,$ee,$7f,$00,$18,$f8,$00,$00,$f7,$7f,$00,$18,$fe,$00,$00,$77,$7f,$00,$d0,$1e
    db $00,$7c,$15,$fe,$00,$01,$60,$15,$fe,$00,$07,$f0,$15,$fe,$00,$03,$b0,$15,$fe,$00,$01,$38,$1e,$81
    db $3c,$1e,$81,$00
ace20:
    dw ace20_s0
    dw ace20_s4
ace20_s0:
    db $00,$00,$00,$00,$00,$00,$78,$88,$09,$fc,$00,$20,$0f,$3f,$80,$09,$fc,$01,$00,$8f,$3f,$00,$09,$fc
    db $00,$00,$c3,$3f,$80,$09,$fe,$00,$00,$0d,$3f,$00,$15,$00,$1c,$7f,$00,$09,$fe,$00,$00,$7e,$1f,$00
    db $0c,$fe,$00,$00,$ff,$00,$40,$3f,$00,$0c,$fe,$00,$00,$e7,$00,$39,$3f,$80,$0c,$fe,$00,$00,$c2,$00
    db $fe,$3f,$00,$09,$fe,$00,$00,$f4,$00,$10,$09,$fe,$00,$00,$7e,$07,$b0,$15,$00,$00,$07,$00,$15,$80
    db $3b,$3f,$80,$af,$15,$00,$39,$0f,$c0,$15,$00,$78,$0f,$e0,$09,$fe,$00,$02,$70,$0f,$60,$09,$fe,$00
    db $06,$f0,$0f,$e0,$09,$fe,$00,$06,$c0,$0f,$c0,$09,$fc,$00,$1e,$00,$0f,$00,$67,$09,$f8,$03,$1e,$80
    db $03,$70,$09,$f8,$03,$1e,$c0,$03,$f8,$09,$f8,$00,$1e,$00,$03,$00
ace20_s4:
    db $00,$00,$00,$00,$00,$00,$75,$86,$15,$c2,$00,$03,$f8,$15,$c0,$18,$03,$f0,$15,$c0,$0c,$03,$38,$15
    db $e0,$00,$03,$d0,$15,$f0,$01,$07,$c0,$15,$e0,$07,$01,$e0,$18,$e0,$0f,$00,$f4,$03,$00,$18,$e0,$0e
    db $00,$73,$03,$98,$18,$e0,$0c,$00,$2f,$03,$e0,$18,$e0,$0f,$00,$41,$0f,$00,$18,$e0,$07,$00,$eb,$7f
    db $00,$18,$f0,$00,$00,$00,$7f,$00,$15,$f8,$03,$03,$b8,$b4,$15,$f0,$03,$00,$9c,$15,$f0,$07,$00,$8e
    db $15,$e0,$07,$20,$06,$15,$e0,$0f,$60,$0e,$15,$e0,$0c,$60,$0c,$15,$c1,$00,$e0,$00,$66,$18,$81,$38
    db $e0,$07,$3f,$00,$18,$81,$3c,$e0,$0f,$3f,$80,$18,$81,$00,$e0,$00,$3f,$00
ace21:
    dw ace21_s0
    dw ace21_s4
ace21_s0:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$b6,$15,$c0,$0f,$7f,$00,$ae,$09,$f8,$00,$00,$18
    db $7f,$00,$09,$f8,$03,$00,$87,$7f,$00,$09,$f8,$00,$00,$2a,$7f,$00,$0c,$fe,$00,$00,$f8,$80,$00,$1f
    db $00,$0c,$fc,$00,$00,$e0,$00,$3f,$1f,$c0,$0c,$fc,$01,$00,$c6,$00,$ff,$1f,$c0,$0c,$fc,$01,$00,$e6
    db $00,$30,$1f,$00,$09,$fc,$00,$00,$fe,$87,$20,$09,$fe,$00,$00,$04,$0f,$00,$09,$fe,$00,$00,$83,$1f
    db $c0,$09,$fe,$00,$00,$71,$1f,$c0,$15,$00,$38,$1f,$c0,$09,$f8,$00,$02,$18,$1f,$80,$09,$f0,$03,$00
    db $f8,$1f,$c0,$09,$f0,$07,$00,$71,$07,$c0,$09,$f0,$07,$04,$81,$07,$f0,$09,$f0,$00,$3c,$00,$07,$00
ace21_s4:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$85,$15,$fc,$00,$07,$f0,$8b,$15,$80,$01,$07,$80
    db $15,$80,$38,$07,$70,$15,$80,$02,$07,$a0,$18,$e0,$0f,$08,$80,$01,$00,$18,$c0,$0e,$00,$03,$01,$fc
    db $18,$c0,$1c,$00,$6f,$01,$fc,$18,$c0,$1e,$00,$63,$01,$00,$18,$c0,$0f,$08,$e2,$7f,$00,$15,$e0,$00
    db $00,$40,$15,$e0,$08,$01,$3c,$15,$e0,$07,$01,$1c,$15,$f0,$03,$01,$8c,$15,$80,$01,$21,$88,$15,$00
    db $3f,$01,$8c,$18,$00,$77,$00,$1c,$7f,$00,$18,$00,$78,$40,$1f,$7f,$00,$18,$03,$00,$c0,$00,$7f,$00
ace22:
    dw ace22_s0
    dw ace22_s4
ace22_s0:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$89,$15,$80,$1f,$7f,$00,$15,$80,$3d
    db $7f,$00,$09,$f8,$00,$00,$38,$7f,$00,$09,$f8,$03,$00,$87,$7f,$00,$09,$f8,$02,$00,$52,$7f,$00,$06
    db $f8,$01,$00,$f0,$0c,$fc,$01,$00,$f8,$00,$00,$0f,$00,$0c,$fc,$01,$00,$c6,$00,$ff,$0f,$e0,$0c,$fc
    db $01,$00,$e0,$00,$df,$0f,$00,$0c,$fc,$00,$00,$ff,$00,$30,$7f,$00,$09,$f8,$00,$00,$3e,$07,$00,$09
    db $f0,$02,$00,$31,$3f,$80,$09,$e0,$07,$00,$f3,$3f,$80,$09,$e0,$0e,$00,$e3,$0f,$80,$09,$e0,$0f,$08
    db $03,$0f,$e0,$09,$e0,$00,$78,$00,$0f,$00
ace22_s4:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$77,$15,$f8,$01,$07,$f0,$15,$f8,$03
    db $07,$d0,$15,$80,$03,$07,$80,$15,$80,$38,$07,$70,$15,$80,$25,$07,$20,$15,$80,$1f,$0f,$00,$18,$c0
    db $1f,$00,$80,$00,$00,$18,$c0,$1c,$00,$6f,$00,$fe,$18,$c0,$1e,$00,$0d,$00,$f0,$18,$c0,$0f,$00,$f3
    db $07,$00,$18,$80,$03,$00,$e0,$7f,$00,$15,$00,$23,$03,$18,$09,$fe,$00,$00,$7f,$03,$38,$09,$fe,$00
    db $00,$ee,$00,$38,$09,$fe,$00,$00,$f0,$80,$3e,$09,$fe,$00,$07,$00,$80,$00
ace23:
    dw ace23_s0
    dw ace23_s0
ace23_s0:
    db $00,$00,$00,$00,$15,$f0,$00,$3f,$00,$15,$e0,$07,$1f,$80,$73,$09,$fe,$00,$00,$0f,$1f,$00,$09,$fe
    db $00,$00,$e3,$3f,$80,$09,$fe,$00,$00,$65,$3f,$80,$7c,$7b,$0c,$fe,$00,$00,$77,$00,$40,$3f,$00,$0c
    db $fe,$00,$00,$e0,$00,$19,$3f,$80,$0c,$fe,$00,$00,$c3,$00,$fe,$3f,$00,$09,$fe,$00,$00,$e5,$00,$d0
    db $09,$fe,$00,$00,$fe,$07,$30,$09,$fe,$00,$00,$6e,$87,$00,$15,$00,$00,$3f,$00,$15,$c0,$19,$1f,$80
    db $15,$c0,$1f,$0f,$c0,$15,$c0,$1d,$0f,$e0,$15,$c0,$1c,$07,$e0,$15,$00,$1c,$07,$70,$15,$01,$78,$07
    db $30,$15,$03,$78,$07,$70,$15,$03,$70,$07,$60,$09,$fe,$00,$07,$40,$07,$20,$09,$fc,$00,$1f,$c0,$03
    db $30,$09,$fc,$01,$0f,$c0,$01,$78,$09,$fc,$01,$0f,$e0,$01,$7c,$09,$fc,$00,$0f,$00,$01,$00
ace24:
    dw ace24_s0
    dw ace24_s0
ace24_s0:
    db $00,$00,$00,$00,$00,$00,$89,$ae,$15,$c0,$1d,$7f,$00,$15,$00,$1a,$7f,$00,$0c,$f8,$00,$00,$47,$78
    db $00,$7f,$00,$0c,$f8,$03,$00,$8b,$70,$03,$7f,$00,$0c,$f8,$00,$00,$70,$00,$06,$7f,$00,$09,$fc,$00
    db $00,$fd,$00,$fe,$09,$f8,$01,$00,$cf,$00,$f8,$09,$f8,$03,$00,$c3,$03,$b0,$09,$f8,$01,$00,$fd,$07
    db $c0,$09,$fc,$00,$00,$0d,$07,$80,$15,$e0,$01,$00,$f0,$93,$18,$f8,$01,$00,$7f,$7f,$00,$18,$f8,$03
    db $00,$87,$7f,$00,$18,$f8,$03,$20,$8e,$7f,$00,$18,$e0,$03,$20,$80,$7f,$00,$18,$c0,$0f,$38,$83,$7f
    db $00,$18,$c0,$1f,$30,$03,$1f,$00,$18,$c0,$0e,$70,$07,$1f,$c0,$18,$80,$18,$f0,$06,$1f,$00,$15,$03
    db $38,$f0,$00,$12,$01,$78,$12,$01,$1c,$12,$c1,$00
ace25:
    dw ace25_s0
    dw ace25_s0
ace25_s0:
    db $00,$00,$00,$00,$00,$00,$00,$15,$fc,$00,$3f,$00,$09,$f8,$00,$38,$01,$3f,$80,$09,$f0,$03,$30,$83
    db $3f,$00,$09,$e0,$07,$00,$06,$7f,$00,$09,$e0,$0e,$00,$cc,$0f,$00,$09,$e0,$0e,$00,$d8,$0f,$e0,$09
    db $e0,$04,$00,$19,$0f,$c0,$09,$e0,$00,$00,$2d,$1f,$80,$09,$e0,$0b,$00,$fd,$01,$00,$09,$e0,$0b,$00
    db $98,$00,$1c,$0c,$e0,$03,$00,$32,$00,$fe,$7f,$00,$0c,$f8,$03,$00,$ed,$00,$ff,$7f,$00,$0c,$f8,$01
    db $00,$cb,$00,$67,$7f,$00,$0c,$fc,$00,$00,$07,$00,$06,$3f,$00,$18,$f0,$07,$10,$81,$07,$80,$18,$f0
    db $01,$0c,$c1,$07,$f0,$18,$fc,$01,$0c,$e1,$07,$f0,$18,$fc,$00,$0c,$e0,$07,$c0,$18,$fc,$01,$0e,$e0
    db $1f,$00,$15,$fc,$01,$0f,$c0,$15,$fc,$01,$1f,$80,$15,$f8,$01,$1f,$80,$15,$f8,$03,$0f,$c0,$b2,$7e
ace26:
    dw ace26_s0
    dw ace26_s0
ace26_s0:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$15,$fe,$00,$3f,$00,$15,$fc,$00,$3f,$80,$15,$c0,$01
    db $3f,$80,$09,$f0,$00,$c0,$1b,$3f,$80,$09,$e0,$06,$80,$12,$3f,$00,$09,$c0,$0c,$00,$37,$7f,$00,$09
    db $c0,$19,$00,$26,$41,$00,$09,$c0,$1b,$00,$70,$80,$1c,$09,$c0,$18,$03,$38,$00,$3e,$0c,$c0,$08,$02
    db $b8,$00,$7e,$03,$00,$0c,$c0,$09,$00,$a0,$00,$f7,$03,$b8,$0c,$c0,$1e,$08,$21,$00,$e1,$03,$f0,$0c
    db $c0,$1f,$00,$63,$00,$80,$07,$e0,$0c,$c0,$07,$00,$c6,$00,$7c,$0f,$40,$0c,$f0,$03,$00,$dd,$00,$fe
    db $1f,$00,$0c,$f8,$01,$00,$3f,$00,$17,$03,$00,$0c,$fc,$00,$00,$7f,$40,$0e,$03,$98,$18,$00,$0f,$60
    db $07,$03,$f8,$18,$e0,$00,$70,$00,$03,$f0,$21,$fe,$00,$07,$60,$27,$0f,$00
ace27:
    dw ace27_s0
    dw ace27_s0
ace27_s0:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$12,$f0,$00,$12,$e0,$06
    db $06,$fe,$00,$00,$0e,$06,$fc,$00,$00,$9c,$06,$fc,$01,$01,$b8,$09,$fc,$01,$01,$30,$c1,$00,$0c,$00
    db $01,$01,$04,$01,$1c,$8f,$00,$0c,$00,$6d,$00,$c8,$00,$7c,$0f,$20,$0c,$00,$6d,$00,$d9,$00,$f1,$0f
    db $e0,$0c,$00,$6d,$00,$9d,$00,$c0,$00,$40,$0c,$00,$6b,$00,$f1,$00,$ff,$00,$86,$0c,$00,$79,$00,$f7
    db $00,$df,$00,$fe,$0c,$00,$70,$00,$61,$00,$83,$00,$bc,$0c,$07,$00,$0c,$00,$38,$00,$01,$00
ace28:
    dw ace28_s0
    dw ace28_s0
ace28_s0:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $00,$09,$e0,$00,$00,$00,$01,$00,$09,$e0,$0f,$00,$7d,$01,$3c,$0c,$e0,$0f,$00,$bf,$00,$f0,$18,$00
    db $0c,$e0,$0f,$00,$72,$00,$6f,$00,$c2,$0c,$00,$0f,$00,$7e,$00,$4f,$00,$fe,$0c,$00,$7c,$00,$3e,$00
    db $fd,$00,$fe,$0c,$01,$00,$80,$00,$00,$00,$00,$00
zombie_left_0:
    dw zombie_left_0_s0
    dw zombie_left_0_s4
zombie_left_0_s0:
    db $00,$12,$81,$00,$12,$00,$3c,$12,$00,$7e,$12,$00,$72,$12,$00,$58,$15,$00,$6c,$3f,$00,$15,$00,$1f
    db $1f,$80,$15,$c0,$17,$0f,$c0,$c7,$c3,$15,$f0,$07,$03,$b8,$15,$f0,$01,$03,$30,$15,$f0,$03,$03,$38
    db $15,$e0,$07,$03,$38,$15,$c0,$0e,$03,$30,$15,$80,$1c,$03,$38,$15,$80,$39,$03,$f8,$15,$80,$31,$03
    db $b8,$15,$80,$12,$03,$c0,$15,$c0,$06,$07,$f0,$15,$e0,$06,$07,$e0,$15,$e0,$0c,$03,$e0,$15,$e0,$04
    db $01,$78,$15,$f0,$06,$01,$7c,$18,$f0,$06,$00,$10,$7f,$00,$18,$f0,$04,$c0,$07,$7f,$00,$18,$f0,$00
    db $f0,$07,$7f,$00,$18,$e0,$06,$f0,$06,$7f,$00,$15,$80,$0e,$e0,$06,$15,$80,$3a,$e0,$0e,$15,$80,$00
    db $e0,$00
zombie_left_0_s4:
    db $00,$15,$f8,$00,$1f,$00,$d9,$15,$f0,$07,$0f,$e0,$15,$f0,$07,$0f,$20,$15,$f0,$05,$0f,$80,$15,$f0
    db $06,$03,$c0,$15,$f0,$01,$01,$f8,$15,$fc,$01,$00,$7c,$c0,$be,$21,$00,$7b,$3f,$80,$21,$00,$13,$3f
    db $00,$21,$00,$33,$3f,$80,$18,$fe,$00,$00,$73,$3f,$80,$ec,$18,$f8,$01,$00,$c3,$3f,$80,$18,$f8,$03
    db $00,$9f,$3f,$80,$18,$f8,$03,$00,$1b,$3f,$80,$18,$f8,$01,$00,$2c,$3f,$00,$18,$fc,$00,$00,$6f,$7f
    db $00,$18,$fe,$00,$00,$6e,$7f,$00,$18,$fe,$00,$00,$ce,$3f,$00,$18,$fe,$00,$00,$47,$1f,$80,$21,$00
    db $67,$1f,$c0,$21,$00,$61,$07,$00,$21,$0c,$40,$07,$70,$21,$0f,$00,$07,$70,$18,$fe,$00,$0f,$60,$07
    db $60,$18,$f8,$00,$0e,$e0,$0f,$60,$18,$f8,$03,$0e,$a0,$0f,$e0,$18,$f8,$00,$0e,$00,$0f,$00
zombie_left_1:
    dw zombie_left_1_s0
    dw zombie_left_1_s4
zombie_left_1_s0:
    db $00,$12,$03,$00,$06,$fe,$00,$01,$78,$06,$fe,$00,$01,$fc,$06,$fe,$00,$01,$a4,$06,$fe,$00,$01,$b0
    db $09,$fe,$00,$00,$dc,$3f,$00,$09,$fe,$00,$00,$17,$1f,$80,$15,$80,$27,$0f,$c0,$15,$80,$05,$07,$e0
    db $15,$f0,$07,$07,$f0,$15,$f0,$01,$07,$30,$15,$f8,$02,$03,$30,$15,$c0,$03,$01,$78,$15,$00,$1e,$01
    db $7c,$09,$fc,$00,$00,$7c,$01,$30,$09,$fc,$01,$00,$e0,$03,$28,$09,$fc,$01,$0c,$c1,$03,$78,$09,$fc
    db $01,$1c,$81,$03,$78,$09,$fc,$00,$30,$80,$03,$a8,$09,$fe,$00,$20,$04,$03,$c0,$15,$e0,$0c,$0f,$e0
    db $15,$e0,$08,$0f,$e0,$15,$e0,$0c,$01,$e0,$15,$e0,$06,$01,$7c,$18,$f0,$06,$00,$14,$7f,$00,$18,$f0
    db $00,$c0,$07,$3f,$00,$18,$f0,$00,$f0,$03,$3f,$80,$18,$c0,$06,$f8,$03,$3f,$80,$18,$c0,$1e,$f0,$03
    db $3f,$00,$18,$c0,$00,$f0,$05,$7f,$00,$21,$f0,$00,$7f,$00
zombie_left_1_s4:
    db $00,$15,$f0,$00,$3f,$00,$15,$e0,$07,$1f,$80,$73,$15,$e0,$0a,$1f,$40,$15,$e0,$0b,$1f,$00,$15,$e0
    db $0d,$03,$c0,$15,$e0,$01,$01,$78,$15,$f8,$02,$00,$7c,$f3,$21,$00,$7f,$7f,$00,$21,$00,$13,$7f,$00
    db $21,$80,$23,$3f,$00,$18,$fc,$00,$00,$37,$1f,$80,$18,$f0,$01,$00,$e7,$1f,$c0,$18,$c0,$07,$00,$c3
    db $1f,$00,$18,$c0,$1e,$00,$02,$3f,$80,$18,$c0,$1c,$c0,$17,$3f,$80,$18,$c1,$18,$c0,$17,$3f,$80,$18
    db $c3,$08,$00,$0a,$3f,$80,$18,$e2,$00,$00,$4c,$3f,$00,$15,$fe,$00,$00,$ce,$15,$fe,$00,$00,$8e,$18
    db $fe,$00,$00,$ce,$1f,$00,$18,$fe,$00,$00,$67,$1f,$c0,$21,$00,$61,$07,$40,$21,$0c,$00,$03,$70,$21
    db $0f,$00,$03,$38,$18,$fc,$00,$0f,$60,$83,$38,$18,$fc,$01,$0f,$e0,$03,$30,$18,$fc,$00,$0f,$00,$07
    db $50,$27,$07,$00
zombie_left_2:
    dw zombie_left_2_s0
    dw zombie_left_2_s4
zombie_left_2_s0:
    db $00,$12,$83,$00,$12,$01,$38,$12,$01,$7c,$12,$01,$74,$12,$01,$58,$15,$00,$78,$3f,$00,$15,$00,$17
    db $0f,$80,$15,$80,$32,$0f,$e0,$15,$80,$05,$0f,$e0,$c3,$15,$f0,$01,$03,$a8,$15,$c0,$02,$03,$38,$09
    db $fc,$00,$00,$1f,$03,$18,$09,$fc,$01,$00,$ff,$01,$38,$09,$fc,$01,$00,$c0,$01,$14,$09,$fc,$01,$1e
    db $80,$01,$7c,$09,$fc,$00,$3e,$00,$01,$fc,$15,$fe,$00,$01,$3c,$15,$f0,$00,$01,$44,$15,$f0,$04,$01
    db $e0,$15,$e0,$04,$0f,$e0,$15,$e0,$0c,$0f,$e0,$15,$e0,$04,$01,$e0,$15,$f0,$06,$01,$7c,$18,$f0,$06
    db $00,$1c,$7f,$00,$18,$f0,$06,$c0,$0b,$3f,$00,$18,$f0,$04,$e0,$03,$3f,$80,$18,$80,$04,$f8,$03,$3f
    db $80,$18,$80,$3e,$f0,$03,$3f,$00,$18,$80,$04,$f0,$07,$7f,$00,$18,$f1,$00,$f0,$00,$7f,$00
zombie_left_2_s4:
    db $00,$15,$f8,$00,$3f,$00,$15,$f0,$03,$1f,$80,$15,$f0,$07,$1f,$c0,$15,$f0,$07,$1f,$40,$15,$f0,$05
    db $1f,$80,$15,$f0,$07,$03,$80,$15,$f0,$01,$00,$78,$15,$f8,$03,$00,$2e,$15,$f8,$00,$00,$5e,$be,$21
    db $00,$1a,$3f,$80,$18,$fc,$00,$00,$23,$3f,$80,$18,$c0,$01,$00,$f1,$3f,$80,$18,$c0,$1f,$00,$f3,$1f
    db $80,$18,$c0,$1c,$00,$01,$1f,$40,$18,$c1,$18,$e0,$07,$1f,$c0,$18,$c3,$00,$e0,$0f,$1f,$c0,$21,$e0
    db $03,$1f,$c0,$21,$00,$04,$1f,$40,$21,$00,$4e,$1f,$00,$15,$fe,$00,$00,$4e,$15,$fe,$00,$00,$ce,$18
    db $fe,$00,$00,$4e,$1f,$00,$21,$00,$67,$1f,$c0,$21,$00,$61,$07,$c0,$21,$0c,$60,$03,$b0,$21,$0e,$40
    db $03,$38,$18,$f8,$00,$0f,$40,$83,$38,$18,$f8,$03,$0f,$e0,$03,$30,$18,$f8,$00,$0f,$40,$07,$70,$21
    db $1f,$00,$07,$00
zombie_left_3:
    dw zombie_left_3_s0
    dw zombie_left_3_s4
zombie_left_3_s0:
    db $00,$12,$83,$00,$12,$01,$38,$06,$fe,$00,$00,$7c,$06,$fe,$00,$00,$f2,$06,$fe,$00,$00,$98,$09,$fe
    db $00,$00,$70,$3f,$00,$15,$00,$17,$1f,$80,$15,$80,$37,$0f,$c0,$15,$80,$07,$0f,$e0,$c3,$15,$f0,$03
    db $03,$a8,$15,$c0,$03,$03,$38,$09,$fc,$00,$00,$1f,$03,$38,$09,$f8,$01,$00,$fe,$03,$38,$09,$f8,$03
    db $00,$88,$03,$18,$09,$f8,$03,$22,$00,$03,$b8,$09,$f8,$00,$7e,$00,$03,$f8,$15,$fe,$00,$03,$b8,$15
    db $f8,$00,$03,$40,$15,$f0,$02,$07,$70,$15,$f0,$06,$07,$70,$15,$f0,$06,$07,$60,$15,$f0,$06,$00,$70
    db $15,$f0,$03,$00,$3e,$18,$f8,$03,$00,$0e,$1f,$00,$18,$f8,$03,$60,$03,$1f,$c0,$18,$f8,$00,$78,$01
    db $1f,$c0,$18,$f0,$03,$7c,$01,$1f,$80,$18,$c0,$07,$78,$01,$3f,$80,$18,$c0,$1d,$78,$03,$3f,$80,$18
    db $c0,$00,$78,$00,$3f,$00
zombie_left_3_s4:
    db $00,$15,$f8,$00,$3f,$00,$15,$f0,$03,$1f,$80,$15,$e0,$07,$0f,$c0,$15,$e0,$0f,$0f,$20,$15,$e0,$09
    db $0f,$80,$15,$e0,$07,$03,$00,$15,$f0,$01,$01,$78,$15,$f8,$03,$00,$7c,$15,$f8,$00,$00,$7e,$be,$21
    db $00,$3a,$3f,$80,$18,$fc,$00,$00,$33,$3f,$80,$18,$c0,$01,$00,$f3,$3f,$80,$18,$80,$1f,$00,$e3,$3f
    db $80,$18,$80,$38,$00,$81,$3f,$80,$18,$82,$30,$20,$0b,$3f,$80,$18,$87,$00,$e0,$0f,$3f,$80,$21,$e0
    db $0b,$3f,$80,$21,$80,$04,$3f,$00,$21,$00,$27,$7f,$00,$21,$00,$67,$7f,$00,$21,$00,$66,$7f,$00,$21
    db $00,$67,$0f,$00,$21,$00,$33,$0f,$e0,$21,$80,$30,$01,$e0,$21,$86,$30,$01,$3c,$21,$87,$00,$81,$1c
    db $21,$07,$30,$c1,$18,$18,$fc,$00,$07,$70,$83,$18,$18,$fc,$01,$07,$d0,$83,$38,$18,$fc,$00,$07,$00
    db $83,$00
zombie_left_4:
    dw zombie_left_4_s0
    dw zombie_left_4_s4
zombie_left_4_s0:
    db $00,$12,$c1,$00,$15,$80,$1c,$7f,$00,$15,$00,$3f,$7f,$00,$15,$00,$79,$7f,$00,$15,$00,$2c,$7f,$00
    db $15,$00,$7c,$3f,$00,$15,$00,$07,$0f,$80,$15,$e0,$0b,$07,$e0,$15,$e0,$03,$07,$f0,$d6,$09,$f8,$00
    db $00,$03,$01,$1c,$09,$f8,$03,$00,$ff,$01,$10,$09,$f8,$03,$00,$9f,$03,$38,$0c,$f8,$03,$00,$06,$00
    db $38,$7f,$00,$0c,$f8,$00,$70,$00,$80,$1f,$7f,$00,$18,$fe,$00,$00,$3e,$7f,$00,$15,$fe,$00,$00,$be
    db $15,$f8,$00,$00,$9a,$15,$f8,$02,$00,$22,$15,$f0,$02,$00,$60,$15,$f0,$06,$07,$70,$15,$f0,$06,$07
    db $60,$15,$f0,$04,$00,$70,$18,$f0,$06,$00,$7e,$3f,$00,$18,$f0,$03,$00,$0f,$1f,$80,$18,$f8,$03,$20
    db $01,$1f,$c0,$18,$f8,$01,$3c,$80,$1f,$c0,$18,$f8,$00,$1c,$80,$1f,$80,$18,$f0,$03,$1c,$c1,$3f,$80
    db $18,$f0,$07,$1c,$c0,$3f,$00,$15,$f0,$00,$1f,$00
zombie_left_4_s4:
    db $00,$15,$fc,$00,$1f,$00,$15,$f8,$01,$07,$c0,$15,$f0,$03,$07,$f0,$15,$f0,$07,$07,$90,$15,$f0,$02
    db $07,$c0,$15,$f0,$07,$03,$c0,$15,$f0,$00,$00,$78,$18,$fe,$00,$00,$be,$7f,$00,$18,$fe,$00,$00,$3f
    db $7f,$00,$21,$80,$0f,$1f,$00,$18,$80,$00,$00,$31,$1f,$c0,$18,$80,$3f,$00,$f1,$1f,$00,$18,$80,$39
    db $00,$f3,$3f,$80,$18,$80,$30,$00,$63,$07,$80,$18,$87,$00,$08,$01,$07,$f0,$21,$e0,$03,$07,$e0,$21
    db $e0,$0b,$0f,$e0,$21,$80,$09,$0f,$a0,$21,$80,$22,$0f,$20,$21,$00,$26,$0f,$00,$21,$00,$67,$7f,$00
    db $21,$00,$66,$7f,$00,$21,$00,$47,$0f,$00,$21,$00,$67,$03,$e0,$21,$00,$30,$01,$f8,$21,$82,$30,$01
    db $1c,$21,$83,$18,$c1,$0c,$21,$81,$08,$c1,$08,$21,$01,$3c,$c3,$18,$21,$01,$7c,$c3,$00,$1e,$01,$00
zombie_left_5:
    dw zombie_left_5_s0
    dw zombie_left_5_s4
zombie_left_5_s0:
    db $00,$00,$12,$c0,$00,$15,$80,$1e,$7f,$00,$15,$80,$3f,$7f,$00,$15,$80,$39,$7f,$00,$15,$80,$2c,$7f
    db $00,$15,$80,$3c,$0f,$00,$15,$80,$05,$07,$e0,$15,$e0,$08,$03,$f0,$15,$e0,$01,$03,$f8,$15,$fc,$00
    db $01,$50,$09,$f8,$00,$00,$01,$01,$9c,$09,$f8,$03,$00,$ff,$01,$8c,$09,$f8,$02,$00,$df,$00,$1c,$09
    db $f8,$03,$00,$02,$40,$16,$09,$f8,$00,$78,$00,$00,$1e,$1e,$00,$5e,$1e,$00,$4e,$15,$fc,$00,$00,$02
    db $15,$fc,$01,$00,$38,$15,$f8,$01,$03,$38,$15,$f8,$03,$00,$30,$18,$f8,$03,$00,$36,$7f,$00,$18,$f8
    db $01,$00,$1f,$0f,$00,$18,$fc,$01,$00,$87,$0f,$e0,$18,$fc,$01,$10,$80,$0f,$e0,$18,$fc,$00,$1e,$c0
    db $0f,$60,$18,$fc,$00,$0f,$40,$0f,$60,$18,$f0,$01,$0e,$e0,$0f,$60,$18,$f0,$07,$0e,$e0,$0f,$e0,$18
    db $f0,$00,$0e,$00,$0f,$00
zombie_left_5_s4:
    db $00,$00,$15,$fc,$00,$0f,$00,$15,$f8,$01,$07,$e0,$b3,$15,$f8,$03,$07,$90,$15,$f8,$02,$07,$c0,$15
    db $f8,$03,$00,$c0,$f3,$18,$fe,$00,$00,$8f,$3f,$00,$18,$fe,$00,$00,$1f,$3f,$80,$21,$c0,$05,$1f,$00
    db $18,$80,$00,$00,$19,$1f,$c0,$18,$80,$3f,$00,$f8,$1f,$c0,$18,$80,$2d,$00,$f1,$0f,$c0,$18,$80,$30
    db $04,$21,$0f,$60,$18,$87,$00,$80,$01,$0f,$e0,$21,$f0,$05,$0f,$e0,$21,$f0,$04,$0f,$e0,$21,$c0,$00
    db $0f,$20,$21,$c0,$13,$0f,$80,$21,$80,$13,$3f,$80,$21,$80,$33,$0f,$00,$21,$80,$33,$07,$60,$21,$80
    db $11,$00,$f0,$21,$c0,$18,$00,$7e,$21,$c1,$18,$00,$0e,$21,$c1,$0c,$e0,$06,$21,$c0,$04,$f0,$06,$21
    db $00,$1e,$e0,$06,$21,$00,$7e,$e0,$0e,$21,$00,$00,$e0,$00
zombie_left_6:
    dw zombie_left_6_s0
    dw zombie_left_6_s0
zombie_left_6_s0:
    db $00,$1e,$81,$00,$1e,$80,$3c,$1e,$00,$3e,$1e,$00,$5a,$1e,$00,$7a,$15,$03,$00,$00,$10,$15,$01,$78
    db $03,$60,$15,$00,$5c,$00,$08,$15,$00,$47,$00,$1e,$15,$10,$04,$00,$3e,$18,$f0,$00,$00,$76,$7f,$00
    db $18,$f8,$02,$00,$e3,$7f,$00,$18,$f0,$03,$00,$c3,$7f,$00,$18,$e0,$07,$00,$8f,$7f,$00,$18,$e0,$0f
    db $00,$9e,$7f,$00,$15,$e0,$05,$00,$80,$15,$c0,$0a,$3f,$00,$15,$c0,$1f,$1f,$00,$15,$80,$1e,$1f,$c0
    db $af,$15,$80,$33,$3f,$80,$15,$80,$31,$1f,$80,$15,$80,$31,$07,$c0,$15,$80,$39,$07,$f0,$15,$80,$38
    db $03,$b0,$15,$82,$10,$00,$28,$15,$c1,$00,$80,$2e,$15,$c1,$0c,$80,$0c,$15,$01,$1c,$c0,$06,$15,$01
    db $74,$c0,$1e,$15,$01,$00,$c0,$00
zombie_left_7:
    dw zombie_left_7_s0
    dw zombie_left_7_s0
zombie_left_7_s0:
    db $00,$00,$00,$1e,$81,$00,$1e,$80,$3c,$d0,$18,$0f,$00,$00,$7b,$7f,$00,$0c,$fe,$00,$07,$60,$00,$3b
    db $7f,$00,$0c,$fe,$00,$03,$f0,$00,$12,$7f,$00,$09,$fe,$00,$00,$b8,$00,$60,$09,$fe,$00,$00,$0d,$00
    db $18,$15,$e0,$0d,$00,$3e,$18,$e0,$01,$00,$7e,$7f,$00,$18,$f0,$02,$00,$77,$7f,$00,$18,$e0,$07,$00
    db $c3,$7f,$00,$18,$c0,$0f,$00,$c7,$7f,$00,$18,$c0,$1f,$00,$9e,$7f,$00,$15,$c0,$03,$00,$98,$15,$80
    db $1e,$03,$00,$15,$00,$3f,$1f,$40,$15,$00,$72,$1f,$c0,$15,$00,$73,$1f,$80,$15,$00,$63,$3f,$80,$15
    db $00,$63,$0f,$80,$15,$00,$73,$0f,$e0,$15,$00,$31,$03,$60,$15,$84,$20,$01,$58,$15,$83,$30,$01,$1c
    db $15,$83,$18,$c1,$0c,$09,$fe,$00,$03,$38,$c0,$04,$09,$fe,$00,$03,$e8,$c0,$1e,$09,$fe,$00,$03,$00
    db $c0,$00
zombie_left_8:
    dw zombie_left_8_s0
    dw zombie_left_8_s0
zombie_left_8_s0:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$1e,$83,$00,$1e,$01,$38,$1e,$00,$5c,$1e,$00,$76,$1e,$00
    db $76,$09,$fc,$00,$1e,$00,$00,$24,$09,$f8,$01,$00,$c0,$01,$e0,$09,$f8,$02,$00,$f7,$03,$00,$09,$f8
    db $03,$00,$3e,$03,$78,$09,$f8,$00,$00,$12,$03,$78,$15,$c0,$04,$01,$f8,$15,$c0,$0d,$01,$dc,$15,$c0
    db $1f,$00,$0c,$15,$80,$1f,$00,$6e,$15,$00,$37,$00,$7e,$09,$fe,$00,$00,$66,$00,$00,$0c,$fe,$00,$00
    db $e7,$78,$00,$7f,$00,$0c,$fe,$00,$00,$c7,$00,$03,$3f,$00,$0c,$fe,$00,$10,$c7,$00,$ff,$1f,$80,$0c
    db $fe,$00,$10,$03,$00,$b7,$1f,$c0,$18,$f8,$00,$00,$00,$1f,$40,$27,$1f,$00
zombie_left_9:
    dw zombie_left_9_s0
    dw zombie_left_9_s0
zombie_left_9_s0:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$77,$15,$f8,$01,$03,$f0,$15
    db $c0,$03,$03,$f8,$15,$80,$16,$03,$f8,$15,$00,$3f,$01,$b0,$0c,$fe,$00,$00,$7d,$00,$b4,$7f,$00,$0c
    db $fc,$00,$00,$ff,$00,$8f,$7f,$00,$0c,$fc,$01,$00,$ce,$20,$0e,$7f,$00,$0c,$f8,$01,$00,$8c,$e0,$0a
    db $3f,$00,$0c,$f8,$03,$01,$04,$e0,$03,$3f,$80,$0c,$f8,$03,$00,$1c,$00,$01,$3f,$80,$0c,$f8,$03,$00
    db $f9,$00,$f9,$1f,$80,$0c,$f8,$01,$00,$d9,$00,$f9,$0f,$c0,$0c,$fc,$01,$00,$90,$00,$21,$0f,$60,$0c
    db $fc,$00,$07,$00,$8c,$00,$0f,$00
zombie_left_10:
    dw zombie_left_10_s0
    dw zombie_left_10_s0
zombie_left_10_s0:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$85,$15
    db $e0,$00,$01,$f0,$15,$c0,$0f,$00,$7c,$09,$fe,$00,$00,$1e,$00,$5e,$0c,$fc,$00,$00,$fb,$00,$f8,$0f
    db $00,$0c,$fc,$01,$00,$e6,$00,$97,$0f,$e0,$0c,$f8,$01,$00,$e4,$00,$07,$0f,$a0,$0c,$f8,$03,$00,$58
    db $10,$c1,$0f,$e0,$0c,$f8,$03,$00,$9d,$1c,$c1,$0f,$60,$0c,$f8,$00,$00,$00,$1c,$00,$0f,$00
zombie_left_11:
    dw zombie_left_11_s0
    dw zombie_left_11_s0
zombie_left_11_s0:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $15,$f0,$00,$01,$00,$18,$e0,$07,$00,$3c,$3f,$00,$18,$c0,$0e,$00,$fc,$1f,$80,$0c,$f8,$00,$00,$1f
    db $00,$7f,$0f,$c0,$0c,$f0,$03,$00,$fd,$00,$df,$07,$e0,$0c,$f0,$07,$00,$c1,$00,$8b,$07,$f0,$0c,$f0
    db $06,$00,$33,$20,$01,$07,$d0,$0c,$f0,$00,$80,$00,$7c,$00,$07,$00
zombie_right_0:
    dw zombie_right_0_s0
    dw zombie_right_0_s4
zombie_right_0_s0:
    db $00,$1e,$81,$00,$1e,$00,$3c,$1e,$00,$7e,$1e,$00,$4e,$1e,$00,$1a,$15,$fc,$00,$00,$36,$15,$f8,$01
    db $00,$f8,$15,$f0,$03,$03,$e8,$c3,$c7,$15,$c0,$1d,$0f,$e0,$15,$c0,$0c,$0f,$80,$15,$c0,$1c,$0f,$c0
    db $15,$c0,$1c,$07,$e0,$15,$c0,$0c,$03,$70,$15,$c0,$1c,$01,$38,$15,$c0,$1f,$01,$9c,$15,$c0,$1d,$01
    db $8c,$15,$c0,$03,$01,$48,$15,$e0,$0f,$03,$60,$15,$e0,$07,$07,$60,$15,$c0,$07,$07,$30,$15,$80,$1e
    db $07,$20,$15,$80,$3e,$0f,$60,$09,$fe,$00,$00,$08,$0f,$60,$09,$fe,$00,$03,$e0,$0f,$20,$09,$fe,$00
    db $0f,$e0,$0f,$00,$09,$fe,$00,$0f,$60,$07,$60,$15,$07,$60,$01,$70,$15,$07,$70,$01,$5c,$15,$07,$00
    db $01,$00
zombie_right_0_s4:
    db $00,$21,$f8,$00,$1f,$00,$21,$f0,$03,$0f,$c0,$21,$f0,$07,$0f,$e0,$21,$f0,$04,$0f,$e0,$21,$f0,$01
    db $0f,$a0,$21,$c0,$03,$0f,$60,$21,$80,$1f,$0f,$80,$21,$00,$3e,$3f,$80,$be,$c0,$15,$fc,$01,$00,$de
    db $15,$fc,$00,$00,$c8,$15,$fc,$01,$00,$cc,$18,$fc,$01,$00,$ce,$7f,$00,$18,$fc,$00,$00,$c7,$3f,$00
    db $18,$fc,$01,$00,$c3,$1f,$80,$18,$fc,$01,$00,$f9,$1f,$c0,$18,$fc,$01,$00,$d8,$1f,$c0,$18,$fc,$00
    db $00,$34,$1f,$80,$18,$fe,$00,$00,$f6,$3f,$00,$18,$fe,$00,$00,$76,$7f,$00,$18,$fc,$00,$00,$73,$7f
    db $00,$18,$f8,$01,$00,$e2,$7f,$00,$15,$f8,$03,$00,$e6,$15,$e0,$00,$00,$86,$15,$e0,$0e,$30,$02,$15
    db $e0,$0e,$f0,$00,$18,$e0,$06,$f0,$06,$7f,$00,$18,$f0,$06,$70,$07,$1f,$00,$18,$f0,$07,$70,$05,$1f
    db $c0,$18,$f0,$00,$70,$00,$1f,$00
zombie_right_1:
    dw zombie_right_1_s0
    dw zombie_right_1_s4
zombie_right_1_s0:
    db $00,$1e,$c0,$00,$21,$80,$1e,$7f,$00,$b0,$21,$80,$25,$7f,$00,$21,$80,$0d,$7f,$00,$18,$fc,$00,$00
    db $3b,$7f,$00,$18,$f8,$01,$00,$e8,$7f,$00,$15,$f0,$03,$01,$e4,$da,$b5,$15,$e0,$0c,$0f,$80,$15,$c0
    db $0c,$1f,$40,$15,$80,$1e,$03,$c0,$15,$80,$3e,$00,$78,$18,$80,$0c,$00,$3e,$3f,$00,$18,$c0,$14,$00
    db $07,$3f,$80,$18,$c0,$1e,$30,$83,$3f,$80,$18,$c0,$1e,$38,$81,$3f,$80,$18,$c0,$15,$0c,$01,$3f,$00
    db $18,$c0,$03,$04,$20,$7f,$00,$15,$f0,$07,$07,$30,$15,$f0,$07,$07,$10,$15,$80,$07,$07,$30,$15,$80
    db $3e,$07,$60,$09,$fe,$00,$00,$28,$0f,$60,$09,$fc,$00,$03,$e0,$0f,$00,$09,$fc,$01,$0f,$c0,$0f,$00
    db $09,$fc,$01,$1f,$c0,$03,$60,$09,$fc,$00,$0f,$c0,$03,$78,$09,$fe,$00,$0f,$a0,$03,$00,$06,$fe,$00
    db $0f,$00
zombie_right_1_s4:
    db $00,$21,$fc,$00,$0f,$00,$21,$f8,$01,$07,$e0,$21,$f8,$03,$07,$f0,$21,$f8,$02,$07,$50,$21,$f8,$00
    db $07,$d0,$21,$c0,$03,$07,$b0,$21,$80,$1e,$07,$80,$21,$00,$3e,$1f,$40,$e4,$b1,$15,$fe,$00,$00,$c8
    db $15,$fc,$00,$01,$c4,$18,$f8,$01,$00,$ec,$3f,$00,$18,$f8,$03,$00,$e7,$0f,$80,$18,$f8,$00,$00,$c3
    db $03,$e0,$18,$fc,$01,$00,$40,$03,$78,$18,$fc,$01,$03,$e8,$03,$38,$18,$fc,$01,$03,$e8,$83,$18,$18
    db $fc,$01,$00,$50,$c3,$10,$18,$fc,$00,$00,$32,$47,$00,$21,$00,$73,$7f,$00,$21,$00,$71,$7f,$00,$18
    db $f8,$00,$00,$73,$7f,$00,$18,$f8,$03,$00,$e6,$7f,$00,$15,$e0,$02,$00,$86,$15,$c0,$0e,$30,$00,$15
    db $c0,$1c,$f0,$00,$18,$c1,$1c,$f0,$06,$3f,$00,$18,$c0,$0c,$f0,$07,$3f,$80,$18,$e0,$0a,$f0,$00,$3f
    db $00,$12,$e0,$00
zombie_right_2:
    dw zombie_right_2_s0
    dw zombie_right_2_s4
zombie_right_2_s0:
    db $00,$1e,$c1,$00,$1e,$80,$1c,$1e,$80,$3e,$1e,$80,$2e,$1e,$80,$1a,$15,$fc,$00,$00,$1e,$15,$f0,$01
    db $00,$e8,$15,$f0,$07,$01,$4c,$15,$f0,$07,$01,$a0,$c7,$15,$c0,$15,$0f,$80,$15,$c0,$1c,$03,$40,$18
    db $c0,$18,$00,$f8,$3f,$00,$18,$80,$1c,$00,$ff,$3f,$80,$18,$80,$28,$00,$03,$3f,$80,$18,$80,$3e,$78
    db $01,$3f,$80,$18,$80,$3f,$7c,$00,$3f,$00,$15,$80,$3c,$7f,$00,$74,$15,$80,$07,$0f,$20,$15,$f0,$07
    db $07,$20,$15,$f0,$07,$07,$30,$15,$80,$07,$07,$20,$15,$80,$3e,$0f,$60,$09,$fe,$00,$00,$38,$0f,$60
    db $09,$fc,$00,$03,$d0,$0f,$60,$09,$fc,$01,$07,$c0,$0f,$20,$09,$fc,$01,$1f,$c0,$01,$20,$09,$fc,$00
    db $0f,$c0,$01,$7c,$09,$fe,$00,$0f,$e0,$01,$20,$09,$fe,$00,$0f,$00,$8f,$00
zombie_right_2_s4:
    db $00,$cd,$21,$f8,$01,$0f,$c0,$21,$f8,$03,$0f,$e0,$21,$f8,$02,$0f,$e0,$21,$f8,$01,$0f,$a0,$21,$c0
    db $01,$0f,$e0,$21,$00,$1e,$0f,$80,$21,$00,$74,$1f,$c0,$21,$00,$7a,$1f,$00,$c0,$15,$fc,$01,$00,$58
    db $18,$fc,$01,$00,$c4,$3f,$00,$18,$fc,$01,$00,$8f,$03,$80,$18,$f8,$01,$00,$cf,$03,$f8,$18,$f8,$02
    db $00,$80,$03,$38,$18,$f8,$03,$07,$e0,$83,$18,$18,$f8,$03,$07,$f0,$c3,$00,$d3,$72,$15,$f8,$00,$00
    db $72,$21,$00,$72,$7f,$00,$21,$00,$73,$7f,$00,$18,$f8,$00,$00,$72,$7f,$00,$15,$f8,$03,$00,$e6,$15
    db $e0,$03,$00,$86,$15,$c0,$0d,$30,$06,$15,$c0,$1c,$70,$02,$18,$c1,$1c,$f0,$02,$1f,$00,$18,$c0,$0c
    db $f0,$07,$1f,$c0,$18,$e0,$0e,$f0,$02,$1f,$00,$15,$e0,$00,$f8,$00
zombie_right_3:
    dw zombie_right_3_s0
    dw zombie_right_3_s4
zombie_right_3_s0:
    db $00,$1e,$c1,$00,$1e,$80,$1c,$d0,$21,$00,$4f,$7f,$00,$21,$00,$19,$7f,$00,$18,$fc,$00,$00,$0e,$7f
    db $00,$15,$f8,$01,$00,$e8,$15,$f0,$03,$01,$ec,$7a,$c7,$15,$c0,$15,$0f,$c0,$15,$c0,$1c,$03,$c0,$18
    db $c0,$1c,$00,$f8,$3f,$00,$18,$c0,$1c,$00,$7f,$1f,$80,$18,$c0,$18,$00,$11,$1f,$c0,$18,$c0,$1d,$44
    db $00,$1f,$c0,$18,$c0,$1f,$7e,$00,$1f,$00,$15,$c0,$1d,$7f,$00,$15,$c0,$02,$1f,$00,$15,$e0,$0e,$0f
    db $40,$15,$e0,$0e,$0f,$60,$15,$e0,$06,$0f,$60,$15,$00,$0e,$0f,$60,$15,$00,$7c,$0f,$c0,$09,$f8,$00
    db $00,$70,$1f,$c0,$09,$f8,$03,$06,$c0,$1f,$c0,$09,$f8,$03,$1e,$80,$1f,$00,$09,$f8,$01,$3e,$80,$0f
    db $c0,$09,$fc,$01,$1e,$80,$03,$e0,$09,$fc,$01,$1e,$c0,$03,$b8,$09,$fc,$00,$1e,$00,$03,$00
zombie_right_3_s4:
    db $00,$cd,$21,$f8,$01,$0f,$c0,$21,$f0,$03,$07,$e0,$21,$f0,$04,$07,$f0,$21,$f0,$01,$07,$90,$21,$c0
    db $00,$07,$e0,$21,$80,$1e,$0f,$80,$21,$00,$3e,$1f,$c0,$21,$00,$7e,$1f,$00,$c0,$15,$fc,$01,$00,$5c
    db $18,$fc,$01,$00,$cc,$3f,$00,$18,$fc,$01,$00,$cf,$03,$80,$18,$fc,$01,$00,$c7,$01,$f8,$18,$fc,$01
    db $00,$81,$01,$1c,$18,$fc,$01,$04,$d0,$41,$0c,$18,$fc,$01,$07,$f0,$e1,$00,$15,$fc,$01,$07,$d0,$15
    db $fc,$00,$01,$20,$15,$fe,$00,$00,$e4,$15,$fe,$00,$00,$e6,$15,$fe,$00,$00,$66,$15,$f0,$00,$00,$e6
    db $15,$f0,$07,$00,$cc,$15,$80,$07,$01,$0c,$15,$80,$3c,$61,$0c,$15,$81,$38,$e1,$00,$15,$83,$18,$e0
    db $0c,$18,$c1,$18,$e0,$0e,$3f,$00,$18,$c1,$1c,$e0,$0b,$3f,$80,$18,$c1,$00,$e0,$00,$3f,$00
zombie_right_4:
    dw zombie_right_4_s0
    dw zombie_right_4_s4
zombie_right_4_s0:
    db $00,$1e,$83,$00,$15,$fe,$00,$01,$38,$d1,$15,$fe,$00,$00,$9e,$15,$fe,$00,$00,$34,$15,$fc,$00,$00
    db $3e,$15,$f0,$01,$00,$e0,$15,$e0,$07,$07,$d0,$15,$e0,$0f,$07,$c0,$15,$80,$0f,$1f,$00,$18,$80,$38
    db $00,$c0,$1f,$00,$18,$80,$08,$00,$ff,$1f,$c0,$18,$c0,$1c,$00,$f9,$1f,$c0,$0c,$fe,$00,$00,$1c,$00
    db $60,$1f,$c0,$0c,$fe,$00,$01,$f8,$0e,$00,$1f,$00,$09,$fe,$00,$00,$7c,$7f,$00,$15,$00,$7d,$7f,$00
    db $15,$00,$59,$1f,$00,$15,$00,$44,$1f,$40,$15,$00,$06,$0f,$40,$15,$e0,$0e,$0f,$60,$15,$e0,$06,$0f
    db $60,$15,$00,$0e,$0f,$20,$09,$fc,$00,$00,$7e,$0f,$60,$09,$f8,$01,$00,$f0,$0f,$c0,$09,$f8,$03,$04
    db $80,$1f,$c0,$09,$f8,$03,$3c,$01,$1f,$80,$09,$f8,$01,$38,$01,$1f,$00,$09,$fc,$01,$38,$83,$0f,$c0
    db $09,$fc,$00,$38,$03,$0f,$e0,$7e
zombie_right_4_s4:
    db $00,$21,$f8,$00,$3f,$00,$21,$e0,$03,$1f,$80,$21,$e0,$0f,$0f,$c0,$21,$e0,$09,$0f,$e0,$21,$e0,$03
    db $0f,$40,$21,$c0,$03,$0f,$e0,$21,$00,$1e,$0f,$00,$18,$fe,$00,$00,$7d,$7f,$00,$18,$fe,$00,$00,$fc
    db $7f,$00,$d6,$18,$f8,$03,$00,$8c,$01,$00,$18,$f8,$00,$00,$8f,$01,$fc,$18,$fc,$01,$00,$cf,$01,$9c
    db $18,$e0,$01,$00,$c6,$01,$0c,$18,$e0,$0f,$10,$80,$e1,$00,$15,$e0,$07,$07,$c0,$15,$f0,$07,$07,$d0
    db $15,$f0,$05,$01,$90,$15,$f0,$04,$01,$44,$15,$f0,$00,$00,$64,$15,$fe,$00,$00,$e6,$15,$fe,$00,$00
    db $66,$15,$f0,$00,$00,$e2,$15,$c0,$07,$00,$e6,$15,$80,$1f,$00,$0c,$15,$80,$38,$41,$0c,$15,$83,$30
    db $c1,$18,$15,$83,$10,$81,$10,$15,$c3,$18,$80,$3c,$15,$c3,$00,$80,$3e,$1e,$80,$00
zombie_right_5:
    dw zombie_right_5_s0
    dw zombie_right_5_s4
zombie_right_5_s0:
    db $00,$00,$1e,$03,$00,$15,$fe,$00,$01,$78,$76,$15,$fe,$00,$01,$9c,$15,$fe,$00,$01,$34,$15,$f0,$00
    db $01,$3c,$da,$15,$c0,$0f,$07,$10,$15,$c0,$1f,$07,$80,$15,$80,$0a,$3f,$00,$18,$80,$39,$00,$80,$1f
    db $00,$18,$80,$31,$00,$ff,$1f,$c0,$18,$00,$38,$00,$fb,$1f,$40,$18,$02,$68,$00,$40,$1f,$c0,$18,$00
    db $78,$1e,$00,$1f,$00,$12,$00,$7a,$12,$00,$72,$15,$00,$40,$3f,$00,$15,$00,$1c,$3f,$80,$15,$c0,$1c
    db $1f,$80,$15,$00,$0c,$1f,$c0,$09,$fe,$00,$00,$6c,$1f,$c0,$09,$f0,$00,$00,$f8,$1f,$80,$09,$f0,$07
    db $00,$e1,$3f,$80,$09,$f0,$07,$08,$01,$3f,$80,$09,$f0,$06,$78,$03,$3f,$00,$09,$f0,$06,$f0,$02,$3f
    db $00,$09,$f0,$06,$70,$07,$0f,$80,$09,$f0,$07,$70,$07,$0f,$e0,$09,$f0,$00,$70,$00,$0f,$00
zombie_right_5_s4:
    db $00,$00,$21,$f0,$00,$3f,$00,$21,$e0,$07,$1f,$80,$21,$e0,$0f,$1f,$c0,$21,$e0,$09,$1f,$c0,$21,$e0
    db $03,$1f,$40,$21,$00,$03,$1f,$c0,$e4,$18,$fc,$00,$00,$f1,$7f,$00,$18,$fc,$01,$00,$f8,$7f,$00,$15
    db $f8,$00,$03,$a0,$18,$f8,$03,$00,$98,$01,$00,$18,$f8,$03,$00,$1f,$01,$fc,$18,$f0,$03,$00,$8f,$01
    db $b4,$18,$f0,$06,$20,$84,$01,$0c,$18,$f0,$07,$01,$80,$e1,$00,$15,$f0,$07,$0f,$a0,$15,$f0,$07,$0f
    db $20,$15,$f0,$04,$03,$00,$15,$f0,$01,$03,$c8,$15,$fc,$01,$01,$c8,$15,$f0,$00,$01,$cc,$15,$e0,$06
    db $01,$cc,$15,$00,$0f,$01,$88,$15,$00,$7e,$03,$18,$15,$00,$70,$83,$18,$15,$07,$60,$83,$30,$15,$0f
    db $60,$03,$20,$15,$07,$60,$00,$78,$15,$07,$70,$00,$7e,$15,$07,$00,$00,$00
zombie_right_6:
    dw zombie_right_6_s0
    dw zombie_right_6_s0
zombie_right_6_s0:
    db $00,$12,$81,$00,$12,$01,$3c,$12,$00,$7c,$12,$00,$5a,$12,$00,$5e,$15,$00,$08,$c0,$00,$15,$c0,$06
    db $80,$1e,$15,$00,$10,$00,$3a,$15,$00,$78,$00,$e2,$15,$00,$7c,$08,$20,$09,$fe,$00,$00,$6e,$0f,$00
    db $09,$fe,$00,$00,$c7,$1f,$40,$09,$fe,$00,$00,$c3,$0f,$c0,$09,$fe,$00,$00,$f1,$07,$e0,$09,$fe,$00
    db $00,$79,$07,$f0,$15,$00,$01,$07,$a0,$15,$fc,$00,$03,$50,$15,$f8,$00,$03,$f8,$15,$f8,$03,$01,$78
    db $15,$f8,$01,$01,$dc,$15,$fc,$01,$01,$cc,$15,$f8,$01,$01,$8c,$15,$e0,$03,$01,$8c,$15,$e0,$0f,$01
    db $9c,$15,$c0,$0d,$01,$1c,$15,$00,$14,$41,$08,$15,$01,$74,$83,$00,$15,$01,$30,$83,$30,$15,$03,$60
    db $80,$38,$15,$03,$78,$80,$2e,$15,$03,$00,$80,$00
zombie_right_7:
    dw zombie_right_7_s0
    dw zombie_right_7_s0
zombie_right_7_s0:
    db $00,$00,$00,$12,$81,$00,$12,$01,$3c,$06,$fe,$00,$00,$7c,$09,$fe,$00,$00,$de,$f0,$00,$0c,$fe,$00
    db $00,$dc,$e0,$06,$7f,$00,$0c,$fe,$00,$00,$48,$c0,$0f,$7f,$00,$18,$00,$06,$00,$1d,$7f,$00,$18,$00
    db $18,$00,$b0,$7f,$00,$15,$00,$7c,$07,$b0,$09,$fe,$00,$00,$7e,$07,$80,$09,$fe,$00,$00,$ee,$0f,$40
    db $09,$fe,$00,$00,$c3,$07,$e0,$09,$fe,$00,$00,$e3,$03,$f0,$09,$fe,$00,$00,$79,$03,$f8,$15,$00,$19
    db $03,$c0,$15,$c0,$00,$01,$78,$15,$f8,$02,$00,$fc,$15,$f8,$03,$00,$4e,$15,$f8,$01,$00,$ce,$15,$fc
    db $01,$00,$c6,$15,$f0,$01,$00,$c6,$15,$f0,$07,$00,$ce,$15,$c0,$06,$00,$8c,$15,$80,$1a,$21,$04,$15
    db $80,$38,$c1,$0c,$15,$83,$30,$c1,$18,$18,$03,$20,$c0,$1c,$7f,$00,$18,$03,$78,$c0,$17,$7f,$00,$18
    db $03,$00,$c0,$00,$7f,$00
zombie_right_8:
    dw zombie_right_8_s0
    dw zombie_right_8_s0
zombie_right_8_s0:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$12,$c1,$00,$12,$80,$1c,$12,$00,$3a,$12,$00,$6e,$12,$00
    db $6e,$18,$00,$24,$78,$00,$3f,$00,$18,$80,$07,$00,$03,$1f,$80,$18,$c0,$00,$00,$ef,$1f,$40,$18,$c0
    db $1e,$00,$7c,$1f,$c0,$18,$c0,$1e,$00,$48,$1f,$00,$15,$80,$1f,$03,$20,$15,$80,$3b,$03,$b0,$15,$00
    db $30,$03,$f8,$15,$00,$76,$01,$f8,$15,$00,$7e,$00,$ec,$18,$00,$00,$00,$66,$7f,$00,$0c,$fe,$00,$1e
    db $00,$00,$e7,$7f,$00,$0c,$fc,$00,$00,$c0,$00,$e3,$7f,$00,$0c,$f8,$01,$00,$ff,$08,$e3,$7f,$00,$0c
    db $f8,$03,$00,$ed,$08,$c0,$7f,$00,$09,$f8,$02,$00,$00,$1f,$00,$03,$f8,$00
zombie_right_9:
    dw zombie_right_9_s0
    dw zombie_right_9_s0
zombie_right_9_s0:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$78,$db,$15,$c0,$1f,$03,$c0
    db $15,$c0,$1f,$01,$68,$15,$80,$0d,$00,$fc,$0c,$fe,$00,$00,$2d,$00,$be,$7f,$00,$0c,$fe,$00,$00,$f1
    db $00,$ff,$3f,$00,$0c,$fe,$00,$04,$70,$00,$73,$3f,$80,$0c,$fc,$00,$07,$50,$00,$31,$1f,$80,$0c,$fc
    db $01,$07,$c0,$80,$20,$1f,$c0,$0c,$fc,$01,$00,$80,$00,$38,$1f,$c0,$0c,$f8,$01,$00,$9f,$00,$9f,$1f
    db $c0,$0c,$f0,$03,$00,$9f,$00,$9b,$1f,$80,$0c,$f0,$06,$00,$84,$00,$09,$3f,$80,$0c,$f0,$00,$31,$00
    db $e0,$00,$3f,$00
zombie_right_10:
    dw zombie_right_10_s0
    dw zombie_right_10_s0
zombie_right_10_s0:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$b6,$15
    db $80,$0f,$07,$00,$15,$00,$3e,$03,$f0,$18,$00,$7a,$00,$78,$7f,$00,$0c,$f0,$00,$00,$1f,$00,$df,$3f
    db $00,$0c,$f0,$07,$00,$e9,$00,$67,$3f,$80,$0c,$f0,$05,$00,$e0,$00,$27,$1f,$80,$0c,$f0,$07,$08,$83
    db $00,$1a,$1f,$c0,$0c,$f0,$06,$38,$83,$00,$b9,$1f,$c0,$0c,$f0,$00,$38,$00,$00,$00,$1f,$00
zombie_right_11:
    dw zombie_right_11_s0
    dw zombie_right_11_s0
zombie_right_11_s0:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $15,$80,$00,$0f,$00,$09,$fc,$00,$00,$3c,$07,$e0,$09,$f8,$01,$00,$3f,$03,$70,$0c,$f0,$03,$00,$fe
    db $00,$f8,$1f,$00,$0c,$e0,$07,$00,$fb,$00,$bf,$0f,$c0,$0c,$e0,$0f,$00,$d1,$00,$83,$0f,$e0,$0c,$e0
    db $0b,$04,$80,$00,$cc,$0f,$60,$0c,$e0,$00,$3e,$00,$01,$00,$0f,$00
alien_left_0:
    dw alien_left_0_s0
    dw alien_left_0_s4
alien_left_0_s0:
    db $00,$00,$00,$78,$09,$fc,$00,$00,$0f,$1f,$80,$09,$f0,$01,$00,$ff,$1f,$c0,$09,$e0,$07,$00,$e2,$1f
    db $00,$09,$c0,$0f,$00,$8c,$0f,$00,$09,$c0,$1e,$00,$50,$0f,$60,$09,$c0,$1c,$00,$c1,$03,$c0,$09,$c0
    db $13,$00,$69,$03,$38,$09,$c0,$02,$00,$3c,$03,$f0,$71,$0c,$e1,$00,$80,$37,$02,$38,$1f,$00,$18,$80
    db $07,$00,$60,$07,$c0,$18,$00,$03,$0c,$81,$03,$30,$0c,$f0,$00,$00,$7b,$3c,$80,$03,$18,$0c,$e0,$07
    db $00,$f3,$07,$00,$c3,$18,$0c,$e0,$0e,$00,$83,$03,$d0,$c3,$08,$0c,$e0,$0c,$20,$87,$01,$f8,$c3,$18
    db $0c,$e0,$08,$00,$0f,$00,$ec,$03,$10,$0c,$e3,$00,$80,$1c,$00,$e7,$07,$70,$18,$80,$38,$00,$e1,$07
    db $60,$18,$82,$30,$00,$78,$0f,$00,$18,$83,$30,$00,$7c,$7f,$00,$18,$80,$18,$00,$0f,$7f,$00,$18,$c0
    db $0e,$e0,$03,$7f,$00,$18,$e0,$06,$f8,$03,$3f,$00,$18,$c0,$04,$f0,$03,$1f,$80,$18,$01,$1c,$e0,$07
    db $1f,$c0,$18,$01,$7c,$e0,$0f,$1f,$00,$18,$01,$00,$e0,$00,$7f,$00
alien_left_0_s4:
    db $00,$00,$00,$75,$15,$c0,$00,$01,$f8,$15,$00,$1f,$01,$fc,$09,$fe,$00,$00,$7e,$01,$20,$09,$fc,$00
    db $00,$f8,$00,$c0,$09,$fc,$01,$00,$e5,$00,$06,$0c,$fc,$01,$00,$cc,$00,$1c,$3f,$00,$0c,$fc,$01,$00
    db $36,$00,$93,$3f,$80,$0c,$fc,$00,$00,$23,$00,$cf,$3f,$00,$36,$0c,$fe,$00,$18,$03,$00,$73,$21,$80
    db $1b,$f8,$00,$00,$76,$00,$0c,$7f,$00,$1b,$f0,$00,$00,$38,$c0,$13,$3f,$00,$1b,$00,$07,$03,$b8,$c0
    db $01,$3f,$80,$0f,$fe,$00,$00,$7f,$00,$30,$7c,$01,$3f,$80,$0f,$fe,$00,$00,$e8,$00,$3d,$3c,$00,$3f
    db $80,$0f,$fe,$00,$02,$c8,$00,$7f,$1c,$81,$3f,$80,$0f,$fe,$00,$00,$80,$00,$fe,$00,$c1,$3f,$00,$0f
    db $fe,$00,$38,$01,$00,$ce,$00,$77,$7f,$00,$1b,$f8,$03,$00,$8e,$00,$16,$7f,$00,$18,$f8,$03,$20,$07
    db $00,$80,$18,$f8,$03,$30,$07,$07,$c0,$18,$f8,$01,$00,$80,$07,$f0,$18,$fc,$00,$0e,$e0,$07,$30,$18
    db $fe,$00,$0f,$60,$83,$30,$18,$fc,$00,$0f,$40,$01,$38,$18,$f0,$01,$1e,$c0,$01,$7c,$18,$f0,$07,$1e
    db $c0,$01,$f0,$18,$f0,$00,$1e,$00,$07,$00
alien_left_1:
    dw alien_left_1_s0
    dw alien_left_1_s4
alien_left_1_s0:
    db $00,$00,$00,$89,$09,$fc,$00,$00,$1f,$7f,$00,$09,$f0,$01,$00,$ff,$7f,$00,$09,$e0,$07,$00,$e4,$7f
    db $00,$09,$c0,$0f,$00,$9c,$0f,$00,$09,$c0,$1e,$00,$38,$0f,$e0,$09,$c0,$1d,$00,$c1,$03,$c0,$09,$c0
    db $02,$00,$6d,$03,$38,$09,$e0,$0a,$00,$3c,$03,$f0,$09,$e0,$0c,$80,$3e,$03,$80,$aa,$ab,$0c,$c0,$0c
    db $00,$33,$0c,$80,$0f,$00,$0c,$c0,$1f,$00,$f3,$3c,$81,$07,$e0,$0c,$c0,$14,$00,$83,$1c,$81,$03,$30
    db $0c,$c0,$18,$20,$03,$0c,$c0,$03,$18,$0c,$c3,$00,$c0,$0f,$07,$a0,$c3,$00,$18,$c0,$1f,$01,$30,$c3
    db $18,$18,$00,$18,$00,$1c,$03,$10,$18,$00,$5f,$00,$07,$07,$70,$18,$00,$5f,$00,$c3,$07,$60,$18,$00
    db $60,$00,$f0,$0f,$00,$15,$02,$38,$07,$70,$15,$80,$18,$07,$60,$15,$c0,$02,$0f,$40,$15,$f0,$06,$1f
    db $40,$15,$c0,$06,$1f,$00,$12,$c0,$1e,$12,$c0,$00
alien_left_1_s4:
    db $00,$00,$00,$77,$15,$c0,$01,$07,$f0,$15,$00,$1f,$07,$f0,$09,$fe,$00,$00,$7e,$07,$40,$09,$fc,$00
    db $00,$f9,$00,$c0,$09,$fc,$01,$00,$e3,$00,$8e,$ba,$0c,$fc,$00,$00,$26,$00,$d3,$3f,$80,$0c,$fe,$00
    db $00,$a3,$00,$cf,$3f,$00,$0c,$fe,$00,$08,$c3,$00,$e8,$3f,$00,$59,$5a,$0c,$fc,$00,$00,$c3,$00,$38
    db $c0,$00,$0f,$fc,$01,$00,$ff,$03,$38,$c0,$1e,$7f,$00,$0f,$fc,$01,$00,$48,$01,$38,$c0,$13,$3f,$00
    db $0f,$fc,$01,$02,$80,$00,$3c,$c0,$01,$3f,$80,$0f,$fc,$00,$3c,$00,$00,$fa,$7c,$00,$3f,$00,$1b,$fc
    db $01,$00,$f3,$1c,$01,$3f,$80,$1b,$f0,$01,$00,$81,$00,$c1,$3f,$00,$1b,$f0,$05,$00,$f0,$00,$77,$7f
    db $00,$1b,$f0,$05,$00,$fc,$00,$36,$7f,$00,$18,$f0,$06,$00,$0f,$00,$00,$18,$f0,$03,$20,$87,$7f,$00
    db $18,$f8,$01,$00,$86,$7f,$00,$15,$fc,$00,$00,$24,$1e,$01,$64,$15,$fc,$00,$01,$60,$15,$fc,$01,$0f
    db $e0,$15,$fc,$00,$0f,$00
alien_left_2:
    dw alien_left_2_s0
    dw alien_left_2_s4
alien_left_2_s0:
    db $00,$00,$00,$78,$09,$fc,$00,$00,$0f,$3f,$80,$70,$09,$e0,$07,$00,$e2,$3f,$00,$09,$c0,$0f,$00,$9c
    db $07,$00,$09,$c0,$1e,$00,$58,$07,$70,$09,$c0,$1c,$00,$80,$03,$e0,$09,$c0,$03,$00,$7d,$03,$98,$09
    db $e0,$02,$00,$3e,$03,$70,$09,$e0,$0c,$80,$3f,$01,$40,$09,$e1,$00,$80,$37,$01,$1c,$09,$e1,$00,$80
    db $03,$01,$b0,$0c,$c0,$0c,$00,$13,$00,$c0,$7f,$00,$0c,$c0,$1f,$00,$f8,$00,$4f,$1f,$00,$0c,$c0,$14
    db $00,$83,$00,$e3,$07,$c0,$0c,$c0,$04,$00,$3f,$08,$e0,$03,$70,$0c,$f1,$00,$00,$3f,$07,$00,$01,$18
    db $18,$00,$70,$07,$30,$c1,$0c,$18,$00,$3e,$03,$70,$e1,$04,$18,$80,$07,$00,$38,$e1,$04,$18,$f0,$01
    db $00,$de,$41,$0c,$18,$f8,$01,$00,$8f,$01,$18,$18,$f8,$03,$20,$03,$03,$90,$18,$f8,$02,$78,$01,$07
    db $c0,$18,$f8,$00,$fc,$00,$1f,$c0,$21,$f8,$00,$1f,$c0,$21,$f0,$03,$1f,$c0,$21,$f0,$07,$1f,$c0,$21
    db $f0,$00,$1f,$00
alien_left_2_s4:
    db $00,$00,$00,$75,$15,$c0,$00,$03,$f8,$cc,$09,$fe,$00,$00,$7e,$03,$20,$0c,$fc,$00,$00,$f9,$00,$c0
    db $7f,$00,$0c,$fc,$01,$00,$e5,$00,$87,$7f,$00,$0c,$fc,$01,$00,$c8,$00,$0e,$3f,$00,$0c,$fc,$00,$00
    db $37,$00,$d9,$3f,$80,$0c,$fe,$00,$00,$23,$00,$e7,$3f,$00,$0c,$fe,$00,$08,$c3,$00,$f4,$1f,$00,$0c
    db $fe,$00,$18,$03,$00,$71,$1f,$c0,$0c,$fe,$00,$18,$00,$00,$3b,$1f,$00,$0c,$fc,$00,$00,$c1,$00,$3c
    db $07,$00,$0c,$fc,$01,$00,$ff,$00,$84,$01,$f0,$0f,$fc,$01,$00,$48,$00,$3e,$00,$3c,$7f,$00,$0f,$fc
    db $00,$00,$43,$00,$fe,$80,$07,$3f,$00,$1b,$10,$03,$00,$f0,$70,$01,$1f,$80,$1b,$f0,$07,$00,$03,$7c
    db $00,$1f,$c0,$1b,$f0,$03,$00,$e7,$3e,$00,$1f,$40,$1b,$f8,$00,$00,$73,$0e,$80,$1f,$40,$24,$00,$1d
    db $04,$e0,$1f,$c0,$24,$80,$18,$00,$f1,$1f,$80,$24,$82,$30,$00,$39,$3f,$00,$24,$87,$20,$80,$1c,$7f
    db $00,$21,$8f,$00,$c1,$0c,$27,$81,$0c,$27,$01,$3c,$27,$01,$7c,$27,$01,$00
alien_left_3:
    dw alien_left_3_s0
    dw alien_left_3_s4
alien_left_3_s0:
    db $00,$00,$00,$b6,$09,$fc,$00,$00,$0f,$3f,$00,$70,$ac,$09,$c0,$0f,$01,$9c,$0f,$00,$09,$c0,$1e,$00
    db $10,$0f,$60,$09,$c0,$1d,$00,$c1,$03,$c0,$09,$c0,$03,$00,$6d,$03,$38,$09,$e0,$02,$00,$3c,$03,$70
    db $71,$aa,$ab,$09,$c0,$0c,$00,$33,$0f,$80,$0c,$c0,$1f,$00,$f7,$00,$c0,$7f,$00,$0c,$c0,$14,$00,$82
    db $00,$cb,$0f,$00,$0c,$c0,$18,$00,$0e,$00,$e3,$07,$e0,$0c,$c3,$00,$00,$3e,$00,$e0,$03,$70,$18,$00
    db $78,$07,$f0,$03,$18,$18,$00,$60,$03,$70,$c3,$08,$18,$00,$3c,$00,$38,$c3,$08,$18,$80,$0f,$00,$3e
    db $c3,$18,$18,$e0,$01,$00,$0e,$43,$10,$18,$f0,$03,$60,$07,$47,$00,$18,$f0,$06,$70,$03,$0f,$00,$18
    db $f0,$00,$f8,$01,$0f,$e0,$21,$fc,$00,$0f,$e0,$21,$fe,$00,$0f,$60,$21,$fe,$00,$0f,$e0,$21,$fe,$00
    db $0f,$00
alien_left_3_s4:
    db $00,$00,$00,$85,$15,$c0,$00,$03,$f0,$cc,$a4,$09,$fc,$00,$00,$f9,$10,$c0,$09,$fc,$01,$00,$e1,$00
    db $06,$ba,$0c,$fc,$00,$00,$36,$00,$d3,$3f,$80,$b9,$36,$59,$5a,$09,$fc,$00,$00,$c3,$00,$38,$0c,$fc
    db $01,$00,$ff,$00,$7c,$07,$00,$0c,$fc,$01,$00,$48,$00,$2c,$00,$b0,$0f,$fc,$01,$00,$80,$00,$ee,$00
    db $3e,$7f,$00,$0f,$fc,$00,$30,$03,$00,$ee,$00,$07,$3f,$00,$1b,$f0,$07,$00,$8f,$70,$01,$3f,$80,$1b
    db $f0,$06,$00,$07,$3c,$00,$3f,$80,$1b,$f0,$03,$00,$c3,$0c,$80,$3f,$80,$1b,$f8,$00,$00,$f3,$0c,$e1
    db $3f,$80,$1b,$fe,$00,$00,$10,$04,$e1,$3f,$00,$24,$06,$30,$04,$70,$7f,$00,$21,$07,$60,$00,$30,$21
    db $0f,$00,$80,$1e,$27,$c0,$0e,$27,$e0,$06,$27,$e0,$0e,$27,$e0,$00
alien_left_4:
    dw alien_left_4_s0
    dw alien_left_4_s4
alien_left_4_s0:
    db $00,$00,$00,$b6,$09,$fc,$00,$00,$0f,$3f,$00,$70,$ac,$09,$c0,$0f,$01,$8c,$0f,$00,$09,$c0,$1e,$20
    db $08,$0f,$60,$09,$c0,$1e,$00,$81,$03,$c0,$09,$c0,$03,$00,$7d,$03,$38,$09,$e0,$02,$00,$3c,$03,$70
    db $71,$aa,$ab,$09,$c0,$0c,$00,$33,$0f,$80,$09,$c0,$1f,$00,$f1,$00,$80,$0c,$c0,$14,$00,$83,$00,$ce
    db $0f,$00,$0c,$c0,$18,$20,$03,$00,$c1,$07,$e0,$0c,$c3,$00,$c0,$0f,$1c,$c0,$03,$10,$18,$80,$1f,$1f
    db $c0,$c3,$18,$18,$00,$3d,$00,$c0,$03,$00,$18,$00,$71,$00,$df,$03,$98,$18,$04,$60,$00,$ff,$03,$c0
    db $18,$02,$70,$00,$f0,$1f,$c0,$18,$00,$38,$06,$00,$1f,$c0,$18,$81,$1c,$fe,$00,$1f,$00,$12,$c1,$0c
    db $12,$81,$0c,$12,$01,$3c,$12,$01,$7c,$12,$01,$00
alien_left_4_s4:
    db $00,$00,$00,$85,$15,$c0,$00,$03,$f0,$cc,$a4,$09,$fc,$00,$00,$f8,$10,$c0,$09,$fc,$01,$02,$e0,$00
    db $86,$0c,$fc,$01,$00,$e8,$00,$1c,$3f,$00,$0c,$fc,$00,$00,$37,$00,$d3,$3f,$80,$b9,$36,$59,$5a,$09
    db $fc,$00,$00,$c3,$00,$38,$0c,$fc,$01,$00,$ff,$00,$18,$0f,$00,$0c,$fc,$01,$00,$48,$00,$3c,$00,$e0
    db $0f,$fc,$01,$02,$80,$00,$3c,$00,$1e,$7f,$00,$0f,$fc,$00,$3c,$00,$01,$fc,$c0,$01,$3f,$00,$1b,$f8
    db $01,$01,$fc,$fc,$01,$3f,$80,$1b,$f0,$03,$00,$dc,$00,$00,$3f,$00,$1b,$f0,$07,$00,$1d,$00,$f9,$3f
    db $80,$1b,$f0,$06,$40,$0f,$00,$fc,$3f,$00,$18,$f0,$07,$20,$0f,$01,$0c,$18,$f0,$03,$00,$80,$61,$0c
    db $18,$f8,$01,$1f,$c0,$e1,$00,$15,$fc,$00,$1f,$c0,$15,$f8,$00,$1f,$c0,$15,$f0,$03,$1f,$c0,$15,$f0
    db $07,$1f,$c0,$15,$f0,$00,$1f,$00
alien_left_5:
    dw alien_left_5_s0
    dw alien_left_5_s4
alien_left_5_s0:
    db $00,$00,$00,$89,$09,$fc,$00,$00,$1f,$3f,$00,$70,$ac,$09,$c0,$0f,$00,$8c,$0f,$00,$09,$c0,$1e,$00
    db $40,$0f,$e0,$09,$c0,$1c,$00,$81,$03,$c0,$09,$c0,$13,$00,$6d,$03,$38,$09,$c0,$02,$00,$3c,$03,$70
    db $71,$0c,$e1,$00,$80,$37,$00,$38,$1f,$00,$18,$80,$07,$00,$f1,$07,$c0,$18,$00,$33,$04,$81,$07,$30
    db $0c,$f0,$00,$00,$7b,$1c,$c0,$03,$10,$0c,$e0,$07,$00,$e2,$0f,$40,$c3,$18,$0c,$e0,$0e,$08,$83,$07
    db $e0,$c3,$08,$0c,$e0,$0c,$30,$83,$01,$d0,$c3,$18,$0c,$e0,$00,$20,$07,$00,$dc,$03,$10,$18,$c0,$0f
    db $00,$07,$07,$70,$18,$c0,$18,$00,$81,$07,$60,$18,$c0,$1d,$00,$20,$0f,$00,$15,$c0,$0e,$00,$f8,$15
    db $e0,$07,$00,$0e,$15,$f0,$03,$20,$86,$15,$f8,$01,$30,$84,$15,$f0,$01,$11,$84,$15,$e0,$07,$11,$c0
    db $15,$e0,$0f,$1f,$00,$b6
alien_left_5_s4:
    db $00,$00,$00,$77,$15,$c0,$01,$03,$f0,$cc,$a4,$09,$fc,$00,$00,$f8,$00,$c0,$09,$fc,$01,$00,$e4,$00
    db $0e,$0c,$fc,$01,$00,$c8,$00,$1c,$3f,$00,$0c,$fc,$01,$00,$36,$00,$d3,$3f,$80,$0c,$fc,$00,$00,$23
    db $00,$c7,$3f,$00,$36,$0c,$fe,$00,$18,$03,$00,$73,$01,$80,$1b,$f8,$00,$00,$7f,$00,$1c,$7f,$00,$1b
    db $f0,$03,$00,$38,$40,$13,$7f,$00,$1b,$00,$07,$01,$bc,$c0,$01,$3f,$00,$0f,$fe,$00,$00,$7e,$00,$24
    db $fc,$01,$3f,$80,$0f,$fe,$00,$00,$e8,$80,$3e,$7c,$00,$3f,$80,$0f,$fe,$00,$03,$c8,$00,$3d,$1c,$01
    db $3f,$80,$0f,$fe,$00,$02,$00,$00,$7d,$00,$c1,$3f,$00,$1b,$fc,$00,$00,$f0,$00,$77,$7f,$00,$1b,$fc
    db $01,$00,$88,$00,$16,$7f,$00,$18,$fc,$01,$00,$d2,$00,$00,$18,$fc,$00,$00,$ef,$0f,$80,$18,$fe,$00
    db $00,$70,$0f,$e0,$21,$02,$38,$0f,$60,$21,$83,$18,$0f,$40,$21,$01,$18,$1f,$40,$18,$fe,$00,$01,$7c
    db $1f,$00,$15,$fe,$00,$01,$f0,$85
alien_left_6:
    dw alien_left_6_s0
    dw alien_left_6_s0
alien_left_6_s0:
    db $00,$00,$79,$09,$fe,$00,$00,$0f,$1f,$c0,$09,$f8,$00,$00,$ff,$1f,$c0,$09,$e0,$03,$00,$f8,$1f,$00
    db $09,$c0,$0f,$01,$c4,$8f,$00,$09,$c0,$1f,$00,$38,$0f,$20,$09,$c0,$1e,$00,$c0,$0f,$e0,$09,$c0,$1b
    db $00,$e1,$03,$80,$09,$c0,$03,$00,$7d,$03,$38,$09,$e0,$0e,$00,$3e,$03,$60,$09,$e0,$00,$80,$3f,$01
    db $00,$15,$80,$13,$01,$bc,$0c,$f0,$00,$c0,$01,$00,$d0,$1f,$00,$0c,$e0,$06,$00,$1b,$04,$e1,$07,$c0
    db $0c,$e0,$0f,$00,$f9,$0c,$e0,$03,$30,$0c,$e0,$0e,$00,$52,$0f,$40,$83,$18,$0c,$e0,$0c,$00,$0f,$1f
    db $c0,$c3,$08,$0c,$e1,$00,$80,$0f,$03,$80,$c3,$08,$18,$00,$3d,$01,$f8,$c3,$18,$0c,$fe,$00,$00,$79
    db $00,$dc,$03,$10,$0c,$fe,$00,$00,$c1,$00,$cf,$07,$70,$0c,$fe,$00,$0c,$e1,$00,$83,$07,$60,$0c,$fe
    db $00,$04,$61,$00,$f0,$0f,$00,$15,$04,$30,$03,$70,$15,$07,$20,$01,$18,$15,$0f,$60,$c1,$0c,$09,$fc
    db $00,$07,$60,$c0,$0c,$09,$f8,$01,$07,$f0,$80,$1e,$09,$f8,$03,$07,$e0,$80,$3e,$09,$f8,$00,$0f,$00
    db $80,$00
alien_left_7:
    dw alien_left_7_s0
    dw alien_left_7_s0
alien_left_7_s0:
    db $00,$00,$79,$15,$e0,$0f,$03,$c0,$15,$e0,$0f,$01,$f8,$15,$e0,$03,$00,$fc,$18,$c0,$03,$00,$1e,$7f
    db $00,$18,$c0,$1e,$00,$47,$3f,$00,$18,$c0,$00,$10,$81,$1f,$80,$18,$fc,$00,$1c,$80,$1f,$c0,$0c,$f8
    db $00,$f8,$01,$00,$c0,$1f,$40,$0c,$e0,$02,$78,$03,$00,$ee,$1f,$00,$0c,$e0,$0f,$18,$00,$00,$e3,$7f
    db $00,$0c,$e0,$0a,$00,$c2,$00,$c8,$7f,$00,$09,$e0,$0c,$00,$72,$00,$ee,$09,$e1,$00,$00,$0c,$00,$62
    db $15,$c0,$1f,$00,$e8,$18,$c0,$1d,$01,$ec,$87,$00,$18,$c0,$1b,$01,$00,$87,$30,$18,$80,$05,$1f,$00
    db $83,$10,$0c,$fe,$00,$00,$3c,$1f,$40,$c3,$18,$0c,$fc,$00,$00,$f8,$07,$c0,$c3,$00,$0c,$fc,$01,$02
    db $c8,$03,$30,$c3,$18,$0c,$fc,$01,$03,$d8,$81,$38,$83,$10,$0c,$fc,$00,$00,$f8,$80,$0c,$07,$30,$0c
    db $fe,$00,$00,$6e,$20,$0b,$07,$60,$18,$00,$67,$20,$81,$0f,$40,$0c,$fe,$00,$00,$61,$3c,$80,$1f,$00
    db $09,$fc,$00,$00,$c1,$3f,$80,$09,$f0,$01,$10,$c7,$3f,$80,$09,$f0,$07,$10,$c0,$3f,$00,$06,$f0,$00
    db $1f,$00
alien_left_8:
    dw alien_left_8_s0
    dw alien_left_8_s0
alien_left_8_s0:
    db $00,$00,$00,$00,$1e,$01,$00,$21,$00,$7c,$7f,$00,$21,$00,$7f,$3f,$00,$18,$fe,$00,$00,$1f,$1f,$80
    db $18,$fe,$00,$00,$bf,$0f,$c0,$18,$fe,$00,$00,$79,$07,$e0,$18,$87,$00,$00,$00,$07,$f0,$18,$03,$30
    db $c2,$18,$03,$30,$18,$01,$78,$81,$10,$83,$38,$18,$01,$5c,$80,$3c,$03,$18,$18,$00,$24,$80,$1d,$03
    db $88,$0c,$fc,$00,$00,$06,$00,$18,$03,$c0,$0c,$f8,$01,$10,$83,$00,$b2,$1f,$00,$0c,$f8,$03,$00,$c1
    db $00,$f3,$3f,$00,$0c,$f8,$03,$00,$b8,$00,$e1,$3f,$80,$0c,$f8,$00,$00,$1f,$00,$04,$07,$00,$18,$80
    db $0f,$30,$82,$c7,$10,$18,$00,$26,$08,$80,$c3,$10,$0c,$fe,$00,$00,$7e,$07,$60,$c3,$08,$0c,$fe,$00
    db $00,$dc,$07,$70,$c3,$08,$0c,$fc,$00,$01,$f0,$01,$30,$83,$18,$0c,$fc,$01,$03,$b0,$80,$1c,$03,$30
    db $0c,$e0,$01,$03,$18,$c0,$07,$07,$60,$0c,$c0,$0f,$41,$08,$f0,$01,$0f,$40,$0c,$c0,$1d,$00,$0c,$fc
    db $00,$1f,$00,$06,$c0,$00,$00,$3e,$12,$00,$78,$12,$03,$00
alien_left_9:
    dw alien_left_9_s0
    dw alien_left_9_s0
alien_left_9_s0:
    db $00,$00,$00,$00,$00,$00,$00,$00,$21,$f0,$00,$7f,$00,$21,$f0,$07,$1f,$00,$21,$c0,$03,$0f,$c0,$21
    db $c0,$19,$07,$e0,$18,$c3,$00,$c0,$0f,$07,$f0,$18,$81,$18,$e0,$04,$03,$70,$18,$80,$3c,$f0,$00,$01
    db $38,$18,$80,$2e,$c0,$06,$81,$1c,$18,$80,$12,$80,$1e,$c1,$1c,$0c,$fc,$00,$00,$02,$00,$3c,$41,$0c
    db $0c,$f8,$01,$08,$c3,$00,$1d,$21,$04,$0c,$f8,$03,$00,$e1,$00,$b9,$11,$84,$0c,$88,$00,$00,$f1,$00
    db $f6,$11,$c0,$0c,$80,$21,$00,$fc,$00,$e3,$1f,$00,$0c,$80,$3f,$00,$9f,$00,$49,$0f,$00,$0c,$80,$1c
    db $00,$0d,$00,$0c,$07,$20,$0c,$c1,$00,$80,$3d,$21,$00,$87,$30,$18,$80,$38,$0f,$80,$87,$10,$18,$02
    db $30,$03,$e0,$07,$30,$0c,$fe,$00,$06,$60,$00,$78,$07,$60,$0c,$f8,$00,$0f,$c0,$00,$1f,$0f,$c0,$0c
    db $f0,$03,$1f,$c0,$c0,$06,$1f,$80,$0c,$f0,$07,$1f,$00,$f0,$00,$3f,$00,$06,$f0,$00,$7f,$00
alien_left_10:
    dw alien_left_10_s0
    dw alien_left_10_s0
alien_left_10_s0:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$15,$fe,$00,$0f,$00,$18,$fe,$00,$0e,$e0
    db $03,$00,$18,$fe,$00,$0e,$e0,$01,$b8,$18,$fe,$00,$0e,$60,$01,$9c,$18,$81,$00,$0e,$20,$01,$dc,$18
    db $81,$3c,$0e,$20,$00,$6c,$18,$80,$3c,$00,$60,$00,$2e,$18,$80,$36,$00,$36,$00,$c6,$0c,$8f,$00,$80
    db $07,$00,$2f,$00,$d6,$0c,$83,$20,$f0,$03,$00,$27,$00,$06,$0c,$81,$38,$00,$03,$00,$af,$10,$06,$0c
    db $80,$3c,$00,$7d,$00,$fc,$00,$46,$0c,$80,$17,$00,$fe,$00,$f9,$00,$60,$0c,$c0,$03,$00,$cf,$00,$d1
    db $03,$00,$0c,$f8,$00,$00,$00,$00,$60,$03,$18,$21,$00,$7a,$03,$70,$21,$00,$0b,$07,$c0,$21,$e0,$00
    db $1f,$00
alien_left_11:
    dw alien_left_11_s0
    dw alien_left_11_s0
alien_left_11_s0:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$cd,$21,$00
    db $01,$0f,$c0,$18,$fc,$00,$00,$64,$07,$e0,$18,$c0,$01,$00,$b6,$03,$f0,$18,$80,$18,$00,$d3,$01,$f8
    db $0c,$c7,$00,$00,$3e,$00,$fc,$01,$3c,$0c,$00,$10,$00,$67,$00,$9d,$00,$1c,$0c,$00,$7f,$00,$e0,$00
    db $fc,$00,$0e,$0c,$00,$47,$00,$8e,$00,$f7,$00,$e6,$0c,$10,$00,$20,$00,$00,$0f,$00,$e0,$21,$e0,$00
    db $0f,$00
alien_right_0:
    dw alien_right_0_s0
    dw alien_right_0_s4
alien_right_0_s0:
    db $00,$00,$00,$77,$18,$f8,$01,$00,$f0,$3f,$00,$18,$f8,$03,$00,$ff,$0f,$80,$18,$f8,$00,$00,$47,$07
    db $e0,$f8,$18,$f0,$06,$00,$0a,$03,$78,$18,$c0,$03,$00,$83,$03,$38,$18,$c0,$1c,$00,$96,$03,$c8,$18
    db $c0,$0f,$00,$3c,$03,$40,$6f,$0c,$f8,$00,$40,$1c,$01,$ec,$87,$00,$09,$e0,$03,$00,$06,$01,$e0,$09
    db $c0,$0c,$30,$81,$00,$c0,$0c,$c0,$18,$3c,$01,$00,$de,$0f,$00,$0c,$c3,$18,$e0,$00,$00,$cf,$07,$e0
    db $0c,$c3,$10,$c0,$0b,$00,$c1,$07,$70,$0c,$c3,$18,$80,$1f,$04,$e1,$07,$30,$0c,$c0,$08,$00,$37,$00
    db $f0,$07,$10,$0c,$e0,$0e,$00,$e7,$01,$38,$c7,$00,$09,$e0,$06,$00,$87,$01,$1c,$09,$f0,$00,$00,$1e
    db $41,$0c,$09,$fe,$00,$00,$3e,$c1,$0c,$09,$fe,$00,$00,$f0,$01,$18,$09,$fe,$00,$07,$c0,$03,$70,$09
    db $fc,$00,$1f,$c0,$07,$60,$09,$f8,$01,$0f,$c0,$03,$20,$09,$f8,$03,$07,$e0,$80,$38,$09,$f8,$00,$07
    db $f0,$80,$3e,$09,$fe,$00,$07,$00,$80,$00
alien_right_0_s4:
    db $00,$00,$00,$cf,$21,$80,$1f,$03,$00,$21,$80,$3f,$00,$f8,$24,$80,$04,$00,$7e,$7f,$00,$e0,$24,$00
    db $60,$00,$a7,$3f,$80,$1b,$fc,$00,$00,$38,$00,$33,$3f,$80,$1b,$fc,$01,$00,$c9,$00,$6c,$3f,$80,$1b
    db $fc,$00,$00,$f3,$00,$c4,$3f,$00,$35,$1b,$84,$01,$00,$ce,$18,$c0,$7f,$00,$0c,$fe,$00,$00,$30,$00
    db $6e,$1f,$00,$0c,$fc,$00,$03,$c8,$00,$1c,$0f,$00,$0c,$fc,$01,$03,$80,$c0,$1d,$00,$e0,$0f,$fc,$01
    db $3e,$80,$00,$0c,$00,$fe,$7f,$00,$0f,$fc,$01,$3c,$00,$00,$bc,$00,$17,$7f,$00,$0f,$fc,$01,$38,$81
    db $00,$fe,$40,$13,$7f,$00,$0f,$fc,$00,$00,$83,$00,$7f,$00,$01,$7f,$00,$0f,$fe,$00,$00,$ee,$00,$73
    db $1c,$80,$7f,$00,$0c,$fe,$00,$00,$68,$00,$71,$1f,$c0,$18,$00,$01,$04,$e0,$1f,$c0,$18,$e0,$03,$0c
    db $e0,$1f,$c0,$18,$e0,$0f,$00,$01,$1f,$80,$18,$e0,$0c,$70,$07,$3f,$00,$18,$c1,$0c,$f0,$06,$7f,$00
    db $18,$80,$1c,$f0,$02,$3f,$00,$18,$80,$3e,$78,$03,$0f,$80,$18,$80,$0f,$78,$03,$0f,$e0,$18,$e0,$00
    db $78,$00,$0f,$00
alien_right_1:
    dw alien_right_1_s0
    dw alien_right_1_s4
alien_right_1_s0:
    db $00,$00,$00,$75,$18,$fe,$00,$00,$f8,$3f,$00,$18,$fe,$00,$00,$ff,$0f,$80,$18,$fe,$00,$00,$27,$07
    db $e0,$18,$f0,$00,$00,$39,$03,$f0,$18,$f0,$07,$00,$1c,$03,$78,$18,$c0,$03,$00,$83,$03,$b8,$18,$c0
    db $1c,$00,$b6,$03,$40,$18,$c0,$0f,$00,$3c,$07,$50,$18,$c0,$01,$01,$7c,$07,$30,$9c,$9d,$0c,$f0,$00
    db $30,$01,$00,$cc,$03,$30,$0c,$e0,$07,$3c,$81,$00,$cf,$03,$f8,$0c,$c0,$0c,$38,$81,$00,$c1,$03,$28
    db $0c,$c0,$18,$30,$03,$04,$c0,$03,$18,$0c,$c3,$00,$e0,$05,$03,$f0,$c3,$00,$09,$c3,$18,$80,$0c,$03
    db $f8,$09,$c0,$08,$00,$38,$00,$18,$09,$e0,$0e,$00,$e0,$00,$fa,$09,$e0,$06,$00,$c3,$00,$fa,$09,$f0
    db $00,$00,$0f,$00,$06,$15,$e0,$0e,$40,$1c,$15,$e0,$06,$01,$18,$15,$f0,$02,$03,$40,$15,$f8,$02,$0f
    db $60,$15,$f8,$00,$03,$60,$1e,$03,$78,$1e,$03,$00
alien_right_1_s4:
    db $00,$00,$00,$21,$e0,$00,$3f,$00,$21,$e0,$0f,$03,$80,$21,$e0,$0f,$00,$f8,$24,$e0,$02,$00,$7e,$7f
    db $00,$24,$00,$03,$00,$9f,$3f,$00,$24,$00,$71,$00,$c7,$3f,$80,$b8,$1b,$fc,$01,$00,$cb,$00,$64,$3f
    db $00,$1b,$fc,$00,$00,$f3,$00,$c5,$7f,$00,$1b,$fc,$00,$00,$17,$10,$c3,$7f,$00,$4f,$50,$1b,$03,$00
    db $00,$1c,$00,$c3,$3f,$00,$0f,$fe,$00,$03,$78,$c0,$1c,$00,$ff,$3f,$80,$0f,$fc,$00,$03,$c8,$80,$1c
    db $00,$12,$3f,$80,$0f,$fc,$01,$03,$80,$00,$3c,$40,$01,$3f,$80,$0f,$fc,$00,$3e,$00,$00,$5f,$3c,$00
    db $3f,$00,$0c,$fc,$01,$38,$80,$00,$cf,$3f,$80,$0c,$fc,$00,$00,$83,$00,$81,$0f,$80,$0c,$fe,$00,$00
    db $ee,$00,$0f,$0f,$a0,$0c,$fe,$00,$00,$6c,$00,$3f,$0f,$a0,$18,$00,$00,$00,$f0,$0f,$60,$18,$fe,$00
    db $04,$e1,$0f,$c0,$18,$fe,$00,$00,$61,$1f,$80,$21,$00,$24,$3f,$00,$1e,$80,$26,$21,$80,$06,$3f,$00
    db $21,$f0,$07,$3f,$80,$21,$f0,$00,$3f,$00
alien_right_2:
    dw alien_right_2_s0
    dw alien_right_2_s4
alien_right_2_s0:
    db $00,$00,$00,$77,$18,$fc,$01,$00,$f0,$3f,$00,$68,$18,$fc,$00,$00,$47,$07,$e0,$18,$e0,$00,$00,$39
    db $03,$f0,$18,$e0,$0e,$00,$1a,$03,$78,$18,$c0,$07,$00,$01,$03,$38,$18,$c0,$19,$00,$be,$03,$c0,$18
    db $c0,$0e,$00,$7c,$07,$40,$18,$80,$02,$01,$fc,$07,$30,$18,$80,$38,$01,$ec,$87,$00,$18,$80,$0d,$01
    db $c0,$87,$00,$0c,$fe,$00,$00,$03,$00,$c8,$03,$30,$0c,$f8,$00,$00,$f2,$00,$1f,$03,$f8,$0c,$e0,$03
    db $00,$c7,$00,$c1,$03,$28,$0c,$c0,$0e,$10,$07,$00,$fc,$03,$20,$0c,$80,$18,$e0,$00,$00,$fc,$8f,$00
    db $09,$83,$30,$e0,$0c,$00,$0e,$09,$87,$20,$c0,$0e,$00,$7c,$09,$87,$20,$00,$1c,$01,$e0,$09,$82,$30
    db $00,$7b,$0f,$80,$09,$80,$18,$00,$f1,$1f,$80,$09,$c0,$09,$04,$c0,$1f,$c0,$09,$e0,$03,$1e,$80,$1f
    db $40,$09,$f8,$03,$3f,$00,$1f,$00,$06,$f8,$03,$1f,$00,$06,$f8,$03,$0f,$c0,$06,$f8,$03,$0f,$e0,$06
    db $f8,$00,$0f,$00
alien_right_2_s4:
    db $00,$00,$00,$cf,$21,$c0,$1f,$03,$00,$bc,$24,$c0,$04,$00,$7e,$7f,$00,$1b,$fe,$00,$00,$03,$00,$9f
    db $3f,$00,$1b,$fe,$00,$00,$e1,$00,$a7,$3f,$80,$1b,$fc,$00,$00,$70,$00,$13,$3f,$80,$1b,$fc,$01,$00
    db $9b,$00,$ec,$3f,$00,$1b,$fc,$00,$00,$e7,$00,$c4,$7f,$00,$1b,$f8,$00,$00,$2f,$10,$c3,$7f,$00,$1b
    db $f8,$03,$00,$8e,$18,$c0,$7f,$00,$1b,$f8,$00,$00,$dc,$18,$00,$7f,$00,$1b,$e0,$00,$00,$3c,$00,$83
    db $3f,$00,$1b,$80,$0f,$00,$21,$00,$ff,$3f,$80,$0f,$fe,$00,$00,$3c,$00,$7c,$00,$12,$3f,$80,$0f,$fc
    db $00,$01,$e0,$00,$7f,$00,$c2,$3f,$00,$0c,$f8,$01,$0e,$80,$00,$0f,$08,$c0,$0c,$f8,$03,$3e,$00,$00
    db $c0,$0f,$e0,$0c,$f8,$02,$7c,$00,$00,$e7,$0f,$c0,$0c,$f8,$02,$70,$01,$00,$ce,$1f,$00,$09,$f8,$03
    db $20,$07,$00,$b8,$09,$f8,$01,$00,$8f,$01,$18,$09,$fc,$00,$00,$9c,$41,$0c,$09,$fe,$00,$01,$38,$e1
    db $04,$15,$83,$30,$f1,$00,$12,$81,$30,$12,$80,$3c,$12,$80,$3e,$12,$80,$00
alien_right_3:
    dw alien_right_3_s0
    dw alien_right_3_s4
alien_right_3_s0:
    db $00,$00,$00,$85,$ea,$68,$94,$18,$f0,$00,$80,$39,$03,$f0,$18,$f0,$06,$00,$08,$03,$78,$18,$c0,$03
    db $00,$83,$03,$b8,$18,$c0,$1c,$00,$b6,$03,$c0,$18,$c0,$0e,$00,$3c,$07,$40,$6f,$9c,$9d,$f7,$0c,$fe
    db $00,$00,$03,$00,$ef,$03,$f8,$0c,$f0,$00,$00,$d3,$00,$41,$03,$28,$0c,$e0,$07,$00,$c7,$00,$70,$03
    db $18,$0c,$c0,$0e,$00,$07,$00,$7c,$c3,$00,$09,$c0,$18,$e0,$0f,$00,$1e,$09,$c3,$10,$c0,$0e,$00,$06
    db $09,$c3,$10,$00,$1c,$00,$3c,$09,$c3,$18,$00,$7c,$01,$f0,$09,$c2,$08,$00,$70,$07,$80,$09,$e2,$00
    db $06,$e0,$0f,$c0,$09,$f0,$00,$0e,$c0,$0f,$60,$09,$f0,$07,$1f,$80,$0f,$00,$06,$f0,$07,$3f,$00,$06
    db $f0,$06,$7f,$00,$06,$f0,$07,$7f,$00,$06,$f0,$00,$7f,$00
alien_right_3_s4:
    db $00,$00,$00,$ce,$21,$c0,$0f,$03,$00,$bc,$92,$24,$08,$03,$00,$9f,$3f,$00,$24,$00,$60,$00,$87,$3f
    db $80,$b8,$1b,$fc,$01,$00,$cb,$00,$6c,$3f,$00,$b7,$35,$4f,$50,$df,$1b,$e0,$00,$00,$3e,$00,$ff,$3f
    db $80,$1b,$00,$0d,$00,$34,$00,$12,$3f,$80,$0f,$fe,$00,$00,$7c,$00,$77,$00,$01,$3f,$80,$0f,$fc,$00
    db $00,$e0,$00,$77,$0c,$c0,$3f,$00,$0c,$fc,$01,$0e,$80,$00,$f1,$0f,$e0,$0c,$fc,$01,$3c,$00,$00,$e0
    db $0f,$60,$0c,$fc,$01,$30,$01,$00,$c3,$0f,$c0,$0c,$fc,$01,$30,$87,$00,$cf,$1f,$00,$0c,$fc,$00,$20
    db $87,$00,$08,$7f,$00,$09,$fe,$00,$20,$0e,$60,$0c,$15,$00,$0c,$e0,$06,$15,$01,$78,$f0,$00,$12,$03
    db $70,$12,$07,$60,$12,$07,$70,$12,$07,$00
alien_right_4:
    dw alien_right_4_s0
    dw alien_right_4_s4
alien_right_4_s0:
    db $00,$00,$00,$85,$ea,$68,$94,$18,$f0,$00,$80,$31,$03,$f0,$18,$f0,$06,$04,$10,$03,$78,$18,$c0,$03
    db $00,$81,$03,$78,$18,$c0,$1c,$00,$be,$03,$c0,$18,$c0,$0e,$00,$3c,$07,$40,$6f,$9c,$9d,$f7,$18,$00
    db $01,$00,$8f,$03,$f8,$0c,$f0,$00,$00,$73,$00,$c1,$03,$28,$0c,$e0,$07,$00,$83,$04,$c0,$03,$18,$0c
    db $c0,$08,$38,$03,$03,$f0,$c3,$00,$09,$c3,$18,$f8,$03,$01,$f8,$09,$c0,$00,$00,$03,$00,$bc,$09,$c0
    db $19,$00,$fb,$00,$8e,$09,$c0,$03,$00,$ff,$20,$06,$09,$f8,$03,$00,$0f,$40,$0e,$09,$f8,$03,$60,$00
    db $00,$1c,$09,$f8,$00,$7f,$00,$81,$38,$1e,$83,$30,$1e,$81,$30,$1e,$80,$3c,$1e,$80,$3e,$1e,$80,$00
alien_right_4_s4:
    db $00,$00,$00,$ce,$21,$c0,$0f,$03,$00,$bc,$92,$24,$08,$03,$00,$1f,$3f,$00,$24,$00,$61,$40,$07,$3f
    db $80,$1b,$fc,$00,$00,$38,$00,$17,$3f,$80,$1b,$fc,$01,$00,$cb,$00,$ec,$3f,$00,$b7,$35,$4f,$50,$df
    db $1b,$f0,$00,$00,$18,$00,$ff,$3f,$80,$1b,$00,$07,$00,$3c,$00,$12,$3f,$80,$0f,$fe,$00,$00,$78,$00
    db $3c,$40,$01,$3f,$80,$0f,$fc,$00,$03,$80,$80,$3f,$3c,$00,$3f,$00,$0c,$fc,$01,$3f,$80,$80,$3f,$1f
    db $80,$0c,$fc,$00,$00,$00,$00,$3b,$0f,$c0,$0c,$fc,$01,$00,$9f,$00,$b8,$0f,$e0,$0c,$fc,$00,$00,$3f
    db $02,$f0,$0f,$60,$18,$80,$30,$04,$f0,$0f,$e0,$18,$86,$30,$00,$01,$0f,$c0,$18,$87,$00,$f8,$03,$1f
    db $80,$21,$f8,$03,$3f,$00,$21,$f8,$03,$1f,$00,$21,$f8,$03,$0f,$c0,$21,$f8,$03,$0f,$e0,$21,$f8,$00
    db $0f,$00
alien_right_5:
    dw alien_right_5_s0
    dw alien_right_5_s4
alien_right_5_s0:
    db $00,$00,$00,$75,$18,$fc,$00,$00,$f8,$3f,$00,$68,$94,$f8,$18,$f0,$07,$00,$02,$03,$78,$18,$c0,$03
    db $00,$81,$03,$38,$18,$c0,$1c,$00,$b6,$03,$c8,$18,$c0,$0e,$00,$3c,$03,$40,$6f,$0c,$f8,$00,$00,$1c
    db $01,$ec,$87,$00,$09,$e0,$03,$00,$8f,$01,$e0,$09,$e0,$0c,$20,$81,$00,$cc,$0c,$c0,$08,$38,$03,$00
    db $de,$0f,$00,$0c,$c3,$18,$f0,$02,$00,$47,$07,$e0,$0c,$c3,$10,$e0,$07,$10,$c1,$07,$70,$0c,$c3,$18
    db $80,$0b,$0c,$c1,$07,$30,$0c,$c0,$08,$00,$3b,$04,$e0,$07,$00,$09,$e0,$0e,$00,$e0,$03,$f0,$09,$e0
    db $06,$00,$81,$03,$18,$09,$f0,$00,$00,$04,$03,$b8,$15,$00,$1f,$03,$70,$15,$00,$70,$07,$e0,$15,$04
    db $61,$0f,$c0,$15,$0c,$21,$1f,$80,$15,$88,$21,$0f,$80,$15,$88,$03,$07,$e0,$15,$f8,$00,$07,$f0,$85
alien_right_5_s4:
    db $00,$00,$00,$21,$e0,$00,$3f,$00,$21,$c0,$0f,$03,$80,$bc,$92,$e0,$24,$00,$70,$00,$27,$3f,$80,$1b
    db $fc,$00,$00,$38,$00,$13,$3f,$80,$1b,$fc,$01,$00,$cb,$00,$6c,$3f,$80,$1b,$fc,$00,$00,$e3,$00,$c4
    db $3f,$00,$35,$1b,$80,$01,$00,$ce,$18,$c0,$7f,$00,$0c,$fe,$00,$00,$38,$00,$fe,$1f,$00,$0c,$fe,$00
    db $02,$c8,$00,$1c,$0f,$c0,$0c,$fc,$00,$03,$80,$80,$3d,$00,$e0,$0f,$fc,$01,$3f,$80,$00,$24,$00,$7e
    db $7f,$00,$0f,$fc,$01,$3e,$00,$01,$7c,$00,$17,$7f,$00,$0f,$fc,$01,$38,$80,$00,$bc,$c0,$13,$7f,$00
    db $0f,$fc,$00,$00,$83,$00,$be,$40,$00,$7f,$00,$0c,$fe,$00,$00,$ee,$00,$0f,$3f,$00,$0c,$fe,$00,$00
    db $68,$00,$11,$3f,$80,$18,$00,$00,$00,$4b,$3f,$80,$18,$f0,$01,$00,$f7,$3f,$00,$18,$f0,$07,$00,$0e
    db $7f,$00,$15,$f0,$06,$40,$1c,$15,$f0,$02,$c1,$18,$15,$f8,$02,$80,$18,$18,$f8,$00,$80,$3e,$7f,$00
    db $21,$80,$0f,$7f,$00,$ce
alien_right_6:
    dw alien_right_6_s0
    dw alien_right_6_s0
alien_right_6_s0:
    db $00,$00,$15,$f8,$00,$07,$00,$18,$f8,$03,$00,$f0,$7f,$00,$18,$f8,$03,$00,$ff,$1f,$00,$18,$f8,$00
    db $00,$1f,$07,$c0,$18,$f1,$00,$80,$23,$03,$f0,$18,$f0,$04,$00,$1c,$03,$f8,$18,$f0,$07,$00,$03,$03
    db $78,$18,$c0,$01,$00,$87,$03,$d8,$18,$c0,$1c,$00,$be,$03,$c0,$18,$c0,$06,$00,$7c,$07,$70,$18,$80
    db $00,$01,$fc,$07,$00,$15,$80,$3d,$01,$c8,$0c,$f8,$00,$00,$0b,$03,$80,$0f,$00,$0c,$e0,$03,$20,$87
    db $00,$d8,$07,$60,$0c,$c0,$0c,$30,$07,$00,$9f,$07,$f0,$0c,$c1,$18,$f0,$02,$00,$4a,$07,$70,$0c,$c3
    db $10,$f8,$03,$00,$f0,$07,$30,$0c,$c3,$10,$c0,$01,$01,$f0,$87,$00,$09,$c3,$18,$80,$1f,$00,$bc,$0c
    db $c0,$08,$00,$3b,$00,$9e,$7f,$00,$0c,$e0,$0e,$00,$f3,$00,$83,$7f,$00,$0c,$e0,$06,$00,$c1,$30,$87
    db $7f,$00,$0c,$f0,$00,$00,$0f,$20,$86,$7f,$00,$15,$c0,$0e,$20,$0c,$15,$80,$18,$e0,$04,$15,$83,$30
    db $f0,$06,$18,$03,$30,$e0,$06,$3f,$00,$18,$01,$78,$e0,$0f,$1f,$80,$18,$01,$7c,$e0,$07,$1f,$c0,$18
    db $01,$00,$f0,$00,$1f,$00
alien_right_7:
    dw alien_right_7_s0
    dw alien_right_7_s0
alien_right_7_s0:
    db $00,$00,$15,$f8,$00,$07,$00,$15,$c0,$03,$07,$f0,$15,$80,$1f,$07,$f0,$15,$00,$3f,$07,$c0,$09,$fe
    db $00,$00,$78,$03,$c0,$09,$fc,$00,$00,$e2,$03,$78,$09,$f8,$01,$08,$81,$03,$00,$09,$f8,$03,$38,$01
    db $3f,$00,$0c,$f8,$02,$00,$03,$1f,$80,$1f,$00,$0c,$f8,$00,$00,$77,$1e,$c0,$07,$40,$0c,$fe,$00,$00
    db $c7,$18,$00,$07,$f0,$0c,$fe,$00,$00,$13,$00,$43,$07,$50,$18,$00,$77,$00,$4e,$07,$30,$18,$00,$46
    db $00,$30,$87,$00,$15,$00,$17,$03,$f8,$09,$e1,$00,$80,$37,$03,$b8,$09,$e1,$0c,$80,$00,$03,$d8,$09
    db $c1,$08,$f8,$00,$01,$a0,$0c,$c3,$18,$f8,$02,$00,$3c,$7f,$00,$0c,$c3,$00,$e0,$03,$00,$1f,$3f,$00
    db $0c,$c3,$18,$c0,$0c,$40,$13,$3f,$80,$0c,$c1,$08,$81,$1c,$c0,$1b,$3f,$80,$0c,$e0,$0c,$01,$30,$00
    db $1f,$3f,$00,$0c,$e0,$06,$04,$d0,$00,$76,$7f,$00,$09,$f0,$02,$04,$81,$00,$e6,$0c,$f8,$00,$3c,$01
    db $00,$86,$7f,$00,$18,$fc,$01,$00,$83,$3f,$00,$18,$fc,$01,$08,$e3,$0f,$80,$18,$fc,$00,$08,$03,$0f
    db $e0,$21,$f8,$00,$0f,$00
alien_right_8:
    dw alien_right_8_s0
    dw alien_right_8_s0
alien_right_8_s0:
    db $00,$00,$00,$00,$12,$80,$00,$06,$fe,$00,$00,$3e,$06,$fc,$00,$00,$fe,$09,$f8,$01,$00,$f8,$7f,$00
    db $09,$f0,$03,$00,$fd,$7f,$00,$09,$e0,$07,$00,$9e,$7f,$00,$09,$e0,$0f,$00,$00,$e1,$00,$09,$c0,$0c
    db $43,$18,$c0,$0c,$09,$c1,$1c,$81,$08,$80,$1e,$09,$c0,$18,$01,$3c,$80,$3a,$09,$c0,$11,$01,$b8,$00
    db $24,$0c,$c0,$03,$00,$18,$00,$60,$3f,$00,$0c,$f8,$00,$00,$4d,$08,$c1,$1f,$80,$0c,$fc,$00,$00,$cf
    db $00,$83,$1f,$c0,$0c,$fc,$01,$00,$87,$00,$1d,$1f,$c0,$0c,$e0,$00,$00,$20,$00,$f8,$1f,$00,$09,$e3
    db $08,$0c,$41,$01,$f0,$09,$c3,$08,$10,$01,$00,$64,$0c,$c3,$10,$e0,$06,$00,$7e,$7f,$00,$0c,$c3,$10
    db $e0,$0e,$00,$3b,$7f,$00,$0c,$c1,$18,$80,$0c,$80,$0f,$3f,$00,$0c,$c0,$0c,$01,$38,$c0,$0d,$3f,$80
    db $0c,$e0,$06,$03,$e0,$c0,$18,$07,$80,$0c,$f0,$02,$0f,$80,$82,$10,$03,$f0,$0c,$f8,$00,$3f,$00,$00
    db $30,$03,$b8,$21,$00,$7c,$03,$00,$1e,$00,$1e,$1e,$c0,$00
alien_right_9:
    dw alien_right_9_s0
    dw alien_right_9_s0
alien_right_9_s0:
    db $00,$00,$00,$00,$00,$00,$00,$00,$06,$fe,$00,$0f,$00,$06,$f8,$00,$0f,$e0,$06,$f0,$03,$03,$c0,$06
    db $e0,$07,$03,$98,$09,$e0,$0f,$03,$f0,$c3,$00,$09,$c0,$0e,$07,$20,$81,$18,$09,$80,$1c,$0f,$00,$01
    db $3c,$09,$81,$38,$03,$60,$01,$74,$09,$83,$38,$01,$78,$01,$48,$0c,$82,$30,$00,$3c,$00,$40,$3f,$00
    db $0c,$84,$20,$00,$b8,$10,$c3,$1f,$80,$0c,$88,$21,$00,$9d,$00,$87,$1f,$c0,$0c,$88,$03,$00,$6f,$00
    db $8f,$11,$00,$0c,$f8,$00,$00,$c7,$00,$3f,$01,$84,$0c,$f0,$00,$00,$92,$00,$f9,$01,$fc,$0c,$e0,$04
    db $00,$30,$00,$b0,$01,$38,$0c,$e1,$0c,$84,$00,$01,$bc,$83,$00,$09,$e1,$08,$f0,$01,$01,$1c,$09,$e0
    db $0c,$c0,$07,$40,$0c,$0c,$e0,$06,$00,$1e,$60,$06,$7f,$00,$0c,$f0,$03,$00,$f8,$f0,$03,$1f,$00,$0c
    db $f8,$01,$03,$60,$f8,$03,$0f,$c0,$0c,$fc,$00,$0f,$00,$f8,$00,$0f,$e0,$21,$fe,$00,$0f,$00
alien_right_10:
    dw alien_right_10_s0
    dw alien_right_10_s0
alien_right_10_s0:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$15,$f0,$00,$7f,$00,$09,$c0,$00,$70,$07
    db $7f,$00,$09,$80,$1d,$70,$07,$7f,$00,$09,$80,$39,$70,$06,$7f,$00,$09,$80,$3b,$70,$04,$81,$00,$09
    db $00,$36,$70,$04,$81,$3c,$09,$00,$74,$00,$06,$01,$3c,$09,$00,$63,$00,$6c,$01,$6c,$0c,$00,$6b,$00
    db $f4,$01,$e0,$f1,$00,$0c,$00,$60,$00,$e4,$0f,$c0,$c1,$04,$0c,$08,$60,$00,$f5,$00,$c0,$81,$1c,$0c
    db $00,$62,$00,$3f,$00,$be,$01,$3c,$0c,$00,$06,$00,$9f,$00,$7f,$01,$e8,$0c,$c0,$00,$00,$8b,$00,$f3
    db $03,$c0,$0c,$c0,$18,$00,$06,$00,$00,$1f,$00,$06,$c0,$0e,$00,$5e,$06,$e0,$03,$00,$d0,$06,$f8,$00
    db $07,$00
alien_right_11:
    dw alien_right_11_s0
    dw alien_right_11_s0
alien_right_11_s0:
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$06,$f8,$00
    db $3f,$00,$06,$f0,$03,$00,$80,$09,$e0,$07,$00,$26,$3f,$00,$09,$c0,$0f,$00,$6d,$03,$80,$09,$80,$1f
    db $00,$cb,$01,$18,$0c,$80,$3c,$00,$3f,$00,$7c,$e3,$00,$0c,$00,$38,$00,$b9,$00,$e6,$00,$08,$0c,$00
    db $70,$00,$3f,$00,$07,$00,$fe,$0c,$00,$67,$00,$ef,$00,$71,$00,$e2,$0c,$00,$07,$00,$f0,$04,$00,$08
    db $00,$06,$f0,$00,$07,$00
ptable:
    dw ace0
    dw ace1
    dw ace2
    dw ace3
    dw ace4
    dw ace5
    dw ace6
    dw ace7
    dw ace8
    dw ace9
    dw ace10
    dw ace11
    dw ace12
    dw ace13
    dw ace14
    dw ace15
    dw ace16
    dw ace17
    dw ace18
    dw ace19
    dw ace20
    dw ace21
    dw ace22
    dw ace23
    dw ace24
    dw ace25
    dw ace26
    dw ace27
    dw ace28
etable_left:
    dw zombie_left_0
    dw zombie_left_1
    dw zombie_left_2
    dw zombie_left_3
    dw zombie_left_4
    dw zombie_left_5
    dw zombie_left_6
    dw zombie_left_7
    dw zombie_left_8
    dw zombie_left_9
    dw zombie_left_10
    dw zombie_left_11
etable_right:
    dw zombie_right_0
    dw zombie_right_1
    dw zombie_right_2
    dw zombie_right_3
    dw zombie_right_4
    dw zombie_right_5
    dw zombie_right_6
    dw zombie_right_7
    dw zombie_right_8
    dw zombie_right_9
    dw zombie_right_10
    dw zombie_right_11
atable_left:
    dw alien_left_0
    dw alien_left_1
    dw alien_left_2
    dw alien_left_3
    dw alien_left_4
    dw alien_left_5
    dw alien_left_6
    dw alien_left_7
    dw alien_left_8
    dw alien_left_9
    dw alien_left_10
    dw alien_left_11
atable_right:
    dw alien_right_0
    dw alien_right_1
    dw alien_right_2
    dw alien_right_3
    dw alien_right_4
    dw alien_right_5
    dw alien_right_6
    dw alien_right_7
    dw alien_right_8
    dw alien_right_9
    dw alien_right_10
    dw alien_right_11
hboom_pose:
    db $02,$02,$02,$02,$02,$01,$01,$01,$01,$00,$00,$00,$00
boom0:
    db $00,$00,$00,$00,$01,$fc,$3f,$fc,$3f,$fc,$3f,$fc,$3f,$fc,$3f,$fc,$3f,$fc,$3f,$fc,$3f,$fc,$3f,$fc
    db $3f,$fc,$3f,$fc,$00,$00,$00,$00
boom1:
    db $00,$00,$00,$3e,$7c,$3e,$7c,$3e,$7c,$3e,$7c,$3e,$7f,$e0,$03,$e0,$03,$e0,$03,$e0,$7f,$fe,$7c,$3e
    db $7c,$3e,$7c,$3e,$7c,$3e,$00,$00
boom2:
    db $00,$07,$c0,$07,$c0,$00,$c0,$00,$00,$00,$00,$00,$00,$00,$01,$c0,$01,$c0,$01,$c0,$00,$00,$00,$00
    db $00,$00,$c0,$07,$c0,$07,$c0,$07
death_blast0:
    db $00,$00,$00,$00,$01,$80,$00,$00,$08,$10,$07,$f0,$07,$e0,$27,$e4,$27,$ec,$07,$e0,$07,$e0,$08,$10
    db $02,$00,$01,$80,$00,$00,$00,$00
death_blast1:
    db $01,$c0,$21,$84,$31,$8c,$3b,$5c,$2b,$f6,$1f,$f8,$9f,$e8,$f7,$ff,$ff,$ff,$6f,$f4,$2f,$fc,$0e,$b0
    db $37,$ec,$35,$fc,$05,$a0,$11,$80
death_blast2:
    db $04,$80,$00,$c0,$75,$ce,$30,$5c,$2b,$54,$02,$e2,$58,$2a,$d4,$22,$c4,$33,$2c,$14,$4b,$c0,$0a,$b8
    db $14,$08,$75,$ce,$23,$44,$01,$20
death_blast_table:
    dw death_blast0
    dw death_blast1
    dw death_blast2
death_positions:
    db $d0,$50,$f0,$60,$e0,$70,$d0,$80,$f0,$50,$d0,$60,$f0,$80,$e0,$50
spark_bitmap:
    db $10,$00,$44,$10,$aa,$10,$44,$00
explosion_table:
    dw boom0
    dw boom1
    dw boom2
meteor_table:
    dw firefall
    dw firefall1
    dw firefall2
title_screen:
    db $01,$00,$ff,$62,$01,$00,$09,$7f,$ff,$ff,$f8,$3f,$ff,$ff,$fc,$0f,$98,$08,$01,$ff,$80,$08,$08,$ff
    db $c3,$ff,$c0,$07,$ff,$ff,$e0,$88,$1f,$02,$07,$ff,$88,$04,$03,$80,$00,$01,$80,$0f,$80,$08,$0b,$3f
    db $fc,$3f,$f0,$07,$ff,$1f,$fe,$01,$ff,$c1,$98,$20,$09,$1f,$fe,$00,$00,$e0,$00,$03,$ff,$87,$80,$24
    db $05,$0f,$fe,$00,$ff,$e1,$80,$3f,$04,$f0,$3f,$fc,$1f,$80,$07,$90,$20,$80,$5f,$01,$fc,$80,$57,$01
    db $fe,$80,$11,$01,$fe,$80,$0c,$0d,$ff,$8f,$ff,$07,$ff,$81,$ff,$e0,$ff,$e0,$01,$ff,$f0,$80,$1f,$02
    db $01,$ff,$80,$60,$02,$00,$00,$88,$05,$90,$10,$88,$01,$09,$bf,$f3,$ff,$00,$fe,$1c,$00,$00,$f9,$ff
    db $63,$fe,$00,$80,$77,$80,$f8,$88,$a5,$80,$a1,$88,$08,$a9,$00,$80,$07,$a1,$00,$01,$ff,$80,$b2,$02
    db $ff,$fc,$99,$00,$07,$87,$3f,$f0,$7f,$f0,$07,$fe,$e1,$00,$01,$f0,$91,$00,$01,$00,$b1,$00,$03,$c0
    db $3f,$f0,$e9,$00,$90,$04,$98,$5f,$01,$03,$88,$3b,$02,$ff,$c0,$99,$00,$80,$20,$b1,$00,$01,$e3,$c1
    db $00,$02,$fc,$18,$ff,$67,$00,$01,$81,$81,$02,$ff,$f0,$89,$04,$80,$a1,$01,$f8,$80,$08,$01,$fe,$99
    db $00,$01,$80,$80,$c1,$c9,$00,$04,$fe,$03,$ff,$c0,$80,$08,$01,$07,$a9,$00,$88,$c5,$90,$c0,$89,$00
    db $01,$f8,$a1,$00,$01,$3f,$81,$17,$81,$00,$04,$f0,$00,$3f,$f0,$8a,$4a,$a9,$00,$90,$5b,$88,$04,$91
    db $00,$80,$3b,$01,$e1,$80,$02,$a9,$00,$01,$3f,$ff,$16,$00,$01,$02,$fe,$30,$ff,$48,$00,$01,$89,$bd
    db $01,$03,$80,$c1,$81,$e9,$80,$7b,$02,$ff,$f0,$80,$04,$02,$ff,$00,$80,$9c,$01,$7f,$82,$b1,$80,$01
    db $88,$0f,$01,$f1,$89,$04,$80,$9d,$88,$08,$8b,$08,$03,$ff,$c7,$ff,$80,$98,$98,$c0,$88,$0f,$89,$04
    db $99,$00,$02,$0e,$7f,$88,$28,$81,$00,$01,$07,$a9,$00,$02,$3f,$fc,$c1,$00,$07,$f8,$01,$ff,$e3,$ff
    db $df,$f8,$82,$cb,$b1,$00,$a0,$5b,$a9,$00,$02,$fc,$0f,$80,$8d,$01,$e1,$8a,$61,$01,$39,$a1,$40,$b9
    db $00,$01,$e7,$ba,$92,$03,$00,$fe,$70,$98,$15,$ff,$45,$00,$01,$88,$f8,$a9,$00,$01,$f8,$88,$cd,$89
    db $7c,$01,$ff,$d9,$00,$88,$9d,$91,$00,$8a,$ba,$83,$f5,$c1,$00,$80,$ed,$03,$ff,$ff,$83,$81,$00,$01
    db $0f,$b1,$00,$02,$fc,$07,$90,$44,$89,$00,$01,$f8,$88,$a9,$03,$07,$ff,$9f,$82,$08,$89,$00,$03,$83
    db $ff,$9f,$c9,$00,$8a,$5f,$01,$e0,$80,$33,$88,$11,$91,$08,$03,$0f,$fc,$00,$80,$68,$04,$c3,$ff,$87
    db $f9,$a1,$00,$90,$66,$98,$6a,$b0,$b2,$03,$c0,$00,$07,$80,$17,$ff,$46,$00,$01,$80,$c1,$89,$d4,$82
    db $9b,$90,$c9,$80,$ba,$8a,$e0,$01,$f0,$80,$0f,$a1,$00,$01,$80,$80,$04,$01,$c0,$82,$a9,$01,$f0,$80
    db $ad,$01,$c0,$84,$e0,$02,$f8,$03,$89,$00,$02,$7f,$f9,$b9,$00,$89,$24,$03,$83,$ff,$80,$81,$00,$01
    db $1e,$93,$2c,$02,$fc,$3f,$d9,$00,$88,$b3,$8b,$08,$a1,$00,$80,$e2,$d1,$00,$88,$33,$01,$e0,$a1,$00
    db $02,$f0,$1f,$80,$1e,$01,$f3,$99,$00,$90,$3a,$02,$0f,$c7,$88,$50,$89,$7e,$01,$c7,$8c,$20,$8c,$3f
    db $09,$e3,$ff,$1f,$ff,$e7,$c0,$1f,$fc,$7f,$ff,$45,$00,$01,$8c,$d8,$89,$04,$89,$fc,$88,$08,$99,$00
    db $01,$c0,$80,$0f,$c1,$00,$80,$0b,$80,$cf,$c9,$00,$81,$a5,$9c,$e0,$9a,$3b,$99,$00,$02,$fe,$1e,$90
    db $a1,$04,$f8,$3f,$fc,$0f,$81,$50,$a3,$c0,$01,$ff,$80,$af,$90,$04,$01,$fe,$88,$0c,$01,$83,$80,$0a
    db $80,$4c,$80,$0a,$b1,$00,$95,$13,$8c,$50,$8a,$54,$81,$30,$06,$7f,$f3,$ff,$87,$fe,$0f,$a1,$00,$02
    db $07,$cf,$d1,$00,$01,$e3,$80,$2c,$01,$f3,$89,$00,$04,$80,$1f,$fc,$3f,$ff,$45,$00,$01,$8b,$79,$80
    db $7d,$88,$f8,$a8,$08,$a1,$00,$90,$e0,$b9,$00,$01,$e0,$80,$ad,$a6,$e0,$01,$07,$80,$de,$b1,$00,$98
    db $26,$9e,$e0,$01,$18,$a9,$00,$8e,$02,$90,$20,$88,$f4,$a1,$04,$a1,$00,$82,$c8,$9e,$e0,$a9,$00,$01
    db $c1,$8b,$d1,$8e,$50,$80,$24,$01,$c0,$a1,$00,$01,$fc,$a9,$00,$89,$61,$99,$00,$8b,$93,$91,$00,$01
    db $f8,$80,$55,$84,$a0,$84,$59,$a0,$61,$02,$fc,$7f,$88,$20,$82,$5d,$a8,$20,$01,$7f,$80,$2d,$a0,$20
    db $88,$a0,$01,$01,$8d,$b1,$02,$3f,$fe,$8c,$8b,$8e,$83,$8d,$a1,$80,$2d,$01,$e0,$91,$e0,$8c,$c0,$01
    db $cf,$8a,$ba,$01,$7f,$8d,$de,$8b,$8b,$81,$c9,$01,$e0,$8a,$c1,$01,$cc,$aa,$21,$80,$39,$89,$f5,$01
    db $c1,$8b,$06,$04,$ff,$e7,$ff,$80,$88,$33,$81,$ec,$a8,$7e,$80,$19,$c5,$19,$07,$c3,$9f,$fc,$7f,$fc
    db $3f,$df,$90,$f4,$01,$9c,$98,$5f,$01,$c0,$94,$15,$87,$22,$8b,$61,$01,$00,$80,$68,$01,$ee,$80,$87
    db $90,$19,$ff,$48,$a0,$08,$9e,$a2,$8b,$87,$01,$c3,$88,$8a,$81,$29,$b1,$20,$8b,$78,$01,$03,$e1,$00
    db $01,$0f,$c1,$00,$89,$ef,$01,$9f,$83,$9e,$01,$3c,$96,$de,$01,$c0,$a9,$00,$80,$aa,$01,$8c,$a9,$1f
    db $89,$00,$90,$dc,$03,$ff,$ff,$f9,$8e,$9a,$8a,$cf,$92,$d4,$81,$c1,$88,$30,$01,$81,$9d,$21,$99,$00
    db $03,$c7,$9f,$fc,$80,$4a,$99,$00,$01,$3c,$98,$5f,$01,$80,$91,$00,$89,$9f,$a1,$00,$03,$fc,$00,$0f
    db $91,$2e,$ff,$45,$00,$01,$88,$7b,$92,$76,$92,$ba,$01,$87,$a1,$00,$82,$00,$01,$f8,$90,$e0,$b9,$00
    db $84,$96,$80,$0f,$8c,$7d,$02,$0f,$fc,$b9,$00,$8a,$35,$81,$10,$02,$fc,$38,$b9,$00,$83,$ba,$83,$c1
    db $89,$be,$99,$00,$81,$fe,$a9,$00,$03,$fb,$ff,$c1,$82,$a7,$01,$fe,$82,$56,$a1,$00,$89,$0b,$01,$0d
    db $9f,$21,$01,$5f,$ff,$05,$be,$09,$03,$c7,$cf,$fc,$81,$8e,$b1,$00,$97,$4e,$91,$00,$8a,$bf,$89,$00
    db $02,$3f,$f8,$82,$a1,$9a,$00,$90,$81,$ff,$43,$a0,$08,$99,$00,$90,$53,$a9,$00,$83,$04,$a1,$00,$04
    db $ff,$67,$88,$07,$80,$bc,$89,$00,$03,$fd,$ff,$e8,$89,$00,$02,$e0,$1f,$c1,$00,$9d,$9c,$89,$00,$01
    db $f0,$8c,$b1,$8e,$be,$88,$b4,$80,$4d,$01,$bc,$a9,$00,$01,$f0,$93,$1b,$90,$5b,$01,$f3,$8f,$d7,$80
    db $44,$c9,$00,$02,$fe,$1d,$91,$00,$02,$e0,$df,$91,$00,$02,$87,$ef,$81,$00,$82,$23,$01,$3f,$80,$19
    db $01,$30,$a1,$00,$03,$00,$00,$20,$f0,$b8,$01,$04,$ff,$47,$a0,$09,$88,$61,$99,$00,$90,$93,$91,$00
    db $81,$14,$87,$64,$99,$00,$8c,$df,$01,$07,$83,$e0,$01,$80,$94,$44,$03,$f8,$1f,$fc,$80,$f9,$84,$9f
    db $83,$2d,$01,$c0,$a1,$00,$01,$0f,$a2,$00,$84,$94,$9a,$4e,$88,$53,$82,$00,$01,$b8,$a4,$7e,$81,$00
    db $95,$af,$8a,$5f,$01,$e3,$87,$e6,$84,$de,$a1,$00,$8c,$10,$80,$e7,$01,$3d,$91,$00,$01,$c1,$89,$00
    db $01,$0f,$80,$26,$04,$fc,$ff,$e1,$c0,$84,$34,$80,$19,$01,$70,$ff,$63,$a0,$0a,$88,$96,$01,$f1,$b9
    db $00,$01,$8f,$88,$bc,$8e,$cb,$81,$00,$93,$5f,$89,$d1,$89,$00,$01,$1e,$9d,$44,$97,$78,$03,$7f,$f8
    db $3f,$81,$14,$ab,$7e,$01,$0f,$92,$00,$01,$78,$80,$44,$91,$00,$01,$fe,$91,$53,$81,$00,$01,$38,$ac
    db $e0,$01,$e0,$91,$00,$ff,$05,$e6,$08,$83,$48,$84,$de,$01,$f8,$81,$00,$88,$19,$81,$41,$88,$e7,$01
    db $38,$90,$20,$01,$c3,$89,$7b,$03,$07,$ff,$03,$89,$8e,$02,$c0,$0f,$ff,$05,$d4,$0c,$ff,$08,$b1,$0c
    db $ff,$5c,$01,$00,$03,$0f,$ff,$7b,$81,$00,$85,$f7,$01,$7f,$80,$93,$01,$ef,$80,$e9,$01,$7d,$ff,$05
    db $c3,$09,$c9,$00,$80,$96,$95,$e0,$c9,$00,$84,$2d,$a9,$00,$80,$cc,$84,$e2,$01,$79,$80,$44,$89,$00
    db $02,$f7,$fc,$91,$53,$03,$fe,$0f,$fe,$b1,$00,$03,$80,$7f,$e0,$bd,$e0,$83,$48,$01,$7f,$e1,$00,$9a
    db $20,$01,$cf,$ff,$06,$0a,$0c,$01,$01,$89,$00,$83,$e0,$92,$39,$ff,$65,$00,$01,$be,$e0,$84,$eb,$9e
    db $e0,$91,$00,$01,$e0,$90,$e1,$9b,$15,$b1,$00,$89,$0f,$89,$00,$81,$ce,$b1,$00,$96,$e0,$01,$01,$8d
    db $da,$96,$e0,$9c,$f4,$87,$cc,$a9,$00,$01,$00,$91,$00,$95,$e0,$87,$e6,$81,$00,$01,$f0,$a1,$00,$a0
    db $5f,$82,$20,$80,$57,$02,$de,$03,$9c,$e0,$81,$00,$01,$e7,$a4,$e0,$ff,$09,$bb,$0a,$ff,$63,$01,$00
    db $09,$f8,$c4,$c0,$3c,$38,$00,$fc,$c4,$fc,$80,$06,$ff,$32,$01,$00,$01,$38,$90,$02,$01,$f8,$84,$96
    db $04,$3c,$f8,$38,$3c,$ff,$07,$5a,$08,$ff,$2c,$01,$00,$0c,$c4,$fc,$c4,$f8,$3c,$fc,$38,$c4,$00,$38
    db $c4,$fc,$ff,$34,$81,$00,$ff,$1e,$01,$00,$80,$59,$02,$c4,$00,$86,$4e,$06,$c4,$38,$f8,$fc,$00,$38
    db $80,$01,$ff,$13,$81,$00,$06,$c4,$c0,$c0,$c4,$00,$c0,$90,$06,$ff,$33,$bf,$00,$a0,$02,$01,$04,$80
    db $42,$80,$43,$ff,$32,$41,$00,$08,$c8,$c0,$ec,$c4,$c0,$10,$c4,$e4,$80,$88,$01,$10,$ff,$34,$81,$00
    db $ff,$1e,$01,$00,$80,$59,$80,$dc,$88,$e5,$02,$c4,$c0,$98,$05,$ff,$57,$00,$01,$01,$08,$ff,$38,$00
    db $01,$03,$d0,$c0,$d4,$ff,$5e,$00,$01,$01,$28,$b1,$00,$03,$04,$cc,$04,$ff,$13,$a1,$00,$83,$00,$02
    db $38,$fc,$80,$06,$02,$f8,$dc,$ff,$36,$00,$01,$01,$fc,$80,$04,$04,$f8,$00,$10,$00,$82,$62,$01,$c0
    db $ff,$06,$79,$0b,$ff,$2d,$01,$00,$08,$e0,$f8,$d4,$f8,$38,$10,$c4,$d4,$83,$82,$ff,$55,$00,$01,$02
    db $d4,$10,$89,$00,$08,$d4,$fc,$f8,$f8,$00,$08,$d4,$08,$ff,$13,$a1,$00,$81,$fa,$01,$04,$92,$00,$83
    db $2a,$ff,$32,$01,$00,$01,$d4,$91,$fe,$05,$c0,$00,$20,$00,$04,$8a,$43,$ff,$34,$00,$02,$80,$80,$03
    db $10,$c4,$cc,$ff,$58,$00,$02,$01,$cc,$99,$00,$06,$c4,$d0,$c0,$00,$10,$e4,$ff,$14,$62,$00,$ff,$3e
    db $00,$01,$01,$c8,$a1,$00,$82,$5e,$ff,$36,$00,$01,$01,$c8,$ff,$63,$00,$01,$05,$30,$00,$ec,$c4,$c8
    db $81,$a4,$02,$c4,$20,$ff,$14,$00,$01,$03,$38,$fc,$f8,$80,$c2,$01,$38,$ff,$36,$00,$06,$01,$34,$80
    db $fe,$01,$38,$91,$00,$03,$f8,$c0,$c4,$ff,$37,$00,$06,$03,$c0,$f8,$10,$86,$00,$03,$c4,$38,$10,$ff
    db $52,$00,$06,$80,$59,$04,$10,$00,$3c,$30,$8c,$00,$01,$fc,$86,$0d,$ff,$53,$62,$06,$ff,$b7,$01,$00
    db $01,$07,$ff,$40,$01,$00,$01,$47,$ff,$1d,$01,$00,$ff,$2e,$20,$00,$01,$42,$90,$03,$ff,$13,$20,$00
    db $e0,$16,$ff,$25,$60,$00,$01,$42,$88,$35,$03,$07,$07,$42,$90,$08,$90,$42,$98,$0a,$90,$09,$01,$42
    db $90,$0d,$01,$42,$ff,$1f,$a0,$00,$d0,$20,$ff,$13,$84,$00,$ff,$1f,$20,$00,$80,$12,$ff,$22,$00,$01
    db $80,$8c,$ff,$1b,$01,$00,$ff,$13,$20,$00,$88,$be,$98,$05,$90,$20,$ff,$49,$01,$00,$01,$46,$b8,$01
    db $ff,$42,$07,$02,$ff,$32,$41,$00,$01,$45,$c8,$01,$ff,$4b,$d7,$00,$ff,$17,$a6,$02,$a8,$19,$00
phase_bank:
boss_open:
    db $00,$00,$00,$00,$05,$00,$00,$00,$00,$00,$1e,$a0,$00,$00,$00,$04,$72,$14,$00,$00,$00,$04,$72,$14
    db $00,$00,$00,$21,$68,$80,$00,$00,$00,$9b,$da,$54,$00,$00,$0a,$ed,$e1,$56,$00,$00,$17,$73,$4c,$80
    db $00,$00,$6d,$bd,$91,$00,$00,$01,$aa,$ee,$80,$10,$00,$01,$aa,$ee,$80,$10,$00,$04,$db,$fa,$00,$a4
    db $00,$05,$a5,$dd,$2b,$52,$00,$0b,$93,$70,$2d,$d4,$00,$1b,$46,$c0,$eb,$a0,$00,$17,$11,$81,$be,$1a
    db $00,$74,$2a,$17,$f6,$e8,$00,$74,$2a,$17,$f6,$e8,$00,$5a,$d0,$55,$48,$00,$00,$d0,$45,$4b,$42,$88
    db $01,$45,$a0,$80,$94,$10,$01,$20,$96,$10,$50,$0c,$01,$8b,$a9,$02,$a4,$82,$01,$8b,$a9,$02,$a4,$82
    db $02,$82,$b6,$6a,$00,$40,$00,$9f,$fa,$16,$80,$20,$04,$8f,$7d,$5f,$41,$08,$00,$3d,$f4,$2b,$ea,$50
    db $04,$5f,$da,$aa,$a9,$54,$02,$7f,$a8,$c0,$55,$4a,$02,$7f,$a8,$c0,$55,$4a,$00,$fe,$aa,$88,$00,$80
    db $01,$7d,$52,$01,$08,$14,$01,$f7,$6c,$ae,$40,$00,$01,$6e,$b4,$f1,$00,$02,$01,$fe,$b2,$bc,$a2,$80
    db $03,$5a,$c9,$46,$13,$4a,$03,$5a,$c9,$46,$13,$4a,$02,$f9,$55,$11,$07,$a4,$03,$b7,$a8,$00,$2c,$20
    db $02,$ea,$94,$05,$48,$10,$03,$ae,$d2,$12,$99,$90,$05,$fd,$55,$01,$10,$c2,$07,$77,$54,$84,$00,$d0
    db $07,$77,$54,$84,$00,$d0,$07,$df,$aa,$80,$33,$ca,$0f,$7f,$55,$52,$0a,$d0,$0d,$bd,$45,$40,$20,$50
    db $1a,$c8,$0b,$60,$04,$20,$0a,$80,$16,$d5,$30,$a8,$09,$18,$1b,$50,$32,$28,$04,$06,$2e,$a0,$30,$d0
    db $06,$09,$ba,$0a,$cb,$20,$0d,$f9,$d0,$1f,$49,$88,$1a,$bc,$00,$aa,$af,$44,$3d,$a7,$44,$ad,$a0,$1a
    db $34,$03,$d9,$57,$a8,$68,$30,$1d,$ac,$aa,$a3,$5c,$00,$7f,$76,$aa,$44,$f4,$00,$81,$ae,$e0,$85,$50
    db $00,$87,$66,$92,$13,$2a,$00,$10,$92,$40,$26,$94,$00,$7d,$04,$08,$aa,$20,$00,$00,$00,$00,$80,$00
boss_closed:
    db $d0,$78,$10,$02,$ea,$03,$ae,$05,$fd,$07,$77,$07,$77,$07,$d1,$0f,$40,$0d,$b8,$1a,$c7,$0a,$80,$09
    db $18,$04,$06,$06,$09,$0d,$f9,$1a,$bc,$3d,$a7
boss_hit_img:
    db $d0,$78,$10,$02,$ea,$03,$ae,$05,$fd,$07,$77,$07,$77,$07,$df,$0f,$7f,$0d,$bb,$1a,$ff,$0a,$8e,$09
    db $18,$04,$06,$06,$09,$0d,$f9,$1a,$bc,$3d,$a7
boss_mouth:
    db $d8,$88,$08,$7f,$d9,$00,$ac,$00,$76,$a0,$ae,$81,$66,$10,$92,$7d,$04,$00,$00
bossfire0:
    db $00,$00,$3c,$00,$7f,$f0,$ff,$00,$ff,$fe,$7f,$e0,$3c,$00,$00,$00
bossfire1:
    db $00,$00,$3c,$00,$7f,$fc,$ff,$00,$ff,$fe,$7f,$f0,$3c,$00,$00,$00
bossfire2:
    db $00,$00,$3c,$00,$7f,$ff,$ff,$00,$ff,$fe,$7f,$f8,$3c,$00,$00,$00
bossfire_table:
    dw bossfire0
    dw bossfire1
    dw bossfire2
floor_ptr:
    dw floor0
    dw floor2
    dw floor4
    dw floor6
floor0:
    db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
    db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fc,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
    db $ff,$fb,$f8,$ff,$ff,$be,$ee,$3f,$ef,$ff,$ff,$f2,$3f,$ff,$bf,$ee,$98,$ff,$ff,$ff,$fe,$ff,$ff,$ef
    db $10,$50,$11,$0f,$55,$50,$00,$00,$0f,$fe,$34,$40,$47,$07,$01,$00,$01,$76,$17,$1f,$f1,$dc,$10,$04
    db $00,$e0,$20,$88,$18,$23,$a8,$ee,$0a,$18,$e0,$0e,$ea,$2c,$00,$8c,$80,$a0,$fc,$0a,$a0,$a8,$08,$08
    db $00,$40,$07,$f0,$00,$0f,$55,$5c,$00,$01,$40,$55,$55,$5c,$00,$04,$04,$04,$54,$00,$40,$00,$00,$00
    db $03,$82,$0f,$fa,$20,$0f,$fb,$ba,$00,$00,$00,$bf,$fe,$f0,$00,$2c,$0a,$00,$00,$a0,$20,$00,$02,$a0
    db $00,$01,$3f,$f0,$40,$03,$df,$14,$00,$00,$00,$5b,$f7,$00,$00,$11,$10,$41,$44,$40,$00,$00,$10,$00
    db $00,$08,$7e,$e8,$e0,$20,$be,$fe,$a8,$08,$8a,$eb,$fe,$00,$02,$c0,$18,$c6,$af,$8b,$00,$a8,$a2,$08
    db $00,$00,$f5,$51,$c0,$40,$1f,$ff,$50,$00,$05,$5c,$74,$00,$01,$40,$10,$04,$54,$04,$00,$10,$00,$00
    db $00,$18,$a0,$02,$a0,$a0,$0f,$ff,$fa,$2a,$2a,$fe,$20,$30,$00,$07,$a0,$0a,$aa,$00,$02,$a0,$04,$00
    db $01,$01,$40,$01,$00,$00,$07,$ff,$f5,$50,$45,$7e,$00,$00,$11,$1d,$c0,$14,$14,$00,$01,$10,$00,$00
    db $08,$a1,$80,$00,$80,$02,$02,$ff,$fe,$28,$af,$ff,$00,$20,$c0,$3e,$bc,$2a,$a8,$00,$0a,$fc,$a8,$88
    db $15,$f1,$00,$00,$40,$04,$10,$7f,$7c,$51,$5d,$df,$00,$00,$01,$3c,$7c,$00,$50,$00,$07,$f8,$00,$10
    db $23,$fa,$00,$00,$20,$08,$20,$3e,$02,$ba,$ab,$ff,$00,$02,$20,$78,$0a,$2a,$30,$00,$3f,$e0,$82,$78
    db $00,$74,$00,$00,$11,$00,$10,$00,$05,$d5,$51,$76,$00,$00,$7e,$50,$00,$10,$00,$00,$7f,$00,$11,$f0
    db $a6,$3a,$88,$20,$02,$48,$88,$a0,$79,$fe,$e8,$f0,$80,$03,$fe,$a0,$07,$e0,$a0,$03,$fe,$a0,$03,$8f
    db $40,$40,$c0,$00,$10,$00,$00,$00,$01,$dd,$54,$00,$00,$07,$d0,$00,$07,$c0,$00,$47,$f8,$00,$40,$5c
    db $02,$22,$e0,$20,$0f,$8e,$00,$80,$00,$fb,$ef,$00,$03,$8f,$80,$20,$0f,$c3,$82,$8f,$f8,$00,$3b,$a8
    db $0f,$00,$44,$00,$1f,$1c,$00,$1c,$00,$73,$9c,$00,$15,$0f,$00,$47,$01,$41,$71,$11,$40,$01,$15,$00
    db $0e,$a0,$8e,$ca,$f8,$08,$ee,$7e,$08,$78,$08,$00,$aa,$0e,$80,$0e,$8a,$80,$2e,$f8,$c3,$0e,$ae,$80
    db $00,$0c,$71,$5c,$f0,$10,$44,$50,$98,$10,$40,$05,$64,$40,$07,$1c,$00,$04,$40,$40,$07,$44,$44,$00
    db $00,$68,$a3,$fa,$03,$ba,$0a,$81,$b2,$01,$e0,$a2,$e7,$c2,$62,$20,$20,$09,$82,$02,$28,$ee,$a0,$20
    db $00,$10,$01,$55,$00,$50,$04,$50,$50,$00,$01,$55,$01,$01,$00,$00,$00,$00,$11,$51,$41,$00,$00,$00
floor2:
    db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
    db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$f3,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
    db $ff,$ef,$e3,$ff,$fe,$fb,$b8,$ff,$bf,$ff,$ff,$c8,$ff,$fe,$ff,$ba,$63,$ff,$ff,$ff,$fb,$ff,$ff,$bf
    db $41,$40,$44,$3d,$55,$40,$00,$00,$3f,$f8,$d1,$01,$1c,$1c,$04,$00,$05,$d8,$5c,$7f,$c7,$70,$40,$10
    db $03,$80,$82,$20,$60,$8e,$a3,$b8,$28,$63,$80,$3b,$a8,$b0,$02,$32,$02,$83,$f0,$2a,$82,$a0,$20,$20
    db $01,$00,$1f,$c0,$00,$3d,$55,$70,$00,$05,$01,$55,$55,$70,$00,$10,$10,$11,$50,$01,$00,$00,$00,$00
    db $0e,$08,$3f,$e8,$80,$3f,$ee,$e8,$00,$00,$02,$ff,$fb,$c0,$00,$b0,$28,$00,$02,$80,$80,$00,$0a,$80
    db $00,$04,$ff,$c1,$00,$0f,$7c,$50,$00,$00,$01,$6f,$dc,$00,$00,$44,$41,$05,$11,$00,$00,$00,$40,$00
    db $00,$21,$fb,$a3,$80,$82,$fb,$fa,$a0,$22,$2b,$af,$f8,$00,$0b,$00,$63,$1a,$be,$2c,$02,$a2,$88,$20
    db $00,$03,$d5,$47,$01,$00,$7f,$fd,$40,$00,$15,$71,$d0,$00,$05,$00,$40,$11,$50,$10,$00,$40,$00,$00
    db $00,$62,$80,$0a,$82,$80,$3f,$ff,$e8,$a8,$ab,$f8,$80,$c0,$00,$1e,$80,$2a,$a8,$00,$0a,$80,$10,$00
    db $04,$05,$00,$04,$00,$00,$1f,$ff,$d5,$41,$15,$f8,$00,$00,$44,$77,$00,$50,$50,$00,$04,$40,$00,$00
    db $22,$86,$00,$02,$00,$08,$0b,$ff,$f8,$a2,$bf,$fc,$00,$83,$00,$fa,$f0,$aa,$a0,$00,$2b,$f2,$a2,$20
    db $57,$c4,$00,$01,$00,$10,$41,$fd,$f1,$45,$77,$7c,$00,$00,$04,$f1,$f0,$01,$40,$00,$1f,$e0,$00,$40
    db $8f,$e8,$00,$00,$80,$20,$80,$f8,$0a,$ea,$af,$fc,$00,$08,$81,$e0,$28,$a8,$c0,$00,$ff,$82,$09,$e0
    db $01,$d0,$00,$00,$44,$00,$40,$00,$17,$55,$45,$d8,$00,$01,$f9,$40,$00,$40,$00,$01,$fc,$00,$47,$c0
    db $98,$ea,$20,$80,$09,$22,$22,$81,$e7,$fb,$a3,$c2,$00,$0f,$fa,$80,$1f,$82,$80,$0f,$fa,$80,$0e,$3e
    db $01,$03,$00,$00,$40,$00,$00,$00,$07,$75,$50,$00,$00,$1f,$40,$00,$1f,$00,$01,$1f,$e0,$01,$01,$71
    db $08,$8b,$80,$80,$3e,$38,$02,$00,$03,$ef,$bc,$00,$0e,$3e,$00,$80,$3f,$0e,$0a,$3f,$e0,$00,$ee,$a0
    db $3c,$01,$10,$00,$7c,$70,$00,$70,$01,$ce,$70,$00,$54,$3c,$01,$1c,$05,$05,$c4,$45,$00,$04,$54,$00
    db $3a,$82,$3b,$2b,$e0,$23,$b9,$f8,$21,$e0,$20,$02,$a8,$3a,$00,$3a,$2a,$00,$bb,$e3,$0c,$3a,$ba,$00
    db $00,$31,$c5,$73,$c0,$41,$11,$42,$60,$41,$00,$15,$91,$00,$1c,$70,$00,$11,$01,$00,$1d,$11,$10,$00
    db $01,$a2,$8f,$e8,$0e,$e8,$2a,$06,$c8,$07,$82,$8b,$9f,$09,$88,$80,$80,$26,$08,$08,$a3,$ba,$80,$80
    db $00,$40,$05,$54,$01,$40,$11,$41,$40,$00,$05,$54,$04,$04,$00,$00,$00,$00,$45,$45,$04,$00,$00,$00
floor4:
    db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
    db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$cf,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
    db $ff,$bf,$8f,$ff,$fb,$ee,$e3,$fe,$ff,$ff,$ff,$23,$ff,$fb,$fe,$e9,$8f,$ff,$ff,$ff,$ef,$ff,$fe,$ff
    db $05,$01,$10,$f5,$55,$00,$00,$00,$ff,$e3,$44,$04,$70,$70,$10,$00,$17,$61,$71,$ff,$1d,$c1,$00,$41
    db $0e,$02,$08,$81,$82,$3a,$8e,$e0,$a1,$8e,$00,$ee,$a2,$c0,$08,$c8,$0a,$0f,$c0,$aa,$0a,$80,$80,$80
    db $04,$00,$7f,$00,$00,$f5,$55,$c0,$00,$14,$05,$55,$55,$c0,$00,$40,$40,$45,$40,$04,$00,$00,$00,$00
    db $38,$20,$ff,$a2,$00,$ff,$bb,$a0,$00,$00,$0b,$ff,$ef,$00,$02,$c0,$a0,$00,$0a,$02,$00,$00,$2a,$00
    db $00,$13,$ff,$04,$00,$3d,$f1,$40,$00,$00,$05,$bf,$70,$00,$01,$11,$04,$14,$44,$00,$00,$01,$00,$00
    db $00,$87,$ee,$8e,$02,$0b,$ef,$ea,$80,$88,$ae,$bf,$e0,$00,$2c,$01,$8c,$6a,$f8,$b0,$0a,$8a,$20,$80
    db $00,$0f,$55,$1c,$04,$01,$ff,$f5,$00,$00,$55,$c7,$40,$00,$14,$01,$00,$45,$40,$40,$01,$00,$00,$00
    db $01,$8a,$00,$2a,$0a,$00,$ff,$ff,$a2,$a2,$af,$e2,$03,$00,$00,$7a,$00,$aa,$a0,$00,$2a,$00,$40,$00
    db $10,$14,$00,$10,$00,$00,$7f,$ff,$55,$04,$57,$e0,$00,$01,$11,$dc,$01,$41,$40,$00,$11,$00,$00,$00
    db $8a,$18,$00,$08,$00,$20,$2f,$ff,$e2,$8a,$ff,$f0,$02,$0c,$03,$eb,$c2,$aa,$80,$00,$af,$ca,$88,$80
    db $5f,$10,$00,$04,$00,$41,$07,$f7,$c5,$15,$dd,$f0,$00,$00,$13,$c7,$c0,$05,$00,$00,$7f,$80,$01,$01
    db $3f,$a0,$00,$02,$00,$82,$03,$e0,$2b,$aa,$bf,$f0,$00,$22,$07,$80,$a2,$a3,$00,$03,$fe,$08,$27,$82
    db $07,$40,$00,$01,$10,$01,$00,$00,$5d,$55,$17,$60,$00,$07,$e5,$00,$01,$00,$00,$07,$f0,$01,$1f,$00
    db $63,$a8,$82,$00,$24,$88,$8a,$07,$9f,$ee,$8f,$08,$00,$3f,$ea,$00,$7e,$0a,$00,$3f,$ea,$00,$38,$fa
    db $04,$0c,$00,$01,$00,$00,$00,$00,$1d,$d5,$40,$00,$00,$7d,$00,$00,$7c,$00,$04,$7f,$80,$04,$05,$c4
    db $22,$2e,$02,$00,$f8,$e0,$08,$00,$0f,$be,$f0,$00,$38,$f8,$02,$00,$fc,$38,$28,$ff,$80,$03,$ba,$80
    db $f0,$04,$40,$01,$f1,$c0,$01,$c0,$07,$39,$c0,$01,$50,$f0,$04,$70,$14,$17,$11,$14,$00,$11,$50,$00
    db $ea,$08,$ec,$af,$80,$8e,$e7,$e0,$87,$80,$80,$0a,$a0,$e8,$00,$e8,$a8,$02,$ef,$8c,$30,$ea,$e8,$00
    db $00,$c7,$15,$cf,$01,$04,$45,$09,$81,$04,$00,$56,$44,$00,$71,$c0,$00,$44,$04,$00,$74,$44,$40,$00
    db $06,$8a,$3f,$a0,$3b,$a0,$a8,$1b,$20,$1e,$0a,$2e,$7c,$26,$22,$02,$00,$98,$20,$22,$8e,$ea,$02,$00
    db $01,$00,$15,$50,$05,$00,$45,$05,$00,$00,$15,$50,$10,$10,$00,$00,$00,$01,$15,$14,$10,$00,$00,$00
floor6:
    db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
    db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$3f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
    db $fe,$fe,$3f,$ff,$ef,$bb,$8f,$fb,$ff,$ff,$fc,$8f,$ff,$ef,$fb,$a6,$3f,$ff,$ff,$ff,$bf,$ff,$fb,$ff
    db $14,$04,$43,$d5,$54,$00,$00,$03,$ff,$8d,$10,$11,$c1,$c0,$40,$00,$5d,$85,$c7,$fc,$77,$04,$01,$04
    db $38,$08,$22,$06,$08,$ea,$3b,$82,$86,$38,$03,$ba,$8b,$00,$23,$20,$28,$3f,$02,$a8,$2a,$02,$02,$00
    db $10,$01,$fc,$00,$03,$d5,$57,$00,$00,$50,$15,$55,$57,$00,$01,$01,$01,$15,$00,$10,$00,$00,$00,$00
    db $e0,$83,$fe,$88,$03,$fe,$ee,$80,$00,$00,$2f,$ff,$bc,$00,$0b,$02,$80,$00,$28,$08,$00,$00,$a8,$00
    db $00,$4f,$fc,$10,$00,$f7,$c5,$00,$00,$00,$16,$fd,$c0,$00,$04,$44,$10,$51,$10,$00,$00,$04,$00,$00
    db $02,$1f,$ba,$38,$08,$2f,$bf,$aa,$02,$22,$ba,$ff,$80,$00,$b0,$06,$31,$ab,$e2,$c0,$2a,$28,$82,$00
    db $00,$3d,$54,$70,$10,$07,$ff,$d4,$00,$01,$57,$1d,$00,$00,$50,$04,$01,$15,$01,$00,$04,$00,$00,$00
    db $06,$28,$00,$a8,$28,$03,$ff,$fe,$8a,$8a,$bf,$88,$0c,$00,$01,$e8,$02,$aa,$80,$00,$a8,$01,$00,$00
    db $40,$50,$00,$40,$00,$01,$ff,$fd,$54,$11,$5f,$80,$00,$04,$47,$70,$05,$05,$00,$00,$44,$00,$00,$00
    db $28,$60,$00,$20,$00,$80,$bf,$ff,$8a,$2b,$ff,$c0,$08,$30,$0f,$af,$0a,$aa,$00,$02,$bf,$2a,$22,$02
    db $7c,$40,$00,$10,$01,$04,$1f,$df,$14,$57,$77,$c0,$00,$00,$4f,$1f,$00,$14,$00,$01,$fe,$00,$04,$05
    db $fe,$80,$00,$08,$02,$08,$0f,$80,$ae,$aa,$ff,$c0,$00,$88,$1e,$02,$8a,$8c,$00,$0f,$f8,$20,$9e,$08
    db $1d,$00,$00,$04,$40,$04,$00,$01,$75,$54,$5d,$80,$00,$1f,$94,$00,$04,$00,$00,$1f,$c0,$04,$7c,$00
    db $8e,$a2,$08,$00,$92,$22,$28,$1e,$7f,$ba,$3c,$20,$00,$ff,$a8,$01,$f8,$28,$00,$ff,$a8,$00,$e3,$e9
    db $10,$30,$00,$04,$00,$00,$00,$00,$77,$55,$00,$00,$01,$f4,$00,$01,$f0,$00,$11,$fe,$00,$10,$17,$10
    db $88,$b8,$08,$03,$e3,$80,$20,$00,$3e,$fb,$c0,$00,$e3,$e0,$08,$03,$f0,$e0,$a3,$fe,$00,$0e,$ea,$00
    db $c0,$11,$00,$07,$c7,$00,$07,$00,$1c,$e7,$00,$05,$43,$c0,$11,$c0,$50,$5c,$44,$50,$00,$45,$40,$03
    db $a8,$23,$b2,$be,$02,$3b,$9f,$82,$1e,$02,$00,$2a,$83,$a0,$03,$a2,$a0,$0b,$be,$30,$c3,$ab,$a0,$03
    db $03,$1c,$57,$3c,$04,$11,$14,$26,$04,$10,$01,$59,$10,$01,$c7,$00,$01,$10,$10,$01,$d1,$11,$00,$00
    db $1a,$28,$fe,$80,$ee,$82,$a0,$6c,$80,$78,$28,$b9,$f0,$98,$88,$08,$02,$60,$80,$8a,$3b,$a8,$08,$00
    db $04,$00,$55,$40,$14,$01,$14,$14,$00,$00,$55,$40,$40,$40,$00,$00,$00,$04,$54,$50,$40,$00,$00,$00
moon_bitmap:
    db $00,$00,$0f,$f8,$00,$00,$00,$00,$7e,$0f,$00,$00,$00,$03,$fe,$0f,$e0,$00,$00,$0f,$ff,$ae,$10,$00
    db $00,$1f,$ff,$6c,$00,$00,$00,$7f,$fe,$78,$10,$00,$00,$e7,$79,$f0,$30,$00,$01,$cf,$fb,$b0,$00,$00
    db $03,$ff,$ff,$e8,$00,$00,$03,$ff,$ff,$fc,$00,$00,$07,$f9,$be,$fe,$00,$00,$0f,$f0,$7c,$ff,$40,$00
    db $1f,$e0,$7f,$ff,$b0,$00,$1e,$20,$ff,$87,$b0,$00,$3e,$71,$fc,$01,$20,$00,$3c,$f1,$f0,$00,$00,$00
    db $2c,$c1,$e0,$00,$00,$00,$6f,$c1,$c0,$01,$c0,$00,$7f,$93,$c0,$01,$c0,$00,$7f,$d6,$c0,$07,$00,$00
    db $ff,$e4,$c0,$0f,$00,$00,$fd,$81,$e0,$1e,$00,$00,$ff,$e3,$ff,$fe,$00,$00,$ef,$ff,$fe,$0c,$02,$80
    db $ff,$3f,$f0,$1c,$00,$00,$fe,$16,$e4,$1c,$90,$00,$fe,$30,$c0,$3f,$b0,$00,$ee,$60,$00,$ff,$f0,$00
    db $6f,$c0,$00,$ff,$f0,$00,$7f,$99,$81,$f1,$00,$00,$7f,$f9,$01,$c5,$60,$00,$3f,$ff,$83,$95,$78,$00
    db $3f,$ff,$80,$10,$00,$00,$3b,$c7,$c0,$00,$00,$00,$1f,$87,$78,$05,$00,$00,$1f,$8f,$7c,$0e,$00,$00
    db $0f,$df,$f8,$5e,$00,$00,$07,$fc,$ff,$df,$c0,$00,$03,$bd,$8f,$ff,$f0,$20,$03,$ff,$0f,$fe,$70,$40
    db $01,$fe,$3d,$f8,$20,$00,$00,$fe,$78,$f0,$00,$00,$00,$3e,$0b,$c0,$00,$00,$00,$1f,$07,$c0,$00,$00
    db $00,$0f,$80,$00,$10,$00,$00,$03,$f0,$00,$c0,$00,$00,$00,$7f,$ce,$00,$00,$00,$00,$07,$60,$00,$00
initial_screen:
    db $01,$00,$ff,$35,$01,$00,$01,$08,$ff,$36,$37,$00,$ff,$15,$01,$00,$01,$80,$ff,$4b,$4c,$00,$ff,$ff
    db $01,$00,$ff,$77,$01,$00,$01,$04,$ff,$4d,$4e,$00,$01,$01,$ff,$ff,$4e,$01,$ff,$ab,$01,$00,$ff,$4c
    db $07,$04,$ff,$16,$01,$00,$01,$20,$ff,$8f,$cb,$00,$ff,$3c,$9d,$02,$ff,$ff,$d9,$02,$ff,$97,$0c,$06
    db $01,$40,$ff,$ff,$73,$01,$ff,$ff,$01,$00,$ff,$ff,$01,$00,$ff,$ff,$01,$00,$ff,$ff,$01,$00,$ff,$ff
    db $01,$00,$ff,$ff,$01,$00,$ff,$ff,$01,$00,$ff,$ff,$01,$00,$ff,$a7,$01,$00,$01,$ff,$ff,$1f,$01,$00
    db $07,$80,$00,$c0,$c4,$cc,$10,$c4,$ff,$06,$83,$0e,$05,$a0,$00,$28,$10,$c4,$90,$0c,$01,$a0,$80,$17
    db $08,$04,$c0,$00,$00,$01,$80,$00,$d4,$90,$01,$04,$00,$01,$08,$42,$80,$16,$80,$09,$04,$00,$00,$42
    db $10,$88,$0a,$01,$10,$80,$0a,$01,$84,$ff,$a1,$94,$0b,$ff,$0d,$12,$0b,$b8,$0d,$a8,$0a,$80,$e0,$06
    db $c0,$38,$c4,$10,$38,$f8,$a1,$00,$04,$10,$fc,$f8,$c4,$88,$0c,$89,$00,$02,$f8,$fc,$90,$20,$01,$e4
    db $90,$01,$04,$00,$02,$10,$84,$80,$16,$80,$09,$80,$f6,$01,$20,$88,$0a,$81,$00,$02,$01,$08,$ff,$c3
    db $00,$01,$c0,$01,$01,$a0,$f0,$0a,$80,$20,$01,$c4,$90,$01,$04,$00,$04,$21,$08,$80,$16,$80,$09,$80
    db $f6,$01,$40,$88,$0a,$81,$00,$02,$02,$10,$ff,$a1,$00,$01,$08,$88,$00,$f8,$c4,$c4,$fc,$38,$3c,$ff
    db $05,$a4,$0e,$05,$a8,$00,$c4,$fc,$f8,$88,$0c,$80,$0a,$80,$14,$81,$e0,$01,$11,$ff,$22,$00,$01,$01
    db $38,$90,$01,$a0,$16,$a0,$09,$b0,$0a,$ff,$a3,$00,$02,$05,$c4,$c4,$e4,$10,$c4,$83,$cb,$90,$b6,$01
    db $c4,$83,$e0,$88,$0c,$8a,$e0,$01,$c0,$9b,$e0,$ff,$1e,$00,$01,$01,$88,$ff,$0c,$e4,$0f,$01,$a8,$f0
    db $0a,$01,$11,$ff,$c2,$00,$01,$ff,$18,$e0,$01,$8c,$e0,$e1,$20,$ff,$13,$40,$03,$ff,$a2,$00,$01,$05
    db $f8,$c4,$d4,$10,$c4,$a8,$e0,$81,$00,$01,$fc,$88,$0c,$04,$a0,$00,$f8,$fc,$8c,$f5,$bb,$e0,$a0,$20
    db $98,$09,$88,$0a,$01,$30,$ff,$c7,$00,$01,$d6,$e0,$8a,$00,$e6,$e0,$01,$cc,$90,$01,$85,$d6,$01,$21
    db $80,$16,$88,$09,$01,$00,$94,$ea,$01,$cc,$8a,$00,$02,$42,$01,$ff,$20,$40,$07,$01,$45,$ff,$56,$01
    db $00,$01,$07,$90,$01,$ff,$ba,$20,$00,$ff,$ff,$01,$00,$ff,$8a,$01,$00,$01,$46,$c8,$01,$01,$44,$b0
    db $01,$01,$47,$a8,$01,$ff,$40,$20,$00,$00
shadow equ $f000
shadow_plus1 equ $f001
shadow_end equ $fd00
row_dict_base equ $8f08
phase_size equ $0e21
vars_size equ 109
