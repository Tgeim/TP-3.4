from flask import Blueprint, render_template, request, redirect, session
from backend.conexion import obtener_conexion

ruta_editar_empleado = Blueprint('ruta_editar_empleado', __name__)

@ruta_editar_empleado.route('/admin/editar_empleado/<int:id_empleado>', methods=['GET', 'POST'])
def editar_empleado(id_empleado):
    if 'usuario' not in session or not session['usuario']['esAdmin']:
        return redirect('/')

    conexion = obtener_conexion()
    cursor = conexion.cursor()

    if request.method == 'POST':
        mensaje = None  # Para evitar UnboundLocalError
        nombre = request.form['nombreCompleto']
        documento = request.form['documentoIdentidad']
        fecha_nacimiento = request.form['fechaNacimiento']
        id_tipo_doc = request.form['idTipoDocumento']
        id_departamento = request.form['idDepartamento']
        id_puesto = request.form['idPuesto']
        id_usuario = session['usuario']['id']
        ip = request.remote_addr

        try:
            cursor.execute("""
                DECLARE @out INT;
                EXEC dbo.SP_EditarEmpleado 
                    @inId = ?,
                    @inNombreCompleto = ?,
                    @inValorDocumento = ?,
                    @inFechaNacimiento = ?,
                    @inIdTipoDocumento = ?,
                    @inIdDepartamento = ?,
                    @inIdPuesto = ?,
                    @inIdPostByUser = ?,
                    @inPostInIP = ?,
                    @outResultCode = @out OUTPUT;
                SELECT @out AS resultado;
            """, (id_empleado, nombre, documento, fecha_nacimiento, id_tipo_doc, id_departamento, id_puesto, id_usuario, ip))

            while cursor.description is None:
                if not cursor.nextset():
                    raise Exception("No se encontró resultset de salida")

            result = cursor.fetchone()
            if result and result[0] == 0:
                conexion.commit()
                conexion.close()
                return redirect('/admin/empleados')
            else:
                mensaje = f"Error al editar empleado. Código: {result[0]}"
        except Exception as e:
            conexion.rollback()
            mensaje = f"Error inesperado: {e}"

        # Cargar catálogos si hubo error
        tipos_documento, departamentos, puestos = [], [], []
        try:
            cursor.execute("DECLARE @out INT; EXEC dbo.SP_ListarTipoDocumento @outResultCode = @out OUTPUT;")
            tipos_documento = cursor.fetchall()
            cursor.nextset()

            cursor.execute("DECLARE @out INT; EXEC dbo.SP_ListarDepartamentos @outResultCode = @out OUTPUT;")
            departamentos = cursor.fetchall()
            cursor.nextset()

            cursor.execute("DECLARE @out INT; EXEC dbo.SP_ListarPuestos @outResultCode = @out OUTPUT;")
            puestos = cursor.fetchall()
            cursor.nextset()
        except:
            mensaje += " Error cargando catálogos."

        conexion.close()
        return render_template("admin/editar_empleado.html",
                               mensaje=mensaje,
                               empleado={
                                   'id': id_empleado,
                                   'nombreCompleto': nombre,
                                   'valorDocumento': documento,
                                   'fechaNacimiento': fecha_nacimiento,
                                   'idTipoDocumento': int(id_tipo_doc),
                                   'idDepartamento': int(id_departamento),
                                   'idPuesto': int(id_puesto),
                                   'usuario': session['usuario']
                               },
                               tipos_documento=tipos_documento,
                               departamentos=departamentos,
                               puestos=puestos)

    else:
        try:
            cursor.execute("""
                DECLARE @out INT;
                EXEC dbo.SP_ConsultarEmpleadoPorId
                    @inId = ?,
                    @outResultCode = @out OUTPUT;
            """, (id_empleado,))
            empleado = cursor.fetchone()
            columnas = [col[0] for col in cursor.description]
            empleado_dict = dict(zip(columnas, empleado))
            cursor.nextset()

            cursor.execute("DECLARE @out INT; EXEC dbo.SP_ListarTipoDocumento @outResultCode = @out OUTPUT;")
            tipos_documento = cursor.fetchall()
            cursor.nextset()

            cursor.execute("DECLARE @out INT; EXEC dbo.SP_ListarDepartamentos @outResultCode = @out OUTPUT;")
            departamentos = cursor.fetchall()
            cursor.nextset()

            cursor.execute("DECLARE @out INT; EXEC dbo.SP_ListarPuestos @outResultCode = @out OUTPUT;")
            puestos = cursor.fetchall()
            cursor.nextset()

        except Exception as e:
            conexion.close()
            return f"Error cargando datos: {e}", 500

        conexion.close()
        return render_template("admin/editar_empleado.html",
                               empleado=empleado_dict,
                               tipos_documento=tipos_documento,
                               departamentos=departamentos,
                               puestos=puestos,
                               usuario=session['usuario'])