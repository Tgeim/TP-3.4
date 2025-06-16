/*
Nombre: dbo.SP_ListarTipoDocumento
Descripción: Retorna todos los tipos de documento registrados.
Propósito: Alimentar formularios de inserción o edición de empleados.
*/

CREATE PROCEDURE dbo.SP_ListarTipoDocumento
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT id, nombre
        FROM dbo.TipoDocumento;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50031; -- Error al listar tipos de documento
    END CATCH
END;
