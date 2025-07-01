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

    --============================================
    -- Variables para bloque JornadasProximaSemana
    DECLARE
        @xmlBloqueJornadas     XML,
        @valorDocJornada       VARCHAR(30),
        @idTipoJornadaAsignada INT,
        @idEmpleadoAsignado    INT,
        @fechaInicioJornada    DATE,
        @iJornada               INT,
        @totalJornadas         INT;

    -- Tabla variable para almacenar nodos de jornada
    DECLARE @jornadasXML TABLE (
        valorDocumento     VARCHAR(30),
        idTipoJornada      INT
    );
    --============================================

    --===========================================
    -- Variables para bloque MarcasAsistencia
    DECLARE
        @xmlBloqueMarcas       XML,
        @valorDocMarca         VARCHAR(30),
        @horaEntradaMarca      DATETIME,
        @horaSalidaMarca       DATETIME,
        @idEmpleadoMarca       INT,
        @iMarca                INT,
        @totalMarcas           INT;

    -- Tabla variable para almacenar marcas extraídas del XML
    DECLARE @marcasXML TABLE (
        valorDocumento     VARCHAR(30),
        horaEntrada        DATETIME,
        horaSalida         DATETIME
    );
    --===========================================

    --===========================================
    -- Variables para bloque de AsociaciónEmpleadoDeducciones
    DECLARE
        @xmlBloqueAsociaciones     XML,
        @valorDocAsociacion        VARCHAR(30),
        @idTipoDeduccionAsociada   INT,
        @montoDeduccionAsociada    INT,
        @idEmpleadoAsociado        INT,
        @iAsociacion               INT,
        @totalAsociaciones         INT;

    -- Tabla variable para almacenar asociaciones desde el XML
    DECLARE @asociacionesXML TABLE (
        valorDocumento     VARCHAR(30),
        idTipoDeduccion    INT,
        monto              INT
    );
    --============================================


    --===========================================
    -- Variables para bloque de DesasociaciónEmpleadoDeducciones
    DECLARE
        @xmlBloqueDesasociaciones     XML,
        @valorDocDesasociacion        VARCHAR(30),
        @idTipoDeduccionDesasociada   INT,
        @idEmpleadoDesasociado        INT,
        @iDesasociacion               INT,
        @totalDesasociaciones         INT;

    -- Tabla variable para almacenar desasociaciones desde el XML
    DECLARE @desasociacionesXML TABLE (
        valorDocumento     VARCHAR(30),
        idTipoDeduccion    INT
    );
    --============================================


    --============================================
    -- 🔹 Variables para bloque de EliminarEmpleados
    DECLARE
        @xmlBloqueEliminaciones     XML,
        @valorDocEliminar           VARCHAR(30),
        @idEmpleadoEliminar         INT,
        @resultadoEliminarSP        INT,
        @iEliminar                  INT,
        @totalEliminaciones         INT;

    -- 🔹 Tabla variable para almacenar los empleados a eliminar desde el XML
    DECLARE @eliminacionesXML TABLE (
        valorDocumento     VARCHAR(30)
    );
    --============================================


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
                        PRINT '  Puesto "' + @nombrePuesto + '" no encontrado. Empleado omitido.';
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
                            PRINT ' Error al insertar "' + @nombreCompleto + 
                                '" | Código: ' + CAST(@resultadoSP AS VARCHAR);
                        END
                        ELSE
                        BEGIN
                            PRINT ' Insertado: ' + @nombreCompleto;
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

            -- Limpieza previa
            DELETE FROM @jornadasXML;
                    SET @xmlBloqueJornadas = NULL;

            -- Extraer el bloque de jornadas de la semana siguiente
            SET @xmlBloqueJornadas = @xmlOperacion.query('
                /Operacion
                /FechaOperacion[@Fecha=sql:variable("@fechaActual")]
                /JornadasProximaSemana
            ');

            IF @xmlBloqueJornadas.exist('/JornadasProximaSemana/TipoJornadaProximaSemana') = 1
            BEGIN
                PRINT ' Asignando jornadas de próxima semana...';

                -- Llenar la tabla variable con los nodos de jornada
                INSERT INTO @jornadasXML (
                    valorDocumento,
                    idTipoJornada
                )
                SELECT
                    nodo.value('@ValorTipoDocumento', 'VARCHAR(30)'),
                    nodo.value('@IdTipoJornada', 'INT')
                FROM @xmlBloqueJornadas.nodes('/JornadasProximaSemana/TipoJornadaProximaSemana') AS T(nodo);

                -- Calcular fecha de inicio de la semana (viernes siguiente al jueves actual)
                SET @fechaInicioJornada = DATEADD(DAY, 1, @fechaActual);

                SET @iJornada = 1;
                SET @totalJornadas = (SELECT COUNT(*) FROM @jornadasXML);

                WHILE @iJornada <= @totalJornadas
                BEGIN
                    -- Obtener datos de la fila i
                    SELECT 
                        @valorDocJornada       = valorDocumento,
                        @idTipoJornadaAsignada = idTipoJornada
                    FROM (
                        SELECT 
                            valorDocumento,
                            idTipoJornada,
                            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS fila
                        FROM @jornadasXML
                    ) AS filaJ
                    WHERE fila = @iJornada;

                    -- Buscar el ID del empleado por documento
                    SELECT @idEmpleadoAsignado = id
                    FROM dbo.Empleado
                    WHERE valorDocumento = @valorDocJornada
                    AND activo = 1;

                    IF @idEmpleadoAsignado IS NULL
                    BEGIN
                        PRINT '  Empleado con documento "' + @valorDocJornada + '" no encontrado. Jornada omitida.';
                    END
                    ELSE
                    BEGIN
                        -- Insertar la jornada directamente
                        INSERT INTO dbo.JornadaAsignada (
                            idEmpleado,
                            fechaInicioSemana,
                            idTipoJornada,
                            fechaCreacion
                        )
                        VALUES (
                            @idEmpleadoAsignado,
                            @fechaInicioJornada,
                            @idTipoJornadaAsignada,
                            @fechaActual -- la fecha del jueves, no GETDATE()
                        );

                        PRINT ' Jornada asignada a empleado ' + @valorDocJornada;
                    END

                    -- Limpieza
                    SET @idEmpleadoAsignado = NULL;

                    SET @iJornada += 1;
                END
            END

        END

        ------------------------------
        -- ETIQUETA: MarcasAsistencia
        ------------------------------
        IF @xmlOperacion.exist('/Operacion/FechaOperacion[@Fecha=sql:variable("@fechaActual")]/MarcasAsistencia/MarcaDeAsistencia') = 1
        BEGIN
            PRINT ' Insertando marcas de asistencia...';
            -- Limpieza previa
            DELETE FROM @marcasXML;
            SET @xmlBloqueMarcas = NULL;

            -- Extraer bloque de marcas
            SET @xmlBloqueMarcas = @xmlOperacion.query('
                /Operacion
                /FechaOperacion[@Fecha=sql:variable("@fechaActual")]
                /MarcasAsistencia
            ');

            IF @xmlBloqueMarcas.exist('/MarcasAsistencia/MarcaDeAsistencia') = 1
            BEGIN
                PRINT ' Insertando marcas de asistencia...';

                -- Llenar tabla variable con los datos del XML
                INSERT INTO @marcasXML (
                    valorDocumento,
                    horaEntrada,
                    horaSalida
                )
                SELECT
                    nodo.value('@ValorTipoDocumento', 'VARCHAR(30)'),
                    nodo.value('@HoraEntrada', 'DATETIME'),
                    nodo.value('@HoraSalida', 'DATETIME')
                FROM @xmlBloqueMarcas.nodes('/MarcasAsistencia/MarcaDeAsistencia') AS T(nodo);

                SET @iMarca = 1;
                SET @totalMarcas = (SELECT COUNT(*) FROM @marcasXML);

                WHILE @iMarca <= @totalMarcas
                BEGIN
                    -- Obtener los datos de la marca i
                    SELECT 
                        @valorDocMarca    = valorDocumento,
                        @horaEntradaMarca = horaEntrada,
                        @horaSalidaMarca  = horaSalida
                    FROM (
                        SELECT 
                            valorDocumento,
                            horaEntrada,
                            horaSalida,
                            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS fila
                        FROM @marcasXML
                    ) AS marcasConFila
                    WHERE fila = @iMarca;

                    -- Obtener ID del empleado
                    SELECT @idEmpleadoMarca = id
                    FROM dbo.Empleado
                    WHERE valorDocumento = @valorDocMarca
                    AND activo = 1;

                    IF @idEmpleadoMarca IS NULL
                    BEGIN
                        PRINT '  Empleado con documento "' + @valorDocMarca + '" no encontrado. Marca omitida.';
                    END
                    ELSE
                    BEGIN
                        -- Insertar marca
                        INSERT INTO dbo.Marca (
                            idEmpleado,
                            fechaHoraEntrada,
                            fechaHoraSalida
                        )
                        VALUES (
                            @idEmpleadoMarca,
                            @horaEntradaMarca,
                            @horaSalidaMarca
                        );

                        PRINT ' Marca insertada para empleado ' + @valorDocMarca;
                    END

                    -- Limpieza para siguiente iteración
                    SET @idEmpleadoMarca = NULL;

                    SET @iMarca += 1;
                END
            END

        END

        --------------------------------------
        -- ETIQUETA: AsociacionDeducciones
        --------------------------------------
        IF @xmlOperacion.exist('/Operacion/FechaOperacion[@Fecha=sql:variable("@fechaActual")]/AsociacionEmpleadoDeducciones/AsociacionEmpleadoConDeduccion') = 1
        BEGIN
            PRINT ' Asociando deducciones...';


            -- Limpieza previa
            DELETE FROM @asociacionesXML;
            SET @xmlBloqueAsociaciones = NULL;

            -- Extraer bloque de asociaciones de deducciones
            SET @xmlBloqueAsociaciones = @xmlOperacion.query('
                /Operacion
                /FechaOperacion[@Fecha=sql:variable("@fechaActual")]
                /AsociacionEmpleadoDeducciones
            ');

            IF @xmlBloqueAsociaciones.exist('/AsociacionEmpleadoDeducciones/AsociacionEmpleadoConDeduccion') = 1
            BEGIN
                PRINT ' Asociando deducciones...';

                -- Llenar la tabla variable
                INSERT INTO @asociacionesXML (
                    valorDocumento,
                    idTipoDeduccion,
                    monto
                )
                SELECT
                    nodo.value('@ValorTipoDocumento', 'VARCHAR(30)'),
                    nodo.value('@IdTipoDeduccion', 'INT'),
                    ISNULL(nodo.value('@Monto', 'INT'), 0)
                FROM @xmlBloqueAsociaciones.nodes('/AsociacionEmpleadoDeducciones/AsociacionEmpleadoConDeduccion') AS T(nodo);

                SET @iAsociacion = 1;
                SET @totalAsociaciones = (SELECT COUNT(*) FROM @asociacionesXML);

                WHILE @iAsociacion <= @totalAsociaciones
                BEGIN
                    -- Extraer datos de la fila i
                    SELECT 
                        @valorDocAsociacion      = valorDocumento,
                        @idTipoDeduccionAsociada = idTipoDeduccion,
                        @montoDeduccionAsociada  = monto
                    FROM (
                        SELECT 
                            valorDocumento,
                            idTipoDeduccion,
                            monto,
                            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS fila
                        FROM @asociacionesXML
                    ) AS asociacionesConFila
                    WHERE fila = @iAsociacion;

                    -- Buscar ID del empleado
                    SELECT @idEmpleadoAsociado = id
                    FROM dbo.Empleado
                    WHERE valorDocumento = @valorDocAsociacion
                    AND activo = 1;

                    IF @idEmpleadoAsociado IS NULL
                    BEGIN
                        PRINT '  Empleado con documento "' + @valorDocAsociacion + '" no encontrado. Asociación omitida.';
                    END
                    ELSE
                    BEGIN
                        -- Insertar la asociación directamente
                        INSERT INTO dbo.DeduccionEmpleado (
                            idEmpleado,
                            idTipoDeduccion,
                            fechaAsociacion,
                            monto
                        )
                        VALUES (
                            @idEmpleadoAsociado,
                            @idTipoDeduccionAsociada,
                            @fechaActual,
                            @montoDeduccionAsociada
                        );

                        PRINT ' Deducción asociada para empleado ' + @valorDocAsociacion;
                    END

                    -- Limpieza
                    SET @idEmpleadoAsociado = NULL;

                    SET @iAsociacion += 1;
                END
            END

        END

        ------------------------------------------
        -- ETIQUETA: DesasociacionDeducciones
        ------------------------------------------
        IF @xmlOperacion.exist('/Operacion/FechaOperacion[@Fecha=sql:variable("@fechaActual")]/DesasociacionEmpleadoDeducciones/DesasociacionEmpleadoConDeduccion') = 1
        BEGIN
            PRINT ' Desasociando deducciones...';


            -- Limpieza previa
            DELETE FROM @desasociacionesXML;
            SET @xmlBloqueDesasociaciones = NULL;

            -- Extraer bloque de desasociación de deducciones
            SET @xmlBloqueDesasociaciones = @xmlOperacion.query('
                /Operacion
                /FechaOperacion[@Fecha=sql:variable("@fechaActual")]
                /DesasociacionEmpleadoDeducciones
            ');

            IF @xmlBloqueDesasociaciones.exist('/DesasociacionEmpleadoDeducciones/DesasociacionEmpleadoConDeduccion') = 1
            BEGIN
                PRINT ' Desasociando deducciones...';

                -- Llenar tabla con datos del XML
                INSERT INTO @desasociacionesXML (
                    valorDocumento,
                    idTipoDeduccion
                )
                SELECT
                    nodo.value('@ValorTipoDocumento', 'VARCHAR(30)'),
                    nodo.value('@IdTipoDeduccion', 'INT')
                FROM @xmlBloqueDesasociaciones.nodes('/DesasociacionEmpleadoDeducciones/DesasociacionEmpleadoConDeduccion') AS T(nodo);

                SET @iDesasociacion = 1;
                SET @totalDesasociaciones = (SELECT COUNT(*) FROM @desasociacionesXML);

                WHILE @iDesasociacion <= @totalDesasociaciones
                BEGIN
                    -- Extraer fila actual
                    SELECT 
                        @valorDocDesasociacion      = valorDocumento,
                        @idTipoDeduccionDesasociada = idTipoDeduccion
                    FROM (
                        SELECT 
                            valorDocumento,
                            idTipoDeduccion,
                            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS fila
                        FROM @desasociacionesXML
                    ) AS filaDes
                    WHERE fila = @iDesasociacion;

                    -- Buscar ID del empleado
                    SELECT @idEmpleadoDesasociado = id
                    FROM dbo.Empleado
                    WHERE valorDocumento = @valorDocDesasociacion
                    AND activo = 1;

                    IF @idEmpleadoDesasociado IS NULL
                    BEGIN
                        PRINT '  Empleado con documento "' + @valorDocDesasociacion + '" no encontrado. Desasociación omitida.';
                    END
                    ELSE
                    BEGIN
                        -- Ejecutar la desasociación
                        UPDATE dbo.DeduccionEmpleado
                        SET fechaDesasociacion = @fechaActual
                        WHERE idEmpleado = @idEmpleadoDesasociado
                        AND idTipoDeduccion = @idTipoDeduccionDesasociada
                        AND fechaDesasociacion IS NULL;

                        PRINT ' Deducción desasociada para empleado ' + @valorDocDesasociacion;
                    END

                    -- Limpieza
                    SET @idEmpleadoDesasociado = NULL;

                    SET @iDesasociacion += 1;
                END
            END

        END

        ------------------------------
        -- ETIQUETA: EliminarEmpleados
        ------------------------------
        IF @xmlOperacion.exist('/Operacion/FechaOperacion[@Fecha=sql:variable("@fechaActual")]/EliminarEmpleados/EliminarEmpleado') = 1
        BEGIN
            PRINT ' Eliminando empleados...';


            -- Limpieza previa
            DELETE FROM @eliminacionesXML;
            SET @xmlBloqueEliminaciones = NULL;

            -- Extraer bloque de eliminación de empleados
            SET @xmlBloqueEliminaciones = @xmlOperacion.query('
                /Operacion
                /FechaOperacion[@Fecha=sql:variable("@fechaActual")]
                /EliminarEmpleados
            ');

            IF @xmlBloqueEliminaciones.exist('/EliminarEmpleados/EliminarEmpleado') = 1
            BEGIN
                PRINT ' Eliminando empleados...';

                -- Llenar tabla con documentos del XML
                INSERT INTO @eliminacionesXML (
                    valorDocumento
                )
                SELECT
                    nodo.value('@ValorTipoDocumento', 'VARCHAR(30)')
                FROM @xmlBloqueEliminaciones.nodes('/EliminarEmpleados/EliminarEmpleado') AS T(nodo);

                SET @iEliminar = 1;
                SET @totalEliminaciones = (SELECT COUNT(*) FROM @eliminacionesXML);

                WHILE @iEliminar <= @totalEliminaciones
                BEGIN
                    -- Obtener documento de la fila actual
                    SELECT @valorDocEliminar = valorDocumento
                    FROM (
                        SELECT 
                            valorDocumento,
                            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS fila
                        FROM @eliminacionesXML
                    ) AS filaEliminar
                    WHERE fila = @iEliminar;

                    -- Buscar ID del empleado
                    SELECT @idEmpleadoEliminar = id
                    FROM dbo.Empleado
                    WHERE valorDocumento = @valorDocEliminar
                    AND activo = 1;

                    IF @idEmpleadoEliminar IS NULL
                    BEGIN
                        PRINT '  Empleado con documento "' + @valorDocEliminar + '" no encontrado o ya inactivo. Eliminación omitida.';
                    END
                    ELSE
                    BEGIN
                        -- Ejecutar SP de eliminación lógica
                        EXEC dbo.SP_EliminarEmpleadoSimulacion
                            @inId             = @idEmpleadoEliminar,
                            @inIdPostByUser   = 1,
                            @inPostInIP       = 'SIMULACION',
                            @outResultCode    = @resultadoEliminarSP OUTPUT;

                        IF @resultadoEliminarSP = 0
                        BEGIN
                            PRINT ' Empleado eliminado lógicamente: ' + @valorDocEliminar;
                        END
                        ELSE
                        BEGIN
                            PRINT ' Error al eliminar empleado ' + @valorDocEliminar + 
                                ' | Código: ' + CAST(@resultadoEliminarSP AS VARCHAR);
                        END
                    END

                    -- Limpieza
                    SET @idEmpleadoEliminar = NULL;
                    SET @resultadoEliminarSP = NULL;

                    SET @iEliminar += 1;
                END
            END

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
    PRINT ' Error!!: ' + @Error;
END CATCH

SET NOCOUNT OFF;