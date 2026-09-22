-- Data Mart de Puntualidad Operacional Aerea (BTS / US DOT)
-- DDL de la tabla de hechos principal y sus indices.
-- Extraido de la seccion 4.8 del README.md del proyecto.

-- ============================================================
-- TABLA DE HECHOS PRINCIPAL
-- Grano: un (1) segmento de vuelo programado
-- ============================================================
CREATE TABLE FACT_VUELO (
    SK_Vuelo                    BIGINT       NOT NULL,
    -- Claves foraneas (14) -------------------------------------
    SK_Fecha                    INT          NOT NULL,
    SK_Aerolinea                INT          NOT NULL,
    SK_Aeropuerto_Origen        INT          NOT NULL,
    SK_Aeropuerto_Destino       INT          NOT NULL,
    SK_Aeronave                 INT          NOT NULL,  -- -1 si cancelado
    SK_Ruta                     INT          NOT NULL,
    SK_Bloque_Salida            INT          NOT NULL,
    SK_Bloque_Llegada           INT          NOT NULL,
    SK_Estado_Vuelo             INT          NOT NULL,
    SK_Causa_Demora             INT          NOT NULL,  -- -1 si no demorado
    SK_Causa_Cancelacion        INT          NOT NULL,  -- -1 si no cancelado
    SK_Rango_Demora_Salida      INT          NOT NULL,
    SK_Rango_Demora_Llegada     INT          NOT NULL,
    -- Dimensiones degeneradas ----------------------------------
    NumeroVuelo                 INT          NOT NULL,
    FlightIdentifier            VARCHAR(12)  NOT NULL,
    -- Metricas de conteo ---------------------------------------
    CantidadVuelos              SMALLINT     NOT NULL DEFAULT 1,
    VuelosOperados              SMALLINT     NOT NULL,
    VuelosCancelados            SMALLINT     NOT NULL,
    VuelosDesviados             SMALLINT     NOT NULL,
    VuelosPuntuales             SMALLINT     NOT NULL,
    -- Metricas de demora ---------------------------------------
    DemoraSalidaMin             INT          NULL,
    DemoraSalidaMinPos          INT          NULL,
    DemoraLlegadaMin            INT          NULL,
    DemoraLlegadaMinPos         INT          NULL,
    IndicadorDemoraSalida15     SMALLINT     NULL,
    IndicadorDemoraLlegada15    SMALLINT     NULL,
    -- Metricas de tiempo operativo -----------------------------
    TiempoRodajeSalidaMin       INT          NULL,
    TiempoRodajeLlegadaMin      INT          NULL,
    TiempoVueloMin              INT          NULL,
    TiempoTotalProgramadoMin    INT          NULL,
    TiempoTotalRealMin          INT          NULL,
    DistanciaMillas             INT          NOT NULL,
    -- Descomposicion causal (poblada solo si ArrDel15 = 1) -----
    DemoraAerolineaMin          INT          NULL,
    DemoraClimaMin              INT          NULL,
    DemoraNASMin                INT          NULL,
    DemoraSeguridadMin          INT          NULL,
    DemoraAeronaveTardiaMin     INT          NULL,
    -- Retorno a puerta y desvio --------------------------------
    TiempoFueraPuertaTotalMin   INT          NULL,
    TiempoFueraPuertaMaxMin     INT          NULL,  -- NO aditiva: usar MAX
    AterrizajesDesvio           SMALLINT     NULL,
    DistanciaDesvioMillas       INT          NULL,
    -- Metricas derivadas ---------------------------------------
    MinutosRecuperadosEnRuta    INT          NULL,
    VarianzaTiempoBloqueMin     INT          NULL,
    HolguraItinerarioMin        INT          NULL,
    DemoraTotalCausalMin        INT          NULL,
    -- Auditoria de linaje --------------------------------------
    FechaCargaETL               TIMESTAMP    NOT NULL,
    ArchivoOrigenETL            VARCHAR(120) NOT NULL,

    CONSTRAINT PK_FACT_VUELO PRIMARY KEY (SK_Vuelo),
    CONSTRAINT FK_FV_Fecha       FOREIGN KEY (SK_Fecha)
        REFERENCES DIM_FECHA (SK_Fecha),
    CONSTRAINT FK_FV_Aerolinea   FOREIGN KEY (SK_Aerolinea)
        REFERENCES DIM_AEROLINEA (SK_Aerolinea),
    CONSTRAINT FK_FV_AptoOrigen  FOREIGN KEY (SK_Aeropuerto_Origen)
        REFERENCES DIM_AEROPUERTO (SK_Aeropuerto),
    CONSTRAINT FK_FV_AptoDestino FOREIGN KEY (SK_Aeropuerto_Destino)
        REFERENCES DIM_AEROPUERTO (SK_Aeropuerto)
    -- (... resto de claves foraneas analogas)
)
PARTITION BY RANGE (SK_Fecha);

-- Indices recomendados sobre la tabla de hechos
CREATE INDEX IX_FV_Fecha_Aerolinea
    ON FACT_VUELO (SK_Fecha, SK_Aerolinea);
CREATE INDEX IX_FV_AptoOrigen_Fecha
    ON FACT_VUELO (SK_Aeropuerto_Origen, SK_Fecha);
CREATE INDEX IX_FV_Ruta_Fecha
    ON FACT_VUELO (SK_Ruta, SK_Fecha);
CREATE INDEX IX_FV_Aeronave_Fecha
    ON FACT_VUELO (SK_Aeronave, SK_Fecha); -- soporta analisis de rotaciones
