/*
Nombre: dbo.SP_ListarMovimientosPorEmpleadoYSemana
Descripción: Lista los movimientos de un empleado durante la semana correspondiente a la fecha dada.
Propósito: Obtener todos los movimientos entre lunes y domingo que contengan la fecha ingresada.
*/

CREATE PROCEDURE dbo.SP_ListarMovimientosPorEmpleadoYSemana
    @inIdEmpleado INT,
    @inFecha DATE,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Calcular el lunes de la semana de la fecha ingresada
        DECLARE @inicioSemana DATE = DATEADD(DAY, -DATEPART(WEEKDAY, @inFecha) + 2, @inFecha);
        DECLARE @finSemana DATE = DATEADD(DAY, 6, @inicioSemana);

        SELECT 
            M.id,
            M.semana,
            M.cantidadHoras,
            M.monto,
            M.creadoPorSistema,
            M.fechaCreacion,
            TM.nombre AS tipoMovimiento,
            E.nombreCompleto AS nombreEmpleado
        FROM dbo.Movimiento M
        INNER JOIN dbo.TipoMovimiento TM ON TM.id = M.idTipoMovimiento
        INNER JOIN dbo.Empleado E ON E.id = M.idEmpleado
        WHERE M.idEmpleado = @inIdEmpleado
          AND M.semana BETWEEN @inicioSemana AND @finSemana
        ORDER BY M.semana, M.fechaCreacion;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50020; -- Error al listar movimientos
    END CATCH
END;
