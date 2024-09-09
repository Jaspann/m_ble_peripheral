import CoreBluetooth
import Flutter
import os

class PeripheralManagerHandler: NSObject, FlutterPlugin, CBPeripheralManagerDelegate, FlutterStreamHandler {
    
    private var peripheralManager: CBPeripheralManager?
    private var eventSink: FlutterEventSink?
    
    private var notificaitonDataQueue: [Data] = []
    private var notificaitonCharacteristicQueue: [CBMutableCharacteristic] = []
    private var notificaitonCentralQueue: [CBCentral] = []
    
    private var devices: [UUID: CBCentral] = [:]
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo: CBCharacteristic) {
        
        let address = central.identifier
        
        guard let entityId = CharacteristicDelegate.getEntityIdFromUUID(uuid: didSubscribeTo.uuid) else {
            return
        }
        
        devices[address] = central
        
        let notificationSubscription: [String: Any] = [
            "event": "NotificationStateChange",
            "entityId": entityId,
            "device": ["address": address.uuidString],
            "enabled": true
        ]
        
        eventSink!(notificationSubscription)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom: CBCharacteristic) {
        
        let address = central.identifier
        
        guard let entityId = CharacteristicDelegate.getEntityIdFromUUID(uuid: didUnsubscribeFrom.uuid) else {
            return
        }
        
        peripheral.setDesiredConnectionLatency(.low, for: central)
        
        devices.removeValue(forKey: address)
        
        let notificationSubscription: [String: Any] = [
            "event": "NotificationStateChange",
            "entityId": entityId,
            "device": ["address": address.uuidString],
            "enabled": false
        ]
        
        eventSink!(notificationSubscription)
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers: CBPeripheralManager) {
        
        //This function is only activated when updateValue() fails, so keep looping until it does or the queue is emptied
        while !notificaitonDataQueue.isEmpty
        {
            let dataValue = notificaitonDataQueue.removeFirst()
            let characteristic = notificaitonCharacteristicQueue.removeFirst()
            let central = notificaitonCentralQueue.removeFirst()
            
            var sent = peripheralManager?.updateValue(dataValue, for: characteristic, onSubscribedCentrals: [central])
            
            // Convert Bool? to Bool
            guard let checkedSent = sent else {
                return
            }
            
            // If the message did not send
            if !checkedSent {
                notificaitonDataQueue.insert(dataValue, at: 0)
                notificaitonCharacteristicQueue.insert(characteristic, at: 0)
                notificaitonCentralQueue.insert(central, at: 0)
                break
            }
        }
        
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
        
        let gattChannel = FlutterMethodChannel(name: "m:kbp/gatt", binaryMessenger: registrar.messenger())
        let advertisingChannel = FlutterMethodChannel(name: "m:kbp/advertising", binaryMessenger: registrar.messenger())
        
        registrar.addMethodCallDelegate(instance, channel: gattChannel)
        registrar.addMethodCallDelegate(instance, channel: advertisingChannel)
        
        let eventChannel = FlutterEventChannel(name: "e:kbp/gatt", binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        let requestNumber = CharacteristicDelegate.addRequest(request: request)
        
        guard let entityId = CharacteristicDelegate.getEntityIdFromUUID(uuid: request.characteristic.uuid) else {return}
        
        let deviceAddress = request.central.identifier.uuidString
        
        let readRequestEvent: [String: Any] = [
            "event": "CharacteristicReadRequest",
            "requestId": requestNumber,
            "entityId": entityId,
            "offset": request.offset,
            "device": ["address": deviceAddress]
            
        ]
        
        eventSink!(readRequestEvent)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest])
    {
        for request in requests {
            let requestNumber = CharacteristicDelegate.addRequest(request: request)
            
            guard let entityId = CharacteristicDelegate.getEntityIdFromUUID(uuid: request.characteristic.uuid) else {return}
            
            var writeRequestEvent: [String: Any] = [
                "event": "CharacteristicWriteRequest",
                "requestId": requestNumber,
                "entityId": entityId,
            ]
            
            if(request.value != nil) {
                writeRequestEvent["value"] = FlutterStandardTypedData(bytes: request.value!)
            }
            
            eventSink!(writeRequestEvent)
        }
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startAdvertising":
            guard let args = call.arguments as? [String: Any],
                  let id = args["Id"] as? String,
                  let kAdvertiseSettingList = args["AdvertiseSetting"] as? [String: Any],
                  let kAdvertiseDataList = args["ScanResponseData"] as? [String: Any]
                    
            else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            
            let kAdvertiseSetting = KAdvertiseSetting(settingMap: kAdvertiseSettingList)
            let kAdvertiseData = KAdvertiseData(settingMap: kAdvertiseDataList)
            
            startAdvertising(id: id, advertiseSetting: kAdvertiseSetting, advertiseData: kAdvertiseData, result: result)
            result(nil)
            
        case "stopAdvertising":
            
            stopAdvertising()
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
            
            guard let request = CharacteristicDelegate.popRequest(requestNumber: requestId)
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
                  let value = args["value"] as? [Int],
                  let address = args["deviceAddress"] as? String,
                  let uuid = UUID(uuidString: address),
                  let central = devices[uuid]
            else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            
            
            let characteristic = CharacteristicDelegate.getKChar(entityId: entityId)
            
            let dataValue = Data((value).map { UInt8($0) })
            
            if !notificaitonDataQueue.isEmpty {
                notificaitonDataQueue.append(dataValue)
                notificaitonCharacteristicQueue.append(characteristic)
                notificaitonCentralQueue.append(central)
                result(nil)
                return
            }
            
            else
            {
                var sent = peripheralManager?.updateValue(dataValue, for: characteristic, onSubscribedCentrals: [central])
                
                // Convert Bool? to Bool
                guard let checkedSent = sent else {
                    result(nil)
                    return
                }
                
                // If the message did not send
                if !checkedSent {
                    notificaitonDataQueue.append(dataValue)
                    notificaitonCharacteristicQueue.append(characteristic)
                    notificaitonCentralQueue.append(central)
                }
            }
            
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
            
            let characteristics = characteristicsData.compactMap { charDict -> CBMutableCharacteristic? in
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
        
        var advertisement: [String : Any] = [:]
        
        if !advertiseData.serviceData.isEmpty {
            advertisement[CBAdvertisementDataServiceUUIDsKey] = advertiseData.serviceData
        }

        if let name: String = advertiseSetting.name {
            advertisement[CBAdvertisementDataLocalNameKey] = name
        }
        
        peripheralManager?.startAdvertising(advertisement)
        
    }
    
    private func stopAdvertising() {
        peripheralManager?.stopAdvertising()
    }
    
    private func activateService(entityId: String) {
        guard let service = GattServiceDelegate.services[entityId] else {
            fatalError("Not Found Gatt Service, may be the entityId is wrong.")
        }
        
        peripheralManager?.add(service)
    }
    
    private func inactivateService(entityId: String) {
        guard let service = GattServiceDelegate.services[entityId] else {
            fatalError("Not Found Gatt Service, may be the entityId is wrong.")
        }
        peripheralManager?.remove(service)
    }
}
