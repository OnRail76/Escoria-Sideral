; SJASMPlus. Mapa por filas; indices desde cero.
ULTRATECNOLOGIA_W EQU 24
ULTRATECNOLOGIA_H EQU 3
ULTRATECNOLOGIA_TILE_COUNT EQU 71
ultratecnologia_tiles: INCBIN "tiles.bin"
ultratecnologia_map: INCBIN "map.bin"
; map[r*24+((offset+c) mod 24)]
