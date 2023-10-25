import CoreBluetooth

class KProperties {

  static let PROPERTY_BROADCAST = 0x01;
  static let PROPERTY_READ = 0x02;
  static let PROPERTY_WRITE_NO_RESPONSE = 0x04;
  static let PROPERTY_WRITE = 0x08;
  static let PROPERTY_NOTIFY = 0x10;
  static let PROPERTY_INDICATE = 0x20;
  static let PROPERTY_SIGNED_WRITE = 0x40;
  static let PROPERTY_EXTENDED_PROPS = 0x80;

    private var characteristicProperties: CBCharacteristicProperties = []

    init(properties: Int) {
        setByMap(properties: properties)
    }

    func getProperties() -> CBCharacteristicProperties {
        return characteristicProperties
    }

    func setByMap(properties: Int) {
        if (properties & KProperties.PROPERTY_BROADCAST) != 0 {
            characteristicProperties.insert(.broadcast)
        }
        if (properties & KProperties.PROPERTY_READ) != 0 {
            characteristicProperties.insert(.read)
        }
        if (properties & KProperties.PROPERTY_WRITE_NO_RESPONSE) != 0 {
            characteristicProperties.insert(.writeWithoutResponse)
        }
        if (properties & KProperties.PROPERTY_WRITE) != 0 {
            characteristicProperties.insert(.write)
        }
        if (properties & KProperties.PROPERTY_NOTIFY) != 0 {
            characteristicProperties.insert(.notify)
        }
        if (properties & KProperties.PROPERTY_INDICATE) != 0 {
            characteristicProperties.insert(.indicate)
        }
        if (properties & KProperties.PROPERTY_SIGNED_WRITE) != 0 {
            characteristicProperties.insert(.authenticatedSignedWrites)
        }
        if (properties & KProperties.PROPERTY_EXTENDED_PROPS) != 0 {
            characteristicProperties.insert(.extendedProperties)
        }
    }
}
