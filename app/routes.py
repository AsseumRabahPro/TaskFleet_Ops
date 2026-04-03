from flask import Blueprint, jsonify, request
from sqlalchemy.exc import SQLAlchemyError

from app.extensions import db
from app.models import Task

api = Blueprint("api", __name__)


@api.get("/tasks")
def get_tasks():
    tasks = Task.query.order_by(Task.id.asc()).all()
    return jsonify([task.to_dict() for task in tasks]), 200


@api.post("/tasks")
def create_task():
    payload = request.get_json(silent=True) or {}
    title = (payload.get("title") or "").strip()

    if not title:
        return jsonify({"error": "Le champ 'title' est obligatoire."}), 400

    try:
        task = Task(title=title)
        db.session.add(task)
        db.session.commit()
        return jsonify(task.to_dict()), 201
    except SQLAlchemyError:
        db.session.rollback()
        return jsonify({"error": "Erreur base de donnees lors de la creation."}), 500


@api.delete("/tasks/<int:task_id>")
def delete_task(task_id: int):
    task = db.session.get(Task, task_id)
    if task is None:
        return jsonify({"error": "Tache introuvable."}), 404

    try:
        db.session.delete(task)
        db.session.commit()
        return jsonify({"message": "Tache supprimee."}), 200
    except SQLAlchemyError:
        db.session.rollback()
        return jsonify({"error": "Erreur base de donnees lors de la suppression."}), 500
