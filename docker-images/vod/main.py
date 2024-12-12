from flask import Flask, request, Response, jsonify
import boto3
from flask_cors import CORS
import io
import requests
import time

app = Flask(__name__)

# Enable CORS for the entire app
CORS(app)

# Define a function to detect the current AWS region
# This function calls an AWS service to know about the region in which this app is running.
# Based on this region, this app will choose the s3 bucket of that region to serve the video,
# because the video file is copied to all the regions.
def get_instance_region():
    try:
        # Request a token for accessing IMDSv2 (Instance Metadata Service v2)
        token_response = requests.put(
            'http://169.254.169.254/latest/api/token',
            headers={'X-aws-ec2-metadata-token-ttl-seconds': '21600'},
            timeout=2
        )
        token = token_response.text

        # Fetch the instance identity document containing region info
        metadata_response = requests.get(
            'http://169.254.169.254/latest/dynamic/instance-identity/document',
            headers={'X-aws-ec2-metadata-token': token},
            timeout=2
        )
        metadata = metadata_response.json()
        return metadata.get('region')
    except requests.RequestException as e:
        print(f"Error fetching instance metadata: {e}")
        return None

# Mapping regions to S3 bucket names
BUCKET_MAPPING = {
    'ap-south-1': 'my-unique-vod-bucket-ap-south-1',
    'us-east-1': 'my-unique-vod-bucket-us-east-1',
    'us-west-1': 'my-unique-vod-bucket-us-west-1'
}

# Get the current region
current_region = get_instance_region()

# Get the S3 bucket name based on the region
BUCKET_NAME = BUCKET_MAPPING.get(current_region, 'default-bucket')

print("SELECTED BUCKET NAME", BUCKET_NAME, "CURRENT REGION", current_region)

# Initialize S3 client
s3 = boto3.client(
    's3'
)

def stream_from_s3(key):
    """Stream content from S3."""
    s3_response = s3.get_object(Bucket=BUCKET_NAME, Key=key)
    return s3_response['Body'].iter_chunks()

# Health check route
@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy"}), 200

# Provide region information and current timestamp for latency
@app.route('/info', methods=['GET'])
def get_info():
    region = get_instance_region()
    current_time = time.time()  # Current timestamp
    return jsonify({"region": region, "timestamp": current_time})

# Serve the master.m3u8 playlist
@app.route('/video/<video_id>/master.m3u8')
def get_master_playlist(video_id):
    # Stream the master playlist (.m3u8) from S3
    master_key = f'videos/{video_id}/master.m3u8'
    return Response(stream_from_s3(master_key), content_type='application/vnd.apple.mpegurl')

# Serve variant stream playlists (e.g., stream_0, stream_1)
@app.route('/video/<video_id>/<stream_id>/playlist.m3u8')
def get_stream_playlist(video_id, stream_id):
    # Stream the specific variant stream playlist (.m3u8) from S3
    playlist_key = f'videos/{video_id}/{stream_id}/playlist.m3u8'
    return Response(stream_from_s3(playlist_key), content_type='application/vnd.apple.mpegurl')

# Serve individual video segments (.ts) for a specific stream
@app.route('/video/<video_id>/<stream_id>/<segment>')
def get_segment(video_id, stream_id, segment):
    # Stream the video segment (.ts) from S3
    segment_key = f'videos/{video_id}/{stream_id}/{segment}'
    return Response(stream_from_s3(segment_key), content_type='video/MP2T')

if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0', port=5000)
