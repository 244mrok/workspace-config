import SwiftUI

struct DeviceListView: View {
    @Bindable var viewModel: DeviceViewModel
    @State private var showingBLEExplorer = false

    var body: some View {
        List {
            if !viewModel.connectedDevices.isEmpty {
                Section("接続中のデバイス") {
                    ForEach(viewModel.connectedDevices) { device in
                        DeviceRow(device: device)
                            .swipeActions(edge: .trailing) {
                                Button("解除", role: .destructive) {
                                    Task { await viewModel.disconnectDevice(device) }
                                }
                            }
                    }
                }
            }

            Section("開発ツール") {
                Button {
                    showingBLEExplorer = true
                } label: {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundStyle(.purple)
                            .frame(width: 30)
                        VStack(alignment: .leading) {
                            Text("BLEエクスプローラー")
                                .font(.body)
                            Text("BLEデバイスのサービス・特性を探索")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("利用可能なデバイス") {
                ForEach(viewModel.availableDeviceTypes) { type in
                    HStack {
                        Image(systemName: type.iconName)
                            .foregroundStyle(.secondary)
                            .frame(width: 30)

                        VStack(alignment: .leading) {
                            Text(type.displayName)
                                .font(.body)
                            Text(type.statusMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("近日対応")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.tertiary, in: Capsule())
                    }
                    .onTapGesture {
                        viewModel.selectedDeviceType = type
                        viewModel.showingPairingSheet = true
                    }
                }
            }
        }
        .navigationTitle("デバイス管理")
        .task {
            await viewModel.loadDevices()
        }
        .sheet(isPresented: $showingBLEExplorer) {
            BLEExplorerView()
        }
        .sheet(isPresented: $viewModel.showingPairingSheet) {
            if let type = viewModel.selectedDeviceType {
                DevicePairingView(deviceType: type)
            }
        }
        .alert("エラー", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - Device Row

private struct DeviceRow: View {
    let device: HealthDevice

    var body: some View {
        HStack {
            Image(systemName: device.type.iconName)
                .foregroundStyle(.blue)
                .frame(width: 30)

            VStack(alignment: .leading) {
                Text(device.name)
                    .font(.body)
                if let lastSync = device.lastSyncDate {
                    Text("最終同期: \(lastSync.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Circle()
                .fill(device.isConnected ? .green : .orange)
                .frame(width: 8, height: 8)
        }
    }
}
