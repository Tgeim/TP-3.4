from flask import Flask, redirect, url_for, session, render_template
from backend.login import ruta_login
from backend.empleados import ruta_empleados
from backend.insertar_empleado import ruta_insertar_empleado

app = Flask(__name__)
app.secret_key = 'clave_secreta_segura'

# Registrar blueprints
app.register_blueprint(ruta_login)
app.register_blueprint(ruta_empleados)
app.register_blueprint(ruta_insertar_empleado)
# Ruta raíz
@app.route('/')
def inicio():

    if 'usuario' in session:
        if session['usuario']['esAdmin']:
            return redirect(url_for('menu_admin'))
        else:
            return redirect(url_for('menu_empleado'))
    return redirect(url_for('ruta_login.login'))

# Menú de administrador
@app.route('/menu_admin')
def menu_admin():
    if 'usuario' not in session or not session['usuario']['esAdmin']:
        return redirect('/')
    return render_template('menu_admin.html', usuario=session['usuario'])

# Menú de empleado
@app.route('/menu_empleado')
def menu_empleado():
    if 'usuario' not in session or session['usuario']['esAdmin']:
        return redirect('/')
    return render_template('menu_empleado.html', usuario=session['usuario'])

if __name__ == '__main__':
    app.run(debug=True)
