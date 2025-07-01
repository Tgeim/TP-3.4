SET NOCOUNT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    -- 1. Obtener el XML
    DECLARE @xmlOperacion XML;
    SELECT @xmlOperacion = CAST(contenidoXML AS XML)
    FROM dbo.XMLSimulacion
    WHERE nombreXML = 'Operacion';

    -- 2. Tabla de fechas únicas
    DECLARE @FechasOperacion TABLE (Fecha DATE PRIMARY KEY);

    INSERT INTO @FechasOperacion (Fecha)
    SELECT DISTINCT T.Nodos.value('@Fecha', 'DATE')
    FROM @xmlOperacion.nodes('/Operacion/FechaOperacion') AS T(Nodos);

    -- 3. Variables de control
    DECLARE @fechaActual DATE;
    DECLARE @indice INT = 1;
    DECLARE @total INT = (SELECT COUNT(*) FROM @FechasOperacion);


    --===========================================
    -- Variables para bloque de NuevosEmpleados
    DECLARE
        @xmlBloqueNuevos    XML,
        @nombreCompleto     VARCHAR(100),
        @valorDocumento     VARCHAR(30),
        @fechaNacimiento    DATE,
        @idTipoDocumento    INT,
        @idDepartamento     INT,
        @nombrePuesto       VARCHAR(100),
        @idPuesto           INT,
        @username           VARCHAR(50),
        @password           VARCHAR(100),
        @resultadoSP        INT,
        @iNuevos            INT,
        @totalNuevos        INT;

    -- Tabla variable para almacenar empleados del XML
    DECLARE @empleadosXML TABLE (
        nombreCompleto     VARCHAR(100),
        idTipoDocumento    INT,
        valorDocumento     VARCHAR(30),
        fechaNacimiento    DATE,
        idDepartamento     INT,
        nombrePuesto       VARCHAR(100),
        username           VARCHAR(50),
        password           VARCHAR(100)
    );
    --===========================================

    WHILE @indice <= @total
    BEGIN
        -- Obtener la fecha correspondiente a este índice
        SELECT @fechaActual = Fecha
        FROM (
            SELECT Fecha, ROW_NUMBER() OVER (ORDER BY Fecha) AS rn
            FROM @FechasOperacion
        ) AS Sub
        WHERE rn = @indice;

        PRINT ' Procesando fecha: ' + CONVERT(VARCHAR, @fechaActual);

        -----------------------------
        -- Bloque: NuevosEmpleados
        -----------------------------
        IF @xmlOperacion.exist('/Operacion/FechaOperacion[@Fecha=sql:variable("@fechaActual")]/NuevosEmpleados/NuevoEmpleado') = 1
        BEGIN
            PRINT ' Insertando nuevos empleados...';
            -- Limpieza previa
            DELETE FROM @empleadosXML;
            SET @xmlBloqueNuevos = NULL;

            -- Extraer bloque de NuevosEmpleados para la fecha actual
            SET @xmlBloqueNuevos = @xmlOperacion.query('
                /Operacion
                /FechaOperacion[@Fecha=sql:variable("@fechaActual")]
                /NuevosEmpleados
            ');

            IF @xmlBloqueNuevos.exist('/NuevosEmpleados/NuevoEmpleado') = 1
            BEGIN
                PRINT ' Insertando nuevos empleados...';

                -- Poblar tabla con los empleados del XML
                INSERT INTO @empleadosXML (
                    nombreCompleto,
                    idTipoDocumento,
                    valorDocumento,
                    fechaNacimiento,
                    idDepartamento,
                    nombrePuesto,
                    username,
                    password
                )
                SELECT
                    nodo.value('@Nombre', 'VARCHAR(100)'),
                    nodo.value('@IdTipoDocumento', 'INT'),
                    nodo.value('@ValorTipoDocumento', 'VARCHAR(30)'),
                    nodo.value('@FechaNacimiento', 'DATE'),
                    nodo.value('@IdDepartamento', 'INT'),
                    nodo.value('@NombrePuesto', 'VARCHAR(100)'),
                    nodo.value('@Usuario', 'VARCHAR(50)'),
                    nodo.value('@Password', 'VARCHAR(100)')
                FROM @xmlBloqueNuevos.nodes('/NuevosEmpleados/NuevoEmpleado') AS T(nodo);

                SET @iNuevos = 1;
                SET @totalNuevos = (SELECT COUNT(*) FROM @empleadosXML);

                WHILE @iNuevos <= @totalNuevos
                BEGIN
                    -- Extraer fila i
                    SELECT 
                        @nombreCompleto     = nombreCompleto,
                        @idTipoDocumento    = idTipoDocumento,
                        @valorDocumento     = valorDocumento,
                        @fechaNacimiento    = fechaNacimiento,
                        @idDepartamento     = idDepartamento,
                        @nombrePuesto       = nombrePuesto,
                        @username           = username,
                        @password           = password
                    FROM (
                        SELECT 
                            nombreCompleto,
                            idTipoDocumento,
                            valorDocumento,
                            fechaNacimiento,
                            idDepartamento,
                            nombrePuesto,
                            username,
                            password,
                            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS fila
                        FROM @empleadosXML
                    ) AS empleadosConFila
                    WHERE fila = @iNuevos;

                    -- Buscar id del puesto
                    SELECT @idPuesto = id
                    FROM dbo.Puesto
                    WHERE nombre = @nombrePuesto;

                    IF @idPuesto IS NULL
                    BEGIN
                        PRINT '⚠️  Puesto "' + @nombrePuesto + '" no encontrado. Empleado omitido.';
                    END
                    ELSE
                    BEGIN
                        -- Llamar SP
                        EXEC dbo.SP_InsertarNuevoEmpleado
                            @inNombreCompleto     = @nombreCompleto,
                            @inValorDocumento     = @valorDocumento,
                            @inFechaNacimiento    = @fechaNacimiento,
                            @inIdTipoDocumento    = @idTipoDocumento,
                            @inIdDepartamento     = @idDepartamento,
                            @inIdPuesto           = @idPuesto,
                            @inUsername           = @username,
                            @inPassword           = @password,
                            @inIdUsuario          = 1,
                            @inIdPostByUser       = 1,
                            @inPostInIP           = 'SIMULACION',
                            @outResultCode        = @resultadoSP OUTPUT;

                        IF @resultadoSP <> 0
                        BEGIN
                            PRINT '❌ Error al insertar "' + @nombreCompleto + 
                                '" | Código: ' + CAST(@resultadoSP AS VARCHAR);
                        END
                        ELSE
                        BEGIN
                            PRINT '✅ Insertado: ' + @nombreCompleto;
                        END
                    END

                    -- Limpieza para siguiente iteración
                    SET @idPuesto = NULL;
                    SET @resultadoSP = NULL;

                    SET @iNuevos += 1;
                END
            END

        END

        -----------------------------------
        -- ETIQUETA: JornadasProximaSemana
        -----------------------------------
        IF @xmlOperacion.exist('/Operacion/FechaOperacion[@Fecha=sql:variable("@fechaActual")]/JornadasProximaSemana/TipoJornadaProximaSemana') = 1
        BEGIN
            PRINT ' Asignando jornadas de próxima semana...';
            -- Aquí iría el bloque para asignar jornadas
        END

        ------------------------------
        -- ETIQUETA: MarcasAsistencia
        ------------------------------
        IF @xmlOperacion.exist('/Operacion/FechaOperacion[@Fecha=sql:variable("@fechaActual")]/MarcasAsistencia/MarcaDeAsistencia') = 1
        BEGIN
            PRINT ' Insertando marcas de asistencia...';
            -- Aquí iría el bloque para insertar marcas
        END

        --------------------------------------
        -- ETIQUETA: AsociacionDeducciones
        --------------------------------------
        IF @xmlOperacion.exist('/Operacion/FechaOperacion[@Fecha=sql:variable("@fechaActual")]/AsociacionEmpleadoDeducciones/AsociacionEmpleadoConDeduccion') = 1
        BEGIN
            PRINT ' Asociando deducciones...';
            -- Aquí iría el bloque para asociar deducciones
        END

        ------------------------------------------
        -- ETIQUETA: DesasociacionDeducciones
        ------------------------------------------
        IF @xmlOperacion.exist('/Operacion/FechaOperacion[@Fecha=sql:variable("@fechaActual")]/DesasociacionEmpleadoDeducciones/DesasociacionEmpleadoConDeduccion') = 1
        BEGIN
            PRINT ' Desasociando deducciones...';
            -- Aquí iría el bloque para desasociar deducciones
        END

        ------------------------------
        -- ETIQUETA: EliminarEmpleados
        ------------------------------
        IF @xmlOperacion.exist('/Operacion/FechaOperacion[@Fecha=sql:variable("@fechaActual")]/EliminarEmpleados/EliminarEmpleado') = 1
        BEGIN
            PRINT ' Eliminando empleados...';
            -- Aquí iría el bloque para eliminar empleados
        END

        ------------------------------
        -- CÁLCULO DE PLANILLA (Jueves)
        ------------------------------
        IF DATENAME(WEEKDAY, @fechaActual) = 'Thursday'
        BEGIN
            PRINT 'Ejecutando cálculo de planilla...';
            -- Aquí iría la llamada a SP_CalcularPlanillaSemanalEmpleado
        END

        SET @indice += 1;
    END

    COMMIT;
END TRY
BEGIN CATCH
    ROLLBACK;
    DECLARE @Error NVARCHAR(MAX) = ERROR_MESSAGE();
    PRINT '❌ Error: ' + @Error;
END CATCH

SET NOCOUNT OFF;