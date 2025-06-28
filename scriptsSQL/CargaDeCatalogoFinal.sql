SET NOCOUNT ON;

DECLARE @xmlCatalogo XML;

---Se obtiene el XML del catalogo y de la operacion ya guardados en la tabla dbo.XMLSimulacion
SELECT @xmlCatalogo = CAST(contenidoXML AS XML)
FROM dbo.XMLSimulacion
WHERE nombreXML = 'Catalogo';



--- Carga de catalogo

BEGIN TRY
    BEGIN TRANSACTION;

    -------------------------------------------------------------
    -- BLOQUE 1: TipoDocumento
    -------------------------------------------------------------


    INSERT INTO dbo.TipoDocumento (
        id,
        nombre
    )
    SELECT
        T.Doc.value('@Id', 'INT'),
        T.Doc.value('@Nombre', 'VARCHAR(50)')
    FROM
        @xmlCatalogo.nodes('/Catalogo/TiposdeDocumentodeIdentidad/TipoDocuIdentidad') AS T(Doc) --- Se asocia el nodo TipoDocuIdentidad
    --- Se extraen los atributos Id y Nombre del nodo TipoDocuIdentidad
    WHERE
        NOT EXISTS (
            SELECT 1
            FROM dbo.TipoDocumento TD
            WHERE TD.id = T.Doc.value('@Id', 'INT')
        ); --- Verifica si ya existe el TipoDocumento con ese ID

    -------------------------------------------------------------
    -- BLOQUE 2: TipoJornada
    -------------------------------------------------------------

    INSERT INTO dbo.TipoJornada (
        id,
        nombre,
        horaInicio,
        horaFin
    )
    SELECT
        T.J.value('@Id', 'INT'),
        T.J.value('@Nombre', 'VARCHAR(50)'),
        T.J.value('@HoraInicio', 'TIME'),
        T.J.value('@HoraFin', 'TIME')
    FROM
        @xmlCatalogo.nodes('/Catalogo/TiposDeJornada/TipoDeJornada') AS T(J) --- Se asocia el nodo TipoDeJornada
    --- Se extraen los atributos Id, Nombre, HoraInicio y HoraFin del nodo Tipo
    WHERE
        NOT EXISTS (
            SELECT 1
            FROM dbo.TipoJornada TJ
            WHERE TJ.id = T.J.value('@Id', 'INT')
        );


    -------------------------------------------------------------
    -- BLOQUE 3: Departamento
    -------------------------------------------------------------
    INSERT INTO dbo.Departamento (
        id,
        nombre
    )
    SELECT
        T.D.value('@Id', 'INT'),
        T.D.value('@Nombre', 'VARCHAR(100)')
    FROM
        @xmlCatalogo.nodes('/Catalogo/Departamentos/Departamento') AS T(D) --- Se asocia el nodo Departamento
    --- Se extraen los atributos Id y Nombre del nodo Departamento
    WHERE
        NOT EXISTS (
            SELECT 1
            FROM dbo.Departamento DP
            WHERE DP.id = T.D.value('@Id', 'INT')
        );

    -------------------------------------------------------------
    -- BLOQUE 4: Feriado
    -------------------------------------------------------------
    INSERT INTO dbo.Feriado (
        id,
        nombre,
        fecha
    )
    SELECT
        T.F.value('@Id', 'INT'),
        T.F.value('@Nombre', 'VARCHAR(100)'),
        T.F.value('@Fecha', 'DATE')
    FROM
        @xmlCatalogo.nodes('/Catalogo/Feriados/Feriado') AS T(F) --- Se asocia el nodo Feriado
    --- Se extraen los atributos Id, Nombre y Fecha del nodo Feriado
    WHERE
        NOT EXISTS (
            SELECT 1
            FROM dbo.Feriado FR
            WHERE FR.id = T.F.value('@Id', 'INT')
        );

    -------------------------------------------------------------
    -- BLOQUE 5: TipoMovimiento
    -------------------------------------------------------------
    INSERT INTO dbo.TipoMovimiento (
        id,
        nombre
    )
    SELECT
        T.M.value('@Id', 'INT'),
        T.M.value('@Nombre', 'VARCHAR(100)')
    FROM
        @xmlCatalogo.nodes('/Catalogo/TiposDeMovimiento/TipoDeMovimiento') AS T(M) --- Se asocia el nodo TipoDeMovimiento
    --- Se extraen los atributos Id y Nombre del nodo TipoDeMovimiento
    WHERE
        NOT EXISTS (
            SELECT 1
            FROM dbo.TipoMovimiento TM
            WHERE TM.id = T.M.value('@Id', 'INT')
        );

    -------------------------------------------------------------
    -- BLOQUE 6: TipoDeduccion
    -------------------------------------------------------------
    INSERT INTO dbo.TipoDeduccion (
        id,
        nombre,
        obligatorio,
        porcentual,
        valor
    )
    SELECT
        T.D.value('@Id', 'INT'),
        T.D.value('@Nombre', 'VARCHAR(100)'),
        CASE T.D.value('@Obligatorio', 'VARCHAR(2)') WHEN 'Si' THEN 1 ELSE 0 END, --- Convierte 'Si' a 1 y cualquier otro valor a 0
        CASE T.D.value('@Porcentual', 'VARCHAR(2)') WHEN 'Si' THEN 1 ELSE 0 END, --- Convierte 'Si' a 1 y cualquier otro valor a 0
        T.D.value('@Valor', 'FLOAT')
    FROM
        @xmlCatalogo.nodes('/Catalogo/TiposDeDeduccion/TipoDeDeduccion') AS T(D) --- Se asocia el nodo TipoDeDeduccion
    --- Se extraen los atributos Id, Nombre, Obligatorio, Porcentual y Valor
    WHERE
        NOT EXISTS (
            SELECT 1
            FROM dbo.TipoDeduccion TD
            WHERE TD.id = T.D.value('@Id', 'INT')
        );

    -------------------------------------------------------------
    -- BLOQUE 7: TipoEvento
    -------------------------------------------------------------
    INSERT INTO dbo.TipoEvento (
        id,
        nombre
    )
    SELECT
        T.E.value('@Id', 'INT'),
        T.E.value('@Nombre', 'VARCHAR(100)')
    FROM
        @xmlCatalogo.nodes('/Catalogo/TiposdeEvento/TipoEvento') AS T(E) --- Se asocia el nodo TipoEvento
    --- Se extraen los atributos Id y Nombre del nodo TipoEvento
    WHERE
        NOT EXISTS (
            SELECT 1
            FROM dbo.TipoEvento TE
            WHERE TE.id = T.E.value('@Id', 'INT')
        );

    -------------------------------------------------------------
    -- BLOQUE 8: Puestos (inserción por nombre, sin ID)
    -------------------------------------------------------------
    INSERT INTO dbo.Puesto (
        nombre,
        salarioPorHora
    )
    SELECT
        T.P.value('@Nombre', 'VARCHAR(100)'),
        T.P.value('@SalarioXHora', 'FLOAT')
    FROM
        @xmlCatalogo.nodes('/Catalogo/Puestos/Puesto') AS T(P) --- Se asocia el nodo Puesto
    --- Se extraen los atributos Nombre y SalarioXHora del nodo Puesto
    WHERE
        NOT EXISTS (
            SELECT 1
            FROM dbo.Puesto PO
            WHERE PO.nombre = T.P.value('@Nombre', 'VARCHAR(100)')
        );

    -------------------------------------------------------------
    -- BLOQUE 9: Usuarios (con id, tipo y esAdministrador en 0)
    -------------------------------------------------------------
    
    SET IDENTITY_INSERT dbo.Usuario ON; -- permitir inserción de ID explícito
    INSERT INTO dbo.Usuario (
        id,
        username,
        passwordHash,
        tipo,
        esAdministrador
    )
    SELECT
        T.U.value('@Id', 'INT'),
        T.U.value('@Username', 'VARCHAR(100)'),
        T.U.value('@Password', 'VARCHAR(100)'),
        T.U.value('@Tipo', 'INT'),
        0  -- se actualizará después según UsuariosAdministradores
    FROM
        @xmlCatalogo.nodes('/Catalogo/Usuarios/Usuario') AS T(U) --- Se asocia el nodo Usuario
    --- Se extraen los atributos Id, Username, Password, Tipo y se establece esAdministrador
    WHERE
        NOT EXISTS (
            SELECT 1
            FROM dbo.Usuario US
            WHERE US.id = T.U.value('@Id', 'INT')
        );

    SET IDENTITY_INSERT dbo.Usuario OFF; -- restaurar comportamiento normal de IDENTITY
    -------------------------------------------------------------
    -- BLOQUE 10: UsuariosAdministradores (update posterior)
    -------------------------------------------------------------
    UPDATE U
    SET U.esAdministrador = 1
    FROM dbo.Usuario U
    INNER JOIN @xmlCatalogo.nodes('/Catalogo/UsuariosAdministradores/UsuarioAdministrador') AS T(X) --- Se asocia el nodo UsuarioAdministrador
    --- Se extraen los atributos IdUsuario del nodo UsuarioAdministrador
        ON U.id = T.X.value('@IdUsuario', 'INT'); 
    --- Actualiza el campo esAdministrador a 1 para los usuarios que son administradores, según el XML


    -------------------------------------------------------------
    -- BLOQUE 11: Empleados (inserción con mapeo a Puesto)
    -------------------------------------------------------------

    -- Tabla intermedia con los empleados desde el XML
    DECLARE @EmpleadosTemp TABLE (
        idUsuario INT,
        nombreCompleto VARCHAR(100),
        valorDocumento VARCHAR(30),
        fechaNacimiento DATE,
        activo BIT,
        idTipoDocumento INT,
        idDepartamento INT,
        nombrePuesto VARCHAR(100)
    ); --- Se le definen las columnas que se van a insertar desde el XML

    -- Cargar XML a tabla temporal
    INSERT INTO @EmpleadosTemp
    SELECT
        T.E.value('@IdUsuario', 'INT'),
        T.E.value('@Nombre', 'VARCHAR(100)'),
        T.E.value('@ValorDocumento', 'VARCHAR(30)'),
        T.E.value('@FechaNacimiento', 'DATE'),
        T.E.value('@Activo', 'BIT'),
        T.E.value('@IdTipoDocumento', 'INT'),
        T.E.value('@IdDepartamento', 'INT'),
        T.E.value('@NombrePuesto', 'VARCHAR(100)')
    FROM
        @xmlCatalogo.nodes('/Catalogo/Empleados/Empleado') AS T(E); --- Se asocia el nodo Empleado
    --- Se extraen los atributos IdUsuario, Nombre, ValorDocumento, FechaNacimiento, Activo, IdTipoDocumento, IdDepartamento y NombrePuesto del nodo Empleado

    -- Mapeo para capturar el id generado
    DECLARE @EmpleadoMapeo TABLE (
        idUsuario INT,
        valorDocumento VARCHAR(30),
        idEmpleado INT
    ); --- esta tabla variable se usará para mapear el idUsuario y el valorDocumento con el idEmpleado generado

    -- MERGE con salida controlada, un merge es útil para manejar inserciones y actualizaciones en una sola operación.
    -- En este caso, se usa para insertar nuevos empleados que no existen en la tabla dbo.Empleado.
    -- Se usa un MERGE con una condición que siempre es falsa (1=0), esto para forzar que solo se realicen inserciones y no actualizaciones.
    MERGE dbo.Empleado AS target
    USING (
        SELECT
            ET.idUsuario,
            ET.valorDocumento,
            ET.nombreCompleto,
            ET.fechaNacimiento,
            ET.activo,
            ET.idTipoDocumento,
            ET.idDepartamento,
            P.id AS idPuesto
        FROM @EmpleadosTemp ET
        INNER JOIN dbo.Puesto P
            ON P.nombre = ET.nombrePuesto
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.Empleado E
            WHERE E.valorDocumento = ET.valorDocumento
        )
    ) AS source
    ON 1 = 0 --- condicion que siempre sera falsa para forzar inserciones

    WHEN NOT MATCHED THEN
        INSERT (
            nombreCompleto,
            valorDocumento,
            fechaNacimiento,
            activo,
            idTipoDocumento,
            idDepartamento,
            idPuesto
        ) --- si no hay coincidencia, inserta un nuevo empleado
        VALUES (
            source.nombreCompleto,
            source.valorDocumento,
            source.fechaNacimiento,
            source.activo,
            source.idTipoDocumento,
            source.idDepartamento,
            source.idPuesto
        ) --- se insertan los valores del empleado desde la tabla variable @EmpleadosTemp

    OUTPUT --- devuelve los valores insertados para mapearlos en la tabla @EmpleadoMapeo
        source.idUsuario,
        source.valorDocumento,
        inserted.id
    INTO @EmpleadoMapeo (idUsuario, valorDocumento, idEmpleado); 


    -------------------------------------------------------------
    -- BLOQUE 12: Asignar idEmpleado a cada Usuario
    -------------------------------------------------------------

    -- Actualizar la tabla Usuario con el idEmpleado correspondiente
    -- Se usa la tabla @EmpleadoMapeo para relacionar los usuarios con los empleados como se especifica en el XML
    UPDATE U
    SET U.idEmpleado = M.idEmpleado
    FROM dbo.Usuario U
    INNER JOIN @EmpleadoMapeo M
        ON U.id = M.idUsuario;

    -------------------------------------------------------------
    -- BLOQUE 13: Errores
    -------------------------------------------------------------
    INSERT INTO dbo.Error (
        codigo,
        descripcion
    )
    SELECT
        T.E.value('@Codigo', 'INT'),
        T.E.value('@Descripcion', 'VARCHAR(255)')
    FROM
        @xmlCatalogo.nodes('/Catalogo/Errores/Error') AS T(E) --- Se asocia el nodo Error
    --- Se extraen los atributos Codigo y Descripcion del nodo Error
    WHERE
        NOT EXISTS (
            SELECT 1
            FROM dbo.Error ER
            WHERE ER.codigo = T.E.value('@Codigo', 'INT')
        ); --- Verifica si ya existe el Error con ese Codigo

    COMMIT; --- Si todo se ejecuta correctamente , se confirma la transacción

END TRY 
--- Manejo de errores
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK; --- Si hay una transacción abierta, se revierte
    THROW;
END CATCH;
SET NOCOUNT OFF;
