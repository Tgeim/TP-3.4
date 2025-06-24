from flask import Blueprint, render_template, session, redirect
from backend.conexion import obtener_conexion

ruta_admin = Blueprint('admin', __name__)

@ruta_admin.route("/menu_admin")
def menu_admin():
    if 'usuario' not in session or not session['usuario']['esAdmin']:
        return redirect("/")

    conexion = obtener_conexion()
    cursor = conexion.cursor()
    print(">>> Entrando a menu_admin")
    try:
        # Ejecutar el SP
        cursor.execute("""
            DECLARE @outResultCode INT;
            EXEC dbo.SP_ListarEmpleados @outResultCode = @outResultCode OUTPUT;
        """)

        # Avanzar hasta encontrar un resultset con columnas
        while cursor.description is None:
            if not cursor.nextset():
                break

        empleados = cursor.fetchall() if cursor.description else []
        columnas = [col[0] for col in cursor.description] if cursor.description else []
        empleados_dict = [dict(zip(columnas, fila)) for fila in empleados]


    except Exception as e:

        empleados_dict = []

    finally:
        conexion.close()

    return render_template("menu_admin.html", usuario=session['usuario'], empleados=empleados_dict)
