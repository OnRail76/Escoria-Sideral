; SJASMPlus. Mapa por filas; indices desde cero.
LABORATORIO_W EQU 24
LABORATORIO_H EQU 3
LABORATORIO_TILE_COUNT EQU 72
laboratorio_tiles: INCBIN "tiles.bin"
laboratorio_map: INCBIN "map.bin"
; map[r*24+((offset+c) mod 24)]
