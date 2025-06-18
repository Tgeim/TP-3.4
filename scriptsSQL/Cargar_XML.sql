-- SCRIPT DE CARGA DE CATÁLOGOS - VERSIÓN FINAL
-- ===================================================================

-- *** CORRECCIÓN FINAL: MANEJO SEGURO DEL CONTEXTO DE USUARIO ***
-- Se establece el contexto de la sesión para que los triggers de bitácora funcionen.

DECLARE @IdUsuarioParaBitacora INT;
DECLARE @AdminUsername VARCHAR(50) = 'Sistema'; -- Usuario prioritario para procesos automáticos

-- Intentar obtener el ID del usuario del sistema
SELECT @IdUsuarioParaBitacora = id FROM dbo.Usuario WHERE username = @AdminUsername;

-- Si no existe, como plan B, buscar al usuario 'Goku' (que se insertará desde el XML)
IF @IdUsuarioParaBitacora IS NULL
BEGIN
    PRINT 'INFO: Usuario "Sistema" no encontrado. Buscando usuario "Goku" como alternativa.';
    SELECT @IdUsuarioParaBitacora = id FROM dbo.Usuario WHERE username = 'Goku';
END

-- Solo establecer el contexto si se encontró un ID de usuario válido
IF @IdUsuarioParaBitacora IS NOT NULL
BEGIN
    PRINT 'INFO: Estableciendo contexto para el usuario con ID: ' + CAST(@IdUsuarioParaBitacora AS VARCHAR);
    DECLARE @Contexto VARBINARY(128) = CAST(@IdUsuarioParaBitacora AS VARBINARY(128));
    SET CONTEXT_INFO @Contexto;
END
ELSE
BEGIN
    PRINT 'ADVERTENCIA: No se encontró un usuario "Sistema" o "Goku" para establecer el contexto. Los triggers de bitácora podrían fallar si no manejan un contexto nulo.';
END
GO -- Separa el lote para asegurar que el contexto se aplique

BEGIN TRY

