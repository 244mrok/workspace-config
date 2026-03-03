import Foundation
import CoreBluetooth

// MARK: - Data Models

struct DiscoveredPeripheral: Identifiable {
    let id: UUID
    let name: String?
    let rssi: Int
    let peripheral: CBPeripheral
    var services: [DiscoveredService] = []
}

struct DiscoveredService: Identifiable {
    let id: String
    let uuid: CBUUID
    var characteristics: [DiscoveredCharacteristic] = []

    var displayName: String {
        BLEKnownUUIDs.serviceName(for: uuid) ?? uuid.uuidString
    }
}

struct DiscoveredCharacteristic: Identifiable {
    let id: String
    let uuid: CBUUID
    let properties: CBCharacteristicProperties
    let characteristic: CBCharacteristic
    var value: Data?
    var isNotifying: Bool = false

    var displayName: String {
        BLEKnownUUIDs.characteristicName(for: uuid) ?? uuid.uuidString
    }

    var propertyLabels: [String] {
        var labels: [String] = []
        if properties.contains(.read) { labels.append("Read") }
        if properties.contains(.write) { labels.append("Write") }
        if properties.contains(.writeWithoutResponse) { labels.append("WriteNoResp") }
        if properties.contains(.notify) { labels.append("Notify") }
        if properties.contains(.indicate) { labels.append("Indicate") }
        return labels
    }

    var hexValue: String? {
        guard let data = value else { return nil }
        return data.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}

struct NotificationEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let characteristicUUID: CBUUID
    let data: Data

    var hexValue: String {
        data.map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    var characteristicName: String {
        BLEKnownUUIDs.characteristicName(for: characteristicUUID) ?? characteristicUUID.uuidString
    }
}

// MARK: - Known UUIDs

enum BLEKnownUUIDs {
    static let services: [String: String] = [
        "180A": "Device Information",
        "180D": "Heart Rate",
        "180F": "Battery Service",
        "181B": "Body Composition",
        "181D": "Weight Scale",
        "1800": "Generic Access",
        "1801": "Generic Attribute",
    ]

    static let characteristics: [String: String] = [
        // Device Information
        "2A29": "Manufacturer Name",
        "2A24": "Model Number",
        "2A25": "Serial Number",
        "2A27": "Hardware Revision",
        "2A26": "Firmware Revision",
        "2A28": "Software Revision",
        "2A23": "System ID",
        // Body Composition
        "2A9B": "Body Composition Feature",
        "2A9C": "Body Composition Measurement",
        // Weight Scale
        "2A9D": "Weight Scale Feature",
        "2A9E": "Weight Measurement",
        // Heart Rate
        "2A37": "Heart Rate Measurement",
        // Battery
        "2A19": "Battery Level",
        // Generic Access
        "2A00": "Device Name",
        "2A01": "Appearance",
        // Date Time
        "2A08": "Date Time",
        "2A2B": "Current Time",
    ]

    static func serviceName(for uuid: CBUUID) -> String? {
        let short = uuid.uuidString.prefix(4)
        return services[String(short)]
    }

    static func characteristicName(for uuid: CBUUID) -> String? {
        let short = uuid.uuidString.prefix(4)
        return characteristics[String(short)]
    }
}

// MARK: - BLE Explorer Service

@MainActor
@Observable
final class BLEExplorerService: NSObject {
    var discoveredPeripherals: [DiscoveredPeripheral] = []
    var connectedPeripheral: DiscoveredPeripheral?
    var isScanning = false
    var bluetoothState: CBManagerState = .unknown
    var notificationLog: [NotificationEntry] = []

    private var centralManager: CBCentralManager?
    private var activePeripheral: CBPeripheral?

    var isBluetoothReady: Bool {
        bluetoothState == .poweredOn
    }

    var bluetoothStatusMessage: String {
        switch bluetoothState {
        case .poweredOn: return "Bluetooth準備完了"
        case .poweredOff: return "Bluetoothがオフです"
        case .unauthorized: return "Bluetooth権限がありません"
        case .unsupported: return "Bluetoothに対応していません"
        case .resetting: return "Bluetoothリセット中..."
        case .unknown: return "Bluetooth状態確認中..."
        @unknown default: return "不明な状態"
        }
    }

    override nonisolated init() {
        super.init()
    }

