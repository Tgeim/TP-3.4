/*
Nombre: dbo.SP_ListarDepartamentos
Descripción: Retorna todos los departamentos registrados.
Propósito: Alimentar formularios de inserción o edición.
*/

CREATE PROCEDURE dbo.SP_ListarDepartamentos
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT id, nombre
        FROM dbo.Departamento;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50030; -- Error al listar departamentos
    END CATCH
END;
