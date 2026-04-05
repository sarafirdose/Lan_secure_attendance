import numpy as np
from datetime import datetime, timedelta

class MLService:
    @staticmethod
    def predict_attendance_risk(history):
        """
        history: List of attendance records [(date, status), ...]
        status: 1 for present, 0 for absent
        """
        if len(history) < 5:
            return {"risk": "Insufficient Data", "prediction": None, "confidence": 0}

        # Convert history to numerical format (days since start, status)
        start_date = datetime.fromisoformat(history[0][0])
        x = np.array([(datetime.fromisoformat(h[0]) - start_date).days for h in history]).reshape(-1, 1)
        y = np.array([1 if h[1] == 'present' or h[1] == 'late' else 0 for h in history])

        # Simple Linear Regression (y = mx + b)
        # We want to see the trend of attendance over time
        if len(np.unique(x)) < 2:
            current_pct = np.mean(y) * 100
            return {
                "risk": "Low" if current_pct >= 75 else "High",
                "prediction": current_pct,
                "confidence": 0.5
            }

        # Fit line
        m, b = np.polyfit(x.flatten(), y, 1)
        
        # Predict 30 days into the future
        future_day = x[-1][0] + 30
        prediction = m * future_day + b
        prediction_pct = max(0, min(100, prediction * 100))

        # Risk Assessment
        risk = "Safe"
        if prediction_pct < 75:
            risk = "Critical"
        elif prediction_pct < 85:
            risk = "Warning"

        return {
            "risk": risk,
            "prediction": round(prediction_pct, 2),
            "trend": "improving" if m > 0 else "declining",
            "confidence": min(0.9, 0.5 + (len(history) / 100))
        }

    @staticmethod
    def get_smart_recommendation(teacher_history, current_time=None):
        """
        Analyzes teacher's behavior to suggest which class to start.
        """
        if not current_time:
            current_time = datetime.now()
            
        current_hour = current_time.hour
        current_weekday = current_time.weekday()

        # Simple rule-based 'intelligence' for now, can be upgraded to clustering
        recommendations = []
        for entry in teacher_history:
            # entry: {'subject': '...', 'class_label': '...', 'timestamp': '...'}
            ts = datetime.fromisoformat(entry['timestamp'])
            if ts.weekday() == current_weekday and abs(ts.hour - current_hour) <= 1:
                recommendations.append(entry)

        if not recommendations:
            return None

        # Return the most frequent recommendation for this slot
        counts = {}
        # Relaxation: If no exact hour match, include all for current day
        if not recommendations:
            for entry in teacher_history:
                ts = datetime.fromisoformat(entry['timestamp'])
                if ts.weekday() == current_weekday:
                    recommendations.append(entry)

        if not recommendations:
            return None

        # Return the most frequent recommendation
        for r in recommendations:
            key = f"{r['subject']}|{r['class_label']}"
            counts[key] = counts.get(key, 0) + 1
        
        best_match = max(counts, key=counts.get)
        subject, class_label = best_match.split('|')
        
        return {
            "subject": subject,
            "class_label": class_label,
            "confidence": min(0.95, counts[best_match] / len(recommendations))
        }
