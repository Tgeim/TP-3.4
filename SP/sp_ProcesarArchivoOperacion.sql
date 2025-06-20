/****** Object:  StoredProcedure [dbo].[sp_ProcesarArchivoOperacion]    Script Date: 12/6/2025 18:11:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_ProcesarArchivoOperacion]
    @xmlOperacion XML
AS
BEGIN
    SET NOCOUNT ON;

    -- Obtener todas las fechas únicas del xml
    DECLARE @FechasOperacion TABLE (Fecha DATE PRIMARY KEY);

    INSERT INTO @FechasOperacion (Fecha)
    SELECT DISTINCT T.Nodos.value('@Fecha', 'DATE')
    FROM @xmlOperacion.nodes('/Operacion/FechaOperacion') AS T(Nodos);

    DECLARE 
        @ProcesandoFecha DATE,
        @DiaSiguiente DATE,
        @doc NVARCHAR(20),
        @dedu INT,
        @monto DECIMAL(10,2),
        @ent DATETIME,
        @sal DATETIME,
        @rc INT,
        @msg NVARCHAR(500),
        @Nombre NVARCHAR(100),
        @IdTipoDocumento INT,
        @ValorDocumento NVARCHAR(20),
        @FechaNacimiento DATE,
        @IdDepartamento INT,
        @NombrePuesto NVARCHAR(100),
        @Usuario NVARCHAR(100),
        @Password NVARCHAR(100),
        @IdPuesto INT,
        @IdEmpleadoEliminar INT;

    WHILE EXISTS (SELECT 1 FROM @FechasOperacion)
    BEGIN
        SELECT TOP 1 @ProcesandoFecha = Fecha FROM @FechasOperacion ORDER BY Fecha;
        SET @DiaSiguiente = DATEADD(DAY, 1, @ProcesandoFecha);

        -- Apertura de semana (con el SP correcto y parámetro)
        EXEC sp_AperturaSemana @FechaOperacion = @ProcesandoFecha;

        -- Apertura de mes si es jueves y el siguiente día es el primer viernes
        IF DATENAME(WEEKDAY, @ProcesandoFecha) = 'Thursday'
        BEGIN
            IF DAY(@DiaSiguiente) <= 7 AND DATENAME(WEEKDAY, @DiaSiguiente) = 'Friday'
            BEGIN
                EXEC sp_AperturaMes @FechaOperacion = @ProcesandoFecha;
            END
        END

        -- Obtener XML de la fecha procesada
        DECLARE @xmlFecha XML;
        SELECT @xmlFecha = T.Nodos.query('.') 
        FROM @xmlOperacion.nodes('/Operacion/FechaOperacion[@Fecha=sql:variable("@ProcesandoFecha")]') AS T(Nodos);

        ----------------------------
        -- NUEVOS EMPLEADOS
        ----------------------------
        DECLARE @NuevosEmpleados TABLE (
            Nombre NVARCHAR(100),
            IdTipoDocumento INT,
            ValorDocumento NVARCHAR(20),
            FechaNacimiento DATE,
            IdDepartamento INT,
            NombrePuesto NVARCHAR(100),
            Usuario NVARCHAR(100),
            Contrasena NVARCHAR(100)
        );

        INSERT INTO @NuevosEmpleados
        SELECT
            E.Nodos.value('@Nombre', 'NVARCHAR(100)'),
            E.Nodos.value('@IdTipoDocumento', 'INT'),
            E.Nodos.value('@ValorTipoDocumento', 'NVARCHAR(20)'),
            E.Nodos.value('@FechaNacimiento', 'DATE'),
            E.Nodos.value('@IdDepartamento', 'INT'),
            E.Nodos.value('@NombrePuesto', 'NVARCHAR(100)'),
            E.Nodos.value('@Usuario', 'NVARCHAR(100)'),
            E.Nodos.value('@Password', 'NVARCHAR(100)')
        FROM @xmlFecha.nodes('/FechaOperacion/NuevosEmpleados/NuevoEmpleado') AS E(Nodos);

        WHILE EXISTS (SELECT 1 FROM @NuevosEmpleados)
        BEGIN
            SELECT TOP 1 
                @Nombre = Nombre,
                @IdTipoDocumento = IdTipoDocumento,
                @ValorDocumento = ValorDocumento,
                @FechaNacimiento = FechaNacimiento,
                @IdDepartamento = IdDepartamento,
                @NombrePuesto = NombrePuesto,
                @Usuario = Usuario,
                @Password = Contrasena
            FROM @NuevosEmpleados;

            SELECT @IdPuesto = Id FROM Puesto WHERE Nombre = @NombrePuesto;

            IF @IdPuesto IS NOT NULL
            BEGIN
                EXEC dbo.sp_InsertarEmpleado
                    @inNombre = @Nombre,
                    @inIdTipoDocumento = @IdTipoDocumento,
                    @inValorDocumento = @ValorDocumento,
                    @inFechaNacimiento = @FechaNacimiento,
                    @inIdDepartamento = @IdDepartamento,
                    @inIdPuesto = @IdPuesto,
                    @inUsername = @Usuario,
                    @inPassword = @Password,
                    @inIdUsuarioEjecutor = 5,
                    @inIPDireccion = '127.0.0.1',
                    @outResultCode = @rc OUTPUT,
                    @outMessage = @msg OUTPUT;
            END

            DELETE FROM @NuevosEmpleados WHERE ValorDocumento = @ValorDocumento;
        END

        ----------------------------
        -- ELIMINAR EMPLEADOS
        ----------------------------
        DECLARE @Eliminaciones TABLE (ValorDocumento NVARCHAR(20));

        INSERT INTO @Eliminaciones
        SELECT D.Nodos.value('@ValorTipoDocumento', 'NVARCHAR(20)')
        FROM @xmlFecha.nodes('/FechaOperacion/EliminarEmpleados/EliminarEmpleado') AS D(Nodos);

        WHILE EXISTS (SELECT 1 FROM @Eliminaciones)
        BEGIN
            SELECT TOP 1 @doc = ValorDocumento FROM @Eliminaciones;
            SELECT @IdEmpleadoEliminar = Id FROM Empleado WHERE ValorDocumento = @doc AND Activo = 1;

            IF @IdEmpleadoEliminar IS NOT NULL
            BEGIN
                EXEC dbo.sp_EliminarEmpleado
                    @inIdEmpleado = @IdEmpleadoEliminar,
                    @inIdUsuarioEjecutor = 5,
                    @inIP = '127.0.0.1',
                    @outResultCode = @rc OUTPUT,
                    @outMessage = @msg OUTPUT;
            END

            DELETE FROM @Eliminaciones WHERE ValorDocumento = @doc;
        END

        ----------------------------
        -- ASOCIAR DEDUCCIONES
        ----------------------------
        DECLARE @Asociaciones TABLE (ValorDocumento NVARCHAR(20), IdTipoDeduccion INT, Monto DECIMAL(10,2));
        INSERT INTO @Asociaciones
        SELECT
            D.Nodos.value('@ValorTipoDocumento', 'NVARCHAR(20)'),
            D.Nodos.value('@IdTipoDeduccion', 'INT'),
            D.Nodos.value('@Monto', 'DECIMAL(10,2)')
        FROM @xmlFecha.nodes('/FechaOperacion/AsociacionEmpleadoDeducciones/AsociacionEmpleadoConDeduccion') AS D(Nodos);

        WHILE EXISTS (SELECT 1 FROM @Asociaciones)
        BEGIN
            SELECT TOP 1 @doc = ValorDocumento, @dedu = IdTipoDeduccion, @monto = Monto FROM @Asociaciones;
            EXEC SP_AsociarEmpleadoDeduccion
                @inValorDocumento = @doc,
                @inIdTipoDeduccion = @dedu,
                @inMontoFijoMensual = @monto,
                @inFechaOperacion = @ProcesandoFecha;
            DELETE FROM @Asociaciones WHERE ValorDocumento = @doc AND IdTipoDeduccion = @dedu;
        END

        ----------------------------
        -- DESASOCIAR DEDUCCIONES
        ----------------------------
        DECLARE @Desasociaciones TABLE (ValorDocumento NVARCHAR(20), IdTipoDeduccion INT);
        INSERT INTO @Desasociaciones
        SELECT
            D.Nodos.value('@ValorTipoDocumento', 'NVARCHAR(20)'),
            D.Nodos.value('@IdTipoDeduccion', 'INT')
        FROM @xmlFecha.nodes('/FechaOperacion/DesasociacionEmpleadoDeducciones/DesasociacionEmpleadoConDeduccion') AS D(Nodos);

        WHILE EXISTS (SELECT 1 FROM @Desasociaciones)
        BEGIN
            SELECT TOP 1 @doc = ValorDocumento, @dedu = IdTipoDeduccion FROM @Desasociaciones;
            EXEC SP_DesasociarEmpleadoDeduccion
                @inValorDocumento = @doc,
                @inIdTipoDeduccion = @dedu,
                @inFechaOperacion = @ProcesandoFecha;

            DELETE FROM @Desasociaciones WHERE ValorDocumento = @doc AND IdTipoDeduccion = @dedu;
        END

        ----------------------------
        -- REGISTRAR JORNADAS PARA PRÓXIMA SEMANA
        ----------------------------
        IF DATENAME(WEEKDAY, @ProcesandoFecha) = 'Thursday' -- verifica que sea jueves
        BEGIN
            DECLARE @Jornadas TABLE 
            (
                ValorDocumento NVARCHAR(20),
                IdTipoJornada INT
            );

            INSERT INTO @Jornadas
            SELECT 
                J.Nodos.value('@ValorTipoDocumento', 'NVARCHAR(20)'),
                J.Nodos.value('@IdTipoJornada', 'INT')
            FROM @xmlFecha.nodes('/FechaOperacion/JornadasProximaSemana/TipoJornadaProximaSemana') AS J(Nodos);

            WHILE EXISTS (SELECT 1 FROM @Jornadas) -- Va registrando cada jornada en un ciclo
            BEGIN
                SELECT TOP 1 @doc = ValorDocumento, @dedu = IdTipoJornada FROM @Jornadas;

                EXEC SP_AsignarJornadaEmpleado
                    @inValorDocumentoEmpleado = @doc,
                    @inFechaInicioSemana = @ProcesandoFecha,  
                    @inIdTipoJornada = @dedu,
                    @inIdPostByUser = 5,
                    @inPostInIP = '127.0.0.1',
                    @outResultCode = @rc OUTPUT;

                DELETE FROM @Jornadas WHERE ValorDocumento = @doc AND IdTipoJornada = @dedu;
            END
        END

        ----------------------------
        -- MARCAS DE ASISTENCIA
        ----------------------------
        DECLARE @Asistencias TABLE (ValorDocumento NVARCHAR(20), HoraEntrada DATETIME, HoraSalida DATETIME);
        INSERT INTO @Asistencias
        SELECT
            M.Nodos.value('@ValorTipoDocumento', 'NVARCHAR(20)'),
            M.Nodos.value('@HoraEntrada', 'DATETIME'),
            M.Nodos.value('@HoraSalida', 'DATETIME')
        FROM @xmlFecha.nodes('/FechaOperacion/MarcasAsistencia/MarcaDeAsistencia') AS M(Nodos);

        WHILE EXISTS (SELECT 1 FROM @Asistencias)
        BEGIN
            SELECT TOP 1 @doc = ValorDocumento, @ent = HoraEntrada, @sal = HoraSalida FROM @Asistencias;
            EXEC SP_RegistrarMarcaAsistencia @inValorDocumento = @doc, @inHoraEntrada = @ent, @inHoraSalida = @sal;
            DELETE FROM @Asistencias WHERE ValorDocumento = @doc AND HoraEntrada = @ent;
        END

        ----------------------------
        -- CIERRE SEMANAL SI ES JUEVES
        ----------------------------
        IF DATENAME(WEEKDAY, @ProcesandoFecha) = 'Thursday'
        BEGIN
            EXEC SP_CerrarSemanaPlanilla
                @inFechaJueves = @ProcesandoFecha,
                @inIdPostByUser = 5,
                @inPostInIP = '127.0.0.1',
                @outResultCode = @rc OUTPUT;
        END

        -- Quitar fecha procesada
        DELETE FROM @FechasOperacion WHERE Fecha = @ProcesandoFecha;
    END
END
GO