-- DECLARACIÓN XML
DECLARE @xml XML = '<?xml version="1.0" ?>
<Catalogo>
  <TiposdeDocumentodeIdentidad>
    <TipoDocuIdentidad Id="1" Nombre="Cedula Nacional"/>
    <TipoDocuIdentidad Id="2" Nombre="Cedula Residente"/>
    <TipoDocuIdentidad Id="3" Nombre="Pasaporte"/>
    <TipoDocuIdentidad Id="4" Nombre="Cedula Juridica"/>
    <TipoDocuIdentidad Id="5" Nombre="Permiso de Trabajo"/>
    <TipoDocuIdentidad Id="6" Nombre="Cedula Extranjera"/>
  </TiposdeDocumentodeIdentidad>
  <TiposDeJornada>
    <TipoDeJornada Id="1" Nombre="Diurno" HoraInicio="06:00" HoraFin="14:00"/>
    <TipoDeJornada Id="2" Nombre="Vespertino" HoraInicio="14:00" HoraFin="22:00"/>
    <TipoDeJornada Id="3" Nombre="Nocturno" HoraInicio="22:00" HoraFin="06:00"/>
  </TiposDeJornada>
  <Puestos>
    <Puesto Nombre="Electricista" SalarioXHora="1200"/>
    <Puesto Nombre="Auxiliar de Laboratorio" SalarioXHora="1250"/>
    <Puesto Nombre="Operador de Maquina" SalarioXHora="1025"/>
    <Puesto Nombre="Soldador" SalarioXHora="1350"/>
    <Puesto Nombre="Tecnico de Mantenimiento" SalarioXHora="1400"/>
    <Puesto Nombre="Bodeguero" SalarioXHora="950"/>
  </Puestos>
  <Departamentos>
    <Departamento Id="1" Nombre="Enlaminado"/>
    <Departamento Id="2" Nombre="Laboratorio"/>
    <Departamento Id="3" Nombre="Bodega de materiales"/>
    <Departamento Id="4" Nombre="Bodega de producto terminado"/>
  </Departamentos>
  <Feriados>
    <Feriado Id="1" Nombre="Día de Año Nuevo" Fecha="20230101"/>
    <Feriado Id="2" Nombre="Día de Juan Santamaría" Fecha="20230411"/>
    <Feriado Id="3" Nombre="Jueves Santo" Fecha="20230406"/>
    <Feriado Id="4" Nombre="Viernes Santo" Fecha="20230407"/>
    <Feriado Id="5" Nombre="Día del Trabajo" Fecha="20230501"/>
    <Feriado Id="6" Nombre="Anexión del Partido de Nicoya" Fecha="20230725"/>
    <Feriado Id="7" Nombre="Día de la Virgen de los Ángeles" Fecha="20230802"/>
    <Feriado Id="8" Nombre="Día de la Madre" Fecha="20230815"/>
    <Feriado Id="9" Nombre="Día de la Independencia" Fecha="20230915"/>
    <Feriado Id="10" Nombre="Día de las Culturas" Fecha="20231012"/>
    <Feriado Id="11" Nombre="Navidad" Fecha="20231225"/>
  </Feriados>
  <TiposDeMovimiento>
    <TipoDeMovimiento Id="1" Nombre="Credito Horas ordinarias"/>
    <TipoDeMovimiento Id="2" Nombre="Credito Horas Extra Normales"/>
    <TipoDeMovimiento Id="3" Nombre="Credito Horas Extra Dobles"/>
    <TipoDeMovimiento Id="4" Nombre="Debito Deducciones de Ley"/>
    <TipoDeMovimiento Id="5" Nombre="Debito Deduccion No Obligatoria"/>
  </TiposDeMovimiento>
  <TiposDeDeduccion>
    <TipoDeDeduccion Id="1" Nombre="Obligatorio de Ley" Obligatorio="Si" Porcentual="Si" Valor="0.095"/>
    <TipoDeDeduccion Id="2" Nombre="Ahorro Asociacion Solidarista" Obligatorio="No" Porcentual="Si" Valor="0.05"/>
    <TipoDeDeduccion Id="3" Nombre="Ahorro Vacacional" Obligatorio="No" Porcentual="No" Valor="0"/>
    <TipoDeDeduccion Id="4" Nombre="Pension Alimenticia" Obligatorio="No" Porcentual="No" Valor="0"/>
  </TiposDeDeduccion>
  <Errores>
    <Error Codigo="50001" Descripcion="Username no existe"/>
    <Error Codigo="50002" Descripcion="Password no existe"/>
    <Error Codigo="50003" Descripcion="Login deshabilitado"/>
    <Error Codigo="50004" Descripcion="Empleado con ValorDocumentoIdentidad ya existe en inserción"/>
    <Error Codigo="50005" Descripcion="Empleado con mismo nombre ya existe en inserción"/>
    <Error Codigo="50006" Descripcion="Empleado con ValorDocumentoIdentidad ya existe en actualización"/>
    <Error Codigo="50007" Descripcion="Empleado con mismo nombre ya existe en actualización"/>
    <Error Codigo="50008" Descripcion="Error de base de datos"/>
    <Error Codigo="50009" Descripcion="Nombre de empleado no alfabético"/>
    <Error Codigo="50010" Descripcion="Valor de documento de identidad no alfabético"/>
  </Errores>
  <Usuarios>
    <Usuario Id="1" Username="Goku" Password="1234" Tipo="1"/>
    <Usuario Id="2" Username="Willy" Password="1234" Tipo="1"/>
    <Usuario Id="3" Username="Pepe" Password="1234" Tipo="2"/>
    <Usuario Id="4" Username="Lola" Password="1234" Tipo="2"/>
    <Usuario Id="5" Username="SinNombre" Password="script" Tipo="3"/>
    <Usuario Id="6" Username="emp1" Password="1234" Tipo="2"/>
    <Usuario Id="7" Username="emp2" Password="1234" Tipo="2"/>
    <Usuario Id="8" Username="emp3" Password="1234" Tipo="2"/>
    <Usuario Id="9" Username="emp4" Password="1234" Tipo="2"/>
    <Usuario Id="10" Username="emp5" Password="1234" Tipo="2"/>
    <Usuario Id="11" Username="emp6" Password="1234" Tipo="2"/>
    <Usuario Id="12" Username="emp7" Password="1234" Tipo="2"/>
    <Usuario Id="13" Username="emp8" Password="1234" Tipo="2"/>
    <Usuario Id="14" Username="emp9" Password="1234" Tipo="2"/>
    <Usuario Id="15" Username="emp10" Password="1234" Tipo="2"/>
    <Usuario Id="16" Username="emp11" Password="1234" Tipo="2"/>
    <Usuario Id="17" Username="emp12" Password="1234" Tipo="2"/>
    <Usuario Id="18" Username="emp13" Password="1234" Tipo="2"/>
    <Usuario Id="19" Username="emp14" Password="1234" Tipo="2"/>
    <Usuario Id="20" Username="emp15" Password="1234" Tipo="2"/>
    <Usuario Id="21" Username="emp16" Password="1234" Tipo="2"/>
    <Usuario Id="22" Username="emp17" Password="1234" Tipo="2"/>
    <Usuario Id="23" Username="emp18" Password="1234" Tipo="2"/>
    <Usuario Id="24" Username="emp19" Password="1234" Tipo="2"/>
    <Usuario Id="25" Username="emp20" Password="1234" Tipo="2"/>
    <Usuario Id="26" Username="emp21" Password="1234" Tipo="2"/>
    <Usuario Id="27" Username="emp22" Password="1234" Tipo="2"/>
    <Usuario Id="28" Username="emp23" Password="1234" Tipo="2"/>
    <Usuario Id="29" Username="emp24" Password="1234" Tipo="2"/>
    <Usuario Id="30" Username="emp25" Password="1234" Tipo="2"/>
    <Usuario Id="31" Username="emp26" Password="1234" Tipo="2"/>
    <Usuario Id="32" Username="emp27" Password="1234" Tipo="2"/>
    <Usuario Id="33" Username="emp28" Password="1234" Tipo="2"/>
    <Usuario Id="34" Username="emp29" Password="1234" Tipo="2"/>
    <Usuario Id="35" Username="emp30" Password="1234" Tipo="2"/>
    <Usuario Id="36" Username="emp31" Password="1234" Tipo="2"/>
    <Usuario Id="37" Username="emp32" Password="1234" Tipo="2"/>
    <Usuario Id="38" Username="emp33" Password="1234" Tipo="2"/>
    <Usuario Id="39" Username="emp34" Password="1234" Tipo="2"/>
    <Usuario Id="40" Username="emp35" Password="1234" Tipo="2"/>
    <Usuario Id="41" Username="emp36" Password="1234" Tipo="2"/>
    <Usuario Id="42" Username="emp37" Password="1234" Tipo="2"/>
    <Usuario Id="43" Username="emp38" Password="1234" Tipo="2"/>
    <Usuario Id="44" Username="emp39" Password="1234" Tipo="2"/>
    <Usuario Id="45" Username="emp40" Password="1234" Tipo="2"/>
    <Usuario Id="46" Username="emp41" Password="1234" Tipo="2"/>
    <Usuario Id="47" Username="emp42" Password="1234" Tipo="2"/>
    <Usuario Id="48" Username="emp43" Password="1234" Tipo="2"/>
    <Usuario Id="49" Username="emp44" Password="1234" Tipo="2"/>
    <Usuario Id="50" Username="emp45" Password="1234" Tipo="2"/>
    <Usuario Id="51" Username="emp46" Password="1234" Tipo="2"/>
    <Usuario Id="52" Username="emp47" Password="1234" Tipo="2"/>
    <Usuario Id="53" Username="emp48" Password="1234" Tipo="2"/>
    <Usuario Id="54" Username="emp49" Password="1234" Tipo="2"/>
    <Usuario Id="55" Username="emp50" Password="1234" Tipo="2"/>
    <Usuario Id="56" Username="emp51" Password="1234" Tipo="2"/>
    <Usuario Id="57" Username="emp52" Password="1234" Tipo="2"/>
    <Usuario Id="58" Username="emp53" Password="1234" Tipo="2"/>
    <Usuario Id="59" Username="emp54" Password="1234" Tipo="2"/>
    <Usuario Id="60" Username="emp55" Password="1234" Tipo="2"/>
    <Usuario Id="61" Username="emp56" Password="1234" Tipo="2"/>
    <Usuario Id="62" Username="emp57" Password="1234" Tipo="2"/>
    <Usuario Id="63" Username="emp58" Password="1234" Tipo="2"/>
    <Usuario Id="64" Username="emp59" Password="1234" Tipo="2"/>
    <Usuario Id="65" Username="emp60" Password="1234" Tipo="2"/>
  </Usuarios>
  <UsuariosAdministradores>
    <UsuarioAdministrador IdUsuario="1"/>
    <UsuarioAdministrador IdUsuario="2"/>
  </UsuariosAdministradores>
  <TiposdeEvento>
    <TipoEvento Id="1" Nombre="Login"/>
    <TipoEvento Id="2" Nombre="Logout"/>
    <TipoEvento Id="3" Nombre="Listar empleados"/>
    <TipoEvento Id="4" Nombre="Listar empleados con filtro"/>
    <TipoEvento Id="5" Nombre="Insertar empleado"/>
    <TipoEvento Id="6" Nombre="Eliminar empleado"/>
    <TipoEvento Id="7" Nombre="Editar empleado"/>
    <TipoEvento Id="8" Nombre="Asociar deducción"/>
    <TipoEvento Id="9" Nombre="Desasociar deducción"/>
    <TipoEvento Id="10" Nombre="Consultar una planilla semanal"/>
    <TipoEvento Id="11" Nombre="Consultar una planilla mensual"/>
    <TipoEvento Id="12" Nombre="Impersonar empleado"/>
    <TipoEvento Id="13" Nombre="Regresar a interfaz de administrador"/>
    <TipoEvento Id="14" Nombre="Ingreso de marcas de asistencia"/>
    <TipoEvento Id="15" Nombre="Ingreso nuevas jornadas"/>
  </TiposdeEvento>
  <Empleados>
    <Empleado Nombre="Harold Cook" IdTipoDocumento="1" ValorDocumento="7-905-598" FechaNacimiento="1991-09-17" IdDepartamento="1" NombrePuesto="Soldador" IdUsuario="6" Activo="1"/>
    <Empleado Nombre="Phil Tilley" IdTipoDocumento="1" ValorDocumento="1-379-534" FechaNacimiento="1984-08-18" IdDepartamento="1" NombrePuesto="Operador de Maquina" IdUsuario="7" Activo="1"/>
    <Empleado Nombre="Nichole Collins" IdTipoDocumento="1" ValorDocumento="2-230-503" FechaNacimiento="2000-10-01" IdDepartamento="3" NombrePuesto="Electricista" IdUsuario="8" Activo="1"/>
    <Empleado Nombre="Catherine Habeck" IdTipoDocumento="1" ValorDocumento="1-693-553" FechaNacimiento="1990-11-04" IdDepartamento="2" NombrePuesto="Auxiliar de Laboratorio" IdUsuario="9" Activo="1"/>
    <Empleado Nombre="Jesenia Caudill" IdTipoDocumento="1" ValorDocumento="4-656-908" FechaNacimiento="2003-03-09" IdDepartamento="3" NombrePuesto="Operador de Maquina" IdUsuario="10" Activo="1"/>
    <Empleado Nombre="Natalie Merritt" IdTipoDocumento="1" ValorDocumento="3-473-263" FechaNacimiento="1968-03-09" IdDepartamento="4" NombrePuesto="Bodeguero" IdUsuario="11" Activo="1"/>
    <Empleado Nombre="Patricia Billings" IdTipoDocumento="1" ValorDocumento="1-822-801" FechaNacimiento="1999-12-13" IdDepartamento="2" NombrePuesto="Tecnico de Mantenimiento" IdUsuario="12" Activo="1"/>
    <Empleado Nombre="Andrew Hymel" IdTipoDocumento="1" ValorDocumento="1-844-443" FechaNacimiento="1966-07-10" IdDepartamento="2" NombrePuesto="Electricista" IdUsuario="13" Activo="1"/>
    <Empleado Nombre="George Klopfer" IdTipoDocumento="1" ValorDocumento="6-602-208" FechaNacimiento="1972-08-17" IdDepartamento="4" NombrePuesto="Operador de Maquina" IdUsuario="14" Activo="1"/>
    <Empleado Nombre="Cathy Camerano" IdTipoDocumento="1" ValorDocumento="7-521-908" FechaNacimiento="1983-11-22" IdDepartamento="3" NombrePuesto="Auxiliar de Laboratorio" IdUsuario="15" Activo="1"/>
    <Empleado Nombre="Whitney Coyle" IdTipoDocumento="1" ValorDocumento="7-860-698" FechaNacimiento="1971-06-18" IdDepartamento="3" NombrePuesto="Auxiliar de Laboratorio" IdUsuario="16" Activo="1"/>
    <Empleado Nombre="Teresa Freeman" IdTipoDocumento="1" ValorDocumento="4-980-889" FechaNacimiento="1987-12-04" IdDepartamento="1" NombrePuesto="Soldador" IdUsuario="17" Activo="1"/>
    <Empleado Nombre="Bobby Cox" IdTipoDocumento="1" ValorDocumento="3-351-750" FechaNacimiento="1985-06-22" IdDepartamento="3" NombrePuesto="Bodeguero" IdUsuario="18" Activo="1"/>
    <Empleado Nombre="Ethel Willey" IdTipoDocumento="1" ValorDocumento="3-791-305" FechaNacimiento="2000-03-13" IdDepartamento="4" NombrePuesto="Operador de Maquina" IdUsuario="19" Activo="1"/>
    <Empleado Nombre="Bryan Bercier" IdTipoDocumento="1" ValorDocumento="1-956-174" FechaNacimiento="2000-06-23" IdDepartamento="2" NombrePuesto="Soldador" IdUsuario="20" Activo="1"/>
    <Empleado Nombre="Robert Haw" IdTipoDocumento="1" ValorDocumento="2-291-580" FechaNacimiento="1990-11-12" IdDepartamento="4" NombrePuesto="Operador de Maquina" IdUsuario="21" Activo="1"/>
    <Empleado Nombre="Phyllis Davis" IdTipoDocumento="1" ValorDocumento="6-331-829" FechaNacimiento="1982-01-01" IdDepartamento="4" NombrePuesto="Electricista" IdUsuario="22" Activo="1"/>
    <Empleado Nombre="Kenneth Dugat" IdTipoDocumento="1" ValorDocumento="7-276-689" FechaNacimiento="1995-02-24" IdDepartamento="4" NombrePuesto="Operador de Maquina" IdUsuario="23" Activo="1"/>
    <Empleado Nombre="Michael Eraso" IdTipoDocumento="1" ValorDocumento="2-437-565" FechaNacimiento="1980-08-05" IdDepartamento="2" NombrePuesto="Soldador" IdUsuario="24" Activo="1"/>
    <Empleado Nombre="Robert Winstead" IdTipoDocumento="1" ValorDocumento="4-889-308" FechaNacimiento="1969-10-24" IdDepartamento="4" NombrePuesto="Operador de Maquina" IdUsuario="25" Activo="1"/>
    <Empleado Nombre="Pedro Miller" IdTipoDocumento="1" ValorDocumento="1-426-945" FechaNacimiento="1977-11-11" IdDepartamento="4" NombrePuesto="Tecnico de Mantenimiento" IdUsuario="26" Activo="1"/>
    <Empleado Nombre="Ronnie Kelly" IdTipoDocumento="1" ValorDocumento="2-340-650" FechaNacimiento="1968-06-18" IdDepartamento="3" NombrePuesto="Soldador" IdUsuario="27" Activo="1"/>
    <Empleado Nombre="James Kelly" IdTipoDocumento="1" ValorDocumento="5-466-259" FechaNacimiento="1985-10-09" IdDepartamento="4" NombrePuesto="Electricista" IdUsuario="28" Activo="1"/>
    <Empleado Nombre="Blanche Arnold" IdTipoDocumento="1" ValorDocumento="7-287-606" FechaNacimiento="1997-02-13" IdDepartamento="1" NombrePuesto="Soldador" IdUsuario="29" Activo="1"/>
    <Empleado Nombre="Wayne Loera" IdTipoDocumento="1" ValorDocumento="1-322-614" FechaNacimiento="1969-09-08" IdDepartamento="1" NombrePuesto="Soldador" IdUsuario="30" Activo="1"/>
    <Empleado Nombre="George Samuels" IdTipoDocumento="1" ValorDocumento="6-163-864" FechaNacimiento="1986-11-06" IdDepartamento="3" NombrePuesto="Bodeguero" IdUsuario="31" Activo="1"/>
    <Empleado Nombre="David Olvera" IdTipoDocumento="1" ValorDocumento="1-780-406" FechaNacimiento="1989-11-07" IdDepartamento="1" NombrePuesto="Tecnico de Mantenimiento" IdUsuario="32" Activo="1"/>
    <Empleado Nombre="Sydney Bertran" IdTipoDocumento="1" ValorDocumento="3-798-466" FechaNacimiento="2001-03-01" IdDepartamento="2" NombrePuesto="Operador de Maquina" IdUsuario="33" Activo="1"/>
    <Empleado Nombre="Emilia Guzowski" IdTipoDocumento="1" ValorDocumento="3-494-485" FechaNacimiento="1980-08-23" IdDepartamento="1" NombrePuesto="Auxiliar de Laboratorio" IdUsuario="34" Activo="1"/>
    <Empleado Nombre="Roberta Carey" IdTipoDocumento="1" ValorDocumento="3-240-103" FechaNacimiento="2001-04-17" IdDepartamento="1" NombrePuesto="Tecnico de Mantenimiento" IdUsuario="35" Activo="1"/>
    <Empleado Nombre="John Ramos" IdTipoDocumento="1" ValorDocumento="5-637-304" FechaNacimiento="1986-06-17" IdDepartamento="1" NombrePuesto="Tecnico de Mantenimiento" IdUsuario="36" Activo="1"/>
    <Empleado Nombre="Reanna Gunter" IdTipoDocumento="1" ValorDocumento="6-242-241" FechaNacimiento="1972-06-28" IdDepartamento="4" NombrePuesto="Bodeguero" IdUsuario="37" Activo="1"/>
    <Empleado Nombre="Joseph Freeman" IdTipoDocumento="1" ValorDocumento="6-438-750" FechaNacimiento="1981-12-20" IdDepartamento="4" NombrePuesto="Electricista" IdUsuario="38" Activo="1"/>
    <Empleado Nombre="Henry Frank" IdTipoDocumento="1" ValorDocumento="1-861-623" FechaNacimiento="1998-01-02" IdDepartamento="3" NombrePuesto="Operador de Maquina" IdUsuario="39" Activo="1"/>
    <Empleado Nombre="Susan Diaz" IdTipoDocumento="1" ValorDocumento="7-572-453" FechaNacimiento="1974-01-07" IdDepartamento="4" NombrePuesto="Tecnico de Mantenimiento" IdUsuario="40" Activo="1"/>
    <Empleado Nombre="Frank Metzler" IdTipoDocumento="1" ValorDocumento="7-917-943" FechaNacimiento="1974-01-06" IdDepartamento="1" NombrePuesto="Electricista" IdUsuario="41" Activo="1"/>
    <Empleado Nombre="Norma Roberts" IdTipoDocumento="1" ValorDocumento="2-327-472" FechaNacimiento="1977-04-15" IdDepartamento="1" NombrePuesto="Operador de Maquina" IdUsuario="42" Activo="1"/>
    <Empleado Nombre="Carol Jinkens" IdTipoDocumento="1" ValorDocumento="6-383-874" FechaNacimiento="1998-06-09" IdDepartamento="4" NombrePuesto="Soldador" IdUsuario="43" Activo="1"/>
    <Empleado Nombre="Rickie Ramirez" IdTipoDocumento="1" ValorDocumento="5-931-181" FechaNacimiento="2002-09-10" IdDepartamento="1" NombrePuesto="Soldador" IdUsuario="44" Activo="1"/>
    <Empleado Nombre="Henry Davine" IdTipoDocumento="1" ValorDocumento="4-361-802" FechaNacimiento="1972-03-05" IdDepartamento="2" NombrePuesto="Electricista" IdUsuario="45" Activo="1"/>
    <Empleado Nombre="Daniel Zick" IdTipoDocumento="1" ValorDocumento="4-163-503" FechaNacimiento="1972-07-28" IdDepartamento="2" NombrePuesto="Tecnico de Mantenimiento" IdUsuario="46" Activo="1"/>
    <Empleado Nombre="Phillip Harned" IdTipoDocumento="1" ValorDocumento="5-429-516" FechaNacimiento="1991-11-06" IdDepartamento="4" NombrePuesto="Electricista" IdUsuario="47" Activo="1"/>
    <Empleado Nombre="Minnie Mcilvaine" IdTipoDocumento="1" ValorDocumento="5-843-617" FechaNacimiento="1967-06-01" IdDepartamento="4" NombrePuesto="Tecnico de Mantenimiento" IdUsuario="48" Activo="1"/>
    <Empleado Nombre="Salvador Dickson" IdTipoDocumento="1" ValorDocumento="1-906-691" FechaNacimiento="1990-09-05" IdDepartamento="1" NombrePuesto="Auxiliar de Laboratorio" IdUsuario="49" Activo="1"/>
    <Empleado Nombre="Jeremy Rea" IdTipoDocumento="1" ValorDocumento="1-715-865" FechaNacimiento="2002-12-22" IdDepartamento="3" NombrePuesto="Auxiliar de Laboratorio" IdUsuario="50" Activo="1"/>
    <Empleado Nombre="Jennifer Miller" IdTipoDocumento="1" ValorDocumento="1-827-625" FechaNacimiento="1995-06-07" IdDepartamento="3" NombrePuesto="Bodeguero" IdUsuario="51" Activo="1"/>
    <Empleado Nombre="Mitchell Rutledge" IdTipoDocumento="1" ValorDocumento="2-109-504" FechaNacimiento="1995-01-07" IdDepartamento="2" NombrePuesto="Operador de Maquina" IdUsuario="52" Activo="1"/>
    <Empleado Nombre="Brian Obermeyer" IdTipoDocumento="1" ValorDocumento="6-592-372" FechaNacimiento="2003-11-25" IdDepartamento="1" NombrePuesto="Soldador" IdUsuario="53" Activo="1"/>
    <Empleado Nombre="Juan Watkins" IdTipoDocumento="1" ValorDocumento="4-473-343" FechaNacimiento="2000-07-25" IdDepartamento="4" NombrePuesto="Tecnico de Mantenimiento" IdUsuario="54" Activo="1"/>
    <Empleado Nombre="Lacy Roberts" IdTipoDocumento="1" ValorDocumento="2-200-834" FechaNacimiento="2004-11-14" IdDepartamento="4" NombrePuesto="Soldador" IdUsuario="55" Activo="1"/>
    <Empleado Nombre="Joe Mayfield" IdTipoDocumento="1" ValorDocumento="4-150-188" FechaNacimiento="1981-11-20" IdDepartamento="3" NombrePuesto="Soldador" IdUsuario="56" Activo="1"/>
    <Empleado Nombre="Veronica Rodriquez" IdTipoDocumento="1" ValorDocumento="4-383-233" FechaNacimiento="1979-10-24" IdDepartamento="2" NombrePuesto="Operador de Maquina" IdUsuario="57" Activo="1"/>
    <Empleado Nombre="Leroy Powell" IdTipoDocumento="1" ValorDocumento="6-246-168" FechaNacimiento="2000-02-25" IdDepartamento="4" NombrePuesto="Auxiliar de Laboratorio" IdUsuario="58" Activo="1"/>
    <Empleado Nombre="Geoffrey Balistrieri" IdTipoDocumento="1" ValorDocumento="3-397-562" FechaNacimiento="2000-11-05" IdDepartamento="2" NombrePuesto="Tecnico de Mantenimiento" IdUsuario="59" Activo="1"/>
    <Empleado Nombre="Sean Stark" IdTipoDocumento="1" ValorDocumento="2-544-750" FechaNacimiento="1987-06-04" IdDepartamento="1" NombrePuesto="Tecnico de Mantenimiento" IdUsuario="60" Activo="1"/>
    <Empleado Nombre="Violet Burge" IdTipoDocumento="1" ValorDocumento="3-971-811" FechaNacimiento="1967-08-12" IdDepartamento="1" NombrePuesto="Electricista" IdUsuario="61" Activo="1"/>
    <Empleado Nombre="Herman Smith" IdTipoDocumento="1" ValorDocumento="7-249-677" FechaNacimiento="1966-04-21" IdDepartamento="4" NombrePuesto="Soldador" IdUsuario="62" Activo="1"/>
    <Empleado Nombre="Kirk Mcguire" IdTipoDocumento="1" ValorDocumento="4-698-978" FechaNacimiento="1990-10-26" IdDepartamento="2" NombrePuesto="Tecnico de Mantenimiento" IdUsuario="63" Activo="1"/>
    <Empleado Nombre="Marvin Bishop" IdTipoDocumento="1" ValorDocumento="7-672-199" FechaNacimiento="1977-03-14" IdDepartamento="1" NombrePuesto="Auxiliar de Laboratorio" IdUsuario="64" Activo="1"/>
    <Empleado Nombre="Natasha Watson" IdTipoDocumento="1" ValorDocumento="7-473-625" FechaNacimiento="1982-12-20" IdDepartamento="3" NombrePuesto="Soldador" IdUsuario="65" Activo="1"/>
  </Empleados>
