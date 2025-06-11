
/*
Nombre: dbo.SP_EditarEmpleado
Descripción: Edita los datos de un empleado activo.
Propósito: Actualizar datos personales o asignaciones de puesto, departamento o tipo de documento.
*/

CREATE PROCEDURE dbo.SP_EditarEmpleado
    @inId INT,
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

        -- Validar existencia del empleado
        IF NOT EXISTS (SELECT 1 FROM dbo.Empleado WHERE id = @inId AND activo = 1)
        BEGIN
            SET @outResultCode = 50004; -- Empleado no encontrado
            ROLLBACK;
            RETURN;
        END

        -- Validar unicidad de valorDocumento
        IF EXISTS (
            SELECT 1 FROM dbo.Empleado
            WHERE valorDocumento = @inValorDocumento AND id <> @inId AND activo = 1
        )
        BEGIN
            SET @outResultCode = 50001; -- valorDocumento duplicado
            ROLLBACK;
            RETURN;
        END

        -- Obtener datos anteriores
        DECLARE @jsonAntes NVARCHAR(MAX);
        SELECT @jsonAntes = (
            SELECT * FROM dbo.Empleado WHERE id = @inId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        -- Actualizar empleado
        UPDATE dbo.Empleado
        SET nombreCompleto = @inNombreCompleto,
            valorDocumento = @inValorDocumento,
            fechaNacimiento = @inFechaNacimiento,
            idTipoDocumento = @inIdTipoDocumento,
            idDepartamento = @inIdDepartamento,
            idPuesto = @inIdPuesto
        WHERE id = @inId;

        -- Obtener datos nuevos
        DECLARE @jsonDespues NVARCHAR(MAX);
        SELECT @jsonDespues = (
            SELECT * FROM dbo.Empleado WHERE id = @inId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        -- Registrar bitácora
        INSERT INTO dbo.BitacoraEvento (
            idUsuario, idTipoEvento, descripcion,
            idPostByUser, postInIP, postTime,
            jsonAntes, jsonDespues
        )
        VALUES (
            @inIdPostByUser, 102, -- 102 = edición
            'Modificación de empleado',
            @inIdPostByUser, @inPostInIP, GETDATE(),
            @jsonAntes, @jsonDespues
        );

        COMMIT;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @outResultCode = 50006; -- Error general al editar
    END CATCH
END;
