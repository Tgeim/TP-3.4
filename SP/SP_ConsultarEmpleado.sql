
/*
Nombre: dbo.SP_ConsultarEmpleadoPorId
Descripción: Consulta los datos detallados de un empleado activo por su ID.
Propósito: Permite cargar los datos de un empleado específico, por ejemplo, antes de editar.
*/

CREATE PROCEDURE dbo.SP_ConsultarEmpleadoPorId
    @inId INT,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Empleado WHERE id = @inId AND activo = 1)
        BEGIN
            SET @outResultCode = 50004; -- Código de error: empleado no encontrado o inactivo
            RETURN;
        END

        SELECT 
            E.id,
            E.nombreCompleto,
            E.valorDocumento,
            E.fechaNacimiento,
            E.idTipoDocumento,
            E.idDepartamento,
            E.idPuesto
        FROM dbo.Empleado E
        WHERE E.id = @inId AND E.activo = 1;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50005; -- Código de error inesperado
    END CATCH
END;
