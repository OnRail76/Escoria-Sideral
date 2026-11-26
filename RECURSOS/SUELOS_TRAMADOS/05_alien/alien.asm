; SJASMPlus. Mapa por filas; indices desde cero.
ALIEN_W EQU 24
ALIEN_H EQU 3
ALIEN_TILE_COUNT EQU 72
alien_tiles: INCBIN "tiles.bin"
alien_map: INCBIN "map.bin"
; map[r*24+((offset+c) mod 24)]
