import Flutter
import UIKit

@available(iOS 11.0, *)
public class SwiftThermalPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, FlutterSceneLifeCycleDelegate {
  var sink: FlutterEventSink?
  @objc public static var canSendMsg = false
  @objc public static var isForeground = false

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.sink = events
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onThermalStateChanged),
      name: ProcessInfo.thermalStateDidChangeNotification,
      object: nil)
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.sink = nil
    NotificationCenter.default.removeObserver(self, name: ProcessInfo.thermalStateDidChangeNotification, object: nil)
    return nil
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch (call.method) {
    case "getThermalStatus":
      result(SwiftThermalPlugin.toChannelValue(state: ProcessInfo.processInfo.thermalState))
      break
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func toChannelValue(state: ProcessInfo.ThermalState) -> Int {
    switch state {
    case ProcessInfo.ThermalState.nominal:
      return 0
    case ProcessInfo.ThermalState.fair:
      return 1
    case ProcessInfo.ThermalState.serious:
      return 3
    case ProcessInfo.ThermalState.critical:
      return 4
    @unknown default:
      return 0
    }
  }

  private func updateForegroundState(_ isForeground: Bool) {
    SwiftThermalPlugin.isForeground = isForeground
  }

  @objc public func onThermalStateChanged() {
    if let events = self.sink, SwiftThermalPlugin.canSendMsg, SwiftThermalPlugin.isForeground {
      events(SwiftThermalPlugin.toChannelValue(state: ProcessInfo.processInfo.thermalState))
    }
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let eventChannel = FlutterEventChannel(name: "thermal/events", binaryMessenger: registrar.messenger())
    let methodChannel = FlutterMethodChannel(name: "thermal", binaryMessenger: registrar.messenger())
    let instance = SwiftThermalPlugin()
    eventChannel.setStreamHandler(instance)
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    registrar.addApplicationDelegate(instance)
    if #available(iOS 13.0, *) {
      registrar.addSceneDelegate(instance)
    }
  }

  // MARK: - ApplicationDelegate

  public func applicationDidBecomeActive(_ application: UIApplication) {
    updateForegroundState(true)
  }

  public func applicationWillEnterForeground(_ application: UIApplication) {
    updateForegroundState(true)
  }

  public func applicationWillResignActive(_ application: UIApplication) {
    updateForegroundState(false)
  }

  public func applicationDidEnterBackground(_ application: UIApplication) {
    updateForegroundState(false)
  }

  // MARK: - SceneDelegate

  @available(iOS 13.0, *)
  public func sceneDidBecomeActive(_ scene: UIScene) {
    updateForegroundState(true)
  }

  @available(iOS 13.0, *)
  public func sceneWillEnterForeground(_ scene: UIScene) {
    updateForegroundState(true)
  }

  @available(iOS 13.0, *)
  public func sceneWillResignActive(_ scene: UIScene) {
    updateForegroundState(false)
  }

  @available(iOS 13.0, *)
  public func sceneDidEnterBackground(_ scene: UIScene) {
    updateForegroundState(false)
  }
}
