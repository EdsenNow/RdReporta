# Project-specific R8 rules belong here when a dependency requires them.
# Flutter's generated rules and Android's optimized defaults remain active.

# ExoPlayer / AndroidX Media3 / video_player
-keep class androidx.media3.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
-keep class io.flutter.plugins.videoplayer.** { *; }

