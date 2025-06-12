
/*
Nombre: dbo.SP_ListarPlanillaSemanalPorEmpleado
Descripción: Devuelve las planillas semanales calculadas para un empleado específico.
Propósito: Permitir a la aplicación visualizar el resumen de planilla semana a semana.
*/

CREATE PROCEDURE dbo.SP_ListarPlanillaSemanalPorEmpleado
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

        -- Listar planillas semanales en rango
        SELECT
            id,
            semanaInicio,
            semanaFin,
            horasOrdinarias,
            horasExtra,
            montoBruto,
            montoDeducciones,
            montoNeto,
            fechaCalculo
        FROM dbo.PlanillaSemanal
        WHERE idEmpleado = @inIdEmpleado
          AND semanaInicio >= @inDesde
          AND semanaFin <= @inHasta
        ORDER BY semanaInicio;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50024; -- Error al consultar planilla semanal
    END CATCH
END;
