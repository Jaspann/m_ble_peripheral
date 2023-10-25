import CoreBluetooth

class GattServiceDelegate {
    // Store all created services, using entityId as the key for retrieval
    static var services: [String: KGattService] = [:]
    static var gattServer: CBPeripheralManager!

    static private let SERVICE_TYPE_PRIMARY = 0

    static func getService(entityId: String) -> KGattService {
        guard let kService = services[entityId] else {
            fatalError("Not Found Gatt Service, may be the entityId is wrong.")
        }
        return kService
    }

    static func setServiceState(entityId: String, state: Bool) {
        guard var kService = services[entityId] else {
            fatalError("Not Found Gatt Service, may be the entityId is wrong.")
        }
        kService.activated = state
    }

    static func createKService(entityId: String, uuid: String, type: Int, characteristics: [KGattCharacteristic]) -> KGattService {
        let service = CBMutableService(type: CBUUID(string: uuid), primary: type == SERVICE_TYPE_PRIMARY)
        characteristics.forEach {
            service.characteristics?.append($0.characteristic)
        }
        let kService = KGattService(entityId: entityId, service: service, activated: false)
        services[entityId] = kService
        return kService
    }
}
