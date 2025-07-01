SET NOCOUNT ON;
-- ==================== Variables globales necesarias para la simulación ====================

-- Usuario que ejecuta la simulación (puede asignarse 1, o el id real del admin/tester que simula)
DECLARE @idUsuarioSimulacion INT = 1;
DECLARE @idPostBySimulacion INT = 1;
DECLARE @ipSimulacion VARCHAR(50) = '127.0.0.1';

-- Tabla para mapear valorDocumento → idEmpleado durante toda la simulación
DECLARE @UsuarioMapping TABLE (
    valorDocumento VARCHAR(30) PRIMARY KEY,
    idEmpleado INT
);
-- ===========================================================================================
DECLARE @xmlOperacion XML;

--- se obtiene el XML de la operacion ya guardado en la tabla dbo.XMLSimulacion
SELECT @xmlOperacion = CAST(contenidoXML AS XML)
FROM dbo.XMLSimulacion
WHERE nombreXML = 'Operacion';


-- Variables para manejar fechas de la operación
DECLARE @fechaBaseOperacion DATE;
DECLARE @inicioSemanaOperacion DATE;
DECLARE @finSemanaOperacion DATE;
DECLARE @fechaLimiteOperacion DATE;

-- Obtener la fecha del primer jueves encontrado en el XML
SELECT TOP 1 @fechaBaseOperacion = T.F.value('@Fecha', 'DATE')
FROM @xmlOperacion.nodes('/Operacion/FechaOperacion') AS T(F)
ORDER BY T.F.value('@Fecha', 'DATE') ASC;

-- Calcular inicio de la semana operativa (viernes anterior)
SET @inicioSemanaOperacion = DATEADD(DAY, -6, @fechaBaseOperacion);
SET @finSemanaOperacion = @fechaBaseOperacion;

-- Obtener la última fecha para cortar el WHILE (último jueves en el XML)
SELECT TOP 1 @fechaLimiteOperacion = T.F.value('@Fecha', 'DATE')
FROM @xmlOperacion.nodes('/Operacion/FechaOperacion') AS T(F)
ORDER BY T.F.value('@Fecha', 'DATE') DESC;

