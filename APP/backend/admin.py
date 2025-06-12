from flask import Blueprint, render_template, session, redirect

ruta_admin = Blueprint('admin', __name__)

@ruta_admin.route("/admin/menu")
def menu_admin():
    if 'usuario' not in session or session['usuario']['tipo'] != 'admin':
        return redirect("/login")
    return render_template("admin/menu.html", usuario=session['usuario'])
