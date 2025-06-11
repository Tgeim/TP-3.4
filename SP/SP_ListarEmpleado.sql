
/*
Nombre: dbo.SP_ListarEmpleados
Descripción: Retorna todos los empleados activos con su información básica.
Propósito: Permite al administrador visualizar el listado general de empleados.
*/

CREATE PROCEDURE dbo.SP_ListarEmpleados
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT 
            E.id,
            E.nombreCompleto,
            E.valorDocumento,
            P.nombre AS puesto,
            D.nombre AS departamento
        FROM dbo.Empleado E
        INNER JOIN dbo.Puesto P ON E.idPuesto = P.id
        INNER JOIN dbo.Departamento D ON E.idDepartamento = D.id
        WHERE E.activo = 1;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50003; -- Código de error de consulta de empleados
    END CATCH
END;
