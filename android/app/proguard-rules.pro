                        # Flutter Wrapper
                        -keep class io.flutter.app.** { *; }
                        -keep class io.flutter.plugin.** { *; }
                        -keep class io.flutter.util.** { *; }
                        -keep class io.flutter.view.** { *; }
                        -keep class io.flutter.** { *; }
                        -keep class io.flutter.plugins.** { *; }

                        # Supabase and Networking
                        -keep class io.supabase.** { *; }
                        -keep class com.supabase.** { *; }
                        -keep class okhttp3.** { *; }
                        -dontwarn io.supabase.**

                        # Preserving your custom data models (replace with your actual package name if different)
                        -keep class com.example.electroride.models.** { *; }

                        -ignorewarnings