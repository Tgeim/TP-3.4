from flask import Blueprint, render_template, request, session, redirect
from backend.conexion import obtener_conexion
import datetime

ruta_movimientos = Blueprint('ruta_movimientos', __name__)

@ruta_movimientos.route('/admin/movimientos', methods=['GET'])
def listar_movimientos():
    if 'usuario' not in session or not session['usuario']['esAdmin']:
        return redirect('/')

    id_empleado = request.args.get('idEmpleado', type=int)
    usar_filtro = request.args.get('usar_filtro', default='0') == '1'
    fecha_param = request.args.get('fecha', default=datetime.date.today().isoformat())

    try:
        fecha_obj = datetime.datetime.strptime(fecha_param, "%Y-%m-%d")
        lunes_semana = fecha_obj - datetime.timedelta(days=fecha_obj.weekday())
        fecha_semana_str = lunes_semana.date().isoformat()
    except ValueError:
        fecha_semana_str = datetime.date.today().isoformat()

    movimientos = []
    empleados = []

    try:
        conexion = obtener_conexion()
        cursor = conexion.cursor()

        # Obtener empleados
        cursor.execute("DECLARE @out INT; EXEC dbo.SP_ListarEmpleados @outResultCode = @out OUTPUT;")
        empleados = cursor.fetchall()
        cursor.nextset()

        if usar_filtro and id_empleado:
            cursor.execute("""
                DECLARE @out INT;
                EXEC dbo.SP_ListarMovimientosPorEmpleadoYSemana
                    @inIdEmpleado = ?,
                    @inFecha = ?,
                    @outResultCode = @out OUTPUT;
            """, (id_empleado, fecha_semana_str))
        else:
            cursor.execute("""
                DECLARE @out INT;
                EXEC dbo.SP_ListarMovimientosPorSemanaGlobal
                    @inFecha = ?,
                    @outResultCode = @out OUTPUT;
            """, (fecha_semana_str,))
        
        movimientos = cursor.fetchall()
        cursor.nextset()
        conexion.close()

    except Exception as e:
        return f"Error cargando movimientos: {e}", 500

    return render_template('admin/listar_movimientos.html',
                           empleados=empleados,
                           movimientos=movimientos,
                           id_empleado=id_empleado,
                           fecha_base=fecha_param,
                           usar_filtro=usar_filtro,
                           usuario=session['usuario'])
