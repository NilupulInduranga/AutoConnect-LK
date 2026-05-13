from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from fraud_detection import FraudDetector
from image_recognition import ImageClassifier

app = FastAPI()
fraud_detector = FraudDetector()
image_classifier = ImageClassifier()

class ListingItem(BaseModel):
    seller_id: str
    title: str
    description: str
    price: float
    category: str
    image_url: str
    vehicle_model: str

class ImageItem(BaseModel):
    image_url: str

@app.get("/")
def read_root():
    return {"message": "AutoConnect AI Service Running"}

@app.post("/analyze_listing")
def analyze_listing(item: ListingItem):
    try:
        result = fraud_detector.analyze_listing(item.dict())
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/analyze_image")
def analyze_image(item: ImageItem):
    try:
        result = image_classifier.predict(item.image_url)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
