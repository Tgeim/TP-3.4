from flask import Blueprint, render_template, request, session, redirect
from backend.conexion import obtener_conexion
import datetime

ruta_planillas_admin = Blueprint('ruta_planillas_admin', __name__)

@ruta_planillas_admin.route('/admin/planillas', methods=['GET'])
def listar_planillas_admin():
    if 'usuario' not in session or not session['usuario']['esAdmin']:
        return redirect('/')

    tipo = request.args.get('tipo', default='mensual')
    usar_filtro_empleado = request.args.get('filtro_empleado') == 'on'
    id_empleado = request.args.get('idEmpleado', type=int)
    fecha_mensual = request.args.get('fecha_mensual')
    fecha_semanal = request.args.get('fecha_semanal')
    planillas = []

    try:
        conexion = obtener_conexion()
        cursor = conexion.cursor()

        # Listado mensual
        if tipo == 'mensual' and fecha_mensual:
            if usar_filtro_empleado and id_empleado:
                cursor.execute("""
                    DECLARE @out INT;
                    EXEC dbo.SP_ListarPlanillaMensualPorEmpleado
                        @inIdEmpleado = ?,
                        @inMes = ?,
                        @outResultCode = @out OUTPUT;
                """, (id_empleado, fecha_mensual))
            else:
                cursor.execute("""
                    DECLARE @out INT;
                    EXEC dbo.SP_ListarPlanillaMensualGlobal
                        @inMes = ?,
                        @outResultCode = @out OUTPUT;
                """, (fecha_mensual,))
            planillas = cursor.fetchall()
            cursor.nextset()

        # Listado semanal
        elif tipo == 'semanal' and fecha_semanal:
            fecha = datetime.datetime.strptime(fecha_semanal, '%Y-%m-%d').date()
            inicio_semana = fecha
            fin_semana = inicio_semana + datetime.timedelta(days=6)

            if usar_filtro_empleado and id_empleado:
                cursor.execute("""
                    DECLARE @out INT;
                    EXEC dbo.SP_ListarPlanillaSemanalPorEmpleado
                        @inIdEmpleado = ?,
                        @inDesde = ?,
                        @inHasta = ?,
                        @outResultCode = @out OUTPUT;
                """, (id_empleado, inicio_semana, fin_semana))
            else:
                cursor.execute("""
                    DECLARE @out INT;
                    EXEC dbo.SP_ListarPlanillaSemanalGlobal
                        @inSemanaInicio = ?,
                        @inSemanaFin = ?,
                        @outResultCode = @out OUTPUT;
                """, (inicio_semana, fin_semana))

            planillas = cursor.fetchall()
            cursor.nextset()

        # Obtener empleados para el filtro
        cursor.execute("DECLARE @out INT; EXEC dbo.SP_ListarEmpleados @outResultCode = @out OUTPUT;")
        empleados = cursor.fetchall()
        cursor.nextset()

        conexion.close()

    except Exception as e:
        return f"Error cargando planillas: {e}", 500

    return render_template('admin/listar_planillas.html',
                           planillas=planillas,
                           tipo=tipo,
                           fecha_mensual=fecha_mensual,
                           fecha_semanal=fecha_semanal,
                           usar_filtro_empleado=usar_filtro_empleado,
                           id_empleado=id_empleado,
                           empleados=empleados)
