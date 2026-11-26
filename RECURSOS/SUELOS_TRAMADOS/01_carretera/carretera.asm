; SJASMPlus. Datos de suelo, mapa por filas, indices desde cero.
ROAD_W EQU 24
ROAD_H EQU 3
ROAD_TILE_COUNT EQU 72
road_tiles: INCBIN "tiles.bin"
road_map: INCBIN "map.bin"
; Para columna visible c, fila r: map[r*24 + ((offset+c) mod 24)].
; Cada tile contiene 8 bytes, uno por linea, bit 7 a la izquierda.
