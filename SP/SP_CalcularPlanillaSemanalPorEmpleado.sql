CREATE PROCEDURE dbo.SP_CalcularPlanillaSemanalEmpleado
    @inFechaCorte DATE,
    @inIdUsuario INT,
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(100),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idTipoEvento INT = 10; -- Tipo de evento: cálculo planilla semanal
    DECLARE @inicioSemana DATE, @finSemana DATE;
    DECLARE @descripcionEvento VARCHAR(200) = 'Cálculo de planilla semanal';
    DECLARE @jsonAntes NVARCHAR(MAX) = NULL;
    DECLARE @jsonDespues NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Definir rango de semana
        SET @finSemana = @inFechaCorte;
        SET @inicioSemana = DATEADD(DAY, -6, @finSemana);

        -- Registro previo en bitácora
        SELECT @jsonAntes = (
            SELECT COUNT(*) AS cantidadAntes
            FROM dbo.PlanillaSemanal
            WHERE semanaInicio = @inicioSemana AND semanaFin = @finSemana
            FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER
        );

        ---------------------------------------------
        -- CTEs para cálculos intermedios
        ---------------------------------------------

        -- Total bruto por empleado en semana
        ;WITH MontoBrutoEmpleado AS (
            SELECT 
                m.idEmpleado,
                SUM(m.monto) AS montoBruto
            FROM dbo.Movimiento m
            WHERE m.semana BETWEEN @inicioSemana AND @finSemana
              AND m.idTipoMovimiento IN (1, 2, 3)
            GROUP BY m.idEmpleado
        ),
        -- Cuántas semanas tiene el mes actual (4 o 5)
        SemanasEnMes AS (
            SELECT COUNT(DISTINCT DATEPART(WEEK, semanaFin)) AS totalSemanas
            FROM dbo.PlanillaSemanal
            WHERE DATEPART(MONTH, semanaFin) = DATEPART(MONTH, @finSemana)
        ),
        -- Cálculo total de deducciones por empleado
        DeduccionesCalculadas AS (
            SELECT 
                de.idEmpleado,
                SUM(
                    CASE 
                        WHEN td.porcentual = 1 THEN (td.valor / 100.0) * ISNULL(mbe.montoBruto, 0)
                        WHEN td.porcentual = 0 THEN td.valor / IIF(s.totalSemanas = 5, 5.0, 4.0)
                        ELSE 0
                    END
                ) AS totalDeducciones
            FROM dbo.DeduccionEmpleado de
            INNER JOIN dbo.TipoDeduccion td ON td.id = de.idTipoDeduccion
            LEFT JOIN MontoBrutoEmpleado mbe ON mbe.idEmpleado = de.idEmpleado
            CROSS JOIN SemanasEnMes s
            WHERE de.fechaAsociacion <= @finSemana
              AND (de.fechaDesasociacion IS NULL OR de.fechaDesasociacion >= @inicioSemana)
            GROUP BY de.idEmpleado
        )

        ---------------------------------------------
        -- Inserción de planilla semanal
        ---------------------------------------------
        INSERT INTO dbo.PlanillaSemanal (
            idEmpleado,
            semanaInicio,
            semanaFin,
            horasOrdinarias,
            horasExtra,
            montoBruto,
            montoDeducciones,
            montoNeto,
            fechaCalculo
        )
        SELECT
            e.id AS idEmpleado,
            @inicioSemana AS semanaInicio,
            @finSemana AS semanaFin,
            ISNULL(SUM(CASE WHEN tm.id = 1 THEN m.cantidadHoras END), 0) AS horasOrdinarias,
            ISNULL(SUM(CASE WHEN tm.id IN (2, 3) THEN m.cantidadHoras END), 0) AS horasExtra,
            ISNULL(SUM(m.monto), 0) AS montoBruto,
            ISNULL(dc.totalDeducciones, 0) AS montoDeducciones,
            ISNULL(SUM(m.monto), 0) - ISNULL(dc.totalDeducciones, 0) AS montoNeto,
            GETDATE() AS fechaCalculo
        FROM dbo.Empleado e
        LEFT JOIN dbo.Movimiento m ON m.idEmpleado = e.id
            AND m.semana BETWEEN @inicioSemana AND @finSemana
        LEFT JOIN dbo.TipoMovimiento tm ON tm.id = m.idTipoMovimiento
        LEFT JOIN DeduccionesCalculadas dc ON dc.idEmpleado = e.id
        WHERE e.activo = 1
        GROUP BY e.id, dc.totalDeducciones;

        ---------------------------------------------
        -- Registro posterior en bitácora
        ---------------------------------------------
        SELECT @jsonDespues = (
            SELECT COUNT(*) AS cantidadDespues
            FROM dbo.PlanillaSemanal
            WHERE semanaInicio = @inicioSemana AND semanaFin = @finSemana
            FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.SP_RegistrarBitacoraEvento
            @inIdUsuario = @inIdUsuario,
            @inIdTipoEvento = @idTipoEvento,
            @inDescripcion = @descripcionEvento,
            @inIdPostByUser = @inIdPostByUser,
            @inPostInIP = @inPostInIP,
            @inJsonAntes = @jsonAntes,
            @inJsonDespues = @jsonDespues,
            @outResultCode = @outResultCode OUTPUT;

        COMMIT;
        SET @outResultCode = 0; -- Éxito

    END TRY
    BEGIN CATCH
        ROLLBACK;
        SET @outResultCode = 50008; -- Código de error definido
    END CATCH
END;
