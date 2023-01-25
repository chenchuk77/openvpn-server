from flask import (Flask, send_file, url_for, jsonify, render_template)
import sys
import os

# webserver for download client config

app = Flask(__name__)

@app.route('/client.conf')
def download():
    path = 'client.conf'
    return send_file(path, as_attachment=True)

if __name__ == '__main__':
    try:
        app.run(debug=True,host='0.0.0.0',port=8888)
    except Exception as e:
        print('cannot start daemon ... maybe its already running ?')
        sys.exit(34)
