org $8000
start:
    ld b,120
    xor a
beep:
    xor 16
    out ($fe),a
    ld c,160
tone_wait:
    dec c
    jp nz, tone_wait
    dec b
    jp nz, beep
    xor a
    out ($fe),a
release:
    halt
    call fire
    jp nz, release
press:
    halt
    call fire
    jp z, press
release_after:
    halt
    call fire
    jp nz, release_after
    ld bc,0
    ret
fire:
    ld bc,$7ffe
    in a,(c)
    bit 0,a
    jp z, pressed
    ld bc,$001f
    in a,(c)
    and 31
    ld d,a
    and 3
    cp 3
    jp z, not_pressed
    ld a,d
    and 12
    cp 12
    jp z, not_pressed
    ld a,d
    bit 4,a
    ret
pressed:
    ld a,1
    or a
    ret
not_pressed:
    xor a
    ret
