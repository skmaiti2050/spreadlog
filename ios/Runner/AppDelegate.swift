import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SpreadlogBackup") {
      BackupFileReceiver.shared.configure(messenger: registrar.messenger())
    }
  }
}

final class BackupFileReceiver {
  static let shared = BackupFileReceiver()
  private var channel: FlutterMethodChannel?
  private var pendingPath: String?
  private var ready = false

  func configure(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "com.spreadlog.app/backup_intent", binaryMessenger: messenger)
    self.channel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      if call.method == "getPendingBackupPath" {
        self.ready = true
        let path = self.pendingPath
        self.pendingPath = nil
        result(path)
      } else { result(FlutterMethodNotImplemented) }
    }
  }

  func receive(_ url: URL) {
    guard url.isFileURL else { return }
    let scoped = url.startAccessingSecurityScopedResource()
    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
    do {
      let handle = try FileHandle(forReadingFrom: url)
      defer { try? handle.close() }
      guard try handle.read(upToCount: 4) == Data([0x53, 0x50, 0x42, 0x4b]) else { return }
      let target = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".spbackup")
      try FileManager.default.copyItem(at: url, to: target)
      if ready { channel?.invokeMethod("onBackupFileReceived", arguments: target.path) }
      else { pendingPath = target.path }
    } catch { NSLog("Spreadlog backup import failed") }
  }
}
