import re

class FraudDetector:
    def __init__(self):
        self.suspicious_keywords = [
            "urgent", "cash only", "no returns", "wire transfer", 
            "western union", "gift card", "too good to be true", 
            "duplicate", "copy", "scam", "bank transfer", "deposit"
        ]
        
        # Approximate price ranges (LKR)
        self.category_price_ranges = {
            "Engine": (50000, 1500000),
            "Body": (5000, 100000),
            "Electrical": (2000, 80000),
            "Suspension": (10000, 200000),
            "Audio": (5000, 150000),
            "Accessories": (1000, 50000),
            "Wheels": (20000, 300000),
            "Interior": (5000, 100000)
        }

    def detect_text_anomaly(self, text: str) -> float:
        text_lower = text.lower()
        score = 0.0
        
        # Keyword check
        for word in self.suspicious_keywords:
            if word in text_lower:
                score += 0.25
        
        # CAPS LOCK check (shouting)
        if len(text) > 10 and text.upper() == text:
            score += 0.2
            
        # Excessive punctuation check
        if text.count('!') > 3 or text.count('$') > 3:
            score += 0.15

        return min(score, 1.0)

    def detect_price_anomaly(self, price: float, category: str) -> float:
        if price <= 0: return 1.0 # Invalid price
        
        safe_range = self.category_price_ranges.get(category, (1000, 1000000))
        min_price, max_price = safe_range
        
        if price < min_price * 0.3: # Suspiciously cheap (70% below min)
            return 0.7
        if price > max_price * 3.0: # Suspiciously expensive
            return 0.4
            
        return 0.0

    def analyze_listing(self, listing_data: dict) -> dict:
        title = listing_data.get('title', '')
        description = listing_data.get('description', '')
        price = listing_data.get('price', 0)
        category = listing_data.get('category', 'Accessories')
        
        text_risk = self.detect_text_anomaly(title + " " + description)
        price_risk = self.detect_price_anomaly(price, category)
        
        # Weighted Score
        total_risk = (text_risk * 0.5) + (price_risk * 0.5)
        
        status = "approved"
        if total_risk > 0.7:
            status = "rejected" # High risk, auto-reject
        elif total_risk > 0.4:
            status = "pending_review" # Medium risk, manual review
        
        return {
            "risk_score": round(total_risk, 2),
            "status": status,
            "details": {
                "text_risk": round(text_risk, 2),
                "price_risk": round(price_risk, 2),
            }
        }
