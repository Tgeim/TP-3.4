
/*
Nombre: dbo.SP_ListarPlanillaMensualGlobal
Descripción: Devuelve la planilla mensual completa de todos los empleados para un mes específico.
Propósito: Permite visualizar pagos globales por mes agrupados por empleado.
*/

CREATE PROCEDURE dbo.SP_ListarPlanillaMensualGlobal
    @inMes VARCHAR(7), -- formato 'YYYY-MM'
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            PM.id,
            PM.idEmpleado,
            E.nombreCompleto,
            D.nombre AS departamento,
            P.nombre AS puesto,
            PM.mes,
            PM.montoTotal,
            PM.fechaCalculo
        FROM dbo.PlanillaMensual PM
        INNER JOIN dbo.Empleado E ON PM.idEmpleado = E.id
        INNER JOIN dbo.Puesto P ON E.idPuesto = P.id
        INNER JOIN dbo.Departamento D ON E.idDepartamento = D.id
        WHERE PM.mes = @inMes
        ORDER BY E.nombreCompleto;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50027; -- Error al listar planilla mensual global
    END CATCH
END;
