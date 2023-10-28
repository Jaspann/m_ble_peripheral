import CoreBluetooth

class KAdvertiseData {
    var serviceData: [CBUUID] = []

    init(settingMap: [String: Any]) {
        setByMap(settingMap: settingMap)
    }

    func setByMap(settingMap: [String: Any]) {
        if let serviceDataDict = settingMap["serviceData"] as? [String: Any] {
            for (key, _) in serviceDataDict {
                serviceData.append(CBUUID(string: key))
            }
        }
    }
}
