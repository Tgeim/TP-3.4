SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.SP_CerrarSemanaPlanilla
    @inFechaJueves DATE,
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(50),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @outResultCode = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Calcular rango semana: viernes anterior a @inFechaJueves hasta @inFechaJueves
        DECLARE @fechaInicioSemana DATE = DATEADD(DAY, -6, @inFechaJueves);

        -- Tabla temporal para acumulados por empleado
        IF OBJECT_ID('tempdb..#PlanillaSemanalTmp') IS NOT NULL DROP TABLE #PlanillaSemanalTmp;
        CREATE TABLE #PlanillaSemanalTmp (
            idEmpleado INT PRIMARY KEY,
            horasOrdinarias FLOAT,
            horasExtra FLOAT,
            montoBruto FLOAT,
            montoDeducciones FLOAT,
            montoNeto FLOAT
        );

        -- Insertar empleados activos con jornada asignada para esa semana
        INSERT INTO #PlanillaSemanalTmp (idEmpleado, horasOrdinarias, horasExtra, montoBruto, montoDeducciones, montoNeto)
        SELECT
            E.id AS idEmpleado,
            0.0 AS horasOrdinarias,
            0.0 AS horasExtra,
            0.0 AS montoBruto,
            0.0 AS montoDeducciones,
            0.0 AS montoNeto
        FROM dbo.Empleado E
        INNER JOIN dbo.JornadaAsignada JA ON JA.idEmpleado = E.id AND JA.fechaInicioSemana = @fechaInicioSemana
        WHERE E.activo = 1;

        -- Calcular horas por empleado (simplificación: sumamos minutos de marcas entrada/salida)
        UPDATE ps
        SET
            horasOrdinarias = ISNULL(marcas.totalHoras, 0)
        FROM #PlanillaSemanalTmp ps
        LEFT JOIN (
            SELECT 
                idEmpleado,
                SUM(DATEDIFF(MINUTE, 
                    MIN(CASE WHEN tipoMarca = 'entrada' THEN fechaHora END),
                    MAX(CASE WHEN tipoMarca = 'salida' THEN fechaHora END)
                ) / 60.0) AS totalHoras
            FROM dbo.Marca
            WHERE fechaHora >= @fechaInicioSemana AND fechaHora <= DATEADD(DAY,1,@inFechaJueves)
            GROUP BY idEmpleado
        ) marcas ON marcas.idEmpleado = ps.idEmpleado;

        -- Calcular montoBruto y horasExtra (todo como horas ordinarias, horasExtra=0)
        UPDATE ps
        SET
            montoBruto = ps.horasOrdinarias * ISNULL(P.salarioPorHora, 0),
            horasExtra = 0
        FROM #PlanillaSemanalTmp ps
        INNER JOIN dbo.Empleado E ON E.id = ps.idEmpleado
        INNER JOIN dbo.Puesto P ON P.id = E.idPuesto;

        -- Calcular montoDeducciones por empleado
        UPDATE ps
        SET montoDeducciones = ISNULL(deducciones.totalDeducciones, 0)
        FROM #PlanillaSemanalTmp ps
        LEFT JOIN (
            SELECT 
                DE.idEmpleado,
                SUM(
                    CASE
                        WHEN TD.porcentual = 1 THEN TD.valor * ps.montoBruto / 100.0
                        ELSE TD.valor
                    END
                ) AS totalDeducciones
            FROM dbo.DeduccionEmpleado DE
            INNER JOIN dbo.TipoDeduccion TD ON TD.id = DE.idTipoDeduccion
            CROSS JOIN #PlanillaSemanalTmp ps
            WHERE DE.fechaAsociacion <= @inFechaJueves
              AND (DE.fechaDesasociacion IS NULL OR DE.fechaDesasociacion > @inFechaJueves)
              AND DE.idEmpleado = ps.idEmpleado
            GROUP BY DE.idEmpleado
        ) deducciones ON deducciones.idEmpleado = ps.idEmpleado;

        -- Calcular montoNeto
        UPDATE #PlanillaSemanalTmp
        SET montoNeto = montoBruto - montoDeducciones;

        -- Insertar o actualizar PlanillaSemanal
        MERGE dbo.PlanillaSemanal AS target
        USING #PlanillaSemanalTmp AS source
        ON target.idEmpleado = source.idEmpleado AND target.semanaInicio = @fechaInicioSemana
        WHEN MATCHED THEN 
            UPDATE SET 
                semanaFin = @inFechaJueves,
                horasOrdinarias = source.horasOrdinarias,
                horasExtra = source.horasExtra,
                montoBruto = source.montoBruto,
                montoDeducciones = source.montoDeducciones,
                montoNeto = source.montoNeto,
                fechaCalculo = GETDATE()
        WHEN NOT MATCHED THEN
            INSERT (idEmpleado, semanaInicio, semanaFin, horasOrdinarias, horasExtra, montoBruto, montoDeducciones, montoNeto, fechaCalculo)
            VALUES (source.idEmpleado, @fechaInicioSemana, @inFechaJueves, source.horasOrdinarias, source.horasExtra, source.montoBruto, source.montoDeducciones, source.montoNeto, GETDATE());

        -- Registrar acción en BitacoraEvento
        INSERT INTO dbo.BitacoraEvento
            (idTipoEvento, descripcion, idPostByUser, postInIP, postTime, jsonAntes, jsonDespues)
        VALUES
            (500, -- Código genérico para "Cierre de semana planilla"
             CONCAT('Cierre de planilla semanal para semana ', CONVERT(VARCHAR, @fechaInicioSemana, 23), ' a ', CONVERT(VARCHAR, @inFechaJueves, 23)),
             @inIdPostByUser,
             @inPostInIP,
             GETDATE(),
             NULL,
             NULL);

        COMMIT TRANSACTION;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @outResultCode = ISNULL(ERROR_NUMBER(), 1);

        INSERT INTO dbo.DBError
            (errorNumber, errorSeverity, errorState, errorProcedure, errorLine, errorMessage, logTime)
        VALUES
            (ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(), ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE(), GETDATE());
    END CATCH
END;
GO
