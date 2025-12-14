#!/usr/bin/env python3
"""
简单的 Flask 应用示例
"""

from flask import Flask, jsonify
import os
import datetime

app = Flask(__name__)

@app.route('/')
def index():
    """主页"""
    return jsonify({
        'message': 'Hello from Python 3.11-slim Docker container!',
        'timestamp': datetime.datetime.now().isoformat(),
        'version': '1.0.0'
    })

@app.route('/health')
def health():
    """健康检查端点"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.datetime.now().isoformat()
    })

@app.route('/info')
def info():
    """系统信息"""
    return jsonify({
        'python_version': os.sys.version,
        'hostname': os.uname().nodename if hasattr(os, 'uname') else 'unknown',
        'environment': os.getenv('ENVIRONMENT', 'development')
    })

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8000))
    debug = os.getenv('DEBUG', 'False').lower() == 'true'
    
    app.run(
        host='0.0.0.0',
        port=port,
        debug=debug
    ) 