# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# ⭐ REGLAS ESPECÍFICAS PARA ARCore Y SCENEFORM
-keep class com.google.ar.** { *; }
-keep class com.google.ar.sceneform.** { *; }
-keep class com.google.ar.core.** { *; }

# ⭐ REGLAS PARA FLUTTER
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# ⭐ REGLAS PARA PLUGINS ESPECÍFICOS
-keep class com.baseflow.** { *; }
-keep class com.butterflyar.app.** { *; }

# ⭐ REGLAS PARA ARCore Flutter Plugin
-dontwarn com.google.ar.**
-dontwarn com.google.devtools.**

# ⭐ MANTENER CLASES DE ANIMACIÓN
-keep class * extends android.animation.** { *; }
-keep class android.animation.** { *; }

# ⭐ REGLAS PARA WEBVIEW (Model Viewer)
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# ⭐ REGLAS GENERALES PARA EVITAR OBFUSCACIÓN
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
# Mantener clases anotadas con @Keep
-keep class androidx.annotation.Keep
-keep @androidx.annotation.Keep class * {*;}
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <methods>;
}
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <fields>;
}
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <init>(...);
}

# Mantener clases de Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Mantener clases nativas
-keepclasseswithmembernames class * {
    native <methods>;
}

# Mantener clases de View
-keep public class * extends android.view.View
-keepclasseswithmembers class * {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Mantener clases de Activity
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.app.backup.BackupAgentHelper
-keep public class * extends android.preference.Preference

# Mantener clases de ARCore y realidad aumentada
-keep class com.google.ar.** { *; }
-keep class com.google.vr.** { *; }
-keep class com.google.tango.** { *; }
-keep class org.webrtc.** { *; }

# Mantener clases de cámara
-keep class android.hardware.camera2.** { *; }
-keep class androidx.camera.** { *; }
-keep class com.google.mediapipe.** { *; }

# Reglas para Play Core y Dynamic Delivery
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.common.** { *; }

# Mantener clases de Flutter y plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class androidx.lifecycle.DefaultLifecycleObserver
