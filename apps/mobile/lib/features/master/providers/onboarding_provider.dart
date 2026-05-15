import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingPhoto {
  final String filename;
  final Uint8List bytes;
  const OnboardingPhoto({required this.filename, required this.bytes});
}

class OnboardingState {
  final List<String> specializations;
  final String address;
  final double lat;
  final double lng;
  final List<OnboardingPhoto> photos;

  const OnboardingState({
    this.specializations = const [],
    this.address = '',
    this.lat = 51.1801,
    this.lng = 71.4460,
    this.photos = const [],
  });

  OnboardingState copyWith({
    List<String>? specializations,
    String? address,
    double? lat,
    double? lng,
    List<OnboardingPhoto>? photos,
  }) {
    return OnboardingState(
      specializations: specializations ?? this.specializations,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      photos: photos ?? this.photos,
    );
  }
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void setSpecializations(List<String> specs) =>
      state = state.copyWith(specializations: specs);

  void setAddress(String address, double lat, double lng) =>
      state = state.copyWith(address: address, lat: lat, lng: lng);

  void setPhotos(List<OnboardingPhoto> photos) =>
      state = state.copyWith(photos: photos);

  void reset() => state = const OnboardingState();
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);
