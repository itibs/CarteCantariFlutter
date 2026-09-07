part of 'auth_cubit.dart';

class AuthState extends Equatable {
  final bool signedIn;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  const AuthState({
    required this.signedIn,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  const AuthState.signedOut() : this(signedIn: false);

  @override
  List<Object?> get props => [signedIn, email, displayName, photoUrl];
}
