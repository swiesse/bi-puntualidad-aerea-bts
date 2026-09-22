#!/usr/bin/env python3
"""
Convierte el CSV mensual del BTS (Reporting Carrier On-Time Performance)
a Parquet con compresion zstd.

Motivo: el CSV descomprimido pesa ~258 MiB y supera el limite duro de 100 MB
por archivo de GitHub. En Parquet + zstd el mismo contenido cabe holgadamente
en el repositorio, sin perder una sola fila ni columna, y ademas queda en un
formato columnar que es el adecuado para cargas analiticas (ver seccion 1.5
del README principal).

Uso:
    py -3 etl/csv_to_parquet.py <entrada.csv> <salida.parquet>
"""

import sys
import os
import pyarrow as pa
import pyarrow.csv as pv
import pyarrow.parquet as pq

COMPRESSION = "zstd"
COMPRESSION_LEVEL = 9


def humanize(num_bytes: float) -> str:
    for unit in ("B", "KiB", "MiB", "GiB"):
        if num_bytes < 1024:
            return f"{num_bytes:.1f} {unit}"
        num_bytes /= 1024
    return f"{num_bytes:.1f} TiB"


def convert(src: str, dst: str) -> None:
    print(f"Leyendo  : {src}")
    print(f"Tamano   : {humanize(os.path.getsize(src))}")

    # El CSV del BTS termina cada fila con una coma final, lo que genera una
    # columna anonima vacia. Se lee todo como esta y luego se descarta.
    table = pv.read_csv(
        src,
        read_options=pv.ReadOptions(block_size=64 << 20),
        parse_options=pv.ParseOptions(newlines_in_values=False),
        convert_options=pv.ConvertOptions(strings_can_be_null=True),
    )

    descartadas = [
        name for name in table.column_names
        if not name.strip() or name.startswith("Unnamed")
    ]
    if descartadas:
        table = table.drop(descartadas)
        print(f"Columnas descartadas (vacias): {descartadas}")

    print(f"Filas    : {table.num_rows:,}")
    print(f"Columnas : {table.num_columns}")

    pq.write_table(
        table,
        dst,
        compression=COMPRESSION,
        compression_level=COMPRESSION_LEVEL,
        use_dictionary=True,
        version="2.6",
    )

    origen = os.path.getsize(src)
    destino = os.path.getsize(dst)
    print(f"\nEscrito  : {dst}")
    print(f"Tamano   : {humanize(destino)}")
    print(f"Reduccion: {origen / destino:.1f}x  ({100 * (1 - destino / origen):.1f}% menos)")

    # Verificacion: releer y comparar dimensiones.
    check = pq.read_table(dst)
    assert check.num_rows == table.num_rows, "Discrepancia en numero de filas"
    assert check.num_columns == table.num_columns, "Discrepancia en numero de columnas"
    print("Verificacion: filas y columnas coinciden tras releer el Parquet.")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    convert(sys.argv[1], sys.argv[2])
