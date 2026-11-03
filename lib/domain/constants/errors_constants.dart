class ErrorsConstants {
  static const String unauthorized = 'unauthorized';
  static const String unknownError = "unknownError";
  static const String noInternet = "noInternet";
  static const String timeout = "timeout";

  static const String noUserFound = "noUserFound";

  static const String emptyNote = "emptyNote";
  static const String maxPinnedNotes = "maxPinnedNotes";
  static const String noteNotFound = "noteNotFound";

  static bool existsKey(String key) {
    return [
      unauthorized,
      unknownError,
      noInternet,
      timeout,
      noUserFound,
      emptyNote,
      maxPinnedNotes,
      noteNotFound,
    ].contains(key);
  }
}
