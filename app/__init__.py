import time

from flask import Flask, jsonify
from sqlalchemy.exc import OperationalError

from app.config import Config
from app.extensions import db


def create_app() -> Flask:
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)

    from app.routes import api

    app.register_blueprint(api)

    @app.get("/health")
    def healthcheck():
        return jsonify({"status": "ok"}), 200

    with app.app_context():
        # Postgres can be up but not ready yet; retry table creation briefly.
        max_attempts = 15
        for attempt in range(1, max_attempts + 1):
            try:
                db.create_all()
                break
            except OperationalError:
                if attempt == max_attempts:
                    raise
                time.sleep(2)

    return app
