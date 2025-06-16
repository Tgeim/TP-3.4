/*
Nombre: dbo.SP_InsertarTipoMovimiento
Descripción: Inserta un nuevo tipo de movimiento en el sistema.
Propósito: Permitir la creación de tipos como "Horas extra", "Bonificación", etc.
*/

CREATE PROCEDURE dbo.SP_InsertarTipoMovimiento
    @inNombre VARCHAR(50),
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(50),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validar que no exista un tipo con el mismo nombre
        IF EXISTS (
            SELECT 1 FROM dbo.TipoMovimiento
            WHERE nombre = @inNombre
        )
        BEGIN
            SET @outResultCode = 50020; -- Nombre duplicado
            ROLLBACK;
            RETURN;
        END

        -- Insertar nuevo tipo
        INSERT INTO dbo.TipoMovimiento (nombre)
        VALUES (@inNombre);

        DECLARE @nuevoId INT = SCOPE_IDENTITY();

        -- Capturar estado insertado
        DECLARE @jsonDespues NVARCHAR(MAX);
        SELECT @jsonDespues = (
            SELECT id, nombre
            FROM dbo.TipoMovimiento
            WHERE id = @nuevoId
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        -- Registrar en bitácora
        EXEC dbo.SP_RegistrarBitacoraEvento
            @inIdUsuario = @inIdPostByUser,
            @inIdTipoEvento = 301, -- Evento: inserción tipo movimiento
            @inDescripcion = 'Inserción de tipo de movimiento',
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
        SET @outResultCode = 50021; -- Error general al insertar tipo movimiento
    END CATCH
END;
