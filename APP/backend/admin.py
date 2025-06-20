from flask import Blueprint, render_template, session, redirect

ruta_admin = Blueprint('admin', __name__)

@ruta_admin.route("/menu_admin")
def menu_admin():
    if 'usuario' not in session or not session['usuario']['esAdmin']:
        return redirect("/")
    return render_template("admin/menu.html", usuario=session['usuario'])
