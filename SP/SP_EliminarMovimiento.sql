/*
Nombre: dbo.SP_EliminarMovimiento
Descripción: Elimina físicamente un movimiento específico.
Propósito: Remover registros de movimientos en planilla que ya no sean válidos.
*/

CREATE PROCEDURE dbo.SP_EliminarMovimiento
    @inId INT,
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(50),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validar existencia
        IF NOT EXISTS (
            SELECT 1 FROM dbo.Movimiento WHERE id = @inId
        )
        BEGIN
            SET @outResultCode = 50014; -- Movimiento no encontrado
            ROLLBACK;
            RETURN;
        END

        -- Capturar estado anterior
        DECLARE @jsonAntes NVARCHAR(MAX);
        SELECT @jsonAntes = (
            SELECT id, idEmpleado, idTipoMovimiento, semana, cantidadHoras, monto, creadoPorSistema, fechaCreacion
            FROM dbo.Movimiento
            WHERE id = @inId
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        -- Eliminar
        DELETE FROM dbo.Movimiento WHERE id = @inId;

        -- Bitácora
        EXEC dbo.SP_RegistrarBitacoraEvento
            @inIdUsuario = @inIdPostByUser,
            @inIdTipoEvento = 403, -- Eliminación de movimiento
            @inDescripcion = 'Eliminación física de movimiento de planilla',
            @inIdPostByUser = @inIdPostByUser,
            @inPostInIP = @inPostInIP,
            @inJsonAntes = @jsonAntes,
            @inJsonDespues = NULL,
            @outResultCode = @outResultCode OUTPUT;

        COMMIT;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @outResultCode = 50016; -- Error general al eliminar movimiento
    END CATCH
END;
