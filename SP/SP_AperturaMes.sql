CREATE PROCEDURE sp_AperturaMes
    @fecha DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @mesActual VARCHAR(7) = FORMAT(@fecha, 'yyyy-MM');

    -- Insertar para cada empleado activo si no existe ya planilla de ese mes
    INSERT INTO PlanillaMensual (
        idEmpleado, mes, montoTotal, fechaCalculo
    )
    SELECT 
        e.id, @mesActual, 0, NULL
    FROM Empleado e
    WHERE e.activo = 1
    AND NOT EXISTS (
        SELECT 1 
        FROM PlanillaMensual pm
        WHERE pm.idEmpleado = e.id
          AND pm.mes = @mesActual
    );
END
