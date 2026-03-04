class UserEvent {}

class OnRegisterEvent extends UserEvent {
  final String username;
  final String email;
  final String password;
  final String accountType;
  OnRegisterEvent({required this.username, required this.email, required this.password, required this.accountType});
}

class OnLoginEvent extends UserEvent {
  final String email;
  final String password;
  OnLoginEvent({required this.email, required this.password});
}
