# Retrofit
-keepattributes Signature
-keepattributes *Annotation*
-keep class de.familienkalender.app.data.remote.dto.** { *; }

# Gson
-keep class com.google.gson.** { *; }
-keepattributes AnnotationDefault,RuntimeVisibleAnnotations

# Room
-keep class * extends androidx.room.RoomDatabase
