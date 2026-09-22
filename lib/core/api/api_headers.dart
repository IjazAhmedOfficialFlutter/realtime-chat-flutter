class ApiHeaders {
  ApiHeaders._();

  static Map<String, String> getHeaders({
    String? token,
  }) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }
}