    func setup() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScan() {
        guard isBluetoothReady else { return }
        discoveredPeripherals = []
        isScanning = true
        centralManager?.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false,
        ])
    }

    func stopScan() {
        centralManager?.stopScan()
        isScanning = false
    }

    func connect(to peripheral: DiscoveredPeripheral) {
        stopScan()
        activePeripheral = peripheral.peripheral
        activePeripheral?.delegate = self
        centralManager?.connect(peripheral.peripheral, options: nil)
    }

    func disconnect() {
        if let peripheral = activePeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        activePeripheral = nil
        connectedPeripheral = nil
    }

    func discoverServices() {
        activePeripheral?.discoverServices(nil)
    }

    func readCharacteristic(_ characteristic: CBCharacteristic) {
        activePeripheral?.readValue(for: characteristic)
    }

    func toggleNotification(for characteristic: CBCharacteristic) {
        let current = characteristic.isNotifying
        activePeripheral?.setNotifyValue(!current, for: characteristic)
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEExplorerService: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        Task { @MainActor in
            self.bluetoothState = state
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let peripheralId = peripheral.identifier
        let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let rssiValue = RSSI.intValue

        Task { @MainActor in
            // Skip peripherals with no name (too noisy)
            guard name != nil else { return }

            if let index = self.discoveredPeripherals.firstIndex(where: { $0.id == peripheralId }) {
                self.discoveredPeripherals[index] = DiscoveredPeripheral(
                    id: peripheralId,
                    name: name,
                    rssi: rssiValue,
                    peripheral: peripheral
                )
            } else {
                self.discoveredPeripherals.append(
                    DiscoveredPeripheral(
                        id: peripheralId,
                        name: name,
                        rssi: rssiValue,
                        peripheral: peripheral
                    )
                )
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            if let index = self.discoveredPeripherals.firstIndex(where: { $0.id == peripheral.identifier }) {
                self.connectedPeripheral = self.discoveredPeripherals[index]
            }
            self.discoverServices()
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            self.activePeripheral = nil
            self.connectedPeripheral = nil
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            self.activePeripheral = nil
            self.connectedPeripheral = nil
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLEExplorerService: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        let discoveredServices = services.map { service in
            DiscoveredService(
                id: service.uuid.uuidString,
                uuid: service.uuid
            )
        }

        Task { @MainActor in
            self.connectedPeripheral?.services = discoveredServices

            // Discover characteristics for each service
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        let serviceUUID = service.uuid.uuidString
        let discovered = characteristics.map { char in
            DiscoveredCharacteristic(
                id: "\(serviceUUID)_\(char.uuid.uuidString)",
                uuid: char.uuid,
                properties: char.properties,
                characteristic: char,
                value: char.value,
                isNotifying: char.isNotifying
            )
        }

        Task { @MainActor in
            if let serviceIndex = self.connectedPeripheral?.services.firstIndex(where: { $0.uuid == service.uuid }) {
                self.connectedPeripheral?.services[serviceIndex].characteristics = discovered
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let charUUID = characteristic.uuid
        let value = characteristic.value
        let isNotifying = characteristic.isNotifying
        let serviceUUID = characteristic.service?.uuid

        Task { @MainActor in
            // Update the stored characteristic value
            if let serviceUUID,
               let sIdx = self.connectedPeripheral?.services.firstIndex(where: { $0.uuid == serviceUUID }),
               let cIdx = self.connectedPeripheral?.services[sIdx].characteristics.firstIndex(where: { $0.uuid == charUUID })
            {
                self.connectedPeripheral?.services[sIdx].characteristics[cIdx].value = value
                self.connectedPeripheral?.services[sIdx].characteristics[cIdx].isNotifying = isNotifying
            }

            // Log notification if subscribed
            if isNotifying, let data = value {
                self.notificationLog.insert(
                    NotificationEntry(
                        timestamp: Date(),
                        characteristicUUID: charUUID,
                        data: data
                    ),
                    at: 0
                )
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        let charUUID = characteristic.uuid
        let isNotifying = characteristic.isNotifying
        let serviceUUID = characteristic.service?.uuid

        Task { @MainActor in
            if let serviceUUID,
               let sIdx = self.connectedPeripheral?.services.firstIndex(where: { $0.uuid == serviceUUID }),
               let cIdx = self.connectedPeripheral?.services[sIdx].characteristics.firstIndex(where: { $0.uuid == charUUID })
            {
                self.connectedPeripheral?.services[sIdx].characteristics[cIdx].isNotifying = isNotifying
            }
        }
    }
}
