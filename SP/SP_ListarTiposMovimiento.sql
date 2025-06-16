/*
Nombre: dbo.SP_ListarTiposMovimiento
Descripción: Lista todos los tipos de movimiento registrados.
Propósito: Llenar catálogos o combos para selección en formularios.
*/

CREATE PROCEDURE dbo.SP_ListarTiposMovimiento
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            id,
            nombre
        FROM dbo.TipoMovimiento;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50022; -- Error al listar tipos de movimiento
    END CATCH
END;
