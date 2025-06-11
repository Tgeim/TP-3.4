
/*
Nombre: dbo.SP_Login
Descripción: Verifica credenciales del usuario y registra intento en la bitácora.
Propósito: Autenticar a los usuarios del sistema y dejar trazabilidad de acceso.
*/

CREATE PROCEDURE dbo.SP_Login
    @inUsername VARCHAR(50),
    @inPasswordHash VARCHAR(100),
    @inPostInIP VARCHAR(50),
    @outIdUsuario INT OUTPUT,
    @outEsAdministrador BIT OUTPUT,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @id INT, @admin BIT;

        SELECT @id = id, @admin = esAdministrador
        FROM dbo.Usuario
        WHERE username = @inUsername AND passwordHash = @inPasswordHash;

        IF @id IS NULL
        BEGIN
            -- Registro intento fallido
            EXEC dbo.SP_RegistrarBitacoraEvento
                @inIdUsuario = NULL,
                @inIdTipoEvento = 201, -- 201 = login fallido
                @inDescripcion = 'Intento de login fallido',
                @inIdPostByUser = 0,
                @inPostInIP = @inPostInIP,
                @inJsonAntes = NULL,
                @inJsonDespues = NULL,
                @outResultCode = @outResultCode OUTPUT;

            SET @outResultCode = 50009; -- Credenciales inválidas
            RETURN;
        END

        -- Login exitoso
        SET @outIdUsuario = @id;
        SET @outEsAdministrador = @admin;

        EXEC dbo.SP_RegistrarBitacoraEvento
            @inIdUsuario = @id,
            @inIdTipoEvento = 200, -- 200 = login exitoso
            @inDescripcion = 'Inicio de sesión exitoso',
            @inIdPostByUser = @id,
            @inPostInIP = @inPostInIP,
            @inJsonAntes = NULL,
            @inJsonDespues = NULL,
            @outResultCode = @outResultCode OUTPUT;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50010; -- Error inesperado al autenticar
    END CATCH
END;