</Catalogo>
';

-- Tablas temporales para mapeo de IDs
DECLARE @TipoDocumentoMapping TABLE (XmlId INT, RealId INT);
DECLARE @DepartamentoMapping TABLE (XmlId INT, RealId INT);
DECLARE @UsuarioMapping TABLE (XmlId INT, RealId INT);

-- *** CORRECCIÓN 2: USAR MERGE PARA HACER EL SCRIPT RE-EJECUTABLE ***

-- 1. TipoDocumento
MERGE INTO dbo.TipoDocumento AS target
USING (
    SELECT 
        T.value('@Nombre', 'VARCHAR(50)') AS Nombre
    FROM @xml.nodes('/Catalogo/TiposdeDocumentodeIdentidad/TipoDocuIdentidad') AS X(T)
) AS source
ON target.nombre = source.Nombre
WHEN NOT MATCHED BY TARGET THEN
    INSERT (nombre) VALUES (source.Nombre);

-- Poblar la tabla de mapeo después de la inserción/actualización
INSERT INTO @TipoDocumentoMapping (XmlId, RealId)
SELECT
    T.value('@Id', 'INT'),
    td.id
FROM @xml.nodes('/Catalogo/TiposdeDocumentodeIdentidad/TipoDocuIdentidad') AS X(T)
JOIN dbo.TipoDocumento td ON td.nombre = T.value('@Nombre', 'VARCHAR(50)');

