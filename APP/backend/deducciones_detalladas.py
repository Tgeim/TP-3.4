from backend.conexion import obtener_conexion
import datetime

def obtener_deducciones_semanales(id_empleado: int, fecha_semana: str):
    conexion = obtener_conexion()
    cursor = conexion.cursor()

    try:
        fecha_obj = datetime.datetime.strptime(fecha_semana, "%Y-%m-%d").date()
        id_empleado = int(id_empleado)

        cursor.execute("""
            DECLARE @out INT;
            EXEC dbo.SP_ConsultarDeduccionesSemanalesPorEmpleado
                @inIdEmpleado = ?,
                @inFechaSemana = ?,
                @outResultCode = @out OUTPUT;
            SELECT @out AS resultado;
        """, (id_empleado, fecha_obj))

        # Primer conjunto: las deducciones
        deducciones = cursor.fetchall()
        columnas = [col[0] for col in cursor.description]

        # Segundo conjunto: el resultado
        cursor.nextset()
        resultado = cursor.fetchone()[0]

        if resultado != 0:
            return []

        return [dict(zip(columnas, fila)) for fila in deducciones]

    except Exception as e:
        print(f"Error al consultar deducciones semanales: {e}")
        return []
    finally:
        conexion.close()


def obtener_deducciones_mensuales(id_empleado: int, mes: str):
    conexion = obtener_conexion()
    cursor = conexion.cursor()

    try:
        if len(mes) == 7:  # Formato "YYYY-MM"
            mes += "-01"

        fecha_obj = datetime.datetime.strptime(mes, "%Y-%m-%d").date()
        id_empleado = int(id_empleado)
        anio = fecha_obj.year
        mes_num = fecha_obj.month

        cursor.execute("""
            DECLARE @out INT;
            EXEC dbo.SP_ConsultarDeduccionesMensualesPorEmpleado
                @inIdEmpleado = ?,
                @inMes = ?,
                @inAnio = ?,
                @outResultCode = @out OUTPUT;
            SELECT @out AS resultado;
        """, (id_empleado, mes_num, anio))

        # Leer deducciones primero
        columnas = [col[0] for col in cursor.description]
        deducciones = cursor.fetchall()

        # Mover al segundo resultset para leer el código de resultado
        cursor.nextset()
        resultado = cursor.fetchone()[0]

        if resultado != 0:
            return []
         
        return [dict(zip(columnas, fila)) for fila in deducciones]

    except Exception as e:
        print(f"Error al consultar deducciones mensuales: {e}")
        return []
    finally:
        conexion.close()
