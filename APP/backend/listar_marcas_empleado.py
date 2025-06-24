from flask import Blueprint, render_template, request, session, redirect
from backend.conexion import obtener_conexion
import datetime

ruta_marcas_empleado = Blueprint('ruta_marcas_empleado', __name__)

@ruta_marcas_empleado.route('/usuario/marcas', methods=['GET'])
def listar_marcas_empleado():
    if 'usuario' not in session or session['usuario'].get('esAdmin'):
        return redirect('/')

    fecha = request.args.get('fecha', default=datetime.date.today().isoformat())
    id_empleado = session['usuario']['id']
    marcas = []

    try:
        fecha_obj = datetime.datetime.strptime(fecha, "%Y-%m-%d")
        lunes_semana = fecha_obj - datetime.timedelta(days=fecha_obj.weekday())
        domingo_semana = lunes_semana + datetime.timedelta(days=6)

        conexion = obtener_conexion()
        cursor = conexion.cursor()

        cursor.execute("""
            DECLARE @out INT;
            EXEC dbo.SP_ListarMarcasPorEmpleadoYSemana
                @inIdEmpleado = ?,
                @inSemanaInicio = ?,
                @inSemanaFin = ?,
                @outResultCode = @out OUTPUT;
        """, (id_empleado, lunes_semana.date(), domingo_semana.date()))

        columnas = [col[0] for col in cursor.description]
        filas = cursor.fetchall()
        marcas = [dict(zip(columnas, fila)) for fila in filas]

        cursor.nextset()
        conexion.close()

    except Exception as e:
        return f"Error cargando marcas: {e}", 500

    return render_template('usuario/listar_marcas_empleado.html',
                           marcas=marcas,
                           fecha_base=fecha,
                           usuario=session['usuario'])
