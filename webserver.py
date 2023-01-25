from flask import (Flask, send_file, url_for, jsonify, render_template)
import sys
import os

# webserver for download client config

app = Flask(__name__)

@app.route('/client.conf')
def download():
    path = 'client.conf'
    return send_file(path, as_attachment=True)

@app.route('/')
def main():
    return """
      try this:</br>
        curl http://{{ inventory_hostname }}:{{ pywebexec_port }}/jps</br>
        curl http://{{ inventory_hostname }}:{{ pywebexec_port }}/restart-service</br>
    """


if __name__ == '__main__':
    try:
        app.run(debug=True,host='0.0.0.0',port=8888)
    #    except IOError as (errno, strerror):
    #        print("I/O error({0}): {1}".format(errno, strerror))
    #        sys.exit(33)
    except Exception as e:
        #logging.error(e):
        print('cannot start daemon ... maybe its already running ?')
        sys.exit(34)
