from flask import Blueprint, render_template, request, session, redirect
from backend.conexion import obtener_conexion
import json

ruta_bitacora_admin = Blueprint('ruta_bitacora_admin', __name__)

@ruta_bitacora_admin.route('/admin/bitacora')
def ver_bitacora_admin():
    if 'usuario' not in session or not session['usuario']['esAdmin']:
        return redirect('/')

    bitacora = []

    try:
        conexion = obtener_conexion()
        cursor = conexion.cursor()

        # Ejecutar el SP
        cursor.execute("""
            DECLARE @outResultCode INT;
            EXEC dbo.SP_ListarBitacoraEventos
                @outResultCode = @outResultCode OUTPUT;
        """)
        columnas = [col[0] for col in cursor.description]
        eventos = cursor.fetchall()

        # Convertir a lista de diccionarios y formatear JSON
        for fila in eventos:
            fila_dict = dict(zip(columnas, fila))

            for campo in ['jsonAntes', 'jsonDespues']:
                if fila_dict[campo]:
                    try:
                        json_formateado = json.loads(fila_dict[campo])
                        fila_dict[campo] = json.dumps(json_formateado, indent=2, ensure_ascii=False)
                    except Exception:
                        # Si no es JSON válido, dejar el valor original
                        pass
                else:
                    fila_dict[campo] = None

            bitacora.append(fila_dict)

        cursor.nextset()
        conexion.close()

    except Exception as e:
        return f"Error cargando bitácora: {e}", 500

    return render_template('admin/bitacora.html', bitacora=bitacora)
