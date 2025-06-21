CREATE PROCEDURE dbo.SP_ConsultarDeduccionesSemanalesPorEmpleado
    @inIdEmpleado INT,
    @inFechaSemana DATE,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @outResultCode = 0;

        DECLARE @montoBrutoSemana DECIMAL(10, 2);

        SELECT @montoBrutoSemana = montoBruto
        FROM dbo.PlanillaSemanal
        WHERE idEmpleado = @inIdEmpleado
          AND semanaInicio = @inFechaSemana;

        IF @montoBrutoSemana IS NULL
        BEGIN
            SET @outResultCode = 100; -- No hay planilla para esa semana
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
                WHEN TD.porcentual = 1 THEN ROUND(TD.valor * @montoBrutoSemana, 2)
                ELSE TD.valor
            END AS montoCalculado
        FROM dbo.DeduccionEmpleado DE
        INNER JOIN dbo.TipoDeduccion TD ON DE.idTipoDeduccion = TD.id
        WHERE DE.idEmpleado = @inIdEmpleado
          AND DE.fechaAsociacion <= @inFechaSemana
          AND (DE.fechaDesasociacion IS NULL OR DE.fechaDesasociacion > @inFechaSemana)
        ORDER BY TD.obligatorio DESC, TD.nombre;

    END TRY
    BEGIN CATCH
        SET @outResultCode = ERROR_NUMBER();
    END CATCH
END;
