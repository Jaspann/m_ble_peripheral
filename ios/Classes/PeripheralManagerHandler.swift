import CoreBluetooth
import Flutter

class PeripheralManagerHandler: NSObject, FlutterPlugin, CBPeripheralManagerDelegate, FlutterStreamHandler {
    
    private var peripheralManager: CBPeripheralManager?
    private var eventSink: FlutterEventSink?
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
    static func register(with registrar: FlutterPluginRegistrar) {
        let instance = PeripheralManagerHandler()
        
        //         let gattChannel = FlutterMethodChannel(name: "m:kbp/gatt", binaryMessenger: registrar.messenger())
        let advertisingChannel = FlutterMethodChannel(name: "m:kbp/advertising", binaryMessenger: registrar.messenger())
        
        //         registrar.addMethodCallDelegate(instance, channel: gattChannel)
        registrar.addMethodCallDelegate(instance, channel: advertisingChannel)
        
        let eventChannel = FlutterEventChannel(name: "e:kbp/gatt", binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        let requestNumber = CharacteristicDelegate.addRequest(request: request)
        
        let readRequestEvent: [String: Any] = [
            "event": "CharacteristicReadRequest",
            "requestId": requestNumber,
            "entityId": String(request.hash),
        ]
        
        eventSink!(readRequestEvent)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest])
    {
        for request in requests {
            let requestNumber = CharacteristicDelegate.addRequest(request: request)
            
            var readRequestEvent: [String: Any] = [
                "event": "CharacteristicWriteRequest",
                "requestId": requestNumber,
                "entityId": String(request.hash),
            ]
            
            if(request.value != nil) {
                readRequestEvent["value"] = FlutterStandardTypedData(bytes: request.value!)
            }
            
            eventSink!(readRequestEvent)
        }
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startAdvertising":
            guard let args = call.arguments as? [String: Any],
                  let id = args["Id"] as? String,
                  let kAdvertiseSettingList = args["AdvertiseSetting"] as? [String: Any],
                  let kAdvertiseDataList = args["AdvertiseData"] as? [String: Any]
                    
            else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            
            let kAdvertiseSetting = KAdvertiseSetting(settingMap: kAdvertiseSettingList)
            let kAdvertiseData = KAdvertiseData(settingMap: kAdvertiseDataList)
            
            startAdvertising(id: id, advertiseSetting: kAdvertiseSetting, advertiseData: kAdvertiseData, result: result)
            result(nil)
            
        case "stopAdvertising":
            guard let id = call.arguments as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            
            stopAdvertising(id, result: result)
            result(nil)
        case "char/create":
            
            guard let args = call.arguments as? [String: Any],
                  let uuid = args["uuid"] as? String,
                  let propertiesList = args["properties"] as? Int,
                  let permissionsList = args["permissions"] as? Int,
                  let entityId = args["entityId"] as? String
            else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            
            let properties = KProperties(properties:propertiesList).getProperties()
            let permissions = KPermissions(permissions: permissionsList).getPermissions()
            
            CharacteristicDelegate.createCharacteristic(uuid: uuid, properties: properties, permissions: permissions, entityId: entityId)
            result(nil)
            
        case "char/sendResponse":
            guard let args = call.arguments as? [String: Any],
                  let requestId = args["requestId"] as? Int,
                  let value = args["value"] as? [Int]
            else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            
            guard var request = CharacteristicDelegate.popRequest(requestNumber: requestId)
            else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "No Request of ID found", details: nil))
                return
            }
            
            request.value = Data((value).map { UInt8($0) })
            
            peripheralManager?.respond(to: request, withResult: .success)
            result(nil)
            
        case "char/notify":
            guard let args = call.arguments as? [String: Any],
                  let entityId = args["charEntityId"] as? String,
                  let value = args["value"] as? [Int]
            else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            
            let characteristic = CharacteristicDelegate.getKChar(entityId: entityId)
            
            let dataValue = Data((value).map { UInt8($0) })
            
            peripheralManager?.updateValue(dataValue, for: characteristic.characteristic, onSubscribedCentrals: nil)
            
            result(nil)
            
        case "service/create":
            guard let args = call.arguments as? [String: Any],
                  let entityId = args["entityId"] as? String,
                  let uuid = args["uuid"] as? String,
                  let type = args["type"] as? Int,
                  let characteristicsData = args["characteristics"] as? [[String: Any]] else {
                result(FlutterError(code: "InvalidArguments", message: "Invalid arguments for service/create", details: nil))
                return
            }
            
            let characteristics = characteristicsData.compactMap { charDict -> KGattCharacteristic? in
                guard let charUuid = charDict["uuid"] as? String,
                      let charPropertiesList = charDict["properties"] as? Int,
                      let charPermissionsList = charDict["permissions"] as? Int,
                      let charEntityId = charDict["entityId"] as? String else {
                    return nil
                }
                
                let charProperties = KProperties(properties: charPropertiesList).getProperties()
                let charPermissions = KPermissions(permissions: charPermissionsList).getPermissions()
                
                return CharacteristicDelegate.createCharacteristic(uuid: charUuid, properties: charProperties, permissions: charPermissions, entityId: charEntityId)
            }
            
            GattServiceDelegate.createKService(entityId: entityId, uuid: uuid, type: type, characteristics: characteristics)
            result(nil)
            
        case "service/activate":
            guard let entityId = call.arguments as? String else {
                result(FlutterError(code: "InvalidArguments", message: "Invalid arguments for service/create", details: nil))
                return
            }
            
            activateService(entityId: entityId)
            
            result(nil)
            
        case "service/inactivate":
            guard let entityId = call.arguments as? String
            else {
                result(FlutterError(code: "InvalidArguments", message: "Invalid arguments for service/create", details: nil))
                return
            }
            
            inactivateService(entityId: entityId)
            
            result(nil)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func startAdvertising(id: String, advertiseSetting: KAdvertiseSetting, advertiseData: KAdvertiseData, result: @escaping FlutterResult) {
        
        let services: [CBUUID] = advertiseData.serviceData
        
        var advertisement: [String : Any] = [CBAdvertisementDataServiceUUIDsKey: services]
        
        if let name: String = advertiseSetting.name {
            advertisement[CBAdvertisementDataLocalNameKey] = name
        }
        
        peripheralManager?.startAdvertising(advertisement)
        
    }
    
    private func stopAdvertising(_ id: String, result: @escaping FlutterResult) {
        // Stop advertising for the given ID
        
        // Example: Stop advertising
        peripheralManager?.stopAdvertising()
    }
    
    private func setServiceState(entityId: String, state: Bool) {
        
    }
    
    private func activateService(entityId: String) {
        guard let kService = GattServiceDelegate.services[entityId] else {
            fatalError("Not Found Gatt Service, may be the entityId is wrong.")
        }
        peripheralManager?.add(kService.service)
        GattServiceDelegate.setServiceState(entityId: entityId, state: true)
    }
    
    private func inactivateService(entityId: String) {
        guard let kService = GattServiceDelegate.services[entityId] else {
            fatalError("Not Found Gatt Service, may be the entityId is wrong.")
        }
        peripheralManager?.remove(kService.service)
        GattServiceDelegate.setServiceState(entityId: entityId, state: false)
    }
}
