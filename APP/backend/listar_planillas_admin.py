from flask import Blueprint, render_template, request, session, redirect
from backend.conexion import obtener_conexion
import datetime

ruta_planillas_admin = Blueprint('ruta_planillas_admin', __name__)

@ruta_planillas_admin.route('/admin/planillas', methods=['GET'])
def listar_planillas_admin():
    if 'usuario' not in session or not session['usuario']['esAdmin']:
        return redirect('/')

    tipo = request.args.get('tipo', default='mensual')
    planillas = []
    fecha_mensual = request.args.get('fecha_mensual')
    fecha_semanal = request.args.get('fecha_semanal')

    try:
        conexion = obtener_conexion()
        cursor = conexion.cursor()

        if tipo == 'mensual' and fecha_mensual:
            # El SP espera formato 'YYYY-MM'
            cursor.execute("""
                DECLARE @out INT;
                EXEC dbo.SP_ListarPlanillaMensualGlobal
                    @inMes = ?,
                    @outResultCode = @out OUTPUT;
            """, (fecha_mensual,))
            planillas = cursor.fetchall()
            cursor.nextset()

        elif tipo == 'semanal' and fecha_semanal:
            # Calcular semana (inicio en lunes, fin en domingo)
            fecha = datetime.datetime.strptime(fecha_semanal, '%Y-%m-%d').date()
            inicio_semana = fecha
            fin_semana = inicio_semana + datetime.timedelta(days=6)
            print("Semana inicio:", inicio_semana)
            print("Semana fin:", fin_semana)
            cursor.execute("""
                DECLARE @out INT;
                EXEC dbo.SP_ListarPlanillaSemanalGlobal
                    @inSemanaInicio = ?,
                    @inSemanaFin = ?,
                    @outResultCode = @out OUTPUT;
            """, (inicio_semana, fin_semana))
            planillas = cursor.fetchall()
            cursor.nextset()

        conexion.close()

    except Exception as e:
        return f"Error cargando planillas: {e}", 500

    return render_template('admin/listar_planillas.html',
                           planillas=planillas,
                           tipo=tipo,
                           fecha_mensual=fecha_mensual,
                           fecha_semanal=fecha_semanal)
