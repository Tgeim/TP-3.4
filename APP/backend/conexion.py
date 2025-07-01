import pyodbc

def obtener_conexion():
    try:
        conexion = pyodbc.connect(
        'DRIVER={ODBC Driver 17 for SQL Server};'
        'SERVER=localhost\\SQLEXPRESS;'
        'DATABASE=TP4;'  # o la base que hayas creado, por ejemplo 'TP4'
        'Trusted_Connection=yes;'
        )
        return conexion
    except Exception as e:
        raise Exception(f"Error al conectar a la base de datos: {str(e)}")
