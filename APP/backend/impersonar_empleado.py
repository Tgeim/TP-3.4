from flask import Blueprint, session, redirect, url_for, request
from backend.conexion import obtener_conexion

ruta_impersonar_empleado = Blueprint('ruta_impersonar_empleado', __name__)

@ruta_impersonar_empleado.route('/admin/impersonar/<int:id_empleado>')
def impersonar_empleado(id_empleado):
    if 'usuario' not in session or not session['usuario']['esAdmin']:
        return redirect('/')

    conexion = obtener_conexion()
    try:
        with conexion.cursor() as cursor:
            cursor.execute("DECLARE @outResultCode INT; EXEC dbo.SP_ConsultarEmpleadoPorId @inId = ?, @outResultCode = @outResultCode OUTPUT; SELECT @outResultCode;", (id_empleado,))


            empleado = cursor.fetchone()
            columnas = [col[0] for col in cursor.description] if cursor.description else []
            print("Resultado crudo del SP:", empleado)
            print("Columnas:", columnas)

        conexion.close()

        if not empleado or not columnas:
            return redirect(url_for('admin.menu_admin', error=1))

        empleado_dict = dict(zip(columnas, empleado))

        session['admin_original'] = session['usuario'].copy()
        session['usuario'] = {
            'id': empleado_dict['id'],
            'username': empleado_dict['nombreCompleto'],
            'esAdmin': False
        }
        session['impersonado'] = True

        return redirect(url_for('menu_empleado'))

    except Exception as e:
        print(f"Error al impersonar: {e}")
        return redirect(url_for('admin.menu_admin', error=1))
