/*
Nombre: dbo.SP_EliminarDeduccionEmpleado
Descripción: Desasocia una deducción activa de un empleado si no es obligatoria.
Propósito: Permite remover deducciones voluntarias.
*/

CREATE PROCEDURE dbo.SP_EliminarDeduccionEmpleado
    @inIdEmpleado INT,
    @inIdTipoDeduccion INT,
    @inFechaDesasociacion DATE,
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(50),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validar existencia de asociación activa
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.DeduccionEmpleado
            WHERE idEmpleado = @inIdEmpleado
              AND idTipoDeduccion = @inIdTipoDeduccion
              AND fechaDesasociacion IS NULL
        )
        BEGIN
            SET @outResultCode = 50019; -- No existe asociación activa
            ROLLBACK;
            RETURN;
        END

        -- Verificar si la deducción es obligatoria
        IF EXISTS (
            SELECT 1
            FROM dbo.TipoDeduccion
            WHERE id = @inIdTipoDeduccion AND obligatorio = 1
        )
        BEGIN
            SET @outResultCode = 50020; -- Deducción obligatoria no se puede desasociar
            ROLLBACK;
            RETURN;
        END

        -- Obtener jsonAntes
        DECLARE @jsonAntes NVARCHAR(MAX);
        SELECT @jsonAntes = (
            SELECT 
                id,
                idEmpleado,
                idTipoDeduccion,
                fechaAsociacion,
                fechaDesasociacion
            FROM dbo.DeduccionEmpleado
            WHERE idEmpleado = @inIdEmpleado
              AND idTipoDeduccion = @inIdTipoDeduccion
              AND fechaDesasociacion IS NULL
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        -- Desasociar la deducción
        UPDATE dbo.DeduccionEmpleado
        SET fechaDesasociacion = @inFechaDesasociacion
        WHERE idEmpleado = @inIdEmpleado
          AND idTipoDeduccion = @inIdTipoDeduccion
          AND fechaDesasociacion IS NULL;

        -- Obtener jsonDespues
        DECLARE @jsonDespues NVARCHAR(MAX);
        SELECT @jsonDespues = (
            SELECT 
                id,
                idEmpleado,
                idTipoDeduccion,
                fechaAsociacion,
                fechaDesasociacion
            FROM dbo.DeduccionEmpleado
            WHERE idEmpleado = @inIdEmpleado
              AND idTipoDeduccion = @inIdTipoDeduccion
              AND fechaDesasociacion = @inFechaDesasociacion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        -- Registrar evento en bitácora
        EXEC dbo.SP_RegistrarBitacoraEvento
            @inIdUsuario = @inIdPostByUser,
            @inIdTipoEvento = 502,
            @inDescripcion = 'Desasociación de deducción de empleado',
            @inIdPostByUser = @inIdPostByUser,
            @inPostInIP = @inPostInIP,
            @inJsonAntes = @jsonAntes,
            @inJsonDespues = @jsonDespues,
            @outResultCode = @outResultCode OUTPUT;

        COMMIT;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @outResultCode = 50021; -- Error general al desasociar deducción
    END CATCH
END;
