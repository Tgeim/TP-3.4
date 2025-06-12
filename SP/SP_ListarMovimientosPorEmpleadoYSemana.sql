
/*
Nombre: dbo.SP_ListarMovimientosPorEmpleadoYSemana
Descripción: Lista todos los movimientos registrados para un empleado durante una semana específica.
Propósito: Permitir visualizar los movimientos de planilla por semana para efectos de revisión y cálculo.
*/

CREATE PROCEDURE dbo.SP_ListarMovimientosPorEmpleadoYSemana
    @inIdEmpleado INT,
    @inSemana DATE,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validar existencia del empleado activo
        IF NOT EXISTS (
            SELECT 1 FROM dbo.Empleado WHERE id = @inIdEmpleado AND activo = 1
        )
        BEGIN
            SET @outResultCode = 50004; -- Empleado no encontrado
            RETURN;
        END

        -- Listar movimientos de la semana
        SELECT
            M.id,
            M.semana,
            TM.nombre AS tipoMovimiento,
            M.cantidadHoras,
            M.monto,
            M.creadoPorSistema,
            M.fechaCreacion
        FROM dbo.Movimiento M
        INNER JOIN dbo.TipoMovimiento TM ON M.idTipoMovimiento = TM.id
        WHERE M.idEmpleado = @inIdEmpleado AND M.semana = @inSemana
        ORDER BY M.fechaCreacion ASC;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50022; -- Error al consultar movimientos
    END CATCH
END;
