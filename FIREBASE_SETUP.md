# 🔥 Firebase Setup Guide for Elythra Music

## 📋 Required Information

### **SHA-1 Certificate Fingerprint (Debug)**
```
10:04:54:84:6C:D0:A8:9E:3D:2D:B9:62:BC:2A:96:19:48:C1:D3:2E
```

### **App Configuration**
- **Package Name**: `com.elythra.music`
- **App Name**: `Elythra Music`
- **Project ID**: `elythra-music` (or auto-generated)

---

## 🚀 Step-by-Step Firebase Console Setup

### **1. Create Firebase Project**
1. Go to: https://console.firebase.google.com
2. Click **"Create a project"**
3. **Project name**: `Elythra Music`
4. **Enable Google Analytics**: ✅ Yes
5. Choose your Analytics account
6. Click **"Create project"**

### **2. Add Android App**
1. In project dashboard, click **"Add app"** → **Android** 📱
2. **Android package name**: `com.elythra.music`
3. **App nickname**: `Elythra Music Android`
4. **Debug signing certificate SHA-1**: 
   ```
   10:04:54:84:6C:D0:A8:9E:3D:2D:B9:62:BC:2A:96:19:48:C1:D3:2E
   ```
5. Click **"Register app"**
6. **Download `google-services.json`** 📥

### **3. Enable Authentication**
1. Go to **Authentication** → **Sign-in method**
2. Click **"Google"** provider
3. **Enable** the toggle ✅
4. **Project support email**: Enter your email
5. **Web SDK configuration**:
   - Web client ID will be auto-generated
   - Web client secret will be auto-generated
6. Click **"Save"**

### **4. Enable Firestore Database**
1. Go to **Firestore Database**
2. Click **"Create database"**
3. **Security rules**: Choose **"Start in test mode"** (for development)
4. **Location**: Choose closest to your users (e.g., `us-central1`)
5. Click **"Done"**

### **5. Configure Project Settings**
1. Go to **Project Settings** ⚙️ → **Your apps**
2. Find your Android app
3. **SHA certificate fingerprints** section:
   - Verify the SHA-1 is added: `10:04:54:84:6C:D0:A8:9E:3D:2D:B9:62:BC:2A:96:19:48:C1:D3:2E`
4. **Web client ID** (for Google Sign-In):
   - Copy this value (you'll need it later)

---

## 📁 Place Configuration Files

### **After downloading from Firebase Console:**

**Android Configuration:**
```bash
# Place the downloaded google-services.json in:
cp ~/Downloads/google-services.json /workspace/android/app/google-services.json
```

**Verify placement:**
```bash
ls -la /workspace/android/app/google-services.json
```

---

## ✅ Verification Checklist

### **Firebase Console Setup:**
- [ ] Firebase project created with name "Elythra Music"
- [ ] Android app added with package `com.elythra.music`
- [ ] SHA-1 fingerprint added: `10:04:54:84:6C:D0:A8:9E:3D:2D:B9:62:BC:2A:96:19:48:C1:D3:2E`
- [ ] Google Sign-In enabled in Authentication
- [ ] Firestore Database created in test mode
- [ ] `google-services.json` downloaded

### **Local Configuration:**
- [ ] `google-services.json` placed in `/workspace/android/app/`
- [ ] File is not the template (contains real Firebase config)

---

## 🔧 Build After Setup

**Once Firebase is configured:**
```bash
cd /workspace
flutter clean
flutter pub get
flutter build apk --debug
```

---

## 🚨 Important Notes

### **Security Rules (Firestore)**
The database is currently in **test mode** (open access). For production, update rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### **SHA-1 for Production**
For production releases, you'll need to add the **release SHA-1** fingerprint:
```bash
# Generate release keystore (when ready for production)
keytool -genkey -v -keystore release.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000
```

### **Web Client ID**
The Web Client ID from Firebase Console will be needed for Google Sign-In configuration in the app.

---

## 🛠️ Troubleshooting

### **If Google Sign-In fails:**
1. Verify SHA-1 fingerprint is correct in Firebase Console
2. Check that `google-services.json` is in the right location
3. Ensure Google Sign-In is enabled in Firebase Authentication

### **If build fails:**
1. Make sure `google-services.json` is not the template file
2. Run `flutter clean && flutter pub get`
3. Check that Firebase dependencies are up to date

### **Get SHA-1 again:**
```bash
# Use the provided script
./scripts/get_sha1.sh
```

---

## 📞 Support

If you encounter issues:
1. Check Firebase Console for any error messages
2. Verify all configuration files are in place
3. Ensure all Firebase services are enabled
4. Check that package names match exactly

**Firebase Console**: https://console.firebase.google.com
**Firebase Documentation**: https://firebase.google.com/docs/android/setup