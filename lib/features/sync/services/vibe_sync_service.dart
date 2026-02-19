import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:network_info_plus/network_info_plus.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

enum SyncRole { none, host, client }

class GuestRequest {
  final String id;
  final String name;
  final dynamic socket; // WebSocketChannel

  GuestRequest(this.id, this.name, this.socket);
}

class VibeSyncService {
  SyncRole _role = SyncRole.none;
  HttpServer? _server;
  WebSocketChannel? _clientChannel;
  
  final List<dynamic> _connectedClients = [];
  final Map<String, GuestRequest> _pendingGuests = {};

  final StreamController<Map<String, dynamic>> _eventController = StreamController.broadcast();
  final StreamController<GuestRequest> _guestRequestController = StreamController.broadcast();
  final StreamController<dynamic> _clientConnectionController = StreamController.broadcast(); // Restored
  
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;
  Stream<GuestRequest> get guestRequestStream => _guestRequestController.stream;
  Stream<dynamic> get clientConnectedStream => _clientConnectionController.stream; // Restored
  SyncRole get role => _role;

  // HOST: Start Server
  Future<String?> startHost() async {
    if (_role != SyncRole.none) return null;
    
    try {
      var handler = webSocketHandler((webSocket) {
        // Don't add to _connectedClients yet. Wait for JOIN_REQUEST.
        webSocket.stream.listen((message) {
           try {
             final data = jsonDecode(message);
             if (data['type'] == 'JOIN_REQUEST') {
               final String id = data['payload']['id'];
               final String name = data['payload']['name'] ?? 'Guest';
               
               if (_pendingGuests.containsKey(id)) {
                  // Already pending? Ignore or update.
                  return;
               }

               final request = GuestRequest(id, name, webSocket);
               _pendingGuests[id] = request;
               _guestRequestController.add(request);
             } else if (_connectedClients.contains(webSocket)) {
               // Only process other messages if accepted
               handleMessage(message);
             }
           } catch (e) {
             print("Host error processing msg: $e");
           }
        }, onDone: () {
           _connectedClients.remove(webSocket);
           // Also remove from pending if exists
           _pendingGuests.removeWhere((key, value) => value.socket == webSocket);
           print("Client Disconnected");
        });
      });

      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8080);
      _role = SyncRole.host;
      
      final info = NetworkInfo();
      return await info.getWifiIP(); // Return Host IP for QR display
    } catch (e) {
      print("Error starting host: $e");
      return null;
    }
  }

  void acceptGuest(String id) {
    final guest = _pendingGuests[id];
    if (guest != null) {
      _pendingGuests.remove(id);
      _connectedClients.add(guest.socket);
      
      // Notify UI/Logic that a client connected (for initial sync)
      _clientConnectionController.add(guest.socket);

      // Send Acceptance
      guest.socket.sink.add(jsonEncode({
        'type': 'CONNECTION_ACCEPTED',
        'payload': {}
      }));
      
      print("Accepted guest $id");
    }
  }

  void declineGuest(String id) {
    final guest = _pendingGuests[id];
    if (guest != null) {
      _pendingGuests.remove(id);
      guest.socket.sink.add(jsonEncode({
        'type': 'CONNECTION_DECLINED',
        'payload': {}
      }));
      guest.socket.sink.close(); 
    }
  }

  // CLIENT: Join Host
  Future<bool> joinHost(String ip) async {
    if (_role != SyncRole.none) return false;

    try {
      final wsUrl = Uri.parse('ws://$ip:8080');
      _clientChannel = IOWebSocketChannel.connect(wsUrl);
      
      final completer = Completer<bool>();
      final myId = "user_${Random().nextInt(10000)}"; // Simple ID generation

      // Send Join Request immediately
      _clientChannel!.sink.add(jsonEncode({
        'type': 'JOIN_REQUEST',
        'payload': {
          'id': myId,
          'name': 'Music Lover' // TODO: Get actual device name potentially
        }
      }));

      _clientChannel!.stream.listen((message) {
        try {
          final data = jsonDecode(message);
          if (data['type'] == 'CONNECTION_ACCEPTED') {
            if (!completer.isCompleted) completer.complete(true);
          } else if (data['type'] == 'CONNECTION_DECLINED') {
            if (!completer.isCompleted) completer.complete(false);
            stop();
          } else {
            // Normal message processing
             handleMessage(message);
          }
        } catch (e) {
           print("Client parse error: $e");
        }
      }, onError: (e) {
        print("Client WS Error: $e");
        if (!completer.isCompleted) completer.complete(false);
        stop(); 
      }, onDone: () {
        print("Client Disconnected from Host");
        if (!completer.isCompleted) completer.complete(false);
        stop();
      });

      _role = SyncRole.client;
      return completer.future;
    } catch (e) {
      print("Error connecting to host: $e");
      return false;
    }
  }

  // Handle Incoming Messages (Both Host and Client)
  void handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);
      _eventController.add(data);
    } catch (e) {
      print("Error parse message: $e");
    }
  }

  // Broadcast Event (Host Only)
  void broadcastEvent(String type, Map<String, dynamic> payload) {
    if (_role != SyncRole.host) return;
    
    final data = jsonEncode({
      'type': type,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'payload': payload
    });

    for (var client in _connectedClients) {
      try {
        client.sink.add(data);
      } catch (e) {
        print("Error sending to client: $e");
      }
    }
  }

  // Stop everything
  void stop() {
    if (_role == SyncRole.host) {
      _server?.close();
      for (var client in _connectedClients) {
        client.sink.close();
      }
      _connectedClients.clear();
      _server = null;
    } else if (_role == SyncRole.client) {
      _clientChannel?.sink.close();
      _clientChannel = null;
    }
    _role = SyncRole.none;
    _pendingGuests.clear();
  }
}

