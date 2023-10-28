import CoreBluetooth

class GattServiceDelegate {
    // Store all created services, using entityId as the key for retrieval
    static var services: [String: CBMutableService] = [:]
    static var gattServer: CBPeripheralManager!

    static private let SERVICE_TYPE_PRIMARY = 0

    static func getService(entityId: String) -> CBMutableService {
        guard let kService = services[entityId] else {
            fatalError("Not Found Gatt Service, may be the entityId is wrong.")
        }
        return kService
    }

    static func createKService(entityId: String, uuid: String, type: Int, characteristics: [CBMutableCharacteristic]) -> CBMutableService {
        let service = CBMutableService(type: CBUUID(string: uuid), primary: type == SERVICE_TYPE_PRIMARY)
        
        if !characteristics.isEmpty
        {
            service.characteristics = characteristics
        }
        services[entityId] = service
        return service
    }
}
