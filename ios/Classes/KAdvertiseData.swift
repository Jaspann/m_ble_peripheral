import CoreBluetooth

class KAdvertiseData {
    var serviceData: [CBUUID] = []

    init(settingMap: [String: Any]) {
        setByMap(settingMap: settingMap)
    }

    func toAdvertiseData() -> [String: Any] {
        var advertiseData: [String: Any] = [:]

        for (uuid, _data) in serviceData {
            advertiseData[CBAdvertisementDataServiceUUIDsKey] = [uuid]
        }

        return advertiseData
    }

    func setByMap(settingMap: [String: Any]) {
        if let serviceDataDict = settingMap["serviceData"] as? [String: Any] {
            for (key, _) in serviceDataDict {
                serviceData.append(CBUUID(string: key))
            }
        }
    }
}
