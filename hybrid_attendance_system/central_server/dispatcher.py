from werkzeug.middleware.dispatcher import DispatcherMiddleware
from werkzeug.serving import run_simple
from admin_app import app as admin_app_instance
from cr_app import app as cr_app_instance
from student_app import app as student_app_instance

# Mount the apps on URL prefixes
application = DispatcherMiddleware(student_app_instance, {
    '/admin': admin_app_instance,
    '/cr': cr_app_instance
})

if __name__ == "__main__":
    # To access:
    # Student App: http://<server_ip>:5000/
    # Admin App: http://<server_ip>:5000/admin/login
    # CR App: http://<server_ip>:5000/cr/login
    run_simple('0.0.0.0', 5000, application, use_reloader=True, use_debugger=True)