-- 2. Departamento
MERGE INTO dbo.Departamento AS target
USING (
    SELECT 
        D.value('@Nombre', 'VARCHAR(100)') AS Nombre
    FROM @xml.nodes('/Catalogo/Departamentos/Departamento') AS X(D)
) AS source
ON target.nombre = source.Nombre
WHEN NOT MATCHED BY TARGET THEN
    INSERT (nombre) VALUES (source.Nombre);

-- Poblar la tabla de mapeo
INSERT INTO @DepartamentoMapping (XmlId, RealId)
SELECT
    D.value('@Id', 'INT'),
    dep.id
FROM @xml.nodes('/Catalogo/Departamentos/Departamento') AS X(D)
JOIN dbo.Departamento dep ON dep.nombre = D.value('@Nombre', 'VARCHAR(100)');

-- 3. Puesto
MERGE INTO dbo.Puesto AS target
USING (
    SELECT 
        P.value('@Nombre', 'VARCHAR(100)') AS Nombre,
        P.value('@SalarioXHora', 'FLOAT') AS SalarioXHora
    FROM @xml.nodes('/Catalogo/Puestos/Puesto') AS X(P)
) AS source
ON target.nombre = source.Nombre
WHEN MATCHED THEN
    UPDATE SET target.salarioPorHora = source.SalarioXHora
