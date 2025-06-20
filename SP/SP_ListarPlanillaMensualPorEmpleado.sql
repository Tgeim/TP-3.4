CREATE PROCEDURE dbo.SP_ListarPlanillaMensualPorEmpleado
    @inIdEmpleado INT,
    @inMes VARCHAR(7), -- formato 'YYYY-MM'
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS (
            SELECT 1 FROM dbo.Empleado WHERE id = @inIdEmpleado AND activo = 1
        )
        BEGIN
            SET @outResultCode = 50004; -- Empleado inactivo o inexistente
            RETURN;
        END

        SELECT
            PS.idEmpleado,
            E.nombreCompleto,
            SUM(PS.horasOrdinarias) AS horasOrdinarias,
            SUM(PS.horasExtra) AS horasExtra,
            SUM(PS.montoBruto) AS montoBruto,
            SUM(PS.montoDeducciones) AS montoDeducciones,
            SUM(PS.montoNeto) AS montoNeto
        FROM dbo.PlanillaSemanal PS
        INNER JOIN dbo.Empleado E ON PS.idEmpleado = E.id
        WHERE PS.idEmpleado = @inIdEmpleado
          AND FORMAT(PS.semanaInicio, 'yyyy-MM') = @inMes
        GROUP BY PS.idEmpleado, E.nombreCompleto;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50103; -- Error resumen mensual por empleado
    END CATCH
END;