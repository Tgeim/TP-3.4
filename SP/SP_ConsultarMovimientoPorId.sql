/*
Nombre: dbo.SP_ConsultarMovimientoPorId
Descripción: Consulta los datos de un movimiento específico por su ID.
Propósito: Obtener los datos necesarios para editar un movimiento.
*/

CREATE PROCEDURE dbo.SP_ConsultarMovimientoPorId
    @inId INT,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Verificar existencia
        IF NOT EXISTS (SELECT 1 FROM dbo.Movimiento WHERE id = @inId)
        BEGIN
            SET @outResultCode = 50020; -- Movimiento no existe
            RETURN;
        END

        -- Devolver los datos del movimiento
        SELECT
            M.id,
            M.idEmpleado,
            E.nombreCompleto,
            M.idTipoMovimiento,
            TM.nombre AS nombreTipo,
            M.semana,
            M.cantidadHoras,
            M.monto,
            M.creadoPorSistema,
            M.fechaCreacion
        FROM dbo.Movimiento M
        JOIN dbo.Empleado E ON M.idEmpleado = E.id
        JOIN dbo.TipoMovimiento TM ON M.idTipoMovimiento = TM.id
        WHERE M.id = @inId;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50021; -- Error general al consultar movimiento
    END CATCH
END;
