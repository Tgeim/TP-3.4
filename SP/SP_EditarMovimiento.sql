/*
Nombre: dbo.SP_EditarMovimiento
Descripción: Edita los datos de un movimiento existente.
Propósito: Permite modificar registros de movimientos manuales en planilla.
*/

CREATE PROCEDURE dbo.SP_EditarMovimiento
    @inId INT,
    @inIdEmpleado INT,
    @inIdTipoMovimiento INT,
    @inSemana DATE,
    @inCantidadHoras FLOAT,
    @inMonto FLOAT,
    @inCreadoPorSistema BIT,
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

        -- Actualizar
        UPDATE dbo.Movimiento
        SET idEmpleado = @inIdEmpleado,
            idTipoMovimiento = @inIdTipoMovimiento,
            semana = @inSemana,
            cantidadHoras = @inCantidadHoras,
            monto = @inMonto,
            creadoPorSistema = @inCreadoPorSistema
        WHERE id = @inId;

        -- Capturar estado posterior
        DECLARE @jsonDespues NVARCHAR(MAX);
        SELECT @jsonDespues = (
            SELECT id, idEmpleado, idTipoMovimiento, semana, cantidadHoras, monto, creadoPorSistema, fechaCreacion
            FROM dbo.Movimiento
            WHERE id = @inId
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        -- Bitácora
        EXEC dbo.SP_RegistrarBitacoraEvento
            @inIdUsuario = @inIdPostByUser,
            @inIdTipoEvento = 402, -- Edición de movimiento
            @inDescripcion = 'Edición de movimiento de planilla',
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
        SET @outResultCode = 50015; -- Error general al editar movimiento
    END CATCH
END;
