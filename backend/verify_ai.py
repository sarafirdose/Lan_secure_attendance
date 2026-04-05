import requests
import json
import time

BASE_URL = "http://127.0.0.1:5000"

def login(uid, password):
    res = requests.post(f"{BASE_URL}/login", json={"uid": uid, "password": password})
    if res.status_code == 200:
        return res.json()['token']
    return None

def test_student_risk(token, uid):
    headers = {"Authorization": f"Bearer {token}"}
    res = requests.get(f"{BASE_URL}/ai-predict?uid={uid}", headers=headers)
    print(f"--- Risk Analysis for {uid} ---")
    print(json.dumps(res.json(), indent=2))
    print()

def test_teacher_recommendation(token, uid):
    headers = {"Authorization": f"Bearer {token}"}
    res = requests.get(f"{BASE_URL}/ai-smart-recommend?uid={uid}", headers=headers)
    print(f"--- Smart Recommendation for {uid} ---")
    print(json.dumps(res.json(), indent=2))
    print()

def test_admin_insights(token):
    headers = {"Authorization": f"Bearer {token}"}
    res = requests.get(f"{BASE_URL}/ai-admin-insights", headers=headers)
    print(f"--- Admin Global Insights ---")
    print(json.dumps(res.json(), indent=2))
    print()

if __name__ == "__main__":
    print("🚀 Starting AI Verification Script...")
    
    # 1. Admin Login
    admin_token = login("ADMIN", "Admin123")
    if not admin_token:
        print("❌ Admin login failed. Is the server running?")
        exit(1)
    
    # 2. Test Admin Insights
    test_admin_insights(admin_token)
    
    # 3. Test Student Risks
    # S101: Expected Critical (Declining)
    # S102: Expected Safe/Warning (Improving)
    # S103: Expected Safe (Stable 80%)
    test_student_risk(admin_token, "S101")
    test_student_risk(admin_token, "S102")
    test_student_risk(admin_token, "S103")
    
    # 4. Teacher Login & Recommendation
    teacher_token = login("T101", "Teacher123")
    test_teacher_recommendation(teacher_token, "T101")

    print("🏁 Verification Complete.")
