from flask import Blueprint, render_template, request, redirect, url_for, session
from backend.conexion import obtener_conexion

ruta_insertar_empleado = Blueprint('ruta_insertar_empleado', __name__)

@ruta_insertar_empleado.route('/admin/nuevo_empleado', methods=['GET', 'POST'])
def nuevo_empleado():
    if 'usuario' not in session or not session['usuario']['esAdmin']:
        return redirect('/')

    mensaje = None

    if request.method == 'POST':
        nombre_completo = request.form['nombreCompleto']
        documento_identidad = request.form['documentoIdentidad']
        fecha_nacimiento = request.form['fechaNacimiento']
        id_tipo_documento = int(request.form['idTipoDocumento'])
        id_departamento = int(request.form['idDepartamento'])
        id_puesto = int(request.form['idPuesto'])
        id_post_by_user = session['usuario'].get('id')
        ip_cliente = request.remote_addr

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
                SELECT @outResultCode;
            """, (
                nombre_completo, documento_identidad, fecha_nacimiento,
                id_tipo_documento, id_departamento, id_puesto,
                id_post_by_user, id_post_by_user, ip_cliente
            ))

            resultado = cursor.fetchone()[0]
            conexion.commit()
            conexion.close()

            if resultado == 0:
                return redirect(url_for('ruta_empleados.listar_empleados'))
            else:
                mensaje = f"Error: El SP devolvió el código {resultado}"

        except Exception as e:
            mensaje = f"Error inesperado: {str(e)}"
        finally:
            try:
                conexion.close()
            except:
                pass

    # GET o POST con error → recargar selects
    try:
        conexion = obtener_conexion()
        cursor = conexion.cursor()

        cursor.execute("DECLARE @out INT; EXEC dbo.SP_ListarTipoDocumento @outResultCode = @out OUTPUT;")
        tipos_documento = cursor.fetchall()

        cursor.nextset()
        cursor.execute("DECLARE @out INT; EXEC dbo.SP_ListarDepartamentos @outResultCode = @out OUTPUT;")
        departamentos = cursor.fetchall()

        cursor.nextset()
        cursor.execute("DECLARE @out INT; EXEC dbo.SP_ListarPuestos @outResultCode = @out OUTPUT;")
        puestos = cursor.fetchall()

        conexion.close()
    except Exception as e:
        return f"Error cargando catálogos: {str(e)}"

    return render_template(
        'admin/nuevo_empleado.html',
        mensaje=mensaje,
        tipos_documento=tipos_documento,
        departamentos=departamentos,
        puestos=puestos,
        usuario=session['usuario']
    )
