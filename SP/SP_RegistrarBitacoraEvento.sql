
/*
Nombre: dbo.SP_RegistrarBitacoraEvento
Descripción: Inserta un evento en la tabla BitacoraEvento.
Propósito: Centraliza el registro de acciones relevantes en el sistema para auditoría.
*/

CREATE PROCEDURE dbo.SP_RegistrarBitacoraEvento
    @inIdUsuario INT,
    @inIdTipoEvento INT,
    @inDescripcion VARCHAR(255),
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(50),
    @inJsonAntes NVARCHAR(MAX) = NULL,
    @inJsonDespues NVARCHAR(MAX) = NULL,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
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
            @inIdUsuario,
            @inIdTipoEvento,
            @inDescripcion,
            @inIdPostByUser,
            @inPostInIP,
            GETDATE(),
            @inJsonAntes,
            @inJsonDespues
        );

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50008; -- Error al registrar evento
    END CATCH
END;
