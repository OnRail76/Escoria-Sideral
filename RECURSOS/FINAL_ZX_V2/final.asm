; Pantalla final ZX Spectrum 48K
mostrar_final:
    ld hl, final_scr
    ld de, $4000
    ld bc, 6912
    ldir
    ret
final_scr:
    incbin "final.scr"
