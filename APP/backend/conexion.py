import pyodbc

def obtener_conexion():
    try:
        conexion = pyodbc.connect(
            'DRIVER={ODBC Driver 17 for SQL Server};'
            'SERVER=pastafari.database.windows.net;'
            'DATABASE=BOSS PASTAFARI;'
            'UID=AdminBD@pastafari;'
            'PWD=Bases123;'
            'TrustServerCertificate=yes;'
        )
        return conexion
    except Exception as e:
        raise Exception(f"Error al conectar a la base de datos: {str(e)}")
