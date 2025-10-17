import 'package:flutter/material.dart';
import '../models/trip.dart';

class TripProvider extends ChangeNotifier {
  final List<Trip> _trips = [
    Trip(
      id: '1',
      name: '오사카 여행',
      destination: '일본 오사카',
      startDate: '2025-03-15',
      duration: '4박 5일',
    ),
    Trip(
      id: '2',
      name: '방콕 여행',
      destination: '태국 방콕',
      startDate: '2025-05-20',
      duration: '3박 4일',
    ),
  ];

  String _currentTripId = '1';

  List<Trip> get trips => _trips;
  String get currentTripId => _currentTripId;
  
  Trip? get currentTrip {
    try {
      return _trips.firstWhere((trip) => trip.id == _currentTripId);
    } catch (e) {
      return _trips.isNotEmpty ? _trips.first : null;
    }
  }

  void setCurrentTrip(String tripId) {
    _currentTripId = tripId;
    notifyListeners();
  }

  void addTrip(Trip trip) {
    _trips.add(trip);
    _currentTripId = trip.id;
    notifyListeners();
  }

  void deleteTrip(String tripId) {
    if (_trips.length > 1) {
      _trips.removeWhere((trip) => trip.id == tripId);
      if (_currentTripId == tripId) {
        _currentTripId = _trips.first.id;
      }
      notifyListeners();
    }
  }
}
