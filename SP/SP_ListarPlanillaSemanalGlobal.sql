
/*
Nombre: dbo.SP_ListarPlanillaSemanalGlobal
Descripción: Devuelve la planilla semanal completa de todos los empleados en una semana dada.
Propósito: Permite al administrador ver cuánto se pagó globalmente y a quién.
*/

CREATE PROCEDURE dbo.SP_ListarPlanillaSemanalGlobal
    @inSemanaInicio DATE,
    @inSemanaFin DATE,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            PS.id,
            PS.idEmpleado,
            E.nombreCompleto,
            D.nombre AS departamento,
            P.nombre AS puesto,
            PS.semanaInicio,
            PS.semanaFin,
            PS.horasOrdinarias,
            PS.horasExtra,
            PS.montoBruto,
            PS.montoDeducciones,
            PS.montoNeto,
            PS.fechaCalculo
        FROM dbo.PlanillaSemanal PS
        INNER JOIN dbo.Empleado E ON PS.idEmpleado = E.id
        INNER JOIN dbo.Puesto P ON E.idPuesto = P.id
        INNER JOIN dbo.Departamento D ON E.idDepartamento = D.id
        WHERE PS.semanaInicio = @inSemanaInicio AND PS.semanaFin = @inSemanaFin
        ORDER BY E.nombreCompleto;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50026; -- Error al listar planilla semanal global
    END CATCH
END;
