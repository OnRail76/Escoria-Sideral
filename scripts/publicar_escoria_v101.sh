#!/usr/bin/env bash
set -euo pipefail
repo=OnRail76/Escoria-Sideral
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
zip=${1:-"$here/ESCORIA_SIDERAL_V1.0.1_PROYECTO_FINAL.zip"}
zip=$(realpath "$zip")
for cmd in gh git unzip sha256sum; do command -v "$cmd" >/dev/null || { echo "Falta $cmd" >&2; exit 1; }; done
gh auth status
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
if gh release view v1.0.1 --repo "$repo" >/dev/null 2>&1; then echo 'La release v1.0.1 ya existe; no se sobrescribe.'; exit 1; fi
unzip -q "$zip" -d "$work"
p="$work/ESCORIA_SIDERAL_V1.0.1"
(cd "$p" && sha256sum -c SHA256SUMS.txt --quiet)
printf '%s  %s\n' df2d7b596060ee42a675de0b748e14e2aa2ce9d8be9a2308e7f538df1240766e "$p/JUEGO/ESCORIA_SIDERAL_V1.0.1.tap" | sha256sum -c -
gh repo clone "$repo" "$work/repo" -- --branch main
cd "$work/repo"
# Do not replace a more recent revision or a different base.
printf '%s  %s\n' 250c3210909e3479801fbec8212b2745d588a9035ae2c6b7c4d87c847a8990f2 JUEGO/ESCORIA_SIDERAL_V1.0.tap | sha256sum -c -
[[ ! -e VERSION || $(cat VERSION) = '1.0' ]] || { echo 'VERSION inesperada; se cancela.' >&2; exit 1; }
branch=release/v1.0.1
# A separate branch retains main until publication is ready.
git switch -c "$branch"
for d in JUEGO FUENTES RECURSOS DOCUMENTACION CAPTURAS; do cp -a "$p/$d/." "$d/"; done
cp "$p/LEEME.md" "$p/CHANGELOG.md" "$p/VERSION" "$p/SHA256SUMS.txt" .
# Remove only the superseded current-edition files (v1.0 remains in its tag/release).
git rm --ignore-unmatch JUEGO/ESCORIA_SIDERAL_V1.0.tap DOCUMENTACION/ESCORIA_SIDERAL_V1.0_ATLAS_MANUAL_MEMORIA.pdf FUENTES/ESCORIA_SIDERAL_ALFA_21_2.tap
for f in "$p/FUENTES/PRUEBAS_V1_0/"*; do git rm --ignore-unmatch "FUENTES/$(basename "$f")"; done
cat > README.md <<'EOF'
# ESCORIA SIDERAL

<p align="center"><img src="DOCUMENTACION/PORTADA_OFICIAL.png" alt="Carátula oficial ESCORIA SIDERAL" width="480"></p>

**El universo también tiene basura…**

**V1.0.1 · ZX Spectrum 48K · 2026 Tony C. Ware**

1988, el presente. Tras la caída de un meteoro en Barcelona, los muertos salen de sus tumbas y extrañas criaturas siembran el terror. Ace Wisconsin, exguerrillero y operativo militar del CNI, recibe la misión de detener el ataque. No sabe ni si mañana saldrá el sol.

## Descargas

- [TAP V1.0.1](JUEGO/ESCORIA_SIDERAL_V1.0.1.tap)
- [Manual, atlas y memoria técnica V1.0.1](DOCUMENTACION/ESCORIA_SIDERAL_V1.0.1_ATLAS_MANUAL_MEMORIA.pdf)
- [Release y paquete completo](https://github.com/OnRail76/Escoria-Sideral/releases/tag/v1.0.1)

## Características

- Cinco fases y cinco jefes con dificultad progresiva.
- Director táctico: enemigos frontales, meteoritos y relámpagos posicionales.
- Gráficos tramados estáticos, sprites con máscara, scroll de suelo y compositor antiparpadeo.
- Beeper original con prioridades sonoras y reserva de CPU.
- Multicarga en una cinta TAP, protegida frente a SPACE mantenido. ZX Spectrum 48K.

## Controles

| Acción | Teclado | Kempston |
|---|---|---|
| Izquierda / derecha | O / P | Izquierda / derecha |
| Saltar | Q | Arriba |
| Agacharse | A | Abajo |
| Disparar | SPACE | FIRE |

Carga con `LOAD ""`, espera el beep y pulsa y suelta SPACE o FIRE. En el título, SPACE selecciona teclado exclusivo; FIRE selecciona Kempston y teclado. Emulador de referencia: Fuse (48K).

![Barcelona, referencia V1.0](CAPTURAS/V1_fase2.png)

## Código y documentación

[Fuentes y compilación](FUENTES/README_V1.md) · [Inventario SHA-256](SHA256SUMS.txt) · [Historial](CHANGELOG.md) · [Información del paquete](LEEME.md).

Gold Master de 93.481 bytes, idéntico al FIX 3 aprobado en Fuse. SHA-256: `df2d7b596060ee42a675de0b748e14e2aa2ce9d8be9a2308e7f538df1240766e`.

## Créditos

Diseño, dirección, código, arte y edición: **Tony C. Ware**. Tecnología: **GRIT ENGINE ZX**.

© 2026 Tony C. Ware. Véase [LICENSE](LICENSE).
EOF
git add README.md LEEME.md CHANGELOG.md VERSION SHA256SUMS.txt JUEGO FUENTES RECURSOS DOCUMENTACION CAPTURAS
git diff --cached --stat
git commit -m 'ESCORIA SIDERAL V1.0.1 - Tactical Director Gold Master'
git push -u origin "$branch"
pr=$(gh pr create --repo "$repo" --base main --head "$branch" --title 'ESCORIA SIDERAL V1.0.1' --body 'FIX 3 aprobado en Fuse. TAP verificado, atlas actualizado y bancos gráficos originales conservados.')
gh pr merge "$pr" --repo "$repo" --merge
# Only publish after main contains the approved binary.
git fetch origin main
target=$(git rev-parse origin/main)
git show "$target:JUEGO/ESCORIA_SIDERAL_V1.0.1.tap" > "$work/published.tap"
cmp "$work/published.tap" "$p/JUEGO/ESCORIA_SIDERAL_V1.0.1.tap"
gh release create v1.0.1 --repo "$repo" --target "$target" --title 'ESCORIA SIDERAL V1.0.1' --latest --notes 'Gold Master: director frontal, peligros ambientales tácticos, multicarga y controles corregidos. FIX 3 aprobado en Fuse. Fondos estáticos, bancos y jefes intactos. Incluye TAP, atlas, portada y paquete completo.' "$p/JUEGO/ESCORIA_SIDERAL_V1.0.1.tap" "$p/DOCUMENTACION/ESCORIA_SIDERAL_V1.0.1_ATLAS_MANUAL_MEMORIA.pdf" "$p/DOCUMENTACION/PORTADA_OFICIAL.png" "$zip"
gh release view v1.0.1 --repo "$repo" --json url,tagName,assets,isDraft,isPrerelease
