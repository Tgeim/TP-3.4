from flask import Blueprint, render_template, session, redirect
from backend.conexion import obtener_conexion

ruta_empleados = Blueprint('ruta_empleados', __name__)

@ruta_empleados.route('/admin/empleados')
def listar_empleados():
    # Verifica que sea un administrador autenticado
    if 'usuario' not in session or not session['usuario']['esAdmin']:
        return redirect('/')

    conexion = obtener_conexion()
    cursor = conexion.cursor()

    try:
        # Ejecuta el SP que retorna el SELECT de empleados y un OUTPUT
        cursor.execute("""
            DECLARE @outResultCode INT;
            EXEC dbo.SP_ListarEmpleados @outResultCode = @outResultCode OUTPUT;
        """)

        # Obtener los empleados desde el primer conjunto de resultados
        empleados = cursor.fetchall()
        columnas = [col[0] for col in cursor.description]
        empleados_dict = [dict(zip(columnas, fila)) for fila in empleados]

        # Avanzar por si quedó un segundo conjunto con el SELECT @outResultCode
        while cursor.nextset():
            pass

    finally:
        conexion.close()

    # Renderizar plantilla con lista de empleados y sus datos
    return render_template('empleados/listar.html', empleados=empleados_dict, usuario=session['usuario'])
