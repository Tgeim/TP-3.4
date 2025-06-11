-- Tabla Error: catálogo de errores del sistema
CREATE TABLE dbo.Error (
    codigo INT PRIMARY KEY,
    descripcion VARCHAR(255) NOT NULL
);
GO

-- Procedimiento: SP_ObtenerError
/*
Nombre: dbo.SP_ObtenerError
Descripción: Devuelve la descripción de un código de error del sistema.
Propósito: Permite a la aplicación mostrar mensajes comprensibles al usuario.
*/
CREATE PROCEDURE dbo.SP_ObtenerError
    @inCodigo INT,
    @outDescripcion VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT @outDescripcion = descripcion
        FROM dbo.Error
        WHERE codigo = @inCodigo;

        IF @outDescripcion IS NULL
            SET @outDescripcion = 'Error desconocido';
    END TRY
    BEGIN CATCH
        SET @outDescripcion = 'Error interno al consultar catálogo de errores';
    END CATCH
END;