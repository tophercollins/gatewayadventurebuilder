# TODO - Future Features

## Audio Playback in Session Page

**Priority:** High
**Status:** Not started

### Requirements
- Add audio player to the session detail page
- Play back recorded session audio
- Variable playback speed control (0.5x, 0.75x, 1x, 1.25x, 1.5x, 1.75x, 2x)
- **Pitch preservation** - Speed changes must NOT distort audio pitch (like YouTube/Netflix)
- Seek/scrub through audio
- Show current timestamp and total duration
- Optional: Sync transcript highlighting with audio position

### Technical Notes
- Use `just_audio` package - supports pitch-preserved speed changes via `setSpeed()`
- The package uses platform-native audio processing which handles pitch correction automatically
- Consider `audio_video_progress_bar` for a nice seek bar UI

### Implementation Steps
1. Add `just_audio` dependency to pubspec.yaml
2. Create `AudioPlayerService` in `lib/services/audio/`
3. Create `AudioPlayerWidget` with play/pause, seek bar, speed selector
4. Integrate into session detail screen
5. Optional: Add transcript sync functionality

### References
- just_audio: https://pub.dev/packages/just_audio
- Speed control preserves pitch by default in just_audio
