from flask import Blueprint, render_template, request, session, redirect, jsonify
from backend.conexion import obtener_conexion
from backend.deducciones_detalladas import obtener_deducciones_semanales, obtener_deducciones_mensuales
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

        # Mensual
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
            filas = cursor.fetchall()
            columnas = [col[0] for col in cursor.description]
            planillas = [dict(zip(columnas, fila)) for fila in filas]
            cursor.nextset()

        # Semanal
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
            filas = cursor.fetchall()
            columnas = [col[0] for col in cursor.description]
            planillas = [dict(zip(columnas, fila)) for fila in filas]
            cursor.nextset()

        # Convertir fechas en planillas a texto
        for p in planillas:
            if 'fechaCalculo' in p and isinstance(p['fechaCalculo'], datetime.date):
                p['fechaCalculo'] = p['fechaCalculo'].strftime('%Y-%m-%d')

        # Lista de empleados
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
                           empleados=empleados,
                           usuario=session['usuario'])


@ruta_planillas_admin.route('/admin/planillas/detalle_deducciones', methods=['GET'])
def detalle_deducciones():
    if 'usuario' not in session or not session['usuario']['esAdmin']:
        return jsonify({'error': 'No autorizado'}), 403

    tipo = request.args.get('tipo')
    id_empleado = request.args.get('idEmpleado', type=int)
    fecha = request.args.get('fecha')
    print("Tipo:", tipo, "ID Empleado:", id_empleado, "Fecha:", fecha)
    try:
        if tipo == 'mensual':
            if len(fecha) == 7:
                fecha += '-01'
            detalles = obtener_deducciones_mensuales(id_empleado, fecha)
        elif tipo == 'semanal':
            print("Obteniendo deducciones semanales para el empleado:", id_empleado, "en la fecha:", fecha)
            detalles = obtener_deducciones_semanales(id_empleado, fecha)
        else:
            return jsonify({'error': 'Tipo inválido'}), 400


        return jsonify({ "deducciones": detalles })  # <- ESTE CAMBIO ES LA CLAVE

    except Exception as e:
        return jsonify({'error': f'Error consultando deducciones: {e}'}), 500
