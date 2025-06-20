from flask import Blueprint, render_template, request, redirect, session
from backend.conexion import obtener_conexion
import socket

ruta_login = Blueprint('ruta_login', __name__)

@ruta_login.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        usuario = request.form['usuario']
        contrasena = request.form['contrasena']
        ip_local = socket.gethostbyname(socket.gethostname())

        conn = obtener_conexion()
        cursor = conn.cursor()
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
        """, (usuario, contrasena, ip_local))

        result = cursor.fetchone()
        conn.close()

        if result and result.resultCode == 0:
            session['usuario'] = {
                'id': result.idUsuario,
                'username': usuario,
                'esAdmin': bool(result.esAdministrador)
            }
            if result.esAdministrador:
                return redirect('/menu_admin')
            else:
                return redirect('/menu_empleado')
        else:
            return render_template('login.html',
                                   error='Credenciales inválidas.',
                                   usuario=usuario)

    return render_template('login.html', usuario='')

@ruta_login.route('/logout')
def logout():
    session.clear()
    return redirect('/login')
