CREATE PROCEDURE dbo.SP_ConsultarDeduccionesMensualesPorEmpleado
    @inIdEmpleado INT,
    @inMes INT,
    @inAnio INT,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @outResultCode = 0;

        DECLARE @montoBrutoMes DECIMAL(10,2) = 0;

        SELECT @montoBrutoMes = SUM(montoBruto)
        FROM dbo.PlanillaSemanal
        WHERE idEmpleado = @inIdEmpleado
          AND MONTH(semanaInicio) = @inMes
          AND YEAR(semanaInicio) = @inAnio;

        IF @montoBrutoMes IS NULL
        BEGIN
            SET @outResultCode = 100; -- No hay planilla para ese mes
            RETURN;
        END

        SELECT
            DE.idEmpleado,
            DE.idTipoDeduccion,
            DE.fechaAsociacion,
            DE.fechaDesasociacion,
            TD.nombre AS nombreDeduccion,
            TD.porcentual,
            TD.valor,
            TD.obligatorio,
            CASE
                WHEN TD.porcentual = 1 THEN ROUND(TD.valor * @montoBrutoMes, 2)
                ELSE TD.valor
            END AS montoCalculado
        FROM dbo.DeduccionEmpleado DE
        INNER JOIN dbo.TipoDeduccion TD ON DE.idTipoDeduccion = TD.id
        WHERE DE.idEmpleado = @inIdEmpleado
          AND DE.fechaAsociacion <= DATEFROMPARTS(@inAnio, @inMes, 1)
          AND (DE.fechaDesasociacion IS NULL OR DE.fechaDesasociacion > EOMONTH(DATEFROMPARTS(@inAnio, @inMes, 1)))
        ORDER BY TD.obligatorio DESC, TD.nombre;

    END TRY
    BEGIN CATCH
        SET @outResultCode = ERROR_NUMBER();
    END CATCH
END;
