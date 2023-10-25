import CoreBluetooth

class KPermissions {

    static let PERMISSION_READ = 0x01;
    static let PERMISSION_READ_ENCRYPTED = 0x02;
    static let PERMISSION_WRITE = 0x10;
    static let PERMISSION_WRITE_ENCRYPTED = 0x20;

    private var attributePermissions: CBAttributePermissions = []

    init(permissions: Int) {
        setByMap(permissions: permissions)
    }

    func getPermissions() -> CBAttributePermissions {
        return attributePermissions
    }

    func setByMap(permissions: Int) {
        if (permissions & KPermissions.PERMISSION_READ) != 0 {
            attributePermissions.insert(.readable)
        }
        if (permissions & KPermissions.PERMISSION_READ_ENCRYPTED) != 0 {
            attributePermissions.insert(.readEncryptionRequired)
        }
        if (permissions & KPermissions.PERMISSION_WRITE) != 0 {
            attributePermissions.insert(.writeable)
        }
        if (permissions & KPermissions.PERMISSION_WRITE_ENCRYPTED) != 0 {
            attributePermissions.insert(.writeEncryptionRequired)
        }
    }
}
