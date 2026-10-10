#!/usr/bin/env bash
# Genera el árbol de fixtures masivos para la paginación de list_assets.
# Uso: ./tools/gen_bulk_assets.sh [cantidad] (por defecto 250).
set -euo pipefail
COUNT="${1:-250}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/assets/bulk"
mkdir -p "$DIR"
for i in $(seq -w 0 $((COUNT - 1))); do
	printf 'fixture bulk file %s for list_assets paging\n' "$i" > "$DIR/file_$i.txt"
done
echo "Generados $COUNT ficheros en $DIR"
