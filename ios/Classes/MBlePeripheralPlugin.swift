import Flutter
import UIKit

public class MBlePeripheralPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
      PeripheralManagerHandler.register(with: registrar)
  }
}