WHEN NOT MATCHED BY TARGET THEN
    INSERT (nombre, salarioPorHora)
    VALUES (source.Nombre, source.SalarioXHora);

-- 4. TipoJornada
MERGE INTO dbo.TipoJornada AS target
USING (
    SELECT 
        J.value('@Nombre', 'VARCHAR(50)') AS Nombre,
        J.value('@HoraInicio', 'VARCHAR(5)') AS HoraInicio,
        J.value('@HoraFin', 'VARCHAR(5)') AS HoraFin
    FROM @xml.nodes('/Catalogo/TiposDeJornada/TipoDeJornada') AS X(J)
) AS source
ON target.nombre = source.Nombre
WHEN MATCHED THEN
    UPDATE SET target.horaInicio = source.HoraInicio, target.horaFin = source.HoraFin
WHEN NOT MATCHED BY TARGET THEN
    INSERT (nombre, horaInicio, horaFin)
    VALUES (source.Nombre, source.HoraInicio, source.HoraFin);

-- 5. TipoMovimiento
MERGE INTO dbo.TipoMovimiento AS target
USING (
    SELECT M.value('@Nombre', 'VARCHAR(50)') AS Nombre
    FROM @xml.nodes('/Catalogo/TiposDeMovimiento/TipoDeMovimiento') AS X(M)
) AS source
ON target.nombre = source.Nombre
WHEN NOT MATCHED BY TARGET THEN
    INSERT (nombre) VALUES (source.Nombre);

