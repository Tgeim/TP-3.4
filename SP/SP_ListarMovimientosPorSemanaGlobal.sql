CREATE PROCEDURE dbo.SP_ListarMovimientosPorSemanaGlobal
    @inFecha DATE,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
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
        WHERE M.semana BETWEEN @inicioSemana AND @finSemana
        ORDER BY E.nombreCompleto, M.semana, M.fechaCreacion;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50021; -- Error al listar movimientos globales
    END CATCH
END;
