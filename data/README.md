# Datos del proyecto

## Procedencia

Todos los datos provienen del **Bureau of Transportation Statistics (BTS)**, tabla
*Reporting Carrier On-Time Performance (1987–present)*, de la librería TranStats del
U.S. Department of Transportation.

- **Fuente:** https://www.transtats.bts.gov/DL_SelectFields.aspx?gnoyr_VQ=FGJ&QO_fu146_anzr=b0-gvzr
- **Licencia:** dato público del Gobierno de EE. UU., sin restricción de uso.
- **Archivo descargado:** `On_Time_Reporting_Carrier_On_Time_Performance_(1987_present)_2026_4.csv`
- **Periodo contenido:** **abril de 2026** (`Year = 2026`, `Month = 4`).
  El sufijo `_2026_4` del nombre indica año y mes, según el *readme* oficial del BTS
  incluido en `reference/bts_readme_field_layout.html`.
- **Cobertura geográfica:** **nacional**. 52 códigos de estado distintos en origen y en
  destino (50 estados + DC + territorios). El archivo **no está filtrado por estado**.

## Volumetría verificada

| Métrica | Valor |
|---|---|
| Filas de datos (sin cabecera) | 597 919 |
| Columnas | 110 |
| Tamaño CSV descomprimido | ~270 MB |
| Tamaño ZIP original | ~30 MB |
| Periodos distintos en el archivo | 1 (`2026-4`) |
| Estados distintos en origen | 52 |
| Vuelos con origen en Idaho (`ID`) | 2 615 (0,44 %) |
| Vuelos con destino en Idaho (`ID`) | 2 610 (0,44 %) |
| Vuelos con origen **o** destino en Idaho | 5 225 (0,87 %) |

## Estructura de carpetas

```
data/
├── raw/          # CSV completo del BTS. NO versionado (.gitignore): supera el limite
│                 # de 100 MB por archivo de GitHub. Se descarga desde la fuente.
├── samples/      # Subconjuntos reducidos, si versionados en el repositorio
│   ├── idaho_2026_04.csv               # 5 225 filas: origen O destino = ID
│   └── muestra_nacional_2026_04_10k.csv # 10 000 primeras filas, cobertura nacional
└── reference/
    └── bts_readme_field_layout.html    # Readme oficial del BTS con el layout de campos
```

## Cómo reconstruir `data/raw/`

1. Descargar el ZIP mensual desde el enlace de la fuente, seleccionando los campos
   descritos en el diccionario de datos del `README.md` principal.
2. Descomprimir el CSV dentro de `data/raw/`.
3. El archivo queda excluido del control de versiones por `.gitignore`.

## Cómo se generaron las muestras

Recorrido en una sola pasada sobre el CSV completo, parseando el formato CSV con campos
entrecomillados (necesario porque `OriginCityName` y `DestCityName` contienen comas
internas, p. ej. `"Boise, ID"`):

```bash
unzip -p Archivio.zip "On_Time_...2026_4.csv" \
  | awk -v ida="data/samples/idaho_2026_04.csv" \
        -v smp="data/samples/muestra_nacional_2026_04_10k.csv" '
      BEGIN { FPAT = "([^,]*)|(\"[^\"]*\")" }
      NR == 1 { print > ida; print > smp; next }
      {
        o = $17; d = $26; gsub(/"/, "", o); gsub(/"/, "", d)
        if (o == "ID" || d == "ID") print > ida
        if (NR <= 10001)            print > smp
      }'
```

`$17` = `OriginState`, `$26` = `DestState`.

## Advertencias de uso

1. **Horas locales.** Todos los campos `hhmm` están en hora local del aeropuerto. Para
   comparar eventos simultáneos en la red hay que convertir a UTC.
2. **Nulos con semántica.** `ArrDelay` nulo en un vuelo con `Cancelled = 1` significa que
   el vuelo no llegó, no que falte el dato. No imputar cero.
3. **Causas de demora condicionadas.** `CarrierDelay`, `WeatherDelay`, `NASDelay`,
   `SecurityDelay` y `LateAircraftDelay` solo se pueblan cuando `ArrDel15 = 1`.
4. **Un solo mes.** Con `2026-4` únicamente no es posible analizar estacionalidad ni
   tendencia interanual. Para ello hay que descargar meses adicionales.
