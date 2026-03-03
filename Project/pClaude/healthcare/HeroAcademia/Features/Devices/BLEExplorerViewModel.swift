import Foundation

@MainActor
@Observable
final class BLEExplorerViewModel {
    let service = BLEExplorerService()
    var filterTanita = true

    var filteredPeripherals: [DiscoveredPeripheral] {
        guard filterTanita else { return service.discoveredPeripherals }
        return service.discoveredPeripherals.filter { peripheral in
            guard let name = peripheral.name?.uppercased() else { return false }
            return name.contains("TANITA") || name.contains("RD-")
        }
    }

    func setup() {
        service.setup()
    }

    func generateDiscoveryReport() -> String {
        var report = "=== BLE Discovery Report ===\n"
        report += "Date: \(Date().formatted())\n\n"

        guard let peripheral = service.connectedPeripheral else {
            report += "No device connected.\n"
            return report
        }

        report += "Device: \(peripheral.name ?? "Unknown")\n"
        report += "UUID: \(peripheral.id.uuidString)\n"
        report += "RSSI: \(peripheral.rssi) dBm\n\n"

        for service in peripheral.services {
            report += "--- Service: \(service.displayName) ---\n"
            report += "  UUID: \(service.uuid.uuidString)\n"

            for char in service.characteristics {
                report += "\n  Characteristic: \(char.displayName)\n"
                report += "    UUID: \(char.uuid.uuidString)\n"
                report += "    Properties: \(char.propertyLabels.joined(separator: ", "))\n"
                if let hex = char.hexValue {
                    report += "    Value (hex): \(hex)\n"
                    if let data = char.value, let str = String(data: data, encoding: .utf8) {
                        report += "    Value (UTF-8): \(str)\n"
                    }
                }
                report += "    Notifying: \(char.isNotifying)\n"
            }
            report += "\n"
        }

        if !service.notificationLog.isEmpty {
            report += "--- Notification Log ---\n"
            for entry in service.notificationLog {
                report += "  [\(entry.timestamp.formatted(.dateTime.hour().minute().second()))] "
                report += "\(entry.characteristicName): \(entry.hexValue)\n"
            }
        }

        return report
    }
}
