/*
Nombre: dbo.SP_ListarPuestos
Descripción: Retorna todos los puestos registrados.
Propósito: Alimentar formularios de inserción o edición.
*/

CREATE PROCEDURE dbo.SP_ListarPuestos
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT id, nombre
        FROM dbo.Puesto;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50031; -- Error al listar puestos
    END CATCH
END;
