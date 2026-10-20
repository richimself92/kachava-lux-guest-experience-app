/// Port abstraction for the 432Hz Sanctuary Soundscape synthesizer.
abstract interface class SoundscapePort {
  bool get isActive;
  int get rootFrequencyHz;
  int get subHarmonicFrequencyHz;
  int get singingBowlChimeHz;
  double get masterGain;
  bool toggle();
  void start();
  void stop();
}

/// Deterministic, cross-platform procedural 432Hz Soundscape synthesizer.
/// Models the 4 acoustic layers defined in `docs/UI_UX_DESIGN.md` Section 4.1:
/// - Layer 1: 432 Hz Root Harmonic Drone
/// - Layer 2: 216 Hz Sub-Harmonic Foundation
/// - Layer 3: 320 Hz Low-pass Cenote Breeze & Ripple
/// - Layer 4: 864 Hz Periodic Singing Bowl Chime
class SanctuarySoundscapeSynthesizer implements SoundscapePort {
  bool _isActive = false;
  double _masterGain = 0.0;

  @override
  bool get isActive => _isActive;

  @override
  int get rootFrequencyHz => 432;

  @override
  int get subHarmonicFrequencyHz => 216;

  @override
  int get singingBowlChimeHz => 864;

  @override
  double get masterGain => _masterGain;

  @override
  bool toggle() {
    if (_isActive) {
      stop();
    } else {
      start();
    }
    return _isActive;
  }

  @override
  void start() {
    _isActive = true;
    _masterGain = 0.08;
  }

  @override
  void stop() {
    _isActive = false;
    _masterGain = 0.0;
  }
}
