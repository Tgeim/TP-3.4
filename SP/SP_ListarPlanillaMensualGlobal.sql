CREATE PROCEDURE dbo.SP_ListarPlanillaMensualGlobal
    @inMes VARCHAR(7), -- formato 'YYYY-MM'
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            E.id AS idEmpleado,
            E.nombreCompleto,
            D.nombre AS nombreDepartamento,
            P.nombre AS nombrePuesto,
            SUM(PS.horasOrdinarias) AS horasOrdinarias,
            SUM(PS.horasExtra) AS horasExtra,
            SUM(PS.montoBruto) AS montoBruto,
            SUM(PS.montoDeducciones) AS montoDeducciones,
            SUM(PS.montoNeto) AS montoNeto
        FROM dbo.PlanillaSemanal PS
        INNER JOIN dbo.Empleado E ON PS.idEmpleado = E.id
        INNER JOIN dbo.Departamento D ON E.idDepartamento = D.id
        INNER JOIN dbo.Puesto P ON E.idPuesto = P.id
        WHERE E.activo = 1
          AND FORMAT(PS.semanaInicio, 'yyyy-MM') = @inMes
        GROUP BY E.id, E.nombreCompleto, D.nombre, P.nombre
        ORDER BY E.nombreCompleto;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50102; -- Error resumen mensual global
    END CATCH
END;