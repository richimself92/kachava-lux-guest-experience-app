import 'dart:async';
import 'dart:js_interop';
import 'alert_chime_port.dart';

@JS('AudioContext')
extension type _JsAudioContext._(JSObject _) implements JSObject {
  external factory _JsAudioContext();
  external double get currentTime;
  external String get state;
  external JSObject get destination;
  external JSPromise<JSAny?> resume();
  external JSPromise<JSAny?> close();
  external _JsOscillatorNode createOscillator();
  external _JsGainNode createGain();
}

extension type _JsAudioParam._(JSObject _) implements JSObject {
  external set value(double val);
  external void setValueAtTime(double value, double startTime);
  external void exponentialRampToValueAtTime(double value, double endTime);
}

extension type _JsOscillatorNode._(JSObject _) implements JSObject {
  external set type(String val);
  external _JsAudioParam get frequency;
  external void connect(JSObject destination);
  external void start([double when]);
  external void stop([double when]);
}

extension type _JsGainNode._(JSObject _) implements JSObject {
  external _JsAudioParam get gain;
  external void connect(JSObject destination);
}

@JS('window')
external _JsWindow get _jsWindow;

extension type _JsWindow._(JSObject _) implements JSObject {
  external void addEventListener(String type, JSFunction listener);
}

/// Web Audio API implementation of [AlertChimePort] that plays a two-tone
/// luxury concierge bell (528Hz -> 660Hz) every 2 seconds for 10 seconds.
class WebAlertChimeAdapter implements AlertChimePort {
  WebAlertChimeAdapter() {
    _registerAutoplayUnlockHooks();
  }

  _JsAudioContext? _ctx;
  Timer? _repeatTimer;
  Timer? _stopTimer;
  bool _ringing = false;
  bool _unlocked = false;

  void _registerAutoplayUnlockHooks() {
    try {
      final handler = ((JSAny? _) => _unlockAudioContext()).toJS;
      _jsWindow.addEventListener('pointerdown', handler);
      _jsWindow.addEventListener('keydown', handler);
    } catch (_) {}
  }

  void _unlockAudioContext() {
    if (_unlocked) return;
    try {
      _ctx ??= _JsAudioContext();
      if (_ctx!.state == 'suspended') _ctx!.resume();
      _unlocked = true;
    } catch (_) {}
  }

  @override
  bool get isRinging => _ringing;

  @override
  void triggerTenSecondChime({void Function()? onAutoStop}) {
    stopChime();
    _ringing = true;
    _playBellPair();
    _repeatTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _playBellPair(),
    );
    _stopTimer = Timer(const Duration(seconds: 10), () {
      stopChime();
      onAutoStop?.call();
    });
  }

  void _playBellPair() {
    try {
      final ctx = _ctx ??= _JsAudioContext();
      if (ctx.state == 'suspended') {
        ctx.resume();
      }
      final now = ctx.currentTime;
      _scheduleTone(ctx, freq: 528.0, start: now, duration: 0.45, peak: 0.18);
      _scheduleTone(
        ctx,
        freq: 660.0,
        start: now + 0.22,
        duration: 0.65,
        peak: 0.22,
      );
    } catch (_) {
      // Browser autoplay restriction or missing audio hardware; fail silently.
    }
  }

  void _scheduleTone(
    _JsAudioContext ctx, {
    required double freq,
    required double start,
    required double duration,
    required double peak,
  }) {
    final osc = ctx.createOscillator();
    final gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(freq, start);
    gain.gain.setValueAtTime(peak, start);
    gain.gain.exponentialRampToValueAtTime(0.001, start + duration);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(start);
    osc.stop(start + duration);
  }

  @override
  void stopChime() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
    _stopTimer?.cancel();
    _stopTimer = null;
    _ringing = false;
  }

  @override
  void dispose() {
    stopChime();
    try {
      _ctx?.close();
    } catch (_) {}
    _ctx = null;
  }
}

AlertChimePort createPlatformAlertChimePort() => WebAlertChimeAdapter();
