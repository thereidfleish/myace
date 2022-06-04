"""The app module, containing the app factory function."""

from flask import Flask
from flask import send_file, request

from .routes import routes, success_response, failure_response
from .models import db, User
from .settings import (
    AWS_ACCESS_KEY_ID,
    AWS_SECRET_ACCESS_KEY,
    CF_PUBLIC_KEY_ID,
    CF_PRIVATE_KEY,
    VIEW_DOCS_KEY,
)
from .extensions import db, login_manager


def create_app(test_config=None):
    """The application factory. Create and configure an app instance."""
    app = Flask(__name__)
    # Load config from settings.py
    app.config.from_pyfile("settings.py")
    register_extensions(app)
    register_routes(app)
    return app


def register_extensions(app) -> None:
    """Register Flask extensions."""
    # SQLAlchemy
    db.init_app(app)
    with app.app_context():
        db.create_all()

    # Flask-Login config and callbacks
    login_manager.init_app(app)

    @login_manager.user_loader
    def load_user(user_id):
        # Return user object if user exists or None if DNE
        user = User.query.filter_by(id=user_id).first()
        return user

    @login_manager.unauthorized_handler
    def unauthorized():
        return failure_response("User not authorized.", 401)


def register_routes(app) -> None:
    """Register all blueprints and misc routes."""
    # routes contains all API routes
    app.register_blueprint(routes)

    @app.route("/health/")
    def health_check():
        return success_response({"status": "OK"})

    @app.route("/docs")
    def docs():
        key = request.args.get("key")
        if key != VIEW_DOCS_KEY:
            return failure_response("Invalid key!", 401)
        return send_file("docs.html")

    # apple token retriever
    @app.route("/appletokenprinter")
    def docs():
        key = request.args.get("key")
        if key != VIEW_DOCS_KEY:  # same key
            return failure_response("Invalid key!", 401)
        return send_file("applebutton.html")
