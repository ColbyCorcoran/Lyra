//
//  OfflineManager.swift
//  Lyra
//
//  Manages offline capabilities and network status monitoring
//

import Foundation
import Network
import SwiftUI

@Observable
class OfflineManager {
    static let shared = OfflineManager()

    var isOnline: Bool = true
    var networkType: NetworkType = .wifi
    var queuedOperations: [QueuedOperation] = []

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.lyra.network.monitor")

    enum NetworkType {
        case wifi
        case cellular
        case ethernet
        case offline
    }

    private init() {
        startMonitoring()
        loadQueuedOperations()
    }

    // MARK: - Network Monitoring

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateNetworkStatus(path: path)
            }
        }
        monitor.start(queue: queue)
    }

    private func updateNetworkStatus(path: NWPath) {
        isOnline = path.status == .satisfied

        if path.usesInterfaceType(.wifi) {
            networkType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            networkType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            networkType = .ethernet
        } else {
            networkType = .offline
        }

        // Process queued operations when coming back online
        if isOnline && !queuedOperations.isEmpty {
            processQueuedOperations()
        }
    }

    // MARK: - Operation Queueing

    func queueOperation(_ operation: QueuedOperation) {
        queuedOperations.append(operation)
        saveQueuedOperations()
        HapticManager.shared.warning()
    }

    private func processQueuedOperations() {
        guard isOnline else { return }

        let operations = queuedOperations
        queuedOperations.removeAll()

        for operation in operations {
            // Execute the operation
            // This would be implemented based on operation type
            print("Processing queued operation: \(operation.type)")
        }

        saveQueuedOperations()
    }

    // MARK: - Persistence

    private func loadQueuedOperations() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "offline.queuedOperations"),
           let operations = try? JSONDecoder().decode([QueuedOperation].self, from: data) {
            queuedOperations = operations
        }
    }

    private func saveQueuedOperations() {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(queuedOperations) {
            defaults.set(data, forKey: "offline.queuedOperations")
        }
    }

    // MARK: - Offline Mode Helpers

    var canSyncOverCellular: Bool {
        UserDefaults.standard.bool(forKey: "sync.allowCellular")
    }

    var shouldSync: Bool {
        guard isOnline else { return false }
        if networkType == .cellular {
            return canSyncOverCellular
        }
        return true
    }

    var networkStatusMessage: String {
        switch networkType {
        case .wifi:
            return "Connected via Wi-Fi"
        case .cellular:
            return "Connected via Cellular"
        case .ethernet:
            return "Connected via Ethernet"
        case .offline:
            return "Offline - Changes will sync when online"
        }
    }

    var networkIcon: String {
        switch networkType {
        case .wifi:
            return "wifi"
        case .cellular:
            return "antenna.radiowaves.left.and.right"
        case .ethernet:
            return "cable.connector"
        case .offline:
            return "wifi.slash"
        }
    }
}

// MARK: - Queued Operation

struct QueuedOperation: Identifiable, Codable {
    var id: UUID
    let type: OperationType
    let timestamp: Date
    let data: Data?

    init(id: UUID = UUID(), type: OperationType, timestamp: Date, data: Data? = nil) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.data = data
    }

    enum OperationType: String, Codable {
        case cloudFileUpload
        case cloudFileDownload
        case syncData
        case deleteCloudFile
    }
}

// MARK: - Offline Status View

struct OfflineStatusBanner: View {
    @State private var offlineManager = OfflineManager.shared

    var body: some View {
        if !offlineManager.isOnline {
            HStack(spacing: 12) {
                Image(systemName: offlineManager.networkIcon)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Offline Mode")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("All changes are saved locally")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !offlineManager.queuedOperations.isEmpty {
                    Text("\(offlineManager.queuedOperations.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.orange)
                        .clipShape(Capsule())
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
