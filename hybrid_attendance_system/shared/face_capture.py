from deepface import DeepFace
import numpy as np
import cv2

def get_embedding_from_image_bytes(image_bytes):
    try:
        nparr = np.frombuffer(image_bytes, np.uint8)
        img_np = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        embedding_objs = DeepFace.represent(
            img_path=img_np,
            model_name='FaceNet',
            detector_backend='mtcnn',
            enforce_detection=True
        )
        if embedding_objs and 'embedding' in embedding_objs[0]:
            return embedding_objs[0]['embedding']
    except Exception as e:
        print(f"Could not process image: {e}")
    return None