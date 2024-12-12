import asyncio
import aiohttp
import time

# Number of concurrent requests
CONCURRENT_REQUESTS = 3_000

# The URL of your Flask app
URL = "http://13.233.133.210:30000/upload"

# Image to send in the POST request
IMAGE_PATH = "color.jpg"

async def send_request(session, image_data, request_num):
    """Send a POST request to upload an image."""
    try:
        async with session.post(URL, data={'image': image_data}) as response:
            status = response.status
            if status == 200:
                # Read the response as binary data
                result = await response.read()

                # # Save the result to a file to verify the processed image
                output_filename = f"processed_image_{request_num}.png"
                # with open(output_filename, 'wb') as f:
                #     f.write(result)

                print(f"Processed image saved as: {output_filename}")
            return status
    except Exception as e:
        print(f"Request failed: {e}")
        return None

async def run_load_test():
    """Simulates concurrent requests."""
    start_time = time.time()
    async with aiohttp.ClientSession() as session:
        with open(IMAGE_PATH, 'rb') as img_file:
            image_data = img_file.read()

        # Create tasks to send concurrent requests
        tasks = [send_request(session, image_data, i) for i in range(CONCURRENT_REQUESTS)]
        
        # Gather results
        responses = await asyncio.gather(*tasks)
    
    # Calculate time taken
    end_time = time.time()
    duration = end_time - start_time
    success_count = sum(1 for status in responses if status == 200)

    print(f"Total requests: {CONCURRENT_REQUESTS}")
    print(f"Successful requests: {success_count}")
    print(f"Total time taken: {duration:.2f} seconds")
    print(f"Requests per second: {CONCURRENT_REQUESTS / duration:.2f}")

if __name__ == "__main__":
    asyncio.run(run_load_test())