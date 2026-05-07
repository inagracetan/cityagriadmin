import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ConnectionStatus { online, offline, syncing }

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  ConnectionStatus _status = ConnectionStatus.online;
  ConnectionStatus get status => _status;

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  ConnectivityService() {
    _init();
  }

  void _init() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      // connectivity_plus 6.x returns a List<ConnectivityResult>
      final isNowOffline = results.contains(ConnectivityResult.none);
      if (_isOffline != isNowOffline) {
        _isOffline = isNowOffline;
        _updateStatus();
      }
    });

    // Also monitor Firestore's internal connection state
    _db.snapshotsInSync().listen((_) {
      // This triggers when a synchronization event happens
      if (!_isOffline && _status == ConnectionStatus.syncing) {
        _updateStatus();
      }
    });
  }

  void _updateStatus() {
    if (_isOffline) {
      _status = ConnectionStatus.offline;
    } else {
      _status = ConnectionStatus.online;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

