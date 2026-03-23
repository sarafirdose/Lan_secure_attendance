@"
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from datetime import datetime, timedelta
import hashlib, uuid, secrets

app = Flask(__name__)
CORS(app)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///secureattend.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

class Student(db.Model):
    id = db.Column(db.String, primary_key=True, default=lambda: str(uuid.uuid4()))
    roll_number = db.Column(db.String(20), unique=True, nullable=False)
    full_name = db.Column(db.String(100), nullable=False)
    department = db.Column(db.String(100))
    year_section = db.Column(db.String(50))
    email = db.Column(db.String(100))
    phone = db.Column(db.String(15))
    password_hash = db.Column(db.String(64), nullable=False)
    device_fingerprint = db.Column(db.String(200))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    def to_dict(self):
        return {'rollNumber': self.roll_number, 'fullName': self.full_name,
                'department': self.department, 'yearSection': self.year_section,
                'email': self.email, 'phone': self.phone}

class AttendanceRecord(db.Model):
    id = db.Column(db.String, primary_key=True, default=lambda: str(uuid.uuid4()))
    roll_number = db.Column(db.String(20), db.ForeignKey('student.roll_number'))
    subject_code = db.Column(db.String(20))
    subject_name = db.Column(db.String(100))
    qr_token = db.Column(db.String(100))
    device_fingerprint = db.Column(db.String(200))
    device_ip = db.Column(db.String(50))
    ssid = db.Column(db.String(100))
    status = db.Column(db.String(20), default='present')
    marked_at = db.Column(db.DateTime, default=datetime.utcnow)
    def to_dict(self):
        return {'id': self.id, 'subjectCode': self.subject_code,
                'subjectName': self.subject_name, 'status': self.status,
                'date': self.marked_at.strftime('%a, %b %d, %Y'),
                'time': self.marked_at.strftime('%I:%M %p')}

class QRToken(db.Model):
    token = db.Column(db.String(100), primary_key=True)
    subject_code = db.Column(db.String(20))
    subject_name = db.Column(db.String(100))
    created_by = db.Column(db.String(50))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    expires_at = db.Column(db.DateTime)

def hash_password(p):
    return hashlib.sha256((p + 'secure_attend_salt').encode()).hexdigest()

def ok(data, code=200):
    return jsonify({'success': True, **data}), code

def err(msg, code=400):
    return jsonify({'success': False, 'message': msg}), code

@app.route('/')
def health():
    return ok({'message': 'SecureAttend backend running'})

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json(silent=True) or {}
    roll = data.get('rollNumber', '').strip().upper()
    if not roll or not data.get('password'):
        return err('rollNumber and password required')
    if Student.query.filter_by(roll_number=roll).first():
        return err('Already registered. Please sign in.', 409)
    s = Student(roll_number=roll, full_name=data.get('fullName',''),
                department=data.get('department',''), year_section=data.get('yearSection',''),
                email=data.get('email',''), phone=data.get('phone',''),
                password_hash=hash_password(data['password']),
                device_fingerprint=data.get('deviceFingerprint',''))
    db.session.add(s)
    db.session.commit()
    return ok({'message': 'Registered successfully', 'student': s.to_dict()}, 201)

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json(silent=True) or {}
    roll = data.get('rollNumber', '').strip().upper()
    s = Student.query.filter_by(roll_number=roll).first()
    if not s:
        return err('Roll number not found', 404)
    if s.password_hash != hash_password(data.get('password','')):
        return err('Incorrect password', 401)
    if s.device_fingerprint and s.device_fingerprint != data.get('deviceFingerprint',''):
        return err('Wrong device', 403)
    return ok({'message': 'Login successful', 'student': s.to_dict()})

@app.route('/mark-attendance', methods=['POST'])
def mark_attendance():
    data = request.get_json(silent=True) or {}
    roll = data.get('rollNumber','').strip().upper()
    s = Student.query.filter_by(roll_number=roll).first()
    if not s:
        return err('Student not found', 404)
    if s.device_fingerprint != data.get('deviceFingerprint',''):
        return err('Wrong device', 403)
    qr = QRToken.query.get(data.get('qrToken',''))
    if not qr:
        return err('Invalid QR code', 400)
    if datetime.utcnow() > qr.expires_at:
        return err('QR code expired', 400)
    today = datetime.utcnow().date()
    dup = AttendanceRecord.query.filter(
        AttendanceRecord.roll_number==roll,
        AttendanceRecord.subject_code==qr.subject_code,
        db.func.date(AttendanceRecord.marked_at)==today).first()
    if dup:
        return err('Already marked today', 409)
    r = AttendanceRecord(roll_number=roll, subject_code=qr.subject_code,
                         subject_name=qr.subject_name, qr_token=qr.token,
                         device_fingerprint=data.get('deviceFingerprint',''),
                         device_ip=data.get('deviceIp',''), ssid=data.get('ssid',''))
    db.session.add(r)
    db.session.commit()
    return ok({'message': 'Attendance marked!', 'subjectCode': qr.subject_code,
               'subjectName': qr.subject_name})

@app.route('/attendance-history')
def attendance_history():
    roll = request.args.get('rollNumber','').strip().upper()
    records = AttendanceRecord.query.filter_by(roll_number=roll).order_by(
        AttendanceRecord.marked_at.desc()).all()
    return ok({'records': [r.to_dict() for r in records]})

@app.route('/generate-qr', methods=['POST'])
def generate_qr():
    data = request.get_json(silent=True) or {}
    token = secrets.token_hex(16)
    expires = datetime.utcnow() + timedelta(minutes=5)
    qr = QRToken(token=token, subject_code=data.get('subjectCode',''),
                 subject_name=data.get('subjectName',''),
                 created_by=data.get('facultyId','faculty'), expires_at=expires)
    db.session.add(qr)
    db.session.commit()
    payload = f"{token}|{data.get('subjectCode','')}|{data.get('subjectName','')}|{int(datetime.utcnow().timestamp())}"
    return ok({'token': token, 'payload': payload, 'expiresIn': '5 minutes'}, 201)

@app.route('/reset-password', methods=['POST'])
def reset_password():
    data = request.get_json(silent=True) or {}
    roll = data.get('rollNumber','').strip().upper()
    s = Student.query.filter_by(roll_number=roll).first()
    if not s:
        return err('Roll number not found', 404)
    s.password_hash = hash_password(data.get('newPassword',''))
    db.session.commit()
    return ok({'message': 'Password updated successfully'})

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
        print('SecureAttend backend ready')
        print('Running on http://0.0.0.0:5000')
    app.run(debug=True, host='0.0.0.0', port=5000)
"@ | Out-File -FilePath app.py -Encoding utf8