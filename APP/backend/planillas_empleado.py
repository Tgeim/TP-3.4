from flask import Blueprint, render_template, request, session, redirect, jsonify
from backend.conexion import obtener_conexion
from backend.deducciones_detalladas import obtener_deducciones_semanales, obtener_deducciones_mensuales
import datetime

ruta_planillas_empleado = Blueprint('ruta_planillas_empleado', __name__)

@ruta_planillas_empleado.route('/usuario/planillas', methods=['GET'])
def listar_planillas_empleado():
    if 'usuario' not in session or session['usuario'].get('esAdmin'):
        return redirect('/')

    tipo = request.args.get('tipo', default='mensual')
    fecha_mensual = request.args.get('fecha_mensual', '').strip()
    fecha_semanal = request.args.get('fecha_semanal', '').strip()
    planillas = []

    id_empleado = session['usuario']['id']

    try:
        conexion = obtener_conexion()
        cursor = conexion.cursor()

        if tipo == 'mensual' and fecha_mensual:
            cursor.execute("""
                DECLARE @out INT;
                EXEC dbo.SP_ListarPlanillaMensualPorEmpleado
                    @inIdEmpleado = ?,
                    @inMes = ?,
                    @outResultCode = @out OUTPUT;
            """, (id_empleado, fecha_mensual))
            columnas = [col[0] for col in cursor.description]
            filas = cursor.fetchall()

        elif tipo == 'semanal' and fecha_semanal:
            fecha = datetime.datetime.strptime(fecha_semanal, '%Y-%m-%d').date()
            inicio_semana = fecha
            fin_semana = inicio_semana + datetime.timedelta(days=6)

            cursor.execute("""
                DECLARE @out INT;
                EXEC dbo.SP_ListarPlanillaSemanalPorEmpleado
                    @inIdEmpleado = ?,
                    @inDesde = ?,
                    @inHasta = ?,
                    @outResultCode = @out OUTPUT;
            """, (id_empleado, inicio_semana, fin_semana))
            columnas = [col[0] for col in cursor.description]
            filas = cursor.fetchall()
        else:
            filas = []
            columnas = []

        planillas = [dict(zip(columnas, fila)) for fila in filas]

        try:
            cursor.nextset()
        except:
            pass

        conexion.close()

    except Exception as e:
        return f"Error al cargar planillas: {e}", 500

    return render_template('usuario/listar_planillas_empleado.html',
                           planillas=planillas,
                           tipo=tipo,
                           fecha_mensual=fecha_mensual,
                           fecha_semanal=fecha_semanal,
                           usuario=session['usuario'])

# ✅ NUEVO: Endpoint para detalle de deducciones igual al de admin, pero adaptado al usuario
@ruta_planillas_empleado.route('/usuario/planillas/detalle_deducciones', methods=['GET'])
def detalle_deducciones_empleado():
    if 'usuario' not in session or session['usuario'].get('esAdmin'):
        return jsonify({'error': 'No autorizado'}), 403

    tipo = request.args.get('tipo')
    fecha = request.args.get('fecha')
    id_empleado = session['usuario']['id']  # Siempre el ID del usuario en sesión

    try:
        if tipo == 'mensual':
            if len(fecha) == 7:
                fecha += '-01'
            detalles = obtener_deducciones_mensuales(id_empleado, fecha)
        elif tipo == 'semanal':
            detalles = obtener_deducciones_semanales(id_empleado, fecha)
        else:
            return jsonify({'error': 'Tipo inválido'}), 400

        return jsonify({ "deducciones": detalles })

    except Exception as e:
        return jsonify({'error': f'Error consultando deducciones: {e}'}), 500
@ruta_planillas_empleado.route('/usuario/planillas/ultimas', methods=['GET'])
def obtener_ultimas_planillas():
    if 'usuario' not in session or session['usuario'].get('esAdmin'):
        return jsonify({'error': 'No autorizado'}), 403

    tipo = request.args.get('tipo')
    id_empleado = session['usuario']['id']
    cantidad = 12 if tipo == 'mensual' else 15

    try:
        conexion = obtener_conexion()
        cursor = conexion.cursor()

        if tipo == 'mensual':
            cursor.execute("""
                DECLARE @out INT;
                EXEC dbo.SP_ListarUltimasPlanillasMensualesEmpleado
                    @inIdEmpleado = ?, @inCantidadMeses = ?, @outResultCode = @out OUTPUT;
            """, (id_empleado, cantidad))
        elif tipo == 'semanal':
            cursor.execute("""
                DECLARE @out INT;
                EXEC dbo.SP_ListarUltimasPlanillasSemanalesEmpleado
                    @inIdEmpleado = ?, @inCantidadSemanas = ?, @outResultCode = @out OUTPUT;
            """, (id_empleado, cantidad))
        else:
            return jsonify({'error': 'Tipo inválido'}), 400

        columnas = [col[0] for col in cursor.description]
        filas = cursor.fetchall()
        planillas = [dict(zip(columnas, fila)) for fila in filas]

        return jsonify({'planillas': planillas})

    except Exception as e:
        return jsonify({'error': f'Error consultando planillas: {e}'}), 500
