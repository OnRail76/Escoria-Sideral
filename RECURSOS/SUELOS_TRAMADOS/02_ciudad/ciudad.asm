; SJASMPlus. Mapa por filas; indices desde cero.
CIUDAD_W EQU 24
CIUDAD_H EQU 3
CIUDAD_TILE_COUNT EQU 72
ciudad_tiles: INCBIN "tiles.bin"
ciudad_map: INCBIN "map.bin"
; map[r*24+((offset+c) mod 24)]
