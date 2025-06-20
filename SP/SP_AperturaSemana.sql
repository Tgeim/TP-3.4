CREATE PROCEDURE sp_AperturaSemana
    @fecha DATE
AS
BEGIN
    SET NOCOUNT ON;
    SET DATEFIRST 1; -- Para que jueves sea 5

    IF DATEPART(WEEKDAY, @fecha) = 5
    BEGIN
        DECLARE @semanaInicio DATE = DATEADD(DAY, -4, @fecha); -- lunes
        DECLARE @semanaFin DATE = DATEADD(DAY, 2, @fecha);     -- domingo

        -- Insertar la semana para cada empleado activo, si no existe ya
        INSERT INTO PlanillaSemanal (
            idEmpleado, semanaInicio, semanaFin, 
            horasOrdinarias, horasExtra, montoBruto, 
            montoDeducciones, montoNeto, fechaCalculo
        )
        SELECT 
            e.id, @semanaInicio, @semanaFin,
            0, 0, 0, 0, 0, NULL
        FROM Empleado e
        WHERE e.activo = 1
        AND NOT EXISTS (
            SELECT 1 
            FROM PlanillaSemanal ps 
            WHERE ps.idEmpleado = e.id 
              AND ps.semanaInicio = @semanaInicio 
              AND ps.semanaFin = @semanaFin
        );
    END

    -- Llamar al procedimiento que crea la planilla mensual si es necesario
    EXEC sp_AperturaMes @fecha;
END
