import SwiftUI
import CoreBluetooth

struct BLEExplorerView: View {
    @State private var viewModel = BLEExplorerViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.service.connectedPeripheral != nil {
                    explorePhase
                } else {
                    scanPhase
                }
            }
            .navigationTitle("BLEエクスプローラー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.service.connectedPeripheral != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(
                            item: viewModel.generateDiscoveryReport(),
                            subject: Text("BLE Discovery Report"),
                            message: Text("TANITA RD-804L BLE探索結果")
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .onAppear {
                viewModel.setup()
            }
        }
    }

    // MARK: - Scan Phase

    private var scanPhase: some View {
        List {
            Section {
                HStack {
                    Circle()
                        .fill(viewModel.service.isBluetoothReady ? .green : .red)
                        .frame(width: 8, height: 8)
                    Text(viewModel.service.bluetoothStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Toggle("TANITAのみ表示", isOn: $viewModel.filterTanita)

                if viewModel.service.isScanning {
                    Button {
                        viewModel.service.stopScan()
                    } label: {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 4)
                            Text("スキャン停止")
                        }
                    }
                } else {
                    Button("スキャン開始") {
                        viewModel.service.startScan()
                    }
                    .disabled(!viewModel.service.isBluetoothReady)
                }
            }

            Section("検出されたデバイス (\(viewModel.filteredPeripherals.count))") {
                if viewModel.filteredPeripherals.isEmpty {
                    if viewModel.service.isScanning {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                ProgressView()
                                Text("デバイスを検索中...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    } else {
                        Text("デバイスが見つかりません")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(viewModel.filteredPeripherals) { peripheral in
                        Button {
                            viewModel.service.connect(to: peripheral)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(peripheral.name ?? "不明なデバイス")
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    Text(peripheral.id.uuidString)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                rssiIndicator(rssi: peripheral.rssi)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Explore Phase

    private var explorePhase: some View {
        List {
            if let peripheral = viewModel.service.connectedPeripheral {
                Section("接続中") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(peripheral.name ?? "不明なデバイス")
                            .font(.headline)
                        Text(peripheral.id.uuidString)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Button("切断", role: .destructive) {
                        viewModel.service.disconnect()
                    }
                }

                if peripheral.services.isEmpty {
                    Section {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 4)
                            Text("サービス探索中...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                ForEach(peripheral.services) { service in
                    Section(service.displayName) {
                        Text(service.uuid.uuidString)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        ForEach(service.characteristics) { char in
                            characteristicRow(char)
                        }
                    }
                }

                if !viewModel.service.notificationLog.isEmpty {
                    Section("通知ログ") {
                        ForEach(viewModel.service.notificationLog) { entry in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(entry.characteristicName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(entry.timestamp.formatted(.dateTime.hour().minute().second()))
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                Text(entry.hexValue)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Components

    private func characteristicRow(_ char: DiscoveredCharacteristic) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(char.displayName)
                .font(.subheadline)

            Text(char.uuid.uuidString)
                .font(.caption2)
                .foregroundStyle(.tertiary)

            // Property badges
            HStack(spacing: 4) {
                ForEach(char.propertyLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(.caption2, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.1), in: Capsule())
                        .foregroundStyle(.blue)
                }
            }

            // Value display
            if let hex = char.hexValue {
                VStack(alignment: .leading, spacing: 2) {
                    Text("値 (hex):")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(hex)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }

                if let data = char.value, let str = String(data: data, encoding: .utf8),
                   str.allSatisfy({ $0.isASCII && !$0.isNewline })
                {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("値 (UTF-8):")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(str)
                            .font(.caption)
                            .textSelection(.enabled)
                    }
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                if char.properties.contains(.read) {
                    Button("読み取り") {
                        viewModel.service.readCharacteristic(char.characteristic)
                    }
                    .font(.caption)
                }

                if char.properties.contains(.notify) || char.properties.contains(.indicate) {
                    Button(char.isNotifying ? "通知停止" : "通知開始") {
                        viewModel.service.toggleNotification(for: char.characteristic)
                    }
                    .font(.caption)
                    .foregroundStyle(char.isNotifying ? .red : .blue)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func rssiIndicator(rssi: Int) -> some View {
        HStack(spacing: 2) {
            let bars = rssiToBars(rssi)
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index < bars ? .green : .gray.opacity(0.3))
                    .frame(width: 3, height: CGFloat(6 + index * 3))
            }
            Text("\(rssi)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .trailing)
        }
    }

    private func rssiToBars(_ rssi: Int) -> Int {
        switch rssi {
        case -50...0: return 4
        case -65...(-51): return 3
        case -80...(-66): return 2
        case -95...(-81): return 1
        default: return 0
        }
    }
}
