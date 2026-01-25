import 'dart:math';

class OtpHelper {
  // Generate a random 4-digit OTP
  static String generateOtp() {
    Random random = Random();
    int otp = 1000 + random.nextInt(9000); // Generates number between 1000-9999
    return otp.toString();
  }

  // Verify if entered OTP matches the stored OTP
  static bool verifyOtp(String enteredOtp, String actualOtp) {
    return enteredOtp.trim() == actualOtp.trim();
  }

  // Format OTP for display (e.g., "1 2 3 4")
  static String formatOtpForDisplay(String otp) {
    if (otp.length != 4) return otp;
    return otp.split('').join(' ');
  }
}