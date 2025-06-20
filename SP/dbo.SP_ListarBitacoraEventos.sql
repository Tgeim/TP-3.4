CREATE PROCEDURE dbo.SP_ListarBitacoraEventos
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT 
            B.id,
            U.username AS nombreUsuario,
            B.descripcion,
            B.postInIP,
            B.postTime,
            B.jsonAntes,
            B.jsonDespues
        FROM dbo.BitacoraEvento B
        INNER JOIN dbo.Usuario U ON B.idUsuario = U.id
        ORDER BY B.postTime DESC;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50030; -- Error al listar bitácora
    END CATCH
END;
