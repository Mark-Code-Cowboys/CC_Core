# On-device text model: native reference

`MethodChannelTextModel` (lib/src/on_device_ai) expects a method channel
answering two calls:

| Method | Arguments | Result |
|---|---|---|
| `isAvailable` | — | `bool` — a usable model on this phone |
| `generate` | `{"prompt": String}` | `String` answer; a `PlatformException` for a generation failure |

cc_core is a pure Dart package, so the native halves live in each app.
Below is the reference implementation lifted from Trace Elements
(Gemini Nano via ML Kit's Prompt API on Android, minSdk 26; Apple
Foundation Models on iOS 26+). Copy, rename the channel, and keep the
contract. Gradle: `implementation("com.google.mlkit:genai-prompt:…")`.

## Android (Kotlin, in MainActivity)

```kotlin
    override fun onDestroy() {
        scope.cancel()
        try {
            model?.close()
        } catch (e: Exception) {
            Log.w(TAG, "closing Gemini Nano client: ${e.message}")
        }
        model = null
        super.onDestroy()
    }

    private fun client(): GenerativeModel =
        model ?: Generation.getClient().also { model = it }

    /// True only when Gemini Nano is ready right now. A downloadable
    /// model starts downloading in the background (once per process)
    /// so a later scan finds it; anything else is unavailable. Any
    /// failure — no AICore, unsupported device — reads as unavailable.
    private suspend fun isModelAvailable(): Boolean = try {
        when (client().checkStatus()) {
            FeatureStatus.AVAILABLE -> true
            FeatureStatus.DOWNLOADABLE -> {
                startDownload()
                false
            }
            else -> false
        }
    } catch (e: Exception) {
        Log.i(TAG, "Gemini Nano unavailable: ${e.message}")
        false
    }

    private fun startDownload() {
        if (downloadJob?.isActive == true) return
        downloadJob = scope.launch {
            try {
                client().download().collect { status ->
                    when (status) {
                        is DownloadStatus.DownloadFailed ->
                            Log.w(TAG, "Gemini Nano download failed: ${status.e.message}")
                        DownloadStatus.DownloadCompleted ->
                            Log.i(TAG, "Gemini Nano download complete")
                        else -> Unit
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Gemini Nano download: ${e.message}")
            }
        }
    }

    private suspend fun generate(prompt: String, result: MethodChannel.Result) {
        try {
            val response = generateLock.withLock {
                client().generateContent(
                    generateContentRequest(TextPart(prompt)) {
                        // Low temperature: the answer is JSON the app parses;
                        // the consensus pass still catches a wobbly run.
                        temperature = 0.2f
                        candidateCount = 1
                    },
                )
            }
            val text = response.candidates.firstOrNull()?.text ?: ""
            result.success(text)
        } catch (e: Exception) {
            Log.w(TAG, "Gemini Nano generation failed: ${e.message}")
            result.error("generation_failed", e.message ?: e.javaClass.simpleName, null)
        }
    }

    private companion object {
        const val TAG = "OnDeviceAI"
        const val CHANNEL = "com.codecowboys.traceelements/on_device_ai"
        const val SHARED_TEXT_CHANNEL = "com.codecowboys.traceelements/shared_text"
    }
}

```

Registration (in `configureFlutterEngine`):

```kotlin
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "<app>/on_device_ai")
    .setMethodCallHandler { call, result ->
        when (call.method) {
            "isAvailable" -> scope.launch { result.success(isModelAvailable()) }
            "generate" -> {
                val prompt = call.argument<String>("prompt")
                if (prompt.isNullOrBlank()) result.error("bad_args", "prompt is required", null)
                else scope.launch { generate(prompt, result) }
            }
            else -> result.notImplemented()
        }
    }
```

## iOS (Swift, in AppDelegate)

```swift
  // MARK: - On-device AI (menu-scan dish decomposition)

  /// Apple's Foundation Models (iOS 26+, Apple Intelligence). The Dart
  /// side (lib/src/lookup/on_device_decomposer.dart) asks `isAvailable`
  /// before each lookup and then `generate` with the full prompt; the
  /// answer is parsed in Dart. Older iOS reports unavailable and the
  /// lookup chain moves on.
  private func registerOnDeviceAiChannel(_ registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "TraceElementsOnDeviceAI") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "com.codecowboys.traceelements/on_device_ai",
      binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isAvailable":
        result(AppDelegate.onDeviceModelAvailable())
      case "generate":
        guard let args = call.arguments as? [String: Any],
          let prompt = args["prompt"] as? String, !prompt.isEmpty
        else {
          result(FlutterError(code: "bad_args", message: "prompt is required", details: nil))
          return
        }
        AppDelegate.generate(prompt: prompt, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func onDeviceModelAvailable() -> Bool {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      return SystemLanguageModel.default.isAvailable
    }
    #endif
    return false
  }

  private static func generate(prompt: String, result: @escaping FlutterResult) {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      Task {
        do {
          let session = LanguageModelSession(
            instructions: "You answer with a single JSON object and nothing else.")
          let response = try await session.respond(
            to: prompt, options: GenerationOptions(temperature: 0.2))
          let text = response.content
          await MainActor.run { result(text) }
        } catch {
          await MainActor.run {
            result(FlutterError(
              code: "generation_failed", message: error.localizedDescription, details: nil))
          }
        }
      }
      return
    }
    #endif
    result(FlutterError(code: "unavailable", message: "No on-device model", details: nil))
  }
}
```

Both models run at low temperature and offer no structured output to
Dart, so parse tolerantly (fences, prefixes, junk lines) — `LineLabeler`
does.
