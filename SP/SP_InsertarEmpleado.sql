CREATE PROCEDURE dbo.SP_InsertarEmpleado
    @inNombreCompleto VARCHAR(100),
    @inValorDocumento VARCHAR(30),
    @inFechaNacimiento DATE,
    @inIdTipoDocumento INT,
    @inIdDepartamento INT,
    @inIdPuesto INT,
    @inIdUsuario INT, -- <- AÑADIDO
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(50),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (
            SELECT 1 FROM dbo.Empleado
            WHERE valorDocumento = @inValorDocumento AND activo = 1
        )
        BEGIN
            SET @outResultCode = 50001;
            ROLLBACK;
            RETURN;
        END

        INSERT INTO dbo.Empleado (
            nombreCompleto,
            valorDocumento,
            fechaNacimiento,
            activo,
            idTipoDocumento,
            idDepartamento,
            idPuesto
        )
        VALUES (
            @inNombreCompleto,
            @inValorDocumento,
            @inFechaNacimiento,
            1,
            @inIdTipoDocumento,
            @inIdDepartamento,
            @inIdPuesto
        );

        DECLARE @nuevoIdEmpleado INT = SCOPE_IDENTITY();

        INSERT INTO dbo.BitacoraEvento (
            idUsuario,
            idTipoEvento,
            descripcion,
            idPostByUser,
            postInIP,
            postTime,
            jsonAntes,
            jsonDespues
        )
        VALUES (
            @inIdUsuario, -- <- Se usa aquí correctamente
            101,
            'Inserción de nuevo empleado',
            @inIdPostByUser,
            @inPostInIP,
            GETDATE(),
            NULL,
            (
                SELECT 
                    id, nombreCompleto, valorDocumento, fechaNacimiento,
                    activo, idTipoDocumento, idDepartamento, idPuesto
                FROM dbo.Empleado
                WHERE id = @nuevoIdEmpleado
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
            )
        );

        COMMIT;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @outResultCode = 50002;
    END CATCH
END;
