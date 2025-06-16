from flask import Blueprint, redirect, session, url_for, request
from backend.conexion import obtener_conexion

ruta_eliminar_empleado = Blueprint('ruta_eliminar_empleado', __name__)

@ruta_eliminar_empleado.route('/admin/eliminar_empleado/<int:id_empleado>', methods=['POST'])
def eliminar_empleado(id_empleado):
    if 'usuario' not in session or not session['usuario']['esAdmin']:
        return redirect('/')

    id_usuario = session['usuario']['id']
    ip = request.remote_addr

    try:
        conexion = obtener_conexion()
        cursor = conexion.cursor()
        cursor.execute("""
            DECLARE @out INT;
            EXEC dbo.SP_EliminarEmpleado
                @inId = ?,
                @inIdPostByUser = ?,
                @inPostInIP = ?,
                @outResultCode = @out OUTPUT;
            SELECT @out AS resultado;
        """, (id_empleado, id_usuario, ip))

        # Avanzar hasta encontrar el SELECT final con el resultado
        while cursor.description is None:
            if not cursor.nextset():
                break

        result = cursor.fetchone()
        conexion.commit()

        if result and result[0] == 0:
            return redirect(url_for('ruta_empleados.listar_empleados'))
        else:
            return f"Error al eliminar. Código: {result[0]}" if result else "Error inesperado: código no devuelto"

    except Exception as e:
        if conexion:
            conexion.rollback()
        return f"Error inesperado al eliminar: {e}"

    finally:
        if conexion:
            conexion.close()
