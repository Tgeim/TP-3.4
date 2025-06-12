from flask import Flask, redirect, url_for, session
from backend.login import ruta_login


app = Flask(__name__)
app.secret_key = 'clave_secreta_segura'

# Registro de funcionalidades
app.register_blueprint(ruta_login)

@app.route('/')
def inicio():
    if 'tipoUsuario' in session:
        if session['tipoUsuario'] == 'admin':
            return redirect(url_for('admin_menu'))
        elif session['tipoUsuario'] == 'empleado':
            return redirect(url_for('empleado_menu'))
    return redirect(url_for('ruta_login.login'))

if __name__ == '__main__':
    app.run(debug=True)
