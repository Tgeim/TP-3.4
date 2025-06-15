/*
Nombre: dbo.SP_InsertarMovimiento
Descripción: Registra un movimiento de planilla específico para un empleado (manual o adicional).
Propósito: Permite agregar ajustes de horas o montos a la planilla semanal.
*/

CREATE PROCEDURE dbo.SP_InsertarMovimiento
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

        -- Validar existencia del empleado activo
        IF NOT EXISTS (
            SELECT 1 FROM dbo.Empleado
            WHERE id = @inIdEmpleado AND activo = 1
        )
        BEGIN
            SET @outResultCode = 50004; -- Empleado no encontrado
            ROLLBACK;
            RETURN;
        END

        -- Insertar movimiento
        INSERT INTO dbo.Movimiento (
            idEmpleado,
            idTipoMovimiento,
            semana,
            cantidadHoras,
            monto,
            creadoPorSistema,
            fechaCreacion
        )
        VALUES (
            @inIdEmpleado,
            @inIdTipoMovimiento,
            @inSemana,
            @inCantidadHoras,
            @inMonto,
            @inCreadoPorSistema,
            GETDATE()
        );

        -- Obtener ID y datos nuevos
        DECLARE @nuevoIdMovimiento INT = SCOPE_IDENTITY();
        DECLARE @jsonDespues NVARCHAR(MAX);
        SELECT @jsonDespues = (
            SELECT
                id,
                idEmpleado,
                idTipoMovimiento,
                semana,
                cantidadHoras,
                monto,
                creadoPorSistema,
                fechaCreacion
            FROM dbo.Movimiento
            WHERE id = @nuevoIdMovimiento
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        -- Registrar bitácora
        EXEC dbo.SP_RegistrarBitacoraEvento
            @inIdUsuario = @inIdPostByUser,
            @inIdTipoEvento = 401, -- Inserción de movimiento
            @inDescripcion = 'Inserción manual de movimiento de planilla',
            @inIdPostByUser = @inIdPostByUser,
            @inPostInIP = @inPostInIP,
            @inJsonAntes = NULL,
            @inJsonDespues = @jsonDespues,
            @outResultCode = @outResultCode OUTPUT;

        COMMIT;
        SET @outResultCode = 0;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @outResultCode = 50013; -- Error general al insertar movimiento
    END CATCH
END;