-- 6. TipoDeduccion
MERGE INTO dbo.TipoDeduccion AS target
USING (
    SELECT 
        D.value('@Nombre', 'VARCHAR(50)') AS Nombre,
        CASE WHEN D.value('@Porcentual', 'VARCHAR(5)') = 'Si' THEN 1 ELSE 0 END AS Porcentual,
        D.value('@Valor', 'FLOAT') AS Valor,
        CASE WHEN D.value('@Obligatorio', 'VARCHAR(5)') = 'Si' THEN 1 ELSE 0 END AS Obligatorio
    FROM @xml.nodes('/Catalogo/TiposDeDeduccion/TipoDeDeduccion') AS X(D)
) AS source
ON target.nombre = source.Nombre
WHEN MATCHED THEN
    UPDATE SET 
        target.porcentual = source.Porcentual,
        target.valor = source.Valor,
        target.obligatorio = source.Obligatorio
WHEN NOT MATCHED BY TARGET THEN
    INSERT (nombre, porcentual, valor, obligatorio)
    VALUES (source.Nombre, source.Porcentual, source.Valor, source.Obligatorio);

-- 7. Usuario
MERGE INTO dbo.Usuario AS target
USING (
    SELECT 
        U.value('@Id', 'INT') AS XmlId,
        U.value('@Username', 'VARCHAR(50)') AS Username,
        U.value('@Password', 'VARCHAR(100)') AS Password,
        CASE WHEN U.value('@Tipo', 'INT') = 1 THEN 1 ELSE 0 END AS EsAdministrador
    FROM @xml.nodes('/Catalogo/Usuarios/Usuario') AS X(U)
) AS source
ON target.username = source.Username
WHEN NOT MATCHED BY TARGET THEN
    INSERT (username, passwordHash, esAdministrador)
    VALUES (source.Username, source.Password, source.EsAdministrador);

