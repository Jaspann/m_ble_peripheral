import CoreBluetooth

class CharacteristicDelegate {
    // Store all created characteristics, using entityId as the key for retrieval
    private static var characteristics: [String: CBMutableCharacteristic] = [:]
    private static var requests: [Int: CBATTRequest] = [:]
    private static var requestCounter: Int = 0

    static func addRequest(request: CBATTRequest) -> Int {
        let requestNumber = requestCounter
        requestCounter = requestCounter + 1

        if(requestCounter == Int.max)
        {
            requestCounter = 0
        }

        requests[requestNumber] = request
        return requestNumber
    }

    static func popRequest(requestNumber: Int) -> CBATTRequest?
    {
        guard let request = requests.removeValue(forKey: requestNumber) else {
            return nil
        }
        return request
    }

    static func getEntityIdFromUUID(uuid: CBUUID) -> String? {
        for (identifier, characteristic) in characteristics {
            if characteristic.uuid == uuid {
                return identifier
            }
        }
        return nil
    }

    static func getKChar(entityId: String) -> CBMutableCharacteristic {
        guard 
            let kChar = characteristics[entityId] 
        else {
            fatalError("Not Found Gatt Characteristic, may be the entityId is wrong.")
        }
        return kChar
    }

    static func createCharacteristic(uuid: String, properties: CBCharacteristicProperties, permissions: CBAttributePermissions, entityId: String) -> CBMutableCharacteristic {
        let characteristic = CBMutableCharacteristic(
            type: CBUUID(string: uuid),
            properties: properties,
            value: nil,
            permissions: permissions
        )

        characteristics[entityId] = characteristic
        return characteristic
    }
}

extension CBMutableCharacteristic {
    func toMap() -> [String: Any?] {
        return [
            "uuid": uuid.uuidString,
            "properties": properties.rawValue,
            "permissions": permissions.rawValue
        ]
    }
}
