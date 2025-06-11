
/*
Nombre: dbo.SP_InsertarEmpleado
Descripción: Inserta un nuevo empleado en el sistema si el valorDocumento no está repetido.
Propósito: Agregar empleados activos a la base de datos con trazabilidad completa.
*/

CREATE PROCEDURE dbo.SP_InsertarEmpleado
    @inNombreCompleto VARCHAR(100),
    @inValorDocumento VARCHAR(30),
    @inFechaNacimiento DATE,
    @inIdTipoDocumento INT,
    @inIdDepartamento INT,
    @inIdPuesto INT,
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(50),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validar que no exista ya un empleado con ese valorDocumento
        IF EXISTS (
            SELECT 1 FROM dbo.Empleado
            WHERE valorDocumento = @inValorDocumento AND activo = 1
        )
        BEGIN
            SET @outResultCode = 50001; -- Código de error: valorDocumento duplicado
            ROLLBACK;
            RETURN;
        END

        -- Insertar nuevo empleado
        INSERT INTO dbo.Empleado (
            nombreCompleto, valorDocumento, fechaNacimiento,
            activo, idTipoDocumento, idDepartamento, idPuesto
        )
        VALUES (
            @inNombreCompleto, @inValorDocumento, @inFechaNacimiento,
            1, @inIdTipoDocumento, @inIdDepartamento, @inIdPuesto
        );

        DECLARE @nuevoIdEmpleado INT = SCOPE_IDENTITY();

        -- Registrar en bitácora
        INSERT INTO dbo.BitacoraEvento (
            idUsuario, idTipoEvento, descripcion,
            idPostByUser, postInIP, postTime,
            jsonAntes, jsonDespues
        )
        VALUES (
            @inIdPostByUser, 101, -- 101 = Inserción
            'Inserción de nuevo empleado',
            @inIdPostByUser, @inPostInIP, GETDATE(),
            NULL,
            (
                SELECT *
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
        SET @outResultCode = 50002; -- Código de error genérico inesperado
    END CATCH
END;
