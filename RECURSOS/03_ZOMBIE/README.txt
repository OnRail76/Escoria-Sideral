ZOMBIE ZX 48K
32x32, 1 bit, 6 caminar + 6 muerte por direccion. Izquierda primero.
Ancla (16,31), pies alineados. 128 bytes/frame, MSB izquierda.
 sprites_masks: imagen seguida de mascara. chars_8x8: 16 tiles por frame, orden filas de tiles.
(fondo AND mascara) OR sprite; mascara inversa de silueta dilatada 1 pixel. Restaurar fondo antes de mover. PNG blanco opaco, negro transparente.
ASM DB estilo sjasmplus. Sin rutina de dibujo ni prueba en emulador.
