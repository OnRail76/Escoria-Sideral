# Fuentes V1.0

Instantánea del código aprobado 0.21.2. Los nombres de archivo internos del generador y cabeceras de cinta se conservan deliberadamente. `base_sin_carga.tap` es un auxiliar de regresión, no la edición jugable.

Requiere Python 3 y Pillow (`python3 -m pip install Pillow`). Ejecutar `python3 build_release.py`. Los ZIP de recursos de esta carpeta son dependencias del generador; no moverlos.

Tests específicos: `python3 test_audio212.py`, `python3 test_audio.py`, `python3 test_render.py`, `python3 test_boss20.py`, `python3 test_loading.py`, `python3 test_kempston.py`. `test_cpu.py` contiene la regresión general; sus registros históricos no equivalen a una nueva ejecución completa. Simulación de instrucciones Z80 sin ULA real ni emulación BASIC completa.
