from flask import Blueprint, redirect, session, request
from backend.conexion import obtener_conexion

ruta_eliminar_movimiento = Blueprint('ruta_eliminar_movimiento', __name__)

@ruta_eliminar_movimiento.route('/admin/eliminar_movimiento/<int:id_movimiento>', methods=['POST'])
def eliminar_movimiento(id_movimiento):
    if 'usuario' not in session or not session['usuario']['esAdmin']:
        return redirect('/')

    conexion = obtener_conexion()
    cursor = conexion.cursor()

    try:
        cursor.execute("""
            DECLARE @out INT;
            EXEC dbo.SP_EliminarMovimiento
                @inId = ?,
                @inIdPostByUser = ?,
                @inPostInIP = ?,
                @outResultCode = @out OUTPUT;
            SELECT @out AS resultado;
        """, (
            id_movimiento,
            session['usuario']['id'],
            request.remote_addr
        ))

        resultado = cursor.fetchone()
        cursor.nextset()

        if resultado and resultado[0] == 0:
            conexion.commit()
        else:
            conexion.rollback()

    except:
        conexion.rollback()
    finally:
        conexion.close()

    return redirect('/admin/movimientos')
