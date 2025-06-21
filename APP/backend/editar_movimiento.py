from flask import Blueprint, render_template, request, session, redirect
from backend.conexion import obtener_conexion

ruta_editar_movimiento = Blueprint('ruta_editar_movimiento', __name__)

@ruta_editar_movimiento.route('/admin/editar_movimiento/<int:id_movimiento>', methods=['GET', 'POST'])
def editar_movimiento(id_movimiento):
    if 'usuario' not in session or not session['usuario']['esAdmin']:
        return redirect('/')

    # Captura de parámetros GET para mantener el filtro al volver
    fecha = request.args.get('fecha', '')
    usar_filtro = request.args.get('usar_filtro', '')
    id_empleado = request.args.get('idEmpleado', '')

    conexion = obtener_conexion()
    cursor = conexion.cursor()

    if request.method == 'POST':
        tipo = request.form['idTipoMovimiento']
        semana = request.form['semana']
        horas = request.form['cantidadHoras']
        monto = request.form['monto']
        id_usuario = session['usuario']['id']
        ip = request.remote_addr

        mensaje = ""
        tipos_movimiento = []

        try:
            # Consultar datos previos
            cursor.execute("""
                DECLARE @out INT;
                EXEC dbo.SP_ConsultarMovimientoPorId
                    @inId = ?,
                    @outResultCode = @out OUTPUT;
            """, (id_movimiento,))
            fila = cursor.fetchone()
            columnas = [col[0] for col in cursor.description]
            datos = dict(zip(columnas, fila))
            cursor.nextset()

            id_empleado_mov = datos['idEmpleado']
            creado_por_sistema = datos['creadoPorSistema']

            # Ejecutar actualización
            cursor.execute("""
                DECLARE @out INT;
                EXEC dbo.SP_EditarMovimiento 
                    @inId = ?,
                    @inIdEmpleado = ?,
                    @inIdTipoMovimiento = ?,
                    @inSemana = ?,
                    @inCantidadHoras = ?,
                    @inMonto = ?,
                    @inCreadoPorSistema = ?,
                    @inIdPostByUser = ?,
                    @inPostInIP = ?,
                    @outResultCode = @out OUTPUT;
                SELECT @out AS resultado;
            """, (
                id_movimiento, id_empleado_mov, tipo, semana, horas, monto,
                creado_por_sistema, id_usuario, ip
            ))

            result = cursor.fetchone()
            cursor.nextset()

            if result and result[0] == 0:
                conexion.commit()
                conexion.close()
                # Redirección con filtros restaurados
                redireccion = f"/admin/movimientos?fecha={fecha}"
                if usar_filtro == '1':
                    redireccion += f"&usar_filtro=1&idEmpleado={id_empleado}"
                return redirect(redireccion)

            mensaje = f"Error al editar movimiento. Código: {result[0] if result else 'desconocido'}"

        except Exception as e:
            conexion.rollback()
            mensaje = f"Error inesperado: {e}"

        try:
            cursor.execute("DECLARE @out INT; EXEC dbo.SP_ListarTiposMovimiento @outResultCode = @out OUTPUT;")
            tipos_movimiento = cursor.fetchall()
            cursor.nextset()
        except:
            mensaje += " Error cargando catálogos."

        conexion.close()
        return render_template("admin/editar_movimiento.html",
                               mensaje=mensaje,
                               movimiento={
                                   'id': id_movimiento,
                                   'idTipoMovimiento': int(tipo),
                                   'semana': semana,
                                   'cantidadHoras': horas,
                                   'monto': monto
                               },
                               tipos_movimiento=tipos_movimiento,
                               usuario=session['usuario'])

    else:
        try:
            cursor.execute("""
                DECLARE @out INT;
                EXEC dbo.SP_ConsultarMovimientoPorId
                    @inId = ?,
                    @outResultCode = @out OUTPUT;
            """, (id_movimiento,))
            movimiento = cursor.fetchone()
            columnas = [col[0] for col in cursor.description]
            movimiento_dict = dict(zip(columnas, movimiento))
            cursor.nextset()

            cursor.execute("DECLARE @out INT; EXEC dbo.SP_ListarTiposMovimiento @outResultCode = @out OUTPUT;")
            tipos_movimiento = cursor.fetchall()
            cursor.nextset()

        except Exception as e:
            conexion.close()
            return f"Error cargando datos: {e}", 500

        conexion.close()
        return render_template("admin/editar_movimiento.html",
                               movimiento=movimiento_dict,
                               tipos_movimiento=tipos_movimiento,
                               usuario=session['usuario'])
