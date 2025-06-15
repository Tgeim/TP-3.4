/*
Nombre: dbo.SP_InsertarDeduccionEmpleado
Descripción: Asocia una deducción a un empleado (si no es obligatoria y no existe ya).
Propósito: Controlar deducciones aplicables por empleado, manualmente o por XML.
*/

CREATE PROCEDURE dbo.SP_InsertarDeduccionEmpleado
    @inIdEmpleado INT,
    @inIdTipoDeduccion INT,
    @inFechaAsociacion DATE,
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(50),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validar existencia del empleado
        IF NOT EXISTS (
            SELECT 1 FROM dbo.Empleado
            WHERE id = @inIdEmpleado AND activo = 1
        )
        BEGIN
            SET @outResultCode = 50004; -- Empleado no encontrado
            ROLLBACK;
            RETURN;
        END

        -- Validar existencia del tipo de deducción
        IF NOT EXISTS (
            SELECT 1 FROM dbo.TipoDeduccion
            WHERE id = @inIdTipoDeduccion
        )
        BEGIN
            SET @outResultCode = 50016; -- Tipo de deducción no válido
            ROLLBACK;
            RETURN;
        END

        -- Validar si ya existe una asociación activa
        IF EXISTS (
            SELECT 1 FROM dbo.DeduccionEmpleado
            WHERE idEmpleado = @inIdEmpleado
              AND idTipoDeduccion = @inIdTipoDeduccion
              AND fechaDesasociacion IS NULL
        )
        BEGIN
            SET @outResultCode = 50017; -- Ya existe deducción activa
            ROLLBACK;
            RETURN;
        END

        -- Insertar deducción
        INSERT INTO dbo.DeduccionEmpleado (
            idEmpleado,
            idTipoDeduccion,
            fechaAsociacion,
            fechaDesasociacion
        )
        VALUES (
            @inIdEmpleado,
            @inIdTipoDeduccion,
            @inFechaAsociacion,
            NULL
        );

        -- Bitácora
        DECLARE @idNueva INT = SCOPE_IDENTITY();
        DECLARE @jsonDespues NVARCHAR(MAX);
        SELECT @jsonDespues = (
            SELECT
                id,
                idEmpleado,
                idTipoDeduccion,
                fechaAsociacion,
                fechaDesasociacion
            FROM dbo.DeduccionEmpleado
            WHERE id = @idNueva
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.SP_RegistrarBitacoraEvento
            @inIdUsuario = @inIdPostByUser,
            @inIdTipoEvento = 501,
            @inDescripcion = 'Asociación de deducción a empleado',
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
        SET @outResultCode = 50018; -- Error general al asociar deducción
    END CATCH
END;
2