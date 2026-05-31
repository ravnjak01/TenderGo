class AdminResetPasswordRequest {
  final String newPassword;
  final String confirmPassword;

  const AdminResetPasswordRequest({
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() =>{
    'newPassword': newPassword,
    'confirmPassword': confirmPassword,
  };
}