-- Poblar la tabla de mapeo
INSERT INTO @UsuarioMapping (XmlId, RealId)
SELECT
    U.value('@Id', 'INT'),
    usr.id
FROM @xml.nodes('/Catalogo/Usuarios/Usuario') AS X(U)
JOIN dbo.Usuario usr ON usr.username = U.value('@Username', 'VARCHAR(50)');


-- *** CORRECCIÓN 3: USAR MERGE PARA EMPLEADOS ***
-- 8. Empleado
MERGE INTO dbo.Empleado AS target
USING (
    SELECT 
        E.value('@Nombre', 'VARCHAR(100)') AS Nombre,
        E.value('@ValorDocumento', 'VARCHAR(30)') AS ValorDocumento,
        E.value('@FechaNacimiento', 'DATE') AS FechaNacimiento,
        E.value('@Activo', 'BIT') AS Activo,
        TDM.RealId AS IdTipoDocumento,
        DM.RealId AS IdDepartamento,
        P.id AS IdPuesto
    FROM @xml.nodes('/Catalogo/Empleados/Empleado') AS X(E)
    INNER JOIN @TipoDocumentoMapping TDM ON TDM.XmlId = E.value('@IdTipoDocumento', 'INT')
    INNER JOIN @DepartamentoMapping DM ON DM.XmlId = E.value('@IdDepartamento', 'INT')
    INNER JOIN dbo.Puesto P ON P.nombre = E.value('@NombrePuesto', 'VARCHAR(100)')
) AS source
ON target.valorDocumento = source.ValorDocumento
WHEN NOT MATCHED BY TARGET THEN
    INSERT (nombreCompleto, valorDocumento, fechaNacimiento, activo, idTipoDocumento, idDepartamento, idPuesto)
    VALUES (source.Nombre, source.ValorDocumento, source.FechaNacimiento, source.Activo, source.IdTipoDocumento, source.IdDepartamento, source.IdPuesto);


