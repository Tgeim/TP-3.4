from flask import Blueprint, render_template, request, redirect, url_for, session
from backend.conexion import obtener_conexion

ruta_insertar_empleado = Blueprint('ruta_insertar_empleado', __name__)

@ruta_insertar_empleado.route('/admin/nuevo_empleado', methods=['GET', 'POST'])
def nuevo_empleado():
    if 'usuario' not in session or not session['usuario']['esAdmin']:
        return redirect('/')

    if request.method == 'POST':
        nombre_completo = request.form['nombreCompleto']
        documento_identidad = request.form['documentoIdentidad']
        fecha_nacimiento = request.form['fechaNacimiento']
        id_tipo_documento = int(request.form['idTipoDocumento'])
        id_departamento = int(request.form['idDepartamento'])
        id_puesto = int(request.form['idPuesto'])
        id_post_by_user = session['usuario'].get('id')  # ⚠️ Este debe estar bien definido en sesión
        ip_cliente = request.remote_addr

        print("DEBUG: ID del usuario que inserta:", id_post_by_user)
        print("DEBUG: Datos recibidos POST")
        print(nombre_completo, documento_identidad, fecha_nacimiento, id_tipo_documento, id_departamento, id_puesto, id_post_by_user)

        try:
            conexion = obtener_conexion()
            cursor = conexion.cursor()
            cursor.execute("""
                DECLARE @outResultCode INT;
                EXEC dbo.SP_InsertarEmpleado
                    @inNombreCompleto = ?,
                    @inValorDocumento = ?,
                    @inFechaNacimiento = ?,
                    @inIdTipoDocumento = ?,
                    @inIdDepartamento = ?,
                    @inIdPuesto = ?,
                    @inIdUsuario = ?,
                    @inIdPostByUser = ?,
                    @inPostInIP = ?,
                    @outResultCode = @outResultCode OUTPUT;
                SELECT @outResultCode AS resultado;
            """, (
                nombre_completo, documento_identidad, fecha_nacimiento,
                id_tipo_documento, id_departamento, id_puesto,
                id_post_by_user, id_post_by_user, ip_cliente
            ))
            resultado = cursor.fetchone()[0]
            print("DEBUG: Resultado del SP_InsertarEmpleado:", resultado)
            conexion.commit()
            conexion.close()

            if resultado == 0:
                return redirect(url_for('ruta_empleados.listar_empleados'))
            else:
                mensaje = f"Error: El SP devolvió el código {resultado}"

        except Exception as e:
            print("DEBUG: Error inesperado al insertar:", str(e))
            mensaje = f"Error inesperado: {str(e)}"
        finally:
            try:
                conexion.close()
            except:
                pass

        # Si hubo error, recargamos selects y mostramos mensaje
        try:
            conexion = obtener_conexion()
            cursor = conexion.cursor()
            cursor.execute("SELECT id, nombre FROM dbo.TipoDocumento")
            tipos_documento = cursor.fetchall()
            cursor.execute("SELECT id, nombre FROM dbo.Departamento")
            departamentos = cursor.fetchall()
            cursor.execute("SELECT id, nombre FROM dbo.Puesto")
            puestos = cursor.fetchall()
            conexion.close()
        except Exception as e:
            return f"Error al recargar formulario: {str(e)}"

        return render_template(
            'admin/nuevo_empleado.html',
            mensaje=mensaje,
            tipos_documento=tipos_documento,
            departamentos=departamentos,
            puestos=puestos
        )

    # GET: mostrar formulario limpio
    conexion = obtener_conexion()
    cursor = conexion.cursor()
    cursor.execute("SELECT id, nombre FROM dbo.TipoDocumento")
    tipos_documento = cursor.fetchall()
    cursor.execute("SELECT id, nombre FROM dbo.Departamento")
    departamentos = cursor.fetchall()
    cursor.execute("SELECT id, nombre FROM dbo.Puesto")
    puestos = cursor.fetchall()
    conexion.close()

    return render_template(
        'admin/nuevo_empleado.html',
        tipos_documento=tipos_documento,
        departamentos=departamentos,
        puestos=puestos
    )
