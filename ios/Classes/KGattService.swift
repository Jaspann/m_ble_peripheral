import CoreBluetooth

struct KGattService {
    let entityId: String
    let service: CBMutableService
    var activated: Bool = false
}
