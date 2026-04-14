enum EventError {
  notLogged,
  tooEarly,
  permissionDenied,
  locationUnavailable,
  tooFar,
  unknown,
}

// Classe che permette di restituire un risultato positivo o un errore
class Result<T> {
  final T? data;
  final EventError? error;

  const Result._({this.data, this.error});

  factory Result.success(T data) =>
      Result._(data: data);

  factory Result.failure(EventError error) =>
      Result._(error: error);

  bool get isSuccess => error == null;
}
