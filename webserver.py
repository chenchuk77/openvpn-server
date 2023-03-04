from flask import (Flask, send_file, url_for, jsonify, render_template)
import sys
import os

# webserver for download client config (ssl)

app = Flask(__name__)

# windows client must be different and needs the same file as *.ovpn
@app.route('/conf/<name>')
def download_for_windows(name):
    path = '{}.ovpn'.format(name)
    return send_file(path, as_attachment=True)


if __name__ == '__main__':
    try:
        # app.run(debug=True,host='0.0.0.0',port=8888, ssl_context=('cert.pem', 'key.pem'))
        app.run(debug=True,host='0.0.0.0',port=443, ssl_context=('cert.pem', 'key.pem'))
    except Exception as e:
        print('cannot start daemon ... maybe its already running ?')
        sys.exit(34)
