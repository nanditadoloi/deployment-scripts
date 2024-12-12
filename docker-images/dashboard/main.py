from flask import Flask, request, Response, jsonify
import boto3
from flask_cors import CORS
import io
import requests
import time
from kubernetes import client, config, watch
kubeconfig_path = "/app/kube-config"

# Load the specified kubeconfig file
config.load_kube_config(config_file=kubeconfig_path)

# Initialize API client
v1 = client.CoreV1Api()

# Watch the endpoints of the service
service_name = "vod-np-service-us-west-1"
namespace = "default"  # Replace with your namespace

w = watch.Watch()
try:
    for event in w.stream(v1.list_namespaced_endpoints, namespace=namespace):
        endpoints = event['object']
        if endpoints.metadata.name == service_name:
            print(f"Event Type: {event['type']}")
            for subset in endpoints.subsets:
                addresses = subset.addresses if subset.addresses else []
                for address in addresses:
                    print(f"Pod IP: {address.ip}")
except Exception as e:
    print(f"Error: {e}")
finally:
    w.stop()

app = Flask(__name__)

# Enable CORS for the entire app
CORS(app)

if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0', port=5000)