----- Iniciar el ciclo WHILE para procesar cada semana de la operación
WHILE @finSemanaOperacion <= @fechaLimiteOperacion
BEGIN
    PRINT '⏳ Procesando semana: ' + CAST(@inicioSemanaOperacion AS VARCHAR) + ' - ' + CAST(@finSemanaOperacion AS VARCHAR);

    BEGIN TRY
        BEGIN TRANSACTION;

 

    -------------------------------------------------------------
    -- BLOQUE 1: Inserción de nuevos empleados
    -------------------------------------------------------------
    PRINT '📌 Procesando nuevos empleados de la semana...';

    -- Recolectar empleados de todos los días desde el viernes anterior hasta el jueves actual
    DECLARE @nuevosEmpleadosSemana TABLE (
        idx INT IDENTITY(1,1),
        nombre NVARCHAR(100),
        valorDoc VARCHAR(30),
        fechaNacimiento DATE,
        idTipoDocumento INT,
        idDepartamento INT,
        nombrePuesto VARCHAR(100),
        username VARCHAR(50),
        password VARCHAR(50)
    );

    INSERT INTO @nuevosEmpleadosSemana (nombre, valorDoc, fechaNacimiento, idTipoDocumento, idDepartamento, nombrePuesto, username, password)
    SELECT  
        E.Empleado.value('@Nombre', 'VARCHAR(100)'),
        E.Empleado.value('@ValorTipoDocumento', 'VARCHAR(30)'),
        E.Empleado.value('@FechaNacimiento', 'DATE'),
        E.Empleado.value('@IdTipoDocumento', 'INT'),
        E.Empleado.value('@IdDepartamento', 'INT'),
        E.Empleado.value('@NombrePuesto', 'VARCHAR(100)'),
        E.Empleado.value('@Usuario', 'VARCHAR(50)'),
        E.Empleado.value('@Password', 'VARCHAR(50)')
    FROM @xmlOperacion.nodes('/Operacion/FechaOperacion') AS F(Fecha)
    CROSS APPLY F.Fecha.nodes('NuevosEmpleados/NuevoEmpleado') AS E(Empleado)
    WHERE 
        F.Fecha.value('@Fecha', 'DATE') BETWEEN @inicioSemanaOperacion AND @finSemanaOperacion
        AND NOT EXISTS (
            SELECT 1 FROM dbo.Empleado em WHERE em.valorDocumento = E.Empleado.value('@ValorTipoDocumento', 'VARCHAR(30)')
        )
        AND NOT EXISTS (
            SELECT 1 FROM @UsuarioMapping um WHERE um.valorDocumento = E.Empleado.value('@ValorTipoDocumento', 'VARCHAR(30)')
        )


    DECLARE @i INT = 1, @total INT;
    SELECT @total = COUNT(*) FROM @nuevosEmpleadosSemana;

    DECLARE 
        @nombre NVARCHAR(100), @valorDoc VARCHAR(30), @fechaNacimiento DATE,
        @idTipoDocumento INT, @idDepartamento INT, @idPuesto INT,
        @username VARCHAR(50), @password VARCHAR(50), @idEmpleado INT,
        @ResultCode INT;

    WHILE @i <= @total
    BEGIN
        SELECT 
            @nombre = nombre,
            @valorDoc = valorDoc,
            @fechaNacimiento = fechaNacimiento,
            @idTipoDocumento = idTipoDocumento,
            @idDepartamento = idDepartamento,
            @username = username,
            @password = password
        FROM @nuevosEmpleadosSemana WHERE idx = @i;

        -- Buscar id del puesto
        SELECT @idPuesto = id FROM dbo.Puesto WHERE nombre = (
            SELECT nombrePuesto FROM @nuevosEmpleadosSemana WHERE idx = @i
        );

        -- Llamar SP de inserción
        EXEC dbo.SP_InsertarNuevoEmpleado
            @inNombreCompleto = @nombre,
            @inValorDocumento = @valorDoc,
            @inFechaNacimiento = @fechaNacimiento,
            @inIdTipoDocumento = @idTipoDocumento,
            @inIdDepartamento = @idDepartamento,
            @inIdPuesto = @idPuesto,
            @inUsername = @username,
            @inPassword = @password,
            @inIdUsuario = @idUsuarioSimulacion,
            @inIdPostByUser = @idPostBySimulacion,
            @inPostInIP = @ipSimulacion,
            @outResultCode = @ResultCode OUTPUT;

        IF @ResultCode = 0
        BEGIN
            SELECT @idEmpleado = id FROM dbo.Empleado WHERE valorDocumento = @valorDoc;
            INSERT INTO @UsuarioMapping (valorDocumento, idEmpleado)
            VALUES (@valorDoc, @idEmpleado);
        END
        ELSE
        BEGIN
            PRINT '⚠️ Error al insertar empleado con documento: ' + @valorDoc;
        END

        SET @i += 1;
    END;

    PRINT '✔ Empleados insertados esta semana: ' + CAST(@total AS VARCHAR);
    -------------------------------------------------------------
    -------------------------------------------------------------
    -------------------------------------------------------------

    -------------------------------------------------------------
    -- BLOQUE 2: Inserción de jornadas de la próxima semana
    -------------------------------------------------------------
    PRINT '📌 Procesando jornadas de la semana...';

    INSERT INTO dbo.JornadaAsignada (
        idEmpleado,
        fechaInicioSemana,
        idTipoJornada,
        fechaCreacion
    )
    SELECT
        E.id,
        @inicioSemanaOperacion,
        J.Empleado.value('@IdTipoJornada', 'INT'),
        GETDATE()
    FROM @xmlOperacion.nodes('/Operacion/FechaOperacion') AS F(Fecha)
    CROSS APPLY F.Fecha.nodes('JornadasProximaSemana/TipoJornadaProximaSemana') AS J(Empleado)
    INNER JOIN dbo.Empleado E
        ON E.valorDocumento = J.Empleado.value('@ValorDocumento', 'VARCHAR(30)')
    WHERE
        F.Fecha.value('@Fecha', 'DATE') BETWEEN @inicioSemanaOperacion AND @finSemanaOperacion
        AND NOT EXISTS (
            SELECT 1
            FROM dbo.JornadaAsignada JA
            WHERE JA.idEmpleado = E.id
            AND JA.fechaInicioSemana = @inicioSemanaOperacion
        );

    PRINT '✔ Jornadas insertadas para la semana que inicia en: ' + CONVERT(VARCHAR, @inicioSemanaOperacion);
    -------------------------------------------------------------
    -------------------------------------------------------------
    -------------------------------------------------------------



    --------------------------------------------------------------
    -- BLOQUE 3: Inserción de marcas de asistencia
    --------------------------------------------------------------

    PRINT '📌 Insertando marcas de asistencia...';

    INSERT INTO dbo.Marca (
        idEmpleado,
        fechaHoraEntrada,
        fechaHoraSalida
    )
    SELECT
        E.id,
        M.Marca.value('@HoraEntrada', 'DATETIME'),
        M.Marca.value('@HoraSalida', 'DATETIME')
    FROM @xmlOperacion.nodes('/Operacion/FechaOperacion') AS F(Fecha)
    CROSS APPLY F.Fecha.nodes('MarcasAsistencia/MarcaDeAsistencia') AS M(Marca)
    INNER JOIN dbo.Empleado E
        ON E.valorDocumento = M.Marca.value('@ValorDocumento', 'VARCHAR(30)')
    WHERE
        F.Fecha.value('@Fecha', 'DATE') BETWEEN @inicioSemanaOperacion AND @finSemanaOperacion
        AND NOT EXISTS (
            SELECT 1 
            FROM dbo.Marca MAR
            WHERE MAR.idEmpleado = E.id
            AND MAR.fechaHoraEntrada = M.Marca.value('@HoraEntrada', 'DATETIME')
            AND MAR.fechaHoraSalida = M.Marca.value('@HoraSalida', 'DATETIME')
        );
    DECLARE @filasAfectadasMarcas INT;
    SET @filasAfectadasMarcas = @@ROWCOUNT;
    PRINT '✔ Marcas insertadas esta semana: ' + CAST(@filasAfectadasMarcas AS VARCHAR);
    -------------------------------------------------------------
    -------------------------------------------------------------
    -------------------------------------------------------------

    -------------------------------------------------------------
    -- BLOQUE 4: Asociación de deducciones a empleados
    -------------------------------------------------------------
    PRINT '📌 Asociando deducciones a empleados...';

    INSERT INTO dbo.DeduccionEmpleado (
        idEmpleado,
        idTipoDeduccion,
        fechaAsociacion,
        fechaDesasociacion,
        monto
    )
    SELECT
        E.id,
        D.Deduccion.value('@IdTipoDeduccion', 'INT'),
        F.Fecha.value('@Fecha', 'DATE'),
        NULL,
        D.Deduccion.value('@Monto', 'INT')
    FROM @xmlOperacion.nodes('/Operacion/FechaOperacion') AS F(Fecha)
    CROSS APPLY F.Fecha.nodes('AsociacionEmpleadoDeducciones/AsociacionEmpleadoConDeduccion') AS D(Deduccion)
    INNER JOIN dbo.Empleado E
        ON E.valorDocumento = D.Deduccion.value('@ValorDocumento', 'VARCHAR(30)')
    WHERE
        F.Fecha.value('@Fecha', 'DATE') BETWEEN @inicioSemanaOperacion AND @finSemanaOperacion
        AND NOT EXISTS (
            SELECT 1
            FROM dbo.DeduccionEmpleado DE
            WHERE DE.idEmpleado = E.id
            AND DE.idTipoDeduccion = D.Deduccion.value('@IdTipoDeduccion', 'INT')
            AND DE.fechaDesasociacion IS NULL
        );
    DECLARE @filasAfectadasDeducciones INT;
    SET @filasAfectadasDeducciones = @@ROWCOUNT;
    PRINT '✔ Deducciones asociadas esta semana: ' + CAST(@filasAfectadasDeducciones AS VARCHAR);
    -------------------------------------------------------------
    -------------------------------------------------------------
    -------------------------------------------------------------

    -------------------------------------------------------------
    -- BLOQUE 5: Desasociación de deducciones de empleados
    -------------------------------------------------------------
    PRINT '📌 Desasociando deducciones de empleados...';

    UPDATE DE
    SET DE.fechaDesasociacion = F.FechaOperacion.value('@Fecha', 'DATE')
    FROM dbo.DeduccionEmpleado DE
    INNER JOIN dbo.Empleado E ON E.id = DE.idEmpleado
    CROSS APPLY @xmlOperacion.nodes('/Operacion/FechaOperacion') AS F(FechaOperacion)
    CROSS APPLY F.FechaOperacion.nodes('DesasociacionEmpleadoDeducciones/DesasociacionEmpleadoConDeduccion') AS D(Deduccion)
    WHERE 
        F.FechaOperacion.value('@Fecha', 'DATE') BETWEEN @inicioSemanaOperacion AND @finSemanaOperacion
        AND D.Deduccion.value('@ValorTipoDocumento', 'VARCHAR(30)') = E.valorDocumento
        AND DE.idTipoDeduccion = D.Deduccion.value('@IdTipoDeduccion', 'INT')
        AND DE.fechaDesasociacion IS NULL;
    DECLARE @filasDesasociadas INT;
    SET @filasDesasociadas = @@ROWCOUNT;
    PRINT '✔ Deducciones desasociadas esta semana: ' + CAST(@filasDesasociadas AS VARCHAR);
    -------------------------------------------------------------
    -------------------------------------------------------------
    -------------------------------------------------------------

    -------------------------------------------------------------
    -- BLOQUE 6: Eliminación lógica de empleados
    -------------------------------------------------------------
    PRINT '📌 Procesando eliminación lógica de empleados...';

    UPDATE E
    SET E.activo = 0
    FROM dbo.Empleado E
    CROSS APPLY @xmlOperacion.nodes('/Operacion/FechaOperacion') AS F(FechaOperacion)
    CROSS APPLY F.FechaOperacion.nodes('EliminarEmpleados/EliminarEmpleado') AS X(Elim)
    WHERE 
        F.FechaOperacion.value('@Fecha', 'DATE') BETWEEN @inicioSemanaOperacion AND @finSemanaOperacion
        AND E.valorDocumento = X.Elim.value('@ValorTipoDocumento', 'VARCHAR(30)')
        AND E.activo = 1;
    DECLARE @filasEliminadas INT;
    SET @filasEliminadas = @@ROWCOUNT;
    PRINT '✔ Empleados desactivados esta semana: ' + CAST(@filasEliminadas AS VARCHAR);

    -------------------------------------------------------------
    -- BLOQUE 7: Cálculo de planilla semanal
    -------------------------------------------------------------
    PRINT '🧮 Ejecutando cálculo de planilla semanal para semana que finaliza en: ' + CAST(@finSemanaOperacion AS VARCHAR);

    IF DATEPART(WEEKDAY, @finSemanaOperacion) = 5  -- jueves (asumiendo SET DATEFIRST 1)
    BEGIN
        BEGIN TRY
            DECLARE @codigoResultado INT;

            EXEC dbo.SP_CalcularPlanillaSemanalEmpleado
                @inFechaCorte = @finSemanaOperacion,
                @inIdUsuario = @idUsuarioSimulacion,
                @inIdPostByUser = @idPostBySimulacion,
                @inPostInIP = @ipSimulacion,
                @outResultCode = @codigoResultado OUTPUT;

            IF @codigoResultado <> 0
            BEGIN
                DECLARE @fechaTexto VARCHAR(10);
                SET @fechaTexto = CONVERT(VARCHAR(10), @finSemanaOperacion, 23);

                RAISERROR('❌ Error al calcular planilla semanal para la semana que finaliza en %s. Código: %d', 16, 1, @fechaTexto, @codigoResultado);
                RETURN;
            END
            ELSE
            BEGIN
                PRINT '✔ Planilla semanal calculada correctamente.';
            END
        END TRY
        BEGIN CATCH
            DECLARE @errMsg NVARCHAR(4000), @errSeverity INT, @errState INT;
            SELECT @errMsg = ERROR_MESSAGE(), @errSeverity = ERROR_SEVERITY(), @errState = ERROR_STATE();
            RAISERROR('❌ Excepción durante cálculo de planilla semanal: %s', @errSeverity, @errState, @errMsg);
            RETURN;
        END CATCH
    END
    ELSE
    BEGIN
        PRINT '⚠ No es jueves. No se calcula planilla esta semana.';
    END
    -------------------------------------------------------------
    -------------------------------------------------------------




    SET @codigoResultado = 0;
    SET @filasAfectadasMarcas = 0;
    SET @filasAfectadasDeducciones = 0;
    SET @filasDesasociadas = 0;
    SET @filasEliminadas = 0;


        COMMIT;
        PRINT '✅ Semana procesada correctamente: ' + CAST(@inicioSemanaOperacion AS VARCHAR) + ' - ' + CAST(@finSemanaOperacion AS VARCHAR);
    END TRY
    BEGIN CATCH
        PRINT '❌ Error al procesar semana: ' + CAST(@inicioSemanaOperacion AS VARCHAR) + ' - ' + CAST(@finSemanaOperacion AS VARCHAR);
        PRINT '⚠️ Mensaje de error: ' + ERROR_MESSAGE();
        IF @@TRANCOUNT > 0
            ROLLBACK;
    END CATCH;

    -- Avanzar a la siguiente semana
    SET @inicioSemanaOperacion = DATEADD(DAY, 7, @inicioSemanaOperacion);
    SET @finSemanaOperacion = DATEADD(DAY, 7, @finSemanaOperacion);
END;
