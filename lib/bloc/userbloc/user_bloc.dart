import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_zen/bloc/userbloc/user_event.dart';
import 'package:study_zen/bloc/userbloc/user_state.dart';
import 'package:study_zen/models/user_model.dart';
import 'package:study_zen/services/user_service.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
   UserBloc(): super(UserInitial()){
    on<OnRegisterEvent>((event, emit) async {
      emit(UserLoading());
      try {
        UserService userService = UserService();
        final result = await userService.registerUser(
          event.username, event.email, event.password, event.accountType
        );

        if (result['success'] == true && result['user'] != null) {
          emit(UserLoaded(result['user'] as UserModel));
        } else {
          final msg = result['error'] ?? 'Failed to register user';
          emit(UserError(msg.toString()));
        }
      } catch (e) {
        emit(UserError("An error occurred: $e"));
      }
    });      
    on<OnLoginEvent>((event, emit) async {
        emit(UserLoading());
        try {
          UserService userService = UserService();
          final response = await userService.loginUser(event.email, event.password);
          if (response['success'] == true && response['user'] != null) {
            emit(UserLoaded(response['user'] as UserModel));
          } else {
            final msg = response['error'] ?? 'Failed to login';
            emit(UserError(msg.toString()));
          }
        } catch (e) {
          emit(UserError("An error occurred: $e"));
        }
      });
   }
}