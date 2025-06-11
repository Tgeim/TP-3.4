
/*
Nombre: dbo.SP_CalcularPlanillaSemanal
Descripción: Calcula la planilla semanal para todos los empleados activos.
Propósito: Determinar salario bruto, deducciones y salario neto por semana.
*/

CREATE PROCEDURE dbo.SP_CalcularPlanillaSemanal
    @inFechaBase DATE,
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(50),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Determinar inicio y fin de semana a partir del jueves de @inFechaBase
        DECLARE @juevesBase DATE = @inFechaBase;
        DECLARE @semanaInicio DATE;
        DECLARE @semanaFin DATE;

        -- La semana cubre desde el viernes anterior a @juevesBase hasta el jueves actual
        SET @semanaInicio = DATEADD(DAY, -6, @juevesBase); -- viernes anterior
        SET @semanaFin = @juevesBase; -- jueves actual

        -- Declaraciones necesarias para cursor y cálculos por empleado
        DECLARE @idEmpleado INT;
        DECLARE @horasTrabajadas FLOAT;
        DECLARE @salarioPorHora FLOAT;
        DECLARE @horasOrdinarias FLOAT;
        DECLARE @horasExtra FLOAT;
        DECLARE @montoBruto FLOAT;
        DECLARE @montoDeducciones FLOAT = 0;
        DECLARE @montoNeto FLOAT;

        -- Cursor para recorrer empleados activos
        DECLARE empleados_cursor CURSOR FOR
        SELECT id, (SELECT salarioPorHora FROM dbo.Puesto WHERE id = E.idPuesto)
        FROM dbo.Empleado E
        WHERE activo = 1;

        OPEN empleados_cursor;
        FETCH NEXT FROM empleados_cursor INTO @idEmpleado, @salarioPorHora;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Aquí irían cálculos de marcas para @idEmpleado entre @semanaInicio y @semanaFin
            -- (omitiendo detalle por ahora)

            -- Simulamos cálculo de horas para ejemplo
            SET @horasTrabajadas = 52;
            SET @horasOrdinarias = CASE WHEN @horasTrabajadas <= 48 THEN @horasTrabajadas ELSE 48 END;
            SET @horasExtra = CASE WHEN @horasTrabajadas > 48 THEN @horasTrabajadas - 48 ELSE 0 END;
            SET @montoBruto = (@horasOrdinarias * @salarioPorHora) + (@horasExtra * @salarioPorHora * 1.5);

            -- Suponemos 10% de deducciones porcentuales para el ejemplo
            SET @montoDeducciones = @montoBruto * 0.1;
            SET @montoNeto = @montoBruto - @montoDeducciones;

            -- Insertar en PlanillaSemanal
            INSERT INTO dbo.PlanillaSemanal (
                idEmpleado, semanaInicio, semanaFin,
                horasOrdinarias, horasExtra,
                montoBruto, montoDeducciones, montoNeto,
                fechaCalculo
            )
            VALUES (
                @idEmpleado, @semanaInicio, @semanaFin,
                @horasOrdinarias, @horasExtra,
                @montoBruto, @montoDeducciones, @montoNeto,
                GETDATE()
            );

            -- Siguiente empleado
            FETCH NEXT FROM empleados_cursor INTO @idEmpleado, @salarioPorHora;
        END

        CLOSE empleados_cursor;
        DEALLOCATE empleados_cursor;

        -- Registrar bitácora
        EXEC dbo.SP_RegistrarBitacoraEvento
            @inIdUsuario = @inIdPostByUser,
            @inIdTipoEvento = 301, -- 301 = cálculo semanal
            @inDescripcion = 'Cálculo de planilla semanal',
            @inIdPostByUser = @inIdPostByUser,
            @inPostInIP = @inPostInIP,
            @inJsonAntes = NULL,
            @inJsonDespues = NULL,
            @outResultCode = @outResultCode OUTPUT;

        COMMIT;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @outResultCode = 50011; -- Error general al calcular planilla
    END CATCH
END;
