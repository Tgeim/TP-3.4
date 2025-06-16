from flask import Flask, redirect, url_for, session, render_template
from backend.login import ruta_login
from backend.empleados import ruta_empleados
from backend.insertar_empleado import ruta_insertar_empleado
from backend.editar_empleado import ruta_editar_empleado 
from backend.eliminar_empleado import ruta_eliminar_empleado
from backend.listar_movimientos import ruta_movimientos
from backend.editar_movimiento import ruta_editar_movimiento
from backend.eliminar_movimiento import ruta_eliminar_movimiento

app = Flask(__name__)
app.secret_key = 'clave_secreta_segura'

# Registrar blueprints
app.register_blueprint(ruta_login)
app.register_blueprint(ruta_empleados)
app.register_blueprint(ruta_insertar_empleado)
app.register_blueprint(ruta_editar_empleado)
app.register_blueprint(ruta_eliminar_empleado)
app.register_blueprint(ruta_movimientos)
app.register_blueprint(ruta_editar_movimiento)
app.register_blueprint(ruta_eliminar_movimiento)

# Ruta raíz
@app.route('/')
def inicio():
    if 'usuario' in session:
        return redirect(url_for('menu_admin' if session['usuario']['esAdmin'] else 'menu_empleado'))
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
