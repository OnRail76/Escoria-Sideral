; Ensamblar con los datos en RAM fuera de VRAM
mostrar_carga:
    ld hl,pantalla_carga
    ld de,$4000
    ld bc,6912
    ldir
    ret
pantalla_carga:
    incbin "escoria_sideral_carga.scr"
