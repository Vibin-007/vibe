import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/vibe_sync_service.dart';

// EVENTS
abstract class VibeSyncEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartHost extends VibeSyncEvent {}

class JoinHost extends VibeSyncEvent {
  final String ip;
  JoinHost(this.ip);
}

class StopSync extends VibeSyncEvent {}

class BroadcastSyncEvent extends VibeSyncEvent {
  final String type;
  final Map<String, dynamic> payload;
  BroadcastSyncEvent(this.type, this.payload);
}

class AcceptJoinRequest extends VibeSyncEvent {
  final String requestId;
  AcceptJoinRequest(this.requestId);
}

class DeclineJoinRequest extends VibeSyncEvent {
  final String requestId;
  DeclineJoinRequest(this.requestId);
}

class _GuestRequestReceived extends VibeSyncEvent {
  final GuestRequest request;
  _GuestRequestReceived(this.request);
}

// STATE
abstract class VibeSyncState extends Equatable {
  @override
  List<Object?> get props => [];
}

class VibeSyncInitial extends VibeSyncState {}

class VibeSyncHosting extends VibeSyncState {
  final String ip;
  final List<GuestRequest> requests;

  VibeSyncHosting(this.ip, {this.requests = const []});
  
  @override
  List<Object?> get props => [ip, requests];

  VibeSyncHosting copyWith({
    String? ip,
    List<GuestRequest>? requests,
  }) {
    return VibeSyncHosting(
      ip ?? this.ip,
      requests: requests ?? this.requests,
    );
  }
}

class VibeSyncJoining extends VibeSyncState {
  final String message;
  VibeSyncJoining({this.message = "Connecting..."});
  @override
  List<Object?> get props => [message];
}

class VibeSyncClientConnected extends VibeSyncState {}

class VibeSyncError extends VibeSyncState {
  final String message;
  VibeSyncError(this.message);
}

// BLOC
class VibeSyncBloc extends Bloc<VibeSyncEvent, VibeSyncState> {
  final VibeSyncService _service;
  StreamSubscription? _requestSubscription;

  VibeSyncBloc(this._service) : super(VibeSyncInitial()) {
    on<StartHost>(_onStartHost);
    on<JoinHost>(_onJoinHost);
    on<StopSync>(_onStopSync);
    on<BroadcastSyncEvent>(_onBroadcastEvent);
    on<AcceptJoinRequest>(_onAcceptRequest);
    on<DeclineJoinRequest>(_onDeclineRequest);
    on<_GuestRequestReceived>(_onGuestRequestReceived);
  }

  Future<void> _onStartHost(StartHost event, Emitter<VibeSyncState> emit) async {
    emit(VibeSyncInitial());
    final ip = await _service.startHost();
    if (ip != null) {
      emit(VibeSyncHosting(ip));
      
      // Listen for incoming requests
      _requestSubscription?.cancel();
      _requestSubscription = _service.guestRequestStream.listen((request) {
        add(_GuestRequestReceived(request));
      });
    } else {
      emit(VibeSyncError("Failed to start host. Check Wi-Fi."));
    }
  }

  void _onGuestRequestReceived(_GuestRequestReceived event, Emitter<VibeSyncState> emit) {
    if (state is VibeSyncHosting) {
      final currentState = state as VibeSyncHosting;
      // Avoid duplicates just in case
      if (currentState.requests.any((r) => r.id == event.request.id)) return;
      
      emit(currentState.copyWith(
        requests: List.from(currentState.requests)..add(event.request)
      ));
    }
  }

  void _onAcceptRequest(AcceptJoinRequest event, Emitter<VibeSyncState> emit) {
    if (state is VibeSyncHosting) {
      final currentState = state as VibeSyncHosting;
      _service.acceptGuest(event.requestId);
      
      emit(currentState.copyWith(
        requests: List.from(currentState.requests)..removeWhere((r) => r.id == event.requestId)
      ));
    }
  }

  void _onDeclineRequest(DeclineJoinRequest event, Emitter<VibeSyncState> emit) {
    if (state is VibeSyncHosting) {
      final currentState = state as VibeSyncHosting;
      _service.declineGuest(event.requestId);
      
      emit(currentState.copyWith(
        requests: List.from(currentState.requests)..removeWhere((r) => r.id == event.requestId)
      ));
    }
  }

  Future<void> _onJoinHost(JoinHost event, Emitter<VibeSyncState> emit) async {
    emit(VibeSyncJoining(message: "Sending Request to Host..."));
    
    // UI update after 1 second to show "Waiting for Approval"
    // Since _service.joinHost waits, we can't emit while awaiting in the same handler easily unless we spawn a future.
    // However, Bloc executes handlers sequentially.
    // Creating a separate timer to update message if it takes too long?
    // Let's just set "Waiting for Host Approval" immediately since "Sending request" is fast.
    
    emit(VibeSyncJoining(message: "Waiting for Host Approval..."));

    final success = await _service.joinHost(event.ip);
    if (success) {
      emit(VibeSyncClientConnected());
    } else {
      emit(VibeSyncError("Connection declined or failed."));
    }
  }

  Future<void> _onStopSync(StopSync event, Emitter<VibeSyncState> emit) async {
    _requestSubscription?.cancel();
    _service.stop();
    emit(VibeSyncInitial());
  }

  void _onBroadcastEvent(BroadcastSyncEvent event, Emitter<VibeSyncState> emit) {
    _service.broadcastEvent(event.type, event.payload);
  }
  
  @override
  Future<void> close() {
    _requestSubscription?.cancel();
    return super.close();
  }
}
