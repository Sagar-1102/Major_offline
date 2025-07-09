import numpy as np
from scipy.spatial.distance import cosine

class FaceRecognitionCore:
    def __init__(self, threshold=0.40):
        self.threshold = threshold
        self.known_face_embeddings = []
        self.known_face_ids = []
        self.known_face_names = []

    def load_known_faces(self, users):
        for user_id, name, embeddings in users:
            for emb in embeddings:
                self.known_face_embeddings.append(np.array(emb))
                self.known_face_ids.append(user_id)
                self.known_face_names.append(name)
        print(f"Loaded embeddings for {len(set(self.known_face_ids))} students.")

    def find_matching_face(self, face_embedding):
        if not self.known_face_embeddings: return None, None
        distances = [cosine(face_embedding, emb) for emb in self.known_face_embeddings]
        min_dist_idx = np.argmin(distances)
        if distances[min_dist_idx] <= self.threshold:
            return self.known_face_ids[min_dist_idx], self.known_face_names[min_dist_idx]
        return None, None