-- 9. Actualizar Usuarios con IDs de Empleados
UPDATE U
SET U.idEmpleado = E.id
FROM dbo.Usuario U
INNER JOIN @UsuarioMapping UM ON U.id = UM.RealId
INNER JOIN (
    SELECT 
        Elem.value('@IdUsuario', 'INT') AS XmlIdUsuario,
        Elem.value('@ValorDocumento', 'VARCHAR(30)') AS ValorDocumento
    FROM @xml.nodes('/Catalogo/Empleados/Empleado') AS X(Elem)
) AS X ON X.XmlIdUsuario = UM.XmlId
INNER JOIN dbo.Empleado E ON E.valorDocumento = X.ValorDocumento
WHERE U.idEmpleado IS NULL; -- Solo actualizar si no tiene un empleado asignado


-- 10. Bitácora de Eventos (opcional, si es parte de la carga inicial)
DECLARE @AdminUserId INT = (SELECT RealId FROM @UsuarioMapping WHERE XmlId = 1);

MERGE INTO dbo.BitacoraEvento AS target
USING (
    SELECT 
        T.value('@Id', 'INT') AS Id,
        T.value('@Nombre', 'VARCHAR(255)') AS Nombre
    FROM @xml.nodes('/Catalogo/TiposdeEvento/TipoEvento') AS X(T)
) AS source
ON target.descripcion = source.Nombre -- O usa un ID si la tabla lo tiene
WHEN NOT MATCHED BY TARGET THEN
    INSERT (idUsuario, idTipoEvento, descripcion, idPostByUser, postInIP, postTime)
    VALUES (@AdminUserId, source.Id, source.Nombre, @AdminUserId, '127.0.0.1', GETDATE());

PRINT '✅ Carga de catálogos finalizada correctamente.';

END TRY
BEGIN CATCH
    PRINT '❌ Error durante la carga de catálogos.';
    
    -- Inserta el error en la tabla de errores
    -- (Tu bloque CATCH original aquí)
    INSERT INTO dbo.DBError (
        errorNumber,
        errorSeverity,
        errorState,
        errorProcedure,
        errorLine,
        errorMessage,
        logTime
    )
    VALUES (
        ERROR_NUMBER(),
        ERROR_SEVERITY(),
        ERROR_STATE(),
        ERROR_PROCEDURE(),
        ERROR_LINE(),
        ERROR_MESSAGE(),
        GETDATE()
    );
    THROW;
END CATCH;
GO