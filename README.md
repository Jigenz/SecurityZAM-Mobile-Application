
# SecurityZAM

### An Open Source Intelligence (OSINT) Mobile Application for Enhanced Security

**Author**: Abdullah Azzam Bin Syafrizal (MSC 1, 1210581)  
**Course**: SKJ4333 - Mobile Security System

---

## About SecurityZAM

SecurityZAM is a comprehensive OSINT tool designed to enhance user security through robust authentication, data intelligence, and runtime protection mechanisms. The app provides a range of security features for a safer mobile experience.

## Key Features

### 1. Secure User Authentication
- **Sign-In & Sign-Up**: Account creation and secure login through Firebase Authentication.
- **Password Protection**: Strong password policies with validation and encryption.

### 2. Two-Factor Authentication (2FA)
- **Enhanced Security**: Adds a second layer of protection for accounts.
- **Verification Methods**: Supports phone and email verification.

### 3. Advanced Geolocation Services
- **IP Geolocation**: Fetches location data based on IP using `ipgeolocation.io` API.
- **GPS Location**: Retrieves real-time GPS data with location permissions.

### 4. QR Code Support with Safety Analysis
- **QR Code Scanning**: Scans and decodes QR codes via the mobile scanner package.
- **Safety Verification**: Analyzes URLs with Google Safe Browsing API for potential threats.

### 5. Runtime Application Self-Protection (RASP)
- **Security Checks**: Monitors for app tampering, injection attacks, and other threats.
- **Mitigation Actions**: Logs security events and limits functionality on detecting threats.

### 6. Device Root Detection
- **Rooted/Jailbroken Detection**: Identifies rooted or jailbroken devices.
- **Security Alerts**: Notifies users and restricts app functionality on compromised devices.

### 7. Risk-Based Scoring
- **Dynamic Risk Assessment**: Calculates risk scores based on device status and location.
- **Risk Levels**: Assigns users into Low, Medium, or High risk categories for tailored security.

### 8. Device Identification
- **Unique Device IDs**: Retrieves specific identifiers for secure user management.
- **Privacy Compliance**: Ensures user data is handled securely.

### 9. Terms of Service
- **Transparency**: Clear guidelines on data usage and user responsibilities.
- **Security Commitment**: Outline of security practices to protect user data.

## Conclusion

SecurityZAM provides a layered security approach to protect user data, designed with both robustness and user experience in mind.

---

## Getting Started

1. **Prerequisites**:
   - Firebase Authentication configured for secure login.
   - `ipgeolocation.io` API for IP-based geolocation.
   - Google Safe Browsing API for URL safety checks.

2. **Installation**:
   - Clone this repository:  
     ```bash
     git clone https://github.com/yourusername/SecurityZAM.git
     ```
   - Follow the setup instructions in the `docs/installation_guide.md`.

3. **Usage**:
   - Open the app on your mobile device.
   - Follow the in-app instructions to set up and use each security feature.

## License

This project is licensed under the MIT License.

---

## Contact

For questions or suggestions, please reach out to azzamabdullah237@gmail.com.



>>>>>>> d5bfc662e8f63b5574ba0a5e0b008d611ac0d802
