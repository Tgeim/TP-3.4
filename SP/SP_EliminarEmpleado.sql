/*
Nombre: dbo.SP_EliminarEmpleado
Descripción: Realiza una baja lógica del empleado marcándolo como inactivo.
Propósito: Desactivar empleados sin eliminar físicamente su información.
*/

CREATE PROCEDURE dbo.SP_EliminarEmpleado
    @inId INT,
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(50),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validar existencia activa
        IF NOT EXISTS (
            SELECT 1 FROM dbo.Empleado
            WHERE id = @inId AND activo = 1
        )
        BEGIN
            SET @outResultCode = 50004; -- Empleado no encontrado
            ROLLBACK;
            RETURN;
        END

        -- Capturar estado anterior
        DECLARE @jsonAntes NVARCHAR(MAX);
        SELECT @jsonAntes = (
            SELECT
                id,
                nombreCompleto,
                valorDocumento,
                fechaNacimiento,
                activo,
                idTipoDocumento,
                idDepartamento,
                idPuesto
            FROM dbo.Empleado
            WHERE id = @inId
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        -- Baja lógica
        UPDATE dbo.Empleado
        SET activo = 0
        WHERE id = @inId;

        -- Capturar estado posterior
        DECLARE @jsonDespues NVARCHAR(MAX);
        SELECT @jsonDespues = (
            SELECT
                id,
                nombreCompleto,
                valorDocumento,
                fechaNacimiento,
                activo,
                idTipoDocumento,
                idDepartamento,
                idPuesto
            FROM dbo.Empleado
            WHERE id = @inId
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        -- Bitácora
        INSERT INTO dbo.BitacoraEvento (
            idUsuario, idTipoEvento, descripcion,
            idPostByUser, postInIP, postTime,
            jsonAntes, jsonDespues
        )
        VALUES (
            @inIdPostByUser, 103, -- 103 = eliminación lógica
            'Borrado lógico de empleado',
            @inIdPostByUser, @inPostInIP, GETDATE(),
            @jsonAntes, @jsonDespues
        );

        COMMIT;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @outResultCode = 50007; -- Error general al eliminar
    END CATCH
END;
