
/*
Nombre: dbo.SP_CalcularPlanillaMensual
Descripción: Calcula la planilla mensual acumulando semanas terminadas en el mes de referencia.
Propósito: Registrar el total mensual de salario neto por empleado.
*/

CREATE PROCEDURE dbo.SP_CalcularPlanillaMensual
    @inFechaReferencia DATE,
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(50),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @anio INT = YEAR(@inFechaReferencia);
        DECLARE @mes INT = MONTH(@inFechaReferencia);
        DECLARE @inicioMes DATE = DATEFROMPARTS(@anio, @mes, 1);
        DECLARE @finMes DATE = EOMONTH(@inFechaReferencia);

        -- Insertar planilla mensual sumando las planillas semanales de ese mes
        INSERT INTO dbo.PlanillaMensual (
            idEmpleado, mes, montoTotal, fechaCalculo
        )
        SELECT
            idEmpleado,
            FORMAT(@inicioMes, 'yyyy-MM'),
            SUM(montoNeto),
            GETDATE()
        FROM dbo.PlanillaSemanal
        WHERE semanaFin BETWEEN @inicioMes AND @finMes
        GROUP BY idEmpleado;

        -- Registrar evento en bitácora
        EXEC dbo.SP_RegistrarBitacoraEvento
            @inIdUsuario = @inIdPostByUser,
            @inIdTipoEvento = 302, -- cálculo mensual
            @inDescripcion = 'Cálculo de planilla mensual',
            @inIdPostByUser = @inIdPostByUser,
            @inPostInIP = @inPostInIP,
            @inJsonAntes = NULL,
            @inJsonDespues = NULL,
            @outResultCode = @outResultCode OUTPUT;

        SET @outResultCode = 0;
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @outResultCode = 50012; -- Error al calcular planilla mensual
    END CATCH
END;
