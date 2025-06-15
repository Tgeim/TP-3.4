/*
Nombre: dbo.SP_InsertarMarca
Descripción: Registra una marca de entrada o salida para un empleado.
Propósito: Capturar la asistencia diaria que se usará para el cálculo de planilla.
*/

CREATE PROCEDURE dbo.SP_InsertarMarca
    @inIdEmpleado INT,
    @inFechaHora DATETIME,
    @inTipoMarca VARCHAR(10), -- 'entrada' o 'salida'
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

        -- Validar tipo de marca permitido
        IF @inTipoMarca NOT IN ('entrada', 'salida')
        BEGIN
            SET @outResultCode = 50014; -- Tipo de marca inválido
            ROLLBACK;
            RETURN;
        END

        -- Insertar marca
        INSERT INTO dbo.Marca (
            idEmpleado,
            fechaHora,
            tipoMarca
        )
        VALUES (
            @inIdEmpleado,
            @inFechaHora,
            @inTipoMarca
        );

        -- Obtener ID de la marca recién creada
        DECLARE @idNuevaMarca INT = SCOPE_IDENTITY();

        -- Obtener datos insertados para bitácora (evitar SELECT *)
        DECLARE @jsonDespues NVARCHAR(MAX);
        SELECT @jsonDespues = (
            SELECT
                id,
                idEmpleado,
                fechaHora,
                tipoMarca
            FROM dbo.Marca
            WHERE id = @idNuevaMarca
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        -- Preparar descripción del evento
        DECLARE @descripcionEvento VARCHAR(255);
        SET @descripcionEvento = 'Marca de ' + @inTipoMarca + ' registrada';

        -- Registrar en bitácora
        EXEC dbo.SP_RegistrarBitacoraEvento
            @inIdUsuario = @inIdPostByUser,
            @inIdTipoEvento = 402, -- Evento: Registro de marca
            @inDescripcion = @descripcionEvento,
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
        SET @outResultCode = 50015; -- Error al insertar marca
    END CATCH
END;
