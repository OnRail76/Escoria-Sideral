ALIEN ZX 48K
32x32, 1 bit, 6 carrera + 6 muerte por direccion. Derecha primero, izquierda espejo.
Ancla nominal (16,31), pies alineados. Escala uniforme de la hoja original.
128 bytes/frame, 4 bytes/fila, MSB izquierda. sprites_masks: imagen seguida de mascara.
chars_8x8 y masks_chars_8x8: 16 caracteres por frame, orden filas de tiles, 8 bytes por tile.
Componer (fondo AND mascara) OR sprite; mascara inversa de silueta dilatada 1 pixel. Restaurar fondo antes de mover.
PNG RGBA: blanco opaco y negro transparente, no incluye halo de mascara.
ASM DB hexadecimal estilo sjasmplus. Sin rutina de dibujo ni prueba emulador.
