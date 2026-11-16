import psycopg
from flask import Flask, jsonify, redirect, render_template, request, url_for
from psycopg.rows import dict_row

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 8192


def connect():
    # libpq читает PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD.
    return psycopg.connect(connect_timeout=3, row_factory=dict_row)


with connect() as conn:
    conn.execute('''CREATE TABLE IF NOT EXISTS notes (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        text TEXT NOT NULL CHECK (char_length(text) BETWEEN 1 AND 500),
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )''')


@app.get('/')
def index():
    with connect() as conn:
        notes = conn.execute('SELECT * FROM notes ORDER BY id DESC LIMIT 100').fetchall()
    return render_template('index.html', notes=notes)


@app.post('/notes')
def create_note():
    text = request.form.get('text', '').strip()
    if not 1 <= len(text) <= 500:
        return 'Введите от 1 до 500 символов.', 400
    with connect() as conn:
        conn.execute('INSERT INTO notes (text) VALUES (%s)', (text,))
    return redirect(url_for('index'), code=303)


@app.get('/health')
def health():
    with connect() as conn:
        conn.execute('SELECT 1 FROM notes LIMIT 1')
    return jsonify(status='ok', database='connected')


@app.errorhandler(psycopg.Error)
def database_error(error):
    app.logger.error('Database operation failed: %s', type(error).__name__)
    return jsonify(status='error', database='unavailable'), 503
