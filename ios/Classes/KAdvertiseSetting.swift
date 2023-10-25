import CoreBluetooth

class KAdvertiseSetting {
    var name: String?
    
    init(settingMap: [String: Any]) {
        setByMap(settingMap: settingMap)
    }
    
    func toAdvertiseSetting() -> [String: Any] {
        return [
            CBAdvertisementDataLocalNameKey: name ?? ""
        ]
    }
    
    func setByMap(settingMap: [String: Any]) {
        name = settingMap["name"] as? String
    }
}
