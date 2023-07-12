import Flutter
import UIKit

@available(iOS 11.0, *)
public class SwiftThermalPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  var sink: FlutterEventSink?
  @objc public static var canSendMsg = false
  
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
  
  @objc public func onThermalStateChanged() {
    if let events = self.sink, SwiftThermalPlugin.canSendMsg {
        do {
            try events(SwiftThermalPlugin.toChannelValue(state: ProcessInfo.processInfo.thermalState))
        } catch {
            
        }
    }
  }
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let eventChannel = FlutterEventChannel(name: "thermal/events", binaryMessenger: registrar.messenger())
    let methodChannel = FlutterMethodChannel(name: "thermal", binaryMessenger: registrar.messenger())
    let instance = SwiftThermalPlugin()
    eventChannel.setStreamHandler(instance)
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
  }
}
