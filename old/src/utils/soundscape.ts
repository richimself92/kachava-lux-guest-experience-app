class SanctuarySoundscape {
  private ctx: AudioContext | null = null;
  private isPlaying = false;
  private masterGain: GainNode | null = null;
  private osc1: OscillatorNode | null = null;
  private osc2: OscillatorNode | null = null;
  private noiseNode: AudioNode | null = null;
  private filterNode: BiquadFilterNode | null = null;
  private intervalId: number | null = null;

  public toggle(): boolean {
    if (this.isPlaying) {
      this.stop();
      return false;
    } else {
      this.start();
      return true;
    }
  }

  public getStatus(): boolean {
    return this.isPlaying;
  }

  public start() {
    try {
      const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      this.ctx = new AudioCtx();
      
      this.masterGain = this.ctx.createGain();
      this.masterGain.gain.setValueAtTime(0.001, this.ctx.currentTime);
      this.masterGain.gain.exponentialRampToValueAtTime(0.08, this.ctx.currentTime + 3);
      this.masterGain.connect(this.ctx.destination);

      // 432 Hz Root Harmonic Drone
      this.osc1 = this.ctx.createOscillator();
      this.osc1.type = 'sine';
      this.osc1.frequency.setValueAtTime(432, this.ctx.currentTime);

      const gain1 = this.ctx.createGain();
      gain1.gain.value = 0.5;
      this.osc1.connect(gain1);
      gain1.connect(this.masterGain);
      this.osc1.start();

      // Sub-harmonic 216 Hz for grounding warmth
      this.osc2 = this.ctx.createOscillator();
      this.osc2.type = 'triangle';
      this.osc2.frequency.setValueAtTime(216, this.ctx.currentTime);

      const gain2 = this.ctx.createGain();
      gain2.gain.value = 0.35;
      this.osc2.connect(gain2);
      gain2.connect(this.masterGain);
      this.osc2.start();

      // Gentle breeze / cenote ripple noise generator
      const bufferSize = this.ctx.sampleRate * 2;
      const noiseBuffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
      const output = noiseBuffer.getChannelData(0);
      for (let i = 0; i < bufferSize; i++) {
        output[i] = Math.random() * 2 - 1;
      }

      const whiteNoise = this.ctx.createBufferSource();
      whiteNoise.buffer = noiseBuffer;
      whiteNoise.loop = true;

      this.filterNode = this.ctx.createBiquadFilter();
      this.filterNode.type = 'lowpass';
      this.filterNode.frequency.setValueAtTime(320, this.ctx.currentTime);

      const noiseGain = this.ctx.createGain();
      noiseGain.gain.value = 0.04;

      whiteNoise.connect(this.filterNode);
      this.filterNode.connect(noiseGain);
      noiseGain.connect(this.masterGain);
      whiteNoise.start();

      this.noiseNode = whiteNoise;
      this.isPlaying = true;

      // Occasional gentle sacred singing bowl chime every 12 seconds
      this.intervalId = window.setInterval(() => {
        if (this.ctx && this.isPlaying && this.masterGain) {
          this.triggerChime();
        }
      }, 11000);

    } catch (e) {
      console.warn('Web Audio not allowed without gesture', e);
      this.isPlaying = false;
    }
  }

  private triggerChime() {
    if (!this.ctx || !this.masterGain) return;
    try {
      const chimeOsc = this.ctx.createOscillator();
      const chimeGain = this.ctx.createGain();
      chimeOsc.type = 'sine';
      // Harmonic 432 * 2 = 864 or 648
      chimeOsc.frequency.setValueAtTime(864, this.ctx.currentTime);

      chimeGain.gain.setValueAtTime(0.0001, this.ctx.currentTime);
      chimeGain.gain.exponentialRampToValueAtTime(0.04, this.ctx.currentTime + 0.1);
      chimeGain.gain.exponentialRampToValueAtTime(0.0001, this.ctx.currentTime + 4.5);

      chimeOsc.connect(chimeGain);
      chimeGain.connect(this.masterGain);
      chimeOsc.start();
      chimeOsc.stop(this.ctx.currentTime + 4.8);
    } catch {
      // ignore
    }
  }

  public stop() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
    if (this.masterGain && this.ctx) {
      this.masterGain.gain.exponentialRampToValueAtTime(0.0001, this.ctx.currentTime + 1);
      setTimeout(() => {
        try {
          this.osc1?.stop();
          this.osc2?.stop();
          this.ctx?.close();
        } catch {
          // ignore
        }
        this.ctx = null;
        this.isPlaying = false;
      }, 1000);
    } else {
      this.isPlaying = false;
    }
  }
}

export const soundscape = new SanctuarySoundscape();
