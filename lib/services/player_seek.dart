/// Calculates a seek position without allowing playback outside the media.
Duration? calculateSeekTarget({
  required Duration position,
  required Duration duration,
  required Duration offset,
}) {
  if (duration <= Duration.zero) return null;
  final target = position + offset;
  final milliseconds =
      target.inMilliseconds.clamp(0, duration.inMilliseconds);
  return Duration(milliseconds: milliseconds);
}
