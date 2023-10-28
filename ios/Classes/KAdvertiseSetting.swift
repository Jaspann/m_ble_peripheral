import CoreBluetooth

class KAdvertiseSetting {
    var name: String?
    
    init(settingMap: [String: Any]) {
        setByMap(settingMap: settingMap)
    }
    
    func toAdvertiseSetting() -> [String: String] {
        
        if let name = name {
                    return [CBAdvertisementDataLocalNameKey: name]
                } else {
                    return [:]
                }
    }
    
    func setByMap(settingMap: [String: Any]) {
        name = settingMap["name"] as? String
    }
}
