from flask import Blueprint, render_template, request, redirect, session
from backend.conexion import obtener_conexion
import hashlib

ruta_login = Blueprint('ruta_login', __name__)

@ruta_login.route('/', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        usuario = request.form['usuario']
        contrasena = request.form['contrasena']
        ip_cliente = request.remote_addr

        # Hasheamos la contraseña
        hash_obj = hashlib.sha256(contrasena.encode())
        contrasena_hash = hash_obj.hexdigest()

        conexion = obtener_conexion()
        try:
            with conexion.cursor() as cursor:
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
                """, usuario, contrasena_hash, ip_cliente)

                resultado = cursor.fetchone()

                if resultado and resultado.resultCode == 0:
                    session['idUsuario'] = resultado.idUsuario
                    session['esAdministrador'] = resultado.esAdministrador
                    session['usuario'] = usuario

                    if resultado.esAdministrador:
                        return render_template('menu_admin.html')
                    else:
                        return render_template('menu_usuario.html')

                else:
                    return render_template('login.html', mensaje='Credenciales inválidas.')

        finally:
            conexion.close()

    return render_template('login.html')
