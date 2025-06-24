from flask import Blueprint, render_template, request, session, redirect
from backend.conexion import obtener_conexion
import datetime

ruta_movimientos_empleado = Blueprint('ruta_movimientos_empleado', __name__)

@ruta_movimientos_empleado.route('/usuario/movimientos', methods=['GET'])
def listar_movimientos_empleado():
    if 'usuario' not in session or session['usuario'].get('esAdmin'):
        return redirect('/')

    fecha_param = request.args.get('fecha', '')
    movimientos = []
    id_empleado = session['usuario']['id']

    try:
        if fecha_param:
            # Asegurar inicio de semana (lunes)
            fecha_obj = datetime.datetime.strptime(fecha_param, '%Y-%m-%d')
            lunes_semana = fecha_obj - datetime.timedelta(days=fecha_obj.weekday())
            fecha_semana_str = lunes_semana.date().isoformat()

            conexion = obtener_conexion()
            cursor = conexion.cursor()

            cursor.execute("""
                DECLARE @out INT;
                EXEC dbo.SP_ListarMovimientosPorEmpleadoYSemana
                    @inIdEmpleado = ?,
                    @inFecha = ?,
                    @outResultCode = @out OUTPUT;
            """, (id_empleado, fecha_semana_str))

            columnas = [col[0] for col in cursor.description]
            filas = cursor.fetchall()
            movimientos = [dict(zip(columnas, fila)) for fila in filas]
            cursor.nextset()
            conexion.close()

    except Exception as e:
        return f"Error cargando movimientos: {e}", 500

    return render_template('usuario/listar_movimientos_empleado.html',
                           movimientos=movimientos,
                           fecha=fecha_param,
                           usuario=session['usuario'])
