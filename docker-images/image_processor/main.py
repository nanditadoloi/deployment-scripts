from flask import Flask, request, send_file
from flask_cors import CORS
from PIL import Image
import io

app = Flask(__name__)

# Enable CORS for the entire app
CORS(app)

@app.route('/upload', methods=['POST'])
def upload_image():
    if 'image' not in request.files:
        return "No image found in request", 400

    # Retrieve the uploaded image
    image_file = request.files['image']

    # Open the image using PIL
    image = Image.open(image_file)

    # Example processing: convert the image to grayscale
    processed_image = image.convert('L')

    # Save the processed image to a BytesIO object
    img_io = io.BytesIO()
    processed_image.save(img_io, 'PNG')
    img_io.seek(0)

    # Send the processed image back to the client
    return send_file(img_io, mimetype='image/png')

if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0', port=5000)