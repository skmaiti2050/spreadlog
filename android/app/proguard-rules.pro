# ML Kit discovers component registrars by their manifest names and invokes
# their no-argument constructors through reflection. Preserve both in release.
-keep class * implements com.google.firebase.components.ComponentRegistrar {
    public <init>();
}
