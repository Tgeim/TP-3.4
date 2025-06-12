from flask import Blueprint, render_template, request, redirect, url_for, session
from backend.conexion import obtener_conexion
import hashlib

ruta_login = Blueprint('ruta_login', __name__)

@ruta_login.route('/', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        usuario = request.form['usuario']
        contrasena = request.form['contrasena']

        # Convertimos la contraseña a hash SHA-256 como lo espera el SP
        hash_password = hashlib.sha256(contrasena.encode()).hexdigest()

        conexion = obtener_conexion()
        cursor = conexion.cursor()

        try:
            cursor.execute("""
                DECLARE @outIdUsuario INT,
                        @outEsAdministrador BIT,
                        @outResultCode INT;

                EXEC dbo.SP_Login
                    @inUsername = ?,
                    @inPasswordHash = ?,
                    @inPostInIP = ?,
                    @outIdUsuario = @outIdUsuario OUTPUT,
                    @outEsAdministrador = @outEsAdministrador OUTPUT,
                    @outResultCode = @outResultCode OUTPUT;

                SELECT @outIdUsuario AS idUsuario,
                       @outEsAdministrador AS esAdministrador,
                       @outResultCode AS resultCode;
            """, (usuario, hash_password, request.remote_addr))

            resultado = cursor.fetchone()

            if resultado.resultCode == 0:
                session['usuario'] = {
                    'id': resultado.idUsuario,
                    'es_admin': resultado.esAdministrador
                }

                if resultado.esAdministrador:
                    return redirect(url_for('ruta_admin.admin_home'))
                else:
                    return redirect(url_for('ruta_usuario.usuario_home'))
            else:
                return render_template('login.html', mensaje='Credenciales incorrectas.')

        except Exception as e:
            print("Error al intentar login:", e)
            return render_template('login.html', mensaje='Ocurrió un error inesperado.')

        finally:
            conexion.close()
    else:
        return render_template('login.html')
