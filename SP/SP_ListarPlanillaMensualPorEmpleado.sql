
/*
Nombre: dbo.SP_ListarPlanillaMensualPorEmpleado
Descripción: Devuelve las planillas mensuales calculadas para un empleado específico.
Propósito: Permitir visualizar el resumen de planilla mensual del empleado.
*/

CREATE PROCEDURE dbo.SP_ListarPlanillaMensualPorEmpleado
    @inIdEmpleado INT,
    @inDesde DATE,
    @inHasta DATE,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validar existencia del empleado activo
        IF NOT EXISTS (
            SELECT 1 FROM dbo.Empleado WHERE id = @inIdEmpleado AND activo = 1
        )
        BEGIN
            SET @outResultCode = 50004;
            RETURN;
        END

        -- Listar planillas mensuales en rango
        SELECT
            id,
            mes,
            horasOrdinarias,
            horasExtra,
            montoBruto,
            montoDeducciones,
            montoNeto,
            fechaCalculo
        FROM dbo.PlanillaMensual
        WHERE idEmpleado = @inIdEmpleado
          AND mes BETWEEN @inDesde AND @inHasta
        ORDER BY mes;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50025; -- Error al consultar planilla mensual
    END CATCH
END;
